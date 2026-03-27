# ==============================================================================
# [database.tf] 백엔드 앱의 데이터를 저장할 구글 관리형 DB를 생성합니다.
# VPC Peering을 통한 내부망 통신과 외부 Auth Proxy 접근을 동시 지원합니다.
# ==============================================================================

resource "google_sql_database_instance" "primary_db" {
  name             = "${var.project_name}-${var.environment}-hybrid-db"
  database_version = "MYSQL_8_0" # 최신 MySQL 8.0 엔진 사용
  region           = var.gcp_region

  # 🚨 주의: VPC Peering 구름다리가 완전히 뚫린 후에 DB를 생성하도록 순서 강제
  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    # DB 체급 설정: 부하 테스트를 견딜 수 있도록 vCPU 2개, RAM 7.5GB 할당
    tier = "db-custom-2-7680" 

    ip_configuration {
      # 💡 AWS Standby 노드가 Auth Proxy로 외부망을 통해 접근할 수 있도록 Public IP 유지
      ipv4_enabled = true 

      # 💡 핵심: GCP 내부의 K3s Primary Node는 Peering된 내부망(Private IP)으로 쾌속/안전 통신!
      private_network = google_compute_network.k3s_vpc.id 
    }
  }
  
  # 테스트 환경이므로 쉽게 지웠다 만들 수 있도록 삭제 보호 기능 끄기
  deletion_protection = false 
}

# DB 접속용 기본 루트 사용자 생성
resource "google_sql_user" "root_user" {
  name     = "root"
  instance = google_sql_database_instance.primary_db.name
  password = var.gcp_db_password # variables.tf에서 주입받은 비밀번호 사용
}

# ----------------------------------------------------------------
# 👇 백엔드 앱의 데이터가 정착할 '논리적 DB(방)' 공간 생성
# ----------------------------------------------------------------
resource "google_sql_database" "app_db" {
  name     = "hybrid_app_db" # 호성님(백엔드) 설정에 적어넣을 실제 DB 이름
  instance = google_sql_database_instance.primary_db.name
}

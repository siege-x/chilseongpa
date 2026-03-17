# ==============================================================================
# [database.tf] 백엔드 앱의 데이터를 저장할 구글 관리형 DB를 생성합니다.
# 오토스케일링을 지원하는 Auth Proxy 아키텍처를 적용했습니다.
# ==============================================================================

resource "google_sql_database_instance" "primary_db" {
  name             = "hybrid-primary-db"
  database_version = "MYSQL_8_0" # 최신 MySQL 8.0 엔진 사용
  region           = var.region

settings {
    tier = "db-custom-2-7680" 
    
    ip_configuration {
      ipv4_enabled = true 

      # 🚨 [추가] 1. GCP 내부 K3s 노드의 접근 허용 (network.tf의 고정 IP 연결)
      authorized_networks {
        name  = "gcp-primary-k3s"
        value = google_compute_address.k3s_static_ip.address
      }

      # 🚨 [추가] 2. AWS Standby 환경의 NAT IP 허용 (일단 변수로 처리)
      authorized_networks {
        name  = "aws-standby-nat"
        value = var.aws_standby_nat_ip 
      }
    }
  }
  
  # 테스트 환경이므로 쉽게 지웠다 만들 수 있도록 삭제 보호 기능 끄기
  deletion_protection = false 
}

# DB 접속용 기본 루트 사용자 생성
resource "google_sql_user" "root_user" {
  name     = "root"
  instance = google_sql_database_instance.primary_db.name
  password = var.db_password # variables.tf에서 주입받은 비밀번호 사용
}
# ----------------------------------------------------------------
# 👇 추가되는 부분: 백엔드 앱의 데이터가 정착할 '논리적 DB(방)' 공간 생성
# ----------------------------------------------------------------
resource "google_sql_database" "app_db" {
  name     = "hybrid_app_db" # 호성님(백엔드) 설정에 적어넣을 실제 DB 이름
  instance = google_sql_database_instance.primary_db.name
}

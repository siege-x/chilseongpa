# ==============================================================================
# [database.tf] 백엔드 앱의 데이터를 저장할 구글 관리형 DB를 생성합니다.
# ==============================================================================

resource "google_sql_database_instance" "primary_db" {
  name             = "${var.project_name}-${var.environment}-hybrid-db"
  database_version = "MYSQL_8_0" 
  region           = var.gcp_region

  # 🚨 주의: VPC Peering 구름다리가 완성된 후에 DB를 만들어야 에러가 안 납니다!
  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier = "db-custom-2-7680" 

    ip_configuration {
      # 💡 AWS Standby 노드가 Auth Proxy로 외부망을 통해 접근할 수 있도록 Public IP 유지
      ipv4_enabled = true 

      # 💡 핵심: GCP 내부의 K3s Primary Node는 Peering된 내부망(Private IP)으로 쾌속 통신!
      private_network = google_compute_network.k3s_vpc.id 
    }
  }
  
  deletion_protection = false 
}

# (이하 사용자 및 데이터베이스 생성 코드는 기존과 동일하게 유지)
resource "google_sql_user" "root_user" { ... }
resource "google_sql_database" "app_db" { ... }

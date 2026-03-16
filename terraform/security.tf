# ==============================================================================
# [security.tf] 타 팀(AWS Standby, 모니터링)에게 나눠줄 '맞춤형 보조 키'를 생성합니다.
# 마스터키 대신 최소 권한만 부여하여 하이브리드 클라우드의 보안을 책임집니다.
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. AWS Standby 팀(정현 님)에게 전달할 'DB 터널링 프록시' 키
# ------------------------------------------------------------------------------
resource "google_service_account" "db_proxy_sa" {
  account_id   = "aws-db-proxy-sa"
  display_name = "For AWS Standby Cloud SQL Auth Proxy"
}

# 이 계정에는 오직 "Cloud SQL 클라이언트(접속)" 권한 딱 하나만 줍니다.
resource "google_project_iam_member" "db_proxy_sa_role" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.db_proxy_sa.email}"
}

# 키 생성 및 로컬 폴더에 aws-db-proxy-key.json 파일로 저장!
resource "google_service_account_key" "db_proxy_sa_key" {
  service_account_id = google_service_account.db_proxy_sa.name
}
resource "local_file" "db_proxy_sa_key_file" {
  content  = base64decode(google_service_account_key.db_proxy_sa_key.private_key)
  filename = "${path.module}/aws-db-proxy-key.json"
}

# ------------------------------------------------------------------------------
# 2. AWS 모니터링 팀(희정 님)에게 전달할 'GCP 노드 탐색기(Prometheus SD)' 키
# ------------------------------------------------------------------------------
resource "google_service_account" "monitoring_sa" {
  account_id   = "aws-monitoring-sa"
  display_name = "Prometheus SD Service Account"
}

# 이 계정에는 오직 "서버 목록 읽기(Compute 뷰어)" 권한 딱 하나만 줍니다.
resource "google_project_iam_member" "monitoring_sa_role" {
  project = var.project_id
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${google_service_account.monitoring_sa.email}"
}

# 키 생성 및 로컬 폴더에 aws-monitoring-key.json 파일로 저장!
resource "google_service_account_key" "monitoring_sa_key" {
  service_account_id = google_service_account.monitoring_sa.name
}
resource "local_file" "monitoring_sa_key_file" {
  content  = base64decode(google_service_account_key.monitoring_sa_key.private_key)
  filename = "${path.module}/aws-monitoring-key.json"
}

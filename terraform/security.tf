# ==============================================================================
# [common.tf 또는 main.tf] 공통 API 활성화
# ==============================================================================

# 0. Secret Manager API 활성화 (금고 기능을 쓰기 위해 필수)
resource "google_project_service" "secretmanager_api" {
  project            = var.project_id
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

# ==============================================================================
# [database_auth.tf] Cloud SQL Auth Proxy용 계정 및 키 관리
# ==============================================================================

# 1. DB 접속용 로봇 계정(SA) 생성
resource "google_service_account" "db_proxy_sa" {
  account_id   = "gcp-db-proxy-sa"
  display_name = "For Cloud SQL Auth Proxy"
}

# 2. 계정 전파를 위한 30초 대기
resource "time_sleep" "wait_30_seconds_db" {
  depends_on      = [google_service_account.db_proxy_sa]
  create_duration = "30s"
}

# 3. DB 접속 권한(Cloud SQL Client) 부여
resource "google_project_iam_member" "db_proxy_sa_role" {
  depends_on = [time_sleep.wait_30_seconds_db]
  project    = var.project_id
  role       = "roles/cloudsql.client"
  member     = "serviceAccount:${google_service_account.db_proxy_sa.email}"
}

# 4. 권한 부여가 완료된 후 인증 키 발급
resource "google_service_account_key" "db_proxy_sa_key" {
  depends_on         = [google_project_iam_member.db_proxy_sa_role]
  service_account_id = google_service_account.db_proxy_sa.name
}

# 5. DB용 보안 금고(Secret) 생성
resource "google_secret_manager_secret" "db_proxy_key_secret" {
  depends_on = [google_project_service.secretmanager_api]
  secret_id  = "gcp-db-proxy-key-json"
  replication {
    auto {}
  }
}

# 6. DB용 키를 금고에 저장
resource "google_secret_manager_secret_version" "db_proxy_key_version" {
  secret      = google_secret_manager_secret.db_proxy_key_secret.id
  secret_data = base64decode(google_service_account_key.db_proxy_sa_key.private_key)
  depends_on  = [google_service_account_key.db_proxy_sa_key]
}
# ==============================================================================
# [monitoring.tf] 외부 모니터링 시스템(Prometheus 등)을 위한 서비스 계정 및 키 관리
# ==============================================================================

# 0. Secret Manager API 활성화 (안전한 실행을 위해 추가)
resource "google_project_service" "secretmanager_api" {
  project = var.project_id
  service = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

# 1. 모니터링용 서비스 계정 생성
resource "google_service_account" "monitoring_sa" {
  account_id   = "gcp-monitoring-sa" # aws-에서 gcp-로 직관적 변경
  display_name = "Service Account for External Monitoring (Prometheus)"
}

# 2. 계정 생성 후 전파를 위한 30초 대기
resource "time_sleep" "wait_30_seconds_monitoring" {
  depends_on      = [google_service_account.monitoring_sa]
  create_duration = "30s"
}

# 3. 서비스 계정에 서버 목록 열람 권한(monitoring Viewer) 부여
resource "google_project_iam_member" "monitoring_sa_role" {
  depends_on = [time_sleep.wait_30_seconds_monitoring]
  project    = var.project_id
  role       = "roles/monitoring.viewer"
  member     = "serviceAccount:${google_service_account.monitoring_sa.email}"
}

# 4. 서비스 계정의 인증 키(JSON) 발급
resource "google_service_account_key" "monitoring_sa_key" {
  depends_on         = [google_project_iam_member.monitoring_sa_role] # 권한 부여 후 키 생성
  service_account_id = google_service_account.monitoring_sa.name
}

# 5. 보안 금고(Secret Manager) 생성
resource "google_secret_manager_secret" "monitoring_key_secret" {
  depends_on = [google_project_service.secretmanager_api]
  secret_id  = "gcp-monitoring-key-json"

  replication {
    auto {} # GCP 버전 5.x 이상의 최신 표준 문법
  }
}

# 6. 발급된 키를 금고 안에 안전하게 저장
resource "google_secret_manager_secret_version" "monitoring_key_version" {
  secret      = google_secret_manager_secret.monitoring_key_secret.id
  # 키 값을 base64로 디코딩하여 실제 JSON 파일 내용으로 저장
  secret_data = base64decode(google_service_account_key.monitoring_sa_key.private_key)

  # 계정 생성, 권한 부여, 키 발급이 모두 완료된 후 마지막에 수행
  depends_on = [google_service_account_key.monitoring_sa_key]
}

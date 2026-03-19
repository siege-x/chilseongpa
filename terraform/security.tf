# ==============================================================================
# [security.tf] Secret Manager 공통 API 및 서비스 계정/키 관리
# ==============================================================================

# 0. Secret Manager API 활성화 (단일 선언)
resource "google_project_service" "secretmanager_api" {
  project            = var.project_id
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

# ------------------------------------------------------------------------------
# 1. Cloud SQL Auth Proxy용 계정 및 키 관리
# ------------------------------------------------------------------------------
resource "google_service_account" "db_proxy_sa" {
  account_id   = "gcp-db-proxy-sa"
  display_name = "For Cloud SQL Auth Proxy"
}

resource "time_sleep" "wait_30_seconds_db" {
  depends_on      = [google_service_account.db_proxy_sa]
  create_duration = "30s"
}

resource "google_project_iam_member" "db_proxy_sa_role" {
  depends_on = [time_sleep.wait_30_seconds_db]
  project    = var.project_id
  role       = "roles/cloudsql.client"
  member     = "serviceAccount:${google_service_account.db_proxy_sa.email}"
}

resource "google_service_account_key" "db_proxy_sa_key" {
  depends_on         = [google_project_iam_member.db_proxy_sa_role]
  service_account_id = google_service_account.db_proxy_sa.name
}

resource "google_secret_manager_secret" "db_proxy_key_secret" {
  depends_on = [google_project_service.secretmanager_api]
  secret_id  = "gcp-db-proxy-key-json"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_proxy_key_version" {
  secret      = google_secret_manager_secret.db_proxy_key_secret.id
  secret_data = base64decode(google_service_account_key.db_proxy_sa_key.private_key)
  depends_on  = [google_service_account_key.db_proxy_sa_key]
}

# ------------------------------------------------------------------------------
# 2. 외부 모니터링 시스템(Prometheus 등)을 위한 계정 관리
# ------------------------------------------------------------------------------
resource "google_service_account" "monitoring_sa" {
  account_id   = "gcp-monitoring-sa"
  display_name = "Service Account for External Monitoring (Prometheus/GCP Metrics)"
}

resource "time_sleep" "wait_30_seconds_monitoring" {
  depends_on      = [google_service_account.monitoring_sa]
  create_duration = "30s"
}

resource "google_project_iam_member" "monitoring_sa_role" {
  depends_on = [time_sleep.wait_30_seconds_monitoring]
  project    = var.project_id
  role       = "roles/monitoring.viewer"
  member     = "serviceAccount:${google_service_account.monitoring_sa.email}"
}

resource "google_service_account_key" "monitoring_sa_key" {
  depends_on         = [google_project_iam_member.monitoring_sa_role]
  service_account_id = google_service_account.monitoring_sa.name
}

resource "google_secret_manager_secret" "monitoring_key_secret" {
  depends_on = [google_project_service.secretmanager_api]
  secret_id  = "gcp-monitoring-key-json"
  replication { auto {} }
}

resource "google_secret_manager_secret_version" "monitoring_key_version" {
  secret      = google_secret_manager_secret.monitoring_key_secret.id
  secret_data = base64decode(google_service_account_key.monitoring_sa_key.private_key)
  depends_on  = [google_service_account_key.monitoring_sa_key]
}

# 1. 로봇 직원(SA) 생성 [기존 코드 유지]
resource "google_service_account" "db_proxy_sa" {
  account_id   = "aws-db-proxy-sa"
  display_name = "For AWS Standby Cloud SQL Auth Proxy"
}

# 🌟 [핵심 방어 코드] 구글 망에 SA 명단이 전파될 때까지 30초 대기 [기존 코드 유지]
resource "time_sleep" "wait_30_seconds_db" {
  depends_on = [google_service_account.db_proxy_sa] 
  create_duration = "30s"
}

# 2. 30초 대기 후 안전하게 권한 부여 [기존 코드 유지]
resource "google_project_iam_member" "db_proxy_sa_role" {
  depends_on = [time_sleep.wait_30_seconds_db] 

  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.db_proxy_sa.email}"
}

# 3. 신분증(JSON 키) 발급 [기존 코드 유지]
resource "google_service_account_key" "db_proxy_sa_key" {
  depends_on = [time_sleep.wait_30_seconds_db] 
  service_account_id = google_service_account.db_proxy_sa.name
}

# -------------------------------------------------------------------------
# 🚨 4. [여기가 수정된 부분!!] JSON 파일 저장 대신 GCP 보안 금고에 저장
# -------------------------------------------------------------------------
resource "google_secret_manager_secret" "db_proxy_key_secret" {
  secret_id = "aws-db-proxy-key-json"
  replication {
    auto {} # 구글이 알아서 안전한 리전에 분산 저장
  }
}

resource "google_secret_manager_secret_version" "db_proxy_key_version" {
  secret      = google_secret_manager_secret.db_proxy_key_secret.id
  # 위 3번에서 발급받은 키 데이터를 금고 안에 쏙 집어넣습니다!
  secret_data = base64decode(google_service_account_key.db_proxy_sa_key.private_key)
}

# 1. 로봇 직원(SA) 생성
resource "google_service_account" "db_proxy_sa" {
  account_id   = "aws-db-proxy-sa"
  display_name = "For AWS Standby Cloud SQL Auth Proxy"
}

# 🌟 [핵심 방어 코드] 구글 망에 SA 명단이 전파될 때까지 30초 대기
resource "time_sleep" "wait_30_seconds_db" {
  depends_on = [google_service_account.db_proxy_sa] # SA가 생성된 직후에만 실행됨
  create_duration = "30s"
}

# 2. 30초 대기 후 안전하게 권한 부여
resource "google_project_iam_member" "db_proxy_sa_role" {
  depends_on = [time_sleep.wait_30_seconds_db] # 30초 대기가 끝난 후에만 실행됨

  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.db_proxy_sa.email}"
}

# 3. 신분증(JSON 키) 발급
resource "google_service_account_key" "db_proxy_sa_key" {
  depends_on = [time_sleep.wait_30_seconds_db] # 30초 대기가 끝난 후에만 실행됨
  service_account_id = google_service_account.db_proxy_sa.name
}

# 4. JSON 파일 저장
resource "local_file" "db_proxy_sa_key_file" {
  content  = base64decode(google_service_account_key.db_proxy_sa_key.private_key)
  filename = "${path.module}/aws-db-proxy-key.json"
}

# (모니터링 SA 계정 부분도 동일한 패턴으로 time_sleep을 적용합니다)

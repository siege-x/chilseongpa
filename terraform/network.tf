# 1. K3s 노드용 정적 퍼블릭 IP (Static IP)
resource "google_compute_address" "k3s_static_ip" {
  name   = "k3s-primary-static-ip"
  region = var.region
}

# -------------------------------------------------------------------------
# 🛡️ 방화벽 규칙 1: 관리자 접근용 (SSH & K3s API)
# -------------------------------------------------------------------------
resource "google_compute_firewall" "allow_admin_access" {
  name    = "allow-k3s-admin-ssh-api"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22", "6443"] # 22(Ansible 접속용), 6443(외부 kubectl 제어용)
  }

  target_tags = ["k3s-node"]
  
  # [아키텍트의 주의사항] 
  # 지금은 테스트를 위해 0.0.0.0/0을 열어두지만, 실무에서는 성호님 집 IP나
  # GitHub Actions의 IP 대역만 허용하도록 범위를 축소해야 해킹을 막습니다!
  source_ranges = ["0.0.0.0/0"] 
}

# -------------------------------------------------------------------------
# 🛡️ 방화벽 규칙 2: 사용자 서비스용 (웹 트래픽)
# -------------------------------------------------------------------------
resource "google_compute_firewall" "allow_web_traffic" {
  name    = "allow-k3s-web-traffic"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80", "443"] # Cloudflare 트래픽 및 헬스체크 통과
  }

  target_tags = ["k3s-node"]
  source_ranges = ["0.0.0.0/0"] # 실무에서는 Cloudflare 공식 IP 대역만 허용
}

# -------------------------------------------------------------------------
# 🛡️ 방화벽 규칙 3: AWS 통합 모니터링 허용 (Prometheus 수집용)
# -------------------------------------------------------------------------
resource "google_compute_firewall" "allow_monitoring_scrape" {
  name    = "allow-k3s-monitoring"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["8080", "9100"] # 8080(앱 메트릭), 9100(노드 익스포터)
  }

  target_tags = ["k3s-node"]
  
  # 실무에서는 '희정님의 AWS Monitoring 서버 IP' 딱 1개만 넣는 것이 정석입니다!
  source_ranges = ["0.0.0.0/0"] 
}

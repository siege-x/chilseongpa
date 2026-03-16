# ==============================================================================
# [network.tf] K3s 노드의 IP를 고정하고, 타 팀이 들어올 수 있도록 대문을 엽니다.
# ==============================================================================

# 1. K3s 노드용 정적 퍼블릭 IP (Static IP)
# 이유: 노드가 재부팅되어도 IP가 바뀌지 않아야 Cloudflare DNS 설정이 유지됩니다.
resource "google_compute_address" "k3s_static_ip" {
  name   = "k3s-primary-static-ip"
  region = var.region
}

# 2. 타 팀(AWS 모니터링, Cloudflare Edge)을 위한 방화벽 규칙
resource "google_compute_firewall" "allow_k3s_ports" {
  name    = "allow-k3s-http-https-metrics"
  network = "default"

  allow {
    protocol = "tcp"
    # 80, 443: Cloudflare의 Health Check 및 사용자 트래픽 통과용
    # 9100: AWS 통합 모니터링 서버가 K3s 노드의 CPU/RAM 지표를 긁어가는 포트
    ports    = ["80", "443", "9100"] 
  }

  # 이 방화벽 규칙을 적용할 타겟 (compute.tf에서 만든 K3s 노드 태그와 일치해야 함)
  target_tags   = ["k3s-node"]
  
  # 어디서부터의 접근을 허용할 것인가 (0.0.0.0/0 은 전 세계 허용)
  # (실무 팁: 실제 운영 시에는 AWS IP와 Cloudflare IP만 넣어서 보안을 강화합니다)
  source_ranges = ["0.0.0.0/0"] 
}

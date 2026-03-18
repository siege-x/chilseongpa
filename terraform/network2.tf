# ==============================================================================
# [network.tf] Zero Trust 네트워크 설정
# ==============================================================================
resource "google_compute_address" "k3s_static_ip" {
  name   = "k3s-primary-static-ip"
  region = var.region
}

# -------------------------------------------------------------------------
# 🛡️ 방화벽: 오직 관리자(Ansible) 접근용 SSH만 허용 (Inbound 100% 차단)
# -------------------------------------------------------------------------
resource "google_compute_firewall" "allow_admin_access" {
  name    = "allow-k3s-admin-ssh"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"] # Ansible 접속용. (6443도 터널링 쓸 거면 닫아버려도 됩니다!)
  }

  target_tags   = ["k3s-node"]
  source_ranges = ["0.0.0.0/0"] # 실무에서는 GitHub Actions IP나 성호님 IP만!
}

# ==============================================================================
# [compute.tf] GCP VPC 내에 K3s가 구동될 가상 머신(VM)을 정의합니다.
# Cloudflare Tunnel을 통해 외부 포트 개방 없이 안전하게 연결됩니다.
# ==============================================================================

resource "google_compute_instance" "k3s_primary_node" {
  # 네이밍 규칙 적용: 팀 표준에 맞춰 식별력을 높입니다.
  name         = "${var.project_name}-${var.environment}-gcp-k3s-node"
  
  # 아키텍트의 결단: 부하 테스트와 안정성을 위해 사양 유지
  machine_type = "e2-standard-2" 
  zone         = var.gcp_zone

  # OS 및 디스크 설정
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 50
      type  = "pd-balanced"
    }
  }

  # 💡 네트워크 설정 (우리가 만든 커스텀 VPC와 서브넷으로 연결!)
  network_interface {
    network    = google_compute_network.k3s_vpc.id
    subnetwork = google_compute_subnetwork.k3s_subnet.id

    access_config {
      # 외부 IP 할당 (터널이 끊겼을 때의 비상용 또는 Ansible 접속용)
    }
  }

  # Cloudflare Tunnel 자동 설치 및 실행 스크립트 추가
  metadata_startup_script = <<-EOF
    #!/bin/bash
    curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
    dpkg -i cloudflared.deb
    cloudflared service install ${var.tunnel_token}
  EOF

  # 보안 및 식별 태그
  tags = ["k3s-node"] 

  # SSH 접속 설정 (루트 레벨에서 전달받은 공개키 사용)
  metadata = {
    ssh-keys = "ubuntu:${var.gcp_ssh_public_key}"
  }
}

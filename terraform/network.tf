# ==============================================================================
# [network.tf] GCP 내부에 커스텀 VPC와 서브넷을 구성하고,
# Cloud SQL(Google-managed VPC)과의 VPC Peering(Private Services Access)을 설정합니다.
# ==============================================================================

# 1. 커스텀 VPC 생성 (default망 탈출!)
resource "google_compute_network" "k3s_vpc" {
  name                    = "${var.project_name}-${var.environment}-vpc"
  auto_create_subnetworks = false # 서브넷을 수동으로 정교하게 통제하기 위해 false
}

# 2. 서브넷 생성 (K3s 노드가 위치할 방)
resource "google_compute_subnetwork" "k3s_subnet" {
  name          = "${var.project_name}-${var.environment}-subnet"
  region        = var.gcp_region
  network       = google_compute_network.k3s_vpc.id
  ip_cidr_range = "10.0.0.0/24" # 내부 IP 대역 지정
}

# -------------------------------------------------------------------------
# 🌟 [핵심] Cloud SQL 전용 VPC와 Peering을 맺기 위한 사전 작업
# -------------------------------------------------------------------------

# 3. 구글 관리형 서비스에 내어줄 Private IP 대역 할당
resource "google_compute_global_address" "private_ip_alloc" {
  name          = "${var.project_name}-${var.environment}-db-ip-alloc"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.k3s_vpc.id
}

# 4. VPC Peering 연결 (Private Services Access 활성화)
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.k3s_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc.name]
}

# -------------------------------------------------------------------------
# 🛡️ 방화벽: 관리자(Ansible) 및 K3s 내부 통신 개방
# -------------------------------------------------------------------------
resource "google_compute_firewall" "allow_admin_access" {
  name    = "${var.project_name}-${var.environment}-allow-k3s-ssh"
  network = google_compute_network.k3s_vpc.name # 커스텀 VPC로 변경

  allow {
    protocol = "tcp"
    ports    = ["22", "9100"] 
  }

  target_tags   = ["k3s-node"]
  source_ranges = ["0.0.0.0/0"] # 실무에서는 Bastion IP로 제한 권장
}

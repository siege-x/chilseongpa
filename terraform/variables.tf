# ==============================================================================
# [variables.tf] 
# 팀 공통 코드에서 사용하는 모든 변수를 여기서 선언해야 에러가 나지 않습니다.
# ==============================================================================

# 1. 네이밍 관련 (image_95ed7a.png 에러 해결용)
variable "project_name" {
  description = "프로젝트 이름"
  type        = string
  default     = "chiltong" # 성호님 프로젝트에 맞는 이름
}

variable "environment" {
  description = "배포 환경"
  type        = string
  default     = "dev"
}

# 2. 클라우드플레어 관련 (image_95f4c2.png 에러 해결용)
variable "tunnel_token" {
  description = "Cloudflare Tunnel Token"
  type        = string
  sensitive   = true # 보안을 위해 터미널 출력 방지
}

# 3. 기존 GCP 설정 변수들 (누락되지 않게 확인)
variable "gcp_project_id" {
  type        = string
}

variable "gcp_region" {
  type        = string
  default     = "asia-northeast3"
}

variable "gcp_zone" {
  type        = string
  default     = "asia-northeast3-a"
}

variable "gcp_db_password" {
  type        = string
  sensitive   = true
}

variable "gcp_ssh_public_key" {
  type        = string
}

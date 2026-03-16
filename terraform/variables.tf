# ==============================================================================
# [variables.tf] 하드코딩을 방지하고, 환경(Dev/Prod)이 바뀔 때 유연하게 
# 대처하기 위해 사용하는 변수 저장소입니다.
# ==============================================================================

variable "project_id" {
  description = "GCP 프로젝트 ID (예: hybrid-cloud-12345)"
  type        = string
}

variable "region" {
  description = "인프라가 배포될 리전 (AWS와 통신 지연을 막기 위해 서울로 고정)"
  type        = string
  default     = "asia-northeast3" # 아키텍트의 결정: 서울 리전
}

variable "zone" {
  description = "인프라가 배포될 가용 영역"
  type        = string
  default     = "asia-northeast3-a"
}

variable "db_password" {
  description = "Cloud SQL Root 비밀번호 (terraform.tfvars 파일에서 따로 주입받음)"
  type        = string
  sensitive   = true # 화면이나 로그에 비밀번호가 노출되지 않도록 가려줍니다.
}

# ==============================================================================
# [providers.tf] 구글 클라우드(GCP)와 통신하기 위한 테라폼의 기본 세팅 파일입니다.
# ==============================================================================

terraform {
  # 사용할 플러그인(Provider)들을 정의합니다.
  required_providers {
    # 1. GCP에 리소스를 만들기 위한 공식 구글 플러그인
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    # 2. 로컬 PC에 JSON 키 파일을 저장하기 위한 플러그인 (마법의 키 발급용)
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    # ✨ 여기에 추가하세요! (시간 대기용 플러그인)
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

# 구글 클라우드 계정에 로그인하는 부분입니다.
provider "google" {
  # (초특급 주의) 성호님의 마스터키 파일입니다. 절대 GitHub에 올리면 안 됩니다!
  credentials = file("gcpkey.json") 
  
  # 아래 변수들은 variables.tf 파일에서 끌어와서 사용합니다.
  project     = var.project_id
  region      = var.region
  zone        = var.zone
}

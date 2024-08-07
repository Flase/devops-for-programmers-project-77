terraform {
  backend "s3" {
    key                         = "cloud.tfstate"
    region                      = "ru-1"
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_s3_checksum            = true
    endpoints = {
      s3 = "https://s3.ru-1.storage.selcloud.ru"
    }
  }
}

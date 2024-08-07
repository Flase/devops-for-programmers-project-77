terraform {
  required_providers {
    selectel = {
      source  = "selectel/selectel"
      version = "5.1.1"
    }
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "2.0.0"
    }
  }
}

provider "selectel" {
  domain_name = "61244"
  username    = "Radozhitskiy"
  password    = var.selectel_password
}

provider "openstack" {
  auth_url    = "https://cloud.api.selcloud.ru/identity/v3"
  domain_name = "61244"
  tenant_id   = var.selectel_radozhickij_uuid
  user_name   = "Radozhitskiy"
  password    = var.selectel_password
  region      = "ru-9"
}

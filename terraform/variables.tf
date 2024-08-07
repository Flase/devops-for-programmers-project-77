variable "vm_count" {
  type    = number
  default = 3
}

variable "base_name" {
  type    = string
  default = "vm"
}

variable "s3_access_key" {
  description = "Access key for S3 backend"
  type        = string
}

variable "s3_secret_key" {
  description = "Secret key for S3 backend"
  type        = string
}

variable "selectel_password" {
  description = "Password for Selectel provider"
  type        = string
}

variable "selectel_radozhickij_uuid" {
  description = "UUID for Selectel tenant"
  type        = string
}

variable "service_user_uid" {
  description = "UUID for Selectel service user"
  type        = string
}

variable "selectel_domain_name" {
  description = "Selectel account ID"
  type        = string
}

variable "s3_bucket" {
  description = "S3 bucket name"
  type        = string
}

variable "radozhickij_network_id" {
  description = "Network UID"
  type        = string
}

variable "radozhickij_subnet_id" {
  description = "Subnet UID"
  type        = string
}

variable "app_db_password_vault" {
  description = "db password"
  type = string
}
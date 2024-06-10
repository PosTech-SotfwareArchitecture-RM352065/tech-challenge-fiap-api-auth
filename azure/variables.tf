variable "environment" {
  type      = string
  sensitive = false
  default   = "development"
}

variable "main_resource_group" {
  type      = string
  sensitive = false
  default   = "fiap-tech-challenge-main-group"
}

variable "main_resource_group_location" {
  type      = string
  sensitive = false
  default   = "eastus"
}
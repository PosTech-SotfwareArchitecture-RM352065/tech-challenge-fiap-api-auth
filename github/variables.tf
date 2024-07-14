variable "environment" {
  type      = string
  sensitive = false
  default   = ""
}

variable "sanduba_costumer_auth_secret_key" {
  type      = string
  sensitive = true
  default   = ""
}

variable "sanduba_costumer_database_connection_string" {
  type      = string
  sensitive = true
  default   = ""
}

variable "sanduba_costumer_url" {
  type      = string
  sensitive = false
  default   = ""
}
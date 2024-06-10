variable "environment" {
  type      = string
  sensitive = false
  default   = "development"
}

variable "auth_secret_key" {
  type      = string
  sensitive = true
  default   = ""
}

variable "database_connection_string" {
  type      = string
  sensitive = true
  default   = ""
}
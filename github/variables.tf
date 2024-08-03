variable "environment" {
  type      = string
  sensitive = false
  default   = ""
}

variable "sanduba_customer_auth_secret_key" {
  type      = string
  sensitive = true
  default   = ""
}

variable "sanduba_customer_database_connection_string" {
  type      = string
  sensitive = true
  default   = ""
}

variable "sanduba_customer_topic_manager_connection_string" {
  type      = string
  sensitive = true
  default   = ""
}

variable "sanduba_customer_topic_publisher_connection_string" {
  type      = string
  sensitive = true
  default   = ""
}

variable "sanduba_customer_topic_listener_connection_string" {
  type      = string
  sensitive = true
  default   = ""
}

variable "sanduba_customer_url" {
  type      = string
  sensitive = false
  default   = ""
}
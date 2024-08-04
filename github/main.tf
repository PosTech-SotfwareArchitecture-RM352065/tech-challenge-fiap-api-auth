resource "github_actions_organization_secret" "github_auth_secret_key" {
  secret_name     = "APP_AUTH_SECRET_KEY"
  visibility      = "all"
  plaintext_value = var.sanduba_customer_auth_secret_key
}

resource "github_actions_organization_secret" "database_connectionstring" {
  secret_name     = "APP_CUSTOMER_DATABASE_CONNECTION_STRING"
  visibility      = "all"
  plaintext_value = var.sanduba_customer_database_connection_string
}

resource "github_actions_organization_secret" "topic_manager_connectionstring" {
  secret_name     = "APP_CUSTOMER_TOPIC_MANAGER_CONNECTION_STRING"
  visibility      = "all"
  plaintext_value = var.sanduba_customer_topic_manager_connection_string
}

resource "github_actions_organization_secret" "topic_publisher_connectionstring" {
  secret_name     = "APP_CUSTOMER_TOPIC_PUBLISHER_CONNECTION_STRING"
  visibility      = "all"
  plaintext_value = var.sanduba_customer_topic_publisher_connection_string
}

resource "github_actions_organization_secret" "topic_listener_connectionstring" {
  secret_name     = "APP_CUSTOMER_TOPIC_LISTENER_CONNECTION_STRING"
  visibility      = "all"
  plaintext_value = var.sanduba_customer_topic_listener_connection_string
}

resource "github_actions_organization_variable" "sanduba_customer_url" {
  variable_name = "APP_CUSTOMER_URL"
  visibility    = "all"
  value         = var.sanduba_customer_url
}

resource "github_actions_organization_variable" "sanduba_customer_admin_api_key" {
  variable_name = "APP_CUSTOMER_ADMIN_API_KEY"
  visibility    = "all"
  value         = var.sanduba_customer_admin_api_key
}
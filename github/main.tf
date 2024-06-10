resource "github_actions_organization_secret" "github_auth_secret_key" {
  secret_name     = "APP_AUTH_SECRET_KEY"
  visibility      = "all"
  plaintext_value = var.sanduba_costumer_auth_secret_key
}


resource "github_actions_organization_secret" "database_connectionstring" {
  secret_name     = "APP_COSTUMER_DATABASE_CONNECTION_STRING"
  visibility      = "all"
  plaintext_value = var.sanduba_costumer_database_connection_string
}

resource "github_actions_organization_variable" "sanduba_costumer_url" {
  variable_name = "APP_COSTUMER_URL"
  visibility    = "all"
  value         = var.sanduba_costumer_url
}
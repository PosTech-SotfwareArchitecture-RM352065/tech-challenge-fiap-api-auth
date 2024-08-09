
resource "azurerm_resource_group" "resource_group" {
  name     = "fiap-tech-challenge-customer-group"
  location = var.main_resource_group_location

  tags = {
    environment = var.environment
  }
}

resource "random_password" "sqlserver_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_uuid" "sqlserver_user" {
}

resource "random_uuid" "auth_secret_key" {
}

resource "azurerm_mssql_server" "sqlserver" {
  name                         = "sanduba-customer-sqlserver"
  resource_group_name          = azurerm_resource_group.resource_group.name
  location                     = azurerm_resource_group.resource_group.location
  version                      = "12.0"
  administrator_login          = random_uuid.sqlserver_user.result
  administrator_login_password = random_password.sqlserver_password.result

  tags = {
    environment = azurerm_resource_group.resource_group.tags["environment"]
  }
}

resource "azurerm_mssql_firewall_rule" "sqlserver_allow_azure_services_rule" {
  name             = "Allow access to Azure services"
  server_id        = azurerm_mssql_server.sqlserver.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_mssql_firewall_rule" "sqlserver_allow_home_ip_rule" {
  name             = "Allow access to Home IP"
  server_id        = azurerm_mssql_server.sqlserver.id
  start_ip_address = var.home_ip_address
  end_ip_address   = var.home_ip_address
}

resource "azurerm_mssql_database" "sanduba_customer_database" {
  name                 = "sanduba-customer-database"
  server_id            = azurerm_mssql_server.sqlserver.id
  collation            = "SQL_Latin1_General_CP1_CI_AS"
  sku_name             = "Basic"
  max_size_gb          = 2
  read_scale           = false
  zone_redundant       = false
  geo_backup_enabled   = false
  create_mode          = "Default"
  storage_account_type = "Local"

  tags = {
    environment = azurerm_resource_group.resource_group.tags["environment"]
  }
}

resource "azurerm_service_plan" "customer_plan" {
  name                = "customer-app-service-plan"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  os_type             = "Linux"
  sku_name            = "B1"

  tags = {
    environment = azurerm_resource_group.resource_group.tags["environment"]
  }
}

resource "azurerm_servicebus_namespace" "servicebus_namespace" {
  name                = "fiap-tech-challenge-customer-topic-namespace"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  sku                 = "Standard"

  tags = {
    environment = azurerm_resource_group.resource_group.tags["environment"]
  }
}

resource "azurerm_servicebus_topic" "servicebus_topic" {
  name         = "fiap-tech-challenge-customer-topic"
  namespace_id = azurerm_servicebus_namespace.servicebus_namespace.id
}

resource "azurerm_servicebus_topic_authorization_rule" "servicebus_topic_manager" {
  name     = "${azurerm_servicebus_topic.servicebus_topic.name}-manager"
  topic_id = azurerm_servicebus_topic.servicebus_topic.id
  listen   = true
  send     = true
  manage   = true
}

resource "azurerm_servicebus_topic_authorization_rule" "servicebus_topic_publisher" {
  name     = "${azurerm_servicebus_topic.servicebus_topic.name}-publisher"
  topic_id = azurerm_servicebus_topic.servicebus_topic.id
  listen   = false
  send     = true
  manage   = false
}

resource "azurerm_servicebus_topic_authorization_rule" "servicebus_topic_listener" {
  name     = "${azurerm_servicebus_topic.servicebus_topic.name}-listener"
  topic_id = azurerm_servicebus_topic.servicebus_topic.id
  listen   = true
  send     = false
  manage   = false
}

resource "azurerm_servicebus_subscription" "topic_subscription" {
  name               = "customer-topic-subscription"
  topic_id           = data.azurerm_servicebus_topic.servicebus_topic.id
  max_delivery_count = 1
}

data "azurerm_storage_account" "storage_account_terraform" {
  name                = "sandubaterraform"
  resource_group_name = var.main_resource_group
}

data "azurerm_virtual_network" "virtual_network" {
  name                = "fiap-tech-challenge-network"
  resource_group_name = var.main_resource_group
}

data "azurerm_subnet" "api_subnet" {
  name                 = "fiap-tech-challenge-customer-subnet"
  virtual_network_name = data.azurerm_virtual_network.virtual_network.name
  resource_group_name  = data.azurerm_virtual_network.virtual_network.resource_group_name
}

resource "azurerm_linux_function_app" "linux_function" {
  name                        = "sanduba-customer-function"
  resource_group_name         = azurerm_resource_group.resource_group.name
  location                    = azurerm_resource_group.resource_group.location
  storage_account_name        = data.azurerm_storage_account.storage_account_terraform.name
  storage_account_access_key  = data.azurerm_storage_account.storage_account_terraform.primary_access_key
  service_plan_id             = azurerm_service_plan.customer_plan.id
  https_only                  = true
  functions_extension_version = "~4"

  app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE   = false
    FUNCTIONS_EXTENSION_VERSION           = "~4"
    "SqlServerSettings__ConnectionString" = "Server=tcp:${azurerm_mssql_server.sqlserver.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.sanduba_customer_database.name};Persist Security Info=False;User ID=${random_uuid.sqlserver_user.result};Password=${random_password.sqlserver_password.result};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
    "BrokerSettings__ConnectionString"    = azurerm_servicebus_topic_authorization_rule.servicebus_topic_manager.primary_connection_string
    "BrokerSettings__TopicName"           = azurerm_servicebus_topic.servicebus_topic.name
    "BrokerSettings__SubscriptionName"    = azurerm_servicebus_subscription.topic_subscription.name
    AUTH_SECRET_KEY                       = random_uuid.auth_secret_key.result
    AUTH_ISSUER                           = "Sanduba.Auth"
    AUTH_AUDIENCE                         = "Users"
  }

  site_config {
    always_on = true
    application_stack {
      docker {
        registry_url = "https://index.docker.io"
        image_name   = "cangelosilima/sanduba-customer-api"
        image_tag    = "latest"
      }
    }
  }

  virtual_network_subnet_id = data.azurerm_subnet.api_subnet.id

  tags = {
    environment = azurerm_resource_group.resource_group.tags["environment"]
  }
}

data "azurerm_storage_account" "log_storage_account" {
  name                = "sandubalog"
  resource_group_name = var.main_resource_group
}

data "azurerm_log_analytics_workspace" "log_workspace" {
  name                = "fiap-tech-challenge-observability-workspace"
  resource_group_name = data.azurerm_storage_account.log_storage_account.resource_group_name
}

resource "azurerm_monitor_diagnostic_setting" "function_monitor" {
  name                       = "fiap-tech-challenge-customer-function-monitor"
  target_resource_id         = azurerm_linux_function_app.linux_function.id
  storage_account_id         = data.azurerm_storage_account.log_storage_account.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.log_workspace.id

  enabled_log {
    category = "FunctionAppLogs"
  }

  metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "topic_monitor" {
  name                       = "fiap-tech-challenge-customer-topic-monitor"
  target_resource_id         = azurerm_servicebus_namespace.servicebus_namespace.id
  storage_account_id         = data.azurerm_storage_account.log_storage_account.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.log_workspace.id

  enabled_log {
    category_group = "allLogs"
  }

  metric {
    category = "AllMetrics"
  }
}

output "sanduba_customer_database_connection_string" {
  sensitive = true
  value     = "Server=tcp:${azurerm_mssql_server.sqlserver.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.sanduba_customer_database.name};Persist Security Info=False;User ID=${random_uuid.sqlserver_user.result};Password=${random_password.sqlserver_password.result};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
}

output "sanduba_customer_topic_manager_connection_string" {
  sensitive = true
  value     = azurerm_servicebus_topic_authorization_rule.servicebus_topic_manager.primary_connection_string
}

output "sanduba_customer_topic_publisher_connection_string" {
  sensitive = true
  value     = azurerm_servicebus_topic_authorization_rule.servicebus_topic_publisher.primary_connection_string
}

output "sanduba_customer_topic_listener_connection_string" {
  sensitive = true
  value     = azurerm_servicebus_topic_authorization_rule.servicebus_topic_listener.primary_connection_string
}

output "sanduba_customer_auth_key" {
  sensitive = true
  value     = random_uuid.auth_secret_key.result
}

output "sanduba_customer_url" {
  sensitive = false
  value     = "https://${azurerm_linux_function_app.linux_function.default_hostname}/api"
}

data "azurerm_function_app_host_keys" "function_app_key" {
  name                = azurerm_linux_function_app.linux_function.name
  resource_group_name = azurerm_linux_function_app.linux_function.resource_group_name
}

output "sanduba_customer_admin_api_key" {
  sensitive = true
  value     = data.azurerm_function_app_host_keys.function_app_key.primary_key
}
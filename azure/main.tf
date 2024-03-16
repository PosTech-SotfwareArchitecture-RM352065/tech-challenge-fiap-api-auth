terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.90.0"
    }
  }
  backend "azurerm" {
    key = "terraform-auth.tfstate"
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

data "azurerm_resource_group" "main_group" {
  name = "fiap-tech-challenge-main-group"
}

resource "azurerm_resource_group" "resource_group" {
  name       = "fiap-tech-challenge-auth-group"
  location   = data.azurerm_resource_group.main_group.location
  managed_by = data.azurerm_resource_group.main_group.name

  tags = {
    environment = data.azurerm_resource_group.main_group.tags["environment"]
  }
}

resource "azurerm_service_plan" "auth_plan" {
  name                = "auth-app-service-plan"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  os_type             = "Linux"
  sku_name            = "B1"

  tags = {
    environment = azurerm_resource_group.resource_group.tags["environment"]
  }
}

data "azurerm_storage_account" "storage_account_terraform" {
  name                = "sandubaterraform"
  resource_group_name = data.azurerm_resource_group.main_group.name
}

data "azurerm_virtual_network" "virtual_network" {
  name                = "fiap-tech-challenge-network"
  resource_group_name = data.azurerm_resource_group.main_group.name
}

data "azurerm_subnet" "api_subnet" {
  name                 = "fiap-tech-challenge-auth-subnet"
  virtual_network_name = data.azurerm_virtual_network.virtual_network.name
  resource_group_name  = data.azurerm_virtual_network.virtual_network.resource_group_name
}

resource "azurerm_linux_function_app" "linux_function" {
  name                        = "sanduba-auth-function"
  resource_group_name         = azurerm_resource_group.resource_group.name
  location                    = azurerm_resource_group.resource_group.location
  storage_account_name        = data.azurerm_storage_account.storage_account_terraform.name
  storage_account_access_key  = data.azurerm_storage_account.storage_account_terraform.primary_access_key
  service_plan_id             = azurerm_service_plan.auth_plan.id
  https_only                  = true
  functions_extension_version = "~4"

  app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = false
    FUNCTIONS_EXTENSION_VERSION         = "~4"
    AUTH_SECRET_KEY                     = var.authentication_secret_key
  }

  site_config {
    always_on = true
    application_stack {
      docker {
        registry_url = "https://index.docker.io"
        image_name   = "cangelosilima/sanduba-auth.api"
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
  resource_group_name = "fiap-tech-challenge-observability-group"
}

data "azurerm_log_analytics_workspace" "log_workspace" {
  name                = "fiap-tech-challenge-observability-workspace"
  resource_group_name = "fiap-tech-challenge-observability-group"
}


resource "azurerm_monitor_diagnostic_setting" "function_monitor" {
  name                       = "fiap-tech-challenge-auth-monitor"
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

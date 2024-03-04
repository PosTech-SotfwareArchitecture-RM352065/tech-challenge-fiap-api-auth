terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.90.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "fiap-tech-challenge-main-group"
    storage_account_name = "sandubaterraform"
    container_name       = "sanduba-terraform-storage-container"
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

resource "azurerm_application_insights" "auth_app_insights" {
  name                = "auth-app-insights"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  application_type    = "other"

  tags = {
    environment = azurerm_resource_group.resource_group.tags["environment"]
  }
}

data "azurerm_storage_account" "storage_account_terraform" {
  name                = "sandubaterraform"
  resource_group_name = data.azurerm_resource_group.main_group.name
}

resource "azurerm_linux_function_app" "linux_function" {
  name                       = "sanduba-auth-function"
  resource_group_name        = azurerm_resource_group.resource_group.name
  location                   = azurerm_resource_group.resource_group.location
  storage_account_name       = data.azurerm_storage_account.storage_account_terraform.name
  storage_account_access_key = data.azurerm_storage_account.storage_account_terraform.primary_access_key
  service_plan_id            = azurerm_service_plan.auth_plan.id
  https_only                 = true
  functions_extension_version = "~4"

  app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = false
  }

  site_config {
    application_insights_key               = azurerm_application_insights.auth_app_insights.instrumentation_key
    application_insights_connection_string = azurerm_application_insights.auth_app_insights.connection_string
    application_stack {
      docker {
        registry_url      = "https://index.docker.io"
        image_name        = "cangelosilima/sanduba-auth.api"
        image_tag         = "latest"
      }
    }
  }

  tags = {
    environment = azurerm_resource_group.resource_group.tags["environment"]
  }
}
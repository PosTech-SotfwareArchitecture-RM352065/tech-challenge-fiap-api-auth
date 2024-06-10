terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.90.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.1"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
  backend "azurerm" {
    key = "terraform-costumer.tfstate"
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

module "azure" {
  source                       = "./azure"
  main_resource_group          = data.azurerm_resource_group.main_group.name
  main_resource_group_location = data.azurerm_resource_group.main_group.location
  environment                  = data.azurerm_resource_group.main_group.tags["environment"]
}

module "github" {
  source                     = "./github"
  auth_secret_key            = module.azure.sanduba_costumer_auth_key
  database_connection_string = module.azure.sanduba_costumer_database_connection_string
  environment                = data.azurerm_resource_group.main_group.tags["environment"]
}
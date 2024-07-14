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
  home_ip_address              = var.home_ip_address
}

module "github" {
  source                                      = "./github"
  sanduba_costumer_auth_secret_key            = module.azure.sanduba_costumer_auth_key
  sanduba_costumer_database_connection_string = module.azure.sanduba_costumer_database_connection_string
  sanduba_costumer_url                        = module.azure.sanduba_costumer_url
  environment                                 = data.azurerm_resource_group.main_group.tags["environment"]
}
# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "> 4.0.0"
    }
  }
}

provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}

data "azurerm_resource_group" "main" {
  name     = var.resource_group_name
}
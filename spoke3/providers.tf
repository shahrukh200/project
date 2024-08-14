terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }
  required_version = ">= 1.1.0"

  backend "azurerm" {
    resource_group_name  = "shahrukh_resource_group"
    storage_account_name = "storageacc1ountms0121"
    container_name       = "backend-files"
    key                  = "spk1.tfstate"


  }
}
provider "azurerm" {
  features {}
}
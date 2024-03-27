terraform {
  required_providers {
    azurerm = {
      version = "= 3.88.0"
    }
  }
}

provider "azurerm" {
  features {}
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.51.0"
    }
  }
}

provider "azurerm" {
  subscription_id = "de63325c-0eac-407a-bd5c-db5742e35643"
  client_id       = "a1315780-d919-40de-aa6d-d95ff329722e"
  client_secret   = "E6U8Q~GMzfPDwwEvJiItTriK8XEr_T4C.8ovtcMc"
  tenant_id       = "93bece08-15b1-4a1d-ac47-e3c788d1efa4"
  features {}
}


resource "azurerm_resource_group" "testingterraform" {
  name     = "testingterraform"
  location = "East US"

}
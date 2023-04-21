terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.51.0"
    }
  }
}

provider "azurerm" {
  client_id       = "104bfe2c-13de-4330-a305-0dca478e43c2" 
  tenant_id       = "e8392f38-922d-4398-833d-329567533392" 
  subscription_id = "fd096583-2aad-460b-8eba-1f86d21a96c2" 
  client_secret   = "VR48Q~EefkRT1AAuXYdMYLe.g5cJHkKDfH5w3acE"
  features {}
}

resource "azurerm_resource_group" "testingterraform" {
    name = local.resource_group
    location = local.location
  
}

locals {
  resource_group="testingterraform"
  location="East US"
}
variable "storage_account_name" {
    type = string
    description = "please enter the storage account name"
    default = "testingstore212"
  
}

variable "container_name" {
  type = string
  description = "container name"
  default = "container222"
  
}

variable "blob_name" {
  type = string
  description = "block blob name"
  default = "testingblob12"
  
}
resource "azurerm_storage_account" "storageaccount" {
  name                     = var.storage_account_name
  resource_group_name      = local.resource_group
  location                 = local.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  cross_tenant_replication_enabled = false
  access_tier = "Hot"
  min_tls_version = "TLS1_2"
  shared_access_key_enabled = true
  public_network_access_enabled = true
  default_to_oauth_authentication = false
  depends_on = [
    azurerm_resource_group.testingterraform
  ]


  tags = {
    environment = "testing"
  }
}

# This resource is used for creating the container with necessary access level.
resource "azurerm_storage_container" "containername" {
  name                  = var.container_name
  storage_account_name  = var.storage_account_name
  container_access_type = "blob"

  # This creates dependency of the container on storage account
  depends_on = [
    azurerm_storage_account.storageaccount
  ]
}

# This resource is used for creating the blob inside the container 
resource "azurerm_storage_blob" "blobname" {
  name                   = var.blob_name
  storage_account_name   = var.storage_account_name
  storage_container_name = var.container_name
  type                   = "Block"
  source                 = "testing.txt"
  # This creates dependency of blob on container 
  depends_on = [azurerm_storage_container.containername]
}



resource "azurerm_storage_account" "storageaccount" {
  name                             = "testingstore2"
  resource_group_name              = "testingterraform"
  location                         = "East US"
  account_tier                     = "Standard"
  account_replication_type         = "LRS"
  account_kind                     = "StorageV2"
  cross_tenant_replication_enabled = false
  access_tier                      = "Cool"
  min_tls_version                  = "TLS1_2"
  shared_access_key_enabled        = true
  public_network_access_enabled    = true
  default_to_oauth_authentication  = false


  tags = {
    environment = "testing"
  }
}

# This resource is used for creating the container with necessary access level.
resource "azurerm_storage_container" "containername" {
  name                  = "container22"
  storage_account_name  = azurerm_storage_account.storageaccount.name
  container_access_type = "blob"

  # This creates dependency of the container on storage account
  depends_on = [
    azurerm_storage_account.storageaccount
  ]
}

# This resource is used for creating the blob inside the container 
resource "azurerm_storage_blob" "blobname" {
  name                   = "testingblob"
  storage_account_name   = azurerm_storage_account.storageaccount.name
  storage_container_name = azurerm_storage_container.containername.name
  type                   = "Block"
  source                 = "testing.txt"
  # This creates dependency of blob on container 
  depends_on = [azurerm_storage_container.containername]
}

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

data "azurerm_client_config" "current" {

  
}



resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "West Europe"
}

resource "azurerm_virtual_network" "example" {
  name                = "example-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "my_terraform_public_ip" {
  name = "vmpubip"
  resource_group_name  = azurerm_resource_group.example.name
  allocation_method = "Dynamic"
  location = azurerm_resource_group.example.location

}

resource "azurerm_network_security_group" "mynsg" {
  name                = "normalnsg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  security_rule {
    name                       = "RDP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "web"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "another"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "example" {
  name                = "example-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.my_terraform_public_ip.id
}
}

resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.example.id
  network_security_group_id = azurerm_network_security_group.mynsg.id
  
}

resource "azurerm_windows_virtual_machine" "example" {
  name                = "example-machine"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = azurerm_key_vault_secret.example.value
  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  depends_on = [
    azurerm_key_vault.example,
    azurerm_key_vault_secret.example
  ]
}

resource "azurerm_key_vault" "example" {
  name                        = "vmkeyvalult23"
  location                    = azurerm_resource_group.example.location
  resource_group_name         = azurerm_resource_group.example.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get","Create","Delete","List","Import"
    ]

    secret_permissions = [
      "Get","Set","List","Delete","Restore","Recover"
    ]

    storage_permissions = [
      "Get","Recover","Set"
    ]

    
  }
  depends_on = [
      azurerm_resource_group.example
    ]
}

resource "azurerm_key_vault_secret" "example" {
  name         = "vmsecret"
  value        = "P@$$w0rd1234!"
  key_vault_id = azurerm_key_vault.example.id
  depends_on = [
    azurerm_key_vault.example,
    azurerm_resource_group.example
  ]
}

resource "azurerm_storage_account" "example" {
  name                     = "accsastoragetest"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  public_network_access_enabled = true
  default_to_oauth_authentication = true
  depends_on = [
    azurerm_resource_group.example,
    azurerm_windows_virtual_machine.example
  ]

  tags = {
    environment = "staging"
  }
}

resource "azurerm_storage_container" "example" {
  name                  = "vhds"
  storage_account_name  = azurerm_storage_account.example.name
  container_access_type = "container"
}

# This resource is used for creating the blob inside the container 
resource "azurerm_storage_blob" "blobname" {
  name                   = "IISSetup.ps1"
  storage_account_name   = "accsastoragetest"
  storage_container_name = "vhds"
  type                   = "Block"
  source                 = "IISSetup.ps1"
  # This creates dependency of blob on container 
  depends_on = [azurerm_storage_container.example]
}

resource "azurerm_virtual_machine_extension" "customscript" {
  name                 = "IISSetup.ps1"
  virtual_machine_id   = azurerm_windows_virtual_machine.example.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.8"
  auto_upgrade_minor_version = true
  depends_on = [
    azurerm_storage_blob.blobname
  ]

  settings = <<SETTINGS
 {
  "fileUris": ["https://accsastoragetest.blob.core.windows.net/vhds/IISSetup.ps1"],
  "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted -file IISSetup.ps1"
 }
SETTINGS

protected_settings = <<PROTECTED_SETTINGS
  {
    "storageAccountName" : "${azurerm_storage_account.example.name}",
    "storageAccountKey":"${azurerm_storage_account.example.primary_access_key}"
  }
  PROTECTED_SETTINGS

}


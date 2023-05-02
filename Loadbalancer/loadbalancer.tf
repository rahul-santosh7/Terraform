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
  name     = "loadbalancertest"
  location = "East Us"
}

resource "azurerm_virtual_network" "example" {
  name                = "vnet67"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  name                 = "subnet27"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
}


resource "azurerm_network_security_group" "mynsg" {
  name                = "normalnsg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  security_rule {
    name                       = "RDP"
    priority                   = 100
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
    priority                   = 101
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

resource "azurerm_network_security_group" "mynsg2" {
  name                = "normalnsg2"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  security_rule {
    name                       = "RDP"
    priority                   = 100
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
    priority                   = 101
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
  name                = "virtualnic12"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
}
}

resource "azurerm_network_interface" "example2" {
  name                = "virtualnic13"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
}
}

resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.example.id
  network_security_group_id = azurerm_network_security_group.mynsg.id
  
}

resource "azurerm_network_interface_security_group_association" "example1" {
  network_interface_id      = azurerm_network_interface.example2.id
  network_security_group_id = azurerm_network_security_group.mynsg2.id
  
}

resource "azurerm_windows_virtual_machine" "example" {
  name                = "example-machine"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = "November@2k22"
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
    sku       = "2019-Datacenter"
    version   = "latest"
  }


}
resource "azurerm_windows_virtual_machine" "example1" {
  name                = "examplemachine2"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = "November@2k22"
  network_interface_ids = [
    azurerm_network_interface.example2.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }


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
    azurerm_windows_virtual_machine.example,
    azurerm_windows_virtual_machine.example1

  ]


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
resource "azurerm_virtual_machine_extension" "customscript1" {
  name                 = "IISSetup.ps1"
  virtual_machine_id   = azurerm_windows_virtual_machine.example1.id
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

resource "azurerm_public_ip" "example" {
  name                = "pubip22"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Static"
  sku = "Standard"
}

resource "azurerm_lb" "example" {
  name                = "vmloadtest"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.example.id
  }

  depends_on = [
    azurerm_virtual_machine_extension.customscript,
    azurerm_virtual_machine_extension.customscript1,
    azurerm_public_ip.example,
    azurerm_windows_virtual_machine.example1,
    azurerm_windows_virtual_machine.example,
    azurerm_storage_account.example
  ]
}
resource "azurerm_lb_backend_address_pool" "example" {
  loadbalancer_id = azurerm_lb.example.id
  name            = "BackEndAddressPool"

  depends_on = [
    azurerm_lb.example,
    azurerm_public_ip.example
  ]
}

resource "azurerm_lb_backend_address_pool_address" "example" {
  name                    = "appvmm1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.example.id
  virtual_network_id      = azurerm_virtual_network.example.id
  ip_address              = azurerm_network_interface.example.private_ip_address
  depends_on = [
    azurerm_lb_backend_address_pool.example
  ]
}

resource "azurerm_lb_backend_address_pool_address" "example1" {
  name                    = "appvmm2"
  backend_address_pool_id = azurerm_lb_backend_address_pool.example.id
  virtual_network_id      = azurerm_virtual_network.example.id
  ip_address              = azurerm_network_interface.example2.private_ip_address
  depends_on = [
    azurerm_lb_backend_address_pool.example
  ]
}

resource "azurerm_lb_probe" "example" {
  loadbalancer_id = azurerm_lb.example.id
  name            = "websiteprobe"
  port            = 80
}

resource "azurerm_lb_rule" "example" {
  loadbalancer_id                = azurerm_lb.example.id
  name                           = "LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id = azurerm_lb_probe.example.id
  backend_address_pool_ids = [azurerm_lb_backend_address_pool.example.id]
  
}

resource "azurerm_dns_zone" "example-public" {
  name                = "rahulsantosh.com"
  resource_group_name = azurerm_resource_group.example.name

  depends_on = [
    azurerm_public_ip.example,
    azurerm_lb.example
  ]
}

output "servernames" {
    value=azurerm_dns_zone.example-public.name_servers
  
}

resource "azurerm_dns_a_record" "example" {
  name                = "test"
  zone_name           = azurerm_dns_zone.example-public.name
  resource_group_name = azurerm_resource_group.example.name
  ttl                 = 300
  records             = [azurerm_public_ip.example.ip_address]
  depends_on = [
    azurerm_public_ip.example,
    azurerm_lb.example
  ]
}
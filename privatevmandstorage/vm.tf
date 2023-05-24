terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.51.0"
    }
  }
}

provider "azurerm" {
client_id = "a6c6163b-607b-467d-9c3e-09dd4da70294"
tenant_id = "0c45565b-c823-4469-9b6b-30989afb7a2e"
subscription_id = "738dfdc6-f0bd-407d-b899-c56640f7ce02"
client_secret = "mtc8Q~UqkUy-EXMS6WcjKm3ayv8p5J5EI5aQ.crC"
  features {}
}

resource "azurerm_resource_group" "testingterraform" {
  name     = "virtualmachinetest"
  location = "West US"

}

resource "azurerm_virtual_network" "network" {
  name                = "virtualm-network"
  address_space       = ["10.0.0.0/16"]
  resource_group_name = azurerm_resource_group.testingterraform.name
  location            = azurerm_resource_group.testingterraform.location
}

resource "azurerm_subnet" "subnet1" {
  name                 = "subnet1"
  resource_group_name  = azurerm_resource_group.testingterraform.name
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefixes     = ["10.0.1.0/24"]
  service_endpoints = ["Microsoft.Storage"]
}

resource "azurerm_subnet" "subnet2" {
  name                 = "subnet2"
  resource_group_name  = azurerm_resource_group.testingterraform.name
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefixes     = ["10.0.2.0/24"]
  service_endpoints = ["Microsoft.Storage"]
}

resource "azurerm_network_security_group" "nsg1" {
  name                = "normalnsg"
  location            = azurerm_resource_group.testingterraform.location
  resource_group_name = azurerm_resource_group.testingterraform.name

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
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

resource "azurerm_network_interface" "nic1" {
  name                      = "nic1"
  location                  = azurerm_resource_group.testingterraform.location
  resource_group_name       = azurerm_resource_group.testingterraform.name


  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "nic2" {
  name                      = "nic2"
  location                  = azurerm_resource_group.testingterraform.location
  resource_group_name       = azurerm_resource_group.testingterraform.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet2.id
    private_ip_address_allocation = "Dynamic"
  }

}

resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.nic1.id
  network_security_group_id = azurerm_network_security_group.nsg1.id
  
}

resource "azurerm_network_interface_security_group_association" "example2" {
  network_interface_id      = azurerm_network_interface.nic2.id
  network_security_group_id = azurerm_network_security_group.nsg1.id
  
}
 
resource "azurerm_linux_virtual_machine" "vm1" {
  name                = "myvm1"
  location            = azurerm_resource_group.testingterraform.location
  resource_group_name = azurerm_resource_group.testingterraform.name
  size                = "Standard_B2s"

  network_interface_ids = [azurerm_network_interface.nic1.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  admin_username = "adminuser"
  admin_ssh_key {
    username       = "adminuser"
    public_key     = file("~/.ssh/id_rsa.pub")  # Path to your public SSH key
  }

   
  depends_on = [
    azurerm_virtual_network.network,
    azurerm_subnet.subnet2,
    azurerm_network_interface.nic1

  ]
}

resource "azurerm_linux_virtual_machine" "vm2" {
  name                = "myvm2"
  location            = azurerm_resource_group.testingterraform.location
  resource_group_name = azurerm_resource_group.testingterraform.name
  size                = "Standard_B2s"

  network_interface_ids = [azurerm_network_interface.nic2.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  admin_username = "adminuser"
  admin_ssh_key {
    username       = "adminuser"
    public_key     = file("~/.ssh/id_rsa.pub")  # Path to your public SSH key
  }

   
  depends_on = [
    azurerm_virtual_network.network,
    azurerm_subnet.subnet1,
    azurerm_network_interface.nic1,
    azurerm_linux_virtual_machine.vm1


  ]
}


resource "azurerm_storage_account" "example" {
  name                     = "rahulprivst"
  resource_group_name      = azurerm_resource_group.testingterraform.name
  location                 = azurerm_resource_group.testingterraform.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
resource "azurerm_storage_account_network_rules" "example" {
  storage_account_id = azurerm_storage_account.example.id

  default_action = "Deny"

  virtual_network_subnet_ids = [
    azurerm_subnet.subnet1.id,
    azurerm_subnet.subnet2.id
  ]
}
resource "azurerm_private_endpoint" "example" {
  name                = "privateendpoint1"
  location            = azurerm_resource_group.testingterraform.location
  resource_group_name = azurerm_resource_group.testingterraform.name
  subnet_id                  = azurerm_subnet.subnet1.id
  private_service_connection {
    name                           = "example-private-connection"
    is_manual_connection = false
    private_connection_resource_id = azurerm_storage_account.example.id
    subresource_names              = ["blob"]
  }
}
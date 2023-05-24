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

variable "resource_group_name" {
  description = "Name of the resource group"
  default     = "newresource123"
}

variable "location" {
  description = "Azure region where the resources will be created"
  default     = "West US"
}


variable "vms" {
  description = "List of VM names and their corresponding Linux publishers, offers, skus, versions, subnets, and NSGs"
  type        = list(object({
    name        = string
    publisher   = string
    offer       = string
    sku         = string
    version     = string
    subnet_name = string
    nsg_name    = string
    vm_size     = string
  }))
  default = [
    {
      name        = "vm1"
      publisher   = "Canonical"
      offer       = "UbuntuServer"
      sku         = "18.04-LTS"
      version     = "latest"
      subnet_name = "subnet1"
      nsg_name    = "nsg1"
      vm_size     = "Standard_B1s"
    },
    {
      name        = "vm2"
      publisher   = "RedHat"
      offer       = "RHEL"
      sku         = "7-RAW"
      version     = "latest"
      subnet_name = "subnet2"
      nsg_name    = "nsg2"
      vm_size      = "Standard_B1s"
    },
    {
      name        = "vm3"
      publisher   = "OpenLogic"
      offer       = "CentOS"
      sku         = "7_9"
      version     = "latest"
      subnet_name = "subnet3"
      nsg_name    = "nsg3"
      vm_size      = "Standard_B1s"
    }
  ]
}
resource "azurerm_resource_group" "newresource123" {
  name     = var.resource_group_name
  location = var.location

}
resource "azurerm_virtual_network" "network" {
  name                = "my-virtual-network"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name
  
}

resource "azurerm_subnet" "subnets" {
  count                = length(var.vms)
  name                 = var.vms[count.index].subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefixes     = ["10.0.${count.index}.0/24"]
  
}

resource "azurerm_network_security_group" "security_groups" {
  count               = length(var.vms)
  name                = var.vms[count.index].nsg_name
  location            = var.location
  resource_group_name = var.resource_group_name
  
}

resource "azurerm_network_interface" "nics" {
  count               = length(var.vms)
  name                = "nic${count.index + 1}"
  location            = var.location
  resource_group_name = var.resource_group_name
  

  ip_configuration {
    name                          = "ipconfig${count.index + 1}"
    subnet_id                     = azurerm_subnet.subnets[count.index].id
    private_ip_address_allocation = "Dynamic"
    
  }
  
 
}

resource "azurerm_network_interface_security_group_association" "example" {
  count                     = length(var.vms)
  network_interface_id      = azurerm_network_interface.nics[count.index].id
  network_security_group_id = azurerm_network_security_group.security_groups[count.index].id
}


resource "azurerm_virtual_machine" "vms" {
  count               = length(var.vms)
  name                = var.vms[count.index].name
  location            = var.location
  resource_group_name = var.resource_group_name
  vm_size             = var.vms[count.index].vm_size
  network_interface_ids = [azurerm_network_interface.nics[count.index].id]

  storage_image_reference {
    publisher = var.vms[count.index].publisher
    offer     = var.vms[count.index].offer
    sku       = var.vms[count.index].sku
    version   = var.vms[count.index].version
  }

  storage_os_disk {
    name              = "${var.vms[count.index].name}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = var.vms[count.index].name
    admin_username = "adminuser"
    admin_password = "Password123!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
  
}

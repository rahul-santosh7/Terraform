terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.51.0"
    }
  }
}


terraform {
 backend "azurerm" {

 resource_group_name= "NetworkWatcherRG"
storage_account_name= "kstg123"
container_name = "rahul"
key= "terraform.tfstate"
 }
}

provider "azurerm" {
  tenant_id = "0c45565b-c823-4469-9b6b-30989afb7a2e"
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
   }
  }

}

variable "myObjectId" {
  default = "439b602a-a78d-47b5-93d2-adc7c0b96814"
}

variable "ADO_Service_Account_ObjectId" {
  default = "7991a281-33bb-455a-9eb8-fe8ece4f0857"
}

data "azurerm_client_config" "current" {

  
}



resource "azurerm_resource_group" "newresource123" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = "Testing"
    Department  = "Bench"
  }
 

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

resource "azurerm_virtual_network" "network" {
  name                = "my-virtual-network"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name
  depends_on = [
    azurerm_key_vault.example,
    azurerm_resource_group.newresource123
  ]

   tags = {
    Environment = "Testing"
    Department  = "Bench"
  }
 
  
}

resource "azurerm_subnet" "subnets" {
  count                = length(var.vms)
  name                 = var.vms[count.index].subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefixes     = ["10.0.${count.index}.0/24"]
  depends_on = [
    azurerm_key_vault.example,
    azurerm_resource_group.newresource123
  ]

  
}

resource "azurerm_network_security_group" "security_groups" {
  count               = length(var.vms)
  name                = var.vms[count.index].nsg_name
  location            = var.location
  resource_group_name = var.resource_group_name
  depends_on = [
    azurerm_key_vault.example,
    azurerm_resource_group.newresource123,
    azurerm_network_interface.nics
  ]

   tags = {
    Environment = "Testing"
    Department  = "Bench"
  }
 
  
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
  depends_on = [
    azurerm_key_vault.example,
    azurerm_resource_group.newresource123
  ]

   tags = {
    Environment = "Testing"
    Department  = "Bench"
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
    admin_password = azurerm_key_vault_secret.example.value
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
   tags = {
    Environment = "Testing"
    Department  = "Bench"
  }
 
  depends_on = [
    azurerm_key_vault.example,
    azurerm_resource_group.newresource123,
    azurerm_network_interface.nics
  ]
  
}



resource "azurerm_key_vault" "example" {
  name                        = "vmkeyvalut23"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name = "standard"


  depends_on = [
      azurerm_resource_group.newresource123
    ]

     tags = {
    Environment = "Testing"
    Department  = "Bench"
  }
 
}

locals {
  objectIds = {
    currentid = data.azurerm_client_config.current.object_id
    myid      = var.myObjectId
    adoid     = var.ADO_Service_Account_ObjectId
  }

}
resource "azurerm_key_vault_access_policy" "example" {
  for_each           = local.objectIds
  key_vault_id       = azurerm_key_vault.example.id
  tenant_id          = data.azurerm_client_config.current.tenant_id
  object_id          = each.value
  secret_permissions = ["Get", "Set", "List", "Delete", "Recover", "Restore", "Set", "Purge"]

}


resource "random_string" "secret" {
  length  = 16
  special = true
}


resource "azurerm_key_vault_secret" "example" {
  name         = "vmsecret"
  value        = random_string.secret.result
  key_vault_id = azurerm_key_vault.example.id
  depends_on = [
    azurerm_key_vault.example,
    azurerm_resource_group.newresource123
  ]
}









#resources
resource "azurerm_resource_group" "Ram-tfrg1" {
  name     = var.ResourceGroupName
  location = var.ResourceLocation
}

#network
resource "azurerm_virtual_network" "Ram-tfvnet1" {
  name                = var.Vnet_Name
  address_space       = var.Vnet_CIDR
  location            = azurerm_resource_group.Ram-tfrg1.location
  resource_group_name = azurerm_resource_group.Ram-tfrg1.name
}

resource "azurerm_subnet" "Ram-tf-subnet1" {
  name                 = var.Subnet_Name
  resource_group_name  = azurerm_resource_group.Ram-tfrg1.name
  virtual_network_name = azurerm_virtual_network.Ram-tfvnet1.name
  address_prefixes     = var.Subnet_address_prefixes
}

resource "azurerm_network_interface" "Ram-tf-nic1" {
  count               = var.InstanceCount
  name                = "${var.Nic_Name_Prefix}_${count.index}"
  resource_group_name = azurerm_resource_group.Ram-tfrg1.name
  location            = azurerm_resource_group.Ram-tfrg1.location

  ip_configuration {
    name                          = "nic1-config1_${count.index}"
    subnet_id                     = azurerm_subnet.Ram-tf-subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = element(azurerm_public_ip.Ram-tf-pip1.*.id, count.index)
  }
}

resource "azurerm_public_ip" "Ram-tf-pip1" {
  count               = var.InstanceCount
  name                = "${var.PIP_Name_Prefix}_${count.index}"
  resource_group_name = azurerm_resource_group.Ram-tfrg1.name
  location            = azurerm_resource_group.Ram-tfrg1.location
  allocation_method   = "Static"
  tags = {
    "Name" = "TF VM"
  }
}

#VM
resource "azurerm_windows_virtual_machine" "Ram-tf-VM1" {
  count                 = var.InstanceCount
  name                  = "${var.VM_Name_Prefix}${count.index}"
  resource_group_name   = azurerm_resource_group.Ram-tfrg1.name
  location              = azurerm_resource_group.Ram-tfrg1.location
  size                  = var.VM_Size
  admin_username        = "testuser"
  admin_password        = "Prime@123"
  network_interface_ids = [element(azurerm_network_interface.Ram-tf-nic1.*.id, count.index)]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = var.SKU
    version   = "latest"
  }

}




resource "azurerm_storage_account" "teststorageyrk1" {
  name                     = "teststorageyrk1"
  resource_group_name      = azurerm_resource_group.Ram-tfrg1.name
  location                 = azurerm_resource_group.Ram-tfrg1.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "psscripts" {
  name                  = "psscripts"
  storage_account_name  = azurerm_storage_account.teststorageyrk1.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "uploadfiles" {
  name                   = "IISSetup.ps1"
  storage_account_name   = azurerm_storage_account.teststorageyrk1.name
  storage_container_name = azurerm_storage_container.psscripts.name
  type                   = "Block"
  source                 = "PowerShellScripts\\IISSetup.ps1"
}


/*data "template_file" "init" {
  template = "${file("init.tpl")}"
  vars = {
    ips = azurerm_windows_virtual_machine.Ram-tf-VM1[*].public_ip_address
  }
}*/


locals {
  ips = templatefile("${"init.tpl"}",{
    ips = azurerm_windows_virtual_machine.Ram-tf-VM1[*].public_ip_address
  })
}
resource "local_file" "testfile" {
  content = "${local.ips}"
  filename = "testing.txt"
}


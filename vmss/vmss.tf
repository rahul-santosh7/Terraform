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
resource "azurerm_resource_group" "example" {
  name     = "vmsstest12"
  location = "East Us"
}

resource "azurerm_virtual_network" "example" {
  name                = "vmssnetwork12"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "internal" {
  name                 = "vmsssubnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_windows_virtual_machine_scale_set" "example" {
  name                = "vmsstest1"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  sku                 = "Standard_F1"
  instances           = 3
  admin_password      = "P@55w0rd1234!"
  admin_username      = "adminuser"

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "vmssnic"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.internal.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.example.id]
    }
  }
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
    
    azurerm_public_ip.example
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
    azurerm_windows_virtual_machine_scale_set.example

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

resource "azurerm_virtual_machine_scale_set_extension" "example" {
  name                         = "example"
  virtual_machine_scale_set_id = azurerm_windows_virtual_machine_scale_set.example.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version         = "1.9"
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


resource "azurerm_subnet_network_security_group_association" "networksgassociation" {
    subnet_id                 = azurerm_subnet.internal.id
    network_security_group_id = azurerm_network_security_group.mynsg2.id
}

resource "azurerm_monitor_autoscale_setting" "example" {
  name                = "myAutoscaleSetting"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  target_resource_id  = azurerm_windows_virtual_machine_scale_set.example.id

  profile {
    name = "defaultProfile"

    capacity {
      default = 1
      minimum = 1
      maximum = 4
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_windows_virtual_machine_scale_set.example.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 25
        metric_namespace   = "microsoft.compute/virtualmachinescalesets"
        dimensions {
          name     = "AppName"
          operator = "Equals"
          values   = ["App1"]
        }
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_windows_virtual_machine_scale_set.example.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
  }

  notification {
    email {
      send_to_subscription_administrator    = true
      send_to_subscription_co_administrator = true
      custom_emails                         = ["rahul.santosh7@gmail.com"]
    }
  }
}


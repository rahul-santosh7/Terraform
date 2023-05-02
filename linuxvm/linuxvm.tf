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
  name     = "newlinuxresources"
  location = "East Us"
}

resource "azurerm_virtual_network" "example" {
  name                = "example-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  depends_on = [
    azurerm_resource_group.example
  ]
}

resource "azurerm_subnet" "example" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
  depends_on = [
    azurerm_virtual_network.example
  ]
}

resource "azurerm_public_ip" "my_terraform_public_ip" {
  name = "vmpubip"
  resource_group_name  = azurerm_resource_group.example.name
  allocation_method = "Dynamic"
  location = azurerm_resource_group.example.location
  depends_on = [
    azurerm_resource_group.example
  ]

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
depends_on = [
  azurerm_public_ip.my_terraform_public_ip
]
}

resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.example.id
  network_security_group_id = azurerm_network_security_group.mynsg.id
  
}
resource "local_file" "linuxkey" {
  filename = "linuxkey.pem"
  content = tls_private_key.example_ssh.private_key_pem
}

resource "tls_private_key" "example_ssh" {
    algorithm = "RSA"
    rsa_bits = 4096

}


resource "azurerm_storage_account" "example" {
  name                     = "linuxsa22"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
depends_on = [
  azurerm_resource_group.example
]
 
}

resource "azurerm_storage_container" "example" {
  name                  = "vhds"
  storage_account_name  = azurerm_storage_account.example.name
  container_access_type = "container"
}

resource "azurerm_linux_virtual_machine" "example" {
  name                  = "linuxvm22"
  location              = azurerm_resource_group.example.location
  resource_group_name   = azurerm_resource_group.example.name
  network_interface_ids = [azurerm_network_interface.example.id]
  size              = "Standard_D4s_v3"
  admin_username = "adminuser"
  

  admin_ssh_key {
        username = "adminuser"
        public_key = tls_private_key.example_ssh.public_key_openssh #The magic here
  }


  os_disk {
    name          = "myosdisk1"
    caching       = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18_04-lts-gen2"
    version = "latest"
  }


depends_on = [
  tls_private_key.example_ssh
]
}



resource "azurerm_virtual_machine_extension" "example" {
  name                 = "hostname22"
  virtual_machine_id   = azurerm_linux_virtual_machine.example.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"
  

  protected_settings = <<PROTECTED_SETTINGS
 {
  "script": "${filebase64("custom_script.sh")}"
          
  }
PROTECTED_SETTINGS


}

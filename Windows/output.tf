output "PublicIp" {
  value       = join(",", azurerm_windows_virtual_machine.Ram-tf-VM1.*.public_ip_address)
  description = "Windows VM Pubic Ip"
}

output "publicip2" {
  value = [azurerm_windows_virtual_machine.Ram-tf-VM1.*.public_ip_address]
}

output "publicip3" {
  value = azurerm_windows_virtual_machine.Ram-tf-VM1.*.public_ip_address
}

/*data "azurerm_public_ip" "datapip" {
  filter {
    name = "tag:Name"
    values = ["TF VM"]
  }
  depends_on = [
    azurerm_public_ip.Ram-tf-pip1
  ]
}

output "testpip" {
  value = data.azurerm_public_ip.datapip
}*/
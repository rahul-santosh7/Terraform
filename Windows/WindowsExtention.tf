resource "azurerm_virtual_machine_extension" "iissetup" {
  count                = var.InstanceCount
  name                 = "IISSetup"
  virtual_machine_id   = element(azurerm_windows_virtual_machine.Ram-tf-VM1.*.id, count.index)
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"
  settings             = <<SETTINGS
  {
    "fileUris": ["https://teststorageyrk1.blob.core.windows.net/psscripts/IISSetup.ps1"],
    "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted -file IISSetup.ps1"
  }
  SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
  {
    "storageAccountName" : "${azurerm_storage_account.teststorageyrk1.name}",
    "storageAccountKey":"${azurerm_storage_account.teststorageyrk1.primary_access_key}"
  }
  PROTECTED_SETTINGS
}


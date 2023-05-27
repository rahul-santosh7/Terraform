variable "client_id" {
  sensitive = true
}

variable "client_secret" {
  sensitive = true
}

variable "tenant_id" {
  sensitive = true
}

variable "subscription_id" {
  sensitive = true
}


variable "resource_group_name" {
  description = "Name of the resource group"
  default     = "newresource123"
  
}

variable "location" {
  description = "Azure region where the resources will be created"
  default     = "West US"
}

variable "myObjectId" {
  default = "439b602a-a78d-47b5-93d2-adc7c0b96814"
}

variable "ADO_Service_Account_ObjectId" {
  default = "7991a281-33bb-455a-9eb8-fe8ece4f0857"
}
locals {
  objectIds = {
    currentid = data.azurerm_client_config.current.object_id
    myid      = var.myObjectId
    adoid     = var.ADO_Service_Account_ObjectId
  }

}
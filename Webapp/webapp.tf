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

variable "sql_server_name" {
  type = string 
  default = "webappsqlserver12"
}

variable "sql_database" {
  type = string 
  default = "webappsqldb"
  
}

data "azurerm_sql_database" "example" {
  name                = var.sql_database
  resource_group_name = azurerm_resource_group.rg.name
  server_name = var.sql_server_name
}

data "azurerm_sql_server" "example" {
  name                = var.sql_server_name
  resource_group_name = azurerm_resource_group.rg.name
}
#output "connection_string" {
  #value = "Server=${data.azurerm_sql_server.example.fqdn};Database=${data.azurerm_sql_database.example.name};User Id=sqladmin;Password=November@2k22;Encrypt=true;TrustServerCertificate=false;Connection Timeout=30;"
#}




resource "azurerm_resource_group" "rg" {
  name     = "example-resources"
  location = "East Us"
}

resource "azurerm_storage_account" "storage" {
  name                     = "storagenewtest34"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}



resource "azurerm_app_service_plan" "plan" {
  name                = "newaasp"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku {
    tier = "Basic"
    size = "B1"
  }
}

resource "azurerm_app_service" "example" {
  name                = "example356"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  app_service_plan_id = azurerm_app_service_plan.plan.id

  site_config {
      dotnet_framework_version = "v5.0"
    
  }
  app_settings = {
    "AzureWebJobsStorage"  = azurerm_storage_account.storage.primary_connection_string
    "FUNCTIONS_EXTENSION_VERSION" = "~5"
    "FUNCTIONS_WORKER_RUNTIME" = "dotnet"
    "SQLSERVER_NAME"     = azurerm_sql_server.example.fully_qualified_domain_name
    "SQLSERVER_DATABASE" = data.azurerm_sql_database.example.name
    "SQLSERVER_USER"     = "sqladmin"
    "SQLSERVER_PASSWORD" = "November@2k22"
    "SQLSERVER_CONNECTION_STRING" = "Server=tcp:${data.azurerm_sql_server.example.fqdn},1433;Initial Catalog=${data.azurerm_sql_database.example.name};Persist Security Info=False;User Id=sqladmin;Password=November@2k22;MultipleActiveResultSets=False;Encrypt=true;TrustServerCertificate=False;Connection Timeout=30;"
  }

  source_control {
    repo_url = "https://github.com/rahul-santosh7/Webapp"
    branch = "main"
    manual_integration = "true"
    use_mercurial = "false"
  }
  depends_on = [
    azurerm_sql_database.example
  ]

}

resource "azurerm_sql_server" "example" {
  name                         = "webappsqlserver12"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = "November@2k22"


}


resource "azurerm_sql_database" "example" {
  name                = "webappsqldb"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  server_name         = azurerm_sql_server.example.name
  collation = "SQL_Latin1_General_CP1_CI_AS"
depends_on = [
  azurerm_sql_server.example
]
}

resource "azurerm_sql_firewall_rule" "example" {
  name                = "FirewallRule1"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_sql_server.example.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
  depends_on = [
    azurerm_sql_database.example
  ]
}







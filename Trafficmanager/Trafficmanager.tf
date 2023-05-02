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


resource "azurerm_resource_group" "rg" {
  name     = "example-resources"
  location = "East Us"
}




resource "azurerm_app_service_plan" "plan" {
  name                = "newaasp"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "example" {
  name                = "example356"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  app_service_plan_id = azurerm_app_service_plan.plan.id

  site_config {
      dotnet_framework_version = "v6.0"
    
  }
  app_settings = {
    "FUNCTIONS_EXTENSION_VERSION" = "~6"
    "FUNCTIONS_WORKER_RUNTIME" = "dotnet"
  }

  source_control {
    repo_url = "https://github.com/rahul-santosh7/primarywebapp"
    branch = "master"
    manual_integration = "true"
    use_mercurial = "false"
  }
  
}

resource "azurerm_app_service" "app" {
  name                = "example357"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  app_service_plan_id = azurerm_app_service_plan.plan.id

  site_config {
      dotnet_framework_version = "v6.0"
    
  }
  app_settings = {
    "FUNCTIONS_EXTENSION_VERSION" = "~6"
    "FUNCTIONS_WORKER_RUNTIME" = "dotnet"
  }

  source_control {
    repo_url = "https://github.com/rahul-santosh7/WebApplication2"
    branch = "master"
    manual_integration = "true"
    use_mercurial = "false"
  }
  
}

resource "azurerm_traffic_manager_profile" "example" {
  name                   = "testingwebapp12"
  resource_group_name    = azurerm_resource_group.rg.name
  traffic_routing_method = "Priority"

  dns_config {
    relative_name = "testingwebapp12"
    ttl           = 100
  }

  monitor_config {
    protocol                     = "HTTPS"
    port                         = 443
    path                         = "/"
    interval_in_seconds          = 30
    timeout_in_seconds           = 9
    tolerated_number_of_failures = 3
  }
}

resource "azurerm_traffic_manager_azure_endpoint" "example" {
  name               = "primaryendpoint"
  profile_id         = azurerm_traffic_manager_profile.example.id
  weight             = 70
  priority = 1
  target_resource_id = azurerm_app_service.example.id
}

resource "azurerm_traffic_manager_azure_endpoint" "example1" {
  name               = "secondaryendpoint"
  profile_id         = azurerm_traffic_manager_profile.example.id
  weight             = 30
  priority = 2
  target_resource_id = azurerm_app_service.app.id
}







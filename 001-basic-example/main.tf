locals {
  location = "northeurope"  
}

resource "azurerm_resource_group" "application_rg" {  
  name     = "ary-app-rg"
  location = local.location
}

resource "azurerm_storage_account" "application_storage" {
  name                     = "aryappsa"
  resource_group_name      = azurerm_resource_group.application_rg.name
  location                 = azurerm_resource_group.application_rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
}
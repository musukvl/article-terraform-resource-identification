locals {
  location = "northeurope"
  application = {
    "document-parser-service" = {
      storage_account_name = "arydocparsesvc"
    }
    "email-sender-service" = {
      storage_account_name = "aryemailsendersvc"
    }
  }
}

resource "azurerm_resource_group" "application_rg" {  
  for_each = local.application
  name     = "ary-app-rg-${each.key}"
  location = local.location
}

resource "azurerm_storage_account" "application_storage" {
  for_each = local.application
  name                     = each.value.storage_account_name
  resource_group_name      = azurerm_resource_group.application_rg[each.key].name
  location                 = azurerm_resource_group.application_rg[each.key].location
  account_tier             = "Standard"
  account_replication_type = "GRS"
}
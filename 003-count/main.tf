locals {
  location = "northeurope"

  applications = [
    {
      name = "document-parser-service"
      storage_account_name = "arydocparsesvc"
    },
    {
      name = "email-sender-service"
      storage_account_name = "aryemailsendersvc"
    }
  ]

}

resource "azurerm_resource_group" "application_rg" {  
  count    = length(local.applications)
  name     = "ary-app-rg-${local.applications[count.index].name}"
  location = local.location
}

resource "azurerm_storage_account" "application_storage" {
  count = length(local.applications)
  name                     = local.applications[count.index].storage_account_name
  resource_group_name      = azurerm_resource_group.application_rg[count.index].name
  location                 = local.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
}
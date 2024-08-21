resource "azurerm_resource_group" "resource_group" {
name = var.resource_group_name
location = var.location
}

# create the storage account

resource "azurerm_storage_account" "stgaccount" {
name = var.storage_account_name
resource_group_name = azurerm_resource_group.resource_group.name
location = azurerm_resource_group.resource_group.location
account_tier = "Standard"
account_replication_type = "LRS"
depends_on = [ azurerm_resource_group.resource_group ]
  
}

# create storage account container to store the state files

resource "azurerm_storage_container" "project_state" {
    name = var.container_name
    storage_account_name = azurerm_storage_account.stgaccount.name
    container_access_type = "private"
  
}
resource "azurerm_resource_group""sha" {
    name = "shahrukh1"
    location = "uk south"
  
}
resource "azurerm_virtual_network" "vn001" {
    resource_group_name = azurerm_resource_group.sha.name
    address_space = [ "10.1.0.0/16" ]
    location = azurerm_resource_group.sha.location
    name = "vnet001"
depends_on=[azurerm_resource_group.sha]  
}
resource "azurerm_subnet" "subnet001" {
    for_each = var.ms
    resource_group_name = azurerm_resource_group.sha.name
    virtual_network_name = azurerm_virtual_network.vn001.name
    address_prefixes = [each.value.address_prefixes]
    name = each.value.name
  
}

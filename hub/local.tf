locals {
     subnet_names = [for subnet in azurerm_subnet.subnet: subnet.name]
}
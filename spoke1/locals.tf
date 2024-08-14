locals {
  subnet_names ={for i, sub in azurerm_subnet.subnet: i => sub.name}
  nsg_names = [for nsg in azurerm_network_security_group.nsg : nsg.name]
  subnet_id = [for i in azurerm_subnet.subnet : i.id]
}
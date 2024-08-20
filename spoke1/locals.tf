locals {
  subnet_names =[for  sub in azurerm_subnet.subnet:sub.name]
  nsg_names = {for i,nsg in azurerm_network_security_group.nsg:i=>nsg.name}
  subnet_id = [for i in azurerm_subnet.subnet : i.id]
  rules_csv=csvdecode(file(var.rule_file))


   yourPowerShellScript= try(file("mount/vm-mount.ps1"),null)
   base64EncodedScript = base64encode(local.yourPowerShellScript)


}
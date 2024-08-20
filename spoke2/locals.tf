locals {
    rules_csv = csvdecode(file(var.rules_file))
    subnet_names = [for subnet in azurerm_subnet.subnet : subnet.name]
    nsg_names = { for idx , nsg in azurerm_network_security_group.nsg : idx => nsg.name}
    # nsg_counts=length(local.subnet_name)
    application_gateway_backend_address_sha_ids = [for sha in azurerm_application_gateway.appgw.backend_address_pool : sha.id]

}









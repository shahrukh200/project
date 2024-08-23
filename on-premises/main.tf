resource "azurerm_resource_group" "shahrukh2" {
   name     = var.resource_group_name
   location = var.resource_group_location
}

# Create the Virtual Network with address space

resource "azurerm_virtual_network" "shahrukh2_vnet" {
    for_each = var.vnet_details
    name = each.value.vnet_name
    address_space = [each.value.address_space]
    resource_group_name = azurerm_resource_group.shahrukh2.name
    location = azurerm_resource_group.shahrukh2.location
    depends_on = [ azurerm_resource_group.shahrukh2]
}

# Create the Subnets with address prefixes

resource "azurerm_subnet" "subnet" {
  for_each = var.subnet_details
  name = each.key
  address_prefixes = [each.value.address_prefix]
  virtual_network_name = azurerm_virtual_network.shahrukh2_vnet["vnet001"].name
  resource_group_name = azurerm_resource_group.shahrukh2.name
  depends_on = [ azurerm_virtual_network.shahrukh2_vnet]
}

# Create the Public IP for VPN Gateway 

resource "azurerm_public_ip" "public_ips" {
  name = "shahrukh2-VPN-${azurerm_subnet.subnet["GatewaySubnet"].name}-IP"
  location            = azurerm_resource_group.shahrukh2.location
  resource_group_name = azurerm_resource_group.shahrukh2.name
  allocation_method   = "Static"
  sku                 = "Standard"
  depends_on = [ azurerm_resource_group.shahrukh2]
}

# Create the VPN Gateway in their Specified Subnet

resource "azurerm_virtual_network_gateway" "gateway" {
  name                = "shahrukh-VPN-gateway"
  location            = azurerm_resource_group.shahrukh2.location
  resource_group_name = azurerm_resource_group.shahrukh2.name
 
  type     = "Vpn"
  vpn_type = "RouteBased"
  active_active = false
  enable_bgp    = false
  sku           = "VpnGw1"
 
  ip_configuration {
    name                = "shahrukh2"
    public_ip_address_id = azurerm_public_ip.public_ips.id
    private_ip_address_allocation = "Dynamic"
    subnet_id = azurerm_subnet.subnet["GatewaySubnet"].id
  }
  depends_on = [ azurerm_resource_group.shahrukh2 , azurerm_public_ip.public_ips , azurerm_subnet.subnet ]
}


data "azurerm_public_ip" "public_ips" {
name = "GatewaySubnet-ip"
resource_group_name = "hub1"
}

#Fetch the data from Hub Virtual Network (address_space)

data "azurerm_virtual_network" "vnet001" {
  name = "vnet001"
  resource_group_name = "hub1"
}

# Create the Local Network Gateway for VPN Gateway

resource "azurerm_local_network_gateway" "shahrukh2" {
  name                = "shahrukh2"
  location            = azurerm_resource_group.shahrukh2.location
  resource_group_name = azurerm_resource_group.shahrukh2.name
  gateway_address     = data.azurerm_public_ip.public_ips.ip_address
  address_space       = [data.azurerm_virtual_network.vnet001.address_space[0]]
  depends_on = [ azurerm_public_ip.public_ips , azurerm_virtual_network_gateway.gateway , data.azurerm_public_ip.public_ips , data.azurerm_virtual_network.vnet001 ]
}

# Create the VPN-Connection for Connecting the Networks

resource "azurerm_virtual_network_gateway_connection" "vpn_connection" {
  name                = "OnPremises-Hub-vpn-connection"
  location            = azurerm_resource_group.shahrukh2.location
  resource_group_name = azurerm_resource_group.shahrukh2.name
  virtual_network_gateway_id     = azurerm_virtual_network_gateway.gateway.id
  local_network_gateway_id       = azurerm_local_network_gateway.shahrukh2.id
  type                           = "IPsec"
  connection_protocol            = "IKEv2"
  shared_key                     = "YourSharedKey"

  depends_on = [ azurerm_virtual_network_gateway.gateway , azurerm_local_network_gateway.shahrukh2]
}

# Create the Network Interface card for Virtual Machines

resource "azurerm_network_interface" "subnet_nic" {
  name                = "sub-nic"
  resource_group_name = azurerm_resource_group.shahrukh2.name
  location = azurerm_resource_group.shahrukh2.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet["onpremisessubnet002"].id
    private_ip_address_allocation = "Dynamic"
  }
  depends_on = [ azurerm_virtual_network.shahrukh2_vnet , azurerm_subnet.subnet ]
}

# Fetch the data from key vault

data "azurerm_key_vault" "Key_vault" {
  name                = "keyvault001"
  resource_group_name = "Spk1"
}

# Get the username from key vault secret store
data "azurerm_key_vault_secret" "vm_admin_username" {
  name         = "username001"
  key_vault_id = data.azurerm_key_vault.Key_vault.id
}

# Get the password from key vault secret store
data "azurerm_key_vault_secret" "vm_admin_password" {
  name         = "password001"
  key_vault_id = data.azurerm_key_vault.Key_vault.id
}

# Create the Virtual Machines(VM) and assign the NIC to specific VM

resource "azurerm_windows_virtual_machine" "VMs" {
  name = "shahrukh2"
  resource_group_name = azurerm_resource_group.shahrukh2.name
  location = azurerm_resource_group.shahrukh2.location
  size                  = "Standard_DS1_v2"
  admin_username        = data.azurerm_key_vault_secret.vm_admin_username.value
  admin_password        = data.azurerm_key_vault_secret.vm_admin_password.value
  network_interface_ids = [azurerm_network_interface.subnet_nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
  depends_on = [ azurerm_network_interface.subnet_nic , data.azurerm_key_vault_secret.vm_admin_password , data.azurerm_key_vault_secret.vm_admin_username]
}

# Creates the route table

resource "azurerm_route_table" "route_table" {
  name                = "shahrukh2"
  resource_group_name = azurerm_resource_group.shahrukh2.name
  location = azurerm_resource_group.shahrukh2.location
  depends_on = [ azurerm_resource_group.shahrukh2 , azurerm_subnet.subnet ]
}

# Creates the route in the route table (OnPrem-Firewall-Spoke)

resource "azurerm_route" "route001" {
  name                   = "onpremises"
  resource_group_name = azurerm_resource_group.shahrukh2.name
  route_table_name = azurerm_route_table.route_table.name
  address_prefix = "10.3.0.0/16"     
  next_hop_type      = "VirtualNetworkGateway" 
  depends_on = [ azurerm_route_table.route_table ]
}

# Associate the route table with their subnet

resource "azurerm_subnet_route_table_association" "RT-ass" {
   subnet_id                 = azurerm_subnet.subnet["GatewaySubnet"].id
   route_table_id = azurerm_route_table.route_table.id
   depends_on = [ azurerm_subnet.subnet , azurerm_route_table.route_table ]
}
 

resource "azurerm_resource_group" "shahub" {
   name     = var.resource_group_name
   location = var.resource_group_location
}

# create the vm with address space

resource "azurerm_virtual_network" "vnet001" {
    for_each = var.vnet_details
    name = each.value.vnet_name
    address_space = [each.value.address_space]
    resource_group_name = azurerm_resource_group.shahub.name
    location = azurerm_resource_group.shahub.location
    depends_on = [ azurerm_resource_group.shahub ]
}

# create the subnets with address prefixes

resource "azurerm_subnet" "subnet" {
  for_each = var.subnet_details
  name = each.key
  address_prefixes = [each.value.address_prefix]
  virtual_network_name = azurerm_virtual_network.vnet001["vnet001"].name
  resource_group_name = azurerm_resource_group.shahub.name
  depends_on = [ azurerm_virtual_network.vnet001]
}


# create the public ips for azure firewall,vpn gateway and gateway and azure bastion host

resource "azurerm_public_ip" "public_ips" {
  for_each = toset(local.subnet_names)
  name = "${each.key}-ip"
  location = azurerm_resource_group.shahub.location
  resource_group_name = azurerm_resource_group.shahub.name
  allocation_method = "Static"
  sku = "Standard"
  depends_on = [ azurerm_resource_group.shahub ]

}



# create the azure firewall policy

resource "azurerm_firewall_policy" "firewall_policy" {
  name                = "example-firewall-policy"
  location            = azurerm_resource_group.shahub.location
  resource_group_name = azurerm_resource_group.shahub.name
  sku = "Standard"
  depends_on = [ azurerm_resource_group.shahub, azurerm_subnet.subnet ]
}
 
# create the azure firewall to control the outbound traffic

resource "azurerm_firewall" "firewall001" {
  name                = "Firewall001"
  location            = azurerm_resource_group.shahub.location
  resource_group_name = azurerm_resource_group.shahub.name
   sku_name = "AZFW_VNet"
   sku_tier = "Standard"

  ip_configuration {
    name                 = "firewallconfiguration"
    subnet_id            = azurerm_subnet.subnet["AzureFirewallSubnet"].id
    public_ip_address_id = azurerm_public_ip.public_ips["AzureFirewallSubnet"].id
  }
   firewall_policy_id = azurerm_firewall_policy.firewall_policy.id
  depends_on = [ azurerm_resource_group.shahub , azurerm_public_ip.public_ips , 
  azurerm_subnet.subnet , azurerm_firewall_policy.firewall_policy ]
}


# create the ip group to store spoke ip address

resource "azurerm_ip_group" "Ip_group" {
  name = "spk-ip-group"
resource_group_name= azurerm_resource_group.shahub.name
location=azurerm_resource_group.shahub.location
cidrs=["10.2.0.0/16 ,10.3.0.0/16 ,10.4.0.0/16"]
depends_on = [ azurerm_resource_group.shahub ]
}


#  azure firewall policy rule collection

resource "azurerm_firewall_policy_rule_collection_group" "azurerm_firewall_policy_rule_collection" {
name ="app-rule-collection-group"
firewall_policy_id = azurerm_firewall_policy.firewall_policy.id
priority = 100

nat_rule_collection{
  name = "dnat_rule_collection"
  priority = 100
  action = "dnat"

  rule {
    name = "allow-rdp"
    source_addresses = [" 192.168.0.1"]
    destination_ports = ["3389"]
    destination_address = azurerm_public_ip.public_ips["AzureFirewallSubnet"].ip_address
  translated_address = "10.100.2.4"   
      translated_port    = "3389"
      protocols         = ["TCP"]
    }
  }
 
 # Create the Network rule collection for forwarding the traffic betwwen Hub and OnPremises network

  network_rule_collection {    
    name     = "network-rule-collection"
    priority = 200
    action   = "Allow"

    rule {
      name = "allow-spokes"
      source_addresses = [ "10.1.0.0/16" ]    
      destination_addresses = [ "10.3.0.0/16" ] 
      destination_ports = [ "*" ]
      protocols = [ "Any" ]
    }
  }

  depends_on = [ azurerm_firewall.firewall001 , azurerm_ip_group.Ip_group ]
}

# Create the VPN Gateway in their Specified Subnet

resource "azurerm_virtual_network_gateway" "gateway" {
  name                = "Hub-vpn-gateway"
  location            = azurerm_resource_group.shahub.location
  resource_group_name = azurerm_resource_group.shahub.name
 
  type     = "Vpn"
  vpn_type = "RouteBased"
  active_active = false
  enable_bgp    = false
  sku           = "VpnGw1"
 
  ip_configuration {
    name                = "vnetGatewayConfi"
    public_ip_address_id = azurerm_public_ip.public_ips["GatewaySubnet"].id
    private_ip_address_allocation = "Dynamic"
    subnet_id = azurerm_subnet.subnet["GatewaySubnet"].id
  }
  depends_on = [ azurerm_resource_group.shahub , azurerm_public_ip.public_ip , azurerm_subnet.subnet]
}

# Fetch the data from On_premises Gateway Public_IP (IP_address)

data "azurerm_public_ip" "public_ips" {
  name = "shahrukh2-VPN-GatewaySubnet-IP"
  resource_group_name = "shahrukh2"
}

# Fetch the data from On_Premise Virtual Network address_space

data "azurerm_virtual_network" "shahrukh2_vnet" {
  name = "vnet001"
  resource_group_name = "shahrukh2"
}


# Create the Local Network Gateway for VPN Gateway

resource "azurerm_local_network_gateway" "Hub_local_gateway" {
  name                = "Hub-To-OnPremises"
  resource_group_name = azurerm_virtual_network_gateway.gateway.resource_group_name
  location = azurerm_virtual_network_gateway.gateway.location
  gateway_address     = data.azurerm_public_ip.public_ips.ip_address       
  address_space       = [data.azurerm_virtual_network.shahrukh2_vnet.address_space[0]] 

  depends_on = [ azurerm_public_ip.public_ips , azurerm_virtual_network_gateway.gateway , 
              data.azurerm_public_ip.public_ips ,data.azurerm_virtual_network.shahrukh2_vnet ]
}

 # Create the VPN-Connection for Connecting the Networks

resource "azurerm_virtual_network_gateway_connection" "vpn_connection" { 
  name                           = "Hub-OnPremises-vpn-connection"
  resource_group_name = azurerm_virtual_network_gateway.gateway.resource_group_name
  location = azurerm_virtual_network_gateway.gateway.location
  virtual_network_gateway_id     = azurerm_virtual_network_gateway.gateway.id
  local_network_gateway_id       = azurerm_local_network_gateway.Hub_local_gateway.id
  type                           = "IPsec"
  connection_protocol            = "IKEv2"
  shared_key                     = "YourSharedKey" 

  depends_on = [ azurerm_virtual_network_gateway.gateway , azurerm_local_network_gateway.Hub_local_gateway]
}


# Creates the route table

resource "azurerm_route_table" "route_table" {
  name                = "Hub-Gateway-RT"
  resource_group_name = azurerm_resource_group.shahub.name
  location = azurerm_resource_group.shahub.location
  depends_on = [ azurerm_resource_group.shahub , azurerm_subnet.subnet ]
}

# Creates the route in the route table

resource "azurerm_route" "route002" {
  name                   = "spk1"
  resource_group_name = azurerm_route_table.route_table.resource_group_name
  route_table_name = azurerm_route_table.route_table.name
  address_prefix = "10.3.0.0/16"     # destnation network address space
  next_hop_type          = "VirtualAppliance" 
  next_hop_in_ip_address = "10.10.0.4"   # Firewall private IP
  depends_on = [ azurerm_route_table.route_table ]
}

# Associate the route table with the their subnet

resource "azurerm_subnet_route_table_association" "RT-association" {
   subnet_id                 = azurerm_subnet.subnet["GatewaySubnet"].id
   route_table_id = azurerm_route_table.route_table.id
  depends_on = [ azurerm_subnet.subnet , azurerm_route_table.route_table ]
}


# # Creates the policy definition

# resource "azurerm_policy_definition" "resourcegroup_policy_def" {
#   name         = "Hub_resourcegroup-policy"
#   policy_type  = "Custom"
#   mode         = "All"
#   display_name = "Hub Policy"
#   description  = "A policy to demonstrate resource group level policy."
 
#   policy_rule = <<POLICY_RULE
#   {
#     "if": {
#       "field": "location",
#       "equals": "uk south"
#     },
#     "then": {
#       "effect": "deny"
#     }
#   }
#   POLICY_RULE
 
#   metadata = <<METADATA
#   {
#     "category": "General"
#   }
#   METADATA
# }
 
# # Assign the policy
# resource "azurerm_policy_assignment" "example" {
#   name                 = "Hub-resourcegroup-policy-assignment"
#   policy_definition_id = azurerm_policy_definition.rg_policy_def.id
#   scope                = azurerm_resource_groupshahub["Hub_RG"].id
#   display_name         = "Hub_RG Policy Assignment"
#   description          = "Assigning policy to the resource group"
# }

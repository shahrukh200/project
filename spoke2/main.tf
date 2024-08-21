resource "azurerm_resource_group" "spk2" {
  name = var.resource_group_name
  location = var.resource_group_location
}

# create the vnet with address space

resource "azurerm_virtual_network" "vnet001" {                
    name = each.value.vnet_name
    for_each = var.vnet_details
    address_space = [each.value.address_space]
    resource_group_name = azurerm_resource_group.spk2.name
    location = azurerm_resource_group.spk2.location
    depends_on = [ azurerm_resource_group.spk2 ]
}

// Subnet with address prefixes

resource "azurerm_subnet""subnet" {                        
  for_each = var.subnet_details
  name = each.key
  address_prefixes = [each.value.address_prefix]
  virtual_network_name = azurerm_virtual_network.vnet001["Spk2_vnet001"].name
  resource_group_name = azurerm_resource_group.spk2.name
  depends_on = [ azurerm_resource_group.spk2 , azurerm_virtual_network.vnet001 ]
}

// Network Security Group => Nsg with rules

resource "azurerm_network_security_group" "nsg" {
  for_each = toset(local.subnet_names) 
  name = "${each.key}-nsg"
  resource_group_name = azurerm_resource_group.spk2.name 
  location = azurerm_resource_group.spk2.location 
  
       dynamic "security_rule" {

        for_each = { for rule in local.rules_csv: rule.name => rule }
    content {

      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
     }

    depends_on = [ azurerm_subnet.subnet ]
}

# associate the nsg for their subnets

# resource "azurerm_subnet_network_security_group_association" "nsg_association" {
#   for_each = {for id, nsg in azurerm_network_security_group.nsg : id => nsg.id}
#   network_security_group_id = each.value
#   subnet_id = azurerm_subnet.subnet[each.key].id
#   depends_on = [ azurerm_subnet.subnet, azurerm_network_security_group.nsg ]
# }

# create the public ip for application gateway

  resource "azurerm_public_ip" "spk2public-ip" {
  name                = "spk2"
  location            = azurerm_resource_group.spk2.location
  resource_group_name = azurerm_resource_group.spk2.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# create the application for their dedicated subnet
resource "azurerm_application_gateway" "appgw" {
  name                = "spk2gateway"
  resource_group_name = azurerm_resource_group.spk2.name
  location = azurerm_resource_group.spk2.location
  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }
 
  gateway_ip_configuration {
    name      = "spk2"
    subnet_id = azurerm_subnet.subnet["subnet001"].id
  }
 
  frontend_ip_configuration {
    name                 = "appgw-frontend-ip"
    public_ip_address_id = azurerm_public_ip.spk2public-ip.id
  }
 
  frontend_port {
    name = "frontend-port"
    port = 80
  }
 
  backend_address_pool {
    name = "appgw-backend-pool"
  }
 
  backend_http_settings {
    name                  = "appgw-backend-http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 20
  }
 
  http_listener {
    name                           = "appgw-http-listener"
    frontend_ip_configuration_name = "appgw-frontend-ip"
    frontend_port_name             = "frontend-port"
    protocol                       = "Http"
  }
 
  request_routing_rule {
    name                       = "appgw-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "appgw-http-listener"
    backend_address_pool_name  = "appgw-backend-pool"
    backend_http_settings_name = "appgw-backend-http-settings"
  }
    depends_on = [azurerm_resource_group.spk2,azurerm_subnet.subnet ,azurerm_public_ip.spk2public-ip]
}

# Fetch the data from key vault

# data "azurerm_key_vault" "keyvaultt001" {
#   name = "keyvault001"
# resource_group_name="spk2"
# }

# Get the username from key vault secret store

# data "azurerm_key_vault_secret" "vm_admin_password" {
#   name = "spkvmusername"
#   key_vault_id = data.azurerm_key_vault.key_vault_id
#   }

  # Create windows Virtual Machine Scale Set (VMSS)

  # resource "azurerm_windows_virtual_machine_scale_set" "vmscaleset" {
  #   name = "vmscaleset"
  #   resource_group_name = azurerm_resource_group.spk2.name
  #   location = azurerm_resource_group.spk2.location
  #   sku = "standard_ds1-v2"
  #   instances = 2
  #   admin_username = data.azurerm_key_vault_secret.vm_admin_username.value
  #   admin_password = data.azurerm_key_vault_secret.vm_admin_password.value
  #   network_interface {
  #     name = "vmss"
  #     primary = true
  #     ip_configuration {
  #       name = "internal"
  #       subnet_id = azurerm_subnet.subnet["vmss"].id
  #       application_gateway_backend_address_pool_ids = [local.application_gateway_backend_address_pool_ids[0]]
  #     }
  #   }
  #   os_disk {
  #     caching = "readwrite"
  #     storage_account_type = standard_lrs
  #   }
  #   source_image_reference {
  #     publisher = "mswindowserver"
  #     offer = "windowswrver"
  #     sku = "2019-datacenter"
  #     version = latest
  #   }
  # }

    

  # Hub Virtual Network for peering the Spoke_02 Virtual Network (Spk2<--> Hub)


# data "azurerm_virtual_network" "Hub_vnet" {
#   name = "Hubvnet"
#   resource_group_name = "spk2"
# }

# Peering between Spoke_02 and Hub networks (Spk2 <--> Hub)
# resource "azurerm_virtual_network_peering" "spk2" {
#   name                      = "Spk2"
#   resource_group_name       = azurerm_virtual_network.spk2["Spk2"].resource_group_name
#   virtual_network_name      = azurerm_virtual_network.Spk2["Spk2"].name
#   remote_virtual_network_id = data.azurerm_virtual_network.Hub_vnet.id
#   allow_virtual_network_access = true
#   allow_forwarded_traffic   = true
#   allow_gateway_transit     = false
#   use_remote_gateways       = false
#   depends_on = [ azurerm_virtual_network.Spoke_02_vnet , data.azurerm_virtual_network.Hub_vnet  ]
# }

# # Establish the Peering between and Hub Spoke_01 networks (Hub <--> Spk2)
# resource "azurerm_virtual_network_peering" "Hub-Spoke_02" {
#   name                      = "Hub-Spoke_02"
#   resource_group_name       = data.azurerm_virtual_network.Hub_vnet.resource_group_name
#   virtual_network_name      = data.azurerm_virtual_network.Hub_vnet.name
#   remote_virtual_network_id = azurerm_virtual_network.spk2["Spk2vnet"].id
#   allow_virtual_network_access = true
#   allow_forwarded_traffic   = true
#   allow_gateway_transit     = true
#   use_remote_gateways       = false
#   depends_on = [ azurerm_virtual_network.spk2 , data.azurerm_virtual_network.Hub_vnet ]
# }

# # Creates the policy definition
# resource "azurerm_policy_definition" "spk2" {
#   name         = "Spk2-policy"
#   policy_type  = "Custom"
#   mode         = "All"
#   display_name = "Spoke02 Policy"
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
#   name                 = "Spk2-rg-policy-assignment"
#   policy_definition_id = azurerm_policy_definition.rg_policy_def.id
#   scope                = azurerm_resource_group.Spoke_01.id
#   display_name         = "Spoke02_RG Policy Assignment"
#   description          = "Assigning policy to the resource group"
# }
  
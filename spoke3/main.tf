resource "azurerm_resource_group" "Spk3" {
  name     = var.resource_group_name
  location = var.resource_group_location
}

# Create the Virtual Network with address space

resource "azurerm_virtual_network" "Spk3" {
    for_each = var.vnet_details
    name = each.value.vnet_name
    address_space = [each.value.address_space]
    resource_group_name = azurerm_resource_group.Spk3.name
    location = azurerm_resource_group.Spk3.location
    depends_on = [ azurerm_resource_group.Spk3]
}

# Create the Subnets with address prefixes


resource "azurerm_subnet" "subnet" {
  for_each = var.subnet_details
  name = each.key
  address_prefixes = [each.value.address_prefix]
  virtual_network_name = azurerm_virtual_network.Spk3["spk3vnet001"].name
  resource_group_name = azurerm_resource_group.Spk3.name
  delegation {
    name = "appservice"
    service_delegation {
      name = "Microsoft.Web/serverFarms"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action"
      ]
    }
  }
  depends_on = [ azurerm_virtual_network.Spk3 ]
}


 
# Create an App Service Plan

resource "azurerm_app_service_plan" "appplan" {
  name                = "app_service_plan_name"
  location            = azurerm_resource_group.Spk3.location
  resource_group_name = azurerm_resource_group.Spk3.name
  sku {
    tier = "Standard"
    size = "S1"
  }
  depends_on = [ azurerm_resource_group.Spk3]
}

# Create the Web App

resource "azurerm_app_service" "webapplication" {
  name                = var.web_app_name
  location            = azurerm_resource_group.Spk3.location
  resource_group_name = azurerm_resource_group.Spk3.name
  app_service_plan_id = azurerm_app_service_plan.appplan.id

  
  depends_on = [azurerm_resource_group.Spk3 , azurerm_app_service_plan.appplan]
}

# Enable the Virtual Network Integration to App services

resource "azurerm_app_service_virtual_network_swift_connection" "vent001" {
  app_service_id = azurerm_app_service.webapplication.id
  subnet_id = azurerm_subnet.subnet["spk3subnet001"].id
  depends_on = [ azurerm_app_service.webapplication , azurerm_subnet.subnet ]
}



data "azurerm_virtual_network" "vnet001" {
  name = "vnet001"
  resource_group_name = "hub1"
}


#establish the peering between spk1 & hub networks(spoke3-hub)


resource "azurerm_virtual_network_peering" "Spk3-To-hub1" {
  name                      = "Spk3-to-hub"
  resource_group_name       = azurerm_virtual_network.Spk3["spk3vnet001"].resource_group_name
  virtual_network_name      = azurerm_virtual_network.Spk3["spk3vnet001"].name
  remote_virtual_network_id = data.azurerm_virtual_network.vnet001.id
  allow_virtual_network_access = true
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
  use_remote_gateways       = false
  depends_on = [ azurerm_virtual_network.Spk3 , data.azurerm_virtual_network.vnet001 ]
}

# Establish the Peering between and Hub Spoke1 networks (Hub-Spoke_03)


resource "azurerm_virtual_network_peering" "Hub-Spk3" {
  name                      = "Hub-Spk3"
  resource_group_name       = data.azurerm_virtual_network.vnet001.resource_group_name
  virtual_network_name      = data.azurerm_virtual_network.vnet001.name
  remote_virtual_network_id = azurerm_virtual_network.Spk3["spk3vnet001"].id
  allow_virtual_network_access = true
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
  use_remote_gateways       = false
  depends_on = [ azurerm_virtual_network.Spk3 , data.azurerm_virtual_network.vnet001 ]
}



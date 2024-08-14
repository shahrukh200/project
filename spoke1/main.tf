data "azurerm_client_config" "current" {}
data "azuread_client_config" "current" {}

// resource group

resource "azurerm_resource_group" "spk1" {                 
    name = var.resource_group_name
    location = var.resource_group_location
}

// create the virtual network with address space

resource "azurerm_virtual_network" "spk1vnet001" {
  for_each = var.virtual_network               
    name = each.value.venet_name
    address_space = [each.value.address_space]
    resource_group_name = azurerm_resource_group.spk1.name
    location = azurerm_resource_group.spk1.location
    depends_on = [ azurerm_resource_group.spk1 ]
}

// Subnet with address prefixes

resource "azurerm_subnet" "subnet" {                        
  for_each = var.subnet_details
  name = each.key
  address_prefixes = [each.value.address_prefix]
  virtual_network_name = azurerm_virtual_network.spk1vnet001["spk1vnet001"].name
  resource_group_name = azurerm_resource_group.spk1.name
  depends_on = [ azurerm_virtual_network.spk1vnet001]
}

// Network Security Group => Nsg with rules

resource "azurerm_network_security_group" "nsg" {
  for_each = toset (local.subnet_names)
  name = each.key
  resource_group_name = azurerm_resource_group.spk1.name
  location = azurerm_resource_group.spk1.location

  dynamic "security_rule" {
    for_each = {for rule in locals.rules_csv: rule.name => rule}
    content {
      name = security_rule.value.name
      priority = security_rule.value.priority
      direction = security_rule.value.direction
      access = security_rule.value.access
      protocol = security_rule.value.protocol
      source_port_range = security_rule.value.source_port_range
      destination_port_range = security_rule.value.destination_port_range
      source_address_prefix = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
      
    }
  }
  depends_on = [ azurerm_subnet.subnet ]
}
//nsg for subnets
resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  for_each = {for id,subnet in azurerm_subnet.subnet  : id => subnet.id}
  subnet_id = each.value
  network_security_group_id  = azurerm_network_security_group.nsg[local.nsg_names[each.key]].id
  depends_on = [ azurerm_network_security_group.nsg ]
}

// create Nic for vm

resource "azurerm_network_interface" "subnet_nic" {
  for_each = toset(local.subnet_names)
  name = "${each.key}-nic"
  resource_group_name = azurerm_resource_group.spk1.name
  location = azurerm_resource_group.spk1.location

  ip_configuration {
    name = "internal"
    subnet_id = azurerm_subnet.subnet[each.key].id
    private_ip_address_allocation = "Dynamic"
  }
  depends_on = [ azurerm_subnet.subnet ]
}

// Keyvault

resource "azurerm_key_vault" "Key_vault" {
  name                        = var.key_vault_name
  resource_group_name = azurerm_resource_group.spk1.name
  location = azurerm_resource_group.spk1.location
  sku_name                    = "standard"
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  purge_protection_enabled    = true
  soft_delete_retention_days = 30
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azuread_client_config.current.object_id
 
    secret_permissions = [
      "Get",
      "Set",
      "backup",
      "delete",
      "purge",
      "list",
      "recover",
      "restore",
    ]
  }
  depends_on = [ azurerm_resource_group.spk1 ]
}

// Key vault Username

resource "azurerm_key_vault_secret" "vm_admin_username" {
  name         = "username001"
  value        = var.admin_username
  key_vault_id = azurerm_key_vault.Key_vault.id
  depends_on = [ azurerm_key_vault.Key_vault ]
}

resource "azurerm_key_vault_secret" "vm_admin_password" {
  name         = "password001"
  value        = var.admin_password
  key_vault_id = azurerm_key_vault.Key_vault.id
  depends_on = [ azurerm_key_vault.Key_vault ]
}


// virtual machine

resource "azurerm_windows_virtual_machine" "spk1vm" {
for_each = {for id, nic in azurerm_network_interface.subnet_nic : id => nic.id}
  name                = "${azurerm_subnet.subnet[local.nsg_names[each.key]].name}-vm" 
  location            = azurerm_resource_group.spk1.location
  resource_group_name = azurerm_resource_group.spk1.name
  size                = "Standard_B1s"
  admin_username      = azurerm_key_vault_secret.vm_admin_username.value
  admin_password      = azurerm_key_vault_secret.vm_admin_password.value
  
  # for_each=local.nic_names

  network_interface_ids = [each.value]

  # zone=each.key

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

#   zone = var.availability_zones

depends_on = [ azurerm_resource_group.spk1, azurerm_subnet.subnet, azurerm_network_interface.nic ]
}

// storage account file share

resource "azurerm_storage_account" "stg-act" {
  name                     = var.storage_account_name
  resource_group_name = azurerm_resource_group.spk1.name
  location                 = azurerm_resource_group.spk1.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  depends_on = [ azurerm_resource_group.spk1 ]
}

//fileshare in storage account
resource "azurerm_storage_share" "fileshare" {
  name                 = var.file_share_name
  storage_account_name = azurerm_storage_account.stg-act
  quota                = 10

  depends_on = [ azurerm_resource_group.spk1, azurerm_storage_account.stg-act ]
}

// mount fileshare to vm

resource "azurerm_virtual_machine_extension" "vm-mount" {
  name                 = "spk1-vm-extension"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm["sp01-subnet1"].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  protected_settings = <<SETTINGS
 {
   "commandToExecute": "powershell -command \"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${local.base64EncodedScript }')) | Out-File -filepath postBuild.ps1\" && powershell -ExecutionPolicy Unrestricted -File postBuild.ps1"
}
  SETTINGS

  depends_on = [azurerm_windows_virtual_machine.VM]
   
}


# Create data disk
resource "azurerm_managed_disk" "data_disk" {
  name                 = var.data_disk_name
  resource_group_name = azurerm_resource_group.spk1.name
  location = azurerm_resource_group.spk1.location
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "4"
  depends_on = [ azurerm_windows_virtual_machine.VM ]
}

# Attach the data disk to the virtual machine
resource "azurerm_virtual_machine_data_disk_attachment" "Attach" {
  managed_disk_id    = azurerm_managed_disk.data_disk.id
  virtual_machine_id = azurerm_windows_virtual_machine.VM["vm1"].id
  lun                = 0
  caching            = "ReadWrite"
  depends_on = [ azurerm_windows_virtual_machine.VM , azurerm_managed_disk.data_disk ]
}

# Fetch the data from Hub Virtual Network for peering the Spoke_01 Virtual Network (Spoke_01 <--> Hub)
data "azurerm_virtual_network" "Hub_vnet" {
  name = "Hub_vnet"
  resource_group_name = "spk1"
}

# Establish the Peering between Spoke_01 and Hub networks (Spoke_01 <--> Hub)
resource "azurerm_virtual_network_peering" "spk1-To-Hub" {
  name                      = "Spk1-To-Hub"
  resource_group_name       = azurerm_virtual_network.spk1vnet001["spk1venet001"].var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.spk1vnet001["spk1venet001"].name
  remote_virtual_network_id = data.azurerm_virtual_network.Hub_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
  use_remote_gateways       = false
  depends_on = [ azurerm_virtual_network.spk1vnet001 , data.azurerm_virtual_network.Hub_vnet]
}

# Establish the Peering between and Hub Spoke_01 networks (Hub <--> Spoke_01)
resource "azurerm_virtual_network_peering" "Hub-Spk1" {
  name                      = "Hub-Spk1"
  resource_group_name       = data.azurerm_virtual_network.Hub_vnet.resource_group_name
  virtual_network_name      = data.azurerm_virtual_network.Hub_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.spk1vnet001["spk1venet001"].id
  allow_virtual_network_access = true
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
  use_remote_gateways       = false
  depends_on = [ azurerm_virtual_network.spk1vnet001_vnet , data.azurerm_virtual_network.Hub_vnet ]
}


# Creates the policy definition
# resource "azurerm_policy_definition" "rg_policy_def" {
#   name         = "Spk1_rg-policy"
#   policy_type  = "Custom"
#   mode         = "All"
#   display_name = "Spk1 Policy"
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
#   name                 = "Spk1-rg-policy-assignment"
#   policy_definition_id = azurerm_policy_definition.rg_policy_def.id
#   scope                = azurerm_resource_group.Spk1["Spk1"].id
#   display_name         = "Spk1 Policy Assignment"
#   description          = "Assigning policy to the resource group"
# }

# # Creates the Log Analytics workspace 
# resource "azurerm_log_analytics_workspace" "log_analytics" {
#   name                = "example-law"
#   resource_group_name = azurerm_resource_group.Spk1.name
#   location = azurerm_resource_group.Spk1.location
#   sku                 = "PerGB2018"
#   retention_in_days   = 10
# }

# # 
# resource "azurerm_monitor_diagnostic_setting" "vnet_monitor" {
#   name               = "diag-settings-vnet"
#   target_resource_id = azurerm_virtual_network.spk["Spk1vnet001"].id
#   log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics.id
 
#   log {
#     category = "NetworkSecurityGroupEvent"
#     enabled  = true
 
#     retention_policy {
#       enabled = false
#     }
#   }
# }
 
# resource "azurerm_monitor_diagnostic_setting" "vm_monitor" {
#   name               = "diag-settings-vm"
#   target_resource_id = azurerm_windows_virtual_machine.VM[each.key].id
#   log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id
 
#   log {
#     category = "GuestOSUpdate"
#     enabled  = true
 
#     retention_policy {
#       enabled = false
#     }
#   }
 
#   metric {
#     category = "AllMetrics"
#     enabled  = true
 
#     retention_policy {
#       enabled = false
#     }
#   }
# }


# # Create Recovery Services Vault
# resource "azurerm_recovery_services_vault" "vault" {
#   name                = "exampleRecoveryServicesVault"
#   location            = azurerm_resource_group.spk1.location
#   resource_group_name = azurerm_resource_group.spk1.name
#   sku                 = "Standard"
# }
 
# # Create Backup Policy
# resource "azurerm_backup_policy_vm" "backup_policy" {
#   name                = "exampleBackupPolicy"
#   resource_group_name = azurerm_resource_group.spk1.name
#   recovery_vault_name = azurerm_recovery_services_vault.vault.name
 
#   retention_daily {
#     count = 7
#   }
 
#   backup {
#     frequency = "Daily"
#     time      = "23:00"
#   }
# }
 
# # Enable Backup for VM
# resource "azurerm_backup_protected_vm" "protected_vm" {
#   resource_group_name    = azurerm_resource_group.spk1.name
#   recovery_vault_name    = azurerm_recovery_services_vault.vault.name
#   source_vm_id           = azurerm_virtual_machine.vm.id
#   backup_policy_id       = azurerm_backup_policy_vm.backup_policy.id
# }
 
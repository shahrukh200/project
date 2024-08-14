# variable "rg_details" {
#   type = map(object({
#     rg_name = string
#     rg_location = string
#   }))
#   default = {
#     "Hub_RG" = {
#       rg_name = "shahub"
#       rg_location = "uk south"
#     }
#   }
# }

# variable "vnet_details" {
#   type = map(object({
#     vnet_name = string
#     address_space = string
#   }))
#   default = {
#     "Hub_vnet" = {
#       vnet_name = "shavnet"
#       address_space = "10.1.0.0/16"
#     }
#   }
# }

# variable "subnet_details" {
#   type = map(object({
#     subnet_name = string
#     address_prefix = string
#   }))
#   default = {
#     "AzureFirewallSubnet" = {
#         subnet_name = "AzureFirewallsubnet"
#         address_prefix = "10.10.0.0/26"
#     },

#     "GatewaySubnet" = {
#       subnet_name = "GatewaySubnet"
#       address_prefix = "10.10.1.0/27"
#     },
    
#     "AzureBastionSubnet" = {
#         subnet_name = "AzureBastionSubnet"
#         address_prefix = "10.10.2.0/24"
#     } 
#   }
# }

# variable "appService_subnet" {
#   type = map(object({
#     subnet_name = string
#     address_prefix = string
#   }))
#   default = {
#     "AppServiceSubnet" = {
#       subnet_name = "subnet001"
#       address_prefix = "10.10.3.0/27"
#     }
#   }
# }

variable "resource_group_name" {
  type = string
  description = "name of resource group"
  validation {
    condition = length(var.resource_group_name)>0
    error_message = "name must be provided"
  }
  
}
variable "resource_group_location" {
  type = string
  description = "location of the resource group"
  validation {
    condition = length(var.resource_group_location)>0
    error_message = "location must be provided"
  }
  
}

variable "vnet_details" {
  type = map(object({
    vnet_name =string
    address_space=string 
  }))
  description = "detials of the vnet"
  
}
variable "subnet_details" {
  type =map(object({
    subnet_name =string
    address_prefix=string 
  }))
  description = "details of the subnets"
  
}
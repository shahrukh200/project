# variable "rg" {
#   type = map(object({
#     rg_name = string
#     rg_location = string
#   }))
#   default = {
#     "On_Premises_RG" = {
#       rg_name = "shahrukh0"
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
#     "On_Premises_vnet" = {
#       vnet_name = "On_Premises_vnet"
#       address_space = "10.100.0.0/16"
#     }
#   }
# }

# variable "subnet_details" {
#   type = map(object({
#     subnet_name = string
#     address_prefix = string
#   }))
#   default = {
#     "shahrukh" = {
#       subnet_name = "subnet002"
#       address_prefix = "10.1.1.0/24"
#     },
    
#     "DB" = {
#         subnet_name = "subnet002"
#         address_prefix = "10.1.2.0/24"
#     }
#   }
# }


# variable "admin_username" {
#   type        = string
#   default = "azureuser"
# }

# variable "admin_password" {
#   type        = string
#   default = "pass@word1234"
#   sensitive   = true
# }

variable "resource_group_name" {
  type = string
  description = "name of resource"
  validation {
    condition = length(var.resource_group_name)>0
    error_message = "name must be provided"
  }
  
}

  variable "resource_group_location" {
    type = string
    description = "location of resource group"
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
    description = "details of vnet"
    
  }
  variable "subnet_details" {
    type = map(object({
      vnet_name =string
      address_space=string 
    }))
    description = "details of the subnet"
  }
  
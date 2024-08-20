# variable "resource_group_name" {
#   type = string
#   default = "spk2"
  
# }
# variable "resource_group_location" {
#   type = string
#   default = "uk south"
  
# }
# variable "virtual_network_name" {
#   type = string
#   default = "spk2-vnet001"
  
# }
# variable "virtual_network_address_space" {
#   type = string
#   default = "10.4.0.0/16"
  
# }
# variable "subnet_details" {
# type =map(object({
#   name =string
#   address_prefix = string 
# }))
# default = {
#   "spk2-subnet001" = {
#     name="spk2-subnet001"
#     address_prefix="10.4.1.0/24"
    
#   },
#    "spk2-subnet002" = {
#     name="spk2-subnet002"
#     address_prefix="10.4.2.0/24"
    
#   }
# }
    
#   }

# variable "rules_file" {
#   type        = string
#   default     = "rules.csv"
  
# }
# variable "admin_username" {
#   type = string
#   default = "azureuser"
  
# }
# variable "admin_password" {
#   type = string
#   default = "mohamed123"
#   sensitive = true
  
# }


variable "resource_group_name" {
  type = string
  description = "name of the resource group"
  validation {
    condition = length(var.resource_group_name)>0
    error_message = "name must be provided"
  
  }
  
}

variable "resource_group_location" {
  type = string
  description = "location of the resource group"
  validation {

    condition = length (var.resource_group_location)>0
    error_message = "location must be provided"
  }
  
}
variable "vnet_details" {
    type = map(object({
    vnet_name =string
    address_prefix=string 
  }))
  description = "detials of the vnet"
  
}
variable "subnet_details" {
  type = map(object({
    subnet_name =string
    address_prefix=string 
  }))
  description = "detials of the subnet"
  
}

variable "rules_file" {
  type = string
  description = "name of csv file containing nsg rule"
  default = "rules.csv"
  
}

variable "admin_username" {
  type = string
  default = "adminuser"
  
}
variable "admin_password" {
  type = string
  default = "mohamed@s200"
  sensitive = true
  
}






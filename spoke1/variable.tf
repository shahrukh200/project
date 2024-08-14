# variable "resource_group_name" {
#   type = string
#   default = "spk1"
# }

# variable "resource_group_location" {
#   type = string
#   default = "uk south"
# }

# variable "virtual_network_name" {
#     type = string
#     default = "spk1vnet001"
# }

# variable "virtual_network_address_space" {
#     type = string
#     default = "10.3.0.0/16"
# }

# variable "subnet_details" {
#     type = map(object({
#       name = string
#       address_prefix = string
#     }))
#     default = {
#       "spk1-subnet001" = {
#         name = "spk1-subnet001"
#         address_prefix = "10.3.1.0/24"    //subnet1-nsg subnet-nsg
#       },
#       "spk1-subnet002" = {
#         name = "spk1-subnet002"
#         address_prefix = "10.3.2.0/24"   
#       }

#     }
  
# }

# # variable "vm_count" {
# #   type = number
# #   default = 2
# # }

# # variable "availability_zones" {
# #   type    = list(string)
# #   default = ["1", "2"]
# # }

# variable "admin_username" {
#   type = string
#   default = "mohamed"
# }

# variable "admin_password" {
#   type = string
#   default = "mohamedas200"
#   sensitive = true
# }




variable "resource_group_name" {
  type = string
  description = "resource-group-name"
  validation {
    condition = length(var.resource_group_name)>0
    error_message = "resource group name must be provided  "
  }
}
variable "resource_group_location" {
  type = string
  description = "resource-group-location"
  validation {
    condition = length(var.resource_group_location)>0
    error_message = "resource group location must be provided"
  }
  
}
variable "virtual_network" {
  type = map(object({
    virtual_network_name = string
    address_space=string 
  }))
  description = "virtual network detials"
  validation {
    condition = length(var.virtual_network)>0
    error_message = "at least one virtual network must be defined"
  } 
}
variable "subnet_details" {
  type = map(object({
    subnet_name = string
    address_prefix=string
  }))
  description = "subnet_detials"
  validation {
    condition = length(var.subnet_details)>0
    error_message = "at least two subnet must be provided"
  }
  
}
variable "rule_file" {
  type = string
  description = "the name csv file contaning nsg rules"
  default = "rules.csv"
  
}
variable "admin_username" {
  type = string
  description = "the username of the user"
  
}

variable "admin_password" {
  type = string
  description = "password of the user"
  sensitive = true
  
}
variable "key_vault_name" {
  type = string
  description = "name of the key vault"
  
}
variable "storage_account_name" {
  type = string
  description = "name of the storage account"
  
}
variable "file_share_name" {
  type = string
  description = "name of file share"
  
}
variable "data_disk_name" {
  type = string
  description = "name of data disk"
  
}
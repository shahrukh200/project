
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
  description = "subnet_details"
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

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
      subnet_name =string
      address_prefix=string 
    }))
    description = "details of the subnet"
  }
  
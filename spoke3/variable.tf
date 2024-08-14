# 


variable "resource_group_name" {
  type = string
  description = "name of resource group"
  validation {
condition =length(var.resource_group_name)>0
error_message = "name must be provided"    
  }
  
}
variable "resource_group_location" {
  type = string
  description = "resource group location"
  validation {
    condition = length(var.resource_group_location)>0
    error_message = "location must be provided"
  }
  
}
variable "vnet_details" {
  type = map(object({
    vnet_name = string
    address_space=string
  }))
  description = "details of the snet"
  
}
variable "subnet_details" {
  type = map(object({
    subnet_name =string
    address_prefix=string 
  }))
  description = "details of the subnets"
  
}
variable "app_service_plan_name" {
  type = string
  default = "name of app service plan"
  
}

variable "web_app_name" {
  type = string
  default = "name of web app name"
  
}





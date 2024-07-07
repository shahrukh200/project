variable "ms" {
    type = map(object({
      name = string
      address_prefixes=string
    }))
    default = {
        "subnet001"={
            name="subnet001"
            address_prefixes="10.1.1.0/24"

        },
        "subnet002"={
            name="subnet002"
            address_prefixes="10.1.2.0/24"

        }

      
        
      }
    }
  

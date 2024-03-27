variable "env" {
  type    = string
  default = "e2e"
}
variable "hostname" {
  type    = string
  default = "test.com"
}

variable "rg" {
  type    = string
  default = "staging"
}

variable "location" {
  type    = string
  default = "North Central US"
}

variable "suffix" {
  type    = string
  default = "e2e"
}



variable "tags" {
  description = "Default tags to apply to all resources."
  type        = map(any)
}


variable "app_service_plans" {
  description = "Map of Azure App Service Plan configurations"
  type        = map(object({
    sku_name = string
  }))
  default = {
    cgapps_asp = {
      sku_name = "B1"
    }
    cgfuncation_asp = {
      sku_name = "B1"
    }
  }
}

variable "storage_accounts" {
  description = "Map of storage account configurations"
  type        = map(object({
    account_tier             = string
    account_replication_type = string
    account_kind             = string
    access_tier              = string
  }))
  default = {
    concretego_storage_account = {
      account_tier             = "Standard"
      account_replication_type = "LRS"
      account_kind             = "StorageV2"
      access_tier              = "Hot"
    }
    eventhub_storage_account = {
      account_tier             = "Standard"
      account_replication_type = "LRS"
      account_kind             = "StorageV2"
      access_tier              = "Hot"
    }
  }
}


variable "redis_caches" {
  description = "Map of Azure Redis Cache configurations"
  type        = map(object({
    sku_name            = string
    capacity            = number
    family              = string
    maxmemory_reserved  = number
    maxmemory_policy    = string
  }))
  default = {
    concretego_redis_cache = {
      sku_name            = "Standard"
      capacity            = 0
      family              = "C"
      maxmemory_reserved  = 35
      maxmemory_policy    = "volatile-lru"
    }

    # Add more configurations 
  }
}

variable "concretego_zone_id" {
  description = "The AWS Route 53 Zone ID for the concretego.com domain"
  type        = string
  default     = "Z1D3I1VIJKY1XN"
}

variable "cg_sysdyne_cloud_zone_id" {
  description = "The AWS Route 53 Zone ID for the cg.sysdyne.cloud domain"
  type        = string
  default     = "Z10414221EAE9E7BKFO1"
}

variable "dispatchsysdb" {
  description = "Password for the SQL Azure database"
  type        = string
}

variable "dbserver_central_us" {
  description = "Connection string for DB Server Central US"
   type        = string
}

variable "dbserver_east_au_0" {
  description = "Connection string for DB Server East AU 0"
   type        = string
}

variable "dbserver_east_us" {
  description = "Connection string for DB Server East US"
   type        = string
}

variable "dbserver_north_central_us" {
  description = "Connection string for DB Server North US"
   type        = string
}

variable "dbserver_north_central_us_0" {
  description = "Connection string for DB Server North US 0"
   type        = string
}

variable "dbserver_south_central_us_0" {
  description = "Connection string for DB Server South US 0"
   type        = string
}


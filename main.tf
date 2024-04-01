
# resource "azurerm_resource_group" "concretego-demo" {
#   tags     = merge(var.tags, {})
#   name     = "concretego-${var.suffix}"
#   location = var.location
# }


resource "azurerm_service_plan" "concretego-ASP" {
  tags                = merge(var.tags, {})
  sku_name            = var.app_service_plans["cgapps_asp"].sku_name
  resource_group_name = "concretego-${var.rg}"
  os_type             = "Windows"
  name                = "concretego-${var.suffix}"
  location            = var.location
}

resource "azurerm_windows_web_app" "concretego" {
  tags                = merge(var.tags, {})
  service_plan_id     = azurerm_service_plan.concretego-ASP.id
  resource_group_name = "concretego-${var.rg}"
  name                = "concretego-${var.suffix}"
  location            = var.location
  https_only          = true

 identity {
    type = "SystemAssigned"
  }

  app_settings = {
    RedisConnectionString = azurerm_redis_cache.concretego-redis_cache.primary_connection_string
    ApplicationInsightsAgent_EXTENSION_VERSION = "~2"
    XDT_SiteXmlTransform = "<?xml version=\"1.0\" encoding=\"utf-8\"?><configuration xmlns:xdt=\"http://schemas.microsoft.com/XML-Document-Transform\"><system.webServer><proxy xdt:Transform=\"InsertIfMissing\" enabled=\"true\" preserveHostHeader=\"false\" reverseRewriteHostInResponseHeaders=\"false\" /></system.webServer></configuration>"
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.concretego-application-insights.instrumentation_key
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.concretego-application-insights.connection_string
    DBSERVER_CENTRAL_US = var.dbserver_central_us
    DBSERVER_EAST_AU_0 = var.dbserver_east_au_0
    DBSERVER_EAST_US = var.dbserver_east_us
    DBSERVER_NORTH_CENTRAL_US = var.dbserver_north_central_us
    DBSERVER_NORTH_CENTRAL_US_0 = var.dbserver_north_central_us_0
    DBSERVER_SOUTH_CENTRAL_US_0 = var.dbserver_south_central_us_0
  }

  connection_string {
    value = var.dispatchsysdb
    type  = "SQLAzure"
    name  = "DispatchSysDB"
  }

  site_config {
    always_on = true
    use_32_bit_worker = false   # Setting to false enables 64-bit platform
    application_stack {
      dotnet_version = "v6.0"
      current_stack  = "dotnet"
    }
    http2_enabled            = true  # This is required for session affinity
    websockets_enabled       = true   # Enable Web Sockets
    ftps_state               = "Disabled"  # Disable FTPS

  }
}


resource "azurerm_application_insights" "concretego-application-insights" {
  tags                = merge(var.tags, {})
  resource_group_name = "concretego-${var.rg}"
  name                = "concretego-${var.suffix}"
  location            = var.location
  application_type    = "web"
}

resource "azurerm_application_insights" "concretego-api-application-insights" {
  tags                = merge(var.tags, {})
  resource_group_name = "concretego-${var.rg}"
  name                = "concretego-api-${var.suffix}"
  location            = var.location
  application_type    = "web"
}



resource "azurerm_template_deployment" "concretego_IISManager" {
  name                = "IISManagerExtensionDeployment"
  resource_group_name = "concretego-${var.rg}"
  deployment_mode     = "Incremental"
  template_body       = file("${path.module}/arm_templates/iis_manager_extension.json")

  parameters = {
    siteName = azurerm_windows_web_app.concretego.name
  }
}


resource "azurerm_windows_web_app" "concretego-api" {
  tags                = merge(var.tags, {})
  service_plan_id     = azurerm_service_plan.concretego-ASP.id
  resource_group_name = "concretego-${var.rg}"
  name                = "concretego-api-${var.suffix}"
  location            = var.location
  https_only          = true
  client_affinity_enabled = true  # Session Affinity
  identity {
    type = "SystemAssigned"
  }
  app_settings = {
    ASPNETCORE_ENVIRONMENT = "${var.env}"
    ApplicationInsightsAgent_EXTENSION_VERSION = "~2"
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.concretego-api-application-insights.instrumentation_key    
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.concretego-api-application-insights.connection_string
    KeyVaultUri = azurerm_key_vault.concretego-kv.vault_uri
  }
  connection_string {
    value = var.dbserver_east_au_0
    type  = "SQLAzure"
    name  = "DBSERVER_EAST_AU_0"
  }
   connection_string {
    value = var.dbserver_east_us
    type  = "SQLAzure"
    name  = "DBSERVER_EAST_US"
  }
   connection_string {
    value = var.dbserver_north_central_us
    type  = "SQLAzure"
    name  = "DBSERVER_NORTH_CENTRAL_US"
  }
   connection_string {
    value = var.dbserver_north_central_us_0
    type  = "SQLAzure"
    name  = "DBSERVER_NORTH_CENTRAL_US_0"
  }

    connection_string {
    value = var.dbserver_south_central_us_0
    type  = "SQLAzure"
    name  = "DBSERVER_SOUTH_CENTRAL_US_0"
  }
    connection_string {
    value = var.dispatchsysdb
    type  = "SQLAzure"
    name  = "DefaultConnection"
  }

  site_config {
    always_on          = true
    use_32_bit_worker = false   # Setting to false enables 64-bit platform
    application_stack {
      dotnet_version = "v6.0"
      current_stack  = "dotnet"
    }
    http2_enabled            = true  # This is required for session affinity
    websockets_enabled       = true   # Enable Web Sockets
    ftps_state               = "Disabled"  # Disable FTPS
  }
}


resource "azurerm_redis_cache" "concretego-redis_cache" {
  tags                = merge(var.tags, {})
  sku_name            = var.redis_caches["concretego_redis_cache"].sku_name
  resource_group_name = "concretego-${var.rg}"
  name                = "concretego-${var.suffix}"
  location            = var.location
  family              = var.redis_caches["concretego_redis_cache"].family
  capacity            = var.redis_caches["concretego_redis_cache"].capacity

  redis_configuration {
    maxmemory_reserved = var.redis_caches["concretego_redis_cache"].maxmemory_reserved
    maxmemory_policy   = var.redis_caches["concretego_redis_cache"].maxmemory_policy
  }
}

resource "azurerm_storage_account" "concretego-storage_account" {
  tags                     = merge(var.tags, {})
  resource_group_name      = "concretego-${var.rg}"
  name                     = "concretego${var.suffix}"
  location                 = var.location
  account_tier             = var.storage_accounts["concretego_storage_account"].account_tier
  account_replication_type = var.storage_accounts["concretego_storage_account"].account_replication_type
  account_kind             = var.storage_accounts["concretego_storage_account"].account_kind
  access_tier              = var.storage_accounts["concretego_storage_account"].access_tier
}

# Custom domain bindings for concretego Azure Web App
resource "azurerm_app_service_custom_hostname_binding" "concretego_custom_domain" {
  for_each            = toset(local.default_custom_domains_concretego[var.env])
  hostname            = each.value
  app_service_name    = azurerm_windows_web_app.concretego.name
  resource_group_name = azurerm_windows_web_app.concretego.resource_group_name

  # Add SSL certificate configuration here
  ssl_state   = "SniEnabled"  # Enable SNI-based SSL
  thumbprint  = each.value == "e2e.concretego.com" ? local.concretego_ssl_thumbprint : local.cg_sysdyne_cloud_ssl_thumbprint
}

# Custom domain bindings for concretego-api Azure Web App
resource "azurerm_app_service_custom_hostname_binding" "concretego_api_custom_domain" {
  for_each            = toset(local.default_custom_domains_concretego_api[var.env])
  hostname            = each.value
  app_service_name    = azurerm_windows_web_app.concretego-api.name
  resource_group_name = azurerm_windows_web_app.concretego-api.resource_group_name

  # Add SSL certificate configuration here
  ssl_state   = "SniEnabled"  # Enable SNI-based SSL
  thumbprint  = each.value == "api-e2e.concretego.com" ? local.concretego_ssl_thumbprint : null  # Assuming concretego-api does not use cg.sysdyne.cloud SSL
}


# Define AWS Route 53 record resources for concretego Azure Web App (CNAME)
resource "aws_route53_record" "concretego_cname_records" {
  zone_id   = var.concretego_zone_id
  name      = "${var.env}.concretego.com"
  type      = "CNAME"
  ttl       = 300
  records   = [azurerm_windows_web_app.concretego.default_hostname]
}

resource "aws_route53_record" "concretego_sysdyne_cname_records" {
  zone_id   = var.cg_sysdyne_cloud_zone_id
  name      = "${var.env}.cg.sysdyne.cloud"
  type      = "CNAME"
  ttl       = 300
  records   = [azurerm_windows_web_app.concretego.default_hostname]
}

# Define AWS Route 53 record resources for concretego-api Azure Web App (CNAME)
resource "aws_route53_record" "concretego_api_cname_records" {
  for_each  = toset(local.default_custom_domains_concretego_api[var.env])
  zone_id   = var.concretego_zone_id
  name      = each.value
  type      = "CNAME"
  ttl       = 300
  records   = [azurerm_windows_web_app.concretego-api.default_hostname]
}


# Define AWS Route 53 record resources for concretego Azure Web App (TXT)
resource "aws_route53_record" "concretego_txt_records" {
  zone_id   = var.concretego_zone_id
  name      = "asuid.${var.env}.concretego.com"
  type      = "TXT"
  ttl       = 300
  records   = [azurerm_windows_web_app.concretego.custom_domain_verification_id]
}

# Define AWS Route 53 record resources for concretego-api Azure Web App (TXT)
resource "aws_route53_record" "concretego_api_txt_records" {
  for_each  = toset(local.default_custom_domains_concretego_api[var.env])
  zone_id   = var.concretego_zone_id  # Use the zone ID for concretego-api domain
  name      = "asuid.${each.value}"
  type      = "TXT"
  ttl       = 300
  records   = [azurerm_windows_web_app.concretego-api.custom_domain_verification_id]
}


# Define AWS Route 53 record resources for e2e.cg.sysdyne.cloud TXT record for concretego Azure Web App
resource "aws_route53_record" "concretego_sysdyne_txt_record" {
  zone_id   = var.cg_sysdyne_cloud_zone_id  # Use the zone ID for concretego domain
  name      = "asuid.${var.env}.cg.sysdyne.cloud"
  type      = "TXT"
  ttl       = 300
  records   = [azurerm_windows_web_app.concretego.custom_domain_verification_id]
}

# Define the Azure Key Vault resource
resource "azurerm_key_vault" "concretego-kv" {
  tenant_id           = var.tenant_id
  tags                = merge(var.tags, {})
  sku_name            = "standard"
  resource_group_name = "concretego-${var.rg}"
  name                = "concretego-${var.suffix}"
  location            = var.location
}

resource "azurerm_key_vault_access_policy" "concretego_vnext_full_access" {
  tenant_id           = var.tenant_id
  key_vault_id        = azurerm_key_vault.concretego-kv.id
  object_id           = var.object_id
  secret_permissions  = ["Get", "List", "Set", "Delete", "Backup", "Restore", "Recover"]
  key_permissions     = ["Get", "List", "Create", "Update", "Import", "Delete", "Backup", "Restore", "Recover"]
  certificate_permissions = ["Get", "List", "Create", "Update", "Import", "Delete", "Backup", "Restore", "Recover"]
}

resource "azurerm_key_vault_access_policy" "concretego_get_list_access" {
  tenant_id          = var.tenant_id
  key_vault_id       = azurerm_key_vault.concretego-kv.id
  object_id          = azurerm_windows_web_app.concretego.identity[0].principal_id
  secret_permissions = ["Get", "List"]
}



resource "azurerm_key_vault_access_policy" "concretego-api_get_list_access" {
  tenant_id          = var.tenant_id
  key_vault_id       = azurerm_key_vault.concretego-kv.id
  object_id          = azurerm_windows_web_app.concretego-api.identity[0].principal_id
  secret_permissions = ["Get", "List"]
}



# Add secrets to the Azure Key Vault
resource "azurerm_key_vault_secret" "dbserver_central_us" {
  name         = "ConnectionStrings--DBSERVER-CENTRAL-US"
  value        = var.dbserver_central_us
  key_vault_id = azurerm_key_vault.concretego-kv.id
}

resource "azurerm_key_vault_secret" "dbserver_east_au_0" {
  name         = "ConnectionStrings--DBSERVER-EAST-AU-0"
  value        = var.dbserver_east_au_0
  key_vault_id = azurerm_key_vault.concretego-kv.id
}

resource "azurerm_key_vault_secret" "dbserver_east_us" {
  name         = "ConnectionStrings--DBSERVER-EAST-US"
  value        = var.dbserver_east_us
  key_vault_id = azurerm_key_vault.concretego-kv.id
}

resource "azurerm_key_vault_secret" "dbserver_north_central_us" {
  name         = "ConnectionStrings--DBSERVER-NORTH-CENTRAL-US"
  value        = var.dbserver_north_central_us
  key_vault_id = azurerm_key_vault.concretego-kv.id
}

resource "azurerm_key_vault_secret" "dbserver_north_central_us_0" {
  name         = "ConnectionStrings--DBSERVER-NORTH-CENTRAL-US-0"
  value        = var.dbserver_north_central_us_0
  key_vault_id = azurerm_key_vault.concretego-kv.id
}

resource "azurerm_key_vault_secret" "dbserver_south_central_us_0" {
  name         = "ConnectionStrings--DBSERVER-SOUTH-CENTRAL-US-0"
  value        = var.dbserver_south_central_us_0
  key_vault_id = azurerm_key_vault.concretego-kv.id
}

# Add a secret for Blob Storage connection string
resource "azurerm_key_vault_secret" "blob_connection_string" {
  name         = "BlobConnectionString"
  value        = "azurerm_storage_account.concretego-storage_account.primary_blob_connection_string"
  key_vault_id = azurerm_key_vault.concretego-kv.id
}

# Add a secret for Blob Storage connection string
resource "azurerm_key_vault_secret" "sso_client_secret" {
  for_each     = local.selected_secrets
  name         = "Sso--ClientSecret"
  value        = each.value
  key_vault_id = azurerm_key_vault.concretego-kv.id
}






























# resource "azurerm_resource_group" "webcrete" {
#   tags     = merge(var.tags, {})
#   name     = "webcrete${var.suffix}"
#   location = var.location
# }

# resource "azurerm_service_plan" "concretego-funcation-service_plan" {
#   tags                = merge(var.tags, {})
#   sku_name            = var.app_service_plans["cgfuncation_asp"].sku_name
#   resource_group_name = azurerm_resource_group.webcrete.name
#   os_type             = "Windows"
#   name                = "concretego-${var.suffix}-Funcation-ASP"
#   location            = var.location
# }

# resource "azurerm_storage_account" "eventhub-storage_account" {
#   tags                     = merge(var.tags, {})
#   resource_group_name      = azurerm_resource_group.webcrete.name
#   name                     = "eventhubcnewcg${var.suffix}"
#   location                 = var.location
#   account_tier             = var.storage_accounts["eventhub_storage_account"].account_tier
#   account_replication_type = var.storage_accounts["eventhub_storage_account"].account_replication_type
#   account_kind             = var.storage_accounts["eventhub_storage_account"].account_kind
#   access_tier              = var.storage_accounts["eventhub_storage_account"].access_tier
# }

# resource "azurerm_windows_function_app" "eventhub-function-app" {
#   tags                       = merge(var.tags, {})
#   storage_account_name       = azurerm_storage_account.eventhub-storage_account.name
#   storage_account_access_key = azurerm_storage_account.eventhub-storage_account.primary_access_key
#   service_plan_id            = azurerm_service_plan.concretego-funcation-service_plan.id
#   resource_group_name        = azurerm_resource_group.webcrete.name
#   name                       = "eventhubcgnew-${var.suffix}"
#   location                   = var.location

#   site_config {
#     always_on = true
#   }
# }


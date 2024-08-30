terraform {
  required_version = "~> 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.74"
    }
  }
}

provider "azurerm" {
  features {}
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = ">=0.3.0"
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "this" {
  location = "eastus"
  name     = "edgio-cdn-${module.naming.resource_group.name_unique}"
}

resource "azurerm_storage_account" "storage" {
  account_replication_type      = "ZRS"
  account_tier                  = "Standard"
  location                      = azurerm_resource_group.this.location
  name                          = module.naming.storage_account.name_unique
  resource_group_name           = azurerm_resource_group.this.name
  public_network_access_enabled = false
}

# This is the module call
module "azurerm_cdn_profile" {
  source = "../../"
  tags = {
    environment = "avm-demo"
  }
  enable_telemetry    = var.enable_telemetry
  name                = module.naming.cdn_profile.name_unique
  location            = azurerm_resource_group.this.location
  sku                 = "Standard_Verizon"
  resource_group_name = azurerm_resource_group.this.name
  cdn_endpoints = {
    ep1 = {
      name                          = "endpoint-${module.naming.cdn_endpoint.name_unique}"
      is_http_allowed               = true
      is_https_allowed              = true
      querystring_caching_behaviour = "BypassCaching"
      is_compression_enabled        = true
      optimization_type             = "GeneralWebDelivery"
      geo_filters = { # Only one geo filter allowed for Standard_Microsoft sku
        gf1 = {
          relative_path = "/" # Must be / for Standard_Microsoft sku
          action        = "Block"
          country_codes = ["AF", "GB"]
        }
        gf2 = {
          relative_path = "/foo"
          action        = "Allow"
          country_codes = ["AF", "GB"]
        }
      }
      content_types_to_compress = [
        "application/eot",
        "application/font",
        "application/font-sfnt",
        "application/javascript",
        "application/json",
        "application/opentype",
        "application/otf",
        "application/pkcs7-mime",
        "application/truetype",
        "application/ttf",
        "application/vnd.ms-fontobject",
        "application/xhtml+xml",
        "application/xml",
        "application/xml+rss",
        "application/x-font-opentype",
        "application/x-font-truetype",
        "application/x-font-ttf",
        "application/x-httpd-cgi",
        "application/x-javascript",
        "application/x-mpegurl",
        "application/x-opentype",
        "application/x-otf",
        "application/x-perl",
        "application/x-ttf",
        "font/eot",
        "font/ttf",
        "font/otf",
        "font/opentype",
        "image/svg+xml",
        "text/css",
        "text/csv",
        "text/html",
        "text/javascript",
        "text/js",
        "text/plain",
        "text/richtext",
        "text/tab-separated-values",
        "text/xml",
        "text/x-script",
        "text/x-component",
        "text/x-java-source",
      ]
      origin_host_header = replace(replace(azurerm_storage_account.storage.primary_blob_endpoint, "https://", ""), "/", "")
      origin_path        = "/media"
      probe_path         = "/foo.bar"
      origins = {
        og1 = { name = "origin1"
          host_name = replace(replace(azurerm_storage_account.storage.primary_blob_endpoint, "https://", ""), "/", "")
        }
      }
      diagnostic_setting = {
        name                        = "storage_diag"
        log_groups                  = ["allLogs"] # you can set either log_categories or log_groups.
        storage_account_resource_id = azurerm_storage_account.storage.id
        #marketplace_partner_resource_id          = "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/{partnerResourceProvider}/{partnerResourceType}/{partnerResourceName}"
      }
    }
  }
  managed_identities = {
    system_assigned = true
  }

# cdn_endpoint_custom_domains = {
#       cdn1 = {
#         cdn_endpoint_key = "ep1"
#         host_name        = "www.example.com"
#         name             = "example"
#         cdn_managed_https = {
#           certificate_type = "Shared"
#           protocol_type    = "ServerNameIndication"
#           tls_version      = "TLS12"
#         }
#       }
#     }

  diagnostic_settings = {
    workspaceandstorage_diag1 = {
      name                           = "workspaceandstorage_diag"
      log_groups                     = ["allLogs"] #must explicitly set since log_groups defaults to ["allLogs"]
      log_analytics_destination_type = "Dedicated"
      #workspace_resource_id          = azurerm_log_analytics_workspace.workspace.id
      storage_account_resource_id = azurerm_storage_account.storage.id
      #marketplace_partner_resource_id          = "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/{partnerResourceProvider}/{partnerResourceType}/{partnerResourceName}"
    }

  }

  role_assignments = {
    self_contributor = {
      role_definition_id_or_name       = "Contributor"
      principal_id                     = data.azurerm_client_config.current.object_id
      skip_service_principal_aad_check = true
      principal_type                   = "User"
    },
    role_assignment_2 = {
      role_definition_id_or_name       = "Reader"
      principal_id                     = data.azurerm_client_config.current.object_id #"125****-c***-4f**-**0d-******53b5**" # replace the principal id with appropriate one
      description                      = "Example role assignment 2 of reader role"
      skip_service_principal_aad_check = false
      principal_type                   = "User"
      #condition                        = "@Resource[Microsoft.Storage/storageAccounts/blobServices/containers:ContainerName] StringEqualsIgnoreCase 'foo_storage_container'"
      #condition_version                = "2.0"
    }
  }

}

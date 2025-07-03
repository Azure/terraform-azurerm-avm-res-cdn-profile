terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  # subscription_id = "your-subscription-id" # Replace with your Azure subscription ID
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = ">=0.3.0"
}

resource "azurerm_resource_group" "this" {
  location = "eastus"
  name     = "ms-cdn-${module.naming.resource_group.name_unique}"
}

resource "azurerm_storage_account" "storage" {
  account_replication_type      = "ZRS"
  account_tier                  = "Standard"
  location                      = azurerm_resource_group.this.location
  name                          = module.naming.storage_account.name_unique
  resource_group_name           = azurerm_resource_group.this.name
  public_network_access_enabled = false
}

# Uncheck below block if your custom domain is hosted in Azure DNS as per https://learn.microsoft.com/en-us/azure/dns/dns-delegate-domain-azure-dns and a DNS zone is already pre-created
# data "azurerm_dns_zone" "dns" {
#   name                = "azure.example.com"
#   resource_group_name = "DNS"
# }


# This is the module call
module "azurerm_cdn_profile" {
  source = "../../"

  location            = azurerm_resource_group.this.location
  name                = module.naming.cdn_profile.name_unique
  resource_group_name = azurerm_resource_group.this.name
  cdn_endpoints = {
    ep1 = {
      name                          = "endpoint-${module.naming.cdn_endpoint.name_unique}"
      is_http_allowed               = false
      is_https_allowed              = true
      querystring_caching_behaviour = "BypassCaching"
      is_compression_enabled        = true
      optimization_type             = "GeneralWebDelivery"
      geo_filters = { # Only one geo filter allowed for Standard_Microsoft sku
        gf1 = {
          relative_path = "/" # Must be '/' for Standard_Microsoft sku
          action        = "Block"
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
  diagnostic_settings = {
    workspaceandstorage_diag = {
      name              = "workspaceandstorage_diag"
      metric_categories = ["AllMetrics"]
      #log_categories                 = ["FrontDoorAccessLog", "FrontDoorHealthProbeLog", "FrontDoorWebApplicationFirewallLog"]
      log_groups                     = ["allLogs"] # must explicitly set since log_groups defaults to ["allLogs"]
      log_analytics_destination_type = "Dedicated"
      storage_account_resource_id    = azurerm_storage_account.storage.id
      #marketplace_partner_resource_id          = "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/{partnerResourceProvider}/{partnerResourceType}/{partnerResourceName}"
    }

  }
  enable_telemetry = var.enable_telemetry
  managed_identities = {
    system_assigned = true
  }
  sku = "Standard_Microsoft"
  tags = {
    environment = "avm-CDN-demo"
  }
}

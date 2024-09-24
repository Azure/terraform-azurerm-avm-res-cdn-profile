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
  tags = {
    environment = "avm-demo"
  }
  enable_telemetry    = var.enable_telemetry
  name                = module.naming.cdn_profile.name_unique
  location            = azurerm_resource_group.this.location
  sku                 = "Standard_Microsoft"
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
  # Uncheck below block to add custom domain to the CDN endpoint [ctrl + '/']
  # cdn_endpoint_custom_domains = {
  #   cdn1 = {
  #     cdn_endpoint_key = "ep1"
  #     dns_zone = {
  #       is_azure_dns_zone                  = true                           # set it to false if your domain is hosted outside Azure DNS
  #       name                               = data.azurerm_dns_zone.dns.name # Provide the DNS zone name if your domain is hosted outside Azure DNS
  #       cname_record_name                  = "www"
  #       ttl                                = 300
  #       tags                               = { environment = "avm-demo" }
  #       azure_dns_zone_resource_group_name = data.azurerm_dns_zone.dns.resource_group_name # Only required if DNS is hosted in Azure
  #     }
  #     name = "example-domain"
  #     cdn_managed_https = {
  #       certificate_type = "Dedicated"
  #       protocol_type    = "ServerNameIndication"
  #       tls_version      = "TLS12"
  #     }
  #   }
  # }

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

  managed_identities = {
    system_assigned = true
  }
}

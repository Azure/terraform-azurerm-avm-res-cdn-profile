terraform {
  required_version = ">= 1.3.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.7.0, < 4.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see https://aka.ms/avm/telemetryinfo.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
}

module "regions" {
  source  = "Azure/regions/azurerm"
  version = ">= 0.3.0"
}

# This is required for resource modules
# resource "azurerm_resource_group" "this" {
#   name     = module.naming.resource_group.name_unique
#   location = "centralindia"
# }

resource "azurerm_resource_group" "this" {
  location = "centralindia"
  name     = module.naming.resource_group.name_unique
}

resource "azurerm_dns_zone" "dnszone" {
  name                = "somedomain.asdwk.com"
  resource_group_name = azurerm_resource_group.this.name
}


# This is the module call
module "azurerm_cdn_profile" {
  #depends_on = [ data.azurerm_resource_group.this ]
  # source = "/workspaces/terraform-azurerm-avm-res-cdn-profile"
  source = "../../"
  tags = {
    environment = "production"
  }
  enable_telemetry    = true
  name                = module.naming.cdn_profile.name_unique
  location            = azurerm_resource_group.this.location
  sku_name            = "Standard_Microsoft"
  resource_group_name = azurerm_resource_group.this.name
  cdn_endpoints = {
    ep1 = {
      name                          = "endpoint-${module.naming.cdn_endpoint.name_unique}"
      is_http_allowed               = true
      is_https_allowed              = true
      querystring_caching_behaviour = "BypassCaching"
      is_compression_enabled        = true
      optimization_type             = "GeneralWebDelivery"
      #geo_filters = {}
      geo_filters = { # Only one geo filter allowed for Standard_Microsoft sku
        gf1 = {
          relative_path = "/" # Must be / for Standard_Microsoft sku
          action        = "Block"
          country_codes = ["AF", "GB"]
        }
        # gf2 = {
        #   relative_path = "/foo" 
        #   action        = "Allow"
        #   country_codes = ["AF", "GB"]
        # }
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
      origin_host_header = "ddsharedstorage.blob.core.windows.net"
      origin_path        = "/media"
      probe_path         = "/foo.bar"
      origins = {
        og1 = { name = "origin1"
          host_name = "ddsharedstorage.blob.core.windows.net"
        }
      }
      global_delivery_rules = {
        gdr1 = {
          cache_expiration_action = {
            behavior = "Override"
            duration = "1.10:30:00"
          }
          cache_key_query_string_action = {
            behavior   = "Include"
            parameters = "*"
          }
        }
      }
    }
  }
  cdn_endpoint_custom_domains = {
    cd1 = {
      name             = "example-domain"
      cdn_endpoint_key = "ep1"
      host_name        = "foo.bar"
    }
  }
  managed_identities = {
    system_assigned = true
  }
}
output "cdn_profile" {
  value = module.azurerm_cdn_profile.system_assigned_mi_principal_id
}
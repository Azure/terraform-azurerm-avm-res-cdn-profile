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
  version = "0.3.0"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = "eastus"
  name     = module.naming.resource_group.name_unique
}

# storage account origin which will be connected to private link
resource "azurerm_storage_account" "storage" {
  account_replication_type      = "ZRS"
  account_tier                  = "Standard"
  location                      = azurerm_resource_group.this.location
  name                          = module.naming.storage_account.name_unique
  resource_group_name           = azurerm_resource_group.this.name
  public_network_access_enabled = false
}

# Create a virtual network
resource "azurerm_virtual_network" "vnet" {
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.this.location
  name                = "my-vnet"
  resource_group_name = azurerm_resource_group.this.name
}

# Create a subnet within the virtual network
resource "azurerm_subnet" "subnet" {
  address_prefixes     = ["10.0.0.0/24"]
  name                 = "my-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}
# Create a private endpoint for the storage account
resource "azurerm_private_endpoint" "storage_endpoint" {
  location            = azurerm_resource_group.this.location
  name                = "storage-endpoint"
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = azurerm_subnet.subnet.id

  private_service_connection {
    is_manual_connection           = false
    name                           = "storage-connection"
    private_connection_resource_id = azurerm_storage_account.storage.id
    subresource_names              = ["blob"]
  }
}

# Create a private DNS zone for the storage account
resource "azurerm_private_dns_zone" "storage_dns_zone" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.this.name
}

# Link the private DNS zone to the virtual network
resource "azurerm_private_dns_zone_virtual_network_link" "dns_link" {
  name                  = "dns-link"
  private_dns_zone_name = azurerm_private_dns_zone.storage_dns_zone.name
  resource_group_name   = azurerm_resource_group.this.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

# This is the module call
module "azurerm_cdn_frontdoor_profile" {
  source              = "../../"
  enable_telemetry    = var.enable_telemetry
  name                = module.naming.cdn_profile.name_unique
  location            = azurerm_resource_group.this.location
  sku                 = "Premium_AzureFrontDoor"
  resource_group_name = azurerm_resource_group.this.name
  front_door_origin_groups = {
    og1 = {
      name = "og1"
      health_probe = {
        hp1 = {
          interval_in_seconds = 240
          path                = "/healthProbe"
          protocol            = "Https"
          request_type        = "HEAD"
        }
      }
      load_balancing = {
        lb1 = {
          additional_latency_in_milliseconds = 0
          sample_size                        = 16
          successful_samples_required        = 3
        }
      }
    }
  }
  front_door_origins = {
    origin1 = {
      name                           = "example-origin1"
      origin_group_name              = "og1"
      enabled                        = true
      certificate_name_check_enabled = true
      host_name                      = replace(replace(azurerm_storage_account.storage.primary_blob_endpoint, "https://", ""), "/", "")
      http_port                      = 80
      https_port                     = 443
      host_header                    = replace(replace(azurerm_storage_account.storage.primary_blob_endpoint, "https://", ""), "/", "")
      priority                       = 1
      weight                         = 1
      private_link = {
        pl = {
          request_message        = "Please approve this private link connection"
          target_type            = "blob"
          location               = azurerm_storage_account.storage.location
          private_link_target_id = azurerm_storage_account.storage.id
        }
      }
    }
  }

  front_door_endpoints = {
    ep-1 = {
      name = "ep-1"
      tags = {
        ENV = "example"
      }
    }
  }

  front_door_routes = {
    route1 = {
      name                   = "route1"
      endpoint_name          = "ep-1"
      origin_group_name      = "og1"
      origin_names           = ["example-origin1"]
      https_redirect_enabled = true
      patterns_to_match      = ["/*"]
      supported_protocols    = ["Http", "Https"]
      rule_set_names         = ["ruleset1"]
      cache = {
        cache1 = {
          query_string_caching_behavior = "IgnoreSpecifiedQueryStrings"
          query_strings                 = ["account", "settings"]
          compression_enabled           = true
          content_types_to_compress     = ["text/html", "text/javascript", "text/xml"]
        }
      }
    }
  }

  front_door_rule_sets = ["ruleset1"]

  front_door_rules = {
    rule1 = {
      name              = "examplerule1"
      order             = 1
      behavior_on_match = "Continue"
      rule_set_name     = "ruleset1"
      origin_group_name = "og1"
      actions = {

        url_rewrite_action = {
          actiontype              = "url_rewrite_action"
          source_pattern          = "/"
          destination             = "/index3.html"
          preserve_unmatched_path = false
        }
        route_configuration_override_action = {
          set_origin_groupid            = true
          actiontype                    = "route_configuration_override_action"
          forwarding_protocol           = "HttpsOnly"
          query_string_caching_behavior = "IncludeSpecifiedQueryStrings"
          query_string_parameters       = ["foo", "clientIp={client_ip}"]
          compression_enabled           = true
          cache_behavior                = "OverrideIfOriginMissing"
          cache_duration                = "365.23:59:59"
        }
        response_header_action = {
          header_action = "Append"
          header_name   = "headername"
          value         = "/abc"
        }
        request_header_action = {
          header_action = "Append"
          header_name   = "headername"
          value         = "/abc"
        }
      }
      conditions = {
        remote_address_condition = {
          operator         = "IPMatch"
          negate_condition = false
          match_values     = ["10.0.0.0/23"]
        }

        query_string_condition = {
          negate_condition = false
          operator         = "BeginsWith"
          match_values     = ["J", "K"]
          transforms       = ["Uppercase"]
        }

        request_header_condition = {
          header_name      = "headername"
          negate_condition = false
          operator         = "BeginsWith"
          match_values     = ["J", "K"]
          transforms       = ["Uppercase"]
        }

        request_body_condition = {
          negate_condition = false
          operator         = "BeginsWith"
          match_values     = ["J", "K"]
          transforms       = ["Uppercase"]
        }

        request_scheme_condition = {
          negate_condition = false
          operator         = "Equal"
          match_values     = ["HTTP"]
        }

        url_path_condition = {
          negate_condition = false
          operator         = "BeginsWith"
          match_values     = ["J", "K"]
          transforms       = ["Uppercase"]
        }

        url_file_extension_condition = {
          negate_condition = false
          operator         = "BeginsWith"
          match_values     = ["J", "K"]
          transforms       = ["Uppercase"]
        }

        url_filename_condition = {
          negate_condition = false
          operator         = "BeginsWith"
          match_values     = ["J", "K"]
          transforms       = ["Uppercase"]
        }

        http_version_condition = {
          negate_condition = false
          operator         = "Equal"
          match_values     = ["2.0"]
        }

        cookies_condition = {
          cookie_name      = "cookie"
          negate_condition = false
          operator         = "BeginsWith"
          match_values     = ["J", "K"]
          transforms       = ["Uppercase"]
        }
      }
    }
  }
}




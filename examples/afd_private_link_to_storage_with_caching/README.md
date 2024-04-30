<!-- BEGIN_TF_DOCS -->
# Default example

This deploys the module in its simplest form.

```hcl
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
  # source = "/workspaces/terraform-azurerm-avm-res-cdn-profile"
  source              = "../../"
  enable_telemetry    = true
  name                = module.naming.cdn_profile.name_unique
  location            = azurerm_resource_group.this.location
  sku_name            = "Premium_AzureFrontDoor"
  resource_group_name = azurerm_resource_group.this.name
  origin_groups = {
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
  origin = {
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

  endpoints = {
    ep-1 = {
      name = "ep-1"
      tags = {
        ENV = "example"
      }
    }
    ep-2 = {
      name = "ep-2"
      tags = {
        ENV = "example2"
      }
    }
  }

  routes = {
    route1 = {
      name                   = "route1"
      endpoint_name          = "ep-1"
      origin_group_name      = "og1"
      origin_names           = ["example-origin", "origin3"]
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

  rule_sets = ["ruleset1", "ruleset2"]

  rules = {
    rule3 = {
      name              = "examplerule3"
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
        # url_redirect_action = {
        #   redirect_type        = "PermanentRedirect"
        #   redirect_protocol    = "MatchRequest"
        #   query_string         = "clientIp={client_ip}"
        #   destination_path     = "/exampleredirection"
        #   destination_hostname = "contoso.com"
        #   destination_fragment = "UrlRedirect"
        # }
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

        # request_method_condition = {
        #   operator         = "Equal"
        #   negate_condition = false
        #   match_values     = ["www.contoso1.com", "images.contoso.com", "video.contoso.com"]
        # }

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

        # socket_address_condition = {
        #   operator         = "IPMatch"
        #   negate_condition = false
        #   match_values     = ["5.5.5.64/26"]
        # }

        # client_port_condition = {
        #   operator         = "Equal"
        #   negate_condition = false
        #   match_values     = ["Mobile"]
        # }

        # server_port_condition = {
        #   operator         = "Equal"
        #   negate_condition = false
        #   match_values     = ["80"]
        # }

        # ssl_protocol_condition = {
        #   operator         = "Equal"
        #   negate_condition = false
        #   match_values     = ["TLSv1"]
        # }

        # request_uri_condition = {
        #   negate_condition = false
        #   operator         = "BeginsWith"
        #   match_values     = ["J", "K"]
        #   transforms       = ["Uppercase"]
        # }


        # host_name_condition = {
        #   operator         = "Equal"
        #   negate_condition = false
        #   match_values     = ["www.contoso1.com", "images.contoso.com", "video.contoso.com"]
        #   transforms       = ["Lowercase", "Trim"]
        # }

        # is_device_condition = {
        #   operator         = "Equal"
        #   negate_condition = false
        #   match_values     = ["Mobile"]
        # }

        # post_args_condition = {
        #   post_args_name = "customerName"
        #   operator       = "BeginsWith"
        #   match_values   = ["J", "K"]
        #   transforms     = ["Uppercase"]
        # }

        # request_method_condition = {
        #   operator         = "Equal"
        #   negate_condition = false
        #   match_values     = ["DELETE"]
        # }

        # url_filename_condition = {
        #   operator         = "Equal"
        #   negate_condition = false
        #   match_values     = ["media.mp4"]
        #   transforms       = ["Lowercase", "RemoveNulls", "Trim"]
        # }
      }
    }
  }
}



```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.3.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.7.0, < 4.0.0)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (>= 3.7.0, < 4.0.0)

- <a name="provider_random"></a> [random](#provider\_random)

## Resources

The following resources are used by this module:

- [azurerm_private_dns_zone.storage_dns_zone](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) (resource)
- [azurerm_private_dns_zone_virtual_network_link.dns_link](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) (resource)
- [azurerm_private_endpoint.storage_endpoint](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) (resource)
- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_storage_account.storage](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) (resource)
- [azurerm_subnet.subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_virtual_network.vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) (resource)
- [random_integer.region_index](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see https://aka.ms/avm/telemetryinfo.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_azurerm_cdn_frontdoor_profile"></a> [azurerm\_cdn\_frontdoor\_profile](#module\_azurerm\_cdn\_frontdoor\_profile)

Source: ../../

Version:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: 0.3.0

### <a name="module_regions"></a> [regions](#module\_regions)

Source: Azure/regions/azurerm

Version: >= 0.3.0

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->
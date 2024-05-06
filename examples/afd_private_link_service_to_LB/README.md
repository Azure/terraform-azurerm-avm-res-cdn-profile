<!-- BEGIN_TF_DOCS -->
# Default example

This deploys the module in its simplest form.

```hcl
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
  location = "centralindia"
  name     = module.naming.resource_group.name_unique
}

# Create a virtual network
resource "azurerm_virtual_network" "vnet" {
  address_space       = ["10.5.0.0/16"]
  location            = azurerm_resource_group.this.location
  name                = "my-vnet"
  resource_group_name = azurerm_resource_group.this.name
}

# Create a subnet within the virtual network
resource "azurerm_subnet" "subnet" {
  address_prefixes                              = ["10.5.1.0/24"]
  name                                          = "my-subnet"
  resource_group_name                           = azurerm_resource_group.this.name
  virtual_network_name                          = azurerm_virtual_network.vnet.name
  private_link_service_network_policies_enabled = false
}

# Create an Internal Load balancer resource 
resource "azurerm_lb" "lb" {
  location            = azurerm_resource_group.this.location
  name                = "lb-example"
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "AFD-lb-IP"
    private_ip_address_allocation = "Dynamic"
    private_ip_address_version    = "IPv4"
    subnet_id                     = azurerm_subnet.subnet.id
    zones                         = ["1", "2"]
  }
}

# Create Private link service
resource "azurerm_private_link_service" "pls" {
  load_balancer_frontend_ip_configuration_ids = [azurerm_lb.lb.frontend_ip_configuration[0].id]
  location                                    = azurerm_resource_group.this.location
  name                                        = "pls-example"
  resource_group_name                         = azurerm_resource_group.this.name

  nat_ip_configuration {
    name                       = "primary"
    primary                    = true
    subnet_id                  = azurerm_subnet.subnet.id
    private_ip_address_version = "IPv4"
  }
}

# This is the module call
module "azurerm_cdn_frontdoor_profile" {
  #source              = "/workspaces/terraform-azurerm-avm-res-cdn-profile"
  source              = "../../"
  depends_on          = [azurerm_private_link_service.pls]
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
      host_name                      = "example.com"
      http_port                      = 80
      https_port                     = 443
      host_header                    = "example.com"
      priority                       = 1
      weight                         = 1
      private_link = {
        pl = {
          request_message        = "Please approve this private link connection"
          location               = azurerm_resource_group.this.location
          private_link_target_id = azurerm_private_link_service.pls.id
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
      forwarding_protocol    = "HttpsOnly"
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

  front_door_rule_sets = ["ruleset1", "ruleset2"]

  front_door_rules = {
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

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.5)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 3.74)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (~> 3.74)

## Resources

The following resources are used by this module:

- [azurerm_lb.lb](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb) (resource)
- [azurerm_private_link_service.pls](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_link_service) (resource)
- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_subnet.subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_virtual_network.vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) (resource)

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

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->
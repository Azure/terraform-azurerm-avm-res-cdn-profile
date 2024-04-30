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

data "azurerm_client_config" "current" {}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = "eastus"
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
  depends_on          = [azurerm_private_link_service.pls, time_sleep.wait_30_seconds]
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

  endpoints = {
    ep-1 = {
      name = "ep-1"
      tags = {
        ENV = "example"
      }
    }
  }

  routes = {
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

resource "time_sleep" "wait_30_seconds" {
  create_duration = "60s"

  depends_on = [azurerm_private_link_service.pls]
}
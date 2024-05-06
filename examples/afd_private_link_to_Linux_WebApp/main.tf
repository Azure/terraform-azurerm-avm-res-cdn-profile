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

# Creating App service plan with premium V3 SKU
resource "azurerm_service_plan" "appservice" {
  location            = azurerm_resource_group.this.location
  name                = "my-appservice"
  os_type             = "Linux"
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "P1v3"
}

# Creating the linux web app
resource "azurerm_linux_web_app" "webapp" {
  location                      = azurerm_resource_group.this.location
  name                          = "my-LinuxWebApp"
  resource_group_name           = azurerm_resource_group.this.name
  service_plan_id               = azurerm_service_plan.appservice.id
  https_only                    = true
  public_network_access_enabled = false

  site_config {
    minimum_tls_version = "1.2"
  }
}

#  Deploy code from a public GitHub repo
resource "azurerm_app_service_source_control" "sourcecontrol" {
  app_id                 = azurerm_linux_web_app.webapp.id
  branch                 = "master"
  repo_url               = "https://github.com/Azure-Samples/nodejs-docs-hello-world"
  use_manual_integration = true
  use_mercurial          = false
}

# This is the module call
module "azurerm_cdn_frontdoor_profile" {
  #source = "/workspaces/terraform-azurerm-avm-res-cdn-profile"
  source                   = "../../"
  enable_telemetry         = var.enable_telemetry
  name                     = module.naming.cdn_profile.name_unique
  location                 = azurerm_resource_group.this.location
  sku                      = "Premium_AzureFrontDoor"
  resource_group_name      = azurerm_resource_group.this.name
  response_timeout_seconds = 120
  tags                     = { environment = "example" }
  front_door_origin_groups = {
    og1 = {
      name = "og1"
      health_probe = {
        hp1 = {
          interval_in_seconds = 100
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
      host_name                      = replace(replace(azurerm_linux_web_app.webapp.default_hostname, "https://", ""), "/", "")
      http_port                      = 80
      https_port                     = 443
      host_header                    = replace(replace(azurerm_linux_web_app.webapp.default_hostname, "https://", ""), "/", "")
      priority                       = 1
      weight                         = 500
      private_link = {
        pl = {
          request_message        = "Please approve this private link connection"
          target_type            = "sites"
          location               = azurerm_linux_web_app.webapp.location
          private_link_target_id = azurerm_linux_web_app.webapp.id
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
    ep-2 = {
      name = "ep-2"
      tags = {
        ENV = "example2"
      }
    }
  }

  front_door_routes = {
    route1 = {
      name                   = "route1"
      endpoint_name          = "ep-1"
      origin_group_name      = "og1"
      origin_names           = ["example-origin", "origin3"]
      forwarding_protocol    = "HttpsOnly"
      https_redirect_enabled = true
      patterns_to_match      = ["/*"]
      supported_protocols    = ["Http", "Https"]
      rule_set_names         = ["ruleset1"]
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




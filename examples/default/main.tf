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
  version = ">= 0.3.0"
}

resource "azurerm_resource_group" "this" {
  location = "eastus"
  name     = "afd_default-${module.naming.resource_group.name_unique}"
}

# This is the module call
module "azurerm_cdn_frontdoor_profile" {
  source = "../../"

  location            = azurerm_resource_group.this.location
  name                = module.naming.cdn_profile.name_unique
  resource_group_name = azurerm_resource_group.this.name
  enable_telemetry    = var.enable_telemetry
  front_door_endpoints = {
    ep1_key = {
      name = "ep1-${module.naming.cdn_endpoint.name_unique}"
      tags = {
        environment = "avm-demo"
      }
    }
    ep2_key = {
      name = "ep2-${module.naming.cdn_endpoint.name_unique}"
    }
  }
  front_door_origin_groups = {
    og1_key = {
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
    origin1_key = {
      name                           = "origin1"
      origin_group_key               = "og1_key"
      enabled                        = true
      certificate_name_check_enabled = false
      host_name                      = "contoso.com"
      http_port                      = 80
      https_port                     = 443
      host_header                    = "www.contoso.com"
      priority                       = 1
      weight                         = 1
    }
    origin2_key = {
      name                           = "origin2"
      origin_group_key               = "og1_key"
      enabled                        = true
      certificate_name_check_enabled = false
      host_name                      = "contoso1.com"
      http_port                      = 80
      https_port                     = 443
      host_header                    = "www.contoso1.com"
      priority                       = 1
      weight                         = 1
    }
    origin3_key = {
      name                           = "origin3"
      origin_group_key               = "og1_key"
      enabled                        = true
      certificate_name_check_enabled = false
      host_name                      = "contoso2.com"
      http_port                      = 80
      https_port                     = 443
      host_header                    = "www.contoso2.com"
      priority                       = 3
      weight                         = 1
    }
  }
  front_door_routes = {
    route1_key = {
      name                      = "route1"
      endpoint_key              = "ep1_key"
      origin_group_key          = "og1_key"
      origin_keys               = ["origin1_key", "origin2_key"]
      forwarding_protocol       = "HttpsOnly"
      https_redirect_enabled    = true
      patterns_to_match         = ["/*"]
      supported_protocols       = ["Http", "Https"]
      rule_set_names            = ["ruleset1"]
      cdn_frontdoor_origin_path = "/originpath"
      cache = {
        cache1 = {
          query_string_caching_behavior = "IgnoreSpecifiedQueryStrings"
          query_strings                 = ["account", "settings"]
          compression_enabled           = true
          content_types_to_compress     = ["text/html", "text/javascript", "text/xml"]
        }
      }
    }
    route2_key = {
      name                      = "route2"
      endpoint_key              = "ep2_key"
      origin_group_key          = "og1_key"
      origin_keys               = ["origin2_key"]
      forwarding_protocol       = "HttpsOnly"
      https_redirect_enabled    = true
      patterns_to_match         = ["/*"]
      supported_protocols       = ["Http", "Https"]
      rule_set_names            = ["ruleset2"]
      cdn_frontdoor_origin_path = "/originpath"
    }
  }
  front_door_rule_sets = ["ruleset1", "ruleset2"]
  front_door_rules = {
    rule1_key = {
      name              = "examplerule1"
      order             = 1
      behavior_on_match = "Continue"
      rule_set_name     = "ruleset1"
      origin_group_key  = "og1_key"
      actions = {

        url_rewrite_actions = [{
          source_pattern          = "/"
          destination             = "/index3.html"
          preserve_unmatched_path = false
        }]
        route_configuration_override_actions = [{
          set_origin_groupid            = true
          forwarding_protocol           = "HttpsOnly"
          query_string_caching_behavior = "IncludeSpecifiedQueryStrings"
          query_string_parameters       = ["foo", "clientIp={client_ip}"]
          compression_enabled           = true
          cache_behavior                = "OverrideIfOriginMissing"
          cache_duration                = "365.23:59:59"
        }]
        response_header_actions = [{
          header_action = "Append"
          header_name   = "headername"
          value         = "/abc"
        }]
        request_header_actions = [{
          header_action = "Append"
          header_name   = "headername"
          value         = "/abc"
        }]
      }

      conditions = {
        remote_address_conditions = [{
          operator         = "IPMatch"
          negate_condition = false
          match_values     = ["10.0.0.0/23"]
        }]

        query_string_conditions = [{
          negate_condition = false
          operator         = "BeginsWith"
          match_values     = ["Query1", "Query2"]
          transforms       = ["Uppercase"]
        }]

        request_header_conditions = [{
          header_name      = "headername"
          negate_condition = false
          operator         = "BeginsWith"
          match_values     = ["Header1", "Header2"]
          transforms       = ["Uppercase"]
        }]

        request_body_conditions = [{
          negate_condition = false
          operator         = "BeginsWith"
          match_values     = ["Body1", "Body2"]
          transforms       = ["Uppercase"]
        }]

        request_scheme_conditions = [{
          negate_condition = false
          operator         = "Equal"
          match_values     = ["HTTP"]
        }]

        url_path_conditions = [{
          negate_condition = false
          operator         = "BeginsWith"
          match_values     = ["UrlPath1", "UrlPath2"]
          transforms       = ["Uppercase"]
        }]

        url_file_extension_conditions = [{
          negate_condition = false
          operator         = "BeginsWith"
          match_values     = ["ext1", "ext2"]
          transforms       = ["Uppercase"]
        }]

        url_filename_conditions = [{
          negate_condition = false
          operator         = "BeginsWith"
          match_values     = ["filename1", "filename2"]
          transforms       = ["Uppercase"]
        }]

        http_version_conditions = [{
          negate_condition = false
          operator         = "Equal"
          match_values     = ["2.0"]
        }]

        cookies_conditions = [{
          cookie_name      = "cookie"
          negate_condition = false
          operator         = "BeginsWith"
          match_values     = ["cookie1", "cookie2"]
          transforms       = ["Uppercase"]
        }]
      }
    }
    rule2_key = {
      name              = "examplerule2"
      order             = 1
      behavior_on_match = "Continue"
      rule_set_name     = "ruleset2"
      origin_group_key  = "og1_key"
      actions = {

        url_redirect_actions = [{
          redirect_type        = "PermanentRedirect"
          redirect_protocol    = "MatchRequest"
          query_string         = "clientIp={client_ip}"
          destination_path     = "/exampleredirection"
          destination_hostname = "contoso.com"
          destination_fragment = "UrlRedirect"
        }]
        response_header_actions = [{
          header_action = "Append"
          header_name   = "headername"
          value         = "/abc"
        }]
        request_header_actions = [{
          header_action = "Append"
          header_name   = "headername"
          value         = "/abc"
        }]
      }

      conditions = {
        request_method_conditions = [{
          operator         = "Equal"
          negate_condition = false
          match_values     = ["GET", "POST", "DELETE"]
        }]

        socket_address_conditions = [{
          operator         = "IPMatch"
          negate_condition = false
          match_values     = ["5.5.5.64/26"]
        }]

        client_port_conditions = [{
          operator         = "Equal"
          negate_condition = false
          match_values     = [80]
        }]

        server_port_conditions = [{
          operator         = "Equal"
          negate_condition = false
          match_values     = [443]
        }]

        ssl_protocol_conditions = [{
          operator         = "Equal"
          negate_condition = false
          match_values     = ["TLSv1", "TLSv1.1"]
        }]

        request_uri_conditions = [{
          negate_condition = false
          operator         = "BeginsWith"
          match_values     = ["uri1", "uri2"]
          transforms       = ["Uppercase"]
        }]

        host_name_conditions = [{
          operator         = "Equal"
          negate_condition = false
          match_values     = ["www.contoso1.com", "images.contoso.com", "video.contoso.com"]
          transforms       = ["Lowercase", "Trim"]
        }]

        is_device_conditions = [{
          operator         = "Equal"
          negate_condition = false
          match_values     = ["Mobile"]
        }]

        post_args_conditions = [{
          post_args_name = "customerName"
          operator       = "BeginsWith"
          match_values   = ["arg1", "arg2"]
          transforms     = ["Uppercase"]
        }]

        url_filename_conditions = [{
          operator         = "Equal"
          negate_condition = false
          match_values     = ["media.mp4"]
          transforms       = ["Lowercase", "RemoveNulls", "Trim"]
        }]
      }
    }
  }
  sku = "Standard_AzureFrontDoor"
  tags = {
    environment = "avm-demo"
  }
}

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
  version = "0.3.0"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = "centralindia"
  name     = "pvtlink-lb-${module.naming.resource_group.name_unique}"
}

# Create a virtual network
resource "azurerm_virtual_network" "vnet" {
  location            = azurerm_resource_group.this.location
  name                = "afd-lb-vnet"
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.5.0.0/16"]
}

# Create a subnet within the virtual network
resource "azurerm_subnet" "subnet" {
  address_prefixes                              = ["10.5.1.0/24"]
  name                                          = "front-end-subnet"
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
    name                          = "afd-lb-ip"
    private_ip_address            = "10.5.1.4"
    private_ip_address_allocation = "Static"
    private_ip_address_version    = "IPv4"
    subnet_id                     = azurerm_subnet.subnet.id
    zones                         = ["1", "2", "3"]
  }
}

# Create Private link service
resource "azurerm_private_link_service" "pls" {
  load_balancer_frontend_ip_configuration_ids = [azurerm_lb.lb.frontend_ip_configuration[0].id]
  location                                    = azurerm_resource_group.this.location
  name                                        = "afd-lb-pls"
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
      certificate_name_check_enabled = true
      host_name                      = "foo.bar"
      http_port                      = 80
      https_port                     = 443
      host_header                    = "foo.bar"
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
  }
  front_door_rule_sets = ["ruleset1"]
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
  }
  sku = "Premium_AzureFrontDoor"

  depends_on = [azurerm_private_link_service.pls]
}

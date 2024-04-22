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
  min = 0
  max = length(module.regions.regions) - 1
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
  name     = module.naming.resource_group.name_unique
  location = module.regions.regions[random_integer.region_index.result].name
}

data "azurerm_role_definition" "example" {
  name = "Contributor"
}

data "azurerm_client_config" "current" {}

module "avm_storage_account" {
  source                    = "Azure/avm-res-storage-storageaccount/azurerm"
  name                      = module.naming.storage_account.name_unique
  resource_group_name       = azurerm_resource_group.this.name
  shared_access_key_enabled = true
  enable_telemetry          = true
  account_replication_type  = "LRS"

}

resource "azurerm_log_analytics_workspace" "workspace" {
  name                = module.naming.log_analytics_workspace.name_unique
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
}

resource "azurerm_eventhub_namespace" "eventhub_namespace" {
  name                = module.naming.eventhub_namespace.name_unique
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Standard"
  capacity            = 1
  zone_redundant      = false


  tags = {
    environment = "Production"
  }
}

resource "azurerm_eventhub" "eventhub" {
  name                = "acceptanceTestEventHub"
  namespace_name      = azurerm_eventhub_namespace.eventhub_namespace.name
  resource_group_name = azurerm_resource_group.this.name
  partition_count     = 2
  message_retention   = 1
}

resource "azurerm_eventhub_namespace_authorization_rule" "example" {
  name                = "streamlogs"
  namespace_name      = azurerm_eventhub_namespace.eventhub_namespace.name
  resource_group_name = azurerm_resource_group.this.name
  listen              = true
  send                = true
  manage              = true
}

resource "azurerm_user_assigned_identity" "identity_for_keyvault" {
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  name                = module.naming.user_assigned_identity.name_unique
}

/* This is the module call that shows how to add interfaces for waf alignment
Locks
Tags
Role Assignments
Diagnostic Settings
Managed Identity
Azure Monitor Alerts
*/
module "azurerm_cdn_frontdoor_profile" {
  source = "/workspaces/terraform-azurerm-avm-res-cdn-profile"
  # source             = "Azure/avm-<res/ptn>-<name>/azurerm"
  enable_telemetry    = true
  name                = module.naming.cdn_profile.name_unique
  location            = azurerm_resource_group.this.location
  sku_name            = "Standard_AzureFrontDoor"
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
      name                           = "example-origin"
      origin_group_name              = "og1"
      enabled                        = true
      certificate_name_check_enabled = false
      host_name                      = "contoso.com"
      http_port                      = 80
      https_port                     = 443
      host_header                    = "www.contoso.com"
      priority                       = 1
      weight                         = 1
    }
    origin2 = {
      name                           = "origin2"
      origin_group_name              = "og1"
      enabled                        = true
      certificate_name_check_enabled = false
      host_name                      = "contoso1.com"
      http_port                      = 80
      https_port                     = 443
      host_header                    = "www.contoso.com"
      priority                       = 1
      weight                         = 1
    }
    origin3 = {
      name                           = "origin3"
      origin_group_name              = "og1"
      enabled                        = true
      certificate_name_check_enabled = false
      host_name                      = "contoso1.com"
      http_port                      = 80
      https_port                     = 443
      host_header                    = "www.contoso.com"
      priority                       = 1
      weight                         = 1
    }

  }

  endpoints = {
    ep1 = {
      name = "ep1"
      tags = {
        ENV = "example"
      }
    }
  }

  routes = {
    route1 = {
      name                   = "route1"
      endpoint_name          = "ep1"
      origin_group_name      = "og1"
      origin_names           = ["example-origin", "origin3"]
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


      }
    }
  }

  diagnostic_settings = {
    workspaceandstorage_diag = {
      name                           = " workspaceandstorage_diag"
      metric_categories              = ["AllMetrics"]
      log_categories                 = ["FrontDoorAccessLog", "FrontDoorHealthProbeLog", "FrontDoorWebApplicationFirewallLog"]
      log_analytics_destination_type = "Dedicated"
      workspace_resource_id          = azurerm_log_analytics_workspace.workspace.id
      storage_account_resource_id    = module.avm_storage_account.id
      #marketplace_partner_resource_id          = "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/{partnerResourceProvider}/{partnerResourceType}/{partnerResourceName}"

    }
    eventhub_diag = {
      name                                     = "eventhubforwarding"
      log_groups                               = ["allLogs", "audit"] 
      metric_categories                        = ["AllMetrics"]
      event_hub_authorization_rule_resource_id = azurerm_eventhub_namespace_authorization_rule.example.id
      event_hub_name                           = azurerm_eventhub_namespace.eventhub_namespace.name

    }
  }


  role_assignments = {
    self_contributor = {
      role_definition_id_or_name       = "Contributor"
      principal_id                     = data.azurerm_client_config.current.object_id
      skip_service_principal_aad_check = true
    },
    # role_assignment_2 = {
    #   role_definition_id_or_name             = "Reader"
    #   principal_id                           = "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
    #   description                            = "Example role assignment 2 of reader role"
    #   skip_service_principal_aad_check       = false
    #   condition                              = "@Resource[Microsoft.Storage/storageAccounts/blobServices/containers:ContainerName] StringEqualsIgnoreCase 'foo_storage_container'"
    #   condition_version                      = "2.0"
    # }
  }

  tags = {
    environment = "production"
  }
  /*      
  # A lock needs to be removed before destroy
   lock = {
       name = "lock-cdnprofile" # optional
       kind = "CanNotDelete"
     }
  */
  managed_identities = {
    system_assigned = true
    user_assigned_resource_ids = [
      azurerm_user_assigned_identity.identity_for_keyvault.id
    ]
  }

}
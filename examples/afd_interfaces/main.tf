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

data "azurerm_client_config" "current" {}

# module "avm_storage_account" {
#   source                    = "Azure/avm-res-storage-storageaccount/azurerm"
#   version                   = "0.1.1"
#   name                      = module.naming.storage_account.name_unique
#   resource_group_name       = azurerm_resource_group.this.name
#   shared_access_key_enabled = true
#   enable_telemetry          = true
#   account_replication_type  = "ZRS"
# }

resource "azurerm_log_analytics_workspace" "workspace" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.log_analytics_workspace.name_unique
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_eventhub_namespace" "eventhub_namespace" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.eventhub_namespace.name_unique
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Standard"
  capacity            = 1
  tags = {
    environment = "Production"
  }
  zone_redundant = false
}

resource "azurerm_eventhub" "eventhub" {
  message_retention   = 1
  name                = "acceptanceTestEventHub"
  namespace_name      = azurerm_eventhub_namespace.eventhub_namespace.name
  partition_count     = 2
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_eventhub_namespace_authorization_rule" "example" {
  name                = "streamlogs"
  namespace_name      = azurerm_eventhub_namespace.eventhub_namespace.name
  resource_group_name = azurerm_resource_group.this.name
  listen              = true
  manage              = true
  send                = true
}

resource "azurerm_user_assigned_identity" "identity_for_keyvault" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.user_assigned_identity.name_unique
  resource_group_name = azurerm_resource_group.this.name
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
  source              = "../../"
  enable_telemetry    = var.enable_telemetry
  name                = module.naming.cdn_profile.name_unique
  location            = azurerm_resource_group.this.location
  sku                 = "Standard_AzureFrontDoor"
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
  }

  front_door_endpoints = {
    ep1 = {
      name = "ep1"
      tags = {
        ENV = "example"
      }
    }
  }

  front_door_routes = {
    route1 = {
      name                   = "route1"
      endpoint_name          = "ep1"
      origin_group_name      = "og1"
      origin_names           = ["example-origin"]
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

  diagnostic_settings = {
    workspaceandstorage_diag = {
      name                           = "workspaceandstorage_diag"
      metric_categories              = ["AllMetrics"]
      log_categories                 = ["FrontDoorAccessLog", "FrontDoorHealthProbeLog", "FrontDoorWebApplicationFirewallLog"]
      log_analytics_destination_type = azurerm_log_analytics_workspace.workspace.id == null ? null : "Dedicated"
      workspace_resource_id          = azurerm_log_analytics_workspace.workspace.id
      #storage_account_resource_id    = module.avm_storage_account.id
      #marketplace_partner_resource_id          = "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/{partnerResourceProvider}/{partnerResourceType}/{partnerResourceName}"
    }
    eventhub_diag = {
      name = "eventhubforwarding"
      #log_categories = ["FrontDoorAccessLog", "FrontDoorHealthProbeLog", "FrontDoorWebApplicationFirewallLog"]
      log_groups                               = ["allLogs", "Audit"] # you can set either log_categories or log_groups.
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
      principal_type                   = "User"
    },
    role_assignment_2 = {
      role_definition_id_or_name       = "Reader"
      principal_id                     = "125****-c***-4f**-**0d-******53b5**" # replace the principal id with appropriate one
      description                      = "Example role assignment 2 of reader role"
      skip_service_principal_aad_check = false
      # condition                        = "@Resource[Microsoft.Storage/storageAccounts/blobServices/containers:ContainerName] StringEqualsIgnoreCase 'foo_storage_container'"
      # condition_version                = "2.0"
      principal_type = "User"
    }
  }

  tags = {
    environment = "production"
    costcenter  = "IT"
  }

  # A lock needs to be removed before destroy or before making changes
  #  lock = {
  #      name = "lock-cdnprofile" # optional
  #      kind = "CanNotDelete"
  #    }

  managed_identities = {
    system_assigned = true
    user_assigned_resource_ids = [
      azurerm_user_assigned_identity.identity_for_keyvault.id
    ]
  }
}
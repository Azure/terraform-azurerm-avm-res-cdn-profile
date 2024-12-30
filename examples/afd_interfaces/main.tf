terraform {
  required_version = "~> 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.103.1"
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
  name     = "interfaces_${module.naming.resource_group.name_unique}"
}

data "azurerm_client_config" "current" {}

resource "azurerm_storage_account" "storage" {
  account_replication_type      = "ZRS"
  account_tier                  = "Standard"
  location                      = azurerm_resource_group.this.location
  name                          = module.naming.storage_account.name_unique
  resource_group_name           = azurerm_resource_group.this.name
  public_network_access_enabled = false
}

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
    environment = "avm-demo"
  }
}

resource "azurerm_eventhub" "eventhub" {
  message_retention   = 1
  name                = "acceptanceTestEventHub"
  namespace_name     = azurerm_eventhub_namespace.eventhub_namespace.name
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

# Creating an action group for metric alerts
resource "azurerm_monitor_action_group" "example" {
  name                = "CriticalAlertsAction"
  resource_group_name = azurerm_resource_group.this.name
  short_name          = "p0action"
    email_receiver {
    name                    = "sendtodevops"
    email_address           = "devops@contoso.com"
    use_common_alert_schema = true
  }
}  

/* This is the module call that shows how to add interfaces for waf alignment
Locks
Tags
Role Assignments
Diagnostic Settings
Managed Identity
*/
module "azurerm_cdn_frontdoor_profile" {
  source              = "../../"
  enable_telemetry    = var.enable_telemetry
  name                = module.naming.cdn_profile.name_unique
  location            = azurerm_resource_group.this.location
  sku                 = "Standard_AzureFrontDoor"
  resource_group_name = azurerm_resource_group.this.name
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
  }
  front_door_endpoints = {
    ep1_key = {
      name = "ep1-${module.naming.cdn_endpoint.name_unique}"
      tags = {
        env = "prod"
      }
    }
  }
  front_door_rule_sets = ["ruleset1"]

  front_door_routes = {
    route1_key = {
      name                   = "route1"
      endpoint_key           = "ep1_key"
      origin_group_key       = "og1_key"
      origin_keys            = ["origin1_key"]
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

# Below example represents the recommended metric alerts for CDN profile as per [Azure Monitor baseline Alerts](https://azure.github.io/azure-monitor-baseline-alerts/services/Cdn/profiles/)
  metric_alerts = {
    alert1 = {
      name                = "1st criterion"
      description         = "Action will be triggered when ByteHitRatio is less than 90."
      enabled             = false
      frequency           = "PT5M"
      severity            = 2
      target_resource_type = "Microsoft.Cdn/profiles"
      window_size         = "PT30M"
      tags                = {
        environment = "AVM-Test"
      }
      criterias = [{
        metric_namespace = "Microsoft.Cdn/profiles"
        metric_name      = "ByteHitRatio"
        aggregation      = "Average"
        operator         = "LessThan"
        threshold        = 90
      }]
      actions = [{
        action_group_id = azurerm_monitor_action_group.example.id
      }]
    }

    alert2 = {
      name                = "2nd criterion"
      description         = "Action will be triggered when OriginHealthPercentage is less than 90."
      enabled             = false
      frequency           = "PT1M"
      severity            = 2
      target_resource_type = "Microsoft.Cdn/profiles"
      window_size         = "PT5M"
      tags                = {
        environment = "AVM-Test"
      }
      criterias = [{
        metric_namespace = "Microsoft.Cdn/profiles"
        metric_name      = "OriginHealthPercentage"
        aggregation      = "Average"
        operator         = "LessThanOrEqual"
        threshold        = 90
        dimensions = [{
          name     = "Origingroup"
          operator = "Include"
          values   = ["render"]
        }]
      }]
      actions = [{
        action_group_id = azurerm_monitor_action_group.example.id
      }]
    }

    alert3 = {
      name                = "3rd criterion"
      description         = "Action will be triggered when Percentage5XX is greater than 10."
      enabled             = false
      frequency           = "PT1M"
      severity            = 2
      target_resource_type = "Microsoft.Cdn/profiles"
      window_size         = "PT5M"
      tags                = {
        environment = "AVM-Test"
      }
      criterias = [{
        metric_namespace = "Microsoft.Cdn/profiles"
        metric_name      = "Percentage5XX"
        aggregation      = "Average"
        operator         = "GreaterThan"
        threshold        = 10
      }]
      actions = [{
        action_group_id = azurerm_monitor_action_group.example.id
      }]
    }

    alert4 = {
      name                = "4th criterion"
      description         = "Action will be triggered when RequestCount is greater than 1000."
      enabled             = false
      frequency           = "PT1M"
      severity            = 3
      target_resource_type = "Microsoft.Cdn/profiles"
      window_size         = "PT5M"
      tags                = {
        environment = "AVM-Test"
      }
      criterias = [{
        metric_namespace = "Microsoft.Cdn/profiles"
        metric_name      = "RequestCount"
        aggregation      = "Total"
        operator         = "GreaterThan"
        threshold        = 1000
      }]
      actions = [{
        action_group_id = azurerm_monitor_action_group.example.id
      }]
    }

    alert5 = {
      name                = "5th criterion"
      description         = "Action will be triggered when TotalLatency is greater than 100."
      enabled             = false
      frequency           = "PT1M"
      severity            = 2
      target_resource_type = "Microsoft.Cdn/profiles"
      window_size         = "PT5M"
      tags                = {
        environment = "AVM-Test"
      }
      criterias = [{
        metric_namespace = "Microsoft.Cdn/profiles"
        metric_name      = "TotalLatency"
        aggregation      = "Average"
        operator         = "GreaterThan"
        threshold        = 100
      }]
      actions = [{
        action_group_id = azurerm_monitor_action_group.example.id
      }]
    }
  } 

  diagnostic_settings = {
    workspaceandstorage_diag = {
      name                           = "workspaceandstorage_diag"
      metric_categories              = ["AllMetrics"]
      log_categories                 = ["FrontDoorAccessLog", "FrontDoorHealthProbeLog", "FrontDoorWebApplicationFirewallLog"]
      log_groups                     = [] # must explicitly set since log_groups defaults to ["allLogs"]
      log_analytics_destination_type = "Dedicated"
      workspace_resource_id          = azurerm_log_analytics_workspace.workspace.id
      storage_account_resource_id    = azurerm_storage_account.storage.id
      #marketplace_partner_resource_id          = "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/{partnerResourceProvider}/{partnerResourceType}/{partnerResourceName}"
    }
    eventhub_diag = {
      name                                     = "eventhubforwarding"
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
      principal_id                     = data.azurerm_client_config.current.object_id # replace the principal id with appropriate one
      description                      = "Example role assignment 2 of reader role"
      skip_service_principal_aad_check = false
      principal_type                   = "User"
      #condition                        = "@Resource[Microsoft.Storage/storageAccounts/blobServices/containers:ContainerName] StringEqualsIgnoreCase 'foo_storage_container'"
      #condition_version                = "2.0"
    }
  }

  tags = {
    environment = "avm-demo"
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
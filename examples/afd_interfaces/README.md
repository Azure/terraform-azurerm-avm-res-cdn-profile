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

data "azurerm_client_config" "current" {}

module "avm_storage_account" {
  source                    = "Azure/avm-res-storage-storageaccount/azurerm"
  version                   = "0.1.1"
  name                      = module.naming.storage_account.name_unique
  resource_group_name       = azurerm_resource_group.this.name
  shared_access_key_enabled = true
  enable_telemetry          = true
  account_replication_type  = "LRS"
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
  # source = "/workspaces/terraform-azurerm-avm-res-cdn-profile"
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

- [azurerm_eventhub.eventhub](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub) (resource)
- [azurerm_eventhub_namespace.eventhub_namespace](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub_namespace) (resource)
- [azurerm_eventhub_namespace_authorization_rule.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub_namespace_authorization_rule) (resource)
- [azurerm_log_analytics_workspace.workspace](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) (resource)
- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_user_assigned_identity.identity_for_keyvault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) (resource)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)

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

### <a name="module_avm_storage_account"></a> [avm\_storage\_account](#module\_avm\_storage\_account)

Source: Azure/avm-res-storage-storageaccount/azurerm

Version: 0.1.1

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
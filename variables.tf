variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see https://aka.ms/avm/telemetryinfo.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

# This is required for most resource modules
variable "resource_group_name" {
  type        = string
  description = "The resource group where the resources will be deployed."
}

variable "name" {
  type = string
}

variable "sku_name" {
  type = string
}

variable "tags" {
  type    = map(any)
  default = null
}

variable "response_timeout_seconds" {
  type    = number
  default = 16
}

variable "location" {
  type    = string
  default = null
}

variable "origin_groups" {
  type = map(object({
    name = string
    health_probe = optional(map(object({
      interval_in_seconds = number
      path                = optional(string, "/")
      protocol            = string
      request_type        = optional(string, "HEAD")
    })), {})
    load_balancing = map(object({
      additional_latency_in_milliseconds = optional(number, 50)
      sample_size                        = optional(number, 4)
      successful_samples_required        = optional(number, 3)
    }))
  }))
  default = null

}

variable "origin" {
  type = map(object({
    name                           = string
    origin_group_name              = string
    host_name                      = string
    certificate_name_check_enabled = string
    enabled                        = string
    http_port                      = optional(number, 80)
    https_port                     = optional(number, 443)
    host_header                    = optional(string, null)
    priority                       = optional(number, 1)
    weight                         = optional(number, 500)
    private_link = optional(map(object({
      request_message        = string
      target_type            = optional(string, null)
      location               = string
      private_link_target_id = string
    })), null)
  }))
}

variable "endpoints" {
  type = map(object({
    name    = string
    enabled = optional(bool, true)
    tags    = optional(map(any))
  }))
}

variable "routes" {
  type = map(object({
    name                   = string
    origin_group_name      = string
    origin_names           = list(string)
    endpoint_name          = string
    forwarding_protocol    = optional(string, "HttpsOnly")
    supported_protocols    = list(string)
    patterns_to_match      = list(string)
    link_to_default_domain = optional(bool, true)
    https_redirect_enabled = optional(bool, true)
    custom_domain_names    = optional(list(string))
    cache = optional(map(object({
      query_string_caching_behavior = optional(string, "IgnoreQueryString")
      query_strings                 = optional(list(string))
      compression_enabled           = optional(bool, false)
      content_types_to_compress     = optional(list(string))
    })), {})
  }))
}

variable "rule_sets" {
  type    = set(string)
  default = []
}

variable "rules" {
  type = map(any)
}

variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
  Controls the Resource Lock configuration for this resource. The following properties can be specified:
  
  - `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
  - `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
  DESCRIPTION

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "Lock kind must be either `\"CanNotDelete\"` or `\"ReadOnly\"`."
  }
}

variable "diagnostic_settings" {
  type = map(object({
    name                                     = optional(string, null)
    log_categories                           = optional(set(string), [])
    log_groups                               = optional(set(string), [])
    metric_categories                        = optional(set(string), ["AllMetrics"])
    log_analytics_destination_type           = optional(string, "Dedicated")
    workspace_resource_id                    = optional(string, null)
    storage_account_resource_id              = optional(string, null)
    event_hub_authorization_rule_resource_id = optional(string, null)
    event_hub_name                           = optional(string, null)
    marketplace_partner_resource_id          = optional(string, null)
  }))
  default  = {}
  nullable = false

  validation {
    condition     = alltrue([for _, v in var.diagnostic_settings : contains(["Dedicated", "AzureDiagnostics"], v.log_analytics_destination_type)])
    error_message = "Log analytics destination type must be one of: 'Dedicated', 'AzureDiagnostics'."
  }
  validation {
    condition = alltrue(
      [
        for _, v in var.diagnostic_settings :
        v.workspace_resource_id != null || v.storage_account_resource_id != null || v.event_hub_authorization_rule_resource_id != null || v.marketplace_partner_resource_id != null
      ]
    )
    error_message = "At least one of `workspace_resource_id`, `storage_account_resource_id`, `marketplace_partner_resource_id`, or `event_hub_authorization_rule_resource_id`, must be set."
  }
  validation {
    condition = alltrue(
      [
        for _, v in var.diagnostic_settings :
        ((length(v.log_categories) > 0 && length(v.log_groups) > 0) ? false : true )#|| (coalesce(v.log_categories, []) == [] && coalesce(v.log_groups, []) != []))
      ]
    )
    error_message = "Set either Log categories or Log groups, you cant set both"
  }
  description = <<DESCRIPTION
  A map of diagnostic settings to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  
  - `name` - (Optional) The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
  - `log_categories` - (Optional) A set of log categories to send to the log analytics workspace. Defaults to `[]`.
  - `log_groups` - (Optional) A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`.
  - `metric_categories` - (Optional) A set of metric categories to send to the log analytics workspace. Defaults to `["AllMetrics"]`.
  - `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
  - `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
  - `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
  - `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
  - `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
  - `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic LogsLogs.
  DESCRIPTION
}

variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    principal_type                         = optional(string, "User") #["User" "Group" "ServicePrincipal"] case sensitive
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
  A map of role assignments to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  
  - `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
  - `principal_id` - The ID of the principal to assign the role to.
  - `description` - The description of the role assignment.
  - `skip_service_principal_aad_check` - If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
  - `condition` - The condition which will be used to scope the role assignment.
  - `condition_version` - The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
  
  > Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
  DESCRIPTION
}

variable "managed_identities" {
  type = object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
  Controls the Managed Identity configuration on this resource. The following properties can be specified:
  
  - `system_assigned` - (Optional) Specifies if the System Assigned Managed Identity should be enabled.
  - `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource.
  DESCRIPTION
  nullable    = false
}

variable "front_door_secret" {
  type = object({
    name                     = string
    key_vault_certificate_id = string
  })
  default = null
}

variable "front_door_custom_domains" {
  type = map(object({
    name        = string
    dns_zone_id = string
    host_name   = string
    # associated_route_names = optional(list(string)) no functional purpose
    tls = object({
      certificate_type        = optional(string, "ManagedCertificate")
      minimum_tls_version     = optional(string, null)
      cdn_frontdoor_secret_id = optional(string, null)
    })


  }))
  default = {}
}

variable "front_door_security_policies" {
  type = map(object({
    name = string
    firewall = object({
      front_door_firewall_policy_name = string
      association = object({
        domain_names      = optional(list(string), [])
        endpoint_names    = optional(list(string), [])
        patterns_to_match = list(string)
      })
    })
  }))
  nullable = false
  default  = {}
  validation {
    condition     = length(flatten([for name, policy in var.front_door_security_policies : concat(policy.firewall.association.domain_names, policy.firewall.association.endpoint_names)])) == length(distinct(flatten([for name, policy in var.front_door_security_policies : concat(policy.firewall.association.domain_names, policy.firewall.association.endpoint_names)])))
    error_message = "Endpoint/Custom domain is already being used, please provide unique association."
  }

}

variable "front_door_firewall_policies" {
  type = map(object({
    name                              = string
    resource_group_name               = string
    sku_name                          = string
    enabled                           = optional(bool, true)
    mode                              = string
    request_body_check_enabled        = optional(bool, true)
    redirect_url                      = optional(string)
    custom_block_response_status_code = optional(number)
    custom_block_response_body        = optional(string)
    custom_rules = map(object({
      name                           = string
      enabled                        = optional(bool, true)
      priority                       = optional(number, 1)
      rate_limit_duration_in_minutes = optional(number, 1)
      rate_limit_threshold           = optional(number, 10)
      type                           = string
      action                         = string
      match_conditions = map(object({
        match_variable     = string
        operator           = string
        negation_condition = optional(bool)
        match_values       = list(string)
        selector           = optional(string)
        transforms         = optional(list(string))
      }))
    }))
    managed_rules = optional(map(object({
      type    = string
      version = string
      action  = string
      exclusion = optional(map(object({
        match_variable = string
        operator       = string
        selector       = optional(string)
      })), {})
      override = optional(map(object({
        rule_group_name = string
        exclusion = optional(map(object({
          match_variable = string
          operator       = string
          selector       = optional(string)
        })), {})
        rule = optional(map(object({
          action  = string
          enabled = optional(bool, false)
          exclusion = optional(map(object({
            match_variable = string
            operator       = string
            selector       = optional(string)
          })), {})
        })), {})
      })), {})
    })), {})
    tags = optional(map(any))
  }))
  nullable = false
  default  = {}
  validation {
    condition     = alltrue([for _, v in var.front_door_firewall_policies : contains(["Standard_AzureFrontDoor", "Premium_AzureFrontDoor"], v.sku_name)])
    error_message = "Possible values include 'Standard_AzureFrontDoor' or 'Premium_AzureFrontDoor' for Sku_name"
  }
  validation {
    condition     = alltrue([for _, v in var.front_door_firewall_policies : contains(["Detection", "Prevention"], v.mode)])
    error_message = " Possible values are 'Detection', 'Prevention' for mode"
  }
  validation {
    condition     = alltrue([for _, v in var.front_door_firewall_policies : contains(["200", "403", "405", "406", "429"], tostring(v.custom_block_response_status_code))])
    error_message = " Possible values are 200, 403, 405, 406, or 429 for custom_block_response_status_code"
  }
  validation {
    condition     = alltrue([for _, v in var.front_door_firewall_policies : alltrue([for _, x in v["custom_rules"] : contains(["Allow", "Block", "Log", "Redirect"], x["action"])])])
    error_message = "Possible values are 'Allow', 'Block', 'Log', or 'Redirect' for action"
  }
  validation {
    condition     = alltrue([for _, v in var.front_door_firewall_policies : alltrue([for _, x in v["custom_rules"] : contains(["MatchRule", "RateLimitRule"], x["type"])])])
    error_message = "Possible values are 'MatchRule' or 'RateLimitRule' for type."
  }
  # validation {
  #   condition = length([for _, v in var.front_door_firewall_policies : v.custom_rules != null && length(v.custom_rules[*].match_conditions) > 0 ? v.custom_rules[*].match_conditions : null]) <= 10
  #   error_message = "If match_condition is used, it should not exceed 10 blocks."
  # }
  validation {
    condition     = alltrue([for _, v in var.front_door_firewall_policies : alltrue([for _, x in v["custom_rules"] : alltrue([for _, y in x["match_conditions"] : contains(["Cookies", "PostArgs", "QueryString", "RemoteAddr", "RequestBody", "RequestHeader", "RequestMethod", "RequestUri", "SocketAddr"], y["match_variable"])])])])
    error_message = "Possible values are 'Cookies', 'PostArgs', 'QueryString', 'RemoteAddr', 'RequestBody', 'RequestHeader', 'RequestMethod','RequestUri', or 'SocketAddr' for match_condition."
  }
  # validation {
  #   condition = length(flatten([for name, policy in var.front_door_firewall_policies : policy.custom_rules != null ? [for mc in policy.custom_rules[*].match_conditions : length(mc.match_values)] : []])) <= 600 && alltrue(flatten([for name, policy in var.front_door_firewall_policies : policy.custom_rules != null ? [for mc in policy.custom_rules[*].match_conditions : alltrue([for mv in mc.match_values : length(mv) <= 256])] : []]))
  #   error_message = "The total number of match_values across all match_condition blocks should not exceed 600, and each match_value should be up to 256 characters in length."
  # }
  validation {
    condition     = alltrue([for _, v in var.front_door_firewall_policies : alltrue([for _, x in v["custom_rules"] : alltrue([for _, y in x["match_conditions"] : contains(["Any", "BeginsWith", "Contains", "EndsWith", "Equal", "GeoMatch", "GreaterThan", "GreaterThanOrEqual", "IPMatch", "LessThan", "LessThanOrEqual", "RegEx"], y["operator"])])])])
    error_message = "Possible values are 'Any', 'BeginsWith', 'Contains', 'EndsWith', 'Equal', 'GeoMatch', 'GreaterThan', 'GreaterThanOrEqual', 'IPMatch', 'LessThan', 'LessThanOrEqua'l or 'RegEx' for operator."
  }
  # validation {
  #   condition = alltrue(flatten([for name, policy in var.front_door_firewall_policies : policy.custom_rules != null ? [for mc in policy.custom_rules[*].match_conditions : length([for mv in mc.match_values : mc.match_variable == "QueryString" || mc.match_variable == "PostArgs" || mc.match_variable == "RequestHeader" || mc.match_variable == "Cookies" ? coalesce(mc.selector, null) : null]) == length(mc.match_values)] : []]))
  #   error_message = "If the match_variable is QueryString, PostArgs, RequestHeader, or Cookies, a selector should be provided."
  # }
  validation {
    condition     = alltrue([for _, v in var.front_door_firewall_policies : alltrue([for _, x in v["custom_rules"] : alltrue([for _, y in x["match_conditions"] : alltrue([y["transforms"] == null ? true : alltrue([for transform in coalesce(y["transforms"], []) : contains(["Lowercase", "RemoveNulls", "Trim", "Uppercase", "URLDecode", "URLEncode"], transform)])])])])])
    error_message = "Possible values are 'Lowercase', 'RemoveNulls', 'Trim', 'Uppercase', 'URLDecode' or 'URLEncode' for transforms."
  }
  validation {
    condition     = alltrue([for name, policy in var.front_door_firewall_policies : policy.sku_name == "Premium_AzureFrontDoor" ? length(keys(policy.managed_rules)) > 0 : length(keys(policy.managed_rules)) == 0])
    error_message = "Managed rules should be set only when the Sku_name selected is 'Premium_AzureFrontDoor'."
  }
  validation {
    condition     = alltrue([for _, v in var.front_door_firewall_policies : alltrue([for _, x in v["managed_rules"] : contains(["DefaultRuleSet", "Microsoft_DefaultRuleSet", "BotProtection", "Microsoft_BotManagerRuleSet"], x["type"])])])
    error_message = "Possible values include 'DefaultRuleSet', 'Microsoft_DefaultRuleSet', 'BotProtection' or 'Microsoft_BotManagerRuleSet' for managed_rule type."
  }
}




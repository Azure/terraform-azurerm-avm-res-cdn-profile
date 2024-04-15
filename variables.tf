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
  type        = string
  description = "The name of the Azure Front Door."
}

variable "sku_name" {
  type        = string
  default     = "Standard_AzureFrontDoor"
  description = "The SKU name of the Azure Front Door. Default is `Standard`. Possible values are `standard` and `premium`.SKU name for CDN can be 'Standard_Akamai', 'Standard_ChinaCdn, 'Standard_Microsoft','Standard_Verizon' or 'Premium_Verizon'"
  validation {
    condition     = contains(["Standard_AzureFrontDoor", "Premium_AzureFrontDoor", "Standard_Akamai", "Standard_ChinaCdn", "Standard_Microsoft", "Standard_Verizon", "Premium_Verizon"], var.sku_name)
    error_message = "The SKU must be either 'Standard' or 'Premium' for Front Door. For CDN use correct SKU name"
  }
}

variable "tags" {
  type        = map(any)
  default     = null
  description = "Map of tags to assign to the Azure Front Door resource."
}

variable "response_timeout_seconds" {
  type        = number
  default     = 120
  description = "Specifies the maximum response timeout in seconds. Possible values are between 16 and 240 seconds (inclusive). Defaults to 120 seconds. "
  validation {
    condition     = var.response_timeout_seconds >= 16 && var.response_timeout_seconds <= 120
    error_message = "The respoonse time must be between 16 & 120 Seconds"
  }
}

variable "location" {
  type        = string
  default     = null
  description = "The Azure location where the resources will be deployed."
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
  # The below 2 properties will be enabled in near future
  # restore_traffic_time_to_healed_or_new_endpoint_in_minutes = optional(number, 10)
  # session_affinity_enabled = optional(bool, true)
  default = null
  # validation {
  #   condition = alltrue(
  #     [
  #       for _, v in var.origin_groups :
  #       v.restore_traffic_time_to_healed_or_new_endpoint_in_minutes >= 0 && v.restore_traffic_time_to_healed_or_new_endpoint_in_minutes <= 50
  #     ]
  #   )
  #   error_message = "Possible values must be between 0 & 50 minutes"
  # }
  validation {
    condition = alltrue(
      [
        for _, v in var.origin_groups :
        alltrue(
          [
            for _, x in v["health_probe"] : contains(["Http", "Https"], x["protocol"])
          ]
        )
      ]
    )
    error_message = "Value must be either HTTP or HTTPS"
  }
  validation {
    condition = alltrue(
      [
        for _, v in var.origin_groups :
        alltrue(
          [
            for _, x in v["health_probe"] : x["interval_in_seconds"] >= 5 && x["interval_in_seconds"] <= 31536000
          ]
        )
      ]
    )
    error_message = "Possible values must be between 5 & 31536000 seconds"
  }
  validation {
    condition = alltrue(
      [
        for _, v in var.origin_groups :
        alltrue(
          [
            for _, x in v["health_probe"] : contains(["GET", "HEAD"], x["request_type"])
          ]
        )
      ]
    )
    error_message = "Value must be either GET or HEAD"
  }
  validation {
    condition = alltrue(
      [
        for _, v in var.origin_groups :
        alltrue(
          [
            for _, x in v["load_balancing"] : x["additional_latency_in_milliseconds"] >= 0 && x["additional_latency_in_milliseconds"] <= 1000
          ]
        )
      ]
    )
    error_message = "Possible values must be between 0 & 1000 milliseconds"
  }
  validation {
    condition = alltrue(
      [
        for _, v in var.origin_groups :
        alltrue(
          [
            for _, x in v["load_balancing"] : x["sample_size"] >= 0 && x["sample_size"] <= 255
          ]
        )
      ]
    )
    error_message = "Possible values must be between 0 & 255"
  }
  validation {
    condition = alltrue(
      [
        for _, v in var.origin_groups :
        alltrue(
          [
            for _, x in v["load_balancing"] : x["successful_samples_required"] >= 0 && x["successful_samples_required"] <= 255
          ]
        )
      ]
    )
    error_message = "Possible values must be between 0 & 255"
  }
  description = <<DESCRIPTION
  Manages a Front Door (standard/premium) Origin group.
  
  - `name` - (Required) The name which should be used for this Front Door Origin Group. 
  - `load_balancing` - (Required) A load_balancing block as defined below:-
      - 'additional_latency_in_milliseconds' - (Optional) Specifies the additional latency in milliseconds for probes to fall into the lowest latency bucket. Possible values are between 0 and 1000 milliseconds (inclusive). Defaults to 50
      - 'sample_size' - (Optional) Specifies the number of samples to consider for load balancing decisions. Possible values are between 0 and 255 (inclusive). Defaults to 4.
      - 'successful_samples_required' - (Optional) Specifies the number of samples within the sample period that must succeed. Possible values are between 0 and 255 (inclusive). Defaults to 3.
  - 'health_probe' - (Optional) A health_probe block as defined below:-
      - 'protocol' - (Required) Specifies the protocol to use for health probe. Possible values are Http and Https.
      - 'interval_in_seconds' - (Required) Specifies the number of seconds between health probes. Possible values are between 5 and 31536000 seconds (inclusive).
      - 'request_type' - (Optional) Specifies the type of health probe request that is made. Possible values are GET and HEAD. Defaults to HEAD.
      - 'path' - (Optional) Specifies the path relative to the origin that is used to determine the health of the origin. Defaults to /.
  DESCRIPTION
}

variable "origin" {
  type = map(object({
    name                           = string
    origin_group_name              = string
    host_name                      = string
    certificate_name_check_enabled = string
    enabled                        = optional(bool, true)
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
  validation {
    condition = alltrue(
      [
        for _, v in var.origin : v.http_port >= 1 && v.http_port <= 65535
      ]
    )
    error_message = "Possible values must be between 1 & 65535"
  }
  validation {
    condition = alltrue(
      [
        for _, v in var.origin : v.https_port >= 1 && v.https_port <= 65535
      ]
    )
    error_message = "Possible values must be between 1 & 65535"
  }
  validation {
    condition = alltrue(
      [
        for _, v in var.origin : v.priority >= 1 && v.priority <= 5
      ]
    )
    error_message = "Possible values must be between 1 & 5"
  }
  validation {
    condition = alltrue(
      [
        for _, v in var.origin : v.weight >= 1 && v.weight <= 1000
      ]
    )
    error_message = "Possible values must be between 1 & 1000"
  }
  # Need to verify below validation
  validation {
    condition = alltrue(
      [
        for v in var.origin : v.private_link == null ? true : alltrue(
          [
            for x in v.private_link : length(x.request_message) >= 10 && length(x.request_message) <= 140
          ]
        )
      ]
    )
    error_message = "Values must be between 1 and 140 characters in length"
  }
  validation {
    condition = alltrue(
      [
        for _, v in var.origin : v["private_link"] == null ? true : alltrue(
          [
            for _, x in v["private_link"] : x["target_type"] == null ? true : contains(["blob", "blob_secondary", "web", "sites"], x["target_type"])
          ]
        )
      ]
    )
    error_message = "Possible values are 'blob', 'blob_secondary', 'web' and 'sites'. Set it to 'null' for Load balancer as origin"
  }
  description = <<DESCRIPTION
  Manages a Front Door (standard/premium) Origin.
  
  - `name` - (Required) The name which should be used for this Front Door Origin.
  - 'origin_group_name' - (Required) The name of the origin group to associate the origin with.
  - `host_name` - (Required) The IPv4 address, IPv6 address or Domain name of the Origin.
  - 'certificate_name_check_enabled' - (Required) Specifies whether certificate name checks are enabled for this origin.
  - 'enabled' - (Optional) Should the origin be enabled? Possible values are true or false. Defaults to true.
  - 'http_port' - (Optional) The value of the HTTP port. Must be between 1 and 65535. Defaults to 80
  - 'https_port' - (Optional) The value of the HTTPS port. Must be between 1 and 65535. Defaults to 443.
  - 'origin_host_header' - (Optional) The host header value (an IPv4 address, IPv6 address or Domain name) which is sent to the origin with each request. If unspecified the hostname from the request will be used.
  - 'priority' - (Optional) Priority of origin in given origin group for load balancing. Higher priorities will not be used for load balancing if any lower priority origin is healthy. Must be between 1 and 5 (inclusive). Defaults to 1
  - 'private_link' - (Optional) A private_link block as defined below:-
      - 'request_message' - (Optional) Specifies the request message that will be submitted to the private_link_target_id when requesting the private link endpoint connection. Values must be between 1 and 140 characters in length. Defaults to Access request for CDN FrontDoor Private Link Origin.
      - 'target_type' - (Optional) Specifies the type of target for this Private Link Endpoint. Possible values are blob, blob_secondary, web and sites.
      - 'location' - (Required) Specifies the location where the Private Link resource should exist. Changing this forces a new resource to be created.
  - 'weight' - (Optional) The weight of the origin in a given origin group for load balancing. Must be between 1 and 1000. Defaults to 500.
  DESCRIPTION
}

variable "endpoints" {
  type = map(object({
    name    = string
    enabled = optional(bool, true)
    tags    = optional(map(any))
  }))
  description = <<DESCRIPTION
  Manages a Front Door (standard/premium) Endpoint.
  
  - `name` - (Required) The name which should be used for this Front Door Endpoint.  
  - `enabled` - (Optional) Specifies if this Front Door Endpoint is enabled? Defaults to true.
  - 'tags' - (Optional) Specifies a mapping of tags which should be assigned to the Front Door Endpoint.
  DESCRIPTION
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
  validation {
    condition = alltrue(
      [
        for _, v in var.routes :
        can(regex("^[a-zA-Z0-9][-a-zA-Z0-9]{0,88}[a-zA-Z0-9]$", v.name))
      ]
    )
    error_message = "Valid values must begin with a letter or number, end with a letter or number and may only contain letters, numbers and hyphens with a maximum length of 90 characters."
  }
  validation {
    condition = alltrue(
      [
        for _, v in var.routes :
        contains(["HttpOnly", "HttpsOnly", "MatchRequest"], v.forwarding_protocol)
      ]
    )
    error_message = "Possible values are 'HttpOnly', 'HttpsOnly' or 'MatchRequest'.Defaults to 'HttpsOnly'"
  }
  validation {
    condition = alltrue(
      [
        for _, v in var.routes : length(v.supported_protocols) > 0 && alltrue([for protocol in v.supported_protocols : protocol == "Http" || protocol == "Https"]) &&
        (!v.https_redirect_enabled || (contains(v.supported_protocols, "Http") && contains(v.supported_protocols, "Https")))
      ]
    )
    error_message = "Possible values are 'Http', 'Https' only. If 'https_redirect_enabled' is set to true the 'supported_protocols' field must contain both 'Http' and 'Https' values. "
  }
  validation {
    condition = alltrue(
      [
        for _, v in var.routes :
        alltrue(
          [
            for _, x in v["cache"] : contains(["IgnoreQueryString", "IgnoreSpecifiedQueryStrings", "IncludeSpecifiedQueryStrings", "UseQueryString"], x["query_string_caching_behavior"])
          ]
        )
      ]
    )
    error_message = "Possible values includes 'IgnoreQueryString', 'IgnoreSpecifiedQueryStrings', 'IncludeSpecifiedQueryStrings' or 'UseQueryString'. Defaults to 'IgnoreQueryString'."
  }
  validation {
    condition = alltrue(
      [
        for _, v in var.routes :
        alltrue(
          [
            for _, x in v["cache"] : alltrue([for y in x["content_types_to_compress"] : contains(["application/eot", "application/font", "application/font-sfnt", "application/javascript", "application/json", "application/opentype", "application/otf", "application/pkcs7-mime", "application/truetype", "application/ttf", "application/vnd.ms-fontobject", "application/xhtml+xml", "application/xml", "application/xml+rss", "application/x-font-opentype", "application/x-font-truetype", "application/x-font-ttf", "application/x-httpd-cgi", "application/x-mpegurl", "application/x-opentype", "application/x-otf", "application/x-perl", "application/x-ttf", "application/x-javascript", "font/eot", "font/ttf", "font/otf", "font/opentype", "image/svg+xml", "text/css", "text/csv", "text/html", "text/javascript", "text/js", "text/plain", "text/richtext", "text/tab-separated-values", "text/xml", "text/x-script", "text/x-component", "text/x-java-source"], y)])
          ]
        )
      ]
    )
    error_message = "Possible values include 'application/eot', 'application/font', 'application/font-sfnt', 'application/javascript', 'application/json', 'application/opentype', 'application/otf', 'application/pkcs7-mime', 'application/truetype', 'application/ttf', 'application/vnd.ms-fontobject', 'application/xhtml+xml', 'application/xml', 'application/xml+rss', 'application/x-font-opentype', 'application/x-font-truetype', 'application/x-font-ttf', 'application/x-httpd-cgi', 'application/x-mpegurl', 'application/x-opentype', 'application/x-otf', 'application/x-perl', 'application/x-ttf', 'application/x-javascript', 'font/eot', 'font/ttf', 'font/otf', 'font/opentype', 'image/svg+xml', 'text/css', 'text/csv', 'text/html', 'text/javascript', 'text/js', 'text/plain', 'text/richtext', 'text/tab-separated-values', 'text/xml', 'text/x-script', 'text/x-component' or 'text/x-java-source'."
  }
  description = <<DESCRIPTION
  Manages a Front Door (standard/premium) Route.
  
  - `name` - (Required) The name which should be used for this Front Door Route. Valid values must begin with a letter or number, end with a letter or number and may only contain letters, numbers and hyphens with a maximum length of 90 characters.
  - 'origin_group_name' - (Required) The name of the origin group to associate the route with.
  - `origin_names` - (Required) The name of the origins to associate the route with.
  - 'endpoint_name' - (Required) The name of the origins to associate the route with.
  - 'forwarding_protocol' - (Optional) The Protocol that will be use when forwarding traffic to backends. Possible values are 'HttpOnly', 'HttpsOnly' or 'MatchRequest'. Defaults to 'MatchRequest'.
  - 'patterns_to_match' - (Required) The route patterns of the rule.
  - 'supported_protocols' - (Required) One or more Protocols supported by this Front Door Route. Possible values are 'Http' or 'Https'.
  - 'https_redirect_enabled' - (Optional) Automatically redirect HTTP traffic to HTTPS traffic? Possible values are true or false. Defaults to true.
  - 'link_to_default_domain' - (Optional) Should this Front Door Route be linked to the default endpoint? Possible values include true or false. Defaults to true.
  - 'cache' - (Optional) A cache block as defined below:-
      - 'query_string_caching_behavior' - (Optional) Defines how the Front Door Route will cache requests that include query strings. Possible values include 'IgnoreQueryString', 'IgnoreSpecifiedQueryStrings', 'IncludeSpecifiedQueryStrings' or 'UseQueryString'. Defaults to 'IgnoreQueryString'.
      - 'query_strings' - (Optional) Query strings to include or ignore.
      - 'compression_enabled' - (Optional) Is content compression enabled? Possible values are true or false. Defaults to false.
      - 'content_types_to_compress' - (Optional) A list of one or more Content types (formerly known as MIME types) to compress. Possible values include 'application/eot', 'application/font', 'application/font-sfnt', 'application/javascript', 'application/json', 'application/opentype', 'application/otf', 'application/pkcs7-mime', 'application/truetype', 'application/ttf', 'application/vnd.ms-fontobject', 'application/xhtml+xml', 'application/xml', 'application/xml+rss', 'application/x-font-opentype', 'application/x-font-truetype', 'application/x-font-ttf', 'application/x-httpd-cgi', 'application/x-mpegurl', 'application/x-opentype', 'application/x-otf', 'application/x-perl', 'application/x-ttf', 'application/x-javascript', 'font/eot', 'font/ttf', 'font/otf', 'font/opentype', 'image/svg+xml', 'text/css', 'text/csv', 'text/html', 'text/javascript', 'text/js', 'text/plain', 'text/richtext', 'text/tab-separated-values', 'text/xml', 'text/x-script', 'text/x-component' or 'text/x-java-source'.
  DESCRIPTION
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
        ((length(v.log_categories) > 0 && length(v.log_groups) > 0) ? false : true)
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
  validation {
    condition     =  var.front_door_secret == null ? true : can(regex("^[a-zA-Z0-9][-a-zA-Z0-9]{0,258}[a-zA-Z0-9]$", var.front_door_secret.name))
    error_message = "The secret name must start with a letter or a number, only contain letters, numbers and hyphens, and have a length of between 2 and 260 characters."
  }
  description = <<DESCRIPTION
  Manages a Front Door (standard/premium) Secret.
  
  - `name` - (Required) The name which should be used for this Front Door Secret. 
  - `key_vault_certificate_id` - (Required) The ID of the Key Vault certificate resource to use.
  DESCRIPTION
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
  validation {
    condition     = alltrue([for _, v in var.front_door_security_policies : v.name != ""])
    error_message = "Security policy name must not be an empty string."
  }
  validation {
    condition     = alltrue([for name, policy in var.front_door_security_policies : policy.firewall.association.domain_names == [] ? policy.firewall.association.endpoint_names != [] : true])
    error_message = "Provide either domain names or endpoint names or both."
  }
  validation {
    condition = alltrue([for name, policy in var.front_door_security_policies :
    (length(policy.firewall.association.domain_names) > 0 || length(policy.firewall.association.endpoint_names) > 0) && (policy.firewall.association.domain_names != null || policy.firewall.association.endpoint_names != null)])
    error_message = "Provide either domain names or endpoint names or both, and ensure they are not empty."
  }
  description = <<DESCRIPTION
  Manages a Front Door (standard/premium) Security Policy.
  
  - `name` - (Required) The name which should be used for this Front Door Security Policy. Possible values must not be an empty string.
  - `firewall` - (Required) An firewall block as defined below: -
    - 'front_door_firewall_policy_name' - (Required) the name of Front Door Firewall Policy that should be linked to this Front Door Security Policy.
    - 'association' - (Required) An association block as defined below:-
      - ' domain_names ' - (Optional) list of the domain names to associate with the firewall policy. Provide either domain names or endpoint names or both.
      - ' endpoint_names' - (Optional) list of the endpoint names to associate with the firewall policy. Provide either domain names or endpoint names or both.
      - ' patterns_to_match' - (Required) The list of paths to match for this firewall policy. Possible value includes /*
  DESCRIPTION
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
    custom_rules = optional(map(object({
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
    })), {})
    managed_rules = optional(map(object({
      type    = string
      version = string
      action  = string
      exclusions = optional(map(object({
        match_variable = string
        operator       = string
        selector       = optional(string)
      })), {})
      overrides = optional(map(object({
        rule_group_name = string
        exclusions = optional(map(object({
          match_variable = string
          operator       = string
          selector       = optional(string)
        })), {})
        rules = optional(map(object({
          rule_id = string
          action  = string
          enabled = optional(bool, false)
          exclusions = optional(map(object({
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
  validation {
    condition = alltrue([for _, v in var.front_door_firewall_policies : alltrue([for _, x in v["custom_rules"] : length(x["match_conditions"]) <= 10 ]) && v["custom_rules"] != null])
    error_message = "If match_condition is used, it should not exceed 10 blocks."
  }
  validation {
    condition     = alltrue([for _, v in var.front_door_firewall_policies : alltrue([for _, x in v["custom_rules"] : alltrue([for _, y in x["match_conditions"] : contains(["Cookies", "PostArgs", "QueryString", "RemoteAddr", "RequestBody", "RequestHeader", "RequestMethod", "RequestUri", "SocketAddr"], y["match_variable"])])])])
    error_message = "Possible values are 'Cookies', 'PostArgs', 'QueryString', 'RemoteAddr', 'RequestBody', 'RequestHeader', 'RequestMethod','RequestUri', or 'SocketAddr' for match_condition."
  }
  validation {
    condition = alltrue([for _, v in var.front_door_firewall_policies : v["custom_rules"] != null ? alltrue([for _, x in v["custom_rules"] : alltrue([for _, y in x["match_conditions"] : length(y["match_values"]) <= 256 ])]) : true])
    error_message = "Each match_value should be up to 256 characters in length."
  }
  validation {
    condition     = alltrue([for _, v in var.front_door_firewall_policies : alltrue([for _, x in v["custom_rules"] : alltrue([for _, y in x["match_conditions"] : contains(["Any", "BeginsWith", "Contains", "EndsWith", "Equal", "GeoMatch", "GreaterThan", "GreaterThanOrEqual", "IPMatch", "LessThan", "LessThanOrEqual", "RegEx"], y["operator"])])])])
    error_message = "Possible values are 'Any', 'BeginsWith', 'Contains', 'EndsWith', 'Equal', 'GeoMatch', 'GreaterThan', 'GreaterThanOrEqual', 'IPMatch', 'LessThan', 'LessThanOrEqua'l or 'RegEx' for operator."
  }
  validation {
    condition = alltrue([for _, v in var.front_door_firewall_policies : alltrue([for _, x in v["custom_rules"] : alltrue([for _, y in x["match_conditions"] : contains(["QueryString", "PostArgs", "RequestHeader", "Cookies"], y["match_variable"]) ? y["selector"] != null : true])])])
    error_message = "If the match_variable is QueryString, PostArgs, RequestHeader, or Cookies, a selector should be provided."
  }
  validation {
    condition     = alltrue([for _, v in var.front_door_firewall_policies : alltrue([for _, x in v["custom_rules"] : alltrue([for _, y in x["match_conditions"] : alltrue([y["transforms"] == null ? true : alltrue([for transform in coalesce(y["transforms"], []) : contains(["Lowercase", "RemoveNulls", "Trim", "Uppercase", "UrlDecode", "UrlEncode"], transform) ]) && length(y["transforms"]) <= 5])])])])
    error_message = "Upto 5 transforms are allowed and Possible values are 'Lowercase', 'RemoveNulls', 'Trim', 'Uppercase', 'URLDecode' or 'URLEncode' for transforms."
  }
  validation {
    condition     = alltrue(flatten([for name, policy in var.front_door_firewall_policies : length(policy["managed_rules"]) > 0 ? policy.sku_name == "Premium_AzureFrontDoor" : true]))
    error_message = "Managed rules should be set only when the Sku_name selected is 'Premium_AzureFrontDoor'."
  }
  validation {
    condition     = alltrue([for _, v in var.front_door_firewall_policies : alltrue([for _, x in v["managed_rules"] : contains(["DefaultRuleSet", "Microsoft_DefaultRuleSet", "BotProtection", "Microsoft_BotManagerRuleSet"], x["type"])])])
    error_message = "Possible values include 'DefaultRuleSet', 'Microsoft_DefaultRuleSet', 'BotProtection' or 'Microsoft_BotManagerRuleSet' for managed_rule type."
  }
description = <<DESCRIPTION
  Manages a Front Door (standard/premium) Firewall Policy instance.
  
  - `name` - (Required) The name which should be used for this Front Door Security Policy. Possible values must not be an empty string.
  - `resource_group_name` - (Required) The name of the resource group. Changing this forces a new resource to be created.
  - 'sku_name' - (Required) The sku's pricing tier for this Front Door Firewall Policy. Possible values include 'Standard_AzureFrontDoor' or 'Premium_AzureFrontDoor'.
  - 'enabled' - (Optional) Is the Front Door Firewall Policy enabled? Defaults to true.
  - 'mode' - (Required) The Front Door Firewall Policy mode. Possible values are 'Detection', 'Prevention'.
  - 'request_body_check_enabled' - (Optional) Should policy managed rules inspect the request body content? Defaults to true.
  - 'redirect_url' - (Optional) If action type is redirect, this field represents redirect URL for the client.
  - 'custom_block_response_status_code' - (Optional) If a custom_rule block's action type is block, this is the response status code. Possible values are 200, 403, 405, 406, or 429.
  - 'custom_block_response_body' - (Optional) If a custom_rule block's action type is block, this is the response body. The body must be specified in base64 encoding.
  - 'custom_rule' - (Optional) One or more custom_rule blocks as defined below.
    - 'name' - (Required) Gets name of the resource that is unique within a policy. This name can be used to access the resource.
    - 'action' - (Required) The action to perform when the rule is matched. Possible values are 'Allow', 'Block', 'Log', or 'Redirect'.
    - 'enabled' - (Optional) Is the rule is enabled or disabled? Defaults to true.
    - 'priority' - (Optional) The priority of the rule. Rules with a lower value will be evaluated before rules with a higher value. Defaults to 1.
    - 'type' - (Required) The type of rule. Possible values are MatchRule or RateLimitRule.
    - 'rate_limit_duration_in_minutes' - (Optional) The rate limit duration in minutes. Defaults to 1.
    - 'rate_limit_threshold' - (Optional) The rate limit threshold. Defaults to 10.
    - 'match_condition' - (Optional) One or more match_condition block defined below. Can support up to 10 match_condition blocks.
      - 'match_variable' - (Required) The request variable to compare with. Possible values are Cookies, PostArgs, QueryString, RemoteAddr, RequestBody, RequestHeader, RequestMethod, RequestUri, or SocketAddr.
      - 'match_values' - (Required) Up to 600 possible values to match. Limit is in total across all match_condition blocks and match_values arguments. String value itself can be up to 256 characters in length.
      - 'operator' - (Required) Comparison type to use for matching with the variable value. Possible values are Any, BeginsWith, Contains, EndsWith, Equal, GeoMatch, GreaterThan, GreaterThanOrEqual, IPMatch, LessThan, LessThanOrEqual or RegEx.
      - 'selector' - (Optional) Match against a specific key if the match_variable is QueryString, PostArgs, RequestHeader or Cookies
      - 'negation_condition' - (Optional) Should the result of the condition be negated.
      - 'transforms' - (Optional) Up to 5 transforms to apply. Possible values are Lowercase, RemoveNulls, Trim, Uppercase, URLDecode or URLEncode.
  - 'managed_rule' -  (Optional) One or more managed_rule blocks as defined below.
    - 'type' - (Required) The name of the managed rule to use with this resource. Possible values include DefaultRuleSet, Microsoft_DefaultRuleSet, BotProtection or Microsoft_BotManagerRuleSet.
    - 'version' - (Required) The version of the managed rule to use with this resource. Possible values depends on which DRS type you are using, for the DefaultRuleSet type the possible values include 1.0 or preview-0.1. For Microsoft_DefaultRuleSet the possible values include 1.1, 2.0 or 2.1. For BotProtection the value must be preview-0.1 and for Microsoft_BotManagerRuleSet the value must be 1.0.
    - 'action' - (Required) The action to perform for all DRS rules when the managed rule is matched or when the anomaly score is 5 or greater depending on which version of the DRS you are using. Possible values include Allow, Log, Block, and Redirect.
    - 'exclusion' - (Optional) One or more exclusion blocks as defined below: -
      - 'match_variable' - (Required) The variable type to be excluded. Possible values are QueryStringArgNames, RequestBodyPostArgNames, RequestCookieNames, RequestHeaderNames, RequestBodyJsonArgNames.
      - 'operator' - (Required) Comparison operator to apply to the selector when specifying which elements in the collection this exclusion applies to. Possible values are: Equals, Contains, StartsWith, EndsWith, EqualsAny.
      - 'selector' - (Required) Selector for the value in the match_variable attribute this exclusion applies to.
    - 'override' - (Optional) One or more override blocks as defined below: -
      - 'rule_group_name' - (Required) The managed rule group to override.
      - 'exclusion' - (Optional) One or more exclusion blocks as defined below: -
      - 'rule' - (Optional) One or more rule blocks as defined below. If none are specified, all of the rules in the group will be disabled: -
        - 'rule_id' - (Required) Identifier for the managed rule.
        - 'action' - (Required) The action to be applied when the managed rule matches or when the anomaly score is 5 or greater. Possible values for DRS 1.1 and below are Allow, Log, Block, and Redirect. For DRS 2.0 and above the possible values are Log or AnomalyScoring.
        - 'enabled' - (Optional) Is the managed rule override enabled or disabled. Defaults to false.
        - 'exclusion' - (Optional) One or more exclusion blocks as defined below: -
          - 'match_variable' - (Required) The variable type to be excluded. Possible values are QueryStringArgNames, RequestBodyPostArgNames, RequestCookieNames, RequestHeaderNames, RequestBodyJsonArgNames.
          - 'operator' - (Required) Comparison operator to apply to the selector when specifying which elements in the collection this exclusion applies to. Possible values are: Equals, Contains, StartsWith, EndsWith, EqualsAny.
          - 'selector' - (Required) Selector for the value in the match_variable attribute this exclusion applies to.
  - 'tags' - (Optional) A mapping of tags to assign to the Front Door Firewall Policy.
/*
  DESCRIPTION
}




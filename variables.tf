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
    #   origins = map(object({
    #   name                           = string
    #   origin_group_name              = string
    #   host_name                      = string
    #   certificate_name_check_enabled = string
    #   enabled                        = string
    #   http_port                      = optional(number, 80)
    #   https_port                     = optional(number, 443)
    #   host_header                    = optional(string, null)
    #   priority                       = optional(number, 1)
    #   weight                         = optional(number, 500)
    # }))
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

#variable "rule_set" {
#  type = map(any)

#}

variable "rules" {
  type = map(object({
    name              = string
    rule_set_name     = string
    origin_group_name = string
    order             = number
    actions = map(object({
      url_rewrite_action = optional(map(object({
        source_pattern          = string
        destination             = string
        preserve_unmatched_path = optional(bool, false)
      })), {})
      url_redirect_action = optional(map(object({
        redirect_type        = string
        destination_hostname = string
        redirect_protocol    = optional(string, "MatchRequest")
        destination_path     = optional(string, "")
        query_string         = optional(string, "")
        destination_fragment = optional(string, "")
      })), {})
      route_configuration_override_action = optional(map(object({
        cache_duration                = optional(string)
        forwarding_protocol           = optional(string)
        query_string_caching_behavior = optional(string)
        query_string_parameters       = optional(list(string))
        compression_enabled           = optional(bool)
        cache_behavior                = optional(string)
      })), {})
      request_header_action = optional(map(object({
        header_action = string
        header_name   = string
        value         = string
      })), {})
      response_header_action = optional(map(object({
        header_action = string
        header_name   = string
        value         = string
      })), {})
    }))
    behavior_on_match = optional(string, "continue")
    conditions = optional(map(object({
      remote_address_condition = optional(map(object({
        operator         = optional(string, "IPMatch")
        match_values     = optional(list(string))
        megate_condition = optional(bool, false)
      })), {})
      request_method_condition = optional(map(object({
        operator         = optional(string, "Equal")
        match_values     = list(string)
        megate_condition = optional(bool, false)
      })), {})
      query_string_condition = optional(map(object({
        operator         = string
        match_values     = optional(list(any))
        transforms       = optional(string)
        megate_condition = optional(bool, false)
      })), {})
      post_args_condition = optional(map(object({
        post_args_name   = string
        operator         = string
        match_values     = optional(list(any))
        transforms       = optional(string)
        megate_condition = optional(bool, false)
      })), {})
      request_uri_condition = optional(map(object({
        operator         = string
        match_values     = optional(list(any))
        transforms       = optional(string)
        megate_condition = optional(bool, false)
      })), {})
      request_header_condition = optional(map(object({
        header_name      = string
        operator         = string
        match_values     = optional(list(any))
        transforms       = optional(string)
        megate_condition = optional(bool, false)
      })), {})
      request_body_condition = optional(map(object({
        operator         = string
        match_values     = list(any)
        transforms       = optional(string)
        megate_condition = optional(bool, false)
      })), {})
      request_scheme_condition = optional(map(object({
        operator         = optional(string, "Equal")
        match_values     = optional(string)
        megate_condition = optional(bool, false)
      })), {})
      url_path_condition = optional(map(object({
        operator         = string
        match_values     = optional(list(any))
        transforms       = optional(string)
        megate_condition = optional(bool, false)
      })), {})
      url_file_extension_condition = optional(map(object({
        operator         = string
        match_values     = list(any)
        transforms       = optional(string)
        megate_condition = optional(bool, false)
      })), {})
      url_filename_condition = optional(map(object({
        operator         = string
        match_values     = optional(list(any))
        transforms       = optional(string)
        megate_condition = optional(bool, false)
      })), {})
      http_version_condition = optional(map(object({
        operator         = optional(string, "Equal")
        match_values     = number
        megate_condition = optional(bool, false)
      })), {})
      cookies_condition = optional(map(object({
        cookie_name      = string
        operator         = string
        match_values     = optional(list(any))
        transforms       = optional(string)
        megate_condition = optional(bool, false)
      })), {})
      is_device_condition = optional(map(object({
        operator         = optional(string, "Equal")
        match_values     = string
        megate_condition = optional(bool, false)
      })), {})
      socket_address_condition = optional(map(object({
        operator         = optional(string, "IPMatch")
        match_values     = optional(list(string))
        megate_condition = optional(bool, false)
      })), {})
      client_port_condition = optional(map(object({
        operator         = string
        match_values     = list(number)
        megate_condition = optional(bool, false)
      })), {})
      server_port_condition = optional(map(object({
        operator         = string
        match_values     = list(number)
        megate_condition = optional(bool, false)
      })), {})
      host_name_condition = optional(map(object({
        operator         = string
        match_values     = optional(list(string))
        transforms       = string
        megate_condition = optional(bool, false)
      })), {})
      ssl_protocol_condition = optional(map(object({
        match_values     = list(string)
        operator         = optional(string, "Equal")
        negate_condition = optional(bool, false)
      })), {})
    })), {})
  }))
}



resource "azurerm_cdn_frontdoor_rule_set" "rule_set" {
  for_each = var.front_door_rule_sets

  cdn_frontdoor_profile_id = azapi_resource.front_door_profile.id
  name                     = each.value
}

resource "azurerm_cdn_frontdoor_rule" "rules" {
  for_each = var.front_door_rules

  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.rule_set[each.value.rule_set_name].id
  name                      = each.value.name
  order                     = each.value.order
  behavior_on_match         = each.value.behavior_on_match

  actions {
    dynamic "request_header_action" {
      for_each = each.value.actions.request_header_actions

      content {
        header_action = request_header_action.value.header_action
        header_name   = request_header_action.value.header_name
        value         = request_header_action.value.value
      }
    }
    dynamic "response_header_action" {
      for_each = each.value.actions.response_header_actions

      content {
        header_action = response_header_action.value.header_action
        header_name   = response_header_action.value.header_name
        value         = response_header_action.value.value
      }
    }
    dynamic "route_configuration_override_action" {
      for_each = each.value.actions.route_configuration_override_actions

      content {
        cache_behavior                = route_configuration_override_action.value.cache_behavior
        cache_duration                = route_configuration_override_action.value.cache_duration
        cdn_frontdoor_origin_group_id = route_configuration_override_action.value.set_origin_groupid == true ? azurerm_cdn_frontdoor_origin_group.origin_groups[each.value.origin_group_key].id : null
        compression_enabled           = route_configuration_override_action.value.compression_enabled
        forwarding_protocol           = route_configuration_override_action.value.forwarding_protocol
        query_string_caching_behavior = route_configuration_override_action.value.query_string_caching_behavior
        query_string_parameters       = route_configuration_override_action.value.query_string_parameters
      }
    }
    dynamic "url_redirect_action" {
      for_each = each.value.actions.url_redirect_actions

      content {
        destination_hostname = url_redirect_action.value.destination_hostname
        redirect_type        = url_redirect_action.value.redirect_type
        destination_fragment = url_redirect_action.value.destination_fragment
        destination_path     = url_redirect_action.value.destination_path
        query_string         = url_redirect_action.value.query_string
        redirect_protocol    = url_redirect_action.value.redirect_protocol
      }
    }
    dynamic "url_rewrite_action" {
      for_each = each.value.actions.url_rewrite_actions

      content {
        destination             = url_rewrite_action.value.destination
        source_pattern          = url_rewrite_action.value.source_pattern
        preserve_unmatched_path = url_rewrite_action.value.preserve_unmatched_path
      }
    }
  }
  conditions {
    dynamic "client_port_condition" {
      for_each = each.value.conditions.client_port_conditions

      content {
        operator         = client_port_condition.value.operator
        match_values     = client_port_condition.value.match_values
        negate_condition = client_port_condition.value.negate_condition
      }
    }
    dynamic "cookies_condition" {
      for_each = each.value.conditions.cookies_conditions

      content {
        cookie_name      = cookies_condition.value.cookie_name
        operator         = cookies_condition.value.operator
        match_values     = cookies_condition.value.match_values
        negate_condition = cookies_condition.value.negate_condition
        transforms       = cookies_condition.value.transforms
      }
    }
    dynamic "host_name_condition" {
      for_each = each.value.conditions.host_name_conditions

      content {
        operator         = host_name_condition.value.operator
        match_values     = host_name_condition.value.match_values
        negate_condition = host_name_condition.value.negate_condition
        transforms       = host_name_condition.value.transforms
      }
    }
    dynamic "http_version_condition" {
      for_each = each.value.conditions.http_version_conditions

      content {
        match_values     = http_version_condition.value.match_values
        negate_condition = http_version_condition.value.negate_condition
        operator         = http_version_condition.value.operator
      }
    }
    dynamic "is_device_condition" {
      for_each = each.value.conditions.is_device_conditions

      content {
        match_values     = is_device_condition.value.match_values
        negate_condition = is_device_condition.value.negate_condition
        operator         = is_device_condition.value.operator
      }
    }
    dynamic "post_args_condition" {
      for_each = each.value.conditions.post_args_conditions

      content {
        operator         = post_args_condition.value.operator
        post_args_name   = post_args_condition.value.post_args_name
        match_values     = post_args_condition.value.match_values
        negate_condition = post_args_condition.value.negate_condition
        transforms       = post_args_condition.value.transforms
      }
    }
    dynamic "query_string_condition" {
      for_each = each.value.conditions.query_string_conditions

      content {
        operator         = query_string_condition.value.operator
        match_values     = query_string_condition.value.match_values
        negate_condition = query_string_condition.value.negate_condition
        transforms       = query_string_condition.value.transforms
      }
    }
    dynamic "remote_address_condition" {
      for_each = each.value.conditions.remote_address_conditions

      content {
        match_values     = remote_address_condition.value.match_values
        negate_condition = remote_address_condition.value.negate_condition
        operator         = remote_address_condition.value.operator
      }
    }
    dynamic "request_body_condition" {
      for_each = each.value.conditions.request_body_conditions

      content {
        match_values     = request_body_condition.value.match_values
        operator         = request_body_condition.value.operator
        negate_condition = request_body_condition.value.negate_condition
        transforms       = request_body_condition.value.transforms
      }
    }
    dynamic "request_header_condition" {
      for_each = each.value.conditions.request_header_conditions

      content {
        header_name      = request_header_condition.value.header_name
        operator         = request_header_condition.value.operator
        match_values     = request_header_condition.value.match_values
        negate_condition = request_header_condition.value.negate_condition
        transforms       = request_header_condition.value.transforms
      }
    }
    dynamic "request_method_condition" {
      for_each = each.value.conditions.request_method_conditions

      content {
        match_values     = request_method_condition.value.match_values
        negate_condition = request_method_condition.value.negate_condition
        operator         = request_method_condition.value.operator
      }
    }
    dynamic "request_scheme_condition" {
      for_each = each.value.conditions.request_scheme_conditions

      content {
        match_values     = request_scheme_condition.value.match_values
        negate_condition = request_scheme_condition.value.negate_condition
        operator         = request_scheme_condition.value.operator
      }
    }
    dynamic "request_uri_condition" {
      for_each = each.value.conditions.request_uri_conditions

      content {
        operator         = request_uri_condition.value.operator
        match_values     = request_uri_condition.value.match_values
        negate_condition = request_uri_condition.value.negate_condition
        transforms       = request_uri_condition.value.transforms
      }
    }
    dynamic "server_port_condition" {
      for_each = each.value.conditions.server_port_conditions

      content {
        match_values     = server_port_condition.value.match_values
        operator         = server_port_condition.value.operator
        negate_condition = server_port_condition.value.negate_condition
      }
    }
    dynamic "socket_address_condition" {
      for_each = each.value.conditions.socket_address_conditions

      content {
        match_values     = socket_address_condition.value.match_values
        negate_condition = socket_address_condition.value.negate_condition
        operator         = socket_address_condition.value.operator
      }
    }
    dynamic "ssl_protocol_condition" {
      for_each = each.value.conditions.ssl_protocol_conditions

      content {
        match_values     = ssl_protocol_condition.value.match_values
        negate_condition = ssl_protocol_condition.value.negate_condition
        operator         = ssl_protocol_condition.value.operator
      }
    }
    dynamic "url_file_extension_condition" {
      for_each = each.value.conditions.url_file_extension_conditions

      content {
        match_values     = url_file_extension_condition.value.match_values
        operator         = url_file_extension_condition.value.operator
        negate_condition = url_file_extension_condition.value.negate_condition
        transforms       = url_file_extension_condition.value.transforms
      }
    }
    dynamic "url_filename_condition" {
      for_each = each.value.conditions.url_filename_conditions

      content {
        operator         = url_filename_condition.value.operator
        match_values     = url_filename_condition.value.match_values
        negate_condition = url_filename_condition.value.negate_condition
        transforms       = url_filename_condition.value.transforms
      }
    }
    dynamic "url_path_condition" {
      for_each = each.value.conditions.url_path_conditions

      content {
        operator         = url_path_condition.value.operator
        match_values     = url_path_condition.value.match_values
        negate_condition = url_path_condition.value.negate_condition
        transforms       = url_path_condition.value.transforms
      }
    }
  }

  depends_on = [azurerm_cdn_frontdoor_origin_group.origin_groups, azurerm_cdn_frontdoor_origin.origins]
}
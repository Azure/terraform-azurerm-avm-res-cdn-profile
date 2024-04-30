resource "azurerm_cdn_frontdoor_rule_set" "rule_set" {
  for_each = var.rule_sets

  cdn_frontdoor_profile_id = azapi_resource.front_door_profile.id
  name                     = each.value
}

resource "azurerm_cdn_frontdoor_rule" "rules" {
  for_each = var.rules

  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.rule_set[each.value.rule_set_name].id
  name                      = each.value.name
  order                     = each.value.order
  behavior_on_match         = each.value.behavior_on_match

  actions {
    dynamic "request_header_action" {
      for_each = { for key, value in each.value.actions : key => value
        if key == "request_header_action"
      }

      content {
        header_action = request_header_action.value.header_action
        header_name   = request_header_action.value.header_name
        value         = request_header_action.value.value
      }
    }
    dynamic "response_header_action" {
      for_each = { for key, value in each.value.actions : key => value
        if key == "response_header_action"
      }

      content {
        header_action = response_header_action.value.header_action
        header_name   = response_header_action.value.header_name
        value         = response_header_action.value.value
      }
    }
    dynamic "route_configuration_override_action" {
      for_each = { for key, value in each.value.actions : key => value
        if key == "route_configuration_override_action"
      }

      content {
        cache_behavior                = route_configuration_override_action.value.cache_behavior
        cache_duration                = route_configuration_override_action.value.cache_duration
        cdn_frontdoor_origin_group_id = try(route_configuration_override_action.value.set_origin_groupid == true ? azurerm_cdn_frontdoor_origin_group.example[each.value.origin_group_name].id : null)
        compression_enabled           = route_configuration_override_action.value.compression_enabled
        forwarding_protocol           = try(route_configuration_override_action.value.forwarding_protocol, null)
        query_string_caching_behavior = try(route_configuration_override_action.value.query_string_caching_behavior, null)
        query_string_parameters       = route_configuration_override_action.value.query_string_parameters
      }
    }
    dynamic "url_redirect_action" {
      for_each = { for key, value in each.value.actions : key => value
        if key == "url_redirect_action"
      }

      content {
        destination_hostname = url_redirect_action.value.destination_hostname
        redirect_type        = url_redirect_action.value.redirect_type
        destination_fragment = try(url_redirect_action.value.destination_fragment, "")
        destination_path     = try(url_redirect_action.value.destination_path, "")
        query_string         = try(url_redirect_action.value.query_string, "")
        redirect_protocol    = try(url_redirect_action.value.redirect_protocol, "MatchRequest")
      }
    }
    dynamic "url_rewrite_action" {
      for_each = { for key, value in each.value.actions : key => value
        if key == "url_rewrite_action"
      }

      content {
        destination             = url_rewrite_action.value.destination
        source_pattern          = url_rewrite_action.value.source_pattern
        preserve_unmatched_path = try(url_rewrite_action.value.preserve_unmatched_path, false)
      }
    }
  }
  conditions {
    dynamic "client_port_condition" {
      for_each = { for key, value in each.value.conditions : key => value
        if key == "client_port_condition"
      }
      content {
        operator         = client_port_condition.value.operator
        match_values     = client_port_condition.value.match_values
        negate_condition = try(client_port_condition.value.negate_condition, false)
      }
    }
    dynamic "cookies_condition" {
      for_each = { for key, value in each.value.conditions : key => value
        if key == "cookies_condition"
      }
      content {
        cookie_name      = cookies_condition.value.cookie_name
        operator         = cookies_condition.value.operator
        match_values     = cookies_condition.value.match_values
        negate_condition = try(cookies_condition.value.negate_condition, false)
        transforms       = cookies_condition.value.transforms
      }
    }
    dynamic "host_name_condition" {
      for_each = { for key, value in each.value.conditions : key => value
        if key == "host_name_condition"
      }
      content {
        operator         = host_name_condition.value.operator
        match_values     = host_name_condition.value.match_values
        negate_condition = try(host_name_condition.value.negate_condition, false)
        transforms       = host_name_condition.value.transforms
      }
    }
    dynamic "http_version_condition" {
      for_each = { for key, value in each.value.conditions : key => value
        if key == "http_version_condition"
      }
      content {
        match_values     = http_version_condition.value.match_values
        negate_condition = try(http_version_condition.value.negate_condition, false)
        operator         = try(http_version_condition.value.operator, "Equal")
      }
    }
    dynamic "is_device_condition" {
      for_each = { for key, value in each.value.conditions : key => value
        if key == "is_device_condition"
      }
      content {
        match_values     = is_device_condition.value.match_values
        negate_condition = try(is_device_condition.value.negate_condition, false)
        operator         = try(is_device_condition.value.operator, "Equal")
      }
    }
    dynamic "post_args_condition" {
      for_each = { for key, value in each.value.conditions : key => value
        if key == "post_args_condition"
      }
      content {
        operator         = post_args_condition.value.operator
        post_args_name   = post_args_condition.value.post_args_name
        match_values     = post_args_condition.value.match_values
        negate_condition = try(post_args_condition.value.negate_condition, false)
        transforms       = post_args_condition.value.transforms
      }
    }
    dynamic "query_string_condition" {
      for_each = { for key, value in each.value.conditions : key => value
        if key == "query_string_condition"
      }
      content {
        operator         = query_string_condition.value.operator
        match_values     = query_string_condition.value.match_values
        negate_condition = try(query_string_condition.value.negate_condition, false)
        transforms       = query_string_condition.value.transforms
      }
    }
    dynamic "remote_address_condition" {
      for_each = { for key, value in each.value.conditions : key => value
        if key == "remote_address_condition"
      }
      content {
        match_values     = remote_address_condition.value.match_values
        negate_condition = try(remote_address_condition.value.negate_condition, false)
        operator         = try(remote_address_condition.value.operator, "IPMatch")
      }
    }
    dynamic "request_body_condition" {
      for_each = { for key, value in each.value.conditions : key => value
        if key == "request_body_condition"
      }
      content {
        match_values     = request_body_condition.value.match_values
        operator         = request_body_condition.value.operator
        negate_condition = try(request_body_condition.value.negate_condition, false)
        transforms       = request_body_condition.value.transforms
      }
    }
    dynamic "request_header_condition" {
      for_each = { for key, value in each.value.conditions : key => value
        if key == "request_header_condition"
      }
      content {
        header_name      = request_header_condition.value.header_name
        operator         = request_header_condition.value.operator
        match_values     = request_header_condition.value.match_values
        negate_condition = try(request_header_condition.value.negate_condition, false)
        transforms       = request_header_condition.value.transforms
      }
    }
    dynamic "request_method_condition" {
      for_each = { for key, value in each.value.conditions : key => value
        if key == "request_method_condition"
      }
      content {
        match_values     = request_method_condition.value.match_values
        negate_condition = try(request_method_condition.value.negate_condition, false)
        operator         = try(request_method_condition.value.operator, "Equal")
      }
    }
    dynamic "request_scheme_condition" {
      for_each = { for key, value in each.value.conditions : key => value
        if key == "request_scheme_condition"
      }
      content {
        match_values     = request_scheme_condition.value.match_values
        negate_condition = try(request_scheme_condition.value.negate_condition, false)
        operator         = try(request_scheme_condition.value.operator, "Equal")
      }
    }
    dynamic "request_uri_condition" {
      for_each = { for key, value in each.value.conditions : key => value
        if key == "request_uri_condition"
      }
      content {
        operator         = request_uri_condition.value.operator
        match_values     = request_uri_condition.value.match_values
        negate_condition = try(request_uri_condition.value.negate_condition, false)
        transforms       = request_uri_condition.value.transforms
      }
    }
    dynamic "server_port_condition" {
      for_each = { for key, value in each.value.conditions : key => value
        if key == "server_port_condition"
      }
      content {
        match_values     = server_port_condition.value.match_values
        operator         = server_port_condition.value.operator
        negate_condition = try(server_port_condition.value.negate_condition, false)
      }
    }
    dynamic "socket_address_condition" {
      for_each = { for key, value in each.value.conditions : key => value
        if key == "socket_address_condition"
      }
      content {
        match_values     = socket_address_condition.value.match_values
        negate_condition = try(socket_address_condition.value.negate_condition, false)
        operator         = try(socket_address_condition.value.operator, "IPMatch")
      }
    }
    dynamic "ssl_protocol_condition" {
      for_each = { for key, value in each.value.conditions : key => value
        if key == "ssl_protocol_condition"
      }
      content {
        match_values     = ssl_protocol_condition.value.match_values
        negate_condition = try(ssl_protocol_condition.value.negate_condition, false)
        operator         = ssl_protocol_condition.value.operator
      }
    }
    dynamic "url_file_extension_condition" {
      for_each = { for key, value in each.value.conditions : key => value
        if key == "url_file_extension_condition"
      }
      content {
        match_values     = url_file_extension_condition.value.match_values
        operator         = url_file_extension_condition.value.operator
        negate_condition = try(url_file_extension_condition.value.negate_condition, false)
        transforms       = url_file_extension_condition.value.transforms
      }
    }
    dynamic "url_filename_condition" {
      for_each = { for key, value in each.value.conditions : key => value
        if key == "url_filename_condition"
      }
      content {
        operator         = url_filename_condition.value.operator
        match_values     = url_filename_condition.value.match_values
        negate_condition = try(url_filename_condition.value.negate_condition, false)
        transforms       = url_filename_condition.value.transforms
      }
    }
    dynamic "url_path_condition" {
      for_each = { for key, value in each.value.conditions : key => value
        if key == "url_path_condition"
      }
      content {
        operator         = url_path_condition.value.operator
        match_values     = url_path_condition.value.match_values
        negate_condition = try(url_path_condition.value.negate_condition, false)
        transforms       = url_path_condition.value.transforms
      }
    }
  }

  depends_on = [azurerm_cdn_frontdoor_origin_group.example, azurerm_cdn_frontdoor_origin.origins]
}
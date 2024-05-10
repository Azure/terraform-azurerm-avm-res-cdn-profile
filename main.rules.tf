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
      for_each = { for key, value in each.value.actions : key => value
        if key == "request_header_action"
      }

      content {
        header_action = try(request_header_action.value.header_action,null)
        header_name   = try(request_header_action.value.header_name,null)
        value         = try(request_header_action.value.value,null)
      }
    }
    dynamic "response_header_action" {
      for_each = { for key, value in each.value.actions : key => value
        if key == "response_header_action"
      }

      content {
        header_action = try(response_header_action.value.header_action,null)
        header_name   = try(response_header_action.value.header_name,null)
        value         = try(response_header_action.value.value,null)
      }
    }
    dynamic "route_configuration_override_action" {
      for_each = { for key, value in each.value.actions : key => value
        if key == "route_configuration_override_action"
      }

      content {
        cache_behavior                = try(route_configuration_override_action.value.cache_behavior, null)
        cache_duration                = try(route_configuration_override_action.value.cache_duration, null)
        cdn_frontdoor_origin_group_id = try(route_configuration_override_action.value.set_origin_groupid == true ? azurerm_cdn_frontdoor_origin_group.example[each.value.origin_group_name].id : null, null)
        compression_enabled           = try(route_configuration_override_action.value.compression_enabled, null)
        forwarding_protocol           = try(route_configuration_override_action.value.forwarding_protocol, null)
        query_string_caching_behavior = try(route_configuration_override_action.value.query_string_caching_behavior, null)
        query_string_parameters       = try(route_configuration_override_action.value.query_string_parameters, null)
      }
    }
    dynamic "url_redirect_action" {
      for_each = { for key, value in each.value.actions : key => value
        if key == "url_redirect_action"
      }

      content {
        destination_hostname = try(url_redirect_action.value.destination_hostname, null)
        redirect_type        = try(url_redirect_action.value.redirect_type, null)
        destination_fragment = try(url_redirect_action.value.destination_fragment, null)
        destination_path     = try(url_redirect_action.value.destination_path, null)
        query_string         = try(url_redirect_action.value.query_string, null)
        redirect_protocol    = try(url_redirect_action.value.redirect_protocol, null)
      }
    }
    dynamic "url_rewrite_action" {
      for_each = { for key, value in each.value.actions : key => value
        if key == "url_rewrite_action"
      }

      content {
        destination             = try(url_rewrite_action.value.destination, null)
        source_pattern          = try(url_rewrite_action.value.source_pattern, null)
        preserve_unmatched_path = try(url_rewrite_action.value.preserve_unmatched_path, null)
      }
    }
  }
  conditions {
    dynamic "client_port_condition" {
      for_each = { for key, value in each.value.conditions : key => value
        if key == "client_port_condition"
      }
      content {
        operator         = try(client_port_condition.value.operator, null)
        match_values     = try(client_port_condition.value.match_values, null)
        negate_condition = try(client_port_condition.value.negate_condition, null)
      }
    }
    dynamic "cookies_condition" {
      for_each = { for key, value in each.value.conditions : key => value
        if key == "cookies_condition"
      }
      content {
        cookie_name      = try(cookies_condition.value.cookie_name,null)
        operator         = try(cookies_condition.value.operator,null)
        match_values     = try(cookies_condition.value.match_values,null)
        negate_condition = try(cookies_condition.value.negate_condition,null)
        transforms       = try(cookies_condition.value.transforms, null)
      }
    }
    dynamic "host_name_condition" {
      for_each = { for key, value in each.value.conditions : key => value
        if key == "host_name_condition"
      }
      content {
        operator         = try(host_name_condition.value.operator,null)
        match_values     = try(host_name_condition.value.match_values,null)
        negate_condition = try(host_name_condition.value.negate_condition,null)
        transforms       = try(host_name_condition.value.transforms,null)
      }
    }
    dynamic "http_version_condition" {
      for_each = { for key, value in each.value.conditions : key => value
        if key == "http_version_condition"
      }
      content {
        match_values     = try(http_version_condition.value.match_values,null)
        negate_condition = try(http_version_condition.value.negate_condition,null)
        operator         = try(http_version_condition.value.operator,null)
      }
    }
    dynamic "is_device_condition" {
      for_each = { for key, value in each.value.conditions : key => value
        if key == "is_device_condition"
      }
      content {
        match_values     = try(is_device_condition.value.match_values,null)
        negate_condition = try(is_device_condition.value.negate_condition,null)
        operator         = try(is_device_condition.value.operator, "Equal")
      }
    }
    dynamic "post_args_condition" {
      for_each = { for key, value in each.value.conditions : key => value
        if key == "post_args_condition"
      }
      content {
        operator         = try(post_args_condition.value.operator,null)
        post_args_name   = try(post_args_condition.value.post_args_name,null)
        match_values     = try(post_args_condition.value.match_values,null)
        negate_condition = try(post_args_condition.value.negate_condition,null)
        transforms       = try(post_args_condition.value.transforms,null)
      }
    }
    dynamic "query_string_condition" {
      for_each = { for key, value in each.value.conditions : key => value
        if key == "query_string_condition"
      }
      content {
        operator         = try(query_string_condition.value.operator,null)
        match_values     = try(query_string_condition.value.match_values,null)
        negate_condition = try(query_string_condition.value.negate_condition,null)
        transforms       = try(query_string_condition.value.transforms,null)
      }
    }
    dynamic "remote_address_condition" {
      for_each = { for key, value in each.value.conditions : key => value
        if key == "remote_address_condition"
      }
      content {
        match_values     = try(remote_address_condition.value.match_values,null)
        negate_condition = try(remote_address_condition.value.negate_condition,null)
        operator         = try(remote_address_condition.value.operator,null)
      }
    }
    dynamic "request_body_condition" {
      for_each = { for key, value in each.value.conditions : key => value
        if key == "request_body_condition"
      }
      content {
        match_values     = try(request_body_condition.value.match_values,null)
        operator         = try(request_body_condition.value.operator,null)
        negate_condition = try(request_body_condition.value.negate_condition,null)
        transforms       = try(request_body_condition.value.transforms,null)
      }
    }
    dynamic "request_header_condition" {
      for_each = { for key, value in each.value.conditions : key => value
        if key == "request_header_condition"
      }
      content {
        header_name      = try(request_header_condition.value.header_name,null)
        operator         = try(request_header_condition.value.operator,null)
        match_values     = try(request_header_condition.value.match_values,null)
        negate_condition = try(request_header_condition.value.negate_condition,null)
        transforms       = try(request_header_condition.value.transforms,null)
      }
    }
    dynamic "request_method_condition" {
      for_each = { for key, value in each.value.conditions : key => value
        if key == "request_method_condition"
      }
      content {
        match_values     = try(request_method_condition.value.match_values,null)
        negate_condition = try(request_method_condition.value.negate_condition,null)
        operator         = try(request_method_condition.value.operator,null)
      }
    }
    dynamic "request_scheme_condition" {
      for_each = { for key, value in each.value.conditions : key => value
        if key == "request_scheme_condition"
      }
      content {
        match_values     = try(request_scheme_condition.value.match_values,null)
        negate_condition = try(request_scheme_condition.value.negate_condition,null)
        operator         = try(request_scheme_condition.value.operator,null)
      }
    }
    dynamic "request_uri_condition" {
      for_each = { for key, value in each.value.conditions : key => value
        if key == "request_uri_condition"
      }
      content {
        operator         = try(request_uri_condition.value.operator,null)
        match_values     = try(request_uri_condition.value.match_values,null)
        negate_condition = try(request_uri_condition.value.negate_condition,null)
        transforms       = try(request_uri_condition.value.transforms,null)
      }
    }
    dynamic "server_port_condition" {
      for_each = { for key, value in each.value.conditions : key => value
        if key == "server_port_condition"
      }
      content {
        match_values     = try(server_port_condition.value.match_values,null)
        operator         = try(server_port_condition.value.operator,null)
        negate_condition = try(server_port_condition.value.negate_condition,null)
      }
    }
    dynamic "socket_address_condition" {
      for_each = { for key, value in each.value.conditions : key => value
        if key == "socket_address_condition"
      }
      content {
        match_values     = try(socket_address_condition.value.match_values, null)
        negate_condition = try(socket_address_condition.value.negate_condition, null)
        operator         = try(socket_address_condition.value.operator, null)
      }
    }
    dynamic "ssl_protocol_condition" {
      for_each = { for key, value in each.value.conditions : key => value
        if key == "ssl_protocol_condition"
      }
      content {
        match_values     = try(ssl_protocol_condition.value.match_values, null)
        negate_condition = try(ssl_protocol_condition.value.negate_condition, null)
        operator         = try(ssl_protocol_condition.value.operator, null)
      }
    }
    dynamic "url_file_extension_condition" {
      for_each = { for key, value in each.value.conditions : key => value
        if key == "url_file_extension_condition"
      }
      content {
        match_values     = try(url_file_extension_condition.value.match_values, null)
        operator         = try(url_file_extension_condition.value.operator, null)
        negate_condition = try(url_file_extension_condition.value.negate_condition, null)
        transforms       = try(url_file_extension_condition.value.transforms, null)
      }
    }
    dynamic "url_filename_condition" {
      for_each = { for key, value in each.value.conditions : key => value
        if key == "url_filename_condition"
      }
      content {
        operator         = try(url_filename_condition.value.operator, null)
        match_values     = try(url_filename_condition.value.match_values, null)
        negate_condition = try(url_filename_condition.value.negate_condition, null)
        transforms       = try(url_filename_condition.value.transforms, null)
      }
    }
    dynamic "url_path_condition" {
      for_each = { for key, value in each.value.conditions : key => value
        if key == "url_path_condition"
      }
      content {
        operator         = try(url_path_condition.value.operator, null)
        match_values     = try(url_path_condition.value.match_values, null)
        negate_condition = try(url_path_condition.value.negate_condition, null)
        transforms       = try(url_path_condition.value.transforms, null)
      }
    }
  }

  depends_on = [azurerm_cdn_frontdoor_origin_group.example, azurerm_cdn_frontdoor_origin.origins]
}
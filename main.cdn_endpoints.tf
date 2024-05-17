resource "azurerm_cdn_endpoint" "endpoint" {
  for_each = var.cdn_endpoints

  location                      = var.location
  name                          = each.value.name
  profile_name                  = azapi_resource.front_door_profile.name
  resource_group_name           = var.resource_group_name
  content_types_to_compress     = each.value.content_types_to_compress
  is_compression_enabled        = each.value.is_compression_enabled
  is_http_allowed               = each.value.is_http_allowed
  is_https_allowed              = each.value.is_https_allowed
  origin_host_header            = each.value.origin_host_header
  origin_path                   = each.value.origin_path
  probe_path                    = each.value.probe_path
  querystring_caching_behaviour = each.value.querystring_caching_behaviour
  tags                          = each.value.tags

  dynamic "origin" {
    for_each = each.value.origins
    content {
      host_name = origin.value.host_name
      name      = origin.value.name
    }
  }
  # azurerm_cdn_endpoint supports `global_delivery_rule` and `delivery_rule` only when `Standard_Microsoft` sku is used.
  dynamic "delivery_rule" {
    for_each = coalesce(each.value.delivery_rules, [])
    content {
      name  = delivery_rule.value.name
      order = delivery_rule.value.order
      dynamic "cache_expiration_action" {
        for_each = delivery_rule.value.cache_expiration_action
        content {
          behavior = cache_expiration_action.value.behavior
          duration = cache_expiration_action.value.duration
        }
      }
      dynamic "cache_key_query_string_action" {
        for_each = delivery_rule.value.cache_key_query_string_action
        content {
          behavior   = cache_key_query_string_action.value.behavior
          parameters = cache_key_query_string_action.value.parameters
        }
      }
      dynamic "cookies_condition" {
        for_each = delivery_rule.value.cookies_condition
        content {
          selector         = cookies_condition.value.selector
          operator         = cookies_condition.value.operator
          negate_condition = cookies_condition.value.negate_condition
          match_values     = cookies_condition.value.match_values
          transforms       = cookies_condition.value.transforms
        }
      }
      dynamic "device_condition" {
        for_each = delivery_rule.value.device_condition
        content {
          operator         = device_condition.value.operator
          negate_condition = device_condition.value.negate_condition
          match_values     = device_condition.value.match_values
        }
      }

      dynamic "http_version_condition" {
        for_each = delivery_rule.value.http_version_condition
        content {
          operator         = http_version_condition.value.operator
          negate_condition = http_version_condition.value.negate_condition
          match_values     = http_version_condition.value.match_values
        }
      }

      dynamic "modify_request_header_action" {
        for_each = delivery_rule.value.modify_request_header_action
        content {
          name   = modify_request_header_action.value.name
          action = modify_request_header_action.value.action
          value  = modify_request_header_action.value.value
        }
      }

      dynamic "modify_response_header_action" {
        for_each = delivery_rule.value.modify_response_header_action
        content {
          name   = modify_response_header_action.value.name
          action = modify_response_header_action.value.action
          value  = modify_response_header_action.value.value
        }
      }
      dynamic "post_arg_condition" {
        for_each = delivery_rule.value.post_arg_condition
        content {
          selector         = post_arg_condition.value.selector
          operator         = post_arg_condition.value.operator
          negate_condition = post_arg_condition.value.negate_condition
          match_values     = post_arg_condition.value.match_values
          transforms       = post_arg_condition.value.transforms
        }
      }
      dynamic "query_string_condition" {
        for_each = delivery_rule.value.query_string_condition
        content {
          operator         = query_string_condition.value.operator
          negate_condition = query_string_condition.value.negate_condition
          match_values     = query_string_condition.value.match_values
          transforms       = query_string_condition.value.transforms
        }
      }
      dynamic "remote_address_condition" {
        for_each = delivery_rule.value.remote_address_condition
        content {
          operator         = remote_address_condition.value.operator
          negate_condition = remote_address_condition.value.negate_condition
          match_values     = remote_address_condition.value.match_values
        }
      }
      dynamic "request_body_condition" {
        for_each = delivery_rule.value.request_body_condition
        content {
          operator         = request_body_condition.value.operator
          negate_condition = request_body_condition.value.negate_condition
          match_values     = request_body_condition.value.match_values
          transforms       = request_body_condition.value.transforms
        }
      }
      dynamic "request_header_condition" {
        for_each = delivery_rule.value.request_header_condition
        content {
          selector         = request_header_condition.value.selector
          operator         = request_header_condition.value.operator
          negate_condition = request_header_condition.value.negate_condition
          match_values     = request_header_condition.value.match_values
          transforms       = request_header_condition.value.transforms
        }
      }
      dynamic "request_method_condition" {
        for_each = delivery_rule.value.request_method_condition
        content {
          operator         = request_method_condition.value.operator
          negate_condition = request_method_condition.value.negate_condition
          match_values     = request_method_condition.value.match_values
        }
      }
      dynamic "request_scheme_condition" {
        for_each = delivery_rule.value.request_scheme_condition
        content {
          operator         = request_scheme_condition.value.operator
          negate_condition = request_scheme_condition.value.negate_condition
          match_values     = request_scheme_condition.value.match_values
        }
      }

      dynamic "request_uri_condition" {
        for_each = delivery_rule.value.request_uri_condition
        content {
          operator         = request_uri_condition.value.operator
          negate_condition = request_uri_condition.value.negate_condition
          match_values     = request_uri_condition.value.match_values
          transforms       = request_uri_condition.value.transforms
        }
      }

      dynamic "url_file_extension_condition" {
        for_each = delivery_rule.value.url_file_extension_condition
        content {
          operator         = url_file_extension_condition.value.operator
          negate_condition = url_file_extension_condition.value.negate_condition
          match_values     = url_file_extension_condition.value.match_values
          transforms       = url_file_extension_condition.value.transforms
        }
      }

      dynamic "url_file_name_condition" {
        for_each = delivery_rule.value.url_file_name_condition
        content {
          operator         = url_file_name_condition.value.operator
          negate_condition = url_file_name_condition.value.negate_condition
          match_values     = url_file_name_condition.value.match_values
          transforms       = url_file_name_condition.value.transforms
        }
      }
      dynamic "url_path_condition" {
        for_each = delivery_rule.value.url_path_condition
        content {
          operator         = url_path_condition.value.operator
          negate_condition = url_path_condition.value.negate_condition
          match_values     = url_path_condition.value.match_values
          transforms       = url_path_condition.value.transforms
        }
      }

      dynamic "url_redirect_action" {
        for_each = delivery_rule.value.url_redirect_action
        content {
          redirect_type = url_redirect_action.value.redirect_type
          protocol      = url_redirect_action.value.protocol
          hostname      = url_redirect_action.value.hostname
          path          = url_redirect_action.value.path
          fragment      = url_redirect_action.value.fragment
          query_string  = url_redirect_action.value.query_string
        }
      }

      dynamic "url_rewrite_action" {
        for_each = delivery_rule.value.url_rewrite_action
        content {
          source_pattern          = url_rewrite_action.value.source_pattern
          destination             = url_rewrite_action.value.destination
          preserve_unmatched_path = url_rewrite_action.value.preserve_unmatched_path
        }
      }

    }
  }

  dynamic "geo_filter" {
    for_each = each.value.geo_filters
    content {
      action        = geo_filter.value.action
      country_codes = geo_filter.value.country_codes
      relative_path = geo_filter.value.relative_path
    }
  }
}


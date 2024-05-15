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
  #Only for Microsoft_Standard Sku.
  dynamic "delivery_rule" {
    for_each = each.value.delivery_rules == null ? {} : each.value.delivery_rules

    content {
      name  = delivery_rule.value.name
      order = delivery_rule.value.order
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
  dynamic "global_delivery_rule" {
    for_each = each.value.global_delivery_rule != null ? [each.value.global_delivery_rule] : []
    content {
      cache_expiration_action {
        behavior = global_delivery_rule.value.cache_expiration_action.behavior
        duration = global_delivery_rule.value.cache_expiration_action.duration
      }
      cache_key_query_string_action {
        behavior   = global_delivery_rule.value.cache_key_query_string_action.behavior
        parameters = global_delivery_rule.value.cache_key_query_string_action.parameters
      }
    }
  }
}


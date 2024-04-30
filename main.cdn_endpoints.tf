resource "azurerm_cdn_endpoint" "endpoint" {
  for_each = var.cdn_endpoints

  location                      = var.location
  name                          = each.value.name
  tags                          = each.value.tags
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
  global_delivery_rule {
    cache_expiration_action {
      behavior = each.value.global_delivery_rule.cache_expiration_action.behavior
      duration = each.value.global_delivery_rule.cache_expiration_action.duration
    }
    cache_key_query_string_action {
      behavior   = each.value.global_delivery_rule.cache_key_query_string_action.behavior
      parameters = each.value.global_delivery_rule.cache_key_query_string_action.parameters
    }
  }
}

resource "azurerm_cdn_endpoint_custom_domain" "example" {
  for_each = var.cdn_endpoint_custom_domains

  cdn_endpoint_id = azurerm_cdn_endpoint.endpoint[each.value.cdn_endpoint_key].id
  host_name       = each.value.host_name
  name            = each.value.name
}


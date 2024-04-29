resource "azurerm_cdn_endpoint" "endpoint" {
  for_each                      = var.cdn_endpoints
  name                          = each.value.name
  profile_name                  = azapi_resource.front_door_profile.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  is_http_allowed               = each.value.is_http_allowed
  is_https_allowed              = each.value.is_https_allowed
  querystring_caching_behaviour = each.value.querystring_caching_behaviour
  is_compression_enabled        = each.value.is_compression_enabled
  content_types_to_compress     = each.value.content_types_to_compress
  #optimization_type             = try(each.value.optimization_type, null)

  dynamic "geo_filter" {
    for_each = each.value.geo_filters
    content {
      relative_path = geo_filter.value.relative_path
      action        = geo_filter.value.action
      country_codes = geo_filter.value.country_codes
    }
  }
  #Only for Microsoft_Standard Sku.
  
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
  #Only for Microsoft_Standard Sku.
  dynamic "delivery_rule" {
    for_each = each.value.delivery_rules == null ? {} : each.value.delivery_rules

    content {
      name  = delivery_rule.value.name
      order = delivery_rule.value.order
    }
  }

  origin_host_header = each.value.origin_host_header
  origin_path        = each.value.origin_path
  probe_path         = each.value.probe_path

  dynamic "origin" {
    for_each = each.value.origins
    content {

      name      = origin.value.name
      host_name = origin.value.host_name
    }
  }
}

resource "azurerm_cdn_endpoint_custom_domain" "example" {
  for_each        = var.cdn_endpoint_custom_domains
  name            = each.value.name
  cdn_endpoint_id = azurerm_cdn_endpoint.endpoint[each.value.cdn_endpoint_key].id
  host_name       = each.value.host_name
}


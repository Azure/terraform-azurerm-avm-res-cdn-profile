resource "azurerm_cdn_frontdoor_endpoint" "endpoints" {
  for_each                 = var.endpoints
  name                     = each.value.name
  cdn_frontdoor_profile_id = azapi_resource.front_door_profile.id
  enabled                  = each.value.enabled
  tags                     = each.value.tags
}

resource "azurerm_cdn_frontdoor_route" "routes" {
  depends_on                      = [azurerm_cdn_frontdoor_origin.origins]
  for_each                        = var.routes
  name                            = each.value.name
  cdn_frontdoor_endpoint_id       = azurerm_cdn_frontdoor_endpoint.endpoints[each.value.endpoint_name].id
  cdn_frontdoor_origin_group_id   = azurerm_cdn_frontdoor_origin_group.example[each.value.origin_group_name].id
  cdn_frontdoor_origin_ids        = [for x in azurerm_cdn_frontdoor_origin.origins : x.id if contains(each.value.origin_names, x.name)]
  supported_protocols             = each.value.supported_protocols
  patterns_to_match               = each.value.patterns_to_match
  forwarding_protocol             = each.value.forwarding_protocol
  link_to_default_domain          = each.value.link_to_default_domain
  https_redirect_enabled          = each.value.https_redirect_enabled
  cdn_frontdoor_custom_domain_ids = [for k, v in azurerm_cdn_frontdoor_custom_domain.cds : v.id if contains(coalesce(each.value.custom_domain_names,[""]), v.name)]
  dynamic "cache" {
    for_each = each.value.cache
    content {
      query_string_caching_behavior = cache.value["query_string_caching_behavior"]
      query_strings                 = cache.value["query_strings"]
      compression_enabled           = cache.value["compression_enabled"]
      content_types_to_compress     = cache.value["content_types_to_compress"]
    }
  }
}

#  locals {
# #   alloriginids = flatten([ for x in [azurerm_cdn_frontdoor_origin.origins] : [ x.id ] ])
#     alloriginids= [for x in azurerm_cdn_frontdoor_origin.origins : x.id if contains(var.routes.origin_names, x.name)]
# #   alloriginnames = flatten([ for x in [azurerm_cdn_frontdoor_origin.origins] : [ x.name ] ])
# #  # originids = matchkeys(alloriginids,alloriginnames,var.routes.origin_names)
# } 
#  output "originids" {
#    value = local.alloriginids
#  }

# output "filtered_values" {
#   value = [for key, value in var.my_object : key => value if contains(var.filtered_keys, key)]
# }


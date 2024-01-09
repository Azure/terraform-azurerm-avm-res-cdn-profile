resource "azurerm_cdn_frontdoor_endpoint" "endpoints" {
  for_each = var.endpoints
  name = each.value.name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.example.id
}

resource "azurerm_cdn_frontdoor_route" "routes" {
  for_each = var.routes
  name = each.value.name
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.endpoints[each.value.endpoint_name].id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.example[each.value.origin_group_name].id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.example["origin2"].id]

  supported_protocols    = ["Http", "Https"]
  patterns_to_match      = ["/*"]
  forwarding_protocol    = "HttpsOnly"
  link_to_default_domain = true
  https_redirect_enabled = true
}

locals {
  originids = flatten([ for x in [azurerm_cdn_frontdoor_origin.example] : [ x.id ] ])
  #origins = flatten([azurerm_cdn_frontdoor_origin.example.id])
} 
#  output "originids" {
#    value = locals.origins
#  }
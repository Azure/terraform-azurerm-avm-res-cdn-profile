resource "azurerm_cdn_frontdoor_endpoint" "endpoints" {
  for_each = var.endpoints
  name = each.value.name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.example.id
}

resource "azurerm_cdn_frontdoor_route" "routes" {
  depends_on = [ azurerm_cdn_frontdoor_origin.origins ]
  for_each = var.routes
  name = each.value.name
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.endpoints[each.value.endpoint_name].id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.example[each.value.origin_group_name].id
  cdn_frontdoor_origin_ids      = [for x in azurerm_cdn_frontdoor_origin.origins : x.id if contains(each.value.origin_names, x.name)]
  

  supported_protocols    = ["Http", "Https"]
  patterns_to_match      = ["/*"]
  forwarding_protocol    = "HttpsOnly"
  link_to_default_domain = true
  https_redirect_enabled = true
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
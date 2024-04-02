resource "azurerm_cdn_frontdoor_custom_domain" "cds" {
  for_each                 = var.front_door_custom_domains
  name                     = each.value.name
  cdn_frontdoor_profile_id = azapi_resource.front_door_profile.id
  dns_zone_id              = each.value.dns_zone_id
  host_name                = each.value.host_name

  tls {
    certificate_type        = each.value.tls.certificate_type
    minimum_tls_version     = each.value.tls.minimum_tls_version
    cdn_frontdoor_secret_id = each.value.tls.cdn_frontdoor_secret_id
  }
}

# no functional purpose. custom domain setting in route are enough --> to discuss
# resource "azurerm_cdn_frontdoor_custom_domain_association" "example" {
#         for_each = { for key, value in  var.front_door_custom_domains : key => value
#         if try(value.associated_route_names,null) != null
#       }
#   cdn_frontdoor_custom_domain_id = azurerm_cdn_frontdoor_custom_domain.cds[each.key].id
#   cdn_frontdoor_route_ids        = [for x in azurerm_cdn_frontdoor_route.routes : x.id if contains(each.value.associated_route_names, x.name)]
# }

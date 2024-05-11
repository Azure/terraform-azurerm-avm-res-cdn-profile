resource "azurerm_cdn_frontdoor_custom_domain" "cds" {
  for_each = var.front_door_custom_domains

  cdn_frontdoor_profile_id = azapi_resource.front_door_profile.id
  host_name                = each.value.host_name
  name                     = each.value.name
  dns_zone_id              = each.value.dns_zone_id

  tls {
    cdn_frontdoor_secret_id = each.value.tls.cdn_frontdoor_secret_id
    certificate_type        = each.value.tls.certificate_type
    minimum_tls_version     = each.value.tls.minimum_tls_version
  }
}

#creating domain association resource block for seamless updation of custom domains
resource "azurerm_cdn_frontdoor_custom_domain_association" "association" {
  for_each = azurerm_cdn_frontdoor_custom_domain.cds

  cdn_frontdoor_custom_domain_id = each.value.id
  cdn_frontdoor_route_ids        = local.custom_domain_routes[each.value.name]
}



locals {
  custom_domain_routes = {
    for domain in azurerm_cdn_frontdoor_custom_domain.cds : domain.name => [
      for route in try(azurerm_cdn_frontdoor_route.routes, []) : route.id
      if contains(try(length(route.cdn_frontdoor_custom_domain_ids)) > 0 ? route.cdn_frontdoor_custom_domain_ids : [], domain.id)
    ]
  }
}
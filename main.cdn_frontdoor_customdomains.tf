resource "azurerm_cdn_frontdoor_custom_domain" "cds" {
  for_each = var.front_door_custom_domains

  cdn_frontdoor_profile_id = azapi_resource.front_door_profile.id
  host_name                = each.value.host_name
  name                     = each.value.name
  dns_zone_id              = each.value.dns_zone_id

  tls {
    cdn_frontdoor_secret_id = each.value.tls.certificate_type == "CustomerCertificate" ? azurerm_cdn_frontdoor_secret.frontdoorsecret[each.value.tls.cdn_frontdoor_secret_key].id : null
    certificate_type        = each.value.tls.certificate_type
  }
}

# creating domain association resource block for seamless updation of custom domains
resource "azurerm_cdn_frontdoor_custom_domain_association" "association" {
  for_each = azurerm_cdn_frontdoor_custom_domain.cds

  cdn_frontdoor_custom_domain_id = each.value.id
  cdn_frontdoor_route_ids        = local.custom_domain_routes[each.key]
}




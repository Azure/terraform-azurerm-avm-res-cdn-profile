locals {
  custom_domain_routes = {
    for key, domain in azurerm_cdn_frontdoor_custom_domain.cds : key => [
      for route in try(azurerm_cdn_frontdoor_route.routes, []) : route.id
      if contains(try(length(route.cdn_frontdoor_custom_domain_ids)) > 0 ? route.cdn_frontdoor_custom_domain_ids : [], domain.id)
    ]
  }
  filtered_epcds_for_security_policy = { for k, v in var.front_door_security_policies : k =>
    concat([for item in try(v.firewall.association.endpoint_keys, []) : azurerm_cdn_frontdoor_endpoint.endpoints[item].id], [for item in try(v.firewall.association.domain_keys, []) : azurerm_cdn_frontdoor_custom_domain.cds[item].id])
  }
  managed_identity_type              = var.managed_identities.system_assigned ? ((length(var.managed_identities.user_assigned_resource_ids) > 0) ? "SystemAssigned, UserAssigned" : "SystemAssigned") : ((length(var.managed_identities.user_assigned_resource_ids) > 0) ? "UserAssigned" : null)
  role_definition_resource_substring = "providers/Microsoft.Authorization/roleDefinitions"
  route_custom_domains = {
    for k, v in var.front_door_routes : k => [for cd in v.custom_domain_keys : azurerm_cdn_frontdoor_custom_domain.cds[cd].id]
  }
}

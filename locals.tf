locals {
  cdn_endpoint_diagnostics = { for k, v in var.cdn_endpoints : k => v if strcontains(var.sku, "AzureFrontDoor") == false && v.diagnostic_setting != null }
  custom_domain_routes = {
    for key, domain in azurerm_cdn_frontdoor_custom_domain.cds : key => [
      for route in try(azurerm_cdn_frontdoor_route.routes, []) : route.id
      if contains(coalesce(route.cdn_frontdoor_custom_domain_ids, []), domain.id)
    ]
  }
  filtered_epcds_for_security_policy = { for k, v in var.front_door_security_policies : k =>
    concat([for item in try(v.firewall.association.endpoint_keys, []) : azurerm_cdn_frontdoor_endpoint.endpoints[item].id], [for item in try(v.firewall.association.domain_keys, []) : azurerm_cdn_frontdoor_custom_domain.cds[item].id])
  }
  managed_identities = {
    system_assigned_user_assigned = (var.managed_identities.system_assigned || length(var.managed_identities.user_assigned_resource_ids) > 0) ? {
      this = {
        type                       = var.managed_identities.system_assigned && length(var.managed_identities.user_assigned_resource_ids) > 0 ? "SystemAssigned, UserAssigned" : length(var.managed_identities.user_assigned_resource_ids) > 0 ? "UserAssigned" : "SystemAssigned"
        user_assigned_resource_ids = var.managed_identities.user_assigned_resource_ids
      }
    } : {}
    system_assigned = var.managed_identities.system_assigned ? {
      this = {
        type = "SystemAssigned"
      }
    } : {}
    user_assigned = length(var.managed_identities.user_assigned_resource_ids) > 0 ? {
      this = {
        type                       = "UserAssigned"
        user_assigned_resource_ids = var.managed_identities.user_assigned_resource_ids
      }
    } : {}
  }
  resource_group_id                  = provider::azapi::subscription_resource_id(local.subscription_id, local.resource_type, local.resource_names)
  resource_names                     = [var.resource_group_name]
  resource_type                      = "Microsoft.Resources/resourceGroups"
  role_definition_resource_substring = "providers/Microsoft.Authorization/roleDefinitions"
  route_custom_domains = {
    for k, v in var.front_door_routes : k => [for cd in v.custom_domain_keys : azurerm_cdn_frontdoor_custom_domain.cds[cd].id]
  }
  subscription_id = data.azapi_client_config.current.subscription_id
}
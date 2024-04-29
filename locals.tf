locals {
  managed_identity_type = var.managed_identities.system_assigned ? ((length(var.managed_identities.user_assigned_resource_ids) > 0) ? "SystemAssigned, UserAssigned" : "SystemAssigned") : ((length(var.managed_identities.user_assigned_resource_ids) > 0) ? "UserAssigned" : null)

  role_definition_resource_substring = "providers/Microsoft.Authorization/roleDefinitions"

  filtered_epcds_for_security_policy = {
    for k, v in var.front_door_security_policies : k => concat(flatten([for e in try(azurerm_cdn_frontdoor_endpoint.endpoints, []) : e.id if contains(try(v.firewall.association.endpoint_names, []), e.name)]), flatten([for c in try(azurerm_cdn_frontdoor_custom_domain.cds, []) : c.id if contains(try(v.firewall.association.domain_names, []), c.name)]))
  }
}
output "epslist1" {
  value = local.filtered_epcds_for_security_policy
}
 
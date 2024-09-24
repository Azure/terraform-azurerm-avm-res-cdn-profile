output "cdn_endpoint_custom_domains" {
  description = "CDN endpoint custom domains output object"
  value       = azurerm_cdn_endpoint_custom_domain.cds
}

output "cdn_endpoints" {
  description = "CDN endpoint output object"
  value       = azurerm_cdn_endpoint.endpoints
}

output "frontdoor_custom_domains" {
  description = "Azure front door custom domains output object"
  value       = azurerm_cdn_frontdoor_custom_domain.cds
}

output "frontdoor_endpoints" {
  description = "Azure front door endpoint output object"
  value       = azurerm_cdn_frontdoor_endpoint.endpoints
}

output "frontdoor_firewall_policies" {
  description = "Azure front door firewall policies output object"
  value       = azurerm_cdn_frontdoor_firewall_policy.wafs
}

output "frontdoor_origin_groups" {
  description = "Azure front door origin groups output object"
  value       = azurerm_cdn_frontdoor_origin_group.origin_groups
}

output "frontdoor_origins" {
  description = "Azure front door origins output object"
  value       = azurerm_cdn_frontdoor_origin.origins
}

output "frontdoor_rule_sets" {
  description = "Azure front door rule sets output object"
  value       = azurerm_cdn_frontdoor_rule_set.rule_set
}

output "frontdoor_rules" {
  description = "Azure front door rules output object"
  value       = azurerm_cdn_frontdoor_rule.rules
}

output "frontdoor_security_policies" {
  description = "Azure front door security policies output object"
  value       = azurerm_cdn_frontdoor_security_policy.security_policies
}

output "resource" {
  description = "Full resource output object"
  value       = azapi_resource.front_door_profile
}

output "resource_id" {
  description = "The resource id of the Front door profile"
  value       = azapi_resource.front_door_profile.id
}

output "resource_name" {
  description = "The resource name of the Front door profile"
  value       = azapi_resource.front_door_profile.name
}

output "system_assigned_mi_principal_id" {
  description = "The system assigned managed identity of the front door profile"
  value       = try(azapi_resource.front_door_profile.identity[0].principal_id, null)
}

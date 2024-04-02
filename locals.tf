# TODO: insert locals here.

# locals {
#   managed_identity_type = var.managed_identities.system_assigned ? ((length(var.managed_identities.user_assigned_resource_ids) > 0) ? "SystemAssigned, UserAssigned" : "SystemAssigned") : ((length(var.managed_identities.user_assigned_resource_ids) > 0) ? "UserAssigned" : null)

# }


#   locals {
    
#   }


  


locals {
  managed_identity_type = var.managed_identities.system_assigned ? ((length(var.managed_identities.user_assigned_resource_ids) > 0) ? "SystemAssigned, UserAssigned" : "SystemAssigned") : ((length(var.managed_identities.user_assigned_resource_ids) > 0) ? "UserAssigned" : null)
  
  role_definition_resource_substring = "providers/Microsoft.Authorization/roleDefinitions"

  # filtered_endpoints_for_security_policy = {
  #   for k, v in try(var.front_door_security_policies != null ? var.front_door_security_policies : {}) : k => [
  #     for ep in try(v.firewall.association.endpoint_names, {}) : try([for s in try(azurerm_cdn_frontdoor_endpoint.endpoints, {}) : s.id if s.name == ep], [for s in azurerm_cdn_frontdoor_endpoint.endpoints : s.id if s.name == ep])[0]

  #   ]

  # }
  # filtered_domains_for_security_policy = {
  #   for k, v in try(var.front_door_security_policies != null ? var.front_door_security_policies : {}) : k => [
  #     for domain in try(v.firewall.association.domain_names, {}) : try([for s in try(azurerm_cdn_frontdoor_custom_domain.cds, {}) : s.id if s.name == domain], [for s in azurerm_cdn_frontdoor_custom_domain.cds : s.id if s.name == domain])[0]
  #   ]
  # }
}





locals {
  filtered_epcds_for_security_policy = {
    for k, v in values(var.front_door_security_policies) : k => concat([ 
      for ep_name in try(v.firewall.association.endpoint_names,[]) : try(lookup(azurerm_cdn_frontdoor_endpoint.endpoints, ep_name).id, null)
    ],
    [
      for cd_name in try(v.firewall.association.domain_names,[]) : try(lookup(azurerm_cdn_frontdoor_custom_domain.cds, cd_name).id, null)
    ]
    )
    
  }

}
output "epslist" {
  value =  local.filtered_epcds_for_security_policy 
}

output "test" {
  value="somevalue"
}


 
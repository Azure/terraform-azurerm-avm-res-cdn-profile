


resource "azurerm_cdn_frontdoor_firewall_policy" "wafs" {
  for_each = var.front_door_firewall_policies != null ? var.front_door_firewall_policies : {}

  name                  = each.value.name
  resource_group_name   = each.value.resource_group_name
  sku_name              = each.value.sku_name
  enabled               = each.value.enabled
  mode                  = each.value.mode
  redirect_url          = each.value.redirect_url
  custom_block_response_status_code = each.value.custom_block_response_status_code
  custom_block_response_body        = each.value.custom_block_response_body

  dynamic "custom_rule" {
    for_each = each.value.custom_rules
    content {
      name                           = custom_rule.value.name
      enabled                        = custom_rule.value.enabled
      priority                       = custom_rule.value.priority
      rate_limit_duration_in_minutes = custom_rule.value.rate_limit_duration_in_minutes
      rate_limit_threshold           = custom_rule.value.rate_limit_threshold
      type                           = custom_rule.value.type
      action                         = custom_rule.value.action

      dynamic "match_condition" {
        for_each = custom_rule.value.match_conditions
        content {
          match_variable     = match_condition.value.match_variable
          operator           = match_condition.value.operator
          negation_condition = match_condition.value.negation_condition
          match_values       = match_condition.value.match_values
          selector           = try(match_condition.value.selector, null)
          transforms         = try(match_condition.value.transforms, null)
        }
      }
    }
  }
}


# resource "azurerm_cdn_frontdoor_security_policy" "example" {
#   depends_on = [azurerm_cdn_frontdoor_firewall_policy.wafs  ]
#   for_each                 = try(var.front_door_security_policies != null ? var.front_door_security_policies : {})
#   name                     = each.value.name
#   cdn_frontdoor_profile_id = azapi_resource.front_door_profile.id
#   security_policies {
#     firewall {
#       cdn_frontdoor_firewall_policy_id = {for k, v in azurerm_cdn_frontdoor_firewall_policy.wafs : k => v.id if v.name == each.value.firewall.front_door_firewall_policy_name}
#       association {
#         dynamic "domain" {
#           for_each = concat(try(local.filtered_epcds_for_security_policy[each.key], null), try(local.filtered_epcds_for_security_policy[each.key], null))
#           content {
#             cdn_frontdoor_domain_id = domain.value[each.value]
#           }

#         }
#         patterns_to_match = ["/*"]

#       }
#     }
#   }

# }

resource "azurerm_cdn_frontdoor_security_policy" "example" {
  for_each                 = try(var.front_door_security_policies != null ? var.front_door_security_policies : {})
  name                     = each.value.name
  cdn_frontdoor_profile_id = azapi_resource.front_door_profile.id

  security_policies {

    firewall {
      
      cdn_frontdoor_firewall_policy_id = [for v in azurerm_cdn_frontdoor_firewall_policy.wafs : v.id if v.name == each.value.firewall.front_door_firewall_policy_name][0]
      

      association {
        dynamic "domain" {
          for_each = try(local.filtered_epcds_for_security_policy[each.key], null)
          content {
            cdn_frontdoor_domain_id = domain.value
          }

        }
        patterns_to_match = ["/*"]

      }
    }
  }

}








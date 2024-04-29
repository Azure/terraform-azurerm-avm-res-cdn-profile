


resource "azurerm_cdn_frontdoor_firewall_policy" "wafs" {
  for_each = var.front_door_firewall_policies != null ? var.front_door_firewall_policies : {}

  name                              = each.value.name
  resource_group_name               = each.value.resource_group_name
  sku_name                          = each.value.sku_name
  enabled                           = each.value.enabled
  mode                              = each.value.mode
  redirect_url                      = each.value.redirect_url
  custom_block_response_status_code = each.value.custom_block_response_status_code
  custom_block_response_body        = each.value.custom_block_response_body

  dynamic "custom_rule" {
    for_each = try(each.value.custom_rules, null)
    content {
      name                           = custom_rule.value.name
      enabled                        = custom_rule.value.enabled
      priority                       = custom_rule.value.priority
      rate_limit_duration_in_minutes = custom_rule.value.rate_limit_duration_in_minutes
      rate_limit_threshold           = custom_rule.value.rate_limit_threshold
      type                           = custom_rule.value.type
      action                         = custom_rule.value.action

      dynamic "match_condition" {
        for_each = try(custom_rule.value.match_conditions, null)
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

  dynamic "managed_rule" {
    for_each = try(each.value.managed_rules, null)
    content {
      type    = managed_rule.value.type
      version = managed_rule.value.version
      action  = managed_rule.value.action

      dynamic "exclusion" {
        for_each = try(managed_rule.value.exclusions, null)
        content {
          match_variable = exclusion.value.match_variable
          operator       = exclusion.value.operator
          selector       = try(exclusion.value.selector, null)
        }
      }

      dynamic "override" {
        for_each = try(managed_rule.value.overrides, null)
        content {
          rule_group_name = override.value.rule_group_name

          dynamic "exclusion" {
            for_each = try(override.value.exclusions, null)
            content {
              match_variable = exclusion.value.match_variable
              operator       = exclusion.value.operator
              selector       = try(exclusion.value.selector, null)
            }
          }

          dynamic "rule" {
            for_each = try(override.value.rules, null)
            content {
              rule_id = rule.value.rule_id
              action  = rule.value.action
              enabled = try(rule.value.enabled, null)

              dynamic "exclusion" {
                for_each = try(rule.value.exclusions, null)
                content {
                  match_variable = exclusion.value.match_variable
                  operator       = exclusion.value.operator
                  selector       = try(exclusion.value.selector, null)
                }
              }
            }
          }
        }
      }
    }
  }
}


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








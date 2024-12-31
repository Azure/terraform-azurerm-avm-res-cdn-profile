resource "azurerm_cdn_frontdoor_firewall_policy" "wafs" {
  for_each = var.front_door_firewall_policies != null ? var.front_door_firewall_policies : {}

  mode                              = each.value.mode
  name                              = each.value.name
  resource_group_name               = each.value.resource_group_name
  sku_name                          = each.value.sku_name
  custom_block_response_body        = each.value.custom_block_response_body
  custom_block_response_status_code = each.value.custom_block_response_status_code
  enabled                           = each.value.enabled
  redirect_url                      = each.value.redirect_url
  tags                              = each.value.tags != null ? each.value.tags : var.tags

  dynamic "custom_rule" {
    for_each = try(each.value.custom_rules, null)

    content {
      action                         = custom_rule.value.action
      name                           = custom_rule.value.name
      type                           = custom_rule.value.type
      enabled                        = custom_rule.value.enabled
      priority                       = custom_rule.value.priority
      rate_limit_duration_in_minutes = custom_rule.value.rate_limit_duration_in_minutes
      rate_limit_threshold           = custom_rule.value.rate_limit_threshold

      dynamic "match_condition" {
        for_each = try(custom_rule.value.match_conditions, null)

        content {
          match_values       = match_condition.value.match_values
          match_variable     = match_condition.value.match_variable
          operator           = match_condition.value.operator
          negation_condition = match_condition.value.negation_condition
          selector           = try(match_condition.value.selector, null)
          transforms         = try(match_condition.value.transforms, null)
        }
      }
    }
  }
  dynamic "managed_rule" {
    for_each = try(each.value.managed_rules, null)

    content {
      action  = managed_rule.value.action
      type    = managed_rule.value.type
      version = managed_rule.value.version

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
              action  = rule.value.action
              rule_id = rule.value.rule_id
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

resource "azurerm_cdn_frontdoor_security_policy" "security_policies" {
  for_each = try(var.front_door_security_policies != null ? var.front_door_security_policies : {})

  cdn_frontdoor_profile_id = azapi_resource.front_door_profile.id
  name                     = each.value.name

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.wafs[each.value.firewall.front_door_firewall_policy_key].id

      association {
        patterns_to_match = ["/*"]

        dynamic "domain" {
          for_each = local.filtered_epcds_for_security_policy[each.key]

          content {
            cdn_frontdoor_domain_id = domain.value
          }
        }
      }
    }
  }

  depends_on = [azurerm_cdn_frontdoor_custom_domain.cds, azurerm_cdn_frontdoor_endpoint.endpoints]
}








resource "azurerm_cdn_frontdoor_rule_set" "rule_set" {
  for_each                 = var.rule_sets
  name                     = each.value
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.example.id
}

resource "azurerm_cdn_frontdoor_rule" "rules" {
  depends_on                = [azurerm_cdn_frontdoor_origin_group.example, azurerm_cdn_frontdoor_origin.origins]
  for_each                  = var.rules
  name                      = each.value.name
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.rule_set[each.value.rule_set_name].id
  order                     = each.value.order
  behavior_on_match         = each.value.behavior_on_match

  actions {
    #for_each = each.value.actions  #cant add foreach here.. multiple action blocks not allowed

    dynamic "url_rewrite_action" {
      for_each = { for key, value in each.value.actions : key => value
        if key == "url_rewrite_action"
      }

      content {
        source_pattern          = url_rewrite_action.value.source_pattern
        destination             = url_rewrite_action.value.destination
        preserve_unmatched_path = url_rewrite_action.value.preserve_unmatched_path
      }
    }
    dynamic "route_configuration_override_action" {
      for_each = { for key, value in each.value.actions : key => value
        if key == "route_configuration_override_action"
      }

      content {
        cdn_frontdoor_origin_group_id = try(route_configuration_override_action.value.set_origin_groupid == true ? azurerm_cdn_frontdoor_origin_group.example[each.value.origin_group_name].id : null)
        forwarding_protocol           = try(route_configuration_override_action.value.forwarding_protocol, null)
        query_string_caching_behavior = route_configuration_override_action.value.query_string_caching_behavior
        query_string_parameters       = route_configuration_override_action.value.query_string_parameters
        compression_enabled           = route_configuration_override_action.value.compression_enabled
        cache_behavior                = route_configuration_override_action.value.cache_behavior
        cache_duration                = route_configuration_override_action.value.cache_duration
      }
    }
    dynamic "url_redirect_action" {
    for_each = {for key,value in each.value.actions : key =>value 
    if key == "url_redirect_action"
    }

    content {
      
      redirect_type = url_redirect_action.value.redirect_type
      destination_hostname = url_redirect_action.value.destination_hostname
    }
    }
  }



  conditions {
    dynamic "host_name_condition" {
            for_each = { for key, value in each.value.conditions : key => value
        if key == "host_name_condition"
      }
      content {
      operator         = host_name_condition.value.operator
      negate_condition = host_name_condition.value.negate_condition
      match_values     = host_name_condition.value.match_values
      transforms       = host_name_condition.value.transforms
      }
    }

    is_device_condition {
      operator         = "Equal"
      negate_condition = false
      match_values     = ["Mobile"]
    }

    post_args_condition {
      post_args_name = "customerName"
      operator       = "BeginsWith"
      match_values   = ["J", "K"]
      transforms     = ["Uppercase"]
    }

    request_method_condition {
      operator         = "Equal"
      negate_condition = false
      match_values     = ["DELETE"]
    }

    url_filename_condition {
      operator         = "Equal"
      negate_condition = false
      match_values     = ["media.mp4"]
      transforms       = ["Lowercase", "RemoveNulls", "Trim"]
    }
  }
}





# dynamic "url_rewrite_action" {
#   #for_each = toset(each.value.actions["url_rewrite_action"]) != null ? each.value.actions["url_rewrite_action"] : null
#   for_each = each.value.actions
#   content {          
#       source_pattern          = url_rewrite_action.value.source_pattern 
#       destination             = url_rewrite_action.value.destination
#       preserve_unmatched_path = url_rewrite_action.value.preserve_unmatched_path

#     }
#   }
# }

# for_each                = each.value.actions
# dynamic "url_rewrite_action" {
#   for_each = each.value.actions.url_rewrite_action
#   content {
#     source_pattern          = url_rewrite_action.value.source_pattern
#     destination             = url_rewrite_action.value.destination
#     preserve_unmatched_path = url_rewrite_action.value.preserve_unmatched_path
#   }
# }
# dynamic "url_redirect_action" {
#   for_each = each.value.actions.url_redirect_action
#   content {
#     redirect_type        = url_redirect_action.value.redirect_type
#     redirect_protocol    = url_redirect_action.value.redirect_protocol
#     query_string         = url_redirect_action.value.query_string
#     destination_path     = url_redirect_action.value.destination_path
#     destination_hostname = url_redirect_action.value.destination_hostname
#     destination_fragment = url_redirect_action.value.destination_fragment
#   }

# route_configuration_override_action {
#   cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.example[each.value.origin_group_name].id
#   forwarding_protocol           = "HttpsOnly"
#   query_string_caching_behavior = "IncludeSpecifiedQueryStrings"
#   query_string_parameters       = ["foo", "clientIp={client_ip}"]
#   compression_enabled           = true
#   cache_behavior                = "OverrideIfOriginMissing"
#   cache_duration                = "365.23:59:59"
# }



# locals {
#   ura =      for_each = [ var.rules 
#   {for key,value in each.value.actions : key => value
#     if key == "url_rewrite_action"
#     }
# }

# output "orao" {
#   value = locals.ura
# }
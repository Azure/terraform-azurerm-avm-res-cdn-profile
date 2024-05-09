data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each = var.diagnostic_settings

  name                           = each.value.name != null ? each.value.name : "diag-${var.name}"
  target_resource_id             = azapi_resource.front_door_profile.id
  eventhub_authorization_rule_id = each.value.event_hub_authorization_rule_resource_id
  eventhub_name                  = each.value.event_hub_name
  log_analytics_destination_type = each.value.log_analytics_destination_type
  log_analytics_workspace_id     = each.value.workspace_resource_id
  partner_solution_id            = each.value.marketplace_partner_resource_id
  storage_account_id             = each.value.storage_account_resource_id

  dynamic "enabled_log" {
    for_each = each.value.log_categories
    content {
      category = enabled_log.value
   
    }
  }
  dynamic "enabled_log" {
    for_each = each.value.log_groups
    content {
      category_group = enabled_log.value
      
    }
  }
  dynamic "metric" {
    for_each = each.value.metric_categories
    content {
      category = metric.value
    }
  }
}


# Role assignments
resource "azurerm_role_assignment" "this" {
    for_each                               = var.role_assignments
    scope                                  = azapi_resource.front_door_profile.id
    role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
    role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
    principal_id                           = each.value.principal_id
    condition                              = each.value.condition
    condition_version                      = each.value.condition_version
    skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
    delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
    principal_type                         = each.value.principal_type
  }


resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0
  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.lock.kind}")
  scope      = azapi_resource.front_door_profile.id
  notes      = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
  depends_on = [azapi_resource.front_door_profile]
}
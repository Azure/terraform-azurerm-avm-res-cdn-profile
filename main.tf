data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# diagnostic settings can be set at profile level for front door skus and standard_microsoft cdn sku.
resource "azurerm_monitor_diagnostic_setting" "front_door_diag" {
  for_each = strcontains(var.sku, "AzureFrontDoor") || strcontains(var.sku, "Standard_Microsoft") ? var.diagnostic_settings : {}

  name                           = each.value.name != null ? each.value.name : "diag-${var.name}"
  target_resource_id             = azapi_resource.front_door_profile.id
  eventhub_authorization_rule_id = each.value.event_hub_authorization_rule_resource_id
  eventhub_name                  = each.value.event_hub_name
  log_analytics_destination_type = try(each.value.workspace_resource_id == null) ? null : each.value.log_analytics_destination_type
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

  lifecycle {
    ignore_changes = [
      log_analytics_destination_type
    ]
  }
}


# cdn profile endpoints are seperate child resources that have their own diagnostic settings.
resource "azurerm_monitor_diagnostic_setting" "cdn_endpoint_diag" {
  for_each = local.cdn_endpoint_diagnostics

  name                           = each.value.diagnostic_setting.name != null ? each.value.diagnostic_setting.name : "diag-${var.name}"
  target_resource_id             = azurerm_cdn_endpoint.endpoint[each.key].id
  eventhub_authorization_rule_id = each.value.diagnostic_setting.event_hub_authorization_rule_resource_id
  eventhub_name                  = each.value.diagnostic_setting.event_hub_name
  log_analytics_destination_type = try(each.value.diagnostic_setting.workspace_resource_id == null) ? null : each.value.diagnostic_setting.log_analytics_destination_type
  log_analytics_workspace_id     = each.value.diagnostic_setting.workspace_resource_id
  partner_solution_id            = each.value.diagnostic_setting.marketplace_partner_resource_id
  storage_account_id             = each.value.diagnostic_setting.storage_account_resource_id

  dynamic "enabled_log" {
    for_each = each.value.diagnostic_setting.log_categories

    content {
      category = enabled_log.value
    }
  }
  dynamic "enabled_log" {
    for_each = each.value.diagnostic_setting.log_groups

    content {
      category_group = enabled_log.value
    }
  }
  dynamic "metric" {
    for_each = each.value.diagnostic_setting.metric_categories

    content {
      category = metric.value
    }
  }

  lifecycle {
    ignore_changes = [
      log_analytics_destination_type
    ]
  }
}

# Role assignments
resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = azapi_resource.front_door_profile.id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  principal_type                         = each.value.principal_type
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}

resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.lock.kind}")
  scope      = azapi_resource.front_door_profile.id
  notes      = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."

  depends_on = [azapi_resource.front_door_profile]
}


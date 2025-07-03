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
  dynamic "enabled_metric" {
    for_each = each.value.metric_categories

    content {
      category = enabled_metric.value
    }
  }

  lifecycle {
    ignore_changes = [
      log_analytics_destination_type,
      enabled_metric
    ]
  }
}


# cdn profile endpoints are separate child resources that have their own diagnostic settings.
resource "azurerm_monitor_diagnostic_setting" "cdn_endpoint_diag" {
  for_each = local.cdn_endpoint_diagnostics

  name                           = each.value.diagnostic_setting.name != null ? each.value.diagnostic_setting.name : "diag-${var.name}"
  target_resource_id             = azurerm_cdn_endpoint.endpoints[each.key].id
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
  dynamic "enabled_metric" {
    for_each = each.value.diagnostic_setting.metric_categories

    content {
      category = enabled_metric.value
    }
  }

  lifecycle {
    ignore_changes = [
      log_analytics_destination_type,
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

# metric alerts
resource "azurerm_monitor_metric_alert" "this" {
  for_each = var.metric_alerts != null ? var.metric_alerts : {}

  name                     = each.value.name
  resource_group_name      = var.resource_group_name
  scopes                   = [azapi_resource.front_door_profile.id]
  auto_mitigate            = each.value.auto_mitigate
  description              = each.value.description
  enabled                  = each.value.enabled
  frequency                = each.value.frequency
  severity                 = each.value.severity
  tags                     = each.value.tags != null ? each.value.tags : var.tags
  target_resource_location = each.value.target_resource_location
  target_resource_type     = each.value.target_resource_type
  window_size              = each.value.window_size

  dynamic "action" {
    for_each = each.value.actions != null ? each.value.actions : []

    content {
      action_group_id    = action.value.action_group_id
      webhook_properties = action.value.webhook_properties
    }
  }
  dynamic "application_insights_web_test_location_availability_criteria" {
    for_each = each.value.application_insights_web_test_location_availability_criterias != null ? each.value.application_insights_web_test_location_availability_criterias : []

    content {
      component_id          = application_insights_web_test_location_availability_criteria.value.component_id
      failed_location_count = application_insights_web_test_location_availability_criteria.value.failed_location_count
      web_test_id           = application_insights_web_test_location_availability_criteria.value.web_test_id
    }
  }
  dynamic "criteria" {
    for_each = try(each.value.criterias, [])

    content {
      aggregation            = criteria.value.aggregation
      metric_name            = criteria.value.metric_name
      metric_namespace       = criteria.value.metric_namespace
      operator               = criteria.value.operator
      threshold              = criteria.value.threshold
      skip_metric_validation = criteria.value.skip_metric_validation

      dynamic "dimension" {
        for_each = criteria.value.dimensions != null ? criteria.value.dimensions : []

        content {
          name     = dimension.value.name
          operator = dimension.value.operator
          values   = dimension.value.values
        }
      }
    }
  }
  dynamic "dynamic_criteria" {
    for_each = each.value.dynamic_criterias != null ? each.value.dynamic_criterias : []

    content {
      aggregation              = dynamic_criteria.value.aggregation
      alert_sensitivity        = dynamic_criteria.value.alert_sensitivity
      metric_name              = dynamic_criteria.value.metric_name
      metric_namespace         = dynamic_criteria.value.metric_namespace
      operator                 = dynamic_criteria.value.operator
      evaluation_failure_count = dynamic_criteria.value.evaluation_failure_count
      evaluation_total_count   = dynamic_criteria.value.evaluation_total_count
      ignore_data_before       = dynamic_criteria.value.ignore_data_before
      skip_metric_validation   = dynamic_criteria.value.skip_metric_validation

      dimension {
        name     = dynamic_criteria.value.dimension.name
        operator = dynamic_criteria.value.dimension.operator
        values   = dynamic_criteria.value.dimension.values
      }
    }
  }
}

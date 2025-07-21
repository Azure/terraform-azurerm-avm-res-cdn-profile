data "azapi_client_config" "current" {}

# using azapi since azurerm_cdn_frontdoor_profile commented above does not support identity blocks
resource "azapi_resource" "front_door_profile" {
  location  = "Global"
  name      = var.name
  parent_id = local.resource_group_id
  type      = "Microsoft.Cdn/profiles@2023-07-01-preview"
  body = {
    properties = {
      originResponseTimeoutSeconds = var.response_timeout_seconds
    }
    sku = {
      name = var.sku
    }
  }
  create_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers              = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  schema_validation_enabled = false
  tags                      = var.tags
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  # Resources supporting both SystemAssigned and UserAssigned
  dynamic "identity" {
    for_each = local.managed_identities.system_assigned_user_assigned

    content {
      type         = identity.value.type
      identity_ids = identity.value.user_assigned_resource_ids
    }
  }
}
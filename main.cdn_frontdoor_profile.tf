#using azapi since azurerm_cdn_frontdoor_profile commented above does not support identity blocks
resource "azapi_resource" "front_door_profile" {
  type = "Microsoft.Cdn/profiles@2023-07-01-preview"
  body = jsonencode({
    properties = {
      originResponseTimeoutSeconds = var.response_timeout_seconds
    }
    sku = {
      name = var.sku
    }
  })
  location                  = "Global"
  name                      = var.name
  parent_id                 = data.azurerm_resource_group.rg.id
  schema_validation_enabled = false
  tags                      = var.tags

  dynamic "identity" {
    for_each = local.managed_identity_type == null ? [] : ["identity"]
    content {
      type         = local.managed_identity_type
      identity_ids = var.managed_identities.user_assigned_resource_ids
    }
  }
}


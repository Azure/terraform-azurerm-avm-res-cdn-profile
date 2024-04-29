# resource "azurerm_cdn_frontdoor_profile" "example" {
#   name                = var.name
#   resource_group_name = var.resource_group_name
#   sku_name            = var.sku_name
#   tags                = var.tags
#    dynamic "identity" {
#       for_each = (var.managed_identities.system_assigned || length(var.managed_identities.user_assigned_resource_ids) > 0) ? { this = var.managed_identities } : {}
#       content {
#         type         = identity.value.system_assigned && length(identity.value.user_assigned_resource_ids) > 0 ? "SystemAssigned, UserAssigned" : length(identity.value.user_assigned_resource_ids) > 0 ? "UserAssigned" : "SystemAssigned"
#         identity_ids = identity.value.user_assigned_resource_ids
#       }
#     }
# }

#using azapi since azurerm_cdn_frontdoor_profile commented above does not support identity blocks
resource "azapi_resource" "front_door_profile" {

  type                      = "Microsoft.Cdn/profiles@2023-07-01-preview"
  schema_validation_enabled = false
  name                      = var.name
  location                  = "Global"
  parent_id                 = data.azurerm_resource_group.rg.id
  tags                      = var.tags

  dynamic "identity" {
    for_each = local.managed_identity_type == null ? [] : ["identity"]
    content {
      type         = local.managed_identity_type
      identity_ids = var.managed_identities.user_assigned_resource_ids
    }
  }
  body = jsonencode({
    properties = {
      originResponseTimeoutSeconds = 20
    }
    sku = {
      name = var.sku_name
    }
  })
}


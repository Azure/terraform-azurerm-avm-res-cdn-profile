
resource "azurerm_cdn_frontdoor_secret" "frontdoorsecret" {
  for_each = var.front_door_secrets

  cdn_frontdoor_profile_id = azapi_resource.front_door_profile.id
  name                     = each.value.name

  secret {
    customer_certificate {
      key_vault_certificate_id = each.value.key_vault_certificate_id
    }
  }
}



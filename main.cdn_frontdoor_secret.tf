
resource "azurerm_cdn_frontdoor_secret" "frontdoorsecret" {
  count = var.front_door_secret == null ? 0 : 1

  cdn_frontdoor_profile_id = azapi_resource.front_door_profile.id
  name                     = "front-certificate"

  secret {
    customer_certificate {
      key_vault_certificate_id = var.front_door_secret.key_vault_certificate_id
    }
  }
}



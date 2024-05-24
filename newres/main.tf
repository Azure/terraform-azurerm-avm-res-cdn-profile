resource "azurerm_cdn_endpoint_custom_domain" "this" {
  cdn_endpoint_id = var.cdn_endpoint_custom_domain.cdn_endpoint_id
  host_name       = var.cdn_endpoint_custom_domain.host_name
  name            = var.cdn_endpoint_custom_domain.name

  dynamic "cdn_managed_https" {
    for_each = var.cdn_endpoint_custom_domain.cdn_managed_https == null ? [] : [var.cdn_endpoint_custom_domain.cdn_managed_https]
    content {
      certificate_type = cdn_managed_https.value.certificate_type
      protocol_type    = cdn_managed_https.value.protocol_type
      tls_version      = cdn_managed_https.value.tls_version
    }
  }
  dynamic "timeouts" {
    for_each = var.cdn_endpoint_custom_domain.timeouts == null ? [] : [var.cdn_endpoint_custom_domain.timeouts]
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
  dynamic "user_managed_https" {
    for_each = var.cdn_endpoint_custom_domain.user_managed_https == null ? [] : [var.cdn_endpoint_custom_domain.user_managed_https]
    content {
      key_vault_certificate_id = user_managed_https.value.key_vault_certificate_id
      key_vault_secret_id      = user_managed_https.value.key_vault_secret_id
      tls_version              = user_managed_https.value.tls_version
    }
  }
}


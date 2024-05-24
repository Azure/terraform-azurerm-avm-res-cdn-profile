variable "cdn_endpoint_custom_domain" {
  type = object({
    cdn_endpoint_id = string
    host_name       = string
    name            = string
    cdn_managed_https = optional(object({
      certificate_type = string
      protocol_type    = string
      tls_version      = optional(string)
    }))
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
    user_managed_https = optional(object({
      key_vault_certificate_id = optional(string)
      key_vault_secret_id      = optional(string)
      tls_version              = optional(string)
    }))
  })
  description = <<-EOT
 - `cdn_endpoint_id` - (Required) The ID of the CDN Endpoint. Changing this forces a new CDN Endpoint Custom Domain to be created.
 - `host_name` - (Required) The host name of the custom domain. Changing this forces a new CDN Endpoint Custom Domain to be created.
 - `name` - (Required) The name which should be used for this CDN Endpoint Custom Domain. Changing this forces a new CDN Endpoint Custom Domain to be created.

 ---
 `cdn_managed_https` block supports the following:
 - `certificate_type` - (Required) The type of HTTPS certificate. Possible values are `Shared` and `Dedicated`.
 - `protocol_type` - (Required) The type of protocol. Possible values are `ServerNameIndication` and `IPBased`.
 - `tls_version` - (Optional) The minimum TLS protocol version that is used for HTTPS. Possible values are `TLS10` (representing TLS 1.0/1.1), `TLS12` (representing TLS 1.2) and `None` (representing no minimums). Defaults to `TLS12`.

 ---
 `timeouts` block supports the following:
 - `create` - (Defaults to 12 hours) Used when creating the Custom Domain for this CDN Endpoint.
 - `delete` - (Defaults to 12 hours) Used when deleting the CDN Endpoint Custom Domain.
 - `read` - (Defaults to 5 minutes) Used when retrieving the CDN Endpoint Custom Domain.
 - `update` - (Defaults to 24 hours) Used when updating the CDN Endpoint Custom Domain.

 ---
 `user_managed_https` block supports the following:
 - `key_vault_certificate_id` - (Optional) The ID of the Key Vault Certificate that contains the HTTPS certificate. This is deprecated in favor of `key_vault_secret_id`.
 - `key_vault_secret_id` - (Optional) The ID of the Key Vault Secret that contains the HTTPS certificate.
 - `tls_version` - (Optional) The minimum TLS protocol version that is used for HTTPS. Possible values are `TLS10` (representing TLS 1.0/1.1), `TLS12` (representing TLS 1.2) and `None` (representing no minimums). Defaults to `TLS12`.
EOT
  nullable    = false
}

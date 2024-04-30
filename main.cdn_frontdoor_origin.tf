resource "azurerm_cdn_frontdoor_origin" "origins" {
  for_each = var.origin

  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.example[each.value.origin_group_name].id
  certificate_name_check_enabled = each.value.certificate_name_check_enabled
  host_name                      = each.value.host_name
  name                           = each.value.name
  enabled                        = each.value.enabled
  http_port                      = each.value.http_port
  https_port                     = each.value.https_port
  origin_host_header             = each.value.host_header
  priority                       = each.value.priority
  weight                         = each.value.weight

  dynamic "private_link" {
    for_each = each.value.private_link != null ? (each.value.private_link) : {}

    content {
      location               = private_link.value.location
      private_link_target_id = private_link.value.private_link_target_id
      request_message        = private_link.value.request_message
      target_type            = private_link.value.target_type
    }
  }
}
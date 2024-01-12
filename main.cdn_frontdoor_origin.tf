resource "azurerm_cdn_frontdoor_origin" "origins" {
  for_each                       = var.origin
  name                           = each.value.name
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.example[each.value.origin_group_name].id
  enabled                        = each.value.enabled
  certificate_name_check_enabled = each.value.certificate_name_check_enabled
  host_name                      = each.value.host_name
  http_port                      = each.value.http_port
  https_port                     = each.value.https_port
  origin_host_header             = each.value.host_header
  priority                       = each.value.priority
  weight                         = each.value.weight
}
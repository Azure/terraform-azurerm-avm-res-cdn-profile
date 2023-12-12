resource "azurerm_cdn_frontdoor_origin" "example" {
  name                          = var.origin_name
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.example.id
  enabled                       = var.origin_enabled

  certificate_name_check_enabled = var.origin_certificate_name_check_enabled
  host_name          = var.origin_host_name
  http_port          = var.origin_http_port
  https_port         = var.origin_https_port
  origin_host_header = var.origin_host_header
  priority           = var.origin_priority
  weight             = var.origin_weight
}
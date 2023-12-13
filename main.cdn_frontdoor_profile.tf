resource "azurerm_cdn_frontdoor_profile" "example" {
  name                = var.name
  resource_group_name = var.resource_group_name
  sku_name            = var.sku_name
  tags                = var.tags
}
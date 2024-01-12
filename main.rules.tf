resource "azurerm_cdn_frontdoor_rule_set" "example" {
  for_each                 = var.rule_sets
  name                     = each.value
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.example.id
}
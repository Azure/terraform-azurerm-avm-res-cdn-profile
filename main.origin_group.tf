resource "azurerm_cdn_frontdoor_origin_group" "example" {
  name                     = var.origin_group_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.example.id
  session_affinity_enabled = true

  restore_traffic_time_to_healed_or_new_endpoint_in_minutes = 10

 dynamic "health_probe" {
  for_each = var.health_probe
  content {
    interval_in_seconds = health_probe.value["interval_in_seconds"]
    protocol = health_probe.value["protocol"]
    path = health_probe.value["path"]
    request_type = health_probe.value["request_type"]
  }
 }

 dynamic "load_balancing" {
  for_each = var.load_balancing
  content {
    additional_latency_in_milliseconds = load_balancing.value["additional_latency_in_milliseconds"]
    sample_size = load_balancing.value["sample_size"]
    successful_samples_required = load_balancing.value["successful_samples_required"]
  }
 }
}
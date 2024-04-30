output "resource_id" {
  value = azapi_resource.front_door_profile.id
}

# TODO: insert outputs here.
output "resource_name" {
  value = azapi_resource.front_door_profile.name
}

output "system_assigned_mi_principal_id" {
  value = try(azapi_resource.front_door_profile.identity[0].principal_id, null)
}

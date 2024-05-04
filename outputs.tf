output "resource_id" {
  description = " The resource id of the Front door profile"
  value       = azapi_resource.front_door_profile.id
}

output "resource_name" {
  description = " The resource name of the Front door profile"
  value       = azapi_resource.front_door_profile.name
}

output "system_assigned_mi_principal_id" {
  description = " The system assigned managed identity of the front door profile"
  value       = try(azapi_resource.front_door_profile.identity[0].principal_id, null)
}

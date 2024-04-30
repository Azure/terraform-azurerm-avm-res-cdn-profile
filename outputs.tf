output "resource_id" {
  value       = azapi_resource.front_door_profile.id
  description = " The resource id of the Front door profile"
}

output "resource_name" {
  value       = azapi_resource.front_door_profile.name
  description = " The resource name of the Front door profile"
}

output "system_assigned_mi_principal_id" {
  value       = try(azapi_resource.front_door_profile.identity[0].principal_id, null)
  description = " The system assigned managed identity of the front door profile"
}

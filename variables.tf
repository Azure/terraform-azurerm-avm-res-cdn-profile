variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see https://aka.ms/avm/telemetryinfo.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

# This is required for most resource modules
variable "resource_group_name" {
  type        = string
  description = "The resource group where the resources will be deployed."
}

variable "name" {
  type = string
}

variable "sku_name" {
  type = string
}

variable "tags" {
  type    = map(any)
  default = null
}

variable "response_timeout_seconds" {
  type    = number
  default = 16
}

variable "location" {
  type    = string
  default = null
}

variable "origin_groups" {
  type = map(object({
    name = string
    health_probe = optional(map(object({
      interval_in_seconds = number
      path                = optional(string, "/")
      protocol            = string
      request_type        = optional(string, "HEAD")
    })), {})
    load_balancing = map(object({
      additional_latency_in_milliseconds = optional(number, 50)
      sample_size                        = optional(number, 4)
      successful_samples_required        = optional(number, 3)
    }))
  }))
  default = null
}

variable "origin" {
  type = map(object({
    name                           = string
    origin_group_name              = string
    host_name                      = string
    certificate_name_check_enabled = string
    enabled                        = string
    http_port                      = optional(number, 80)
    https_port                     = optional(number, 443)
    host_header                    = optional(string, null)
    priority                       = optional(number, 1)
    weight                         = optional(number, 500)
  }))
}

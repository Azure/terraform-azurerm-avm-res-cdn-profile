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
  type = string
  default = null
}

variable "origin_group_name" {
  type = string
  default = null
}

variable "health_probe" {
  type = map(object({
    interval_in_seconds = number
    path = string
    protocol = string
    request_type = string
  }))
  default = {}
}


variable "load_balancing" {
  type = map(object({
    additional_latency_in_milliseconds = number
    sample_size = number
    successful_samples_required = number
  }))
  default =  {
      
    }
  }

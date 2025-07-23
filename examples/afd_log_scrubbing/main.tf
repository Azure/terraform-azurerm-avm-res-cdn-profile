terraform {
  required_version = ">= 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.116.0, < 5.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0, < 4.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# This ensures we have a unique suffix for resource names
resource "random_integer" "region_index" {
  max = 100
  min = 1
}

# Create a resource group
resource "azurerm_resource_group" "this" {
  location = var.location
  name     = module.naming.resource_group.name_unique
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.1"
}

# Deploy the Azure Front Door profile with log scrubbing
module "afd_log_scrubbing" {
  source = "../../"

  # Basic configuration
  location            = azurerm_resource_group.this.location
  name                = module.naming.cdn_profile.name_unique
  resource_group_name = azurerm_resource_group.this.name
  # Enable telemetry (default: true)
  enable_telemetry = var.enable_telemetry
  # Optional: Configure response timeout
  response_timeout_seconds = 120
  # Log scrubbing configuration
  scrubbing_rule = [
    {
      match_variable = "RequestIPAddress"
    },
    {
      match_variable = "RequestUri"
    },
    {
      match_variable = "QueryStringArgNames"
    }
  ]
  sku = "Premium_AzureFrontDoor"
  # Tagging
  tags = {
    environment = "example"
    purpose     = "log-scrubbing-demo"
    department  = "security"
  }
}

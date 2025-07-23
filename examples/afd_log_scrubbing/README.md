<!-- BEGIN_TF_DOCS -->
# Azure Front Door Log Scrubbing Example

This example demonstrates how to configure log scrubbing for an Azure Front Door profile using the Azure Verified Module (AVM) for CDN Profile.

Log scrubbing allows you to control what data gets removed or masked from access logs for compliance and privacy purposes. This is particularly useful for organizations that need to comply with data protection regulations like GDPR while maintaining operational visibility.

## Features Demonstrated

- Premium Azure Front Door profile with log scrubbing enabled
- Multiple scrubbing rules for different data types:
  - Request IP addresses
  - Query string argument names  
  - Request URIs
- Proper tagging for resource management

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## Important Notes

- Log scrubbing is automatically **enabled** when one or more `scrubbing_rule` blocks are present
- Log scrubbing is automatically **disabled** when no `scrubbing_rule` blocks are defined
- Maximum of 3 scrubbing rules allowed per profile
- The operator is implicitly set to `EqualsAny` and cannot be changed
- Log scrubbing requires either Standard or Premium Azure Front Door SKU

## Compliance Benefits

This configuration helps organizations:
- Remove sensitive data from access logs
- Meet GDPR and other privacy regulation requirements
- Maintain operational visibility while protecting customer privacy
- Implement defense-in-depth security practices

```hcl
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
  version = "0.4.2"
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
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.116.0, < 5.0.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (>= 3.5.0, < 4.0.0)

## Resources

The following resources are used by this module:

- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [random_integer.region_index](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see <https://aka.ms/avm/telemetryinfo>.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `false`

### <a name="input_location"></a> [location](#input\_location)

Description: The Azure region where the resources will be deployed.

Type: `string`

Default: `"East US"`

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_afd_log_scrubbing"></a> [afd\_log\_scrubbing](#module\_afd\_log\_scrubbing)

Source: ../../

Version:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: 0.4.2

## Clean up

To remove the resources created by this example:

```bash
terraform destroy
```

## Next Steps

- Learn more about [Azure Front Door log scrubbing](https://docs.microsoft.com/en-us/azure/frontdoor/logs-scrubbing)
- Explore other AVM examples in the `examples/` directory
- Review the [main module documentation](../../README.md) for additional configuration options

## Troubleshooting

If you encounter issues:

1. Verify you have the required Azure permissions
2. Ensure the Azure subscription supports Premium Front Door features
3. Check that all required providers are properly configured
4. Review the Terraform plan output for any validation errors
<!-- END_TF_DOCS -->
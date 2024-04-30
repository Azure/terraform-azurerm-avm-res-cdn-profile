<!-- BEGIN_TF_DOCS -->
# Default example

This deploys the module in its simplest form.

```hcl
terraform {
  required_version = ">= 1.3.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.7.0, < 4.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see https://aka.ms/avm/telemetryinfo.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
}

module "regions" {
  source  = "Azure/regions/azurerm"
  version = ">= 0.3.0"
}

# This is required for resource modules
# resource "azurerm_resource_group" "this" {
#   name     = module.naming.resource_group.name_unique
#   location = "centralindia"
# }

resource "azurerm_resource_group" "this" {
  location = "centralindia"
  name     = module.naming.resource_group.name_unique
}


# This is the module call
module "azurerm_cdn_profile" {
  #depends_on = [ data.azurerm_resource_group.this ]
  source = "/workspaces/terraform-azurerm-avm-res-cdn-profile"
  # source             = "Azure/avm-<res/ptn>-<name>/azurerm"
  tags = {
    environment = "production"
  }
  enable_telemetry    = true
  name                = module.naming.cdn_profile.name_unique
  location            = azurerm_resource_group.this.location
  sku_name            = "Standard_Microsoft"
  resource_group_name = azurerm_resource_group.this.name
  cdn_endpoints = {
    ep1 = {
      name                          = "endpoint-${module.naming.cdn_endpoint.name_unique}"
      is_http_allowed               = true
      is_https_allowed              = true
      querystring_caching_behaviour = "BypassCaching"
      is_compression_enabled        = true
      optimization_type             = "GeneralWebDelivery"
      #geo_filters = {}
      # geo_filters = { # Only one geo filter allowed for Standard_Microsoft sku
      #   gf1 = {
      #     relative_path = "/" # Must be / for Standard_Microsoft sku
      #     action        = "Block"
      #     country_codes = ["AF", "GB"]
      #   }
      #   # gf2 = {
      #   #   relative_path = "/foo" 
      #   #   action        = "Allow"
      #   #   country_codes = ["AF", "GB"]
      #   # }
      # }
      content_types_to_compress = [
        "application/eot",
        "application/font",
        "application/font-sfnt",
        "application/javascript",
        "application/json",
        "application/opentype",
        "application/otf",
        "application/pkcs7-mime",
        "application/truetype",
        "application/ttf",
        "application/vnd.ms-fontobject",
        "application/xhtml+xml",
        "application/xml",
        "application/xml+rss",
        "application/x-font-opentype",
        "application/x-font-truetype",
        "application/x-font-ttf",
        "application/x-httpd-cgi",
        "application/x-javascript",
        "application/x-mpegurl",
        "application/x-opentype",
        "application/x-otf",
        "application/x-perl",
        "application/x-ttf",
        "font/eot",
        "font/ttf",
        "font/otf",
        "font/opentype",
        "image/svg+xml",
        "text/css",
        "text/csv",
        "text/html",
        "text/javascript",
        "text/js",
        "text/plain",
        "text/richtext",
        "text/tab-separated-values",
        "text/xml",
        "text/x-script",
        "text/x-component",
        "text/x-java-source",
      ]
      global_delivery_rule = {

        cache_expiration_action = {
          behavior = "Override"
          duration = "1.10:30:00"
        }
        cache_key_query_string_action = {
          behavior   = "Include"
          parameters = "*"
        }

      }
      origin_host_header = "ddsharedstorage.blob.core.windows.net"
      origin_path        = "/media"
      probe_path         = "/foo.bar"
      origins = {
        og1 = { name = "origin1"
          host_name = "ddsharedstorage.blob.core.windows.net"
        }
      }
    }
  }
  managed_identities = {
    system_assigned = true
  }
}

output "cdn_profile" {
  value = module.azurerm_cdn_profile.system_assigned_mi_principal_id
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.3.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.7.0, < 4.0.0)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (>= 3.7.0, < 4.0.0)

- <a name="provider_random"></a> [random](#provider\_random)

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
For more information see https://aka.ms/avm/telemetryinfo.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

## Outputs

The following outputs are exported:

### <a name="output_cdn_profile"></a> [cdn\_profile](#output\_cdn\_profile)

Description: n/a

## Modules

The following Modules are called:

### <a name="module_azurerm_cdn_profile"></a> [azurerm\_cdn\_profile](#module\_azurerm\_cdn\_profile)

Source: /workspaces/terraform-azurerm-avm-res-cdn-profile

Version:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: 0.3.0

### <a name="module_regions"></a> [regions](#module\_regions)

Source: Azure/regions/azurerm

Version: >= 0.3.0

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->
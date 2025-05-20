<!-- BEGIN_TF_DOCS -->
# Default example

This deploys the module in its simplest form.

```hcl
terraform {
  required_version = "~> 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.74"
    }
  }
}

provider "azurerm" {
  features {}
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
}

resource "azurerm_resource_group" "this" {
  location = "eastus"
  name     = "secpol-${module.naming.resource_group.name_unique}"
}

# resource block for DNS zones
resource "azurerm_dns_zone" "dnszone" {
  name                = "foo-${module.naming.dns_zone.name_unique}.bar"
  resource_group_name = azurerm_resource_group.this.name
}

# This is the module call
module "azurerm_cdn_frontdoor_profile" {
  source = "../../"

  location            = azurerm_resource_group.this.location
  name                = module.naming.cdn_profile.name_unique
  resource_group_name = azurerm_resource_group.this.name
  enable_telemetry    = var.enable_telemetry
  front_door_custom_domains = {
    cd1_key = {
      name        = "contoso1customdomain"
      dns_zone_id = azurerm_dns_zone.dnszone.id
      host_name   = "contoso1.fabrikam.com"

      tls = {
        certificate_type    = "ManagedCertificate"
        minimum_tls_version = "TLS12"
      }
    },
    cd2_key = {
      name        = "contoso2customdomain"
      dns_zone_id = azurerm_dns_zone.dnszone.id
      host_name   = "contoso2.fabrikam.com"
      tls = {
        certificate_type    = "ManagedCertificate"
        minimum_tls_version = "TLS12"
      }
    }
  }
  front_door_endpoints = {
    ep1_key = {
      name = "ep1-${module.naming.cdn_endpoint.name_unique}"
      tags = {
        environment = "avm-demo"
      }
    }
    ep2_key = {
      name = "ep2-${module.naming.cdn_endpoint.name_unique}"
      tags = {
        environment = "avm-demo"
      }
    }
    ep3_key = {
      name = "ep3-${module.naming.cdn_endpoint.name_unique}"
      tags = {
        environment = "avm-demo"
      }
    }
  }
  front_door_firewall_policies = {
    fd_waf1_key = {
      name                              = "examplecdnfdwafpolicy1"
      resource_group_name               = azurerm_resource_group.this.name
      sku_name                          = "Premium_AzureFrontDoor" # Ensure SKU_name for WAF is similar to SKU_name for front door profile.
      enabled                           = true
      mode                              = "Prevention"
      redirect_url                      = "https://www.contoso.com"
      custom_block_response_status_code = 405
      custom_block_response_body        = "PGh0bWw+CjxoZWFkZXI+PHRpdGxlPkhlbGxvPC90aXRsZT48L2hlYWRlcj4KPGJvZHk+CkhlbGxvIHdvcmxkCjwvYm9keT4KPC9odG1sPg=="

      custom_rules = {
        cr1 = {
          name                           = "Rule1"
          enabled                        = true
          priority                       = 1
          rate_limit_duration_in_minutes = 1
          rate_limit_threshold           = 10
          type                           = "MatchRule"
          action                         = "Block"
          match_conditions = {
            m1 = {
              match_variable     = "RemoteAddr"
              operator           = "IPMatch"
              negation_condition = false
              match_values       = ["10.0.1.0/24", "10.0.0.0/24"]
            }
          }
        }

        cr2 = {
          name                           = "Rule2"
          enabled                        = true
          priority                       = 2
          rate_limit_duration_in_minutes = 1
          rate_limit_threshold           = 10
          type                           = "MatchRule"
          action                         = "Block"
          match_conditions = {
            match_condition1 = {
              match_variable     = "RemoteAddr"
              operator           = "IPMatch"
              negation_condition = false
              match_values       = ["192.168.1.0/24"]
            }

            match_condition2 = {
              match_variable     = "RequestHeader"
              selector           = "UserAgent"
              operator           = "Contains"
              negation_condition = false
              match_values       = ["windows"]
              transforms         = ["Lowercase", "Trim"]
            }
          }
        }
      }

      # if using Standard sku , then managed rules are not supported, hence remove the below input variables
      managed_rules = {
        mr1 = {
          type    = "Microsoft_DefaultRuleSet"
          version = "2.1"
          action  = "Log"
          exclusions = {
            exclusion1 = {
              match_variable = "QueryStringArgNames"
              operator       = "Equals"
              selector       = "not_suspicious"
            }
          }
          overrides = {
            override1 = {
              rule_group_name = "PHP"
              rule = {
                rule1 = {
                  rule_id = "933100"
                  enabled = false
                  action  = "Log"
                }
              }
            }

            override2 = {
              rule_group_name = "SQLI"
              exclusions = {
                exclusion1 = {
                  match_variable = "QueryStringArgNames"
                  operator       = "Equals"
                  selector       = "really_not_suspicious"
                }
              }
              rules = {
                rule1 = {
                  rule_id = "942200"
                  action  = "Log"
                  exclusions = {
                    exclusion1 = {
                      match_variable = "QueryStringArgNames"
                      operator       = "Equals"
                      selector       = "innocent"
                    }
                  }
                }
              }
            }
          }
        }

        mr2 = {
          type    = "Microsoft_BotManagerRuleSet"
          version = "1.0"
          action  = "Log"
        }
      }
    }
    fd_waf2_key = {
      name                              = "examplecdnfdwafpolicy2"
      resource_group_name               = azurerm_resource_group.this.name
      sku_name                          = "Premium_AzureFrontDoor" # Ensure SKU_name for WAF is similar to SKU_name for front door profile.
      enabled                           = true
      mode                              = "Prevention"
      redirect_url                      = "https://www.contoso.com"
      custom_block_response_status_code = 405
      custom_block_response_body        = "PGh0bWw+CjxoZWFkZXI+PHRpdGxlPkhlbGxvPC90aXRsZT48L2hlYWRlcj4KPGJvZHk+CkhlbGxvIHdvcmxkCjwvYm9keT4KPC9odG1sPg=="

      custom_rules = {
        cr1 = {
          name                           = "Rule1"
          enabled                        = true
          priority                       = 1
          rate_limit_duration_in_minutes = 1
          rate_limit_threshold           = 10
          type                           = "MatchRule"
          action                         = "Block"
          match_conditions = {
            m1 = {
              match_variable     = "RemoteAddr"
              operator           = "IPMatch"
              negation_condition = false
              match_values       = ["10.0.1.0/24", "10.0.0.0/24"]
            }
          }
        }


        cr2 = {
          name                           = "Rule2"
          enabled                        = true
          priority                       = 2
          rate_limit_duration_in_minutes = 1
          rate_limit_threshold           = 10
          type                           = "MatchRule"
          action                         = "Block"
          match_conditions = {
            match_condition1 = {
              match_variable     = "RemoteAddr"
              operator           = "IPMatch"
              negation_condition = false
              match_values       = ["192.168.1.0/24"]
            }

            match_condition2 = {
              match_variable     = "RequestHeader"
              selector           = "UserAgent"
              operator           = "Contains"
              negation_condition = false
              match_values       = ["windows"]
              transforms         = ["Lowercase", "Trim"]
            }
          }
        }
      }
    }
  }
  front_door_origin_groups = {
    og1_key = {
      name = "og1"
      health_probe = {
        hp1 = {
          interval_in_seconds = 240
          path                = "/healthProbe"
          protocol            = "Https"
          request_type        = "HEAD"
        }
      }
      load_balancing = {
        lb1 = {
          additional_latency_in_milliseconds = 0
          sample_size                        = 16
          successful_samples_required        = 3
        }
      }
    }
  }
  front_door_origins = {
    origin1_key = {
      name                           = "origin1"
      origin_group_key               = "og1_key"
      enabled                        = true
      certificate_name_check_enabled = false
      host_name                      = "contoso1.com"
      http_port                      = 80
      https_port                     = 443
      host_header                    = "www.contoso1.com"
      priority                       = 1
      weight                         = 1
    }
    origin2_key = {
      name                           = "origin2"
      origin_group_key               = "og1_key"
      enabled                        = true
      certificate_name_check_enabled = false
      host_name                      = "contoso2.com"
      http_port                      = 80
      https_port                     = 443
      host_header                    = "www.contoso2.com"
      priority                       = 1
      weight                         = 1
    }
    origin3_key = {
      name                           = "origin3"
      origin_group_key               = "og1_key"
      enabled                        = true
      certificate_name_check_enabled = false
      host_name                      = "contoso3.com"
      http_port                      = 80
      https_port                     = 443
      host_header                    = "www.contoso3.com"
      priority                       = 1
      weight                         = 1
    }
  }
  front_door_routes = {
    route1_key = {
      name                   = "route1"
      endpoint_key           = "ep1_key"
      origin_group_key       = "og1_key"
      origin_keys            = ["origin1_key"]
      forwarding_protocol    = "HttpsOnly"
      https_redirect_enabled = true
      custom_domain_keys     = ["cd1_key", "cd2_key"]
      patterns_to_match      = ["/*"]
      supported_protocols    = ["Http", "Https"]
      rule_set_names         = ["ruleset1"]
      cache = {
        cache1 = {
          query_string_caching_behavior = "IgnoreSpecifiedQueryStrings"
          query_strings                 = ["account", "settings"]
          compression_enabled           = true
          content_types_to_compress     = ["text/html", "text/javascript", "text/xml"]
        }
      }
    }
    route2_key = {
      name                   = "route2"
      endpoint_key           = "ep2_key"
      origin_group_key       = "og1_key"
      origin_keys            = ["origin2_key"]
      forwarding_protocol    = "HttpsOnly"
      https_redirect_enabled = true
      #custom_domain_keys     = ["cd1_key", "cd2_key"]
      patterns_to_match   = ["/*"]
      supported_protocols = ["Http", "Https"]
    }
    route3_key = {
      name                   = "route3"
      endpoint_key           = "ep3_key"
      origin_group_key       = "og1_key"
      origin_keys            = ["origin3_key"]
      forwarding_protocol    = "HttpsOnly"
      https_redirect_enabled = true
      #custom_domain_keys     = ["cd1_key", "cd2_key"]
      patterns_to_match   = ["/*"]
      supported_protocols = ["Http", "Https"]
    }
  }
  front_door_rule_sets = ["ruleset1", "ruleset2"]
  front_door_rules = {
    rule1_key = {
      name              = "examplerule1"
      order             = 1
      behavior_on_match = "Continue"
      rule_set_name     = "ruleset1"
      origin_group_key  = "og1_key"
      actions = {

        url_rewrite_actions = [{
          source_pattern          = "/"
          destination             = "/index3.html"
          preserve_unmatched_path = false
        }]
        route_configuration_override_actions = [{
          set_origin_groupid            = true
          forwarding_protocol           = "HttpsOnly"
          query_string_caching_behavior = "IncludeSpecifiedQueryStrings"
          query_string_parameters       = ["foo", "clientIp={client_ip}"]
          compression_enabled           = true
          cache_behavior                = "OverrideIfOriginMissing"
          cache_duration                = "365.23:59:59"
        }]
        response_header_actions = [{
          header_action = "Append"
          header_name   = "headername"
          value         = "/abc"
        }]
        request_header_actions = [{
          header_action = "Append"
          header_name   = "headername"
          value         = "/abc"
        }]
      }

      conditions = {
        remote_address_conditions = [{
          operator         = "IPMatch"
          negate_condition = false
          match_values     = ["10.0.0.0/23"]
        }]

        query_string_conditions = [{
          negate_condition = false
          operator         = "BeginsWith"
          match_values     = ["Query1", "Query2"]
          transforms       = ["Uppercase"]
        }]

        request_header_conditions = [{
          header_name      = "headername"
          negate_condition = false
          operator         = "BeginsWith"
          match_values     = ["Header1", "Header2"]
          transforms       = ["Uppercase"]
        }]

        request_body_conditions = [{
          negate_condition = false
          operator         = "BeginsWith"
          match_values     = ["Body1", "Body2"]
          transforms       = ["Uppercase"]
        }]

        request_scheme_conditions = [{
          negate_condition = false
          operator         = "Equal"
          match_values     = ["HTTP"]
        }]

        url_path_conditions = [{
          negate_condition = false
          operator         = "BeginsWith"
          match_values     = ["UrlPath1", "UrlPath2"]
          transforms       = ["Uppercase"]
        }]

        url_file_extension_conditions = [{
          negate_condition = false
          operator         = "BeginsWith"
          match_values     = ["ext1", "ext2"]
          transforms       = ["Uppercase"]
        }]

        url_filename_conditions = [{
          negate_condition = false
          operator         = "BeginsWith"
          match_values     = ["filename1", "filename2"]
          transforms       = ["Uppercase"]
        }]

        http_version_conditions = [{
          negate_condition = false
          operator         = "Equal"
          match_values     = ["2.0"]
        }]

        cookies_conditions = [{
          cookie_name      = "cookie"
          negate_condition = false
          operator         = "BeginsWith"
          match_values     = ["cookie1", "cookie2"]
          transforms       = ["Uppercase"]
        }]
      }
    }
  }
  front_door_security_policies = {
    secpol1_key = {
      name = "firewallpolicyforep1cd1"
      firewall = {
        front_door_firewall_policy_key = "fd_waf1_key"
        association = {
          endpoint_keys     = ["ep1_key"]
          domain_keys       = ["cd1_key"]
          patterns_to_match = ["/*"]
        }
      }
    }
    secpol3_key = {
      name = "firewallpolicyforep2andep3cd2"
      firewall = {
        front_door_firewall_policy_key = "fd_waf2_key"
        association = {
          endpoint_keys     = ["ep2_key", "ep3_key"]
          domain_keys       = ["cd2_key"]
          patterns_to_match = ["/*"]
        }
      }
    }
  }
  sku = "Premium_AzureFrontDoor"
  tags = {
    environment = "avm-demo"
  }
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.5)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 3.74)

## Resources

The following resources are used by this module:

- [azurerm_dns_zone.dnszone](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_zone) (resource)
- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)

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

No outputs.

## Modules

The following Modules are called:

### <a name="module_azurerm_cdn_frontdoor_profile"></a> [azurerm\_cdn\_frontdoor\_profile](#module\_azurerm\_cdn\_frontdoor\_profile)

Source: ../../

Version:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: 0.3.0

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->
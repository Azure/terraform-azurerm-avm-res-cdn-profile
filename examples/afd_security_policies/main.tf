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
  location = "centralindia"
  name     = module.naming.resource_group.name_unique
}

# resource block for DNS zones
resource "azurerm_dns_zone" "dnszone" {
  name                = "avm-domain.domain.com"
  resource_group_name = azurerm_resource_group.this.name
}

# This is the module call
module "azurerm_cdn_frontdoor_profile" {
  source              = "../../"
  enable_telemetry    = var.enable_telemetry
  name                = module.naming.cdn_profile.name_unique
  location            = azurerm_resource_group.this.location
  sku                 = "Premium_AzureFrontDoor"
  resource_group_name = azurerm_resource_group.this.name
  front_door_origin_groups = {
    og1 = {
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
    origin1 = {
      name                           = "example-origin1"
      origin_group_name              = "og1"
      enabled                        = true
      certificate_name_check_enabled = false
      host_name                      = "contoso.com"
      http_port                      = 80
      https_port                     = 443
      host_header                    = "www.contoso.com"
      priority                       = 1
      weight                         = 1
    }
    origin2 = {
      name                           = "origin2"
      origin_group_name              = "og1"
      enabled                        = true
      certificate_name_check_enabled = false
      host_name                      = "contoso1.com"
      http_port                      = 80
      https_port                     = 443
      host_header                    = "www.contoso.com"
      priority                       = 1
      weight                         = 1
    }
    origin3 = {
      name                           = "origin3"
      origin_group_name              = "og1"
      enabled                        = true
      certificate_name_check_enabled = false
      host_name                      = "contoso1.com"
      http_port                      = 80
      https_port                     = 443
      host_header                    = "www.contoso.com"
      priority                       = 1
      weight                         = 1
    }

  }

  front_door_endpoints = {
    ep1 = {
      name = "ep1"
      tags = {
        ENV = "example"
      }
    }
    ep2 = {
      name = "ep2"
      tags = {
        ENV = "example2"
      }
    }
    ep3 = {
      name = "ep3"
      tags = {
        ENV = "example3"
      }
    }
  }

  front_door_custom_domains = {
    cd1 = {
      name        = "example-customDomain"
      dns_zone_id = azurerm_dns_zone.dnszone.id
      host_name   = "contoso.fabrikam.com"

      tls = {
        certificate_type    = "ManagedCertificate"
        minimum_tls_version = "TLS12"
      }
    },
    cd2 = {
      name        = "customdomain2"
      dns_zone_id = azurerm_dns_zone.dnszone.id
      host_name   = "contoso2.fabrikam.com"
      tls = {
        certificate_type    = "ManagedCertificate"
        minimum_tls_version = "TLS12"
      }
    }
  }

  front_door_routes = {
    route1 = {
      name                   = "route1"
      endpoint_name          = "ep1"
      origin_group_name      = "og1"
      origin_names           = ["example-origin1"]
      forwarding_protocol    = "HttpsOnly"
      https_redirect_enabled = true
      custom_domain_names    = ["example-customDomain", "customdomain2"]
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
    route2 = {
      name                   = "route2"
      endpoint_name          = "ep2"
      origin_group_name      = "og1"
      origin_names           = ["origin2"]
      forwarding_protocol    = "HttpsOnly"
      https_redirect_enabled = true
      # custom_domain_names    = ["example-customDomain", "customdomain2"]
      patterns_to_match      = ["/*"]
      supported_protocols    = ["Http", "Https"]
    }
    route3 = {
      name                   = "route3"
      endpoint_name          = "ep3"
      origin_group_name      = "og1"
      origin_names           = ["origin3"]
      forwarding_protocol    = "HttpsOnly"
      https_redirect_enabled = true
      # custom_domain_names    = ["example-customDomain", "customdomain2"]
      patterns_to_match      = ["/*"]
      supported_protocols    = ["Http", "Https"]
    }
  }

  front_door_rule_sets = ["ruleset1", "ruleset2"]

  front_door_rules = {
    rule1 = {
      name              = "examplerule1"
      order             = 1
      behavior_on_match = "Continue"
      rule_set_name     = "ruleset1"
      origin_group_name = "og1"
      actions = {
        url_rewrite_action = {
          actiontype              = "url_rewrite_action"
          source_pattern          = "/"
          destination             = "/index3.html"
          preserve_unmatched_path = false
        }
        route_configuration_override_action = {
          set_origin_groupid            = true
          actiontype                    = "route_configuration_override_action"
          forwarding_protocol           = "HttpsOnly"
          query_string_caching_behavior = "IncludeSpecifiedQueryStrings"
          query_string_parameters       = ["foo", "clientIp={client_ip}"]
          compression_enabled           = true
          cache_behavior                = "OverrideIfOriginMissing"
          cache_duration                = "365.23:59:59"
        }
        response_header_action = {
          header_action = "Append"
          header_name   = "headername"
          value         = "/abc"
        }
        request_header_action = {
          header_action = "Append"
          header_name   = "headername"
          value         = "/abc"
        }
      }

      conditions = {
        remote_address_condition = {
          operator         = "IPMatch"
          negate_condition = false
          match_values     = ["10.0.0.0/23"]
        }

        query_string_condition = {
          negate_condition = false
          operator         = "BeginsWith"
          match_values     = ["J", "K"]
          transforms       = ["Uppercase"]
        }

        request_header_condition = {
          header_name      = "headername"
          negate_condition = false
          operator         = "BeginsWith"
          match_values     = ["J", "K"]
          transforms       = ["Uppercase"]
        }

        request_body_condition = {
          negate_condition = false
          operator         = "BeginsWith"
          match_values     = ["J", "K"]
          transforms       = ["Uppercase"]
        }

        request_scheme_condition = {
          negate_condition = false
          operator         = "Equal"
          match_values     = ["HTTP"]
        }

        url_path_condition = {
          negate_condition = false
          operator         = "BeginsWith"
          match_values     = ["J", "K"]
          transforms       = ["Uppercase"]
        }

        url_file_extension_condition = {
          negate_condition = false
          operator         = "BeginsWith"
          match_values     = ["J", "K"]
          transforms       = ["Uppercase"]
        }

        url_filename_condition = {
          negate_condition = false
          operator         = "BeginsWith"
          match_values     = ["J", "K"]
          transforms       = ["Uppercase"]
        }

        http_version_condition = {
          negate_condition = false
          operator         = "Equal"
          match_values     = ["2.0"]
        }

        cookies_condition = {
          cookie_name      = "cookie"
          negate_condition = false
          operator         = "BeginsWith"
          match_values     = ["J", "K"]
          transforms       = ["Uppercase"]
        }
      }
    }
  }

  front_door_firewall_policies = {
    fd_waf1 = {
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
    fd_waf2 = {
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
  front_door_security_policies = {
    secpol1 = {
      name = "firewallpolicyforep1"
      firewall = {
        front_door_firewall_policy_name = "examplecdnfdwafpolicy1"
        association = {
          endpoint_names    = ["ep1"]
          domain_names      = ["cd1"]
          patterns_to_match = ["/*"]
        }
      }
    }
    secpol3 = {
      name = "firewallpolicyforep2andep3"
      firewall = {
        front_door_firewall_policy_name = "examplecdnfdwafpolicy2"
        association = {
          endpoint_names    = ["ep2", "ep3"]
          domain_names      = ["cd2"]
          patterns_to_match = ["/*"]
        }
      }


    }
  }
}


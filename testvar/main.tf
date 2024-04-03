terraform {
  required_version = ">= 1.3.0"
  required_providers {
    # TODO: Ensure all required providers are listed here.
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.71.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "1.9.0"
    }
  }
}





variable "customdomains" {
  type = map(object({
    name = string
    id   = string
  }))
  default = {

    customdomain1 = {
      name = "cd1"
      id   = "cd1id"
    }

    customdomain2 = {
      name = "cd2"
      id   = "cd2id"
    }
  }
}

variable "endpoints" {
  type = map(object({
    name = string
    id   = string
  }))
  default = {

    endpoint1 = {
      name = "ep1"
      id   = "ep1id"
    }
    endpoint2 = {
      name = "ep2"
      id   = "ep2id"
    }
  }
}


variable "policies" {
  type = map(object({
    eps = list(string)
    cds = list(string)
  }))
  default = {
    secpol1 = {

      eps = ["ep1", "ep2"]
      cds = ["cd1", "cd2"]


    }
    secpol2 = {
      eps = ["ep3", "ep4"]
      cds = ["cd1", "cd5"]
    }
    secpol3 = {
      eps = ["ep5", "ep6"]
      cds = ["cd7", "cd8"]
    }
  }

  validation {
    condition     = length(flatten([for policy in var.policies : concat(policy.eps, policy.cds)])) == length(distinct(flatten([for policy in var.policies : concat(policy.eps, policy.cds)])))
    error_message = "Duplicate elements found in the combined list of 'eps' and 'cds' for all policy items"
  }
}






# locals {
#   epids = flatten([for v in var.policies : [for endpoint in var.endpoints : endpoint.id if endpoint.name == v.eps]])
# }


# locals {
#   epids = flatten([for v in var.policies : v.eps])
# }



locals {
  epids = flatten([for v in var.policies : flatten([for e in var.endpoints : e.id if contains(v.eps, e.name)])])
}

locals {
  alleps = flatten([for v in var.policies : v])
}





output "names" {
  value = local.epids
}

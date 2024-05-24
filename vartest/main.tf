variable "cds" {
  type = map(any)
  default = {
    cd1_key = {
      name = "cd1name"
      id   = "cd1id"
    }
    cd2_key = {
      name = "cd2name"
      id   = "cd2id"
    }
  }
}

variable "eps" {
  type = map(any)
  default = {
    ep1_key = {
      name = "ep1name"
      id   = "ep1id"
    }
    ep2_key = {
      name = "ep2name"
      id   = "ep2id"
    }
  }
}

variable "routes" {
  type = map(any)
  default = {
    route1_key = {
      name = "route1"
      id   = "route1id"
      firewall = {
        association = {
          endpoint_keys = ["ep1_key"]
          domain_keys   = ["cd1_key"]

        }
      }
    }
    route2_key = {
      name = "route1"
      id   = "route1id"
      firewall = {
        association = {
          endpoint_keys = ["ep1_key", "ep2_key"]
          domain_keys   = ["cd2_key"]

        }
      }
    }
  }
}

locals {
  filtered_eps_cds = { for k, v in var.routes : k =>
    concat([for item in try(v.firewall.association.endpoint_keys, []) : var.eps[item].id], [for item in try(v.firewall.association.domain_keys, []) : var.cds[item].id])
  }
}

output "f" {
  value = local.filtered_eps_cds
}
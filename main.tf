resource "ncloud_access_control_group" "acgs" {
  for_each = { for acg in var.access_control_groups : acg.name => acg if acg.name != "default" }

  name        = each.value.name
  description = each.value.description
  vpc_no      = each.value.vpc_id
}

data "ncloud_access_control_group" "default" {
  for_each = { for acg in var.access_control_groups : acg.name => acg }

  vpc_no     = each.value.vpc_id
  is_default = true
  filter {
    name  = "name"
    values = [".+default-acg$"]
    regex = true
  }
}

locals {
  acg_ids = merge(
    { for acg in var.access_control_groups : acg.name => data.ncloud_access_control_group.default[acg.name].id if acg.name == "default" },
    { for acg_key, acg_value in ncloud_access_control_group.acgs : acg_key => acg_value.id }
  )
  acg_rules = { for acg_key, acg_id in local.acg_ids : acg_key =>
    {
      acg_id = acg_id
      inbound_rules = [for rule in var.access_control_groups[index(var.access_control_groups.*.name, acg_key)].inbound_rules :
        {
          protocol = rule[0]
          ip_block = (can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}\\/[0-9]{1,2}$", rule[1]))
            ? rule[1] : null
          )
          source_access_control_group_no = (can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}\\/[0-9]{1,2}$", rule[1]))
            ? null : local.acg_ids[rule[1]]
          )
          port_range  = rule[2]
          description = rule[3]
        }
      ]
      outbound_rules = [for rule in var.access_control_groups[index(var.access_control_groups.*.name, acg_key)].outbound_rules :
        {
          protocol = rule[0]
          ip_block = (can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}\\/[0-9]{1,2}$", rule[1]))
            ? rule[1] : null
          )
          source_access_control_group_no = (can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}\\/[0-9]{1,2}$", rule[1]))
            ? null : local.acg_ids[rule[1]]
          )
          port_range  = rule[2]
          description = rule[3]
        }
      ]
    }
  }
}

resource "ncloud_access_control_group_rule" "acg_rules" {
  for_each = { for rule_key, rule in local.acg_rules : rule_key
    => rule if(length(rule.inbound_rules) != 0) || (length(rule.outbound_rules) != 0)
  }

  access_control_group_no = each.value.acg_id

  dynamic "inbound" {
    for_each = each.value.inbound_rules
    content {
      protocol                       = inbound.value.protocol
      port_range                     = inbound.value.port_range
      ip_block                       = inbound.value.ip_block
      source_access_control_group_no = inbound.value.source_access_control_group_no
      description                    = inbound.value.description
    }
  }

  dynamic "outbound" {
    for_each = each.value.outbound_rules
    content {
      protocol                       = outbound.value.protocol
      port_range                     = outbound.value.port_range
      ip_block                       = outbound.value.ip_block
      source_access_control_group_no = outbound.value.source_access_control_group_no
      description                    = outbound.value.description
    }
  }
}

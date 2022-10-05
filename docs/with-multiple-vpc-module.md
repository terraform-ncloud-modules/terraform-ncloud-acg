# ACG Module with multiple VPC Module

This document describes the Terraform module that creates `Ncloud Access Control Groups`.
If you want to use `ACG module` with [multiple VPC Module](https://github.com/terraform-ncloud-modules/terraform-ncloud-vpc/blob/master/docs/multiple-vpc.md), please refer to this article.

## Variable Declaration

### `variable.tf`

You need to create `variable.tf` and declare the ACG variable to recognize ACG variable in `terraform.tfvars`. You can change the variable name to whatever you want.

``` hcl
variable "access_control_groups" {}
```

### `terraform.tfvars`

You can create `terraform.tfvars` and refer to the sample below to write variable declarations.
File name can be `terraform.tfvars` or anything ending in `.auto.tfvars`

#### Structure

Unlike [ACG Module with single VPC Module](https://github.com/terraform-ncloud-modules/terraform-ncloud-acg/blob/master/docs/with-single-vpc-module.md), `ACG Module with multiple VPC Module` requires `vpc_name` additionally.

``` hcl
// ACG declaration (Optional, List)
access_control_groups = [
  {
    name        = string
    description = string
    vpc_name    = string

    // The order of writing inbound_rules & outbound_rules is as follows.
    // [protocol, ip_block|source_access_control_group, port_range, description]
    inbound_rules = [
      [
        string,            // TCP | UDP | ICMP
        string,            // CIDR | AccessControlGroupName
                           // Set to "default" to set "default ACG" to source_access_control_group.
        integer|string,    // PortNumber(22) | PortRange(1-65535)
        string
      ]
    ]
    outbound_rules = []    // same as above
  }
]  

```

#### Example

``` hcl
access_control_groups = [
  {
    name          = "default"
    description   = "Default ACG for vpc-multiple"
    vpc_name      = "vpc-multiple"
    inbound_rules = []
    outbound_rules = [
      ["TCP", "0.0.0.0/0", "1-65535", "All allow to any"],
      ["UDP", "0.0.0.0/0", "1-65535", "All allow to any"]
    ]
  },
  {
    name        = "acg-multiple-public"
    description = "ACG for public servers"
    vpc_name    = "vpc-multiple"
    inbound_rules = [
      ["TCP", "0.0.0.0/0", 22, "SSH allow form any"]
    ]
    outbound_rules = [
      ["TCP", "0.0.0.0/0", "1-65535", "All allow to any"],
      ["UDP", "0.0.0.0/0", "1-65535", "All allow to any"]
    ]
  },
  {
    name        = "acg-multiple-private"
    description = "ACG for private servers"
    vpc_name    = "vpc-multiple"
    inbound_rules = [
      ["TCP", "acg-multiple-public", 22, "SSH allow form acg-multiple-public"]
    ]
    outbound_rules = [
      ["TCP", "0.0.0.0/0", "1-65535", "All allow to any"],
      ["UDP", "0.0.0.0/0", "1-65535", "All allow to any"]
    ]
  }
]
```

## Module Usage

### `main.tf`

Map your (`ACG variable name` & `VPC module name`) to (`local ACG variable` & `local VPC variable`). `ACG module` are created using `local ACG variable`. This eliminates the need to change the variable name reference structure in the `ACG module`.

``` hcl
locals {
  acgs = var.access_control_groups
  vpcs = module.vpcs
}
```

Then just copy and paste the module declaration below.

``` hcl
module "access_control_groups" {
  source = "terraform-ncloud-modules/acg/ncloud"

  access_control_groups = [for acg in local.acgs : merge(acg, { vpc_id = local.vpcs[acg.vpc_name].vpc.id })]
}
```
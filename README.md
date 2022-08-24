# Ncloud ACG Terraform module

## Module Usage

You can manage ACGs using ACG module. But you can also manage ACGs within VPC module ([terraform-ncloud-modules/vpc/ncloud](https://registry.terraform.io/modules/terraform-ncloud-modules/vpc/ncloud)). The latter way is a little easier.

### `main.tf`

#### The ACG module support only multiple ACGs.
``` hcl
module "access_control_groups" {
  source = "./terraform-ncloud-acg"

  // Required
  access_control_groups = [for acg in var.access_control_groups :
    {
      name           = acg.name
      description    = acg.description
      vpc_id         = module.vpc.vpc.id   // see "vpc_id reference scenario" below
      inbound_rules  = acg.inbound_rules
      outbound_rules = acg.outbound_rules
    }
  ]
}
```

### vpc_id reference scenario

with single VPC module (terraform-ncloud-modules/vpc/ncloud)
``` hcl
//variable
# vpc_name = "vpc-sample"  (comment out)

//module
vpc_id = module.vpc.vpc.id
```

with multiple VPC module (terraform-ncloud-modules/vpc/ncloud)
``` hcl
//variable
vpc_name = "vpc-sample"

//module
vpc_id = module.vpcs[acg.vpc_name].vpc.id
```

or you can just type vpc_id manually
``` hcl
//variable
# vpc_name = "vpc-sample"  (comment out)
vpc_id = "25322"           (add new)

//module
vpc_id = acg.vpc_id
```



## Variable Declaration

### `terraform.tfvars`
You can create `terraform.tfvars` and refer to the sample below to write variable specifications.
``` hcl

// Optional, Allow multiple
// You can manage ACG within the VPC module (terraform-ncloud-modules/vpc/ncloud)
// The order of writing inbound_rules & outbound_rules is as follows.
// [protocol, ip_block|source_access_control_group, port_range, description]
access_control_groups = [
  {
    name        = string
    description = string
    vpc_name    = string   // see "vpc_id reference scenario" above
    inbound_rules = [
      [
        string,            // TCP | UDP | ICMP
        string,            // CIDR | AccessControlGroupName
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
    name        = "acg-sample-public"
    description = "ACG for public servers"
    vpc_name    = "vpc-sample"
    inbound_rules = [
      ["TCP", "0.0.0.0/0", 22, "SSH allow form any"]
    ]
    outbound_rules = [
      ["TCP", "0.0.0.0/0", "1-65535", "All allow to any"],
      ["UDP", "0.0.0.0/0", "1-65535", "All allow to any"]
    ]
  },
  {
    name        = "acg-sample-private"
    description = "ACG for private servers"
    vpc_name    = "vpc-sample"
    inbound_rules = [
      ["TCP", "acg-sample-public", 22, "SSH allow form acg-sample-public"]
    ]
    outbound_rules = [
      ["TCP", "0.0.0.0/0", "1-65535", "All allow to any"],
      ["UDP", "0.0.0.0/0", "1-65535", "All allow to any"]
    ]
  }
]


```

### `variable.tf`
You also need to create `variable.tf` to enable `terraform.tfvars`
``` hcl
variable "access_control_groups" {}
```



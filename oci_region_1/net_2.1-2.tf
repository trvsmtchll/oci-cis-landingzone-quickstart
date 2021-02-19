# Copyright (c) 2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

### This Terraform configuration creates three empty security lists.
### The security rules are driven by NSGs (Network Security Groups). See cis2_3-4.tf
### Add security rules as needed. See commented section as an example.

module "cis_security_lists" {
  source                   = "../modules/network/security"
  default_compartment_id   = module.cis_compartments.compartments[local.network_compartment_name].id
  vcn_id                   = module.cis_vcn.vcn_id
  default_security_list_id = module.cis_vcn.default_security_list_id

  security_lists = {
    (local.public_subnet_security_list_name) = {
      compartment_id = null
      defined_tags   = null
      freeform_tags  = null
      ingress_rules  = null
      #egress_rules   = null
      /*ingress_rules   = [{
        stateless     = false
        protocol      = "6"
        src           = "0.0.0.0/0"
        src_type      = "CIDR_BLOCK"
        src_port      = null
        dst_port      = {
          min = 22
          max = 22
        }
        icmp_type     = null
        icmp_code     = null
      },
      {
        stateless     = false
        protocol      = "1"
        src           = "0.0.0.0/0"
        src_type      = "CIDR_BLOCK"
        src_port      = null
        dst_port      = null
        icmp_type     = "3"
        icmp_code     = "4"
      },
      {
        stateless     = false
        protocol      = "1"
        src           = var.public_subnet_cidr
        src_type      = "CIDR_BLOCK"
        src_port      = null
        dst_port      = null
        icmp_type     = "3"
        icmp_code     = null
      },
      {
        stateless     = false
        protocol      = "all"
        src           = "10.0.0.0/8"
        src_type      = "CIDR_BLOCK"
        src_port      = null
        dst_port      = null
        icmp_type     = null
        icmp_code     = null
      },
      {
        stateless     = false
        protocol      = "all"
        src           = "172.16.0.0/12"
        src_type      = "CIDR_BLOCK"
        src_port      = null
        dst_port      = null
        icmp_type     = null
        icmp_code     = null
      },
      {
        stateless     = false
        protocol      = "all"
        src           = "192.168.0.0/16"
        src_type      = "CIDR_BLOCK"
        src_port      = null
        dst_port      = null
        icmp_type     = null
        icmp_code     = null
      }]*/
      egress_rules = [{
        stateless = false
        protocol  = "6"
        dst       = "0.0.0.0/0"
        dst_type  = "CIDR_BLOCK"
        src_port  = null
        dst_port  = null
        icmp_type = null
        icmp_code = null
      }]
    },
    (local.private_subnet_app_security_list_name) = {
      compartment_id = null
      defined_tags   = null
      freeform_tags  = null
      ingress_rules  = null
      egress_rules   = null
    },
    (local.private_subnet_db_security_list_name) = {
      is_create      = true
      compartment_id = null
      defined_tags   = null
      freeform_tags  = null
      ingress_rules  = null
      egress_rules   = null
    }
  }
}  
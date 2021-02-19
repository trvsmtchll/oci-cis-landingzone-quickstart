#####
# This main.tf file contains all of the following in one place for brevity (no impact on infrastructure):
#   net_2.1-2.tf
#   net_2.3-4.tf
#   net_2.5.tf
#   net_vcn.tf
#   oss_4.2.tf
#   mon_3.17.tf
#####

data "terraform_remote_state" "compartments" {
  backend = "s3"
  config = {
    bucket                      = "terraform-state"
    key                         = "iad-terraform.tfstate"
    region                      = "us-ashburn-1"
    endpoint                    = "https://idmnt6wveums.compat.objectstorage.us-ashburn-1.oraclecloud.com"
    shared_credentials_file     = "~/cloud-dev/oci-s3.credentials"
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    force_path_style            = true
  }
}

module "cis_vcn" {
  source               = "../modules/network/vcn"
  compartment_id       = data.terraform_remote_state.compartments.outputs.r1_compartment_objects["${var.service_label}-Network"].id
  vcn_display_name     = local.vcn_display_name
  vcn_cidr             = var.vcn_cidr
  vcn_dns_label        = var.service_label
  service_label        = var.service_label
  service_gateway_cidr = local.valid_service_gateway_cidrs[0]
  is_create_drg        = tobool(var.is_vcn_onprem_connected)

  subnets = {
    (local.public_subnet_name) = {
      compartment_id    = null
      defined_tags      = null
      freeform_tags     = null
      dynamic_cidr      = false
      cidr              = var.public_subnet_cidr
      cidr_len          = null
      cidr_num          = null
      enable_dns        = true
      dns_label         = "public"
      private           = false
      ad                = null
      dhcp_options_id   = null
      route_table_id    = module.cis_vcn.route_tables[local.public_subnet_route_table_name].id
      security_list_ids = [module.cis_security_lists.security_lists[local.public_subnet_security_list_name].id]
    },
    (local.private_subnet_app_name) = {
      compartment_id    = null
      defined_tags      = null
      freeform_tags     = null
      dynamic_cidr      = false
      cidr              = var.private_subnet_app_cidr
      cidr_len          = null
      cidr_num          = null
      enable_dns        = true
      dns_label         = "appsubnet"
      private           = true
      ad                = null
      dhcp_options_id   = null
      route_table_id    = module.cis_vcn.route_tables[local.private_subnet_app_route_table_name].id
      security_list_ids = [module.cis_security_lists.security_lists[local.private_subnet_app_security_list_name].id]
    },
    (local.private_subnet_db_name) = {
      compartment_id    = null
      defined_tags      = null
      freeform_tags     = null
      dynamic_cidr      = false
      cidr              = var.private_subnet_db_cidr
      cidr_len          = null
      cidr_num          = null
      enable_dns        = true
      dns_label         = "dbsubnet"
      private           = true
      ad                = null
      dhcp_options_id   = null
      route_table_id    = module.cis_vcn.route_tables[local.private_subnet_db_route_table_name].id
      security_list_ids = [module.cis_security_lists.security_lists[local.private_subnet_db_security_list_name].id]
    }
  }

  route_tables = {
    (local.public_subnet_route_table_name) = {
      compartment_id = null
      route_rules = [{
        is_create         = true
        destination       = local.anywhere
        destination_type  = "CIDR_BLOCK"
        network_entity_id = module.cis_vcn.internet_gateway_id
        },
        {
          is_create         = tobool(var.is_vcn_onprem_connected)
          destination       = var.onprem_cidr
          destination_type  = "CIDR_BLOCK"
          network_entity_id = module.cis_vcn.drg_id
        }
      ]
    },
    (local.private_subnet_app_route_table_name) = {
      compartment_id = null
      route_rules = [{
        is_create         = true
        destination       = local.valid_service_gateway_cidrs[0]
        destination_type  = "SERVICE_CIDR_BLOCK"
        network_entity_id = module.cis_vcn.service_gateway_id
        },
        {
          is_create         = true
          destination       = local.anywhere
          destination_type  = "CIDR_BLOCK"
          network_entity_id = module.cis_vcn.nat_gateway_id
        }
      ]
    },
    (local.private_subnet_db_route_table_name) = {
      compartment_id = null
      route_rules = [{
        is_create         = true
        destination       = local.valid_service_gateway_cidrs[0]
        destination_type  = "SERVICE_CIDR_BLOCK"
        network_entity_id = module.cis_vcn.service_gateway_id
        }
      ]
    }
  }
}


module "cis_security_lists" {
  source                   = "../modules/network/security"
  default_compartment_id   = data.terraform_remote_state.compartments.outputs.r1_compartment_objects["${var.service_label}-Network"].id
  vcn_id                   = module.cis_vcn.vcn_id
  default_security_list_id = module.cis_vcn.default_security_list_id

  security_lists = {
    (local.public_subnet_security_list_name) = {
      compartment_id = null
      defined_tags   = null
      freeform_tags  = null
      ingress_rules  = null
      egress_rules   = null
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

module "cis_nsgs" {
  source                 = "../modules/network/security"
  default_compartment_id = data.terraform_remote_state.compartments.outputs.r1_compartment_objects["${var.service_label}-Network"].id
  vcn_id                 = module.cis_vcn.vcn_id

  nsgs = {
    (local.bastion_nsg_name) = { # Bastion NSG
      compartment_id = null
      defined_tags   = null
      freeform_tags  = null
      ingress_rules = [
        {
          description = "SSH ingress rule for ${var.public_src_bastion_cidr}."
          stateless   = false
          protocol    = "6"
          src         = var.public_src_bastion_cidr
          src_type    = "CIDR_BLOCK"
          src_port    = null
          dst_port = {
            min = 22
            max = 22
          }
          icmp_code = null
          icmp_type = null
        },
        { # Bastion NSG from on-prem CIDR for SSH
          is_create   = tobool(var.is_vcn_onprem_connected)
          description = "SSH ingress rule for ${var.onprem_cidr}."
          stateless   = false
          protocol    = "6"
          src         = var.onprem_cidr
          src_type    = "CIDR_BLOCK"
          src_port    = null
          dst_port = {
            min = 22
            max = 22
          }
          icmp_code = null
          icmp_type = null
        }
      ]
      egress_rules = [
        {
          description = "SSH egress rule for ${local.app_nsg_name}."
          stateless   = false
          protocol    = "6"
          dst         = local.app_nsg_name
          dst_type    = "NSG_NAME"
          src_port    = null
          dst_port = {
            min = 22
            max = 22
          }
          icmp_code = null
          icmp_type = null
        },
        {
          description = "SSH egress rule for ${local.db_nsg_name}."
          stateless   = false
          protocol    = "6"
          dst         = local.db_nsg_name
          dst_type    = "NSG_NAME"
          src_port    = null
          dst_port = {
            min = 22
            max = 22
          }
          icmp_code = null
          icmp_type = null
        }
      ]
    },
    (local.lbr_nsg_name) = { # LBR NSG
      compartment_id = null
      defined_tags   = null
      freeform_tags  = null
      ingress_rules = [
        { # LBR NSG from external CIDR for HTTPS
          is_create   = true
          description = "HTTPS ingress rule for ${var.public_src_lbr_cidr}."
          stateless   = false
          protocol    = "6"
          src         = var.public_src_lbr_cidr
          src_type    = "CIDR_BLOCK"
          src_port    = null
          dst_port = {
            min = 443
            max = 443
          }
          icmp_code = null
          icmp_type = null
        },
        { # LBR NSG from on-prem CIDR for HTTPS
          is_create   = tobool(var.is_vcn_onprem_connected)
          description = "HTTPS ingress rule for ${var.onprem_cidr}."
          stateless   = false
          protocol    = "6"
          src         = var.onprem_cidr
          src_type    = "CIDR_BLOCK"
          src_port    = null
          dst_port = {
            min = 443
            max = 443
          }
          icmp_code = null
          icmp_type = null
        }
      ]
      egress_rules = [
        {
          description = "HTTP egress rule for ${local.app_nsg_name}."
          stateless   = false
          protocol    = "6"
          dst         = local.app_nsg_name
          dst_type    = "NSG_NAME"
          src_port    = null
          dst_port = {
            min = 80
            max = 80
          }
          icmp_code = null
          icmp_type = null
        }
      ]
    }
    (local.app_nsg_name) = { # App NSG
      compartment_id = null
      defined_tags   = null
      freeform_tags  = null
      ingress_rules = [
        {
          description = "SSH ingress rule for ${local.bastion_nsg_name}."
          stateless   = false
          protocol    = "6"
          src         = local.bastion_nsg_name
          src_type    = "NSG_NAME"
          src_port    = null
          dst_port = {
            min = 22
            max = 22
          }
          icmp_code = null
          icmp_type = null
        },
        {
          description = "HTTP ingress rule for ${local.lbr_nsg_name}."
          stateless   = false
          protocol    = "6"
          src         = local.lbr_nsg_name
          src_type    = "NSG_NAME"
          src_port    = null
          dst_port = {
            min = 80
            max = 80
          }
          icmp_code = null
          icmp_type = null
        }
      ]
      egress_rules = [
        {
          description = "DB egress rule for ${local.db_nsg_name}."
          stateless   = false
          protocol    = "6"
          dst         = local.db_nsg_name
          dst_type    = "NSG_NAME"
          src_port    = null
          dst_port = {
            min = 1521
            max = 1521
          }
          icmp_code = null
          icmp_type = null
        },
        {
          description = "OSN egress rule for ${local.valid_service_gateway_cidrs[0]}."
          stateless   = false
          protocol    = "6"
          dst         = local.valid_service_gateway_cidrs[0]
          dst_type    = "SERVICE_CIDR_BLOCK"
          src_port    = null
          dst_port = {
            min = 443
            max = 443
          }
          icmp_code = null
          icmp_type = null
        }
      ]
    },
    (local.db_nsg_name) = { # DB NSG
      compartment_id = null
      defined_tags   = null
      freeform_tags  = null
      ingress_rules = [
        {
          description = "SSH ingress rule for ${local.bastion_nsg_name}."
          stateless   = false
          protocol    = "6"
          src         = local.bastion_nsg_name
          src_type    = "NSG_NAME"
          src_port    = null
          dst_port = {
            min = 22
            max = 22
          }
          icmp_code = null
          icmp_type = null
        },
        {
          description = "DB ingress rule for ${local.app_nsg_name}."
          stateless   = false
          protocol    = "6"
          src         = local.app_nsg_name
          src_type    = "NSG_NAME"
          src_port    = null
          dst_port = {
            min = 1521
            max = 1522
          }
          icmp_code = null
          icmp_type = null
        }
      ]
      egress_rules = [
        { # DB NSG to OSN
          is_create   = true
          description = "OSN egress rule for ${local.valid_service_gateway_cidrs[0]}."
          stateless   = false
          protocol    = "6"
          dst         = local.valid_service_gateway_cidrs[0]
          dst_type    = "SERVICE_CIDR_BLOCK"
          src_port    = null
          dst_port = {
            min = 443
            max = 443
          }
          icmp_code = null
          icmp_type = null
        }
      ]
    }
  }
}

resource "oci_core_default_security_list" "default_security_list" {
  manage_default_resource_id = module.cis_vcn.default_security_list_id
  ingress_security_rules {
    protocol  = "1"
    stateless = false
    source    = local.anywhere
    icmp_options {
      type = 3
      code = 4
    }
  }
  ingress_security_rules {
    protocol  = "1"
    stateless = false
    source    = var.vcn_cidr
    icmp_options {
      type = 3
      code = null
    }
  }
}

module "cis_buckets" {
  source       = "../modules/object-storage/bucket"
  region       = var.region
  tenancy_ocid = var.tenancy_ocid
  kms_key_id   = module.cis_keys.keys[local.oss_key_name].id
  buckets = {
    "${var.service_label}-AppDevBucket" = {
      compartment_id = data.terraform_remote_state.compartments.outputs.r1_compartment_objects["${var.service_label}-AppDev"].id
    }
  }
}

locals {
  oss_bucket_logs = { for bkt in module.cis_buckets.oci_objectstorage_buckets : bkt.name => {
    log_display_name              = "${bkt.name}-ObjectStorageLog",
    log_type                      = "SERVICE",
    log_config_source_resource    = bkt.name,
    log_config_source_category    = "write",
    log_config_source_service     = "objectstorage",
    log_config_source_source_type = "OCISERVICE",
    log_config_compartment        = data.terraform_remote_state.compartments.outputs.r1_compartment_objects["${var.service_label}-Security"].id,
    log_is_enabled                = true,
    log_retention_duration        = 30,
    defined_tags                  = null,
    freeform_tags                 = null
    }
  }
}

module "cis_oss_logs" {
  source                 = "../modules/monitoring/logs"
  compartment_id         = data.terraform_remote_state.compartments.outputs.r1_compartment_objects["${var.service_label}-Security"].id
  log_group_display_name = "${var.service_label}-ObjectStorageLogGroup"
  log_group_description  = "${var.service_label} Object Storage log group."
  target_resources       = local.oss_bucket_logs
}
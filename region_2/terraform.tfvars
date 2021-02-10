# Copyright (c) 2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

##### The uncommented variable assignments below are for REQUIRED variables that do NOT have a default value in variables.tf.
##### They must be provided appropriate values.

#tenancy_ocid         = "<tenancy_ocid>"
#user_ocid            = "<tenancy_admin_ocid>"
#fingerprint          = "<tenancy_admin_api_key_fingerprint>"
#private_key_path     = "<path_to_tenancy_admin_private_key_file>"
private_key_password = ""
home_region          = "us-ashburn-1"
region               = "us-phoenix-1"
region_key           = "phx"
service_label        = "DAS"

### For Security
network_admin_email_endpoint  = "tmitchell@aviatrix.com"
security_admin_email_endpoint = "tmitchell@aviatrix.com"

### For Networking
is_vcn_onprem_connected = false
#onprem_cidr             = "192.168.1.10"
#public_src_bastion_cidr = "35.0.0.0"

vcn_cidr                = "10.10.0.0/16"
public_subnet_cidr      = "10.10.1.0/24"
private_subnet_app_cidr = "10.10.2.0/24"
private_subnet_db_cidr  = "10.10.3.0/24"
# public_src_lbr_cidr                             = "0.0.0.0/0" 

cloud_guard_configuration_status                = "DISABLED"
cloud_guard_configuration_self_manage_resources = false

##### Aviatrix Transit 
aviatrix_transit_cidr = "10.10.4.0/24"


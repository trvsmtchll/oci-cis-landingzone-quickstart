# Create an Aviatrix Oracle OCI Account
resource "aviatrix_account" "oci_account" {
  account_name                 = "CIS_OCI_Network2"
  cloud_type                   = 16
  oci_tenancy_id               = var.tenancy_ocid
  oci_user_id                  = var.user_ocid
  oci_compartment_id           = module.cis_compartments.compartment_objects["${var.service_label}-Network"].id #module.cis_vcn.vcn.compartment_id
  oci_api_private_key_filepath = var.private_key_path
}

# Create an Aviatrix Transit GW
module "aviatrix_oci_transit" {
  source  = "terraform-aviatrix-modules/oci-transit/aviatrix"
  version = "3.0.1"
  region  = var.region
  name    = var.service_label
  account = aviatrix_account.oci_account.account_name
  cidr    = var.aviatrix_transit_cidr
}

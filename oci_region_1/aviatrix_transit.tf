# Onboard Aviatrix Oracle OCI Account into Controller
resource "aviatrix_account" "oci_account" {
  account_name                 = "CIS_OCI_Network2"
  cloud_type                   = 16
  oci_tenancy_id               = var.tenancy_ocid
  oci_user_id                  = var.user_ocid
  oci_compartment_id           = module.cis_compartments.compartment_objects["${var.service_label}-Network"].id
  oci_api_private_key_filepath = var.private_key_path
}

# Create Aviatrix Transit Network and Transit Gateway
module "aviatrix_oci_transit" {
  source  = "terraform-aviatrix-modules/oci-transit/aviatrix"
  version = "3.0.1"
  region  = var.region
  name    = var.service_label
  account = aviatrix_account.oci_account.account_name
  cidr    = var.aviatrix_transit_cidr
}

# Create Aviatrix Spoke Gateway
resource "aviatrix_spoke_gateway" "oci_spoke" {
  cloud_type         = 16
  account_name       = aviatrix_account.oci_account.account_name
  gw_name            = "${var.service_label}-${var.region}-spoke"
  vpc_id             = "${var.service_label}-VCN"
  vpc_reg            = var.region
  gw_size            = "VM.Standard2.2"
  subnet             = oci_core_subnet.aviatrix_subnet.cidr_block #"10.5.1.0/24"
  enable_active_mesh = true
  transit_gw         = module.aviatrix_oci_transit.transit_gateway.gw_name
}

# Create Aviatrix Spoke Public Subnet
resource "oci_core_subnet" "aviatrix_subnet" {
  cidr_block                 = var.aviatrix_spoke_cidr
  compartment_id             = module.cis_compartments.compartment_objects["${var.service_label}-Network"].id
  vcn_id                     = module.cis_vcn.subnet_objects["${var.service_label}-Public-Subnet"].vcn_id
  display_name               = "${var.service_label}-Aviatrix-Spoke-Public-Subnet"
  dns_label                  = "aviatrix"
  prohibit_public_ip_on_vnic = false
  route_table_id             = oci_core_route_table.aviatrix_route_table.id
  security_list_ids          = [oci_core_security_list.aviatrix_security_list.id]
}

# Create RT
resource "oci_core_route_table" "aviatrix_route_table" {
  compartment_id = module.cis_compartments.compartment_objects["${var.service_label}-Network"].id
  vcn_id         = module.cis_vcn.subnet_objects["${var.service_label}-Public-Subnet"].vcn_id
  display_name   = "AviatrixSpokeRT"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = module.cis_vcn.internet_gateway_id
  }
}

# Create SL
resource "oci_core_security_list" "aviatrix_security_list" {
  compartment_id = module.cis_compartments.compartment_objects["${var.service_label}-Network"].id
  vcn_id         = module.cis_vcn.subnet_objects["${var.service_label}-Public-Subnet"].vcn_id
  display_name   = "AviatrixSpokeSL"

  // allow outbound tcp traffic on all ports
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "6"
  }

  // allow inbound ssh traffic from a specific port
  ingress_security_rules {
    protocol  = "6" // tcp
    source    = "0.0.0.0/0"
    stateless = false

    tcp_options {
      source_port_range {
        min = 22
        max = 22
      }

      // These values correspond to the destination port range.
      min = 22
      max = 22
    }
  }

  // allow inbound icmp traffic of a specific type
  ingress_security_rules {
    protocol  = 1
    source    = "0.0.0.0/0"
    stateless = false

    icmp_options {
      type = 3
      code = 4
    }
  }

  ingress_security_rules {
    protocol  = 1
    source    = var.vcn_cidr
    stateless = false

    icmp_options {
      type = 3
    }
  }

  // allow all RFC1918
  ingress_security_rules {
    protocol  = "all"
    source    = "10.0.0.0/8"
    stateless = false
  }

  ingress_security_rules {
    protocol  = "all"
    source    = "172.16.0.0/12"
    stateless = false
  }

  ingress_security_rules {
    protocol  = "all"
    source    = "192.168.0.0/16"
    stateless = false
  }
  // to allow tunnels to come up 
  ingress_security_rules {
    protocol  = "all"
    source    = "0.0.0.0/0"
    stateless = false
  }

}



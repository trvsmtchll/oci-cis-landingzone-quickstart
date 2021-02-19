output "r1_compartment_objects" {
  description = "Region 1 compartment objects"
  value       = module.cis_compartments.compartment_objects
}

output "r1_aviatrix_transit_gw" {
  description = "Region 1 Aviatrix Transit GW"
  value       = module.aviatrix_oci_transit.transit_gateway.gw_name
}

output "r1_subnet_objects" {
  description = "The managed subnet objects."
  value       = module.cis_vcn.subnet_objects
}


resource "oci_core_public_ip" "nat" {
  compartment_id = var.compartment
  display_name   = "${oci_core_vcn.main.display_name}-nat"
  lifetime       = "RESERVED"

  defined_tags = var.tags

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      defined_tags
    ]
  }
}

resource "oci_core_nat_gateway" "private" {
  compartment_id = var.compartment
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${oci_core_vcn.main.display_name}-nat"
  public_ip_id   = oci_core_public_ip.nat.id

  defined_tags = var.tags

  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}

resource "oci_core_route_table" "private" {
  compartment_id = var.compartment
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${oci_core_vcn.main.display_name}-private"

  dynamic "route_rules" {
    for_each = var.network_cidr
    content {
      network_entity_id = oci_core_drg.link.id
      description       = "Peering"
      destination       = route_rules.value
      destination_type  = "CIDR_BLOCK"
    }
  }

  route_rules {
    network_entity_id = oci_core_nat_gateway.private.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
  route_rules {
    network_entity_id = oci_core_internet_gateway.main.id
    destination       = "::/0"
    destination_type  = "CIDR_BLOCK"
  }
  route_rules {
    network_entity_id = oci_core_service_gateway.main.id
    destination       = data.oci_core_services.object_store.services[0]["cidr_block"]
    destination_type  = "SERVICE_CIDR_BLOCK"
  }

  defined_tags = var.tags

  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}


locals {
  network_cidr_v4 = cidrsubnet(try(one([for ip in var.network_cidr : ip if length(split(".", ip)) > 1]), ""), 4, var.network_shift)
  network_cidr_v6 = cidrsubnet(try(one([for ip in var.network_cidr : ip if length(split(":", ip)) > 1]), ""), 8, var.network_shift * 8)
}

resource "oci_core_vcn" "main" {
  compartment_id = var.compartment
  display_name   = var.network_name
  dns_label      = var.network_name

  cidr_blocks             = [local.network_cidr_v4]
  is_ipv6enabled          = true
  ipv6private_cidr_blocks = [local.network_cidr_v6]

  defined_tags = var.tags

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      defined_tags
    ]
  }
}

resource "oci_core_internet_gateway" "main" {
  compartment_id = var.compartment
  vcn_id         = oci_core_vcn.main.id
  display_name   = oci_core_vcn.main.display_name
  enabled        = true

  defined_tags = var.tags

  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}

resource "oci_core_service_gateway" "main" {
  compartment_id = var.compartment
  vcn_id         = oci_core_vcn.main.id
  display_name   = oci_core_vcn.main.display_name

  services {
    service_id = data.oci_core_services.object_store.services[0]["id"]
  }

  defined_tags = var.tags

  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}

resource "oci_core_route_table" "main" {
  compartment_id = var.compartment
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${oci_core_vcn.main.display_name}-main"

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
    network_entity_id = oci_core_internet_gateway.main.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
  route_rules {
    network_entity_id = oci_core_internet_gateway.main.id
    destination       = "::/0"
    destination_type  = "CIDR_BLOCK"
  }

  defined_tags = var.tags

  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}

resource "oci_core_subnet" "regional_lb" {
  cidr_block                 = cidrsubnet(cidrsubnet(oci_core_vcn.main.cidr_block, 4, 0), 2, 0)
  ipv6cidr_block             = cidrsubnet(oci_core_vcn.main.ipv6cidr_blocks[0], 8, 0)
  compartment_id             = var.compartment
  vcn_id                     = oci_core_vcn.main.id
  route_table_id             = oci_core_route_table.main.id
  prohibit_internet_ingress  = false
  prohibit_public_ip_on_vnic = false

  display_name = "${oci_core_vcn.main.display_name}-regional-lb"
  dns_label    = "lb"

  defined_tags = var.tags

  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}

resource "oci_core_subnet" "regional" {
  cidr_block                 = cidrsubnet(cidrsubnet(oci_core_vcn.main.cidr_block, 4, 0), 1, 1)
  ipv6cidr_block             = cidrsubnet(oci_core_vcn.main.ipv6cidr_blocks[0], 8, 2)
  compartment_id             = var.compartment
  vcn_id                     = oci_core_vcn.main.id
  route_table_id             = oci_core_route_table.main.id
  prohibit_internet_ingress  = false
  prohibit_public_ip_on_vnic = false

  display_name = "${oci_core_vcn.main.display_name}-regional"
  dns_label    = "regional"

  defined_tags = var.tags

  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}

resource "oci_core_subnet" "public" {
  for_each = { for idx, ad in local.zones : ad => idx }

  cidr_block                 = cidrsubnet(oci_core_vcn.main.cidr_block, 4, each.value + 1)
  ipv6cidr_block             = cidrsubnet(oci_core_vcn.main.ipv6cidr_blocks[0], 8, each.value + 10)
  compartment_id             = var.compartment
  vcn_id                     = oci_core_vcn.main.id
  route_table_id             = oci_core_route_table.main.id
  prohibit_internet_ingress  = false
  prohibit_public_ip_on_vnic = false
  availability_domain        = each.key

  display_name = "${oci_core_vcn.main.display_name}-public-${each.value + 1}"
  dns_label    = "public${each.value + 1}"

  defined_tags = var.tags

  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}

resource "oci_core_subnet" "private" {
  for_each = { for idx, ad in local.zones : ad => idx }

  cidr_block                 = cidrsubnet(oci_core_vcn.main.cidr_block, 4, each.value + 4)
  ipv6cidr_block             = cidrsubnet(oci_core_vcn.main.ipv6cidr_blocks[0], 8, each.value + 16)
  compartment_id             = var.compartment
  vcn_id                     = oci_core_vcn.main.id
  route_table_id             = oci_core_route_table.private.id
  prohibit_internet_ingress  = false
  prohibit_public_ip_on_vnic = false
  availability_domain        = each.key

  display_name = "${oci_core_vcn.main.display_name}-private-${each.value + 1}"
  dns_label    = "private${each.value + 1}"

  defined_tags = var.tags

  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}


resource "oci_core_drg" "link" {
  compartment_id = var.compartment
  display_name   = "${oci_core_vcn.main.display_name}-link"
  defined_tags   = var.tags

  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}

resource "oci_core_drg_route_distribution" "link" {
  display_name = "${oci_core_vcn.main.display_name}-link"
  defined_tags = var.tags

  drg_id            = oci_core_drg.link.id
  distribution_type = "IMPORT"

  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}

resource "oci_core_drg_route_table" "link" {
  display_name = "${oci_core_vcn.main.display_name}-link-route-table"
  defined_tags = var.tags
  drg_id       = oci_core_drg.link.id

  import_drg_route_distribution_id = oci_core_drg_route_distribution.link.id
  is_ecmp_enabled                  = true

  lifecycle {
    ignore_changes = [
      defined_tags,
    ]
  }
}

resource "oci_core_drg_attachment" "link" {
  display_name       = "${oci_core_vcn.main.display_name}-link-vcn"
  defined_tags       = var.tags
  drg_id             = oci_core_drg.link.id
  drg_route_table_id = oci_core_drg_route_table.link.id
  vcn_id             = oci_core_vcn.main.id

  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}

resource "oci_core_drg_route_distribution_statement" "link" {
  drg_route_distribution_id = oci_core_drg_route_distribution.link.id
  action                    = "ACCEPT"
  priority                  = 10

  match_criteria {
    match_type      = "DRG_ATTACHMENT_TYPE"
    attachment_type = "VCN"
  }
}

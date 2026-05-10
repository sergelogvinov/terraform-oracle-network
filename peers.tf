
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

resource "oci_core_drg_route_distribution_statement" "ipsec_tunnels" {
  drg_route_distribution_id = oci_core_drg_route_distribution.link.id
  action                    = "ACCEPT"
  priority                  = 20

  match_criteria {
    match_type      = "DRG_ATTACHMENT_TYPE"
    attachment_type = "IPSEC_TUNNEL"
  }
}

# Peer rules

locals {
  ipsec_tunnels_p2p = { for k in flatten([
    for peer, v in var.network_peering : {
      name = peer
      v4   = one([for ip in lookup(v, "p2p", []) : ip if length(split(".", ip)) > 1])
      v6   = one([for ip in lookup(v, "p2p", []) : ip if length(split(":", ip)) > 1])
    }
  ]) : k.name => k }

  ipsec_tunnels = { for k in flatten([
    for peer, v in var.network_peering : [
      for i, ip in v.ip : {
        idx     = i
        peer    = peer
        name    = "${peer}-${i}"
        secret  = lookup(v, "secret", "")
        subnets = lookup(v, "cidrs", var.network_cidr)
        pos     = lookup(v, "p2p_side", 0)

        peer_asn = lookup(v, "asn", 0)
        peer_v4  = length(split(".", ip)) > 1 ? ip : ""
        peer_v6  = length(split(":", ip)) > 1 ? ip : ""
      }
    ] if length(lookup(v, "ip", [])) > 0
  ]) : k.name => k }

  ipsec_tunnels_links = { for k in flatten([
    for link, v in local.ipsec_tunnels : [
      for i in range(2) : {
        idx    = i
        peer   = v.peer
        name   = "${link}-${i}"
        link   = link
        secret = v.secret

        peer_asn    = v.peer_asn
        peer_v4     = v.peer_v4
        peer_v6     = v.peer_v6
        peer_p2p_v4 = local.ipsec_tunnels_p2p[v.peer].v4 != null ? cidrhost(cidrsubnet(local.ipsec_tunnels_p2p[v.peer].v4, 3, v.idx), 2 * i + 1 - v.pos) : ""
        peer_p2p_v6 = local.ipsec_tunnels_p2p[v.peer].v6 != null ? cidrhost(cidrsubnet(local.ipsec_tunnels_p2p[v.peer].v6, 3, v.idx), 4 * i + 1 - v.pos) : ""

        server_p2p_v4 = local.ipsec_tunnels_p2p[v.peer].v4 != null ? cidrhost(cidrsubnet(local.ipsec_tunnels_p2p[v.peer].v4, 3, v.idx), 2 * i + v.pos) : ""
        server_p2p_v6 = local.ipsec_tunnels_p2p[v.peer].v6 != null ? cidrhost(cidrsubnet(local.ipsec_tunnels_p2p[v.peer].v6, 3, v.idx), 4 * i + v.pos) : ""
      }
    ]
  ]) : k.name => k }
}

# output "network_peering" {
#   value = local.ipsec_tunnels_links
# }

resource "oci_core_cpe" "link" {
  for_each       = local.ipsec_tunnels
  compartment_id = var.compartment
  display_name   = "${var.network_name}-link-${each.key}"
  defined_tags   = var.tags

  ip_address = each.value.peer_v4 != "" ? each.value.peer_v4 : each.value.peer_v6

  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}

resource "oci_core_ipsec" "link" {
  for_each       = local.ipsec_tunnels
  compartment_id = var.compartment
  display_name   = "${var.network_name}-link-${each.key}"
  defined_tags   = var.tags

  cpe_id        = oci_core_cpe.link[each.key].id
  drg_id        = oci_core_drg.link.id
  static_routes = each.value.subnets

  lifecycle {
    ignore_changes = [
      defined_tags,
    ]
  }
}

data "oci_core_ipsec_connection_tunnels" "link" {
  for_each = local.ipsec_tunnels
  ipsec_id = oci_core_ipsec.link[each.key].id
}

resource "oci_core_ipsec_connection_tunnel_management" "link" {
  for_each     = local.ipsec_tunnels_links
  display_name = "${var.network_name}-link-${each.key}"
  ipsec_id     = oci_core_ipsec.link[each.value.link].id
  tunnel_id    = data.oci_core_ipsec_connection_tunnels.link[each.value.link].ip_sec_connection_tunnels[each.value.idx].id

  bgp_session_info {
    customer_bgp_asn        = each.value.peer_asn > 0 ? each.value.peer_asn : null
    customer_interface_ip   = each.value.peer_p2p_v4 != "" ? "${each.value.peer_p2p_v4}/31" : null
    customer_interface_ipv6 = each.value.peer_p2p_v6 != "" ? "${each.value.peer_p2p_v6}/127" : null
    oracle_interface_ip     = each.value.server_p2p_v4 != "" ? "${each.value.server_p2p_v4}/31" : null
    oracle_interface_ipv6   = each.value.server_p2p_v6 != "" ? "${each.value.server_p2p_v6}/127" : null
  }

  routing       = each.value.peer_asn > 0 ? "BGP" : "STATIC"
  ike_version   = "V2"
  shared_secret = each.value.secret != "" ? each.value.secret : null

  phase_one_details {
    lifetime = 28800
  }
  phase_two_details {
    is_pfs_enabled = false
    lifetime       = 3600
  }
}

resource "oci_core_drg_attachment_management" "ipsec_tunnels" {
  for_each       = local.ipsec_tunnels_links
  compartment_id = var.compartment
  display_name   = "${var.network_name}-link-${each.key}"

  network_id         = oci_core_ipsec_connection_tunnel_management.link[each.key].id
  drg_id             = oci_core_drg.link.id
  drg_route_table_id = oci_core_drg_route_table.link.id
  attachment_type    = "IPSEC_TUNNEL"

  lifecycle {
    replace_triggered_by = [oci_core_ipsec_connection_tunnel_management.link[each.key].id]
  }
}


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

resource "oci_core_cpe" "link" {
  for_each       = { for name, v in var.network_peering : name => v if lookup(v, "ip", "") != "" }
  compartment_id = var.compartment
  display_name   = "${var.network_name}-link-${each.key}"
  defined_tags   = var.tags

  ip_address = each.value.ip

  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}

resource "oci_core_ipsec" "link" {
  for_each       = { for name, v in var.network_peering : name => v if lookup(v, "ip", "") != "" }
  compartment_id = var.compartment
  display_name   = "${var.network_name}-link-${each.key}"
  defined_tags   = var.tags

  cpe_id        = oci_core_cpe.link[each.key].id
  drg_id        = oci_core_drg.link.id
  static_routes = lookup(each.value, "cidrs", var.network_cidr)

  lifecycle {
    ignore_changes = [
      defined_tags,
    ]
  }
}

data "oci_core_ipsec_connection_tunnels" "link" {
  for_each = { for name, v in var.network_peering : name => v if lookup(v, "ip", "") != "" }
  ipsec_id = oci_core_ipsec.link[each.key].id
}

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
      for i in range(2) : {
        idx : i
        name : "link-${peer}-${i}"
        display_name : "${var.network_name}-link-${i}"
        ipsec  = oci_core_ipsec.link[peer].id
        tunnel = data.oci_core_ipsec_connection_tunnels.link[peer].ip_sec_connection_tunnels[i].id

        static_routes = lookup(v, "cidrs", "")
        shared_secret = lookup(v, "secret", null)

        p2p_side = lookup(v, "p2p_side", 0)
        p2p_v4   = local.ipsec_tunnels_p2p[peer].v4
        p2p_v6   = local.ipsec_tunnels_p2p[peer].v6

        server_v4     = data.oci_core_ipsec_connection_tunnels.link[peer].ip_sec_connection_tunnels[i].vpn_ip
        server_v6     = ""
        server_p2p_v4 = local.ipsec_tunnels_p2p[peer].v4 != null ? cidrhost(local.ipsec_tunnels_p2p[peer].v4, 2 * i + v.p2p_side) : ""
        server_p2p_v6 = local.ipsec_tunnels_p2p[peer].v6 != null ? cidrhost(local.ipsec_tunnels_p2p[peer].v6, 2 * i + v.p2p_side) : ""
        # server_asn    = oci_core_ipsec_connection_tunnel_management.link[k].bgp_session_info[0].oracle_bgp_asn

        peer_v4     = length(split(".", v.ip)) > 1 ? v.ip : ""
        peer_v6     = length(split(":", v.ip)) > 1 ? v.ip : ""
        peer_p2p_v4 = local.ipsec_tunnels_p2p[peer].v4 != null ? cidrhost(local.ipsec_tunnels_p2p[peer].v4, 2 * i + 1 - v.p2p_side) : ""
        peer_p2p_v6 = local.ipsec_tunnels_p2p[peer].v6 != null ? cidrhost(local.ipsec_tunnels_p2p[peer].v6, 2 * i + 1 - v.p2p_side) : ""
        peer_asn    = lookup(v, "asn", 0)
      } if try(var.capabilities.network_peer_enable, false)
    ]
  ]) : k.name => k }
}

resource "oci_core_ipsec_connection_tunnel_management" "link" {
  for_each     = local.ipsec_tunnels
  display_name = each.value.display_name

  ipsec_id  = each.value.ipsec
  tunnel_id = each.value.tunnel

  bgp_session_info {
    customer_bgp_asn        = each.value.peer_asn > 0 ? each.value.peer_asn : null
    customer_interface_ip   = each.value.peer_p2p_v4 != "" ? "${each.value.peer_p2p_v4}/31" : null
    customer_interface_ipv6 = each.value.peer_p2p_v6 != "" ? "${each.value.peer_p2p_v6}/127" : null
    oracle_interface_ip     = each.value.server_p2p_v4 != "" ? "${each.value.server_p2p_v4}/31" : null
    oracle_interface_ipv6   = each.value.server_p2p_v6 != "" ? "${each.value.server_p2p_v6}/127" : null
  }

  routing       = each.value.peer_asn > 0 ? "BGP" : "STATIC"
  ike_version   = "V2"
  shared_secret = each.value.shared_secret
}

resource "oci_core_drg_attachment_management" "ipsec_tunnels" {
  for_each       = local.ipsec_tunnels
  compartment_id = var.compartment
  display_name   = each.value.display_name

  network_id         = each.value.tunnel
  drg_id             = oci_core_drg.link.id
  drg_route_table_id = oci_core_drg_route_table.link.id
  attachment_type    = "IPSEC_TUNNEL"
}


output "regions" {
  description = "Regions"
  value       = [upper(var.region)]
}

output "network_lb" {
  description = "The load balancer network"
  value = { for idx, zone in local.zones : split(":", zone)[1] => {
    network_id = oci_core_vcn.main.id
    subnet_id  = oci_core_subnet.regional_lb.id
    cidr_v4    = oci_core_subnet.regional_lb.cidr_block
    cidr_v6    = oci_core_subnet.regional_lb.ipv6cidr_block
    gateway_v4 = oci_core_subnet.regional_lb.virtual_router_ip
    gateway_v6 = oci_core_subnet.regional_lb.ipv6virtual_router_ip
    mtu        = 1500
  } }
}

output "network_public" {
  description = "The public network"
  value = { for idx, zone in local.zones : split(":", zone)[1] => {
    network_id = oci_core_vcn.main.id
    subnet_id  = oci_core_subnet.public[zone].id
    cidr_v4    = oci_core_subnet.public[zone].cidr_block
    cidr_v6    = oci_core_subnet.public[zone].ipv6cidr_block
    gateway_v4 = oci_core_subnet.public[zone].virtual_router_ip
    gateway_v6 = oci_core_subnet.public[zone].ipv6virtual_router_ip
    mtu        = 1500
  } }
}

output "network_private" {
  description = "The private network"
  value = { for idx, zone in local.zones : split(":", zone)[1] => {
    network_id = oci_core_vcn.main.id
    subnet_id  = oci_core_subnet.private[zone].id
    cidr_v4    = oci_core_subnet.private[zone].cidr_block
    cidr_v6    = oci_core_subnet.private[zone].ipv6cidr_block
    gateway_v4 = oci_core_subnet.private[zone].virtual_router_ip
    gateway_v6 = oci_core_subnet.private[zone].ipv6virtual_router_ip
    mtu        = 1500
  } }
}

output "networks" {
  description = "Regional networks"
  value = { for idx, zone in [var.region] : upper(zone) => {
    cidr_v4 = oci_core_vcn.main.cidr_block
    cidr_v6 = oci_core_vcn.main.ipv6cidr_blocks[0]
  } }
}

output "network_nat" {
  description = "The NAT IPs"
  value = { for idx, zone in [var.region] : upper(zone) => {
    ip_v4 = oci_core_public_ip.nat.ip_address
    }
  }
}

output "network_drg" {
  description = "The DRG ids"
  value = { for idx, zone in [var.region] : upper(zone) => {
    drg             = oci_core_drg.link.id
    drg_route_table = oci_core_drg_route_table.link.id
    }
  }
}

output "network_secgroup" {
  description = "The network security groups"
  value = { for idx, zone in [var.region] : upper(zone) => {
    common       = oci_core_network_security_group.common.id
    controlplane = oci_core_network_security_group.contolplane.id
    web          = oci_core_network_security_group.web.id
    }
  }
}

output "network_peering" {
  value = { for k in flatten([
    for name, v in local.ipsec_tunnels_links : [{
      name = name
      server = {
        asn  = oci_core_ipsec_connection_tunnel_management.link[name].bgp_session_info[0].oracle_bgp_asn
        ip   = data.oci_core_ipsec_connection_tunnels.link[v.link].ip_sec_connection_tunnels[v.idx].vpn_ip
        p2p4 = v.server_p2p_v4
        p2p6 = v.server_p2p_v6
      }
      client = {
        asn  = v.peer_asn
        ip   = v.peer_v4 != "" ? v.peer_v4 : v.peer_v6
        p2p4 = v.peer_p2p_v4
        p2p6 = v.peer_p2p_v6
      }
    }]
  ]) : k.name => k }
}

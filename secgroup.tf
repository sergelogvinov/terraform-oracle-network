
resource "oci_core_default_security_list" "main" {
  compartment_id             = var.compartment
  manage_default_resource_id = oci_core_vcn.main.default_security_list_id
  display_name               = "DefaultSecurityList"

  dynamic "egress_security_rules" {
    for_each = toset(flatten([var.network_cidr, oci_core_vcn.main.ipv6cidr_blocks]))
    content {
      protocol    = length(split(".", egress_security_rules.value)) > 1 ? 1 : 58
      destination = egress_security_rules.value
      stateless   = true
    }
  }

  dynamic "egress_security_rules" {
    for_each = ["0.0.0.0/0", "::/0"]
    content {
      protocol    = "all"
      destination = egress_security_rules.value
      stateless   = false
    }
  }

  dynamic "ingress_security_rules" {
    for_each = toset(flatten([var.network_cidr, oci_core_vcn.main.ipv6cidr_blocks]))
    content {
      protocol  = length(split(".", ingress_security_rules.value)) > 1 ? 1 : 58
      source    = ingress_security_rules.value
      stateless = true
    }
  }

  dynamic "ingress_security_rules" {
    for_each = var.allowlist_datacenters
    content {
      protocol  = length(split(".", ingress_security_rules.value)) > 1 ? 1 : 58
      source    = ingress_security_rules.value
      stateless = false
    }
  }

  ingress_security_rules {
    protocol  = 1
    source    = "0.0.0.0/0"
    stateless = false
    icmp_options {
      type = 3
      code = 4
    }
  }
}

resource "oci_core_network_security_group" "common" {
  display_name   = "${var.project}-common"
  compartment_id = var.compartment
  vcn_id         = oci_core_vcn.main.id
  defined_tags   = var.tags

  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}

resource "oci_core_network_security_group_security_rule" "common_vxvlan_in" {
  for_each = toset(flatten([var.network_cidr, oci_core_vcn.main.ipv6cidr_blocks]))

  network_security_group_id = oci_core_network_security_group.common.id
  protocol                  = "17"
  direction                 = "INGRESS"
  description               = "Cilium-VxLAN"
  source                    = each.value
  stateless                 = true

  udp_options {
    destination_port_range {
      min = 8472
      max = 8472
    }
  }
}
resource "oci_core_network_security_group_security_rule" "common_vxvlan_out" {
  for_each = toset(flatten([var.network_cidr, oci_core_vcn.main.ipv6cidr_blocks]))

  network_security_group_id = oci_core_network_security_group.common.id
  protocol                  = "17"
  direction                 = "EGRESS"
  description               = "Cilium-VxLAN"
  destination               = each.value
  stateless                 = true

  udp_options {
    source_port_range {
      min = 8472
      max = 8472
    }
  }
}
resource "oci_core_network_security_group_security_rule" "common_cilium_health_check" {
  for_each = toset(flatten([var.network_cidr, oci_core_vcn.main.ipv6cidr_blocks, var.allowlist_datacenters]))

  network_security_group_id = oci_core_network_security_group.common.id
  protocol                  = "6"
  direction                 = "INGRESS"
  description               = "Cilium-HealthCheck"
  source                    = each.value
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 4240
      max = 4240
    }
  }
}
resource "oci_core_network_security_group_security_rule" "common_kubelet" {
  for_each = toset(flatten([var.network_cidr, oci_core_vcn.main.ipv6cidr_blocks]))

  network_security_group_id = oci_core_network_security_group.common.id
  protocol                  = "6"
  direction                 = "INGRESS"
  description               = "Kubelet"
  source                    = each.value
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 10250
      max = 10250
    }
  }
}
resource "oci_core_network_security_group_security_rule" "common_talos" {
  for_each = toset(flatten([var.network_cidr, oci_core_vcn.main.ipv6cidr_blocks]))

  network_security_group_id = oci_core_network_security_group.common.id
  protocol                  = "6"
  direction                 = "INGRESS"
  description               = "Talos"
  source                    = each.value
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 50000
      max = 50001
    }
  }
}

resource "oci_core_network_security_group" "contolplane_lb" {
  display_name   = "${var.project}-contolplane-lb"
  compartment_id = var.compartment
  vcn_id         = oci_core_vcn.main.id
  defined_tags   = var.tags

  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}
resource "oci_core_network_security_group_security_rule" "contolplane_lb_kubernetes" {
  for_each = toset(flatten([var.network_cidr, oci_core_vcn.main.ipv6cidr_blocks, var.allowlist_datacenters]))

  network_security_group_id = oci_core_network_security_group.contolplane_lb.id
  protocol                  = "6"
  direction                 = "INGRESS"
  source                    = each.value
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 6443
      max = 6443
    }
  }
}
resource "oci_core_network_security_group_security_rule" "contolplane_lb_talos" {
  for_each = toset(flatten([var.network_cidr, oci_core_vcn.main.ipv6cidr_blocks, var.allowlist_datacenters]))

  network_security_group_id = oci_core_network_security_group.contolplane_lb.id
  protocol                  = "6"
  direction                 = "INGRESS"
  source                    = each.value
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 50000
      max = 50001
    }
  }
}

resource "oci_core_network_security_group" "contolplane" {
  display_name   = "${var.project}-contolplane"
  compartment_id = var.compartment
  vcn_id         = oci_core_vcn.main.id
  defined_tags   = var.tags

  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}
resource "oci_core_network_security_group_security_rule" "contolplane_kubernetes" {
  for_each = toset(flatten([var.network_cidr, oci_core_vcn.main.ipv6cidr_blocks, var.allowlist_datacenters]))

  network_security_group_id = oci_core_network_security_group.contolplane.id
  protocol                  = "6"
  direction                 = "INGRESS"
  source                    = each.value
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 6443
      max = 6443
    }
  }
}
resource "oci_core_network_security_group_security_rule" "contolplane_talos" {
  for_each = toset(flatten([var.network_cidr, oci_core_vcn.main.ipv6cidr_blocks, var.allowlist_datacenters]))

  network_security_group_id = oci_core_network_security_group.contolplane.id
  protocol                  = "6"
  direction                 = "INGRESS"
  source                    = each.value
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 50000
      max = 50001
    }
  }
}
resource "oci_core_network_security_group_security_rule" "contolplane_talos_admin" {
  for_each = toset(var.allowlist_admins)

  network_security_group_id = oci_core_network_security_group.contolplane.id
  protocol                  = "6"
  direction                 = "INGRESS"
  source                    = each.value
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 50000
      max = 50000
    }
  }
}
resource "oci_core_network_security_group_security_rule" "contolplane_etcd" {
  for_each = toset(flatten([var.network_cidr, oci_core_vcn.main.ipv6cidr_blocks, var.allowlist_datacenters]))

  network_security_group_id = oci_core_network_security_group.contolplane.id
  protocol                  = "6"
  direction                 = "INGRESS"
  description               = "Etcd"
  source                    = each.value
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 2379
      max = 2380
    }
  }
}

resource "oci_core_network_security_group" "web" {
  display_name   = "${var.project}-web"
  compartment_id = var.compartment
  vcn_id         = oci_core_vcn.main.id
  defined_tags   = var.tags

  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}
resource "oci_core_network_security_group_security_rule" "web_http_lb" {
  for_each = toset([oci_core_subnet.regional_lb.cidr_block])

  network_security_group_id = oci_core_network_security_group.web.id
  protocol                  = "6"
  direction                 = "INGRESS"
  description               = "LB HealthCheck"
  source                    = each.value
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 80
      max = 80
    }
  }
}
resource "oci_core_network_security_group_security_rule" "web_https_lb" {
  for_each = toset([oci_core_subnet.regional_lb.cidr_block])

  network_security_group_id = oci_core_network_security_group.web.id
  protocol                  = "6"
  direction                 = "INGRESS"
  description               = "LB HealthCheck"
  source                    = each.value
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}
resource "oci_core_network_security_group_security_rule" "web_https" {
  for_each = toset(flatten([var.allowlist_web, var.allowlist_admins]))

  network_security_group_id = oci_core_network_security_group.web.id
  protocol                  = "6"
  direction                 = "INGRESS"
  source                    = each.value
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}

# Terraform module for Oracle Cloud Infrastructure (OCI)

## Overview

## Usage Example

```hcl
module "network" {
  source = "github.com/sergelogvinov/terraform-oracle-network"

  compartment = var.compartment_id
  project     = var.project
  region      = var.region

  network_name  = "production"
  network_cidr  = ["172.17.0.0/16", "fd60:172:17::/48"]
  network_shift = 4

  allowlist_datacenters = ["2600:1900::/28"]
  allowlist_admins      = ["1.2.3.4/32"]
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_oci"></a> [oci](#requirement\_oci) | >= 8.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_oci"></a> [oci](#provider\_oci) | >= 8.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [oci_core_cpe.link](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_cpe) | resource |
| [oci_core_default_security_list.main](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_default_security_list) | resource |
| [oci_core_drg.link](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_drg) | resource |
| [oci_core_drg_attachment.link](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_drg_attachment) | resource |
| [oci_core_drg_attachment_management.ipsec_tunnels](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_drg_attachment_management) | resource |
| [oci_core_drg_route_distribution.link](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_drg_route_distribution) | resource |
| [oci_core_drg_route_distribution_statement.ipsec_tunnels](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_drg_route_distribution_statement) | resource |
| [oci_core_drg_route_distribution_statement.link](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_drg_route_distribution_statement) | resource |
| [oci_core_drg_route_table.link](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_drg_route_table) | resource |
| [oci_core_internet_gateway.main](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_internet_gateway) | resource |
| [oci_core_ipsec.link](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_ipsec) | resource |
| [oci_core_ipsec_connection_tunnel_management.link](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_ipsec_connection_tunnel_management) | resource |
| [oci_core_nat_gateway.private](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_nat_gateway) | resource |
| [oci_core_network_security_group.common](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group) | resource |
| [oci_core_network_security_group.contolplane](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group) | resource |
| [oci_core_network_security_group.contolplane_lb](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group) | resource |
| [oci_core_network_security_group.peer](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group) | resource |
| [oci_core_network_security_group.web](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group) | resource |
| [oci_core_network_security_group_security_rule.common_cilium_health_check](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group_security_rule) | resource |
| [oci_core_network_security_group_security_rule.common_kubelet](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group_security_rule) | resource |
| [oci_core_network_security_group_security_rule.common_talos](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group_security_rule) | resource |
| [oci_core_network_security_group_security_rule.common_vxvlan_in](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group_security_rule) | resource |
| [oci_core_network_security_group_security_rule.common_vxvlan_out](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group_security_rule) | resource |
| [oci_core_network_security_group_security_rule.contolplane_etcd](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group_security_rule) | resource |
| [oci_core_network_security_group_security_rule.contolplane_kubernetes](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group_security_rule) | resource |
| [oci_core_network_security_group_security_rule.contolplane_lb_kubernetes](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group_security_rule) | resource |
| [oci_core_network_security_group_security_rule.contolplane_lb_talos](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group_security_rule) | resource |
| [oci_core_network_security_group_security_rule.contolplane_talos](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group_security_rule) | resource |
| [oci_core_network_security_group_security_rule.contolplane_talos_admin](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group_security_rule) | resource |
| [oci_core_network_security_group_security_rule.peer_ssh](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group_security_rule) | resource |
| [oci_core_network_security_group_security_rule.web_http_lb](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group_security_rule) | resource |
| [oci_core_network_security_group_security_rule.web_https](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group_security_rule) | resource |
| [oci_core_network_security_group_security_rule.web_https_lb](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group_security_rule) | resource |
| [oci_core_public_ip.nat](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_public_ip) | resource |
| [oci_core_route_table.main](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_route_table) | resource |
| [oci_core_route_table.private](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_route_table) | resource |
| [oci_core_service_gateway.main](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_service_gateway) | resource |
| [oci_core_subnet.private](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_subnet) | resource |
| [oci_core_subnet.public](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_subnet) | resource |
| [oci_core_subnet.regional](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_subnet) | resource |
| [oci_core_subnet.regional_lb](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_subnet) | resource |
| [oci_core_vcn.main](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_vcn) | resource |
| [oci_core_ipsec_connection_tunnels.link](https://registry.terraform.io/providers/oracle/oci/latest/docs/data-sources/core_ipsec_connection_tunnels) | data source |
| [oci_core_services.all_services](https://registry.terraform.io/providers/oracle/oci/latest/docs/data-sources/core_services) | data source |
| [oci_core_services.object_store](https://registry.terraform.io/providers/oracle/oci/latest/docs/data-sources/core_services) | data source |
| [oci_identity_availability_domains.main](https://registry.terraform.io/providers/oracle/oci/latest/docs/data-sources/identity_availability_domains) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allowlist_admins"></a> [allowlist\_admins](#input\_allowlist\_admins) | Allowlist for administrators | `list` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| <a name="input_allowlist_datacenters"></a> [allowlist\_datacenters](#input\_allowlist\_datacenters) | Allowlist for datacenters subnets | `list` | `[]` | no |
| <a name="input_allowlist_web"></a> [allowlist\_web](#input\_allowlist\_web) | Cloudflare subnets | `list` | <pre>[<br/>  "173.245.48.0/20",<br/>  "103.21.244.0/22",<br/>  "103.22.200.0/22",<br/>  "103.31.4.0/22",<br/>  "141.101.64.0/18",<br/>  "108.162.192.0/18",<br/>  "190.93.240.0/20",<br/>  "188.114.96.0/20",<br/>  "197.234.240.0/22",<br/>  "198.41.128.0/17",<br/>  "162.158.0.0/15",<br/>  "104.16.0.0/13",<br/>  "104.24.0.0/14",<br/>  "172.64.0.0/13",<br/>  "131.0.72.0/22"<br/>]</pre> | no |
| <a name="input_capabilities"></a> [capabilities](#input\_capabilities) | n/a | `map(any)` | <pre>{<br/>  "network_peer_enable": false<br/>}</pre> | no |
| <a name="input_compartment"></a> [compartment](#input\_compartment) | n/a | `any` | n/a | yes |
| <a name="input_network_cidr"></a> [network\_cidr](#input\_network\_cidr) | Local subnet rfc1918 | `list(string)` | <pre>[<br/>  "172.16.0.0/16",<br/>  "fd60:172:16::/48"<br/>]</pre> | no |
| <a name="input_network_name"></a> [network\_name](#input\_network\_name) | n/a | `string` | `"production"` | no |
| <a name="input_network_peering"></a> [network\_peering](#input\_network\_peering) | n/a | `map(any)` | `{}` | no |
| <a name="input_network_shift"></a> [network\_shift](#input\_network\_shift) | Network number shift | `number` | `4` | no |
| <a name="input_project"></a> [project](#input\_project) | The name of the project | `string` | `"production"` | no |
| <a name="input_region"></a> [region](#input\_region) | The OCI region where resources will be created | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Defined Tags of resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_network_drg"></a> [network\_drg](#output\_network\_drg) | The DRG ids |
| <a name="output_network_lb"></a> [network\_lb](#output\_network\_lb) | The load balancer network |
| <a name="output_network_nat"></a> [network\_nat](#output\_network\_nat) | The NAT IPs |
| <a name="output_network_peering"></a> [network\_peering](#output\_network\_peering) | n/a |
| <a name="output_network_private"></a> [network\_private](#output\_network\_private) | The private network |
| <a name="output_network_public"></a> [network\_public](#output\_network\_public) | The public network |
| <a name="output_network_secgroup"></a> [network\_secgroup](#output\_network\_secgroup) | The network security groups |
| <a name="output_networks"></a> [networks](#output\_networks) | Regional networks |
| <a name="output_regions"></a> [regions](#output\_regions) | Regions |
<!-- END_TF_DOCS -->
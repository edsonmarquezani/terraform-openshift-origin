resource "aws_route53_zone" "cluster-domain" {
  name = "${local.cluster_domain}"

  tags {
    Environment = "${var.environment}"
  }
}

resource "aws_route53_zone" "cluster-private-domain" {
  name = "${local.cluster_private_domain}"

  tags {
    Environment = "${var.environment}"
  }
}

resource "aws_route53_record" "ns-cluster-domain" {
  zone_id = "${data.aws_route53_zone.main-domain.zone_id}"
  name    = "${element(split(".",local.cluster_domain),0)}"
  type    = "NS"
  ttl     = "60"

  records = ["${aws_route53_zone.cluster-domain.name_servers.0}",
    "${aws_route53_zone.cluster-domain.name_servers.1}",
    "${aws_route53_zone.cluster-domain.name_servers.2}",
    "${aws_route53_zone.cluster-domain.name_servers.3}",
  ]
}

resource "aws_route53_record" "ns-cluster-private-domain" {
  zone_id = "${aws_route53_zone.cluster-domain.zone_id}"
  name    = "internal"
  type    = "NS"
  ttl     = "60"

  records = ["${aws_route53_zone.cluster-private-domain.name_servers.0}",
    "${aws_route53_zone.cluster-private-domain.name_servers.1}",
    "${aws_route53_zone.cluster-private-domain.name_servers.2}",
    "${aws_route53_zone.cluster-private-domain.name_servers.3}",
  ]
}

resource "aws_route53_record" "cluster-wildcard" {
  zone_id = "${aws_route53_zone.cluster-domain.zone_id}"
  name    = "*.${local.cluster_domain}"
  type    = "A"
  ttl     = "300"
  records = ["${data.azurerm_public_ip.infra-nodes.ip_address}"]
}

resource "aws_route53_record" "cluster-private-wildcard" {
  zone_id = "${aws_route53_zone.cluster-private-domain.zone_id}"
  name    = "*.${local.cluster_private_domain}"
  type    = "A"
  ttl     = "300"
  records = ["${azurerm_lb.infra-nodes-private.private_ip_address}"]
}

resource "aws_route53_record" "master" {
  zone_id = "${aws_route53_zone.cluster-domain.zone_id}"
  name    = "${local.master_address}"
  type    = "A"
  ttl     = "300"
  records = ["${azurerm_lb.master.private_ip_address}"]
}

resource "aws_route53_record" "master-public" {
  zone_id = "${aws_route53_zone.cluster-domain.zone_id}"
  name    = "${local.master_public_address}"
  type    = "A"
  ttl     = "300"
  records = ["${azurerm_lb.master.private_ip_address}"]
}

resource "aws_route53_record" "bastion" {
  zone_id = "${aws_route53_zone.cluster-domain.zone_id}"
  name    = "${azurerm_virtual_machine.bastion.name}.${local.cluster_domain}"
  type    = "A"
  ttl     = "300"
  records = ["${azurerm_network_interface.bastion-if0.private_ip_address}"]
}

resource "aws_route53_record" "master-nodes" {
  count   = "${var.master_nodes_initial_vm_count+var.master_nodes_extra_vm_count}"
  zone_id = "${aws_route53_zone.cluster-domain.zone_id}"
  name    = "${element(azurerm_virtual_machine.master-nodes.*.name,count.index)}.${local.cluster_domain}"
  type    = "A"
  ttl     = "300"
  records = ["${element(azurerm_network_interface.master-nodes-if0.*.private_ip_address,count.index)}"]
}

resource "aws_route53_record" "infra-nodes" {
  count   = "${var.infra_nodes_initial_vm_count+var.infra_nodes_extra_vm_count}"
  zone_id = "${aws_route53_zone.cluster-domain.zone_id}"
  name    = "${element(azurerm_virtual_machine.infra-nodes.*.name,count.index)}.${local.cluster_domain}"
  type    = "A"
  ttl     = "300"
  records = ["${element(azurerm_network_interface.infra-nodes-if0.*.private_ip_address,count.index)}"]
}

resource "aws_route53_record" "app-nodes" {
  count   = "${var.app_nodes_initial_vm_count+var.app_nodes_extra_vm_count}"
  zone_id = "${aws_route53_zone.cluster-domain.zone_id}"
  name    = "${element(azurerm_virtual_machine.app-nodes.*.name,count.index)}.${local.cluster_domain}"
  type    = "A"
  ttl     = "300"
  records = ["${element(azurerm_network_interface.app-nodes-if0.*.private_ip_address,count.index)}"]
}

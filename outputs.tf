output "master-nodes-private-ips" {
  value = "${azurerm_network_interface.master-nodes-if0.*.private_ip_address}"
}

output "master-nodes-fqdns" {
  value = "${aws_route53_record.master-nodes.*.fqdn}"
}

output "app-nodes-private-ips" {
  value = "${azurerm_network_interface.app-nodes-if0.*.private_ip_address}"
}

output "app-nodes-fqdns" {
  value = "${aws_route53_record.app-nodes.*.fqdn}"
}

output "infra-nodes-private-ips" {
  value = "${azurerm_network_interface.infra-nodes-if0.*.private_ip_address}"
}

output "infra-nodes-fqdns" {
  value = "${aws_route53_record.infra-nodes.*.fqdn}"
}

output "bastion-private-ip" {
  value = "${azurerm_network_interface.bastion-if0.private_ip_address}"
}

output "bastion-fqdn" {
  value = "${aws_route53_record.bastion.fqdn}"
}

output "openshift-url" {
  value = "https://${aws_route53_record.master-public.fqdn}:${var.master_port}"
}

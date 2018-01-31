data "aws_route53_zone" "main-domain" {
  name = "${var.root_domain}"
}

data "azurerm_public_ip" "infra-nodes" {
  depends_on          = ["azurerm_public_ip.infra-nodes"]
  name                = "${local.infra_nodes_lb_name_prefix}"
  resource_group_name = "${var.resource_group_name}"
}

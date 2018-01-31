##################### Master Balancer ###################

resource "azurerm_lb" "master" {
  name                = "${local.master_lb_name_prefix}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.openshift.name}"
  tags                = "${local.common_tags}"

  frontend_ip_configuration {
    name                          = "${local.master_lb_name_prefix}"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = "${var.private_subnet}"
  }
}

resource "azurerm_lb_backend_address_pool" "master" {
  resource_group_name = "${azurerm_resource_group.openshift.name}"
  loadbalancer_id     = "${azurerm_lb.master.id}"
  name                = "${local.master_lb_name_prefix}"
}

resource "azurerm_lb_rule" "master-port" {
  resource_group_name            = "${azurerm_resource_group.openshift.name}"
  loadbalancer_id                = "${azurerm_lb.master.id}"
  name                           = "port-${var.master_port}"
  protocol                       = "Tcp"
  frontend_port                  = "${var.master_port}"
  backend_port                   = "${var.master_port}"
  frontend_ip_configuration_name = "${local.master_lb_name_prefix}"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.master.id}"
  probe_id                       = "${azurerm_lb_probe.master.id}"
}

resource "azurerm_lb_probe" "master" {
  resource_group_name = "${azurerm_resource_group.openshift.name}"
  loadbalancer_id     = "${azurerm_lb.master.id}"
  name                = "${local.master_lb_name_prefix}-probe"
  port                = "${var.master_check_port}"
  protocol            = "Tcp"
}

##################### Infra Nodes Balancer ###################

resource "azurerm_public_ip" "infra-nodes" {
  name                         = "${local.infra_nodes_lb_name_prefix}"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.openshift.name}"
  public_ip_address_allocation = "static"
}

resource "azurerm_lb" "infra-nodes" {
  name                = "${local.infra_nodes_lb_name_prefix}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.openshift.name}"
  tags                = "${local.common_tags}"

  frontend_ip_configuration {
    name                 = "${local.infra_nodes_lb_name_prefix}"
    public_ip_address_id = "${azurerm_public_ip.infra-nodes.id}"
  }
}

resource "azurerm_lb_backend_address_pool" "infra-nodes" {
  resource_group_name = "${azurerm_resource_group.openshift.name}"
  loadbalancer_id     = "${azurerm_lb.infra-nodes.id}"
  name                = "${local.infra_nodes_lb_name_prefix}"
}

resource "azurerm_lb_rule" "infra-nodes-port1" {
  resource_group_name            = "${azurerm_resource_group.openshift.name}"
  loadbalancer_id                = "${azurerm_lb.infra-nodes.id}"
  name                           = "http"
  protocol                       = "Tcp"
  frontend_port                  = "80"
  backend_port                   = "${var.infra_nodes_http_port}"
  frontend_ip_configuration_name = "${local.infra_nodes_lb_name_prefix}"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.infra-nodes.id}"
  probe_id                       = "${azurerm_lb_probe.infra-nodes.id}"
}

resource "azurerm_lb_rule" "infra-nodes-port2" {
  resource_group_name            = "${azurerm_resource_group.openshift.name}"
  loadbalancer_id                = "${azurerm_lb.infra-nodes.id}"
  name                           = "https"
  protocol                       = "Tcp"
  frontend_port                  = "443"
  backend_port                   = "${var.infra_nodes_https_port}"
  frontend_ip_configuration_name = "${local.infra_nodes_lb_name_prefix}"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.infra-nodes.id}"
  probe_id                       = "${azurerm_lb_probe.infra-nodes.id}"
}

resource "azurerm_lb_probe" "infra-nodes" {
  resource_group_name = "${azurerm_resource_group.openshift.name}"
  loadbalancer_id     = "${azurerm_lb.infra-nodes.id}"
  name                = "${local.infra_nodes_lb_name_prefix}-probe"
  port                = "${var.infra_nodes_check_port}"
  protocol            = "Tcp"
}

##################### Infra Nodes Private Balancer ###################

resource "azurerm_lb" "infra-nodes-private" {
  name                = "${local.infra_nodes_lb_name_prefix}-private"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.openshift.name}"
  tags                = "${local.common_tags}"

  frontend_ip_configuration {
    name                          = "${local.infra_nodes_lb_name_prefix}-private"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = "${var.private_subnet}"
  }
}

resource "azurerm_lb_backend_address_pool" "infra-nodes-private" {
  resource_group_name = "${azurerm_resource_group.openshift.name}"
  loadbalancer_id     = "${azurerm_lb.infra-nodes-private.id}"
  name                = "${local.infra_nodes_lb_name_prefix}-private"
}

resource "azurerm_lb_rule" "infra-nodes-private-http" {
  resource_group_name            = "${azurerm_resource_group.openshift.name}"
  loadbalancer_id                = "${azurerm_lb.infra-nodes-private.id}"
  name                           = "http"
  protocol                       = "Tcp"
  frontend_port                  = "80"
  backend_port                   = "${var.infra_nodes_private_http_port}"
  frontend_ip_configuration_name = "${local.infra_nodes_lb_name_prefix}-private"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.infra-nodes-private.id}"
  probe_id                       = "${azurerm_lb_probe.infra-nodes-private.id}"
}

resource "azurerm_lb_rule" "infra-nodes-private-https" {
  resource_group_name            = "${azurerm_resource_group.openshift.name}"
  loadbalancer_id                = "${azurerm_lb.infra-nodes-private.id}"
  name                           = "https"
  protocol                       = "Tcp"
  frontend_port                  = "443"
  backend_port                   = "${var.infra_nodes_private_https_port}"
  frontend_ip_configuration_name = "${local.infra_nodes_lb_name_prefix}-private"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.infra-nodes-private.id}"
  probe_id                       = "${azurerm_lb_probe.infra-nodes-private.id}"
}

resource "azurerm_lb_probe" "infra-nodes-private" {
  resource_group_name = "${azurerm_resource_group.openshift.name}"
  loadbalancer_id     = "${azurerm_lb.infra-nodes-private.id}"
  name                = "${local.infra_nodes_lb_name_prefix}-private-probe"
  port                = "${var.infra_nodes_private_check_port}"
  protocol            = "Tcp"
}

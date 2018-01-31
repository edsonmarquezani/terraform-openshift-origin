locals {
  sg_master_out_rules = [
    {
      name                       = "allow-all"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
  ]

  sg_master_in_rules = [
    {
      name                       = "allow-ssh-1"
      protocol                   = "Tcp"
      source_port_range          = "*"
      source_address_prefix      = "10.0.0.0/8"
      destination_port_range     = "22"
      destination_address_prefix = "*"
    },
    {
      name                       = "allow-ssh-2"
      protocol                   = "Tcp"
      source_port_range          = "*"
      source_address_prefix      = "172.16.0.0/12"
      destination_port_range     = "22"
      destination_address_prefix = "*"
    },
    {
      name                       = "allow-ssh-3"
      protocol                   = "Tcp"
      source_port_range          = "*"
      source_address_prefix      = "192.168.0.0/16"
      destination_port_range     = "22"
      destination_address_prefix = "*"
    },
    {
      name                       = "allow-master-port-1"
      protocol                   = "Tcp"
      source_port_range          = "*"
      source_address_prefix      = "*"
      destination_port_range     = "${var.master_port}"
      destination_address_prefix = "*"
    },
    {
      name                       = "allow-all-internal-pods"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "${var.cluster_pods_network_cidr}"
      destination_address_prefix = "*"
    },
  ]

  sg_app_out_rules = [
    {
      name                       = "allow-all"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
  ]

  sg_app_in_rules = [
    {
      name                       = "allow-ssh-1"
      protocol                   = "Tcp"
      source_port_range          = "*"
      source_address_prefix      = "10.0.0.0/8"
      destination_port_range     = "22"
      destination_address_prefix = "*"
    },
    {
      name                       = "allow-ssh-2"
      protocol                   = "Tcp"
      source_port_range          = "*"
      source_address_prefix      = "172.16.0.0/12"
      destination_port_range     = "22"
      destination_address_prefix = "*"
    },
    {
      name                       = "allow-ssh-3"
      protocol                   = "Tcp"
      source_port_range          = "*"
      source_address_prefix      = "192.168.0.0/16"
      destination_port_range     = "22"
      destination_address_prefix = "*"
    },
    {
      name                       = "allow-all-internal-pods"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "${var.cluster_pods_network_cidr}"
      destination_address_prefix = "*"
    },
  ]

  sg_infra_out_rules = [
    {
      name                       = "allow-all"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
  ]

  sg_infra_in_rules = [
    {
      name                       = "allow-ssh-1"
      protocol                   = "Tcp"
      source_port_range          = "*"
      source_address_prefix      = "10.0.0.0/8"
      destination_port_range     = "22"
      destination_address_prefix = "*"
    },
    {
      name                       = "allow-ssh-2"
      protocol                   = "Tcp"
      source_port_range          = "*"
      source_address_prefix      = "172.16.0.0/12"
      destination_port_range     = "22"
      destination_address_prefix = "*"
    },
    {
      name                       = "allow-ssh-3"
      protocol                   = "Tcp"
      source_port_range          = "*"
      source_address_prefix      = "192.168.0.0/16"
      destination_port_range     = "22"
      destination_address_prefix = "*"
    },
    {
      name                       = "allow-http"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "${var.infra_nodes_http_port}"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      name                       = "allow-https"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "${var.infra_nodes_https_port}"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      name                       = "allow-http-private"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "${var.infra_nodes_private_http_port}"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      name                       = "allow-https-private"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "${var.infra_nodes_private_https_port}"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      name                       = "allow-all-internal-pods"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "${var.cluster_pods_network_cidr}"
      destination_address_prefix = "*"
    },
  ]
}

resource "azurerm_network_security_group" "master" {
  name                = "${local.master_nodes_name_prefix}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.openshift.name}"
  tags                = "${local.common_tags}"
}

resource "azurerm_network_security_group" "app-nodes" {
  name                = "${local.app_nodes_name_prefix}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.openshift.name}"
  tags                = "${local.common_tags}"
}

resource "azurerm_network_security_group" "infra-nodes" {
  name                = "${local.infra_nodes_name_prefix}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.openshift.name}"
  tags                = "${local.common_tags}"
}

resource "azurerm_network_security_rule" "master-out-rules" {
  count                       = "${length(local.sg_master_out_rules)}"
  name                        = "${lookup(local.sg_master_out_rules[count.index],"name")}"
  protocol                    = "${lookup(local.sg_master_out_rules[count.index],"protocol")}"
  source_port_range           = "${lookup(local.sg_master_out_rules[count.index],"source_port_range")}"
  source_address_prefix       = "${lookup(local.sg_master_out_rules[count.index],"source_address_prefix")}"
  destination_port_range      = "${lookup(local.sg_master_out_rules[count.index],"destination_port_range")}"
  destination_address_prefix  = "${lookup(local.sg_master_out_rules[count.index],"destination_address_prefix")}"
  priority                    = "${count.index+100}"
  direction                   = "Outbound"
  access                      = "Allow"
  resource_group_name         = "${azurerm_resource_group.openshift.name}"
  network_security_group_name = "${azurerm_network_security_group.master.name}"
}

resource "azurerm_network_security_rule" "master-in-rules" {
  count                       = "${length(local.sg_master_in_rules)}"
  name                        = "${lookup(local.sg_master_in_rules[count.index],"name")}"
  protocol                    = "${lookup(local.sg_master_in_rules[count.index],"protocol")}"
  source_port_range           = "${lookup(local.sg_master_in_rules[count.index],"source_port_range")}"
  source_address_prefix       = "${lookup(local.sg_master_in_rules[count.index],"source_address_prefix")}"
  destination_port_range      = "${lookup(local.sg_master_in_rules[count.index],"destination_port_range")}"
  destination_address_prefix  = "${lookup(local.sg_master_in_rules[count.index],"destination_address_prefix")}"
  access                      = "Allow"
  direction                   = "Inbound"
  priority                    = "${100+count.index}"
  resource_group_name         = "${azurerm_resource_group.openshift.name}"
  network_security_group_name = "${azurerm_network_security_group.master.name}"
}

resource "azurerm_network_security_rule" "app-nodes-out-rules" {
  count                       = "${length(local.sg_app_out_rules)}"
  name                        = "${lookup(local.sg_app_out_rules[count.index],"name")}"
  protocol                    = "${lookup(local.sg_app_out_rules[count.index],"protocol")}"
  source_port_range           = "${lookup(local.sg_app_out_rules[count.index],"source_port_range")}"
  source_address_prefix       = "${lookup(local.sg_app_out_rules[count.index],"source_address_prefix")}"
  destination_port_range      = "${lookup(local.sg_app_out_rules[count.index],"destination_port_range")}"
  destination_address_prefix  = "${lookup(local.sg_app_out_rules[count.index],"destination_address_prefix")}"
  priority                    = "${count.index+100}"
  direction                   = "Outbound"
  access                      = "Allow"
  resource_group_name         = "${azurerm_resource_group.openshift.name}"
  network_security_group_name = "${azurerm_network_security_group.app-nodes.name}"
}

resource "azurerm_network_security_rule" "app-nodes-in-rules" {
  count                       = "${length(local.sg_app_in_rules)}"
  name                        = "${lookup(local.sg_app_in_rules[count.index],"name")}"
  protocol                    = "${lookup(local.sg_app_in_rules[count.index],"protocol")}"
  source_port_range           = "${lookup(local.sg_app_in_rules[count.index],"source_port_range")}"
  source_address_prefix       = "${lookup(local.sg_app_in_rules[count.index],"source_address_prefix")}"
  destination_port_range      = "${lookup(local.sg_app_in_rules[count.index],"destination_port_range")}"
  destination_address_prefix  = "${lookup(local.sg_app_in_rules[count.index],"destination_address_prefix")}"
  access                      = "Allow"
  direction                   = "Inbound"
  priority                    = "${100+count.index}"
  resource_group_name         = "${azurerm_resource_group.openshift.name}"
  network_security_group_name = "${azurerm_network_security_group.app-nodes.name}"
}

resource "azurerm_network_security_rule" "infra-nodes-out-rules" {
  count                       = "${length(local.sg_infra_out_rules)}"
  name                        = "${lookup(local.sg_infra_out_rules[count.index],"name")}"
  protocol                    = "${lookup(local.sg_infra_out_rules[count.index],"protocol")}"
  source_port_range           = "${lookup(local.sg_infra_out_rules[count.index],"source_port_range")}"
  source_address_prefix       = "${lookup(local.sg_infra_out_rules[count.index],"source_address_prefix")}"
  destination_port_range      = "${lookup(local.sg_infra_out_rules[count.index],"destination_port_range")}"
  destination_address_prefix  = "${lookup(local.sg_infra_out_rules[count.index],"destination_address_prefix")}"
  priority                    = "${count.index+100}"
  direction                   = "Outbound"
  access                      = "Allow"
  resource_group_name         = "${azurerm_resource_group.openshift.name}"
  network_security_group_name = "${azurerm_network_security_group.infra-nodes.name}"
}

resource "azurerm_network_security_rule" "infra-nodes-in-rules" {
  count                       = "${length(local.sg_infra_in_rules)}"
  name                        = "${lookup(local.sg_infra_in_rules[count.index],"name")}"
  protocol                    = "${lookup(local.sg_infra_in_rules[count.index],"protocol")}"
  source_port_range           = "${lookup(local.sg_infra_in_rules[count.index],"source_port_range")}"
  source_address_prefix       = "${lookup(local.sg_infra_in_rules[count.index],"source_address_prefix")}"
  destination_port_range      = "${lookup(local.sg_infra_in_rules[count.index],"destination_port_range")}"
  destination_address_prefix  = "${lookup(local.sg_infra_in_rules[count.index],"destination_address_prefix")}"
  access                      = "Allow"
  direction                   = "Inbound"
  priority                    = "${100+count.index}"
  resource_group_name         = "${azurerm_resource_group.openshift.name}"
  network_security_group_name = "${azurerm_network_security_group.infra-nodes.name}"
}

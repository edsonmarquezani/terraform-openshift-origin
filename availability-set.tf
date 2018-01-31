resource "azurerm_availability_set" "master-nodes" {
  name                        = "${local.master_nodes_name_prefix}"
  location                    = "${var.location}"
  resource_group_name         = "${azurerm_resource_group.openshift.name}"
  tags                        = "${local.common_tags}"
  managed                     = true
  platform_fault_domain_count = 2
}

resource "azurerm_availability_set" "infra-nodes" {
  name                        = "${local.infra_nodes_name_prefix}"
  location                    = "${var.location}"
  resource_group_name         = "${azurerm_resource_group.openshift.name}"
  tags                        = "${local.common_tags}"
  managed                     = true
  platform_fault_domain_count = 2
}

resource "azurerm_availability_set" "app-nodes" {
  name                        = "${local.app_nodes_name_prefix}"
  location                    = "${var.location}"
  resource_group_name         = "${azurerm_resource_group.openshift.name}"
  tags                        = "${local.common_tags}"
  managed                     = true
  platform_fault_domain_count = 2
}

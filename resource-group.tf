resource "azurerm_resource_group" "openshift" {
  name     = "${var.resource_group_name}"
  location = "${var.location}"
  tags     = "${local.common_tags}"
}

resource "azurerm_storage_account" "registry" {
  name                     = "${substr(sha256(var.root_domain),0,24)}"
  resource_group_name      = "${azurerm_resource_group.openshift.name}"
  location                 = "${var.location}"
  account_replication_type = "LRS"
  account_tier             = "Standard"
  tags                     = "${local.common_tags}"
}

resource "azurerm_storage_container" "registry" {
  name                  = "registry"
  resource_group_name   = "${azurerm_resource_group.openshift.name}"
  storage_account_name  = "${azurerm_storage_account.registry.name}"
  container_access_type = "private"
}

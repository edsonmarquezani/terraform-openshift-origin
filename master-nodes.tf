resource "azurerm_network_interface" "master-nodes-if0" {
  depends_on = ["azurerm_network_security_rule.master-out-rules",
    "azurerm_network_security_rule.master-in-rules",
  ]

  count                     = "${var.master_nodes_initial_vm_count + var.master_nodes_extra_vm_count}"
  name                      = "${local.master_nodes_name_prefix}-${count.index+1}-if0"
  location                  = "${var.location}"
  resource_group_name       = "${azurerm_resource_group.openshift.name}"
  network_security_group_id = "${azurerm_network_security_group.master.id}"

  ip_configuration {
    name                                    = "${local.master_nodes_name_prefix}-if0-${count.index+1}"
    subnet_id                               = "${var.private_subnet}"
    private_ip_address_allocation           = "dynamic"
    load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.master.id}"]
  }
}

resource "azurerm_managed_disk" "master-nodes-docker" {
  count                = "${var.master_nodes_initial_vm_count + var.master_nodes_extra_vm_count}"
  name                 = "${local.master_nodes_name_prefix}-${count.index+1}-docker"
  location             = "${azurerm_resource_group.openshift.location}"
  resource_group_name  = "${azurerm_resource_group.openshift.name}"
  storage_account_type = "${var.master_nodes_disk_type}"
  create_option        = "Empty"
  disk_size_gb         = "${var.master_nodes_docker_disk_size}"
}

resource "azurerm_virtual_machine" "master-nodes" {
  count                 = "${var.master_nodes_initial_vm_count + var.master_nodes_extra_vm_count}"
  name                  = "${local.master_nodes_name_prefix}-${count.index+1}"
  location              = "${azurerm_resource_group.openshift.location}"
  resource_group_name   = "${azurerm_resource_group.openshift.name}"
  network_interface_ids = ["${element(azurerm_network_interface.master-nodes-if0.*.id, count.index)}"]
  vm_size               = "${var.master_nodes_vm_type}"
  tags                  = "${local.common_tags}"
  availability_set_id   = "${azurerm_availability_set.master-nodes.id}"

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  os_profile {
    computer_name  = "${local.master_nodes_name_prefix}-${count.index+1}"
    admin_username = "${var.admin_user}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.admin_user}/.ssh/authorized_keys"
      key_data = "${var.ssh_public_key}"
    }
  }

  storage_image_reference {
    publisher = "${var.ami_pulisher}"
    offer     = "${var.ami_offer}"
    sku       = "${var.ami_sku}"
    version   = "${var.ami_version}"
  }

  storage_os_disk {
    name              = "${local.master_nodes_name_prefix}-${count.index+1}-root"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "${var.master_nodes_disk_type}"
  }

  storage_data_disk {
    name            = "${element(azurerm_managed_disk.master-nodes-docker.*.name,count.index)}"
    managed_disk_id = "${element(azurerm_managed_disk.master-nodes-docker.*.id, count.index)}"
    disk_size_gb    = "${var.master_nodes_docker_disk_size}"
    caching         = "ReadWrite"
    create_option   = "Attach"
    lun             = 0
  }

  lifecycle {
    ignore_changes = ["storage_os_disk", "storage_data_disk"]
  }
}

resource "azurerm_network_interface" "bastion-if0" {
  name                = "${local.bastion_name_prefix}-if0"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.openshift.name}"

  ip_configuration {
    name                          = "${local.bastion_name_prefix}-if0-${count.index+1}"
    subnet_id                     = "${var.private_subnet}"
    private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_virtual_machine" "bastion" {
  name                  = "${local.bastion_name_prefix}"
  location              = "${azurerm_resource_group.openshift.location}"
  resource_group_name   = "${azurerm_resource_group.openshift.name}"
  network_interface_ids = ["${azurerm_network_interface.bastion-if0.id}"]
  vm_size               = "${var.bastion_vm_type}"
  tags                  = "${local.common_tags}"

  delete_os_disk_on_termination = true

  os_profile {
    computer_name  = "${local.bastion_name_prefix}-${count.index+1}"
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
    name              = "${local.bastion_name_prefix}-root"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
}

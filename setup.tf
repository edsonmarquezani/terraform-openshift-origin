locals {
  setup_files_path = "/tmp/setup-files"
}

data "template_file" "azure-conf" {
  template = "${file("${path.module}/files/configs/azure.conf.tpl")}"

  vars {
    tenant_id         = "${var.azure_tenant_id}"
    subscription_id   = "${var.azure_subscription_id}"
    aad_client_id     = "${var.azure_aad_client_id}"
    aad_client_secret = "${var.azure_aad_client_secret}"
    aad_tenant_id     = "${var.azure_aad_tenant_id}"
    resource_group    = "${azurerm_resource_group.openshift.name}"
    location          = "${var.location_compact}"
  }
}

data "template_file" "add-node" {
  template = "${file("${path.module}/files/scripts/add-node.sh.tpl")}"

  vars {
    automation_username        = "${var.automation_username}"
    master_nodes_name_prefix   = "${local.master_nodes_name_prefix}"
    openshift_playbook_version = "${var.openshift_playbook_version}"
    router_replica_count       = "${var.infra_nodes_initial_vm_count+var.infra_nodes_extra_vm_count}"
    master_address             = "${local.master_address}"
    openshift_admin_username   = "${var.openshift_admin_username}"
    openshift_admin_passwd     = "${var.openshift_admin_passwd}"
  }
}

data "template_file" "setup-openshift" {
  template = "${file("${path.module}/files/scripts/setup-openshift.sh.tpl")}"

  vars {
    automation_username        = "${var.automation_username}"
    openshift_admin_username   = "${var.openshift_admin_username}"
    openshift_admin_passwd     = "${var.openshift_admin_passwd}"
    master_nodes_name_prefix   = "${local.master_nodes_name_prefix}"
    registry_account_name      = "${azurerm_storage_account.registry.name}"
    registry_account_key       = "${azurerm_storage_account.registry.primary_access_key}"
    cluster_private_domain     = "${local.cluster_private_domain}"
    deploy_logging             = "${var.deploy_logging}"
    deploy_metrics             = "${var.deploy_metrics}"
    router_replica_count       = "${var.infra_nodes_initial_vm_count}"
    openshift_playbook_version = "${var.openshift_playbook_version}"
    master_address             = "${local.master_address}"
    openshift_admin_username   = "${var.openshift_admin_username}"
    openshift_admin_passwd     = "${var.openshift_admin_passwd}"
  }
}

data "template_file" "setup-common" {
  template = "${file("${path.module}/files/scripts/setup-common.sh.tpl")}"

  vars {
    automation_username = "${var.automation_username}"
    admin_user          = "${var.admin_user}"
  }
}

data "template_file" "inventory-initial" {
  template = "${file("${path.module}/files/configs/inventory.ini.tpl")}"

  vars {
    automation_username = "${var.automation_username}"

    # Hostname/domain attributes
    master_address         = "${local.master_address}"
    master_public_address  = "${local.master_public_address}"
    master_api_url         = "https://${local.master_address}:${var.master_port}"
    cluster_domain         = "${local.cluster_domain}"
    cluster_private_domain = "${local.cluster_private_domain}"

    # Network attributes
    cluster_pods_network_cidr    = "${var.cluster_pods_network_cidr}"
    cluster_service_network_cidr = "${var.cluster_service_network_cidr}"

    # Node groups name prefixes
    master_nodes_name_prefix = "${local.master_nodes_name_prefix}"
    app_nodes_name_prefix    = "${local.app_nodes_name_prefix}"
    infra_nodes_name_prefix  = "${local.infra_nodes_name_prefix}"

    # Node groups extra attributes
    master_ansible_options      = "${var.master_ansible_options}"
    app_nodes_ansible_options   = "${var.app_nodes_ansible_options}"
    infra_nodes_ansible_options = "${var.infra_nodes_ansible_options}"

    # Misc attributes
    resource_group = "${var.resource_group_name}"

    # Instance counts for initial setup
    master_nodes_initial_vm_count = "${var.master_nodes_initial_vm_count}"
    app_nodes_initial_vm_count    = "${var.app_nodes_initial_vm_count}"
    infra_nodes_initial_vm_count  = "${var.infra_nodes_initial_vm_count}"
    router_replica_count          = "${var.infra_nodes_initial_vm_count}"
    registry_replica_count        = "${var.infra_nodes_initial_vm_count > 1 ? 2 : 1}"

    # Data disks (convert bytes to Gbytes)
    logs_disk_size    = "${var.logging_data_disk_size/1073741824}"
    metrics_disk_size = "${var.metrics_data_disk_size/1073741824}"

    # Initial setup doesn't have extra nodes, by definition
    new_app_nodes   = ""
    new_infra_nodes = ""
    new_masters     = ""
  }
}

data "template_file" "inventory-extra-app-nodes" {
  template = "${file("${path.module}/files/configs/inventory.ini.tpl")}"
  count    = "${var.app_nodes_extra_vm_count}"

  vars {
    automation_username = "${var.automation_username}"

    # Hostname/domain attributes
    master_address         = "${local.master_address}"
    master_public_address  = "${local.master_public_address}"
    master_api_url         = "https://${local.master_address}:${var.master_port}"
    cluster_domain         = "${local.cluster_domain}"
    cluster_private_domain = "${local.cluster_private_domain}"

    # Network attributes
    cluster_pods_network_cidr    = "${var.cluster_pods_network_cidr}"
    cluster_service_network_cidr = "${var.cluster_service_network_cidr}"

    # Node groups name prefixes
    master_nodes_name_prefix = "${local.master_nodes_name_prefix}"
    app_nodes_name_prefix    = "${local.app_nodes_name_prefix}"
    infra_nodes_name_prefix  = "${local.infra_nodes_name_prefix}"

    # Node groups extra attributes
    master_ansible_options      = "${var.master_ansible_options}"
    app_nodes_ansible_options   = "${var.app_nodes_ansible_options}"
    infra_nodes_ansible_options = "${var.infra_nodes_ansible_options}"

    # Misc attributes
    resource_group = "${var.resource_group_name}"

    # Instance counts for initial setup
    master_nodes_initial_vm_count = "${var.master_nodes_initial_vm_count}"
    app_nodes_initial_vm_count    = "${var.app_nodes_initial_vm_count}"
    infra_nodes_initial_vm_count  = "${var.infra_nodes_initial_vm_count}"
    router_replica_count          = "${var.infra_nodes_initial_vm_count}"
    registry_replica_count        = "${var.infra_nodes_initial_vm_count > 1 ? 2 : 1}"

    # Data disks (convert bytes to Gbytes)
    logs_disk_size    = "${var.logging_data_disk_size/1073741824}"
    metrics_disk_size = "${var.metrics_data_disk_size/1073741824}"

    # Add extra app nodes only
    new_app_nodes   = "${element(azurerm_virtual_machine.app-nodes.*.name,var.app_nodes_initial_vm_count+count.index)} ${var.app_nodes_ansible_options}"
    new_infra_nodes = ""
    new_masters     = ""
  }
}

data "template_file" "inventory-extra-infra-nodes" {
  template = "${file("${path.module}/files/configs/inventory.ini.tpl")}"
  count    = "${var.infra_nodes_extra_vm_count}"

  vars {
    automation_username = "${var.automation_username}"

    # Hostname/domain attributes
    master_address         = "${local.master_address}"
    master_public_address  = "${local.master_public_address}"
    master_api_url         = "https://${local.master_address}:${var.master_port}"
    cluster_domain         = "${local.cluster_domain}"
    cluster_private_domain = "${local.cluster_private_domain}"

    # Network attributes
    cluster_pods_network_cidr    = "${var.cluster_pods_network_cidr}"
    cluster_service_network_cidr = "${var.cluster_service_network_cidr}"

    # Node groups name prefixes
    master_nodes_name_prefix = "${local.master_nodes_name_prefix}"
    app_nodes_name_prefix    = "${local.app_nodes_name_prefix}"
    infra_nodes_name_prefix  = "${local.infra_nodes_name_prefix}"

    # Node groups extra attributes
    master_ansible_options      = "${var.master_ansible_options}"
    app_nodes_ansible_options   = "${var.app_nodes_ansible_options}"
    infra_nodes_ansible_options = "${var.infra_nodes_ansible_options}"

    # Misc attributes
    resource_group = "${var.resource_group_name}"

    # Instance counts for initial setup
    master_nodes_initial_vm_count = "${var.master_nodes_initial_vm_count}"
    app_nodes_initial_vm_count    = "${var.app_nodes_initial_vm_count}"
    infra_nodes_initial_vm_count  = "${var.infra_nodes_initial_vm_count}"
    router_replica_count          = "${var.infra_nodes_initial_vm_count}"
    registry_replica_count        = "${var.infra_nodes_initial_vm_count > 1 ? 2 : 1}"

    # Data disks (convert bytes to Gbytes)
    logs_disk_size    = "${var.logging_data_disk_size/1073741824}"
    metrics_disk_size = "${var.metrics_data_disk_size/1073741824}"

    # Add new infra nodes only
    new_infra_nodes = "${element(azurerm_virtual_machine.infra-nodes.*.name,var.infra_nodes_initial_vm_count+count.index)} ${var.infra_nodes_ansible_options}"
    new_app_nodes   = ""
    new_masters     = ""
  }
}

data "template_file" "inventory-extra-master-nodes" {
  template = "${file("${path.module}/files/configs/inventory.ini.tpl")}"
  count    = "${var.master_nodes_extra_vm_count}"

  vars {
    automation_username = "${var.automation_username}"

    # Hostname/domain attributes
    master_address         = "${local.master_address}"
    master_public_address  = "${local.master_public_address}"
    master_api_url         = "https://${local.master_address}:${var.master_port}"
    cluster_domain         = "${local.cluster_domain}"
    cluster_private_domain = "${local.cluster_private_domain}"

    # Network attributes
    cluster_pods_network_cidr    = "${var.cluster_pods_network_cidr}"
    cluster_service_network_cidr = "${var.cluster_service_network_cidr}"

    # Node groups name prefixes
    master_nodes_name_prefix = "${local.master_nodes_name_prefix}"
    app_nodes_name_prefix    = "${local.app_nodes_name_prefix}"
    infra_nodes_name_prefix  = "${local.infra_nodes_name_prefix}"

    # Node groups extra attributes
    master_ansible_options      = "${var.master_ansible_options}"
    app_nodes_ansible_options   = "${var.app_nodes_ansible_options}"
    infra_nodes_ansible_options = "${var.infra_nodes_ansible_options}"

    # Misc attributes
    resource_group = "${var.resource_group_name}"

    # Instance counts for initial setup
    master_nodes_initial_vm_count = "${var.master_nodes_initial_vm_count}"
    app_nodes_initial_vm_count    = "${var.app_nodes_initial_vm_count}"
    infra_nodes_initial_vm_count  = "${var.infra_nodes_initial_vm_count}"
    router_replica_count          = "${var.infra_nodes_initial_vm_count}"
    registry_replica_count        = "${var.infra_nodes_initial_vm_count > 1 ? 2 : 1}"

    # Data disks (convert bytes to Gbytes)
    logs_disk_size    = "${var.logging_data_disk_size/1073741824}"
    metrics_disk_size = "${var.metrics_data_disk_size/1073741824}"

    # Add extra masters only
    new_masters     = "${element(azurerm_virtual_machine.master-nodes.*.name,var.master_nodes_initial_vm_count+count.index)} ${var.master_ansible_options}"
    new_infra_nodes = ""
    new_app_nodes   = ""
  }
}

resource "null_resource" "setup-bastion" {
  connection {
    host = "${azurerm_network_interface.bastion-if0.private_ip_address}"
    user = "${var.admin_user}"
  }

  provisioner "file" {
    source      = "${path.module}/files"
    destination = "${local.setup_files_path}"
  }

  provisioner "remote-exec" {
    inline = ["rm -rf /tmp/setup-files"]
  }
}

resource "null_resource" "setup-masters" {
  count = "${var.master_nodes_initial_vm_count+var.master_nodes_extra_vm_count}"

  connection {
    host = "${element(azurerm_network_interface.master-nodes-if0.*.private_ip_address,count.index)}"
    user = "${var.admin_user}"
  }

  provisioner "file" {
    source      = "${path.module}/files"
    destination = "${local.setup_files_path}"
  }

  provisioner "file" {
    content     = "${data.template_file.setup-common.rendered}"
    destination = "${local.setup_files_path}/scripts/setup-common.sh"
  }

  provisioner "remote-exec" {
    inline = ["sudo bash -x ${local.setup_files_path}/scripts/setup-common.sh"]
  }
}

resource "null_resource" "setup-infra-nodes" {
  count = "${var.infra_nodes_initial_vm_count+var.infra_nodes_extra_vm_count}"

  connection {
    host = "${element(azurerm_network_interface.infra-nodes-if0.*.private_ip_address,count.index)}"
    user = "${var.admin_user}"
  }

  provisioner "file" {
    source      = "${path.module}/files"
    destination = "${local.setup_files_path}"
  }

  provisioner "file" {
    content     = "${data.template_file.setup-common.rendered}"
    destination = "${local.setup_files_path}/scripts/setup-common.sh"
  }

  provisioner "remote-exec" {
    inline = ["sudo bash -x ${local.setup_files_path}/scripts/setup-common.sh"]
  }
}

resource "null_resource" "setup-app-nodes" {
  count = "${var.app_nodes_initial_vm_count+var.app_nodes_extra_vm_count}"

  connection {
    host = "${element(azurerm_network_interface.app-nodes-if0.*.private_ip_address,count.index)}"
    user = "${var.admin_user}"
  }

  provisioner "file" {
    source      = "${path.module}/files"
    destination = "${local.setup_files_path}"
  }

  provisioner "file" {
    content     = "${data.template_file.setup-common.rendered}"
    destination = "${local.setup_files_path}/scripts/setup-common.sh"
  }

  provisioner "remote-exec" {
    inline = ["sudo bash -x ${local.setup_files_path}/scripts/setup-common.sh"]
  }
}

resource "null_resource" "setup-openshift-files" {
  depends_on = ["null_resource.setup-bastion"]

  connection {
    host = "${azurerm_network_interface.bastion-if0.private_ip_address}"
    user = "${var.admin_user}"
  }

  provisioner "file" {
    source      = "${path.module}/files"
    destination = "${local.setup_files_path}"
  }

  provisioner "file" {
    content     = "${data.template_file.azure-conf.rendered}"
    destination = "${local.setup_files_path}/configs/azure.conf"
  }

  provisioner "file" {
    content     = "${data.template_file.inventory-initial.rendered}"
    destination = "${local.setup_files_path}/configs/inventory.ini"
  }

  provisioner "file" {
    content     = "${data.template_file.setup-openshift.rendered}"
    destination = "${local.setup_files_path}/scripts/setup-openshift.sh"
  }
}

resource "null_resource" "setup-openshift" {
  depends_on = ["null_resource.setup-masters",
    "null_resource.setup-infra-nodes",
    "null_resource.setup-app-nodes",
    "null_resource.setup-openshift-files",
  ]

  connection {
    host = "${azurerm_network_interface.bastion-if0.private_ip_address}"
    user = "${var.admin_user}"
  }

  provisioner "remote-exec" {
    inline = "bash -x ${local.setup_files_path}/scripts/setup-openshift.sh"
  }
}

resource "null_resource" "add-new-master-nodes" {
  depends_on = ["null_resource.setup-openshift",
    "null_resource.setup-masters",
  ]

  count = "${var.master_nodes_extra_vm_count}"

  connection {
    host = "${azurerm_network_interface.bastion-if0.private_ip_address}"
    user = "${var.admin_user}"
  }

  provisioner "file" {
    source      = "${path.module}/files"
    destination = "${local.setup_files_path}-${element(azurerm_virtual_machine.master-nodes.*.name,var.master_nodes_initial_vm_count+count.index)}"
  }

  provisioner "file" {
    content     = "${element(data.template_file.inventory-extra-master-nodes.*.rendered,count.index)}"
    destination = "${local.setup_files_path}-${element(azurerm_virtual_machine.master-nodes.*.name,var.master_nodes_initial_vm_count+count.index)}/configs/inventory.ini"
  }

  provisioner "file" {
    content     = "${data.template_file.azure-conf.rendered}"
    destination = "${local.setup_files_path}-${element(azurerm_virtual_machine.master-nodes.*.name,var.master_nodes_initial_vm_count+count.index)}/configs/azure.conf"
  }

  provisioner "file" {
    content     = "${data.template_file.add-node.rendered}"
    destination = "${local.setup_files_path}-${element(azurerm_virtual_machine.master-nodes.*.name,var.master_nodes_initial_vm_count+count.index)}/scripts/add-node.sh"
  }

  provisioner "remote-exec" {
    inline = "bash -x ${local.setup_files_path}-${element(azurerm_virtual_machine.master-nodes.*.name,var.master_nodes_initial_vm_count+count.index)}/scripts/add-node.sh ${element(azurerm_virtual_machine.master-nodes.*.name,var.master_nodes_initial_vm_count+count.index)} master"
  }
}

resource "null_resource" "add-new-infra-nodes" {
  depends_on = ["null_resource.setup-infra-nodes",
    "null_resource.setup-openshift",
  ]

  count = "${var.infra_nodes_extra_vm_count}"

  connection {
    host = "${azurerm_network_interface.bastion-if0.private_ip_address}"
    user = "${var.admin_user}"
  }

  provisioner "file" {
    source      = "${path.module}/files"
    destination = "${local.setup_files_path}-${element(azurerm_virtual_machine.infra-nodes.*.name,var.infra_nodes_initial_vm_count+count.index)}"
  }

  provisioner "file" {
    content     = "${element(data.template_file.inventory-extra-infra-nodes.*.rendered,count.index)}"
    destination = "${local.setup_files_path}-${element(azurerm_virtual_machine.infra-nodes.*.name,var.infra_nodes_initial_vm_count+count.index)}/configs/inventory.ini"
  }

  provisioner "file" {
    content     = "${data.template_file.azure-conf.rendered}"
    destination = "${local.setup_files_path}-${element(azurerm_virtual_machine.infra-nodes.*.name,var.infra_nodes_initial_vm_count+count.index)}/configs/azure.conf"
  }

  provisioner "file" {
    content     = "${data.template_file.add-node.rendered}"
    destination = "${local.setup_files_path}-${element(azurerm_virtual_machine.infra-nodes.*.name,var.infra_nodes_initial_vm_count+count.index)}/scripts/add-node.sh"
  }

  provisioner "remote-exec" {
    inline = "bash -x ${local.setup_files_path}-${element(azurerm_virtual_machine.infra-nodes.*.name,var.infra_nodes_initial_vm_count+count.index)}/scripts/add-node.sh ${element(azurerm_virtual_machine.infra-nodes.*.name,var.infra_nodes_initial_vm_count+count.index)} infra"
  }
}

resource "null_resource" "add-new-app-nodes" {
  depends_on = ["null_resource.setup-openshift",
    "null_resource.setup-app-nodes",
  ]

  count = "${var.app_nodes_extra_vm_count}"

  connection {
    host = "${azurerm_network_interface.bastion-if0.private_ip_address}"
    user = "${var.admin_user}"
  }

  provisioner "file" {
    source      = "${path.module}/files"
    destination = "${local.setup_files_path}-${element(azurerm_virtual_machine.app-nodes.*.name,var.app_nodes_initial_vm_count+count.index)}"
  }

  provisioner "file" {
    content     = "${element(data.template_file.inventory-extra-app-nodes.*.rendered,count.index)}"
    destination = "${local.setup_files_path}-${element(azurerm_virtual_machine.app-nodes.*.name,var.app_nodes_initial_vm_count+count.index)}/configs/inventory.ini"
  }

  provisioner "file" {
    content     = "${data.template_file.azure-conf.rendered}"
    destination = "${local.setup_files_path}-${element(azurerm_virtual_machine.app-nodes.*.name,var.app_nodes_initial_vm_count+count.index)}/configs/azure.conf"
  }

  provisioner "file" {
    content     = "${data.template_file.add-node.rendered}"
    destination = "${local.setup_files_path}-${element(azurerm_virtual_machine.app-nodes.*.name,var.app_nodes_initial_vm_count+count.index)}/scripts/add-node.sh"
  }

  provisioner "remote-exec" {
    inline = "bash -x ${local.setup_files_path}-${element(azurerm_virtual_machine.app-nodes.*.name,var.app_nodes_initial_vm_count+count.index)}/scripts/add-node.sh ${element(azurerm_virtual_machine.app-nodes.*.name,var.app_nodes_initial_vm_count+count.index)}"
  }
}

# Any instance setup will force the private key to be removed from bastion
# afterwards
resource "null_resource" "remove-key" {
  depends_on = ["null_resource.setup-openshift",
    "null_resource.add-new-master-nodes",
    "null_resource.add-new-infra-nodes",
    "null_resource.add-new-app-nodes",
  ]

  count = "${var.master_nodes_initial_vm_count +
                  var.master_nodes_extra_vm_count +
                  var.app_nodes_extra_vm_count +
                  var.app_nodes_initial_vm_count +
                  var.infra_nodes_extra_vm_count +
                  var.infra_nodes_initial_vm_count
                }"

  connection {
    host = "${azurerm_network_interface.bastion-if0.private_ip_address}"
    user = "${var.admin_user}"
  }

  provisioner "remote-exec" {
    inline = "rm -fv .ssh/id_rsa"
  }
}

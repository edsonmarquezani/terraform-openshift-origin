################### Common variables ###################

variable "environment" {
  default = "openshift-origin"
}

variable "location" {
  default = "East US"
}

variable "location_compact" {
  default = "eastus"
}

variable "automation_username" {
  default = "automation"
}

variable "deploy_metrics" {
  default = "false"
}

variable "deploy_logging" {
  default = "false"
}

variable "resource_group_name" {
  default = "openshift"
}

locals {
  common_tags = {
    environment = "${var.environment}"
  }
}

################## Network Variables ##################

variable "private_subnet" {
  default = ""
}

variable "public_subnet" {
  default = ""
}

variable "private_subnet_cidr" {
  default = "10.0.0.0/16"
}

# Get image information via az cli as documented here:
# https://docs.microsoft.com/en-us/azure/virtual-machines/linux/cli-ps-findimage
# az vm image list --offer RHEL --sku 7 --output table

variable "ami_pulisher" {
  default = "OpenLogic"
}

variable "ami_offer" {
  default = "CentOS"
}

variable "ami_sku" {
  default = "7.4"
}

variable "ami_version" {
  default = "latest"
}

variable "admin_user" {
  default = "centos"
}

variable "ssh_public_key" {
  default = ""
}

################ Openshift Parameters ################

variable "openshift_playbook_version" {
  default = "3.7.25-1"
}

variable "root_domain" {
  default = "foo.bar"
}

variable "cluster_domain" {
  default = "origin.foo.bar"
}

variable "cluster_private_domain" {
  default = "origin.foo.bar"
}

variable "cluster_pods_network_cidr" {
  default = "10.0.0.0/16"
}

variable "cluster_service_network_cidr" {
  default = "172.30.0.0/16"
}

variable "openshift_admin_username" {
  default = "admin"
}

variable "openshift_admin_passwd" {
  default = "admin"
}

locals {
  cluster_domain         = "${var.cluster_domain != "" ? var.cluster_domain : format("ose%s.%s", var.environment, var.root_domain)}"
  cluster_private_domain = "${var.cluster_private_domain != "" ? var.cluster_private_domain : format("internal.ose%s.%s", var.environment, var.root_domain)}"
  master_address         = "master.${local.cluster_domain}"
  master_public_address  = "console.${local.cluster_domain}"
}

############### Master nodes variables ###############

variable "master_nodes_initial_vm_count" {
  default = "1"
}

variable "master_nodes_extra_vm_count" {
  default = "0"
}

variable "master_nodes_vm_type" {
  default = "Standard_DS1_v2"
}

variable "master_port" {
  default = "8443"
}

variable "master_check_port" {
  default = "8443"
}

variable "master_nodes_docker_disk_size" {
  default = "32"
}

variable "master_nodes_os_disk_size" {
  default = "10"
}

variable "master_nodes_disk_type" {
  default = "Premium_LRS"
}

variable "master_ansible_options" {
  default = "openshift_node_labels=\"{'role':'master','zone':'default','logging':'true'}\" openshift_schedulable=false"
}

locals {
  master_nodes_name_prefix = "openshift-${var.environment}-master"
  master_lb_name_prefix    = "lb-openshift-${var.environment}-master"
}

############### Infra nodes variables ###############

variable "infra_nodes_initial_vm_count" {
  default = "1"
}

variable "infra_nodes_extra_vm_count" {
  default = "0"
}

variable "infra_nodes_vm_type" {
  default = "Standard_DS3_v2"
}

variable "infra_nodes_http_port" {
  default = "80"
}

variable "infra_nodes_https_port" {
  default = "443"
}

variable "infra_nodes_private_http_port" {
  default = "81"
}

variable "infra_nodes_private_https_port" {
  default = "444"
}

variable "infra_nodes_check_port" {
  default = "80"
}

variable "infra_nodes_private_check_port" {
  default = "81"
}

variable "infra_nodes_docker_disk_size" {
  default = "32"
}

variable "infra_nodes_os_disk_size" {
  default = "10"
}

variable "infra_nodes_disk_type" {
  default = "Premium_LRS"
}

variable "infra_nodes_ansible_options" {
  default = "openshift_node_labels=\"{'role':'infra','zone':'default','logging':'true'}\""
}

locals {
  infra_nodes_name_prefix    = "openshift-${var.environment}-infra"
  infra_nodes_lb_name_prefix = "lb-openshift-${var.environment}-infra"
}

############### App nodes variables ###############
variable "app_nodes_initial_vm_count" {
  default = "1"
}

variable "app_nodes_extra_vm_count" {
  default = "0"
}

variable "app_nodes_vm_type" {
  default = "Standard_DS1_v2"
}

variable "app_nodes_docker_disk_size" {
  default = "32"
}

variable "app_nodes_os_disk_size" {
  default = "10"
}

variable "app_nodes_disk_type" {
  default = "Premium_LRS"
}

variable "app_nodes_ansible_options" {
  default = "openshift_node_labels=\"{'role':'app','zone':'default','logging':'true'}\""
}

locals {
  app_nodes_name_prefix = "openshift-${var.environment}-node"
}

############### Bastion variables ###############

variable "bastion_vm_type" {
  default = "Standard_DS1_v2"
}

variable "bastion_os_disk_size" {
  default = "10"
}

locals {
  bastion_name_prefix = "openshift-${var.environment}-bastion"
}

##################### Disks ######################

variable "metrics_data_disk_size" {
  default = "68719476736"
}

variable "logging_data_disk_size" {
  default = "68719476736"
}

variable "common_data_disk_size" {
  default = "68719476736"
}

################# Azure Credentials ##############
variable "azure_tenant_id" {
  default = ""
}

variable "azure_subscription_id" {
  default = ""
}

variable "azure_aad_client_id" {
  default = ""
}

variable "azure_aad_client_secret" {
  default = ""
}

variable "azure_aad_tenant_id" {
  default = ""
}

[OSEv3:children]
masters
nodes
etcd
new_nodes
new_masters

[OSEv3:vars]

# Deploy/Ansible options
ansible_become=yes
ansible_ssh_user=${automation_username}
openshift_deployment_type=origin
openshift_release=v3.7
openshift_install_examples=true
openshift_disable_check=memory_availability,disk_availability
openshift_enable_service_catalog=false

# Cluster general attributes
openshift_rolling_restart_mode=services
debug_level=2
docker_udev_workaround=True
openshift_master_access_token_max_seconds=2419200
openshift_hosted_router_replicas=${router_replica_count}
openshift_hosted_registry_replicas=${registry_replica_count}
openshift_override_hostname_check=true
osm_use_cockpit=false
openshift_router_selector='role=infra'
openshift_registry_selector='role=infra'
osm_default_node_selector='role=app'
openshift_ca_cert_expire_days=3650
openshift_node_cert_expire_days=3650
openshift_master_cert_expire_days=3650
etcd_ca_default_days=3650
openshift_node_kubelet_args={'enable-controller-attach-detach': ['true'], 'minimum-container-ttl-duration': ['60s'], 'maximum-dead-containers-per-container': ['2'], 'maximum-dead-containers': ['50'], 'image-gc-high-threshold': ['75'], 'image-gc-low-threshold': ['70'] }
azure_resource_group=${resource_group}
openshift_cloudprovider_kind=azure

# Authentication attributes
openshift_master_identity_providers=[{'name': 'Local', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider', 'filename': '/etc/origin/master/htpasswd'}]
openshift_master_manage_htpasswd=false

# Hostname/domain attributes
openshift_master_cluster_hostname=${master_address}
openshift_master_cluster_public_hostname=${master_public_address}
openshift_master_api_url=${master_api_url}
openshift_node_master_api_url=${master_api_url}
openshift_master_default_subdomain=${cluster_domain}
osm_default_subdomain=${cluster_domain}

# Network attributes
osm_cluster_network_cidr=${cluster_pods_network_cidr}
openshift_portal_net=${cluster_service_network_cidr}
osm_host_subnet_length=9
os_sdn_network_plugin_name=redhat/openshift-ovs-multitenant
openshift_use_openshift_sdn=true
openshift_use_dnsmasq=True

# Metrics settings
openshift_metrics_image_version=v3.7
openshift_metrics_install_metrics=false
openshift_metrics_cassandra_storage_type=dynamic
openshift_metrics_cassandra_pvc_size="${metrics_disk_size}G"
openshift_metrics_cassandra_replicas="1"
openshift_metrics_hawkular_nodeselector={"role":"infra"}
openshift_metrics_cassandra_nodeselector={"role":"infra"}
openshift_metrics_heapster_nodeselector={"role":"infra"}
openshift_metrics_duration=90
openshift_metrics_hawkular_hostname=metrics.${cluster_private_domain}

# Logging settings
openshift_logging_image_version=v3.7
openshift_logging_elasticsearch_proxy_image_version=v1.1.0
openshift_logging_install_logging=false
openshift_logging_es_pvc_dynamic=true
openshift_logging_es_pvc_size="${logs_disk_size}G"
openshift_logging_es_cluster_size=1
openshift_logging_fluentd_nodeselector={"logging":"true"}
openshift_logging_es_nodeselector={"role":"infra"}
openshift_logging_kibana_nodeselector={"role":"infra"}
openshift_logging_curator_nodeselector={"role":"infra"}
openshift_logging_use_ops=false
openshift_logging_purge_logging=false
openshift_logging_kibana_hostname=logs.${cluster_private_domain}
openshift_logging_master_url=${master_api_url}
openshift_logging_master_public_url=${master_api_url}
openshift_logging_curator_default_days=60
openshift_logging_es_pvc_storage_class_name=standard
openshift_logging_es_memory_limit=2G

[masters]
${master_nodes_name_prefix}-[1:${master_nodes_initial_vm_count}] ${master_ansible_options}

[etcd]
${master_nodes_name_prefix}-[1:${master_nodes_initial_vm_count}] ${master_ansible_options}

[infra_nodes]
${infra_nodes_name_prefix}-[1:${infra_nodes_initial_vm_count}] ${infra_nodes_ansible_options}

[nodes]
${master_nodes_name_prefix}-[1:${master_nodes_initial_vm_count}] ${master_ansible_options}
${infra_nodes_name_prefix}-[1:${infra_nodes_initial_vm_count}] ${infra_nodes_ansible_options}
${app_nodes_name_prefix}-[1:${app_nodes_initial_vm_count}] ${app_nodes_ansible_options}

[new_nodes]
${new_app_nodes}
${new_infra_nodes}
${new_masters}

[new_masters]
${new_masters}

#!/bin/bash
# Sets up Openshift with help of Ansible Official Module
set -o pipefail
export ANSIBLE_HOST_KEY_CHECKING=false
export PLAYBOOKS_VERSION=${openshift_playbook_version}
export PLAYBOOKS_PATH="/usr/share/ansible/openshift-ansible"

# Setting up private key
mkdir .ssh
cp /tmp/setup-files/keys/privatekey .ssh/id_rsa
echo "StrictHostKeyChecking no" >> .ssh/config
chmod 400 .ssh/*

# Installing Jq
echo "- Installing JQ ..."
sudo curl -sL https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 -o /usr/local/bin/jq && sudo chmod 755 /usr/local/bin/jq

echo "- Installing Ansible and Openshift modules ..."
sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo sed -i -e "s/^enabled=1/enabled=0/" /etc/yum.repos.d/epel.repo
sudo yum -y --enablerepo=epel install ansible pyOpenSSL
sudo yum install -y wget net-tools bind-utils python-passlib httpd-tools iptables-services bridge-utils bash-completion kexec-tools sos psacct java-1.8.0-openjdk-headless
ansible-playbook -b /tmp/setup-files/scripts/setup-ansible-cfg.yml

cp /tmp/setup-files/configs/inventory.ini .
ansible-inventory -i inventory.ini --list  | jq -r '.nodes.hosts[]' > hosts
sudo cp hosts /etc/ansible/hosts

ansible-playbook -b -i inventory.ini -l masters -u ${automation_username} /tmp/setup-files/scripts/add-master-host.yml -e master_address=${master_address} || exit 1

# Download Ansible Openshift module
sudo mkdir -p $${PLAYBOOKS_PATH}
curl -sL  https://github.com/openshift/openshift-ansible/archive/openshift-ansible-$${PLAYBOOKS_VERSION}.tar.gz -o openshift-ansible.tar.gz && sudo tar -xzvf openshift-ansible.tar.gz -C $${PLAYBOOKS_PATH} --strip-components 1

# Main automation
echo "- Running main automation ..."
ansible-playbook -b -i inventory.ini $${PLAYBOOKS_PATH}/playbooks/byo/config.yml | tee ansible.log || exit 1

# Adding network domain removed by DNSMasq
echo "- Adding domain on network configuration of all hosts ..."
domain=$$(hostname -d)
ansible -b -i inventory.ini all -m shell -a "nmcli con modify eth0 ipv4.dns-search $${domain} && systemctl restart NetworkManager" || exit 1

# Workaround for BZ1469358
echo "- Fixing master certificates after setup ..."
ansible ${master_nodes_name_prefix}-1 -b -u ${automation_username} -m fetch -a "src=/etc/origin/master/ca.serial.txt dest=/tmp/ca.serial.txt flat=true" || exit 1
ansible -b -i inventory.ini masters -m copy -a "src=/tmp/ca.serial.txt dest=/etc/origin/master/ca.serial.txt mode=0644 owner=root" || exit 1

echo "- Setting local admin user ..."
ansible -b -i inventory.ini masters -m shell -a "htpasswd -b /etc/origin/master/htpasswd ${openshift_admin_username} '${openshift_admin_passwd}'" || exit 1
ansible ${master_nodes_name_prefix}-1 -b -u ${automation_username} -m shell -a 'oadm policy add-cluster-role-to-user cluster-admin ${openshift_admin_username}' || exit 1

########################## Configuring cloud-provider Azure ##########################

# Setting up Azure config
echo "- Setting up Azure config on all nodes ..."
ansible -b -i inventory.ini all -m file -a 'path=/etc/azure state=directory mode=0755 owner=root' || exit 1
ansible -b -i inventory.ini all -m copy -a "src=/tmp/setup-files/configs/azure.conf dest=/etc/azure/azure.conf mode=0400 owner=root" || exit 1

echo "- Configuring cloud-provider Azure on masters ..."
ansible-playbook -b -i inventory.ini -l masters -u ${automation_username} /tmp/setup-files/scripts/setup-azure-master.yml || exit 1

echo "- Configuring cloud-provider Azure on nodes ..."
ansible-playbook -b -i inventory.ini -u ${automation_username} /tmp/setup-files/scripts/setup-azure-nodes.yml || exit 1

ansible -i inventory.ini -b all -u ${automation_username} -m systemd -a 'name=openvswitch state=restarted' || exit 1
sleep 20

ansible -i inventory.ini -b all -u ${automation_username} -m systemd -a 'name=origin-node state=restarted' || exit 1
sleep 180

ansible -b -i inventory.ini -u ${automation_username} masters -m shell -a 'oadm manage-node {{inventory_hostname}} --schedulable=false' || exit 1

echo "- Setting up Kubernetes additional resources .."
ansible ${master_nodes_name_prefix}-1 -b -u ${automation_username} -m copy -a 'src=/tmp/setup-files/configs/kubernetes dest=/tmp mode=0644' || exit 1
ansible ${master_nodes_name_prefix}-1 -b -u ${automation_username} -m shell -a "oc create -f /tmp/kubernetes/storageclass.yaml" || exit 1

echo "- Modifying registry configs ..."
ansible ${master_nodes_name_prefix}-1 -b -u ${automation_username} -m shell -a "oc env dc docker-registry -e REGISTRY_STORAGE=azure -e REGISTRY_STORAGE_AZURE_ACCOUNTNAME=${registry_account_name} -e REGISTRY_STORAGE_AZURE_ACCOUNTKEY=${registry_account_key} -e REGISTRY_STORAGE_AZURE_CONTAINER=registry && oc patch dc registry-console -p '{\"spec\":{\"template\":{\"spec\":{\"nodeSelector\":{\"role\":\"infra\"}}}}}'" || exit 1

ansible ${master_nodes_name_prefix}-1 -b -u ${automation_username} -m copy -a 'src=/tmp/setup-files/scripts/create-private-router.sh dest=/tmp/create-private-router.sh mode=0755' || exit 1
ansible ${master_nodes_name_prefix}-1 -b -u ${automation_username} -m shell -a 'bash -x /tmp/create-private-router.sh ${router_replica_count}' || exit 1

ansible -i inventory.ini infra_nodes -b -u ${automation_username} -m copy -a 'src=/tmp/setup-files/scripts/allow-private-route-ports.sh dest=/tmp/allow-private-route-ports.sh mode=0755' || exit 1
ansible -i inventory.ini infra_nodes -b -u ${automation_username} -m shell -a 'bash -x /tmp/allow-private-route-ports.sh' || exit 1

if [ "${deploy_metrics}" == "true" -o "${deploy_metrics}" == "1" ]; then
  echo "- Deploying cluster metrics ..."
  ansible-playbook -b -i inventory.ini $${PLAYBOOKS_PATH}/playbooks/byo/openshift-cluster/openshift-metrics.yml -e openshift_metrics_install_metrics=true | tee ansible-metrics.logs || exit 1
  ansible ${master_nodes_name_prefix}-1 -b -u ${automation_username} -m shell -a "oc delete route hawkular-metrics --namespace=openshift-infra" || exit 1
  ansible ${master_nodes_name_prefix}-1 -b -u ${automation_username} -m shell -a "oc create route passthrough --service=hawkular-metrics --hostname=metrics.${cluster_private_domain} --namespace=openshift-infra" || exit 1
  ansible ${master_nodes_name_prefix}-1 -b -u ${automation_username} -m shell -a "oc label route --namespace=openshift-infra hawkular-metrics router=private --overwrite" || exit 1
fi

if [ "${deploy_logging}" == "true" -o "${deploy_logging}" == "1" ]; then
  echo "- Deploying logging..."
  ansible-playbook -b -i inventory.ini $${PLAYBOOKS_PATH}/playbooks/byo/openshift-cluster/openshift-logging.yml -e openshift_logging_install_logging=true | tee ansible-logging.logs || exit 1
  ansible ${master_nodes_name_prefix}-1 -b -u ${automation_username} -m shell -a "oc label route --namespace=logging logging-kibana router=private --overwrite" || exit 1
fi

ansible -i inventory.ini all -b -u ${automation_username} -m shell -a 'rm -f .ssh/authorized_keys'

rm -rf /tmp/setup-files/{configs,keys}

echo "Done!"

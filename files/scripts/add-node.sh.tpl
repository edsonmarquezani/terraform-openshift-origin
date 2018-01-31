#!/bin/bash
set -o pipefail
HOST=$${1}
NODE_TYPE=$${2}
export ANSIBLE_HOST_KEY_CHECKING=false
export PLAYBOOKS_VERSION=${openshift_playbook_version}

cd /tmp/setup-files-$${HOST}

# Setting up private key
if [ ! -d $${HOME}/.ssh ]; then
  mkdir $${HOME}/.ssh
fi

if [ ! -e $${HOME}/.ssh/id_rsa ]; then
  cp /tmp/setup-files-$${HOST}/keys/privatekey $${HOME}/.ssh/id_rsa
  chmod 400 $${HOME}/.ssh/id_rsa
fi

echo $${HOST} > hosts

# Download Ansible Openshift module
rm -rf ansible
mkdir ansible
curl -sL  https://github.com/openshift/openshift-ansible/archive/openshift-ansible-$${PLAYBOOKS_VERSION}.tar.gz -o openshift-ansible.tar.gz && tar -xzf openshift-ansible.tar.gz -C ansible --strip-components 1

if [ "$${NODE_TYPE}" == "master" ]; then
  ansible -b -i hosts $${HOST} -u ${automation_username} -m shell -a "htpasswd -b /etc/origin/master/htpasswd ${openshift_admin_username} '${openshift_admin_passwd}'"
  ansible -b -i hosts $${HOST} -u ${automation_username} -m shell -a 'oadm policy add-cluster-role-to-user cluster-admin ${openshift_admin_username}'
  ansible-playbook -b -i hosts -u ${automation_username} scripts/add-master-host.yml -e master_address=${master_address} || exit 1
  ansible ${master_nodes_name_prefix}-1 -b -u ${automation_username} -m fetch -a "src=/etc/origin/master/ca.serial.txt dest=/tmp/ca.serial.txt flat=true" || exit 1
  ansible -b -i hosts $${HOST} -u ${automation_username} -m file -a 'path=/etc/origin/master state=directory mode=0755 owner=root' || exit 1
  ansible -b -i hosts $${HOST} -u ${automation_username} -m copy -a "src=/tmp/ca.serial.txt dest=/etc/origin/master/ca.serial.txt mode=0644 owner=root" || exit 1
  ansible-playbook -b -i configs/inventory.ini ansible/playbooks/byo/openshift-master/scaleup.yml | tee ansible.log || exit 1
else
  ansible-playbook -b -i configs/inventory.ini ansible/playbooks/byo/openshift-node/scaleup.yml | tee ansible.log || exit 1
fi

# Adding network domain removed by DNSMasq
echo "- Adding domain on network configuration of all hosts..."
domain=$$(hostname -d)
ansible $${HOST} -b -i hosts -u ${automation_username} -m shell -a "nmcli con modify eth0 ipv4.dns-search $${domain} && systemctl restart NetworkManager" || exit 1

echo "- Configuring cloud-provider Azure on nodes ..."
# Setting up Azure config
ansible -b -i hosts $${HOST} -u ${automation_username} -m file -a 'path=/etc/azure state=directory mode=0755 owner=root' || exit 1
ansible -b -i hosts $${HOST} -u ${automation_username} -m copy -a "src=configs/azure.conf dest=/etc/azure/azure.conf mode=0400 owner=root" || exit 1

ansible-playbook -b -i hosts -u ${automation_username} scripts/setup-azure-nodes.yml || exit 1

ansible -b -i hosts $${HOST} -u ${automation_username} -m systemd -a 'name=openvswitch state=restarted' || exit 1
sleep 20
ansible -b -i hosts $${HOST} -u ${automation_username} -m systemd -a 'name=origin-node state=restarted' || exit 1

if [ "$${NODE_TYPE}" == "master" ]; then
  ansible-playbook -b -i hosts -u ${automation_username} scripts/setup-azure-master.yml || exit 1
  sleep 180
  ansible -b -i hosts all -u ${automation_username} -m shell -a 'oadm manage-node {{ inventory_hostname }} --schedulable=false' || exit 1
fi

if [ "$${NODE_TYPE}" == "infra" ]; then
  ansible -b -i hosts all -u ${automation_username} -m copy -a 'src=scripts/allow-private-route-ports.sh dest=/tmp/allow-private-route-ports.sh mode=0755' || exit 1
  ansible -b -i hosts all -u ${automation_username} -m shell -a 'bash -x /tmp/allow-private-route-ports.sh' || exit 1

  echo "Scaling routers ..."
  ansible -i configs/inventory.ini ${master_nodes_name_prefix}-1 -b -u ${automation_username} -m shell -a "oc scale dc/router --replicas=${router_replica_count}" || exit 1
  ansible -i configs/inventory.ini ${master_nodes_name_prefix}-1 -b -u ${automation_username} -m shell -a "oc scale dc/private-router --replicas=${router_replica_count}" || exit 1
fi

ansible -b -i hosts all -b -u ${automation_username} -m shell -a 'rm -f .ssh/authorized_keys'
rm -rf /tmp/setup-files-$${HOST}

echo "Done!"

#!/bin/bash

adduser ${automation_username}
echo "${automation_username} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/automation
chmod 440 /etc/sudoers.d/automation

mkdir /home/${automation_username}/.ssh
cp /tmp/setup-files/keys/publickey /home/${automation_username}/.ssh/authorized_keys
chown ${automation_username}: /home/${automation_username}/.ssh -R

swapoff -a

sed -i 's/NM_CONTROLLED=no/NM_CONTROLLED=yes/g' /etc/sysconfig/network-scripts/ifcfg-*
systemctl restart network

# Install packages
yum update -y

yum install -y docker-1.12.6 samba-client samba-commons cifs-utils httpd-tools wget net-tools bind-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct

# In order to use Azure File persistent storage
# Ref: https://docs.openshift.com/container-platform/3.6/install_config/persistent_storage/persistent_storage_azure_file.html
setsebool virt_use_samba on

# Setup docker
usermod -aG dockerroot ${admin_user}

# Setup docker Devmapper
if [ ! -e /var/lib/docker/devicemapper ]; then
  device=$$(ls -l /dev/disk/azure/scsi1/lun0 | awk '{print $$NF}' | grep -Eo 'sd[a-z]')
  cat > /etc/sysconfig/docker-storage-setup <<EOF
DEVS=/dev/$${device}
CONTAINER_ROOT_LV_NAME=dockerlv
CONTAINER_ROOT_LV_SIZE=100%FREE
CONTAINER_ROOT_LV_MOUNT_PATH=/var/lib/docker
VG=dockervg
EOF
  docker-storage-setup && systemctl restart docker
  systemctl enable docker
fi

rm -rf /tmp/setup-files

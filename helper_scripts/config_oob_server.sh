#!/bin/bash

#This file is transferred to a Debian/Ubuntu Host and executed to re-map interfaces
#Extra config COULD be added here but I would recommend against that to keep this file standard.
echo "#################################"
echo "  Running OOB server config"
echo "#################################"
sudo su

#Replace existing network interfaces file
echo -e "auto lo" > /etc/network/interfaces
echo -e "iface lo inet loopback\n\n" >> /etc/network/interfaces
echo -e  "source /etc/network/interfaces.d/*.cfg\n" >> /etc/network/interfaces

#Add vagrant interface
echo -e "\n\nauto eth0" >> /etc/network/interfaces
echo -e "iface eth0 inet dhcp\n\n" >> /etc/network/interfaces

####### Custom Stuff
echo "auto swp1" >> /etc/network/interfaces
echo "iface swp1 inet static" >> /etc/network/interfaces
echo "    address 192.168.0.254" >> /etc/network/interfaces
echo "    netmask 255.255.255.0" >> /etc/network/interfaces

echo "cumulus ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/10_cumulus


ifup swp1
sed "s/PasswordAuthentication no/PasswordAuthentication yes/" -i /etc/ssh/sshd_config
service ssh restart

echo " ### Pushing Ansible Hosts File ###"
mkdir -p /etc/ansible
cat << EOT > /etc/ansible/hosts
[oob-switch]
oob-mgmt-switch ansible_host=192.168.0.1 ansible_user=cumulus

[exit]
exit02 ansible_host=192.168.0.42 ansible_user=cumulus
exit01 ansible_host=192.168.0.41 ansible_user=cumulus

[leaf]
leaf04 ansible_host=192.168.0.14 ansible_user=cumulus
leaf02 ansible_host=192.168.0.12 ansible_user=cumulus
leaf03 ansible_host=192.168.0.13 ansible_user=cumulus
leaf01 ansible_host=192.168.0.11 ansible_user=cumulus

[spine]
spine02 ansible_host=192.168.0.22 ansible_user=cumulus
spine01 ansible_host=192.168.0.21 ansible_user=cumulus

[host]
edge01 ansible_host=192.168.0.51 ansible_user=cumulus
server01 ansible_host=192.168.0.31 ansible_user=cumulus
server03 ansible_host=192.168.0.33 ansible_user=cumulus
server02 ansible_host=192.168.0.32 ansible_user=cumulus
server04 ansible_host=192.168.0.34 ansible_user=cumulus

EOT

echo " ### Pushing Ansible Configuration ###"
cat << EOT > /etc/ansible/ansible.cfg
[defaults]
library = /usr/share/ansible
# only use in lab settings. Reference:
# http://docs.ansible.com/intro_getting_started.html#host-key-checking
host_key_checking=False
callback_whitelist = profile_tasks
retry_files_enabled = False
EOT


echo "#################################"
echo "   Finished"
echo "#################################"

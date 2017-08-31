#!/bin/sh
sudo sh -c 'echo "deb http://httpredir.debian.org/debian jessie main" > /etc/apt/sources.list.d/jessie.list'
sudo sh -c 'echo "deb http://ftp.debian.org/debian jessie-backports main" >> /etc/apt/sources.list.d/jessie.list'
sudo sh -c 'echo "deb http://repo3.cumulusnetworks.com/repo Jessie-supplemental upstream" > /etc/apt/sources.list.d/jessie_cl.list'
sudo apt-get update
sudo apt-get install -yq git python-netaddr sshpass
sudo apt-get install -yq -t jessie-backports ansible
git clone https://github.com/cumulusnetworks/cldemo-provision-ts.git

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

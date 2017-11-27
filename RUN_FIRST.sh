#!/usr/bin/env bash

wget -P /etc/ansible/ https://raw.githubusercontent.com/CumulusNetworks/cldemo-netq/citc/hosts
wget -P /etc/ansible/ https://raw.githubusercontent.com/CumulusNetworks/cldemo-netq/citc/ansible.cfg

su -c 'ansible network -a "net add vrf mgmt"' - cumulus
su -c 'ansible network -a "net commit"' - cumulus

git init
git clone -b citc https://github.com/CumulusNetworks/cldemo-netq.git

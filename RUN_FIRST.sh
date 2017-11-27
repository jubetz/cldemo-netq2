#!/usr/bin/env bash

wget -P /etc/ansible/ https://raw.githubusercontent.com/CumulusNetworks/cldemo-netq/citc/hosts

ansible network -a "net add vrf mgmt"
ansible network -a "net commit"

git init
git clone -b citc https://github.com/CumulusNetworks/cldemo-netq.git

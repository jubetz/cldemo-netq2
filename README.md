# Cumulus NetQ Demo

This demo will install Cumulus Linux [NetQ](https://docs.cumulusnetworks.com/display/DOCS/Using+netq+to+Troubleshoot+the+Network) Fabric Validation System using the Cumulus [reference topology](https://github.com/cumulusnetworks/cldemo-vagrant). Please visit the reference topology github page for detailed instructions on using Cumulus Vx with Vagrant.


![Cumulus Reference Topology](https://raw.githubusercontent.com/CumulusNetworks/cldemo-vagrant/master/documentation/cldemo_topology.png)

_Don't want to run it locally? You can also run this demo in [Cumulus In the Cloud](https://cumulusnetworks.com/try-for-free/)_


Table of Contents
=================
* [Prerequisites](#prerequisites)
* [Using Virtualbox](#using-virtualbox)
* [Using Libvirt KVM](#using-libvirtkvm)
* [Running the Demo](#running-the-demo)
    * [EVPN Demo](#evpn-demo)
    * [Docker Swarm   Routing on the Host Demo](#docker-swarm--routing-on-the-host-demo)
* [Troubleshooting + FAQ](#troubleshooting--faq)


Prerequisites
------------------------
* Running this simulation roughly 10G of RAM.
* Internet connectivity is required from the hypervisor. Multiple packages are installed on both the switches and servers when the lab is created.
* Download this repository locally with `git clone https://github.com/CumulusNetworks/cldemo-netq.git` or if you do not have Git installed, [Download the zip file](https://github.com/CumulusNetworks/cldemo-netq/archive/master.zip)
* Download the NetQ Telemetry Server from https://cumulusnetworks.com/downloads/#product=NetQ%20Virtual&version=1.1. You need to be logged into the site to access this.
* Install [Vagrant](https://releases.hashicorp.com/vagrant/). Use release [1.9.5](https://releases.hashicorp.com/vagrant/1.9.5/).
* Install [Virtualbox](https://www.virtualbox.org/wiki/VirtualBox) or [Libvirt+KVM](https://libvirt.org/drvqemu.html) hypervisors.

Using Virtualbox
------------------------
* Add the downloaded box to vagrant via: `vagrant box add cumulus-netq-telemetry-server-amd64-1.1.0-vagrant.box --name=cumulus/ts`

Using Libvirt+KVM
------------------------
* Rename `Vagrantfile-kvm` to `Vagrantfile` replacing the existing Vagrantfile that is used for Virtualbox.
* Install the Vagrant mutate plugin with `vagrant plugin install vagrant-mutate`
* Convert the existing NetQ telemetry server box image to a libvirt compatible version. `vagrant mutate cumulus-netq-telemetry-server-amd64-1.1.0-vagrant.box libvirt`
* Rename the new Vagrant box image by changing the Vagrant directory name. `mv $HOME/.vagrant.d/boxes/cumulus-netq-telemetry-server-amd64-1.1.0-vagrant/ $HOME/.vagrant.d/boxes/cumulus-VAGRANTSLASH-ts`

Running the Demo
------------------------
* The Telemetry Server replaces the oob-mgmt-server in the topology.
* `cd cldemo-netq`
* `vagrant up oob-mgmt-server oob-mgmt-switch`
* `vagrant up` (bringing up the oob-mgmt-server and switch first prevent DHCP issues)
* `vagrant ssh oob-mgmt-server`

### EVPN Demo
The first demo is based on BGP-EVPN with VxLAN Routing.
![EVPN Logical Topology](https://raw.githubusercontent.com/CumulusNetworks/cldemo-netq/master/images/evpn-topology.png)

Server01 and Server03 are in VLAN13, connected via VxLAN (VNI13).  
Server02 and Server04 are in VLAN24, also connected via VxLAN (VNI24).

All four leaf switches are configured with anycast gateways for both VLAN13 and VLAN24.

Server01 has the IP `10.1.3.101`  
Server02 has the IP `10.2.4.102`  
Server03 has the IP `10.1.3.103`  
Server04 has the IP `10.2.4.104`  

**To provision this demo**, from the oob-mgmt-server
* `cd evpn`
* `ansible-playbook run_demo.yml`

After the playbook finishes, you can run a number of tests to view connectivity  
From server01:
* `ping 10.1.3.103` (server03)
* `ping 10.2.4.104` (server04)
* `traceroute 10.1.3.103`
* `traceroute 10.2.4.104`

Notice the path from server01 to server03 is direct, while server01 to server04 passes through an extra hop (the gateway at 10.1.3.1)

From leaf01:
* `netq check bgp`
* `netq check evpn`
* `ip route show | netq resolve` to view the routing table with NetQ hostname resolution
* `netq server03 show ip neighbors` to view the ARP table of server03. This should include an entry for `10.1.3.101`
```
cumulus@leaf01:mgmt-vrf:~$ netq server03 show ip neighbors
Matching neighbor records are:
IP Address       Hostname         Interface            Mac Address              VRF              Remote Last Changed
---------------- ---------------- -------------------- ------------------------ ---------------- ------ ----------------
10.1.3.101       server03         uplink               44:38:39:00:00:03        default          no     9m:8.903s
10.1.3.13        server03         uplink               44:38:39:00:00:24        default          no     7m:24.415s
10.1.3.14        server03         uplink               32:3e:76:e2:7b:ae        default          no     6m:58.210s
192.168.0.254    server03         eth0                 44:38:39:00:00:5f        default          no     9m:57.746s
```
* `netq trace 44:38:39:00:00:03 from leaf03` (this should be the MAC address of server01's `uplink` bond interface)
```
cumulus@leaf01:mgmt-vrf:~$ netq trace 44:38:39:00:00:03 from leaf03
leaf03 -- leaf03:vni13 -- leaf03:swp51 -- spine01:swp1 -- leaf01:vni13 -- leaf01:bond01 -- server01
                                       -- spine01:swp2 -- leaf02:vni13 -- leaf02:bond01 -- server01
                       -- leaf03:swp52 -- spine02:swp1 -- leaf01:vni13 -- leaf01:bond01 -- server01
                                       -- spine02:swp2 -- leaf02:vni13 -- leaf02:bond01 -- server01
Path MTU is 1500
```

On leaf01 misconfigure EVPN 
```
net del bgp l2vpn evpn advertise-all-vni
net commit
```

And check that BGP is still working as expected  
`netq check bgp`

And that EVPN is misconfigured  
`netq check evpn`


Correct the EVPN misconfiguration
```
net add bgp l2vpn evpn advertise-all-vni
net commit
```

Verify that EVPN is functional  
`netq check evpn`

Now, on leaf01 shut down the link to spine01  
`sudo ifdown swp51`

Wait 5-10 seconds for NetQ to export the data.

With NetQ, check BGP again and you should see two failed sessions.  
`netq check bgp`

Again, run the NetQ traceroute that was run earlier
`netq trace 44:38:39:00:00:03 from leaf03` and notice that there are two paths through spine02 but only a single path through spine01 now.

View the changes to the fabric as a result of shutting down the interface  
`netq spine01 show changes between 1s and 5m` *note* the interface state on spine01 may not change because of the virtual environment, but the BGP peer will still fail.

Next, from **spine02**:  
Change the MTU on the interface
```
net add interface swp3 mtu 9000
net commit
```

If we check BGP again, we still have only two failed sessions: leaf01 and spine01.  
`netq check bgp`

If we run the traceroute again, we will see the MTU failure in the path  
`netq trace 44:38:39:00:00:03 from leaf03`

Again, you can see the changes with `netq spine02 show changes between 1s and 5m`


### Docker Swarm + Routing on the Host Demo
The second demo relies on [Cumulus Host Pack](https://cumulusnetworks.com/products/host-pack/) to install Quagga and NetQ on each server. The servers speak eBGP unnumbered to the local top of rack switches.

If any existing demos have already been provisioned, the lab must be rebuilt. On your VM host run `vagrant destroy -f leaf01 leaf02 leaf03 leaf04 spine01 spine02 server01 server02 server03 server04` then recreate a fresh environment with `vagrant up`

![Docker + Routing on the Host](https://raw.githubusercontent.com/CumulusNetworks/cldemo-vagrant/master/documentation/cldemo_topology.png)

Just as described in the Reference Topology diagram, each server is configured with a /32 loopback IP and BGP ASN.


After BGP is configured on the hosts, [Docker CE](https://www.docker.com/community-edition) is automatically installed and [Docker Swarm](https://docs.docker.com/engine/swarm/) is configured.


Within Docker Swarm, server01 acts as the _Swarm Master_ while server02, server03 and server04 act as _Swarm Workers_.

A container running Apache is deployed across three of the nodes in the swarm.

**To provision this demo**, from the oob-mgmt-server  
* `cd docker` (roh for Routing On the Host)
* `ansible-playbook run_demo.yml`

From server01:  
* `sudo docker node ls` to verify that all four servers are in the swarm
* `sudo docker service ps apache_web` to see the three apache containers deployed

Log into to Quagga on server01:  
* `sudo docker exec -it cumulus-roh /usr/bin/vtysh` to attach to the Quagga process
* `show ip bgp summary` to view the BGP peers
* `show ip bgp` to view the BGP routes
* `exit` to log out of quagga


Now use NetQ to verify Docker settings. On **spine01**:  
`netq show docker summary` to see the nodes with docker installed and brief information about them  
`netq show docker swarm cluster` to see the members of the cluster  
`netq show docker swarm node` to view the the members of the cluster and their roles  
`netq show docker container network host` to view the containers with host networking, which shows the Quagga containers  
`netq show docker service` to view the currently running services (only apache_web in this demo)  
`netq show docker service name apache_web connectivity` to view all of the containers named `apache_web` and their connectivity  
`netq leaf02 show docker container adjacent interface swp1` to see the containers that are adjacent to the leaf02, swp1 interface (the containers deployed on server01)

Now, connect to **server03** and shut down the link to leaf04  
`sudo ifdown eth2`

Wait 10-20 seconds for NetQ to export the data and look at the impact of removing leaf03 from the network
`netq leaf03 show impact docker service apache_web` The red indicates that removing leaf03 from service would bring down server03 and the attached containers


Troubleshooting + FAQ
-------
* The `Vagrantfile` expects the telemetry server to be named `cumulus/ts`. If you get the following error
```The box 'cumulus/ts' could not be found or
could not be accessed in the remote catalog. If this is a private
box on HashiCorp's Atlas, please verify you're logged in via
`vagrant login`. Also, please double-check the name. The expanded
URL and error message are shown below:

URL: ["https://atlas.hashicorp.com/cumulus/ts"]
Error: The requested URL returned error: 404 Not Found
```
Please ensure you have the telemetry server downloaded and installed in Vagrant. Use `vagrant box list` to see the current Vagrant box images you have installed.
* `vagrant ssh` fails to network devices - This is expected, as each network device connects through the `oob-mgmt-server`. Use `vagrant ssh oob-mgmt-server` then ssh to the specific network device.
* If you log into a switch and are prompted for the password for the `vagrant` user, issue the command `su - cumulus` to change to the cumulus user on the oob-mgmt-server
* The Docker demo fails on server01 with an  error similar to the following
```TASK [Deploy Apache Containers] ************************************************
Wednesday 06 September 2017  03:03:56 +0000 (0:00:00.567)       0:00:44.092 ***
fatal: [server01]: FAILED! => {"changed": true, "cmd": ["docker", "service", "create", "--name", "apache_web", "--replicas", "3", "--publish", "8080:80", "php:5.6-apache"], "delta": "0:00:02.673790", "end": "2017-09-06 03:03:58.934894", "failed": true, "rc": 1, "start": "2017-09-06 03:03:56.261104", "stderr": "Error response from daemon: rpc error: code = 3 desc = port '8080' is already in use by service 'apache_web' (vviesw72piif37ip8wplod2dn) as an ingress port", "stdout": "", "stdout_lines": [], "warnings": []}
```
The Docker playbook can only be run once without reprovisioning the environment. The error can be ignored. If you need to rebuild the environment, please `vagrant destroy` and then `vagrant up`

This repo will set up Cumulus In the Cloud to run the cldemo-netq environment.

1.) Get a CITC workbench. Go to the [CITC page](https://cumulusnetworks.com/products/cumulus-in-the-cloud/) and click "Get Started"

2.) When it's ready, login. As a pro tip, on the right side bar, under "Resources" is information about SSH access to the oob-mgmt-server.

3.) Log into to your CITC oob-mgmt-server and run  
`git clone -b citc https://github.com/CumulusNetworks/cldemo-netq/ citc`

4.) `cd citc`

5.) `ansible-playbook setup.yml`

6.) `git clone -b citc-dev https://github.com/CumulusNetworks/cldemo-netq/ citc-evpn`

7.) `cd citc-evpn`

8.) `ansible-playbook run_demo.yml`


At this point the environment should be fully provisioned. When this unified with the generic demo the second `git clone` step will be removed and the single demo folders will apply for either CITC or local demos. 

If you need to restart your workbench you can use `<citc_url>/rebuild` and the lab will be destroyed and brought back up, similar to using `vagrant destroy ; vagrant up`

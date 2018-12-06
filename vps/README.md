# Helium Masternode VPS Installation

This masternode installation script vastly simplifies the setup of a Helium masternode running on a virtual private server (VPS), and it also adds a number of other powerful features, including:

* IPv6 Support
* Installs 1-100 (or more!) Helium masternodes in parallel on one VPS, with individual helium.conf and data directories
* It can install masternodes for other coins on the same VPS as Helium
* 100% auto-compilation and 99% of configuration on the masternode side of things
* Automatically compiling from the latest Helium release tag, or another tag can be specified
* Some security hardening is done, including firewalling and a separate user, increasing security
* Automatic startup for all masternode daemons

Some notes and requirements:

* Script has only been tested on Vultr & DO, but should work almost anywhere where IPv6 addresses are available
* Currently only Ubuntu 16.04 Linux is supported
* This script needs to run as root or with sudo, the masternodes will and should not!
* You may want to do the "Configure Helium Wallet" section first as it'll simplify masternode setup.
* If you're transferring collateral from local wallet to the same wallet and are setting up multiple masternodes, use the "Add recipient" button to transfer the HLM. It's faster and also makes sure the 1000HLM transfers stay in one piece.
* This script includes [pimpmynode](https://github.com/TeelaBrown/pimpmynode) by AKcryptoGUY and TeelaBrown. It will modify the VPS welcome message. If you don't want this, there is a 'vanilla' version of Nodemaster for Helium here: https://github.com/trollboxteela/vps

This project was forked from https://github.com/phoreproject/vps (and comes with their screenshots) @marsmensch (Florian) is the primary author behind this VPS installation script for masternodes. If you would like to donate to him, you can use the BTC address below

**Have fun, this is crypto after all!**

```
BTC  33ENWZ9RCYBG7nv6ac8KxBUSuQX64Hx3x3
```

# Install guide on vultr

## How to get VPS server

This guide uses **Vultr** as a VPS hosting provider, but other providers that allow direct root SSH login access and offer Ubuntu 16.04 will work as well.

## Deploy a new system

First, create a new VPS by clicking that small "+" button.

<img src="docs/images/masternode_vps/deploy-a-new-system.png" alt="VPS creation" class="inline"/>

## Location choice

You can choose any location. You may wish to have it hosted in a city/country near you, or choose a different area to help with the global decentralization of the Helium masternode network.

<img src="docs/images/masternode_vps/location-choice.png" alt="VPS location choice" class="inline"/>

## Linux distribution (Ubuntu 16.04 LTS)

Select Ubuntu 16.04.

<img src="docs/images/masternode_vps/linux-distribution--ubuntu-1604-lts-.png" alt="VPS location choice" class="inline"/>

## VPS size

The 25 GB SSD / 1024MB Memory instance is enough for 2-3 masternodes. You may need more memory as the Helium blockchain grows over time, or if you want to run more masternodes.

<img src="docs/images/masternode_vps/vps-size.png" alt="VPS sizing" class="inline"/>

## Activating additional features (IPv6)

Toggle "Enable IPv6" to activate that feature--at Vultr there is no additional cost for this.

<img src="docs/images/masternode_vps/activating-additional-features--ipv6-.png" alt="VPS sizing" class="inline"/>

You may wish to enable DDOS Protection to protect your masternodes against a potential denial of service attack, especially if you are running multiple masternodes from one VPS. Vultr charges an additional fee for this.

## Hostnames & number of VPS

Choose how many instances you want and click "Deploy Now".

<img src="docs/images/masternode_vps/hostnames--amp--number-of-vps.png" alt="VPS sizing" class="inline"/>

## Installation of PuTTY as SSH client (Windows)
If you are running your wallet from Windows, install PuTTY while the server is being set up. You can download PuTTY from here: http://www.putty.org/. Skip this step if you are using a Mac--you will use the built in Terminal application instead.

Once PuTTY is installed, return to the Vultr dashboard to get the login details by clicking on the ... to the right of your server, and select Server Details.

Windows 10 users can access their VPS through the command line. Find out how to do that here: https://www.heliumlabs.org/docs/ssh-in-windows-10-no-more-putty

## Accessing your VPS via SSH

Copy your password for SSH access from the server details page.
<img src="docs/images/masternode_vps/accessing-your-vps-via-ssh.png" alt="check hostname and password" class="inline"/>

Now open PuTTY to add the server.

<img src="docs/images/masternode_vps/login-to-vps-via-PuTTY.png" alt="login to VPS" class="inline"/>

Enter the IP address in the Host Name field, and enter the server name you wish to use for this VPS (e.g., MN01) to Saved Sessions. Click save.

Click the open button. When the console has opened, click Yes in the PuTTY Security Alert box.
<img src="docs/images/masternode_vps/PuTTY-Security-Alert.png" alt="Alert from PuTTY" class="inline"/>

Now enter your server login details provided in your Vultr account.
You cannot Ctrl+V to paste in the console. Either right click the mouse or type shift+insert (sometimes
on keyboard it will just be INS key)

User: root
Password: (paste or type password)

When you paste it will not display, so don't try to paste again.
Just paste once and press Enter.

For Mac users, open Terminal (e.g., Press Command-Space and type Terminal and press Enter). Then type:

```
ssh -l root <IP address>
```
## Install Masternode

Login to your newly installed node as "root".

<img src="docs/images/masternode_vps/login.png" alt="VPS sizing" class="inline"/>

Enter this command to copy the Masternode installation script and install a single Helium Masternode:

```bash
git clone https://github.com/heliumchain/vps.git && cd vps && ./install.sh -p helium
```

If you have your masternode private key, please use this (you can generate masternode private key with Step 2 below).

```bash
git clone https://github.com/heliumchain/vps.git && cd vps && ./install.sh -p helium -k **PRIVATE KEY**
```
Replace ```**PRIVATE KEY**``` with your own masternode privkey.
Using this command, you can skip "Configure masternode configuration files" below, because the command abopve adds the masternode private key to the masternode configuration files.

This prepares the system and installs the Helium Masternode daemon. This includes downloading the latest Helium masternode release, creating a swap file, configuring the firewall, and compiling the Helium Masternode from source. This process takes about 10-15 minutes.

<img src="docs/images/masternode_vps/install.png" alt="VPS configuration" class="inline"/>

While that is underway, go back to your local desktop and open helium-qt.

### Multiple Masternodes on one VPS (ignore if you are installing a single masternode on a new VPS)

If you wish to install more than one masternode on the same VPS, you can add a -c parameter to tell the script how many to configure, so for example this would install three Helium masternodes (all entered on one line):

```bash
git clone https://github.com/heliumchain/vps.git && cd vps && ./install.sh -p helium -c 3
```

If you already have your masternode private keys, you can add them as shown below (all entered on one line):

```bash
git clone https://github.com/heliumchain/vps.git && cd vps && ./install.sh -p helium -c 3 --key **PRIVATE KEY 01** --key2 **PRIVATE KEY 02** --key3 **PRIVATE KEY 03**
```
Replace every `**PRIVATE KEY 01**` etc entry by your masternode privkey. So

```bash
git clone https://github.com/heliumchain/vps.git && cd vps && ./install.sh -p helium -c 3 --key1 7QgVciKfm43fdRxQFLKYn76f3d78phUWRWajUfWGMMHUv5SuUt5 --key2 7RNz4BvxsadGYedHr5KTZ9Wha45gbEbmg9eaXuwXjwuNJZBPsJC --key3 7Qy9bPyZExu78fd5eowoGKxpu7ExvKzsFxjeaaNEXBPRsoYukN
```

Using this command, you can skip the step for "Configure masternode configuration files", because the command above adds the masternode private keys to the masternode configuration files.

Note that you can only install 10 masternodes at a time using this command.


If you are upgrading your masternode(s) to a new release, you should first remove the old version of the VPS script so that the new one you download is tagged with the latest version, and then you add a -u parameter to upgrade existing nodes:

```bash
rm -rf /root/
```
```bash
git clone https://github.com/heliumchain/vps.git && cd vps && ./install.sh -p helium -u
```

The project is configured to use the latest official release of the Helium masternode code, and we will update this project each time a new release is issued, but without downloading the latest version of this project and using the -u parameter, the script will not update an existing Helium node that is already installed.

### Adding Masternodes on an existing installation

You can add masternodes to a VPS that already has several running. You can do this by following the below steps. It will not affect the masternodes that are already running on your VPS.

Open your local wallet's debug console and run ```masternode genkey``` for each new masternode. Send the collateral transactions and note the ```masternode outputs``` for every transaction.

Login to your VPS and run the Nodemaster script:

```bash
cd vps
```
```bash
sudo ./install.sh -p helium -c *
```

Where `*`  is total number of masternode desired on the VPS. This adds folders and files to run new nodes. Running the script again doesn't touch the helium daemon or previous installed nodes.

Edit `/etc/masternodes/helium_n*.conf` and add the `masternodeprivkey` for every new node. Copy assigned VPS_IP found in every .conf. `*` here is the number of every new node. Nodemaster numbers them helium_n1, helium_n2, helium_n3 etcetera.

Edit your local masternode.conf and add a line for every new masternode with:

`"alias" "VPS_IP" "masternodeprivkey" "txhash" "index"`

Save and restart the wallet.

On your VPS, start every new masternode with:

```bash
sudo systemctl enable helium_n*        
``` 
```bash
sudo systemctl start helium_n*
```

Start the new masternodes from the masternodes on your local wallet.


## Configure Helium Wallet
### Step1 - Create Collateral Transaction
Once the wallet is open on your local computer, generate a new receive address and label it however you want to identify your masternode rewards (e.g., Helium-MN-1). This label will show up in your transactions each time you receive a block reward.

Click the Request payment button, and copy the address.

<img src="docs/images/masternode_vps/request.png" alt="making new address" class="inline"/>

Now go to the Send tab, paste the copied address, and send *exactly* 1000 HLM to it in a single transaction. Wait for it to confirm on the blockchain. This is the collateral transaction that will be locked and paired with your new masternode. If you are setting up more than one masternode at one time, repeat this process for each one. Or better yet, use the Add Recipients button to send everything at once.

<img src="docs/images/masternode_vps/send.png" alt="sending 10kPHR" class="inline"/>

### Step 2 - Generate Masternode Private Key
Go to the **[Tools > Debug Console]** and enter these commands below:

```bash
masternode genkey
```
This will produce a masternode private key:

<img src="docs/images/masternode_vps/step2-masternodegenkey.png" alt="generating masternode private key" class="inline"/>

Copy this value to a text file. It will be needed for both the helium configuration file on the masternode VPS, and the masternode configuration file on the computer with the controlling Helium wallet.

If you are setting up multiple masternodes, repeat this step for each one. Each time you run the masternode genkey command it will give you a new private key--it doesn't matter which one you use, but it is important that it is unique for each masternode and that the VPS Helium configuration file and wallet masternode configuration file match (see below).

### Step 3 - Masternode Outputs

This will give you the rest of the information you need to configure your masternode in your Helium wallet--the transaction ID and the output index.

```bash
masternode outputs
```

<img src="docs/images/masternode_vps/step3-masternodeoutputs.png" alt="getting transaction id" class="inline"/>

The long string of characters is the *Transaction ID* for your masternode collateral transaction. The number after the long string is the *Index*. Copy and paste these into the text file next to the private key you generated in Step 2.

If you have multiple masternodes in the same wallet and have done the 1000 HLM transactions for each of them, masternode outputs will display transaction IDs and indexes for each one. You can choose which private key to go with each transaction ID and index, as long as they are all different, and you make sure the corresponding lines in masternode.conf and the VPS helium configuration files match (see below).

## End of installations
When the script finishes, it will look similar to this:

<img src="docs/images/masternode_vps/end.png" alt="installation ended" class="inline"/>

You only have a few steps remaining to complete your masternode configuration.
## Configure masternode configuration files
Since this installation method supports multiple masternodes, the helium configuration files have a node number added to them (e.g., helium_n1.conf, helium_n2.conf), stored in the /etc/masternodes directory. If you have a single masternode on the VPS, you will only need to edit /etc/masternodes/helium_n1.conf.

To open helium_n1.conf for editing, enter these commands:
```bash
sudo apt-get install nano
nano /etc/masternodes/helium_n1.conf
```
The next step adds your masternode private key.

## Add masternode private key
What you need to change is only masternode private key.
(We recommend using IPv6 which is the default, but if you choose IPv4 when you ran the installation script, please edit #NEW_IPv4_ADDRESS_FOR_MASTERNODE_NUMBER to your VPS IP address).
After typing the nano command, you will see something similar to this.

<img src="docs/images/masternode_vps/insert-your-masternode-private-key.png" alt="add private key" class="inline"/>

Copy the masternode private key from the text file you saved it in, and replace HERE_GOES_YOUR_MASTERNODE_KEY_FOR_MASTERNODE_helium_1 with that private key (It starts with a 7.

While you have this file opened, copy the information that follows after masternodeaddr=, starting with the open bracket. This is the masternode's IPv6 address and port, and will be needed for the wallet's masternode.conf file.

Once you have your masternode private key entered, press <font color="Green">Ctrl+X</font> .
Then press <font color="Green">Y</font> to save, and press Enter to exit.

Finally, close and restart your Helium wallet so that it will have the new masternode configuration.

## Start your masternodes
A script for starting all masternodes on the VPS has been created at /usr/local/bin/activate_masternodes_helium.sh.
Run this command after your masternode configuration written above.

```bash
/usr/local/bin/activate_masternodes_helium
```

The masternode daemons will start and begin loading the Helium blockchain.

## Finishing Wallet Configuration & Activate Masternode
To activate your nodes from your wallet, one of the last steps is to add a line for the masternode in the masternode.conf file. This file has the following format, with each value separated with a space:

* alias IP:Port masternodeprivatekey collateral_transaction_ID collateral_output_index
* alias - A short name you use to identify the masternode, you can choose this name as long as it is without spaces (e.g., Helium-MN-1)
* IP:Port - The IP address (either IPv6 or IPv4) and the Port where the masternode is running, separated by a colon (:). You copied this from the helium.conf file on the VPS.
* collateral_transaction_ID: This is the transaction ID you copied from masternode outputs.
* collateral_output_index: This is the index you copied from masternode outputs.

From the wallet menu, edit the local wallet **masternode.conf** file. **[Tools > Open Masternode Configuration File]**
Add the MN conf line, like the example below to the masternode.conf file. Save it, and close the file. It will look like the following example, using your values for each of the fields above. A common mistake is mixing up the private key and the collateral transaction ID--to make this easier, the private key usually begins with an 8.

example.
```
Helium-MN-1 [2001:19f0:5001:ca6:2085::1]:11771 88xrxxxxxxxxxxxxxxxxxxxxxxx7K 6b4c9xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx7ee23 0
```

The image below shows another example using an IPv4 IP address. If you followed this guide you are probably using an IPv6 address that looks like the line above.

<img src="docs/images/masternode_vps/masternode-conf.png" alt="editing masternode.conf" class="inline"/>

If you are running multiple masternodes, you need to add one of these lines for each masternode, and make sure the private key on each line matches the corresponding private key you entered in the VPS helium configuration file for that masternode.
## Check syncing status of masternode
The masternode cannot complete activation until it is fully synced with the Helium blockchain network.

To check the status of your masternode, please enter this command in the VPS terminal. 
```bash
/usr/local/bin/helium-cli -conf=/etc/masternodes/helium_n1.conf getinfo
```
If you have multiple masternodes on the same VPS, you can change n1 to n2 etc. So for node number two type:
```bash
/usr/local/bin/helium-cli -conf=/etc/masternodes/helium_n2.conf getinfo
```
Etcetera.

The output will look like this:
```
{
  "version": 150200,
  "protocolversion": 71029,
  "walletversion": 61000,
  "balance": 0.00000000,
  "zerocoinbalance": 0.00000000,
  "blocks": 47508,
  "timeoffset": 0,
  "connections": 4,
  "proxy": "",
  "difficulty": 24703.78796245168,
  "testnet": false,
  "moneysupply": 8994482.77956084,
  "zHLMsupply": {
    "1": 0.00000000,
    "5": 0.00000000,
    "10": 0.00000000,
    "50": 0.00000000,
    "100": 0.00000000,
    "500": 0.00000000,
    "1000": 0.00000000,
    "5000": 0.00000000,
    "total": 0.00000000
  },
  "keypoololdest": 1537411480,
  "keypoolsize": 1000,
  "unlocked_until": 0,
  "paytxfee": 0.00000000,
  "relayfee": 0.00010000,
  "staking status": "Staking Not Active",
  "errors": ""
```

We're looking at the *blocks*, and need that to be the latest block in the blockchain. You can check your local wallet to see the latest block by hovering over the green check mark.

<img src="docs/images/masternode_vps/status.png" alt="checking syncing status" class="inline"/>

Once your masternode has synced up to the latest block, go to next step. The syncing process may take 15-30 minutes or more as the Helium blockchain grows. You can keep checking progress with the command above, by pressing the up arrow and Enter to repeat it.

## Start Masternode

Go to the debug console of your Helium wallet **[Tools->Debug Console]** and enter the following command, replacing **mn-alias** with the name of the masternode in the Alias column of the Masternodes tab:

```
startmasternode alias false mn-alias
```

You may need to unlock the wallet **[Settings->Unlock Wallet]** before you run this command, entering your passphrase. You can lock the wallet after it is finished.

If everything was setup correctly, after entering the command you will see something like this:
```
{
"overall" : "Successfully started 1 masternodes, failed to start 0, total 1",
"detail" : {
"status" : {
"alias" : "helium-mn01",
"result" : "successful"
}
```
If you are setting up multiple masternodes, repeat this for each one. You can now close the debug console, return the Masternodes tab and check the status:

<img src="docs/images/masternode_vps/enabled.png" alt="checking syncing status" class="inline"/>

It should say ENABLED, and within an hour, the timer in the Active column should start increasing.

Your Helium masternode is now set up and running! Depending on how many masternodes there are, it may take up to 72 hours before you see your first masternode reward--this is normal and rewards should come at more regular intervals after the first one.

<img src="docs/images/masternode_vps/reward.png" alt="rewards" class="inline"/>

## Issues and Questions
Please open a GitHub Issue if there are problems with this installation method. If you can't figure it out just ask someone in the Helium channel.

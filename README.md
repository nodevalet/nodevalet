# NodeValet.io

This is the repository for the https://nodevalet.io Masternode installation service.

To get started, visit us on the web https://nodevalet.io and click the "Get Started" link, or if you already have your own ip6 VPS enabled and running Ubuntu 16.04, try running the "headless" installation script from terminal:

```bash
cd /var/tmp ; sudo git clone https://github.com/nodevalet/nodevalet ; cd nodevalet; sudo bash silentinstall.sh
```

NodeValet helps you securely deploy multiple Masternodes on a VPS of your choosing in a matter of minutes. Fully-automated deployments with the convenience of a hosted solution. NodeValet Masternodes come pre-installed with a variety of maintenance scripts that make sure your Masternode is always online, always secure and even handles wallet updates without user intervention. A true set-and-forget solution.

Self-hosting your own Masternodes has a number of benefits. For starters, it is way more cost-effective than paying someone else to do it. The next best advantage is that you retain full control over your Masternodes so your collateral never leaves your wallet. It can be challenging to set up and maintain Masternodes by yourself, but with NodeValet’s automated VPS installations, you can rapidly deploy fully-autonomous and hardened virtual servers that require little to no maintenance without so much as touching a command prompt. 

Are you a tinkerer who prefers a more hands-on approach? That works, too! Since the VPS which hosts your NodeValet Masternodes exists entirely within your own hosting account (presently at Vultr or Digital Ocean), you can log into it remotely with SSH whenever you want and use our full suite of power tools to quickly get the information you need or make changes to your masternodes with only a minimal knowledge of Linux. NodeValet gives you all the benefits of self-hosting with the additional convenience of a hosted solution. 

API access to your VPS host provider is only necessary for the 30 seconds it takes to connect to your account and deploy your Masternode server. After that is done, you are reminded to disable the API or regenerate the API key.

For now NodeValet supports Helium, Audax, Phore, and PIVX. To try it out please head over to https://nodevalet.io.
We're working to add a variety of other Masternode coins to the service in the near future. 

Part of NodeValet runs on an adapted version of [Florian Maier's Nodemaster script.](https://github.com/masternodes/vps)

# Features

- 5 minute, 'one click' install through our web GUI. No need to log into your VPS.
- We never ask for your personal info so there is nothing to be hacked.
- Automatic server hardening. Your VPS will be more secure than most.
- Automatically generated masternode.conf, copy paste ready into your local wallet.
- Automated maintenance. Your VPS will continuously monitor the status of your Masternode and fix it if needed.
- Automatic wallet updates. Your VPS will check your coin's Github twice a day, and when it sees an update, install it.

**Planned features**

- Full integration with "headless" installation. This will allow you to use our service while bypassing the API requirement. (tinfoil hat mode) 
- On demand system updates. This will allow the user to update their NodeValet Masternode with the latest features without compromising server security.

# Guides

A simple guide for installing Helium masternodes with NodeValet: 

https://www.heliumlabs.org/v1.0/docs/masternodes-with-nodevalet

A simple guide for installing Condominium masternodes with NodeValet:

https://medium.com/@AKcryptoGUY/easy-condominium-masternode-setup-using-nodevalet-io-6b451d8ce87b

# Shell commands

Just because you won't have to log in to your VPS doesn't mean you can't :). To keep things easy we use Nodemaster to configure the actual Masternodes so everything is exactly where you'd expect it to be.

NodeValet keeps its files in `/var/tmp/nodevalet` and its logs in `/var/tmp/nodevalet/logs`

We've added a few small scriptlets to make the most common commands a lot easier. You can simply enter these on the command line:

`showconf` will display the masternode.conf file to be installed in your local wallet  
`autoupdate` checks for new binaries and automatically installs them  
`checkdaemon` will check if all masternodes are correctly synced  
`checksync` will return the syncing status of all masternodes  
`clonesync` can be used to bootstrap a masternode and fully sync its chain from another masternode  
`getinfo 1` returns a summarized `getinfo` of masternode (1, 2, 3 etc) `getinfo` shows all  
`killswitch` turns off all masternodes. Use `activate_masternodes_COIN` to turn them back on  
`makerun` checks if all installed masternodes are running  
`masternodestatus 1`  returns the `masternodestatus` of masternode (1, 2, 3 etc) `masternodestatus` returns all  
`mnstart 1` will re-enable and restart a particular masternode (1, 2, 3 etc) after you have disabled it  
`mnstop 1` will disable and stop a particular masternode (1, 2, 3 etc)  
`mulligan` erase all masternode data and NodeValet files on this VPS; useful to repurpose VPS  
`rebootq` checks if recent system updates require a reboot 
`resync 1` deletes blockchain data for node (1, 2, 3, etc) and forces a resync  
`showlog` will display the installation log  
`showmlog` will display the maintenance log  

We may add more from time to time so stay tuned!

Meanwhile, enjoy the service!

# Links

- [Website](https://www.nodevalet.io)
- [Twitter](https://twitter.com/nodevalet)
- [Discord](https://discord.gg/dx2scUU)
- [Bitcointalk](https://bitcointalk.org/index.php?topic=5226866)


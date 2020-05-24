# NodeValet.io

This is the repository for the https://www.nodevalet.io masternode installation service.

To get started, visit us on the web https://www.nodevalet.io and click the "Get Started" link, or if you already have your own ipv6-enabled VPS started and running Ubuntu 16, 18, or 20, go ahead and launch a our "headless" installation script from terminal:

```bash
cd /var/tmp && sudo git clone https://github.com/nodevalet/nodevalet && cd nodevalet && sudo bash silentinstall.sh
```

NodeValet helps you securely deploy multiple masternodes on a VPS of your choosing in a matter of minutes. We combine fully-automated deployments with the convenience of a hosted solution. NodeValet masternodes come pre-installed with a variety of maintenance scripts that ensure your masternodes are always online, always secure, and they even install most wallet updates without user intervention. **A true set-and-forget solution**.

Self-hosting your own masternodes has a number of benefits. For starters, it is **way more cost-effective** than paying someone else to do it. The next best advantage is that **you retain full control** over your masternodes and **your collateral never leaves your wallet**. It can be challenging to set up and maintain masternodes by yourself, but with NodeValet’s automated VPS installations, you can rapidly deploy fully-autonomous and hardened virtual servers that require little to no maintenance without so much as touching a command line. 

**Are you a tinkerer who prefers a more hands-on approach?** That works, too! Since the VPS which hosts your NodeValet masternodes exists entirely within your own hosting account, you can log into it remotely whenever you want and use our full suite of power tools to quickly get the information you need or make changes to your masternodes with only a minimal knowledge of Linux. **NodeValet gives you all the benefits of self-hosting with the additional convenience of a hosted solution**. 

API access to your VPS host provider is only necessary for the 30 seconds it takes to connect to your account and deploy your masternode server. After that is done, you are reminded to disable the API or regenerate the API key.

For now NodeValet supports **sQuorum, Audax, MUE, Phore, PIVX, Wagerr, SierraCoin, StakeCube, and Smart**. To try it out please head over to https://www.nodevalet.io.
We're working to add a variety of other masternode coins to the service in the near future. 

Part of NodeValet runs on an adapted version of [Florian Maier's Nodemaster script.](https://github.com/masternodes/vps)

# Features

- 5 minute, 'one click' install through our web GUI. No need to log into your VPS.
- We never ask for your personal info so there is nothing to be hacked.
- Automatic server hardening. Your VPS will be more secure than most.
- Automatically generated masternode.conf, copy paste ready into your local wallet.
- Automated maintenance. Your VPS will continuously monitor the status of your masternode and fix it if needed.
- Automatic wallet updates. Your VPS will check your coin's Github twice a day, and when it sees an update, install it.
- Full integration with "headless" installations allow you to use our service while bypassing the API requirement.
- Add new masternodes to your existing VPS by running our `addmn` scriptlet which will prompt for new addresses and info.

## Planned features 

- On demand system updates. This will allow the user to update their NodeValet masternode with the latest features without compromising server security.

# Supported VPS providers

 - Vultr supports headless and GUI installations
 - DigitalOcean supports headless and GUI installations
 - Contabo supports headless installations after running `enable_ipv6` and restarting
 - Hetzner supports headless installations
 - ArubaCloud supports headless installations
 - *Please contact us with others that work or don't work and we will add them to this list*

# Guides

A simple guide for installing Helium masternodes with NodeValet: 

https://medium.com/@AKcryptoGUY/quick-setup-guide-for-helium-masternodes-using-nodevalet-2208c2b8b2f2

# Shell commands

Just because you won't have to log in to your VPS doesn't mean you can't :). 

To keep things easy we use Nodemaster to configure the actual masternodes so everything is exactly where you'd expect it to be.

NodeValet keeps its files in `/var/tmp/nodevalet` and logs in `/var/tmp/nodevalet/logs`

We've added a few small scriptlets to make the most common commands a lot easier. You can simply enter these in the command line:

`showconf` will display the masternode.conf file to be installed in your local wallet  
`autoupdate` checks for new binaries and automatically installs them  
`checksync` will return the syncing status of masternodes  
`clonesync` can be used to bootstrap a masternode and fully sync its chain from another masternode  
`getinfo 1` returns a summarized `getinfo` of masternode (1, 2, 3 etc) `getinfo` shows all  
`killswitch` turns off all masternodes. Use  
`restore_crons` to turn them back on, or use   
`activate_masternodes_COIN` to turn them back on  
`makerun` checks if all installed masternodes are running  
`masternodestatus 1`  returns the `masternodestatus` of masternode (1, 2, 3 etc) `masternodestatus` returns all  
`mnstart 1` will re-enable and start a particular masternode (1, 2, 3 etc) after you have disabled it  
`mnstop 1` will disable and stop a particular masternode (1, 2, 3 etc)  
`mulligan` erase all masternode data and NodeValet files on this VPS; useful to repurpose VPS or reinstall from scratch  
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

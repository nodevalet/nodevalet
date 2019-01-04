# NodeValet.io

This is the repository for the https://nodevalet.io Masternode installation service.

NodeValet lets you securily deploy up to 20 Masternodes on a VPS of your choice in a matter of minutes. Fully automated and with the convenience of a hosted solution. Node Valet Masternodes come pre installed with a variety of maintanance scripts that make sure your Masternode is always online, always secure and even handles wallet updates by itself.

Self hosting your Masternode has a number of benefits in that it is way more cost effective and that you retain full control over your Masternode. It can be challenging to set up and maintain Masternodes yourself. By automating the installation, server hardening and maintenance process we give you the benefits of self hosting with the convenience of a hosted solution. Open source and free of charge.

For now NodeValet supports Helium and Condominium. To try it out please head over to https://nodevalet.io .
We're working to add a variety of other Masternode coins to the service in the very near future. 

Part of NodeValet runs on an adapted version of [Florian Maier's Nodemaster script.](https://github.com/masternodes/vps)

# Features

- 5 minute, 'one click' install through our web GUI. No need to login to your VPS.
- No logging. We don't save as much as a cookie. Not retaining info means there is nothing there to be hacked.
- Automatically generated masternode.conf, copy paste ready.
- Automatic server hardening. Your VPS will be more secure than most.
- Automated maintenance. Your VPS will continuously monitor the status of your Masternode and fix it if needed.
- Automatic wallet updates. Your VPS will check your coin's github twice a day, and when it sees an update, install it.

**Planned features**

- Full integration with "headless" installation. This will allow you to use our service while bypassing the API requirement.  (tinfoil hat mode)  
- On demand system updates. This will allow the user to update their NodeValet Masternode with the latest features without compromising server security.

# Guides

A simple guide for installing Helium masternodes with NodeValet: 

https://www.heliumlabs.org/v1.0/docs/masternodes-with-nodevalet

A simple guide for installing Condominium masternodes with NodeValet:

https://medium.com/@AKcryptoGUY/easy-condominium-masternode-setup-using-nodevalet-io-6b451d8ce87b

# Shell commands

Just because you won't have to log in to your VPS doesn't mean you can't :). To keep things easy we use Nodemaster to configure the actual Masternodes so everything is exactly where you'd expect it to be.

NodeValet keeps its files in  `/var/tmp/nodevalet` and its logs in `/var/tmp/nodevalet/logs`

We've added a few small scripts to make the most common commands a lot easier. You can just enter these on the command line:

`checksync` will return the syncing status of all masternodes.  
`autoupdate` will run the autoupdate script and check for a new version. (rather than wait for the scheduled check)  
`checkdaemon` will check if all masternodes are correctly synced.  
`makerun` checks if all installed masternodes are running.  
`rebootq` checks if recent system updates require a reboot. (rather than wait for the scheduled check)   
`getinfo` returns a summarized `getinfo` of all masternodes.  
`killswitch` turns off all masternodes. Use `activate_masternodes_COIN` to turn them back on.  
`masternodestatus` returns the `masternodestatus` of every installed masternode.    
`resync 1` deletes blockchain data for node 1, 2, 3, etc and forces a resync.  

We'll be adding a couple more in the future so stay tuned!

Meanwhile, enjoy the service!






#!/bin/bash
# Make sure the daemon is not stuck and restart it if it is.
# authorized script to resync entire blockchain in case of catastrophic failure
# Add the following to the crontab (i.e. crontab -e)
# (crontab -l ; echo "*/30 * * * * $INSTALLDIR/maintenance/checkdaemon.sh") | crontab -

INSTALLDIR='/var/tmp/nodevalet'
INFODIR='/var/tmp/nvtemp'
PROJECT=`cat $INFODIR/vpscoin.info`
MNS=`cat $INFODIR/vpsnumber.info`
LOGFILE='/var/tmp/nodevalet/logs/maintenance.log'

# extglob was necessary to make rm -- ! possible
shopt -s extglob

# set mnode daemon name from project.env
MNODE_DAEMON=`grep ^MNODE_DAEMON $INSTALLDIR/nodemaster/config/${PROJECT}/${PROJECT}.env`
echo -e "$MNODE_DAEMON" > $INSTALLDIR/temp/MNODE_DAEMON
sed -i "s/MNODE_DAEMON=\${MNODE_DAEMON:-\/usr\/local\/bin\///" $INSTALLDIR/temp/MNODE_DAEMON  2>&1
cat $INSTALLDIR/temp/MNODE_DAEMON | tr -d '[}]' > $INSTALLDIR/temp/MNODE_DAEMON1
MNODE_DAEMON=$(<$INSTALLDIR/temp/MNODE_DAEMON1)
cat $INSTALLDIR/temp/MNODE_DAEMON1 > $INSTALLDIR/temp/MNODE_DAEMON ; rm -f $INSTALLDIR/temp/MNODE_DAEMON1

if [ -e "$INSTALLDIR/temp/updating" ]
	then echo -e "`date +%m.%d.%Y_%H:%M:%S` : Running checkdaemon.sh" | tee -a "$LOGFILE"
	echo -e "It looks like I'm installing other updates; skipping daemon check.\n"  | tee -a "$LOGFILE"
	exit
fi
touch $INSTALLDIR/temp/updating

echo -e "\n"
for ((i=1;i<=$MNS;i++));
do
echo -e " Checking for stuck blocks on masternode ${PROJECT}_n${i}"
previousBlock=`cat $INSTALLDIR/temp/blockcount${i}`
currentBlock=$(/usr/local/bin/${MNODE_DAEMON::-1}-cli -conf=/etc/masternodes/${PROJECT}_n${i}.conf getblockcount)
/usr/local/bin/${MNODE_DAEMON::-1}-cli -conf=/etc/masternodes/${PROJECT}_n${i}.conf getblockcount > $INSTALLDIR/temp/blockcount${i}
if [ "$previousBlock$" == "$currentBlock$" ]
then
	echo -e " Previous block is $previousBlock and current block is $currentBlock; same"
	echo -e " `date +%m.%d.%Y_%H:%M:%S` : Auto-restarting ${PROJECT}_n${i} because it seems stuck.\n"  | tee -a "$LOGFILE"
        systemctl stop ${PROJECT}_n${i}
        sleep 10
        systemctl start ${PROJECT}_n${i}
	
for ((T=1;T<=10;T++)); 
do 
	# wait 5 minutes to ensure that the chain is unstuck, and if it isn't, nuke and resync the chain on that instance
	sleep 300
	echo -e " Checking if restarting solved the problem on masternode ${PROJECT}_n${i}"
	previousBlock=`cat $INSTALLDIR/temp/blockcount${i}`
	currentBlock=$(/usr/local/bin/${MNODE_DAEMON::-1}-cli -conf=/etc/masternodes/${PROJECT}_n${i}.conf getblockcount)
	/usr/local/bin/${MNODE_DAEMON::-1}-cli -conf=/etc/masternodes/${PROJECT}_n${i}.conf getblockcount > $INSTALLDIR/temp/blockcount${i}
		if [ "$previousBlock$" == "$currentBlock$" ]; then
		echo -e " `date +%m.%d.%Y_%H:%M:%S` : Restarting ${PROJECT}_n${i} didn't fix chain syncing" | tee -a "$LOGFILE"
		echo -e " I have restarted the MN $T time(s) so far and it did not help. \n" | tee -a "$LOGFILE"   
		
		else echo -e " Previous block is $previousBlock and current block is $currentBlock." | tee -a "$LOGFILE"   
		echo -e " ${PROJECT}_n${i} appears to be syncing normally again.\n" | tee -a "$LOGFILE"   
		FIXED="yes"
		break
		fi
done	

if [ ! "$FIXED" == "yes" ]; then

	unset $FIXED
	echo -e " `date +%m.%d.%Y_%H:%M:%S` : Restarting ${PROJECT}_n${i} $T times didn't fix chain" | tee -a "$LOGFILE"
		echo -e " Invoking Holy Hand Grenade to resync entire blockchain\n" | tee -a "$LOGFILE"   	
		sudo systemctl disable ${PROJECT}_n${i}
		sudo systemctl stop ${PROJECT}_n${i}
		sudo /usr/local/bin/${MNODE_DAEMON::-1}-cli -conf=/etc/masternodes/${PROJECT}_n${i}.conf stop
		sleep 5
		cd /var/lib/masternodes/${PROJECT}${i}
		sudo rm -- !("wallet.dat"|"masternode.conf")
		sleep 5
		sudo systemctl enable ${PROJECT}_n${i}
		sudo systemctl start ${PROJECT}_n${i}
		
	else unset $FIXED
	echo " Glad to see that worked, exiting loop for this MN "
	fi
	
else echo -e " Previous block is $previousBlock and current block is $currentBlock."
echo -e " ${PROJECT}_n${i} appears to be syncing normally.\n"
fi

done

echo " Unsetting -update flag \n"
rm -f $INSTALLDIR/temp/updating

#!/bin/bash
# checkdaemon.sh
# Make sure the daemon is not stuck.
# Add the following to the crontab (i.e. crontab -e)

INSTALLDIR='/var/tmp/nodevalet'
PROJECT=`cat $INSTALLDIR/info/vpscoin.info`
MNS=`cat $INSTALLDIR/info/vpsnumber.info`
LOGFILE='$INSTALLDIR/log/checkdaemon.log'

if [ -e "$INSTALLDIR/tmp/updating ]
	then echo "Looks like I'm installing updates, I'll try again later."  | tee -a "$LOGFILE"
	exit
fi

for ((i=1;i<=$MNS;i++));
do
echo -e " Checking for stuck blocks on masternode "$PROJECT"_n${i}"
previousBlock=`cat $INSTALLDIR/tmp/blockcount${i}`
currentBlock=$(/usr/local/bin/"$PROJECT"-cli -conf=/etc/masternodes/"$PROJECT"_n${i}.conf getblockcount)
/usr/local/bin/"$PROJECT"-cli -conf=/etc/masternodes/"$PROJECT"_n${i}.conf getblockcount > $INSTALLDIR/tmp/blockcount${i}
if [ "$previousBlock$" == "$currentBlock$" ]; then
	echo -e " Previous block is $previousBlock and current block is $currentBlock; same"
	echo -e " `date +%m.%d.%Y_%H:%M:%S` : Auto-restarting ${PROJECT}_n${i} because it seems stuck.\n"  | tee -a "$LOGFILE"
        systemctl stop "$PROJECT"_n${i};
        sleep 10;
        systemctl start "$PROJECT"_n${i};
else echo -e " Previous block is $previousBlock and current block is $currentBlock."
echo -e " ${PROJECT}_n${i} appears to be syncing normally.\n"
fi
done

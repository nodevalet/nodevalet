#!/bin/bash
# checkdaemon.sh
# Make sure the daemon is not stuck.
# Add the following to the crontab (i.e. crontab -e)
# */30 * * * * /root/code-red/maintenance/checkdaemon.sh

INSTALLDIR='/root/installtemp'
PROJECT=`cat $INSTALLDIR/vpscoin.info`
MNS=`cat $INSTALLDIR/vpsnumber.info`
LOGFILE='/root/installtemp/checkdaemon.log'

for ((i=1;i<=$MNS;i++));
do
echo -e " Checking for stuck blocks on masternode "$PROJECT"_n${i}"
previousBlock=`cat /root/installtemp/blockcount${i}`
currentBlock=$(/usr/local/bin/"$PROJECT"-cli -conf=/etc/masternodes/"$PROJECT"_n${i}.conf getblockcount)
/usr/local/bin/"$PROJECT"-cli -conf=/etc/masternodes/"$PROJECT"_n${i}.conf getblockcount > /root/installtemp/blockcount${i}
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

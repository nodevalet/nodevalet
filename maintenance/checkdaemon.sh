#!/bin/bash
# checkdaemon.sh
# Make sure the daemon is not stuck.
# Add the following to the crontab (i.e. crontab -e)
# */30 * * * * /root/code-red/maintenance/checkdaemon.sh

INSTALLDIR='/root/installtemp'
PROJECT=`cat $INSTALLDIR/vpscoin.info`

previousBlock=$(cat /root/installtemp/blockcount)
currentBlock=$(/usr/local/bin/"$PROJECT"-cli -conf=/etc/masternodes/"$PROJECT"_n1.conf getblockcount)

/usr/local/bin/"$PROJECT"-cli -conf=/etc/masternodes/"$PROJECT"_n1.conf getblockcount > /root/installtemp/blockcount

if [ "$previousBlock" == "$currentBlock" ]; then
  	systemctl stop '$PROJECT*';
  	sleep 10;
  	cd /usr/local/bin; 
	./activate_masternodes_"$PROJECT";
fi

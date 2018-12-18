#!/bin/bash
#compare nr. of running nodes to number of installed nodes. If different restart daemon
# Add the following to the crontab (i.e. crontab -e)
# */5 * * * * /root/code-red/maintenance/makerun.sh
LOGFILE='/root/installtemp/makerun.log'
INSTALLDIR='/root/installtemp'
PROJECT=`cat $INSTALLDIR/vpscoin.info`
TOTAL=`ps aux | grep -i "$PROJECT"d | wc -l`
CUR_DAEMON=`expr $TOTAL - 1`
EXP_DAEMON=`cat /root/installtemp/vpsnumber.info`

if [ -e "$INSTALLDIR/updating ]
	then echo "Looks like I'm installing updates, I'll try again later."  | tee -a "$LOGFILE"
	exit
fi

if [ "$CUR_DAEMON" != "$EXP_DAEMON" ]
  then echo -e " `date +%m.%d.%Y_%H:%M:%S` : I expected $EXP_DAEMON daemons but found only $CUR_DAEMON. Restarting... \n" | tee -a "$LOGFILE"
  cd /usr/local/bin
  ./activate_masternodes_"$PROJECT"
fi

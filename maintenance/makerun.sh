#!/bin/bash
#compare nr. of running nodes to number of installed nodes. If different restart daemon
# Add the following to the crontab (i.e. crontab -e)

LOGFILE='/var/tmp/nodevalet/logs/makerun.log'
INSTALLDIR='/var/tmp/nodevalet'
INFODIR='/var/tmp/nvtemp'
PROJECT=`cat $INFODIR/vpscoin.info`
MNS=`cat $INFODIR/vpsnumber.info`

# add logging to check if cron is working as planned
# echo -e "`date +%m.%d.%Y_%H:%M:%S` : Executing makerun.sh (every 5 minutes, cron) \n"  | tee -a "$LOGFILE"

TOTAL=`ps aux | grep -i "$PROJECT"d | wc -l`
CUR_DAEMON=`expr $TOTAL - 1`
EXP_DAEMON=`cat /var/temp/nodevalet/info/vpsnumber.info`

if [ -e "$INSTALLDIR/temp/updating ]
	then echo "Looks like I'm installing updates, I'll try again later."  | tee -a "$LOGFILE"
	exit
fi

if [ "$CUR_DAEMON" != "$EXP_DAEMON" ]
  then echo -e " `date +%m.%d.%Y_%H:%M:%S` : I expected $EXP_DAEMON daemons but found only $CUR_DAEMON. Restarting... \n" | tee -a "$LOGFILE"
  cd /usr/local/bin
  ./activate_masternodes_"$PROJECT"
fi

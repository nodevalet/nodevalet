#!/bin/bash
# Compare number of running nodes to number of installed nodes; restart daemon if different
# Add the following to the crontab (i.e. crontab -e)
# (crontab -l ; echo "*/5 * * * * $INSTALLDIR/maintenance/makerun.sh") | crontab -

INSTALLDIR='/var/tmp/nodevalet'
INFODIR='/var/tmp/nvtemp'
PROJECT=$(<$INFODIR/vpscoin.info)
MNS=$(<$INFODIR/vpsnumber.info)
LOGFILE='/var/tmp/nodevalet/logs/maintenance.log'
MNODE_DAEMON=$(<$INFODIR/vpsmnode_daemon.info)
HNAME=$(<$INFODIR/vpshostname.info)

# add logging to check if cron is working as planned
# echo -e "`date +%m.%d.%Y_%H:%M:%S` : Executing makerun.sh (every 5 minutes, cron) \n"  | tee -a "$LOGFILE"

TOTAL=$(ps aux | grep -i "$MNODE_DAEMON" | wc -l)
CUR_DAEMON=$(expr "$TOTAL" - 1)
EXP_DAEMON=$(cat $INFODIR/vpsnumber.info)

if [ -e $INSTALLDIR/temp/updating ]
then echo -e " $(date +%m.%d.%Y_%H:%M:%S) : Running makerun.sh" | tee -a "$LOGFILE"
    echo -e " It looks like I'm busy with something else; skipping make run.\n"  | tee -a "$LOGFILE"
    exit
fi

if [ "$CUR_DAEMON" != "$EXP_DAEMON" ]
then echo -e " $(date +%m.%d.%Y_%H:%M:%S) : I expected $EXP_DAEMON daemons but found only $CUR_DAEMON. Restarting... \n" | tee -a "$LOGFILE"
    bash /usr/local/bin/activate_masternodes_"$PROJECT"
else echo -e "\n $(date +%m.%d.%Y_%H:%M:%S) : Found $CUR_DAEMON of $EXP_DAEMON expected daemons. All is well. \n"
fi

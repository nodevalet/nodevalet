#!/bin/bash
#compare nr. of running nodes to number of installed nodes. If different restart daemon
# Add the following to the crontab (i.e. crontab -e)
# */5 * * * * /root/code-red/maintenance/makerun.sh

INSTALLDIR='/root/installtemp'
PROJECT=`cat $INSTALLDIR/vpscoin.info`
TOTAL=`ps aux | grep -i "$PROJECT"d | wc -l`
CUR_DAEMON=`expr $TOTAL - 1`
EXP_DAEMON=`cat /root/installtemp/vpsnumber.info`
if [ "$CUR_DAEMON" != "$EXP_DAEMON" ]
  then cd /usr/local/bin
  ./activate_masternodes_"$PROJECT"
fi

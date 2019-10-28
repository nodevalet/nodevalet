#!/bin/bash
# Clear debug.log every week
# Add the following to the crontab (i.e. crontab -e)
# (crontab -l ; echo "@weekly $INSTALLDIR/maintenance/cleardebuglog.sh") | crontab -

LOGFILE='/var/tmp/nodevalet/logs/maintenance.log'
INSTALLDIR='/var/tmp/nodevalet'
INFODIR='/var/tmp/nvtemp'
MNS=$(<$INFODIR/vpsnumber.info)
PROJECT=$(<$INFODIR/vpscoin.info)
PROJECTl=${PROJECT,,}
PROJECTt=${PROJECTl~}
MNODE_DAEMON=$(<$INFODIR/vpsmnode_daemon.info)
HNAME=$(<$INFODIR/vpshostname.info)

for ((i=1;i<=$MNS;i++));
do /bin/date > /var/lib/masternodes/"$PROJECT"${i}/debug.log
done

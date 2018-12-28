#!/bin/bash
# Clear debug.log every other day
# Add the following to the crontab (i.e. crontab -e)
# (crontab -l ; echo "@weekly $INSTALLDIR/maintenance/cleardebuglog.sh") | crontab -

INSTALLDIR='/var/temp/nodevalet'
PROJECT=`cat $INSTALLDIR/info/vpscoin.info`
MNS=`cat $INSTALLDIR/info/vpsnumber.info`

for ((i=1;i<=$MNS;i++));
do /bin/date > /var/lib/masternodes/"$PROJECT"${i}/debug.log
done

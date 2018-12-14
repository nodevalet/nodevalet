#!/bin/bash
# clearlog.sh
# Clear debug.log every other day
# Add the following to the crontab (i.e. crontab -e)
# 0 0 */2 * * ~/heliumnode/clearlog.sh

INSTALLDIR='/root/installtemp'
PROJECT=`cat $INSTALLDIR/vpscoin.info`
/bin/date > /var/lib/masternodes/"$PROJECT"1/debug.log
/bin/date > /var/lib/masternodes/"$PROJECT"2/debug.log
/bin/date > /var/lib/masternodes/"$PROJECT"3/debug.log
/bin/date > /var/lib/masternodes/"$PROJECT"4/debug.log
/bin/date > /var/lib/masternodes/"$PROJECT"5/debug.log
/bin/date > /var/lib/masternodes/"$PROJECT"6/debug.log
/bin/date > /var/lib/masternodes/"$PROJECT"7/debug.log
/bin/date > /var/lib/masternodes/"$PROJECT"8/debug.log
/bin/date > /var/lib/masternodes/"$PROJECT"9/debug.log
/bin/date > /var/lib/masternodes/"$PROJECT"10/debug.log
/bin/date > /var/lib/masternodes/"$PROJECT"11/debug.log
/bin/date > /var/lib/masternodes/"$PROJECT"12/debug.log
/bin/date > /var/lib/masternodes/"$PROJECT"13/debug.log
/bin/date > /var/lib/masternodes/"$PROJECT"14/debug.log
/bin/date > /var/lib/masternodes/"$PROJECT"15/debug.log
/bin/date > /var/lib/masternodes/"$PROJECT"16/debug.log
/bin/date > /var/lib/masternodes/"$PROJECT"17/debug.log
/bin/date > /var/lib/masternodes/"$PROJECT"18/debug.log
/bin/date > /var/lib/masternodes/"$PROJECT"19/debug.log
/bin/date > /var/lib/masternodes/"$PROJECT"20/debug.log

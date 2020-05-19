#!/bin/bash
# This script will stop and disable all installed masternodes

# Set common variables
. /var/tmp/nodevalet/maintenance/vars.sh

# disable the crons that could cause problems
. /var/tmp/nodevalet/maintenance/remove_crons.sh

echo -e " $(date +%m.%d.%Y_%H:%M:%S) : ${lightred}Running killswitch.sh${nocolor}" >> "$LOGFILE"
echo -e " User directed server to shut down and disable all masternodes.\n" >> "$LOGFILE"

touch $INSTALLDIR/temp/updating

for ((i=1;i<=$MNS;i++));
do
    echo -e "\n $(date +%m.%d.%Y_%H:%M:%S) : Stopping and disabling masternode ${PROJECT}_n${i}"
    systemctl disable "${PROJECT}"_n${i} > /dev/null 2>&1
    systemctl stop "${PROJECT}"_n${i}
done

echo -e "\n --> All masternodes have been stopped and disabled"
echo -e " To start them again, use command '${white}activate_masternodes_${PROJECT}${nocolor}'"
echo -e " Maintenance crons have been stopped. Restart them with '${white}restore_crons${nocolor}'\n"

rm -f $INSTALLDIR/temp/updating

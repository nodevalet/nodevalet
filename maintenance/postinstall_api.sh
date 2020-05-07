#!/bin/bash

# Set Variables
INSTALLDIR='/var/tmp/nodevalet'
INFODIR='/var/tmp/nvtemp'
LOGFILE='/var/tmp/nodevalet/logs/silentinstall.log'
TRANSMITMN=$(cat $INSTALLDIR/temp/masternode.return)

function final_message() {

    if [ -e $INSTALLDIR/temp/vpsvaletreboot.txt ]; then

        # set hostname variable to the name planted by install script
        if [ -e $INFODIR/vpshostname.info ]
        then HNAME=$(<$INFODIR/vpshostname.info)
        else HNAME=$(hostname)
        fi

        # Schedule bootstrap for 1 minutes from now (after reboot)-- disabled because it doesn't work on DO
        # echo "/var/tmp/nodevalet/maintenance/bootstrap.sh" | at now +1 minutes

        # log successful reboot
        echo -e " $(date +%m.%d.%Y_%H:%M:%S) : Server rebooted successfully " | tee -a "$LOGFILE"
        echo -e "\033[1;37m $(date +%m.%d.%Y_%H:%M:%S) : Server has rebooted after installation \e[0m \n" | tee -a /var/tmp/nodevalet/logs/maintenance.log

        # transmit masternode.return to mother
        curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "'"$TRANSMITMN"'"}' ; echo " "

        # create file to signal cron that reboot has occurred
        touch $INSTALLDIR/temp/installation_complete
        echo -e " SERVER REBOOTED SUCCESSFULLY : $(date +%m.%d.%Y_%H:%M:%S)" | tee -a "$INSTALLDIR/temp/installation_complete"

        # Remove postinstall from rc.local
        sed -i '/postinstall_api.sh/d' /etc/rc.local

        # Add a sequence to interpret the reply as success or fail $?
        rm $INSTALLDIR/temp/vpsvaletreboot.txt

        # create file to signal that bootstrap is running
        touch $INSTALLDIR/temp/bootstrapping

        # Check for bootstrap file and install it if available
        cd $INSTALLDIR/maintenance || exit
        sudo bash bootstrap.sh

        # create file to signal that bootstrap has finished
        rm $INSTALLDIR/temp/bootstrapping

    else :
    fi
}

final_message

exit

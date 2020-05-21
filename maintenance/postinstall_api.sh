#!/bin/bash

# exit with error if not run as root/sudo
if [ "$(id -u)" != "0" ]
then echo -e "\n Please re-run as root or sudo.\n"
    exit 1
fi

# Set Variables
INSTALLDIR='/var/tmp/nodevalet'
INFODIR='/var/tmp/nvtemp'
LOGFILE='/var/tmp/nodevalet/logs/silentinstall.log'
TRANSMITMN=$(cat $INSTALLDIR/temp/masternode.return)

function final_message() {

    if [ -e $INSTALLDIR/temp/vpsvaletreboot.txt ]; then

        # set hostname variable to the name planted by install script
        if [ -e $INFODIR/vps.hostname.info ]
        then HNAME=$(<$INFODIR/vps.hostname.info)
        else HNAME=$(hostname)
        fi

        # Schedule bootstrap for 1 minutes from now (after reboot)-- disabled because it doesn't work on DO
        # echo "/var/tmp/nodevalet/maintenance/bootstrap.sh" | at now +1 minutes

        # log successful reboot
        rm -rf /var/tmp/nodevalet/logs/maintenance.log
        touch /var/tmp/nodevalet/logs/maintenance.log
        echo -e "\033[1;37m $(date +%m.%d.%Y_%H:%M:%S) : Server rebooted successfully " | tee -a "$LOGFILE"
        echo -e "\033[1;37m $(date +%m.%d.%Y_%H:%M:%S) : Server has rebooted after installation \e[0m" | tee -a /var/tmp/nodevalet/logs/maintenance.log

        # transmit masternode.return to mother
        curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "'"$TRANSMITMN"'"}' ; echo " "

        # create file to signal cron that reboot has occurred
        touch $INSTALLDIR/temp/installation_complete
        echo -e " SERVER REBOOTED SUCCESSFULLY : $(date +%m.%d.%Y_%H:%M:%S)" | tee -a "$INSTALLDIR/temp/installation_complete"

        # Remove postinstall from rc.local
        sed -i '/postinstall_api.sh/d' /etc/rc.local

        # Enable SmartStart on subsequent reboots
        echo -e " Enabling SmartStart by adding task to /etc/rc.local \n" | tee -a /var/tmp/nodevalet/logs/maintenance.log
        echo -e "sudo bash /var/tmp/nodevalet/maintenance/smartstart.sh &" >> /etc/rc.local
        sed -i '/exit 0/d' /etc/rc.local
        echo -e "exit 0" >> /etc/rc.local

        # Add a sequence to interpret the reply as success or fail $?
        rm $INSTALLDIR/temp/vpsvaletreboot.txt

        # create file to signal that bootstrap is running
        touch $INSTALLDIR/temp/bootstrapping

        # Check for bootstrap file and install it if available
        cd $INSTALLDIR/maintenance || exit
        sudo bash bootstrap.sh

        # create file to signal that bootstrap has finished
        rm -rf $INSTALLDIR/temp/bootstrapping --force

    else :
    fi
}

final_message

exit

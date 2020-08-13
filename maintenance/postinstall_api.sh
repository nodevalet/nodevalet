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
PROJECT=$(<$INFODIR/vps.coin.info)

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
        echo -e "\033[1;37m $(date +%m.%d.%Y_%H:%M:%S) : Server rebooted successfully \e[0m" | tee -a "$LOGFILE"
        echo -e "\033[1;37m $(date +%m.%d.%Y_%H:%M:%S) : Server has rebooted after installation \e[0m" | tee -a /var/tmp/nodevalet/logs/maintenance.log
     
        # create a script to bump into Sierra mode if detected
        if [ "${PROJECT,,}" = "sierra" ] || [ "${PROJECT,,}" = "dash" ]
        then TRANSMITMN=$(cat $INFODIR/register_prepare.return)
            curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "'"$TRANSMITMN"'"}' ; echo " "
            SLEEPTIME=30
            sleep 30

            # https://api.nodevalet.io/dip3register.php?coin=sierra&hostname=SSMN1-707B-2158-155F-4217&topic=register_prepare&type=output
            APIURL="https://api.nodevalet.io/dip3register.php?coin="
            CURLAPI=$(echo -e "$APIURL$PROJECT&hostname=$HNAME&topic=register_prepare&type=output")

            for ((P=1;P<=60;P++));
            do

            # store NoveValets response in a local file
            curl -s "$CURLAPI" > $INSTALLDIR/temp/API.registerreply.json
            sleep 2

            # read curl API response into variable
            APIRESPONSE=$(cat $INSTALLDIR/temp/API.registerreply.json | jq '.["result"]')

            if [ "${APIRESPONSE}" = "1" ]
            then APIRESPONSE=$(cat $INSTALLDIR/temp/API.registerreply.json | jq '.["message"]')
            break
            else echo -e " NodeValet reports the masternode hasn't activated yet. "
                if [ "${P}" = "60" ]
                then echo " "
                    [ -e $INFODIR/fullauto.info ] && curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Error: Timed out waiting for masternode to start"}' && echo -e " "
                    echo -e "Masternode deployment has timed out after 30 minutes." | tee -a "$LOGFILE"
                    exit 1
                fi
                    echo -e " --> Waiting for $SLEEPTIME seconds before trying again... loop $P"
                    sleep $SLEEPTIME
            fi
            done

            # for:do look was broken with successful response from NodeValet
            echo -e "\033[1;37m $(date +%m.%d.%Y_%H:%M:%S) : $PROJECT masternode started successfully \e[0m" | tee -a "$LOGFILE"
            echo -e "Message is: $APIRESPONSE \n"  | tee -a "$LOGFILE"
            echo -e "$APIRESPONSE" > $INFODIR/vps.protlist.info

            # verify on chain that masternode is started
            # protx list valid | grep <tx hash>
        fi

        # transmit masternode.return to mother
        TRANSMITMN=$(cat $INSTALLDIR/temp/masternode.return)
        curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "'"$TRANSMITMN"'"}' ; echo " "

        # create file to signal cron that installation was completed
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

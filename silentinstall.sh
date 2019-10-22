#!/bin/bash
# Silently install masternodes and insert privkeys

function setup_environment() {
    # Set Variables
    INSTALLDIR='/var/tmp/nodevalet'
    LOGFILE='/var/tmp/nodevalet/logs/silentinstall.log'
    INFODIR='/var/tmp/nvtemp'

    ### define colors ###
    lightred=$'\033[1;31m'  # light red
    red=$'\033[0;31m'  # red
    lightgreen=$'\033[1;32m'  # light green
    green=$'\033[0;32m'  # green
    lightblue=$'\033[1;34m'  # light blue
    blue=$'\033[0;34m'  # blue
    lightpurple=$'\033[1;35m'  # light purple
    purple=$'\033[0;35m'  # purple
    lightcyan=$'\033[1;36m'  # light cyan
    cyan=$'\033[0;36m'  # cyan
    lightgray=$'\033[0;37m'  # light gray
    white=$'\033[1;37m'  # white
    brown=$'\033[0;33m'  # brown
    yellow=$'\033[1;33m'  # yellow
    darkgray=$'\033[1;30m'  # dark gray
    black=$'\033[0;30m'  # black
    nocolor=$'\e[0m' # no color

    # create root/installtemp if it doesn't exist
    if [ ! -d $INSTALLDIR ]
    then mkdir $INSTALLDIR
    else :
    fi

    mkdir $INFODIR
    mkdir $INSTALLDIR/logs
    mkdir $INSTALLDIR/temp
    touch $INSTALLDIR/logs/maintenance.log
    touch $INSTALLDIR/logs/silentinstall.log

    # Create Log File and Begin
    clear
    echo -e " ---------------------------------------------------- " | tee -a "$LOGFILE"
    echo -e " $(date +%m.%d.%Y_%H:%M:%S) : SCRIPT STARTED SUCCESSFULLY " | tee -a "$LOGFILE"
    echo -e " ---------------------------------------------------- " | tee -a "$LOGFILE"
    echo -e " -------- NodeValet.io Masternode Script ------------ " | tee -a "$LOGFILE"
    echo -e " ------------Masternodes Made Easier ---------------- " | tee -a "$LOGFILE"
    echo -e " ---------------------------------------------------- " | tee -a "$LOGFILE"

    # read or set project name
    if [ -s $INFODIR/vpscoin.info ]
    then PROJECT=$(cat $INFODIR/vpscoin.info)
        PROJECTl=${PROJECT,,}
        PROJECTt=${PROJECTl~}
        touch $INFODIR/fullauto.info
        echo -e " Script was invoked by NodeValet and is on full-auto\n" | tee -a "$LOGFILE"
        echo -e " Script was invoked by NodeValet and is on full-auto\n" >> $INFODIR/fullauto.info
        echo -e " Setting Project Name to $PROJECTt : vpscoin.info found" >> $LOGFILE
    else echo -e " Please choose from one of the following supported coins to install:"
        echo -e "    helium | audax | pivx | phore \n"
        echo -e " In one word, which coin are installing today? "
        while :; do
            read -p "  --> " PROJECT
            if [ -d $INSTALLDIR/nodemaster/config/"${PROJECT,,}" ]
            then touch $INFODIR/vpscoin.info
                echo -e "${PROJECT,,}" > $INFODIR/vpscoin.info
                PROJECT=$(cat $INFODIR/vpscoin.info)
                PROJECTl=${PROJECT,,}
                PROJECTt=${PROJECTl~}
                echo -e " Setting Project Name to $PROJECTt : user provided input" >> $LOGFILE
                break
            else echo -e " --> $PROJECT is not supported, try again."
            fi
        done
        # echo -e " \n"
    fi
	
    # set hostname variable to the name planted by install script
    if [ -e $INFODIR/vpshostname.info ]
    then HNAME=$(<$INFODIR/vpshostname.info)
        echo -e " Setting Hostname to $HNAME : vpshostname.info found" >> $LOGFILE
    else HNAME=$(hostname)
        touch $INFODIR/vpshostname.info
        echo -e "$HNAME" > $INFODIR/vpshostname.info
        echo -e " Setting Hostname to $HNAME : read from server hostname" >> $LOGFILE
    fi
    if [ -e $INFODIR/fullauto.info ] ; then curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Your new VPS is online and reporting installation status ..."}' && echo -e " " ; fi
    sleep 6
	
	# read API key if it exists, if not prompt for it
    #if [ -e $INFODIR/vpsapi.info ]
    #then VPSAPI=$(<$INFODIR/vpsapi.info)
    #    echo -e " Setting VPSAPI to $VPSAPI : vpsapi.info found" >> $LOGFILE
	
	#else echo -e "\n Before we can begin, we need to collect your APIKEY."
    #   echo -e " Manually collecting VPSAPI from user" >> $LOGFILE 2>&1
    #    echo -e "   ! ! Please double check your APIKEY for accuracy ! !"
    #    touch $INFODIR/vpsapi.info
           # while :; do
           #     echo -e "${cyan}"
           #    echo -e "\n Please enter your NodeValet API Key."
           #   read -p "  --> " VPSAPI
           #    echo -e "You entered this API Key: ${VPSAPI} "
           #    read -n 1 -s -r -p "  --> Is this correct? y/n  " VERIFY
           #    if [[ $VERIFY == "y" || $VERIFY == "Y" || $VERIFY == "yes" || $VERIFY == "Yes" ]]
           #    then echo -e "${nocolor}" ; break
           #    fi
           #done
           # echo -e "$VPSAPI" >> $INFODIR/vpsapi.info
           # echo -e " -> User API Key is: $VPSAPI" >> $LOGFILE
           # echo -e " \n"
    #fi

    # set mnode daemon name from project.env
    MNODE_DAEMON=$(grep ^MNODE_DAEMON $INSTALLDIR/nodemaster/config/"${PROJECT}"/"${PROJECT}".env)
    echo -e "$MNODE_DAEMON" > $INSTALLDIR/temp/MNODE_DAEMON
    sed -i "s/MNODE_DAEMON=\${MNODE_DAEMON:-\/usr\/local\/bin\///" $INSTALLDIR/temp/MNODE_DAEMON  2>&1
    cat $INSTALLDIR/temp/MNODE_DAEMON | tr -d '[}]' > $INSTALLDIR/temp/MNODE_DAEMON1
    MNODE_DAEMON=$(<$INSTALLDIR/temp/MNODE_DAEMON1)
    cat $INSTALLDIR/temp/MNODE_DAEMON1 > $INSTALLDIR/temp/MNODE_DAEMON ; rm $INSTALLDIR/temp/MNODE_DAEMON1
    echo -e " Setting masternode-daemon to $MNODE_DAEMON" >> $LOGFILE

    # create or assign onlynet from project.env
    ONLYNET=$(grep ^ONLYNET $INSTALLDIR/nodemaster/config/"${PROJECT}"/"${PROJECT}".env)
    echo -e "$ONLYNET" > $INSTALLDIR/temp/ONLYNET
    sed -i "s/ONLYNET=//" $INSTALLDIR/temp/ONLYNET 2>&1
    ONLYNET=$(<$INSTALLDIR/temp/ONLYNET)
    if [ "$ONLYNET" > 0 ]
    then echo -e " Setting network to IPv${ONLYNET} d/t instructions in ${PROJECT}.env" >> $LOGFILE
    else ONLYNET='6'
        echo -e " Setting network to IPv${ONLYNET} d/t no reference in ${PROJECT}.env" >> $LOGFILE
    fi

    # read or assign number of masternodes to install
    if [ -e $INFODIR/vpsnumber.info ]
    then MNS=$(<$INFODIR/vpsnumber.info)
        echo -e " Setting number of masternodes to $MNS : vpsnumber.info found" >> $LOGFILE
        # check memory and set max MNS appropriately then prompt user how many they would like to build
elif [ "$ONLYNET" = 4 ]
    then touch $INFODIR/vpsnumber.info ; MNS=1 ; echo -e "${MNS}" > $INFODIR/vpsnumber.info
        echo -e " Since ONLYNET=4, setting number of masternodes to only allow $MNS" | tee -a "$LOGFILE"
    else NODES=$(grep MemTotal /proc/meminfo | awk '{print $2 / 1024 / 400}')
        MAXNODES=$(echo "$NODES" | awk '{print int($1+0.5)}')
        echo -e "\n This server's memory can safely support $MAXNODES masternodes."
        echo -e " Please enter the number of masternodes to install : "
        while :; do
            read -p "  --> " MNS
            if (($MNS >= 1 && $MNS <= $MAXNODES))
            then echo -e " Setting number of masternodes to $MNS : user provided input" >> $LOGFILE
                touch $INFODIR/vpsnumber.info
                echo -e "${MNS}" > $INFODIR/vpsnumber.info
                break
            else echo -e "\n --> $MNS is not a number between 1 and $MAXNODES, try again."
            fi
        done
    fi

    # create or assign mnprefix
    if [ -s $INFODIR/vpsmnprefix.info ]
    then :
        echo -e " Setting masternode aliases from vpsmnprefix.info file" >> $LOGFILE
    else MNPREFIX=$(hostname)
        echo -e " Generating aliases from hostname ($MNPREFIX) : vpsmnprefix.info not found" >> $LOGFILE
    fi

    # read or collect masternode addresses
    if [ -e $INFODIR/vpsmnaddress.info ]
    then :
        # create a subroutine here to check memory and size MNS appropriately
    else echo -e "\n Before we can begin, we need to collect $MNS masternode addresses."
        echo -e " Manually collecting masternode addresses from user" >> $LOGFILE 2>&1
        echo -e " On your local wallet, generate the masternode addresses and send"
        echo -e " your collateral transactions for masternodes you want to start"
        echo -e " now. You may also add extra addresses even if you have not yet"
        echo -e " funded them, and the script will still create the masternode"
        echo -e " instance which you can later activate from your local wallet."
        echo -e "   ! ! Please double check your addresses for accuracy ! !"
        touch $INFODIR/vpsmnaddress.info
        for ((i=1;i<=$MNS;i++));
        do
            while :; do
                echo -e "${cyan}"
                echo -e "\n Please enter the $PROJECTt address for masternode #$i"
                read -p "  --> " MNADDP
                echo -e "You entered the address: ${MNADDP} "
                read -n 1 -s -r -p "  --> Is this correct? y/n  " VERIFY
                if [[ $VERIFY == "y" || $VERIFY == "Y" || $VERIFY == "yes" || $VERIFY == "Yes" ]]
                then echo -e "${nocolor}" ; break
                fi
            done
            echo -e "$MNADDP" >> $INFODIR/vpsmnaddress.info
            echo -e " -> Masternode $i address is: $MNADDP" >> $LOGFILE
            echo -e " \n"
        done
        echo -e " User manually entered $MNS masternode addresses.\n" >> $LOGFILE 2>&1
    fi

    # query to generate new genkeys or query for user input
    if [ -e $INFODIR/fullauto.info ]
    then : echo -e "\n Genkeys will be automatically generated for $MNS masternodes.\n" >> $LOGFILE 2>&1
    else
        echo -e "\n You can choose to enter your own masternode genkeys or you can let"
        echo -e " your masternode's ${MNODE_DAEMON::-1}-cli generate them for you. Both are"
        echo -e " equally secure, but it's faster if your server does it for you."
        echo -e " (An example of when you would want to enter them yourself would"
        echo -e " be if you are trying to migrate running masternodes to this VPS)\n"
        read -p " Would you like your server to generate genkeys for you? y/n  " GETGENKEYS
        echo -e "${nocolor}"

        while [ "${GETGENKEYS,,}" != "yes" ] && [ "${GETGENKEYS,,}" != "no" ] && [ "${GETGENKEYS,,}" != "y" ] && [ "${GETGENKEYS,,}" != "n" ]; do
            echo -e "${lightred}"
            read -p " --> I don't understand. Enter 'y' for yes or 'n' for no: " GETGENKEYS
            echo -e "${nocolor}"
        done

        if [ "${GETGENKEYS,,}" = "no" ] || [ "${GETGENKEYS,,}" = "n" ]
        then touch $INSTALLDIR/temp/genkeys
            echo -e " User selected to manually enter genkeys for $MNS masternodes." >> $LOGFILE 2>&1
            touch $INSTALLDIR/temp/owngenkeys
            for ((i=1;i<=$MNS;i++));
            do
                while :; do
                    echo -e "${cyan}"
                    echo -e "\n\n Please enter the $PROJECTt genkey for masternode #$i"
                    read -p "  --> " UGENKEY
                    echo -e "You entered the address: ${UGENKEY} "
                    read -n 1 -s -r -p "  --> Is this correct? y/n  " VERIFY
                    if [[ $VERIFY == "y" || $VERIFY == "Y" || $VERIFY == "yes" || $VERIFY == "Yes" ]]
                    then echo -e "${nocolor}"
                        echo -e "$UGENKEY" >> $INSTALLDIR/temp/genkeys
                        echo -e " -> Masternode $i genkey is: $UGENKEY" >> $LOGFILE
                        echo -e " \n"
                        echo -e "$(sed -n ${i}p $INSTALLDIR/temp/genkeys)" > $INSTALLDIR/temp/GENKEY$i
                        break
                    fi
                done
            done
            echo -e " User manually entered genkeys for $MNS masternodes.\n" >> $LOGFILE 2>&1
        else echo -e " User selected to have this VPS create genkeys for $MNS masternodes.\n" >> $LOGFILE 2>&1
        fi
    fi

    # create or assign customssh
    if [ -s $INFODIR/vpssshport.info ]
    then SSHPORT=$(<$INFODIR/vpssshport.info)
        echo -e " Setting SSHPORT to $SSHPORT as found in vpsshport.info \n" >> $LOGFILE
    else
        echo -e "${cyan}"
        echo -e "\n Your current SSH port is : $(sed -n -e '/^Port /p' /etc/ssh/sshd_config) "
        echo -e " Enter a custom port for SSH between 11000 and 65535 or use 22 : "
        while :; do
            read -p "  --> " SSHPORT
            [[ $SSHPORT =~ ^[0-9]+$ ]] || { echo -e "${lightred}";echo -e " --> Try harder, that's not even a number.";echo -e "${nocolor}";continue; }
            if (($SSHPORT >= 11000 && $SSHPORT <= 65535)); then break
            elif [ "$SSHPORT" = 22 ]; then break
            else echo -e "${lightred}"
                echo -e "\n --> That number is out of range, try again. \n"
                echo -e "${nocolor}"
            fi
        done
        echo -e " Setting SSHPORT to $SSHPORT : user provided input \n" >> $LOGFILE
        touch $INFODIR/vpssshport.info
        echo "$SSHPORT" >> $INFODIR/vpssshport.info
    fi
    echo -e " \n"
    echo -e " I am going to install $MNS $PROJECTt masternodes on this VPS \n" >> $LOGFILE
    echo -e "\n"

    # Pull BLOCKEXP from $PROJECT.env
    BLOCKEX=$(grep ^BLOCKEXP $INSTALLDIR/nodemaster/config/"$PROJECT"/"$PROJECT".env)
    if [ -n "$BLOCKEX" ]
    then echo "$BLOCKEX" > $INSTALLDIR/temp/BLOCKEXP
        sed -i "s/BLOCKEXP=//" $INSTALLDIR/temp/BLOCKEXP
        BLOCKEXP=$(<$INSTALLDIR/temp/BLOCKEXP)
        echo -e " Block Explorer set to :" | tee -a "$LOGFILE"
        echo -e " $BLOCKEXP \n" | tee -a "$LOGFILE"
    else echo -e "No block explorer was identified in $PROJECT.env \n" | tee -a "$LOGFILE"
    fi

    # enable softwrap so masternode.conf file can be easily copied
    sed -i "s/# set softwrap/set softwrap/" /etc/nanorc >> $LOGFILE 2>&1
}

function add_cron() {
    echo -e "\n $(date +%m.%d.%Y_%H:%M:%S) : Adding crontabs"  | tee -a "$LOGFILE"
    chmod 0700 $INSTALLDIR/*.sh
    chmod 0700 $INSTALLDIR/maintenance/*.sh
    echo -e "  --> Run post install script after first reboot"  | tee -a "$LOGFILE"
    (crontab -l ; echo "*/1 * * * * $INSTALLDIR/maintenance/postinstall_api.sh") | crontab - 2>/dev/null
    echo -e "  --> Make sure all daemon are running every 5 minutes"  | tee -a "$LOGFILE"
    (crontab -l ; echo "*/5 * * * * $INSTALLDIR/maintenance/makerun.sh") | crontab -
    echo -e "  --> Check for stuck blocks every 30 minutes"  | tee -a "$LOGFILE"
    (crontab -l ; echo "1,31 * * * * $INSTALLDIR/maintenance/checkdaemon.sh") | crontab -
    echo -e "  --> Check for & reboot if needed to install updates every 10 hours"  | tee -a "$LOGFILE"
    (crontab -l ; echo "59 */10 * * * $INSTALLDIR/maintenance/rebootq.sh") | crontab -
    echo -e "  --> Check for wallet updates every 48 hours"  | tee -a "$LOGFILE"
    (crontab -l ; echo "2 */48 * * * $INSTALLDIR/maintenance/autoupdate.sh") | crontab -
    echo -e "  --> Clear daemon debug logs weekly to prevent clog \n"  | tee -a "$LOGFILE"
    (crontab -l ; echo "@weekly $INSTALLDIR/maintenance/cleardebuglog.sh") | crontab -

    # add system link to common maintenance scripts so they can be accessed more easily
    sudo ln -s $INSTALLDIR/maintenance/checksync.sh /usr/local/bin/checksync
    sudo ln -s $INSTALLDIR/maintenance/autoupdate.sh /usr/local/bin/autoupdate
    sudo ln -s $INSTALLDIR/maintenance/checkdaemon.sh /usr/local/bin/checkdaemon
    sudo ln -s $INSTALLDIR/maintenance/makerun.sh /usr/local/bin/makerun
    sudo ln -s $INSTALLDIR/maintenance/rebootq.sh /usr/local/bin/rebootq
    sudo ln -s $INSTALLDIR/maintenance/getinfo.sh /usr/local/bin/getinfo
    sudo ln -s $INSTALLDIR/maintenance/resync.sh /usr/local/bin/resync
    sudo ln -s $INSTALLDIR/maintenance/showlog.sh /usr/local/bin/showlog
    sudo ln -s $INSTALLDIR/maintenance/showmlog.sh /usr/local/bin/showmlog
    sudo ln -s $INSTALLDIR/maintenance/killswitch.sh /usr/local/bin/killswitch
    sudo ln -s $INSTALLDIR/maintenance/masternodestatus.sh /usr/local/bin/masternodestatus
    # sudo ln -s $INSTALLDIR/maintenance/holy_handgrenade.sh /usr/local/bin/holy_handgrenade
}

function silent_harden() {
    if [ -e /var/log/server_hardening.log ]
    then echo -e " This server seems to already be hardened, skipping this part \n" | tee -a "$LOGFILE"
    else echo -e " This server is not yet secure, running VPS Hardening script" | tee -a "$LOGFILE"
        echo -e " Server hardening log is saved at /var/tmp/nodevalet/logs/vps-harden.log \n" | tee -a "$LOGFILE"
        cd $INSTALLDIR/vps-harden || exit
        bash get-hard.sh
    fi
    echo -e "Installing jq and jp2a and unzip packages" | tee -a "$LOGFILE"
    apt-get -qqy -o=Dpkg::Use-Pty=0 -o=Acquire::ForceIPv4=true install jq jp2a unzip | tee -a "$LOGFILE"

    echo -e "Inserting random Chuck Norris joke to avoid excessive blandness\n" | tee -a "$LOGFILE"
    curl -s "http://api.icndb.com/jokes/random" | jq '.value.joke' | tee -a "$LOGFILE"
}

function install_mns() {
    if [ -e /etc/masternodes/"$PROJECT_n1".conf ]
    then touch $INSTALLDIR/temp/mnsexist
        echo -e "Pre-existing masternodes detected; no changes to them will be made" > $INSTALLDIR/mnsexist
        echo -e "Masternodes seem to already be installed, skipping this part" | tee -a "$LOGFILE"
    else
        cd $INSTALLDIR/nodemaster || exit
        echo -e "Invoking local Nodemaster's VPS script" | tee -a "$LOGFILE"
        # echo -e "Downloading Nodemaster's VPS script (from heliumchain repo)" | tee -a "$LOGFILE"
        # sudo git clone https://github.com/heliumchain/vps.git && cd vps
        echo -e "Launching Nodemaster using bash install.sh -n $ONLYNET -p $PROJECT" -c "$MNS" | tee -a "$LOGFILE"
        sudo bash install.sh -n $ONLYNET -p "$PROJECT" -c "$MNS"
        echo -e "activating_masternodes_$PROJECT" | tee -a "$LOGFILE"
        activate_masternodes_"$PROJECT" echo -e | tee -a "$LOGFILE"
        # echo -e "Waiting a couple of seconds for daemons to start..." | tee -a "$LOGFILE"
		# sleep 2  ---- this line seems to break things because the process dies too quickly

        # check if $PROJECTd was built correctly and started
        ps -A | grep "$MNODE_DAEMON" >> $INSTALLDIR/temp/"${PROJECT}"Ds
        cat $INSTALLDIR/temp/"${PROJECT}"Ds >> $LOGFILE
        if [ -s $INSTALLDIR/temp/"${PROJECT}"Ds ]
        then echo -e "\nIt looks like VPS install script completed and ${MNODE_DAEMON} is running... " | tee -a "$LOGFILE"
            # report back to mother
            if [ -e $INFODIR/fullauto.info ] ; then echo -e "Reporting ${MNODE_DAEMON} build success to mother" | tee -a "$LOGFILE" ; curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Process '"$MNODE_DAEMON"' has started ..."}' && echo -e " " ; fi
        else echo -e "It looks like VPS install script failed, ${MNODE_DAEMON} is not running... " | tee -a "$LOGFILE"
            echo -e "Aborting installation, can't install masternodes without ${MNODE_DAEMON}" | tee -a "$LOGFILE"
            # report error, exit script maybe or see if it can self-correct
            echo -e "Reporting ${MNODE_DAEMON} build failure to mother" | tee -a "$LOGFILE"
            if [ -e $INFODIR/fullauto.info ] ; then curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Error: '"$MNODE_DAEMON"' failed to build or start"}' && echo -e " " ; fi
            exit
        fi
    fi
}

function get_genkeys() {
    # Iteratively create all masternode variables for masternode.conf
    # Do not break any pre-existing masternodes
    if [ -s $INSTALLDIR/temp/mnsexist ]
    then echo -e "Skipping get_genkeys function due to presence of $INSTALLDIR/mnsexist" | tee -a "$LOGFILE"
        echo -e "Reporting ${MNODE_DAEMON} build failure to mother" | tee -a "$LOGFILE"
        if [ -e $INFODIR/fullauto.info ] ; then curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Error: Masternodes already exist on this VPS; stopping install."}' && echo -e " " ; fi
        exit
    else
        # Create a file containing all masternode genkeys
        # echo -e "Saving genkey(s) to $INSTALLDIR/temp/genkeys \n"  | tee -a "$LOGFILE"
        touch $INSTALLDIR/temp/genkeys

        # create initial masternode.conf file and populate with notes
        touch $INSTALLDIR/masternode.conf
        echo -e "Creating $INSTALLDIR/masternode.conf file to collect user settings" | tee -a "$LOGFILE"
        cat <<EOT >> $INSTALLDIR/masternode.conf
#######################################################
# Masternode.conf settings to paste into Local Wallet #
#######################################################
EOT
        echo -e "Creating masternode.conf variables and files for $MNS masternodes" | tee -a "$LOGFILE"

        for ((i=1;i<=$MNS;i++));
        do
            for ((P=1;P<=35;P++));
            do
                # create masternode genkeys (smart is special "smartnodes")
                if [ -e $INSTALLDIR/temp/owngenkeys ] ; then :
                elif [ "${PROJECT,,}" = "smart" ] ; then /usr/local/bin/"${MNODE_DAEMON::-1}"-cli -conf=/etc/masternodes/"${PROJECT}"_n1.conf smartnode genkey >> $INSTALLDIR/temp/genkeys
			    else /usr/local/bin/"${MNODE_DAEMON::-1}"-cli -conf=/etc/masternodes/"${PROJECT}"_n1.conf masternode genkey >> $INSTALLDIR/temp/genkeys ; fi
                echo -e "$(sed -n ${i}p $INSTALLDIR/temp/genkeys)" > $INSTALLDIR/temp/GENKEY$i

                if [ "${PROJECT,,}" = "smart" ] ; then echo "smartnodeprivkey=" > $INSTALLDIR/temp/MNPRIV1
				else echo "masternodeprivkey=" > $INSTALLDIR/temp/MNPRIV1 ; fi
                KEYXIST=$(<$INSTALLDIR/temp/GENKEY$i)

                # add extra pause for wallets that are slow to start
                if [ "${PROJECT,,}" = "polis" ] ; then SLEEPTIME=15 ; else SLEEPTIME=3 ; fi

                # check if GENKEY variable is empty; if so stop script and report error
                if [ ${#KEYXIST} = "0" ]
                then echo -e " ${MNODE_DAEMON::-1}-cli couldn't create genkey $i; engine likely still starting up" | tee -a "$LOGFILE"
                    echo -e " --> Waiting for $SLEEPTIME seconds before trying again... loop $P" | tee -a "$LOGFILE"
                    sleep $SLEEPTIME
                else break
                fi

                if [ ${#KEYXIST} = "0" ] && [ "${P}" = "35" ]
                then echo " "
                    if [ -e $INFODIR/fullauto.info ] ; then curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Error: Could not generate masternode genkeys"}' && echo -e " " ; fi
                    echo -e "Problem creating masternode $i. Could not obtain masternode genkey." | tee -a "$LOGFILE"
                    echo -e "I patiently tried 35 times but something isn't working correctly.\n" | tee -a "$LOGFILE"
                    exit
                fi
            done
        done

        for ((i=1;i<=$MNS;i++));
        do
            # get or iterate mnprefixes
            if [ -s $INFODIR/vpsmnprefix.info ] ; then
                echo -e "$(sed -n ${i}p $INFODIR/vpsmnprefix.info)" >> $INSTALLDIR/temp/mnaliases
            else echo -e "${MNPREFIX}-MN$i" >> $INSTALLDIR/temp/mnaliases
            fi

            # create masternode prefix files
            echo -e "$(sed -n ${i}p $INSTALLDIR/temp/mnaliases)" >> $INSTALLDIR/temp/MNALIAS$i

            # create masternode address files
            echo -e "$(sed -n ${i}p $INFODIR/vpsmnaddress.info)" > $INSTALLDIR/temp/MNADD$i

            # append "masternodeprivkey="
            paste $INSTALLDIR/temp/MNPRIV1 $INSTALLDIR/temp/GENKEY$i > $INSTALLDIR/temp/GENKEY${i}FIN
            tr -d '[:blank:]' < $INSTALLDIR/temp/GENKEY${i}FIN > $INSTALLDIR/temp/MNPRIVKEY$i

            # assign GENKEYVAR to the full line masternodeprivkey=xxxxxxxxxx
            GENKEYVAR=$(cat $INSTALLDIR/temp/MNPRIVKEY$i)

            # insert new genkey into project_n$i.conf files (special case for smartnodes)
            if [ "${PROJECT,,}" = "smart" ] ; then
                sed -i "s/^smartnodeprivkey=.*/$GENKEYVAR/" /etc/masternodes/"${PROJECT}"_n$i.conf
                masternodeprivkeyafter=$(grep ^smartnodeprivkey /etc/masternodes/"${PROJECT}"_n$i.conf)
                echo -e " Privkey in ${PROJECT}_n$i.conf after sub is : " >> $LOGFILE
                echo -e " $masternodeprivkeyafter" >> $LOGFILE 
			else
                sed -i "s/^masternodeprivkey=.*/$GENKEYVAR/" /etc/masternodes/"${PROJECT}"_n$i.conf
                masternodeprivkeyafter=$(grep ^masternodeprivkey /etc/masternodes/"${PROJECT}"_n$i.conf)
                echo -e " Privkey in ${PROJECT}_n$i.conf after sub is : " >> $LOGFILE
                echo -e " $masternodeprivkeyafter" >> $LOGFILE
            fi

            # create file with IP addresses
            sed -n -e '/^bind/p' /etc/masternodes/"${PROJECT}"_n$i.conf >> $INSTALLDIR/temp/mnipaddresses

            # remove "bind=" from mnipaddresses
            sed -i "s/bind=//" $INSTALLDIR/temp/mnipaddresses 2>&1

            # the next line produces the IP addresses for this masternode
            echo -e "$(sed -n ${i}p $INSTALLDIR/temp/mnipaddresses)" > $INSTALLDIR/temp/IPADDR$i

            PUBLICIP=$(sudo /usr/bin/wget -q -O - http://ipv4.icanhazip.com/ | /usr/bin/tail)
            PRIVATEIP=$(sudo ifconfig $(route | grep default | awk '{ print $8 }') | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}')

            # to enable functionality in headless mode for LAN connected VPS, replace private IP with public IP
            if [ "$PRIVATEIP" != "$PUBLICIP" ]
            then sed -i "s/$PRIVATEIP/$PUBLICIP/" $INSTALLDIR/temp/IPADDR$i
                echo -e " Your masternode is on a LAN, replacing $PRIVATEIP with $PUBLICIP " | tee -a "$LOGFILE"
            fi

            # Check for presence of txid and, if present, use it for txid/txidx
            if [ -e $INFODIR/vpsmntxdata.info ]
            then echo -e "$(sed -n ${i}p $INFODIR/vpsmntxdata.info)" > $INSTALLDIR/temp/TXID$i
               TX=$(echo $(cat $INSTALLDIR/temp/TXID$i))
                echo -e "$TX" >> $INSTALLDIR/temp/txid
                echo -e "$TX" > $INSTALLDIR/temp/TXID$i
				echo -e " Read TXID for MN$i from vpsmntxdata.info; set to $TX " >> $LOGFILE
                
			# Query nodevalet block explorer for collateral transaction
            else echo -e "Querying NodeValet for collateral txid $i"
				echo -e "    Building query; "
			    curl -s "$BLOCKEXP$(cat $INSTALLDIR/temp/MNADD$i)&KEY=$VPSAPI" | jq '.["txid","txindex"]' | tr -d '["]' > $INSTALLDIR/temp/TXID$i
                TX=$(echo $(cat $INSTALLDIR/temp/TXID$i))
                echo -e "$TX" >> $INSTALLDIR/temp/txid
                echo -e "$TX" > $INSTALLDIR/temp/TXID$i
				echo -e " NodeValet API returned $TX as txid for masternode $i " >> $LOGFILE
				
				# add a line here which will generate a message or error if txid is still not found
				
				
				
				
				
            fi

            # replace null with txid info
            sed -i "s/.*null null/collateral_output_txid tx/" $INSTALLDIR/temp/txid >> $INSTALLDIR/temp/txid 2>&1
            sed -i "s/.*null null/collateral_output_txid tx/" $INSTALLDIR/temp/TXID$i >> $INSTALLDIR/temp/TXID$i 2>&1

            # merge all vars into masternode.conf
            echo "|" > $INSTALLDIR/temp/DELIMETER

            # merge data fields to prepare masternode.return file
            paste -d '|' $INSTALLDIR/temp/MNALIAS$i $INSTALLDIR/temp/IPADDR$i $INSTALLDIR/temp/GENKEY$i $INSTALLDIR/temp/TXID$i >> $INSTALLDIR/temp/masternode.line$i

            # if line contains collateral_tx then start the line with #
            sed -e '/collateral_output_txid tx/ s/^#*/#/' -i $INSTALLDIR/temp/masternode.line$i >> $INSTALLDIR/temp/masternode.line$i 2>&1
            # prepend line with delimeter
            paste -d '|' $INSTALLDIR/temp/DELIMETER $INSTALLDIR/temp/masternode.line$i >> $INSTALLDIR/temp/masternode.all

            # create the masternode.conf output that is returned to consumer
            paste -d ' ' $INSTALLDIR/temp/MNALIAS$i $INSTALLDIR/temp/IPADDR$i $INSTALLDIR/temp/GENKEY$i $INSTALLDIR/temp/TXID$i >> $INSTALLDIR/masternode.conf

            # declutter ; take out trash
            rm $INSTALLDIR/temp/GENKEY${i}FIN ; rm $INSTALLDIR/temp/GENKEY$i ; rm $INSTALLDIR/temp/IPADDR$i ; rm $INSTALLDIR/temp/MNADD$i
            rm $INSTALLDIR/temp/MNALIAS$i ; rm $INSTALLDIR/temp/TXID$i ; rm $INSTALLDIR/temp/"${PROJECT}"Ds --force ; rm $INSTALLDIR/temp/DELIMETER
            rm $INSTALLDIR/0 --force

            echo -e " --> Completed masternode $i loop, moving on..."  | tee -a "$LOGFILE"			
        done
        # echo -e " \n" | tee -a "$LOGFILE"

        # comment out lines that contain "collateral_output_txid tx" in masternode.conf
        sed -e '/collateral_output_txid tx/ s/^#*/# /' -i $INSTALLDIR/masternode.conf >> $INSTALLDIR/masternode.conf 2>&1

        if [ -e $INFODIR/fullauto.info ] ; then echo -e "Converting masternode.conf to one delineated line for mother" | tee -a "$LOGFILE" ; fi
        # convert masternode.conf to one delineated line separated using | and ||
        echo "complete" > $INSTALLDIR/temp/complete

        # comment out lines that contain no txid or index
        # sed -i "s/.*collateral_output_txid tx/.*collateral_output_txid tx/" $INSTALLDIR/txid >> $INSTALLDIR/txid 2>&1

        # replace necessary spaces with + temporarily
        sed -i 's/ /+/g' $INSTALLDIR/temp/masternode.all
        # merge "complete" line with masternode.all file and remove line breaks (\n)
        paste -s $INSTALLDIR/temp/complete $INSTALLDIR/temp/masternode.all |  tr -d '\n' > $INSTALLDIR/temp/masternode.1
        tr -d '[:blank:]' < $INSTALLDIR/temp/masternode.1 > $INSTALLDIR/temp/masternode.return
        sed -i 's/+/ /g' $INSTALLDIR/temp/masternode.return

        # append masternode.conf file
        cat <<EOT >> $INSTALLDIR/masternode.conf
#######################################################
# This file was automatically generated by Node Valet #
#######################################################
EOT

        # round 2: cleanup and declutter
        echo -e "Cleaning up clutter and taking out trash... \n" | tee -a "$LOGFILE"
        rm $INSTALLDIR/temp/complete --force		;	rm $INSTALLDIR/temp/masternode.all --force
        rm $INSTALLDIR/temp/masternode.1 --force	;	rm $INSTALLDIR/temp/masternode.l* --force
        rm $INSTALLDIR/temp/DONATION --force		;	rm $INSTALLDIR/temp/DONATEADDR --force
        rm $INSTALLDIR/temp/txid --force		;	rm $INSTALLDIR/temp/mnaliases --force
        rm $INSTALLDIR/temp/"${PROJECT}"Ds --force	;	rm $INSTALLDIR/temp/MNPRIV* --force
        rm $INSTALLDIR/temp/ONLYNET --force

        clear
        echo -e "This is the contents of your file $INSTALLDIR/masternode.conf \n" | tee -a "$LOGFILE"
        cat $INSTALLDIR/masternode.conf | tee -a "$LOGFILE"
        echo -e "\n"  >> "$LOGFILE"

        if [ ! -s $INFODIR/fullauto.info ]
        then cp $INSTALLDIR/maintenance/postinstall_api.sh /etc/init.d/
            update-rc.d postinstall_api.sh defaults  2>/dev/null
            echo -e " Please follow the steps below to complete your masternode setup: "
            echo -e " 1. Please copy the above file and paste it into the masternode.conf "
            echo -e "    file on your local wallet. (insert txid info to end of each line) "
            echo -e " 2. Reboot the local wallet: type 'reboot' to reboot this VPS and "
            echo -e "    begin syncing the blockchain. "
            echo -e " 3. One the VPS has rebooted successfully, restart your local wallet, "
            echo -e "    and then you may click Start Missing to start your new masternodes. "
            echo -e " 4. If starting any masternodes fails, you may need to start them from "
            echo -e "    debug console using 'startmasternode alias 0 MN1'  where you replace "
            echo -e "    MN1 with the  alias of your masternode. This is due to a quirk in "
            echo -e "    the wallet that doesn't always recognize IPv6 addresses. \n"
            read -n 1 -s -r -p "  --- Please press any key to reboot ---" ANYKEY
    else echo -e "Fullauto detected, skipping masternode.conf display"  >> "$LOGFILE" ;fi
    fi
}

function install_binaries() {

#make special accomodations for coins that build weird, require oddball dependencies, or use sloppy code
if [ "${PROJECT,,}" = "bitsend" ]
then echo -e "Bitsend detected, initiating funky installation process...\n"
# insert specific steps here
add-apt-repository -y ppa:bitcoin/bitcoin
apt-get -o=Dpkg::Use-Pty=0 -o=Acquire::ForceIPv4=true update
apt-get -qqy -o=Dpkg::Use-Pty=0 -o=Acquire::ForceIPv4=true install libboost-system1.58.0 libboost1.58-all-dev libdb4.8++ libdb4.8 libdb4.8-dev libdb4.8++-dev libevent-pthreads-2.0-5
fi

#check for binaries and install if found
echo -e "\nAttempting to download and install $PROJECTt binaries from:"  | tee -a "$LOGFILE"

	# Pull GITAPI_URL from $PROJECT.env
	GIT_API=`grep ^GITAPI_URL $INSTALLDIR/nodemaster/config/$PROJECT/$PROJECT.env`
	if [ -n $GIT_API ] ; then 
	echo "$GIT_API" > $INSTALLDIR/temp/GIT_API
	sed -i "s/GITAPI_URL=//" $INSTALLDIR/temp/GIT_API
	GITAPI_URL=$(<$INSTALLDIR/temp/GIT_API)
	echo -e "$GITAPI_URL" | tee -a "$LOGFILE"
	
# Try and install Binaries now	
# Pull GITSTRING from $PROJECT.gitstring
GITSTRING=`cat $INSTALLDIR/nodemaster/config/${PROJECT}/${PROJECT}.gitstring`

mkdir $INSTALLDIR/temp/bin
cd $INSTALLDIR/temp/bin

curl -s $GITAPI_URL \
       	| grep browser_download_url \
	| grep $GITSTRING \
	| cut -d '"' -f 4 \
	| wget -qi -
TARBALL="$(find . -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -f2- -d" ")"

        if [[ $TARBALL == *.gz ]]
	then tar -xzf $TARBALL
	else unzip $TARBALL
	fi
rm -f $TARBALL
cd  "$(\ls -1dt ./*/ | head -n 1)"
find . -mindepth 2 -type f -print -exec mv {} . \;
cp ${PROJECT}* '/usr/local/bin'
cd ..
rm -r -f *
cd
cd /usr/local/bin
chmod 777 ${PROJECT}*
	
	else
	echo -e "Cannot download binaries; no GITAPI_URL was detected \n" | tee -a "$LOGFILE"
	fi

# check if binaries already exist, skip installing crypto packages if they aren't needed
dEXIST=`ls /usr/local/bin | grep ${MNODE_DAEMON}`

if [ "$dEXIST" = "${MNODE_DAEMON}" ]
then echo -e "Binaries for ${PROJECTt} were downloaded and installed \n"   | tee -a "$LOGFILE"
curl -s $GITAPI_URL \
      | grep tag_name > $INSTALLDIR/temp/currentversion
     
else echo -e "Binaries for ${PROJECTt} could not be downloaded \n"  | tee -a "$LOGFILE"
fi
}

function restart_server() {
    echo -e " \n"
    echo -e "Going to restart server to complete installation... " | tee -a "$LOGFILE"
    cp $INSTALLDIR/maintenance/postinstall_api.sh /etc/init.d/
    update-rc.d postinstall_api.sh defaults  2>/dev/null
    shutdown -r now "Server is going down for upgrade."
}

# This is where the script actually starts

setup_environment
# if [ -e $INFODIR/fullauto.info ] ; then curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Beginning Installation Script..."}' && echo -e " " ; fi
# moved curl update commands into get-hard.sh to provide better detail

silent_harden

if [ -e $INFODIR/fullauto.info ] ; then curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Downloading '"$PROJECTt"' Binaries ..."}' && echo -e " " ; fi
install_binaries

if [ -e $INFODIR/fullauto.info ] ; then curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Creating '"$MNS"' '"$PROJECTt"' Masternodes using Nodemaster VPS script ..."}' && echo -e " " ; fi
install_mns

add_cron

if [ -e $INFODIR/fullauto.info ] ; then curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Configuring '"$MNS"' '"$PROJECTt"' Masternodes ..."}' && echo -e " " ; fi
get_genkeys

if [ -e $INFODIR/fullauto.info ] ; then curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Masternode Configuration is Complete ..."}' && echo -e " " ; fi

# create file to signal cron that reboot has occurred
touch $INSTALLDIR/temp/vpsvaletreboot.txt
if [ -e $INFODIR/fullauto.info ] ; then curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Restarting Server to Finalize Installation ..."}' && echo -e " " ; fi
restart_server

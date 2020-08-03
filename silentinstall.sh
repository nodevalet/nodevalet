#!/bin/bash

# exit with error if not run as root/sudo
if [ "$(id -u)" != "0" ]
then echo -e "\n Please re-run as root or sudo.\n"
    exit 1
fi

# install curl & jq
echo -e "\n\033[1;36mPlease wait a moment while we install 'curl' and 'jq'...\n\e[0m"
sudo apt-get update > /dev/null 2>&1
sudo apt-get -qqy -o=Dpkg::Use-Pty=0 -o=Acquire::ForceIPv4=true install curl jq > /dev/null 2>&1

function setup_environment() {
    # Set Variables
    INSTALLDIR='/var/tmp/nodevalet'
    LOGFILE='/var/tmp/nodevalet/logs/silentinstall.log'
    INFODIR='/var/tmp/nvtemp'
    # enable 'showlog' command ASAP
    sudo ln -s $INSTALLDIR/maintenance/showlog.sh /usr/local/bin/showlog
    chmod 0700 $INSTALLDIR/maintenance/showlog.sh

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
    mkdir $INSTALLDIR
    mkdir $INFODIR
    mkdir $INSTALLDIR/logs
    mkdir $INSTALLDIR/temp
    touch $INSTALLDIR/logs/maintenance.log
    touch $INSTALLDIR/logs/silentinstall.log

    # create rc.local if it does not exist
    if [ -s /etc/rc.local ]
    then :
    else cat <<EOTRC > /etc/rc.local
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

exit 0

EOTRC
        chmod 777 /etc/rc.local
    fi

    # Create Log File and Begin
    clear
    echo -e "${white} ################################################################" | tee -a "$LOGFILE"
    echo -e " #    _   _           _    __     __    _      _     _          #" | tee -a "$LOGFILE"
    echo -e " #   | \ | | ___   __| | __\ \   / /_ _| | ___| |_  (_) ___     #" | tee -a "$LOGFILE"
    echo -e " #   |  \| |/ _ \ / _\` |/ _ \ \ / / _\` | |/ _ \ __| | |/ _ \    #" | tee -a "$LOGFILE"
    echo -e " #   | |\  | (_) | (_| |  __/\ V / (_| | |  __/ |_ _| | (_) |   #" | tee -a "$LOGFILE"
    echo -e " #   |_| \_|\___/ \__,_|\___| \_/ \__,_|_|\___|\__(_)_|\___/    #" | tee -a "$LOGFILE"
    echo -e " #                                 Masternodes Made Easier      #" | tee -a "$LOGFILE"
    echo -e " ################################################################" | tee -a "$LOGFILE"
    echo -e " ${yellow}------------------------------------------------ " | tee -a "$LOGFILE"
    echo -e " $(date +%m.%d.%Y_%H:%M:%S) : BEGIN INSTALLATION SCRIPT " | tee -a "$LOGFILE"
    echo -e " ------------------------------------------------ ${nocolor}\n" | tee -a "$LOGFILE"
}

#####################
###  GATHER INFO  ###
#####################
function gather_info() {
    # read or set project name
    if [ -s $INFODIR/vps.sshport.info ]
    then PROJECT=$(cat $INFODIR/vps.coin.info)
        PROJECTl=${PROJECT,,}
        PROJECTt=${PROJECTl~}
        touch $INFODIR/fullauto.info
        echo -e "${nocolor} Script was invoked by NodeValet and is on full-auto\n" | tee -a "$LOGFILE"
        echo -e " Script was invoked by NodeValet and is on full-auto\n" >> $INFODIR/fullauto.info
        echo -e " Setting Project Name to $PROJECTt : vps.coin.info found" >> $LOGFILE
    else echo -e " ${lightcyan}We are pleased that you have chosen to let NodeValet configure your VPS."
        echo -e " This interactive script will first prompt you for information about your"
        echo -e " setup. Then it will update your VPS and securely install the masternodes.\n"
        echo -e " In most cases, this script will function correctly on supported VPS"
        echo -e " platforms without extra steps. Some providers require extra care.\n"
        echo -e " If you are running on${yellow} Contabo${lightcyan}, you must run the command${yellow} enable_ipv6"
        echo -e "${lightcyan} and reboot your VPS before you proceed.${cyan}"
        while :; do
            echo -e "\n"
            read -n 1 -s -r -p " Are you ready to continue the installation now? y/n  " INSTALLNOW
            if [[ ${INSTALLNOW,,} == "y" || ${INSTALLNOW,,} == "Y" || ${INSTALLNOW,,} == "N" || ${INSTALLNOW,,} == "n" ]]
            then
                break
            fi
        done
        echo -e "${nocolor}"
        if [ "${INSTALLNOW,,}" = "Y" ] || [ "${INSTALLNOW,,}" = "y" ]
        then  clear
            echo -e "\n ${yellow}Great; let's proceed with installation now... ${nocolor}\n"
        else echo -e "\n ${lightred}Exiting script per user request, re-run when ready.${nocolor}\n"
            exit 1
        fi

        # check if VPS supports IPv6
        [ -f /proc/net/if_inet6 ] && echo -e "${lightgreen} It looks like your system supports IPv6. This is good!\n" || echo -e "${lightred} IPv6 support was not found! Look into this if the script fails.${nocolor}\n"

        echo -e "${white} Please choose from one of the following supported coins to install:\n${nocolor}"
        echo -e "${lightpurple}    audax | phore | pivx | squorum | mue${nocolor}\n"
        echo -e "${lightpurple}    sierra | stakecube | wagerr | smart    ${nocolor}\n"
        echo -e "${cyan} In one word, which coin are installing today? ${nocolor}"
        while :; do
            read -p "  --> " PROJECT
            if [ -d $INSTALLDIR/nodemaster/config/"${PROJECT,,}" ]
            then touch $INFODIR/vps.coin.info
                echo -e "${PROJECT,,}" > $INFODIR/vps.coin.info
                PROJECT=$(cat $INFODIR/vps.coin.info)
                PROJECTl=${PROJECT,,}
                PROJECTt=${PROJECTl~}
                echo -e " Setting Project Name to $PROJECTt : user provided input" >> $LOGFILE
                break
            else echo -e " ${lightred}--> $PROJECT is not supported, try again.${nocolor}"
            fi
        done
    fi

    # set hostname variable to the name planted by install script
    if [ -e $INFODIR/vps.hostname.info ]
    then HNAME=$(<$INFODIR/vps.hostname.info)
        echo -e " Setting Hostname to $HNAME : vps.hostname.info found" >> $LOGFILE
    else HNAME=$(hostname)
        touch $INFODIR/vps.hostname.info
        echo -e "$HNAME" > $INFODIR/vps.hostname.info
        echo -e " Setting Hostname to $HNAME : read from server hostname" >> $LOGFILE
    fi
    [ -e $INFODIR/fullauto.info ] && curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Your new VPS is online and reporting installation status ..."}' && echo -e " "
    sleep 4

    # read API key if it exists, if not prompt for it
    if [ -e $INFODIR/vps.api.info ]
    then VPSAPI=$(<$INFODIR/vps.api.info)
        echo -e " Setting NodeValet API key to provided value : vps.api.info found" >> $LOGFILE
    else echo -e "${lightcyan}\n\n Before we begin, we need to verify your NodeValet API Key."
        echo -e " If you do not already have one, you may purchase a NodeValet "
        echo -e " API Key at ${white}https://www.nodevalet.io/purchase.php${lightcyan}. Purchased"
        echo -e " keys permit 5 server installations and expire after 30 days.\n"
        echo -e "${lightgreen} !! Please double-check your NodeValet API Key for accuracy !!${nocolor}"
        touch $INFODIR/vps.api.info
        echo -e -n " "
        while :; do
            echo -e "\n${cyan} Please enter your NodeValet API Key.${nocolor}"
            read -p "  --> " VPSAPI
            echo -e "\n ${white}You entered this API Key: ${yellow}${VPSAPI} ${nocolor}"
            read -n 1 -s -r -p "  ${cyan}--> Is this correct? y/n  ${nocolor}" VERIFY
            if [[ $VERIFY == "y" || $VERIFY == "Y" ]]
            then APITEST="https://api.nodevalet.io/txdata.php?coin=audax&address=APKSdh4QyVGGYBLs7wFbo4MjeXwK3GBD1o&key=$VPSAPI"
                curl -s "$APITEST" > $INSTALLDIR/temp/API.test.json
                APITESTRESPONSE=$(cat $INSTALLDIR/temp/API.test.json)
                ! [[ "${APITESTRESPONSE}" == "Invalid key" ]] && echo -e "${lightgreen}NodeValet API Key is valid${nocolor}" && rm -f $INSTALLDIR/temp/API.test.json && break
                echo -e "${lightred}The API Key you entered is invalid.${nocolor}"
                echo -e "${lightred} User entered an invalid key.${nocolor}" >> $LOGFILE
            else echo " "
            fi
        done
        echo -e "$VPSAPI" > $INFODIR/vps.api.info
        echo -e " NodeValet API Key set to :${lightgreen} $VPSAPI ${nocolor}" >> $LOGFILE
    fi

    # set mnode daemon name from project.env
    MNODE_DAEMON=$(grep ^MNODE_DAEMON $INSTALLDIR/nodemaster/config/"${PROJECT}"/"${PROJECT}".env)
    echo -e "$MNODE_DAEMON" > $INSTALLDIR/temp/MNODE_DAEMON
    sed -i "s/MNODE_DAEMON=\${MNODE_DAEMON:-\/usr\/local\/bin\///" $INSTALLDIR/temp/MNODE_DAEMON  2>&1
    cat $INSTALLDIR/temp/MNODE_DAEMON | tr -d '[}]' > $INSTALLDIR/temp/MNODE_DAEMON1
    MNODE_DAEMON=$(<$INSTALLDIR/temp/MNODE_DAEMON1)
    cat $INSTALLDIR/temp/MNODE_DAEMON1 > $INFODIR/vps.mnode_daemon.info
    rm $INSTALLDIR/temp/MNODE_DAEMON1 ; rm $INSTALLDIR/temp/MNODE_DAEMON
    echo -e "${MNODE_DAEMON::-1}" > $INFODIR/vps.binaries.info 2>&1
    MNODE_BINARIES=$(<$INFODIR/vps.binaries.info)
    echo -e " Setting masternode-daemon to $MNODE_DAEMON : vps.mnode_daemon.info" >> $LOGFILE
    echo -e " Setting masternode-binaries to MNODE_BINARIES : vps.binaries.info" >> $LOGFILE

    # create or assign onlynet from project.env
    ONLYNET=$(grep ^ONLYNET $INSTALLDIR/nodemaster/config/"${PROJECT}"/"${PROJECT}".env)
    echo -e "$ONLYNET" > $INFODIR/vps.onlynet.info
    sed -i "s/ONLYNET=//" $INFODIR/vps.onlynet.info 2>&1
    ONLYNET=$(<$INFODIR/vps.onlynet.info)
    if [ "$ONLYNET" > 0 ]
    then echo -e " Setting network to IPv${ONLYNET} d/t instructions in ${PROJECT}.env" >> $LOGFILE
        echo -e "$ONLYNET" > $INFODIR/vps.onlynet.info
    else ONLYNET='6'
        echo -e " Setting network to IPv${ONLYNET} d/t no reference in ${PROJECT}.env" >> $LOGFILE
        echo -e "$ONLYNET" > $INFODIR/vps.onlynet.info
    fi

    # read or assign number of masternodes to install
    if [ -e $INFODIR/vps.number.info ]
    then MNS=$(<$INFODIR/vps.number.info)
        echo -e " Setting number of masternodes to $MNS : vps.number.info found" >> $LOGFILE
        # check memory and set max MNS appropriately then prompt user how many they would like to build
    elif [ "$ONLYNET" = 4 ]
    then touch $INFODIR/vps.number.info ; MNS=1 ; echo -e "${MNS}" > $INFODIR/vps.number.info
        echo -e " Going to install 1 masternode since IPv4 is required" | tee -a "$LOGFILE"
    else NODES=$(grep MemTotal /proc/meminfo | awk '{print $2 / 1024 / 440}')
        MAXNODES=$(echo "$NODES" | awk '{print int($1+0.5)}')
        echo -e "\n\n${white} This server's memory can safely support $MAXNODES masternodes.${nocolor}\n"
        echo -e "${cyan} Please enter the number of masternodes to install : ${nocolor}"

        while :; do
            read -p "  --> " MNS
            lenMN=${#MNS}
            testvar=$(echo "$MNS" | tr -dc '[:digit:]')   # remove non-numeric chars from $MNS
            if [[ $lenMN -ne ${#testvar} ]]
            then echo -e "\n ${lightred}$MNS is not even a number, enter only numbers.${nocolor}"
                # length would be the same if $MNS was a number
        elif ! (($MNS >= 1 && $MNS <= $MAXNODES))
            then echo -e "\n ${lightred}$MNS is not a number between 1 and $MAXNODES, try another number.${nocolor}"
            else echo -e " Setting number of masternodes to $MNS : user provided input" >> $LOGFILE
                touch $INFODIR/vps.number.info
                echo -e "${MNS}" > $INFODIR/vps.number.info
                break   # exit the loop
            fi
        done
    fi

    # create or assign mnprefix
    if [ -s $INFODIR/vps.mnprefix.info ]
    then echo -e " Setting masternode aliases from vps.mnprefix.info file" >> $LOGFILE
    else MNPREFIX=$(hostname)
        echo -e " Generating aliases from hostname : vps.mnprefix.info not found" >> $LOGFILE
    fi

    # read or collect masternode addresses
    if [ -e $INFODIR/fullauto.info ]
    then echo -e " \n\nThere is no need to collect addreses, ${yellow}fullauto.info ${nocolor}exists\n" | tee -a "$LOGFILE"
    else
        # Gather MN addresses
        # Check if blockchain is fully-supported
        BLOCKEX=$(grep ^BLOCKEXP=unsupported $INSTALLDIR/nodemaster/config/"$PROJECT"/"$PROJECT".env)
        if [ -n "$BLOCKEX" ]
        then echo -e "\n\n ${lightcyan}NodeValet found no fully-supported block explorer.${nocolor}" | tee -a "$LOGFILE"
            echo -e " ${lightred}You must manually enter your transaction IDs for your masternodes to work.\n${nocolor}" | tee -a "$LOGFILE"
            echo -e "\n${white} In order to retrieve your transaction IDs, you should first send the required "
            echo -e " collateral to each of your masternode addresses and wait for at least 1 "
            echo -e " confirmation. Once you have done this, open${yellow} debug console ${white}and typically "
            echo -e " you will enter the command ${yellow}masternode outputs${white}. This will display a list of"
            echo -e " all of your valid collateral transactions. You will need to copy and insert "
            echo -e " these transactions and their index number so NodeValet can generate the"
            echo -e " masternode.conf file that you will paste into your local wallet.\n"
            echo -e " A transaction ID and index should look pretty similar to this: "
            echo -e "${yellow} b1097524b3e08f8d7e71be99b916b38702269c6ea37161bba49ba538a631dd56 1 ${nocolor}"
            VERIFY=
            touch $INFODIR/vps.mntxdata.info
            for ((i=1;i<=$MNS;i++));
            do
                echo -e "${cyan}"
                while :; do
                    echo -e "\n Please enter the transaction ID and index for masternode #$i"
                    echo -e " Leave this field blank if this masternode is not yet funded.${nocolor}"
                    read -p "  --> " UTXID
                    echo -e "\n${white} You entered the transaction ID and index:"
                    echo -e "${yellow} ${UTXID} ${cyan}"
                    read -n 1 -s -r -p "  --> Is this correct? y/n  " VERIFY
                    if [[ $VERIFY == "y" || $VERIFY == "Y" ]]
                    then echo -e -n "${nocolor}"
                        # save TXID to vps.mntxdata.info if length is greater than 5
                        if [ ${#UTXID} -ge 5 ]; then echo -e "$UTXID" >> $INFODIR/vps.mntxdata.info
                        else echo -e "null null" >> $INFODIR/vps.mntxdata.info
                        fi
                        break
                    fi
                done
                echo -e -n "${nocolor}\n"
            done
            echo -e " User manually entered TXIDs and indices for $MNS masternodes\n" >> $LOGFILE 2>&1

        else echo -e "\n\n${lightcyan} Before we can begin, we need to collect${white} $MNS masternode addresses.${lightcyan}"
            echo -e " Manually collecting masternode addresses from user..." >> $LOGFILE 2>&1
            echo -e " In your local wallet, generate the masternode addresses and send"
            echo -e " your collateral transactions for masternodes you want to start"
            echo -e " now. You may also add extra addresses even if you have not yet"
            echo -e " funded them, and the script will still create the masternode"
            echo -e " instance which you can later activate from your local wallet.\n"
            echo -e "${lightgreen}   ! ! Please double-check your addresses for accuracy ! !${nocolor}"
            touch $INFODIR/vps.mnaddress.info

            # Pull BLOCKEXP from $PROJECT.env
            BLOCKEX=$(grep ^BLOCKEXP $INSTALLDIR/nodemaster/config/"$PROJECT"/"$PROJECT".env)
            if [ -n "$BLOCKEX" ]
            then echo "$BLOCKEX" > $INFODIR/vps.BLOCKEXP.info
                sed -i "s/BLOCKEXP=//" $INFODIR/vps.BLOCKEXP.info
                BLOCKEXP=$(<$INFODIR/vps.BLOCKEXP.info)
            else echo -e "No block explorer was identified in $PROJECT.env \n"
            fi

            for ((i=1;i<=$MNS;i++));
            do
                while :; do
                    echo -e "\n${cyan} Please enter the $PROJECTt address for masternode #$i${nocolor}"
                    read -p "  --> " MNADDP
                    echo -e "\n"

                    CURLAPI=$(echo -e "$BLOCKEXP${MNADDP}&key=$VPSAPI")

                    # store NoveValets response in a local file
                    curl -s "$CURLAPI" > $INSTALLDIR/temp/API.response$i.json

                    # read curl API response into variable
                    APIRESPONSE=$(cat $INSTALLDIR/temp/API.response$i.json)

                    # check if API response is invalid
                    [[ "${APIRESPONSE}" == "Invalid key" ]] && echo -e "NodeValet replied: ${lightred}Invalid API Key${nocolor}"   | tee -a "$LOGFILE" && echo -e "null\nnull" > $INSTALLDIR/temp/TXID$i
                    [[ "${APIRESPONSE}" == "Invalid coin" ]] && echo -e "NodeValet replied: ${lightred}Invalid Coin${nocolor}"   | tee -a "$LOGFILE" && echo -e "null\nnull" > $INSTALLDIR/temp/TXID$i
                    [[ "${APIRESPONSE}" == "Invalid address" ]] && echo -e "NodeValet replied: ${lightred}Invalid Address${nocolor}"   | tee -a "$LOGFILE" && echo -e "null\nnull" > $INSTALLDIR/temp/TXID$i
                    [[ "${APIRESPONSE}" == "null" ]] && echo -e "NodeValet replied: Null ${lightred}(no collateral transaction found)${nocolor}"   | tee -a "$LOGFILE" && echo -e "null\nnull" > $INSTALLDIR/temp/TXID$i

                    # check if stored file (API.response$i.json) has NOT length greater than zero
                    ! [[ -s $INSTALLDIR/temp/API.response$i.json ]] && echo "--> Server did not respond or response was empty"   | tee -a "$LOGFILE" && echo -e "null\nnull" > $INSTALLDIR/temp/TXID$i

                    # check if stored file (TXID$i) does NOT exist (then no errors were detected above)
                    ! [[ -e $INSTALLDIR/temp/TXID$i ]] && echo "It looks like this is a valid masternode address." && echo "NodeValet replied with a collateral transaction ID for masternode $i"  | tee -a "$LOGFILE" && cat $INSTALLDIR/temp/API.response$i.json | jq '.["txid","txindex"]' | tr -d '["]' > $INSTALLDIR/temp/TXID$i && cat $INSTALLDIR/temp/API.response$i.json | jq '.'

                    TX=$(echo $(cat $INSTALLDIR/temp/TXID$i))
                    echo -e "$TX" > $INSTALLDIR/temp/TXID$i
                    echo -e " NodeValet API returned $TX as txid for masternode $i " >> $LOGFILE

                    echo " "
                    read -n 1 -s -r -p "${cyan}  --> Is this what you expected? y/n  ${nocolor}" VERIFY
                    echo " "
                    if [[ $VERIFY == "y" || $VERIFY == "Y" || $VERIFY == "yes" || $VERIFY == "Yes" ]]
                    then echo -e "$TX" >> $INFODIR/vps.mntxdata.info
                        rm $INSTALLDIR/temp/API.response$i.json --force
                        break
                    else rm $INSTALLDIR/temp/TXID$i --force
                    fi
                done
                echo -e "$MNADDP" >> $INFODIR/vps.mnaddress.info
                echo -e " -> Address $i is: $MNADDP \n"  | tee -a "$LOGFILE"
            done
        fi
    fi

    # query to generate new genkeys or query for user input
    if [ -e $INFODIR/fullauto.info ]
    then : echo -e "\n Genkeys will be automatically generated for $MNS masternodes.\n" >> $LOGFILE 2>&1
    else
        echo -e "${lightcyan}\n\n You can choose to enter your own masternode genkeys or you can let"
        echo -e " your masternode's ${yellow}${MNODE_DAEMON::-1}-cli ${lightcyan}generate them for you. Both are equally "
        echo -e " secure, but it's faster if your server does it for you. An example of "
        echo -e " when you would want to enter them yourself would be if you are trying "
        echo -e " to transfer existing masternodes to this VPS without interruption.${cyan}"
        while :; do
            echo -e "\n Would you like your server to generate genkeys for you? y/n ${white}"
            read -n 1 -s -r -p " --> Hint: The correct answer here is usually 'yes' " GETGENKEYS
            if [[ $GETGENKEYS == "y" || $GETGENKEYS == "Y" || $GETGENKEYS == "N" || $GETGENKEYS == "n" ]]
            then
                break
            fi
        done
        echo -e -n "${nocolor}"

        if [ "${GETGENKEYS,,}" = "N" ] || [ "${GETGENKEYS,,}" = "n" ]
        then touch $INSTALLDIR/temp/genkeys
            echo -e " User selected to manually enter genkeys for $MNS masternodes" >> $LOGFILE 2>&1
            touch $INSTALLDIR/temp/owngenkeys
            for ((i=1;i<=$MNS;i++));
            do
                echo -e "${cyan}"
                while :; do
                    echo -e "\n Please enter the $PROJECTt genkey for masternode #$i"
                    read -p "  --> " UGENKEY
                    echo -e "\n${white} You entered the address: ${yellow}${UGENKEY}${nocolor} "
                    read -n 1 -s -r -p "  --> Is this correct? y/n  " VERIFY
                    if [[ $VERIFY == "y" || $VERIFY == "Y" ]]
                    then echo -e -n "${nocolor}"
                        echo -e "$UGENKEY" >> $INSTALLDIR/temp/genkeys
                        echo -e " -> Masternode $i genkey is: $UGENKEY" >> $LOGFILE
                        echo -e "$(sed -n ${i}p $INSTALLDIR/temp/genkeys)" > $INSTALLDIR/temp/GENKEY$i
                        break
                    fi
                done
                echo -e -n "${nocolor}"
            done
            echo -e " User manually entered genkeys for $MNS masternodes\n" >> $LOGFILE 2>&1
        else echo -e " User selected to have this VPS create genkeys for $MNS masternodes\n" >> $LOGFILE 2>&1
            echo -e "${nocolor}"
            echo -e "\n ${yellow}No problem.  The VPS will generate your masternode genkeys.${nocolor}\n"
        fi
    fi

    # query to collect TXIDs if not detected
    #    if [ -e $INFODIR/fullauto.info ]
    #    then echo -e "\n Transaction IDs and indices will be retrieved from vps.mntxdata.info.\n" >> $LOGFILE 2>&1
    #    else
    #        # Pull BLOCKEXP from $PROJECT.env
    #        BLOCKEX=$(grep ^BLOCKEXP=unsupported $INSTALLDIR/nodemaster/config/"$PROJECT"/"$PROJECT".env)
    #        if [ -n "$BLOCKEX" ]
    #        then :
    #        else echo -e "\n ${lightcyan}NodeValet found a supported block explorer for $PROJECT.${nocolor}" | tee -a "$LOGFILE"
    #            echo -e " ${white}NodeValet will lookup your masternode transaction information using "
    #           echo -e " the masternode address(es) you entered earlier.${nocolor}"
    #       fi
    #   fi

    # create or assign customssh
    if [ -s $INFODIR/vps.sshport.info ]
    then SSHPORT=$(<$INFODIR/vps.sshport.info)
        echo -e " Setting SSH port to $SSHPORT as found in vpsshport.info \n" >> $LOGFILE
    else
        echo -e "\n\n${white} Your current SSH port is : ${yellow}$(sed -n -e '/Port /p' /etc/ssh/sshd_config) ${nocolor}\n"
        echo -e "${cyan} Enter a custom port for SSH between 11000 and 65535 or use 22 : ${nocolor}"

        # what I consider a good example of a complicated query for numerical data
        while :; do
            read -p "  --> " SSHPORT
            [[ $SSHPORT =~ ^[0-9]+$ ]] || { echo -e " \n${lightred}Try harder, that's not even a number.";echo -e "${nocolor}";continue; }
            if (($SSHPORT >= 11000 && $SSHPORT <= 65535)); then break
            elif [ "$SSHPORT" = 22 ]; then break
            else echo -e "\n${lightred}That number is out of range, try again.${nocolor}\n"
            fi
        done

        echo -e " Setting SSHPORT to $SSHPORT : user provided input \n" >> $LOGFILE
        touch $INFODIR/vps.sshport.info
        echo "$SSHPORT" >> $INFODIR/vps.sshport.info
    fi
    echo -e " \n"
    echo -e " I am going to install $MNS $PROJECTt masternodes on this VPS \n" >> $LOGFILE
    echo -e "\n"

    # Pull BLOCKEXP from $PROJECT.env
    BLOCKEX=$(grep ^BLOCKEXP $INSTALLDIR/nodemaster/config/"$PROJECT"/"$PROJECT".env)
    if [ -n "$BLOCKEX" ]
    then echo "$BLOCKEX" > $INFODIR/vps.BLOCKEXP.info
        sed -i "s/BLOCKEXP=//" $INFODIR/vps.BLOCKEXP.info
        BLOCKEXP=$(<$INFODIR/vps.BLOCKEXP.info)
        echo -e " Block Explorer set to :" | tee -a "$LOGFILE"
        echo -e " $BLOCKEXP \n" | tee -a "$LOGFILE"
    else echo -e "No block explorer was identified in $PROJECT.env \n" | tee -a "$LOGFILE"
    fi

    # enable softwrap so masternode.conf file can be easily copied
    sed -i "s/# set softwrap/set softwrap/" /etc/nanorc >> $LOGFILE 2>&1
}

######################
###  CHECK DISTRO  ###
######################
function check_distro() {
    # currently supporting Ubuntu 16.04/18.04/20.04
    if [[ -r /etc/os-release ]]; then
        . /etc/os-release
        if [[ "${VERSION_ID}" != "16.04" ]] && [[ "${VERSION_ID}" != "18.04" ]] && [[ "${VERSION_ID}" != "20.04" ]]; then
            echo -e "This script only supports Ubuntu 16.04/18.04/20.04 LTS, exiting.\n"
            exit 1
        fi
    else
        # no, thats not ok!
        echo -e "This script only supports Ubuntu 16.04/18.04/20.04 LTS, exiting.\n"
        exit 1
    fi
}

####################
###  HARDEN VPS  ###
####################
function harden_vps() {
    if [ -e /var/log/server_hardening.log ]
    then echo -e " This server seems to already be hardened, skipping this part \n" | tee -a "$LOGFILE"
    else echo -e " This server is not yet secure, running VPS Hardening script" | tee -a "$LOGFILE"
        echo -e " Server hardening log is saved at /var/tmp/nodevalet/logs/vps-harden.log \n" | tee -a "$LOGFILE"
        cd $INSTALLDIR/vps-harden || exit
        bash get-hard.sh
    fi
    echo -e " Installing jp2a and figlet and unzip and at packages" >> $LOGFILE
    sudo apt-get -qqy -o=Dpkg::Use-Pty=0 -o=Acquire::ForceIPv4=true install jp2a unzip figlet at
    # apt-get -qqy -o=Dpkg::Use-Pty=0 -o=Acquire::ForceIPv4=true install jq jp2a unzip figlet at | tee -a "$LOGFILE"

    echo -e "\nInserting random Chuck Norris joke to keep things spicy ${lightblue}\n" | tee -a "$LOGFILE"
    curl -s "http://api.icndb.com/jokes/random" | jq '.value.joke' | tee -a "$LOGFILE"
}

##########################
###  INSTALL BINARIES  ###
##########################
function install_binaries() {

    # make special accomodations for coins that build weird, require oddball dependencies, or use sloppy code
    if [ "${PROJECT,,}" = "bitsend" ]
    then echo -e "${nocolor}Bitsend detected, initiating funky installation process...\n"
        # insert specific steps here
        add-apt-repository -y ppa:bitcoin/bitcoin
        apt-get -o=Dpkg::Use-Pty=0 -o=Acquire::ForceIPv4=true update
        apt-get -qqy -o=Dpkg::Use-Pty=0 -o=Acquire::ForceIPv4=true install libboost-system1.58.0 libboost1.58-all-dev libdb4.8++ libdb4.8 libdb4.8-dev libdb4.8++-dev libevent-pthreads-2.0-5
    fi

    # check for binaries and install if found
    echo -e "\n${lightcyan}Attempting to download and install $PROJECTt binaries from:${nocolor}"
    echo -e "\n${nocolor}Attempting to download and install $PROJECTt binaries from:" >> "$LOGFILE"

    # Pull GITAPI_URL from $PROJECT.env
    GIT_API=$(grep ^GITAPI_URL $INSTALLDIR/nodemaster/config/"$PROJECT"/"$PROJECT".env)
    if [ -n "$GIT_API" ] ; then
        echo "$GIT_API" > $INFODIR/vps.GIT_API.info
        sed -i "s/GITAPI_URL=//" $INFODIR/vps.GIT_API.info
        GITAPI_URL=$(<$INFODIR/vps.GIT_API.info)
        echo -e "$GITAPI_URL" | tee -a "$LOGFILE"
        echo " "

        # Try and install Binaries now
        # Pull GITSTRING from $PROJECT.gitstring
        GITSTRING=$(cat $INSTALLDIR/nodemaster/config/"${PROJECT}"/"${PROJECT}".gitstring)

        mkdir $INSTALLDIR/temp/bin
        cd $INSTALLDIR/temp/bin

        curl -s "$GITAPI_URL" \
            | grep browser_download_url \
            | grep "$GITSTRING" \
            | cut -d '"' -f 4 \
            | wget -qi -
        TARBALL="$(find . -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -f2- -d" ")"

        # do not try to unpack and install if tarball does not exist
        if [ -z "$TARBALL" ]
        then echo -e "${lightred}Binaries for ${PROJECTt} matching ${yellow}$GITSTRING${lightred} could not be located.${nocolor}"
        else echo -e "${lightcyan}Unpacking and installing binaries.${nocolor}"
            if [[ $TARBALL == *.gz ]]
            then tar -xzf "$TARBALL"
            elif [[ $TARBALL == *.tgz ]]
            then tar -xzf "$TARBALL"
            else unzip "$TARBALL"
            fi
            rm -f "$TARBALL"
            cd  "$(\ls -1dt ./*/ | head -n 1)"
            find . -mindepth 2 -type f -print -exec mv {} . \;
            cp "${MNODE_BINARIES}"* '/usr/local/bin'
            cd ..
            rm -r -f *
            cd
            cd /usr/local/bin
            chmod 777 "${MNODE_BINARIES}"*
        fi

    else
        echo -e "Cannot download binaries; no GITAPI_URL was detected \n" | tee -a "$LOGFILE"
    fi

    # check if binaries already exist, skip installing crypto packages if they aren't needed
    dEXIST=$(ls /usr/local/bin | grep "${MNODE_BINARIES}")

    if [[ "${dEXIST}" ]]
    then echo -e "\n${lightcyan}Binaries for ${PROJECTt} were successfully downloaded and installed${nocolor}"   | tee -a "$LOGFILE"
    echo -e "\nThey are now located in the ${white}/usr/local/bin\n"   | tee -a "$LOGFILE"
    curl -s "$GITAPI_URL" | grep tag_name > $INSTALLDIR/temp/currentversion

    else echo -e "${lightred}Binaries for ${PROJECTt} were not installed.\n${nocolor}"  | tee -a "$LOGFILE"
    fi

    # remove binaries temp folder
    rm -rf $INSTALLDIR/temp/bin
}

#####################
###  INSTALL MNS  ###
#####################
function install_mns() {
    if [ -e /etc/masternodes/"$PROJECT_n1".conf ]
    then touch $INSTALLDIR/temp/mnsexist
        echo -e "Pre-existing masternodes detected; no changes to them will be made" > $INSTALLDIR/mnsexist
        echo -e "Masternodes seem to already be installed, skipping this part" | tee -a "$LOGFILE"
    else
        cd $INSTALLDIR/nodemaster || exit
        echo -e "Invoking local Nodemaster's VPS script" | tee -a "$LOGFILE"
        echo -e "Launching Nodemaster using ${white}bash install.sh -n $ONLYNET -p $PROJECT -c $MNS ${nocolor}" | tee -a "$LOGFILE"
        sudo bash install.sh -n $ONLYNET -p "$PROJECT" -c "$MNS"
        echo -e "\n"

        # add support for deterministic wallets so they don't break everything
        if [ "${PROJECT,,}" = "mue" ] || [ "${PROJECT,,}" = "audax" ]
        then echo -e "${lightcyan} Setting masternode services to not use deterministic seeds for wallets\n${nocolor}" | tee -a "$LOGFILE"
            for ((i=1;i<=$MNS;i++));
            do
                sed -i "s/${MNODE_DAEMON}/${MNODE_DAEMON} -usehd=0/" /etc/systemd/system/${PROJECT}_n$i.service >> $LOGFILE 2>&1
            done
        fi

        # activate masternodes, or activate just FIRST masternode
        echo -e "${lightred}Attention: ${green}Your $PROJECTt masternode(s) are now activating...${nocolor} \n" | tee -a "$LOGFILE"
        activate_masternodes_"$PROJECT" echo -e | tee -a "$LOGFILE"

        # check if $PROJECTd was built correctly and started
        if ps -A | grep "$MNODE_BINARIES" > /dev/null
        then
            # report back to mother
            if [ -e "$INFODIR"/fullauto.info ] ; then echo -e "Reporting ${MNODE_BINARIES} build success to mother" | tee -a "$LOGFILE" ; curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Process '"$MNODE_DAEMON"' has started ..."}' && echo -e " " ; fi

        else
            for ((H=1;H<=10;H++));
            do
                if ps -A | grep "$MNODE_BINARIES" > /dev/null
                then
                    # report back to mother
                    if [ -e "$INFODIR"/fullauto.info ] ; then echo -e "Reporting ${MNODE_BINARIES} build success to mother" | tee -a "$LOGFILE" ; curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Process '"$MNODE_DAEMON"' started after '"$H"' seconds ..."}' && echo -e " " ; fi
                    break
                else

                    if [ "${H}" = "10" ]
                    then echo " "
                        echo -e "After $H (H) seconds, $MNODE_DAEMON is still not running" | tee -a "$LOGFILE"
                        echo -e "so we are going to abort this installation now. \n" | tee -a "$LOGFILE"
                        echo -e "Reporting ${MNODE_DAEMON} build failure to mother" | tee -a "$LOGFILE"
                        if [ -e "$INFODIR"/fullauto.info ] ; then curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Error: '"$MNODE_DAEMON"' failed to build or start after 10 seconds"}' && echo -e " " ; fi
                        exit
                    fi
                    sleep 1
                fi
            done
        fi
    fi
}

########################
###  ADD SCRIPTLETS  ###
########################
function add_scriptlets() {
    # Enable run permissions on all scripts
    chmod 0700 $INSTALLDIR/*.sh
    chmod 0700 $INSTALLDIR/maintenance/*.sh

    # Add system link to common maintenance scripts so they can be accessed more easily
    sudo ln -s $INSTALLDIR/maintenance/addmn.sh /usr/local/bin/addmn
    sudo ln -s $INSTALLDIR/maintenance/autoupdate.sh /usr/local/bin/autoupdate
    sudo ln -s $INSTALLDIR/maintenance/bootstrap.sh /usr/local/bin/bootstrap
    sudo ln -s $INSTALLDIR/maintenance/checkdaemon.sh /usr/local/bin/checkdaemon
    sudo ln -s $INSTALLDIR/maintenance/checksync.sh /usr/local/bin/checksync
    sudo ln -s $INSTALLDIR/maintenance/clonesync.sh /usr/local/bin/clonesync
    sudo ln -s $INSTALLDIR/maintenance/clonesync_all.sh /usr/local/bin/clonesync_all
    sudo ln -s $INSTALLDIR/maintenance/getinfo.sh /usr/local/bin/getinfo
    sudo ln -s $INSTALLDIR/maintenance/killswitch.sh /usr/local/bin/killswitch
    sudo ln -s $INSTALLDIR/maintenance/makerun.sh /usr/local/bin/makerun
    sudo ln -s $INSTALLDIR/maintenance/masternodestatus.sh /usr/local/bin/masternodestatus
    sudo ln -s $INSTALLDIR/maintenance/mnedit.sh /usr/local/bin/mnedit
    sudo ln -s $INSTALLDIR/maintenance/mnstart.sh /usr/local/bin/mnstart
    sudo ln -s $INSTALLDIR/maintenance/mnstop.sh /usr/local/bin/mnstop
    sudo ln -s $INSTALLDIR/maintenance/mulligan.sh /usr/local/bin/mulligan
    sudo ln -s $INSTALLDIR/maintenance/rebootq.sh /usr/local/bin/rebootq
    sudo ln -s $INSTALLDIR/maintenance/remove_crons.sh /usr/local/bin/remove_crons
    sudo ln -s $INSTALLDIR/maintenance/restore_crons.sh /usr/local/bin/restore_crons
    sudo ln -s $INSTALLDIR/maintenance/resync.sh /usr/local/bin/resync
    sudo ln -s $INSTALLDIR/maintenance/showconf.sh /usr/local/bin/showconf
    sudo ln -s $INSTALLDIR/maintenance/showdebug.sh /usr/local/bin/showdebug
    sudo ln -s $INSTALLDIR/maintenance/showmlog.sh /usr/local/bin/showmlog
    sudo ln -s $INSTALLDIR/maintenance/smartstart.sh /usr/local/bin/smartstart
    sudo ln -s $INSTALLDIR/maintenance/rpc.sh /usr/local/bin/rpc
}

######################
###  ADD CRONJOBS  ###
######################
function add_cron() {
    # Add maintenance and automation cronjobs
    echo -e "\n $(date +%m.%d.%Y_%H:%M:%S) : Adding crontabs"  | tee -a "$LOGFILE"
    echo -e "  --> Check for stuck blocks every 30 minutes"  | tee -a "$LOGFILE"
    (crontab -l ; echo "5,35 * * * * /var/tmp/nodevalet/maintenance/checkdaemon.sh") | crontab -
    echo -e "  --> Check for & reboot if needed to install updates every 10 hours"  | tee -a "$LOGFILE"
    (crontab -l ; echo "59 */10 * * * /var/tmp/nodevalet/maintenance/rebootq.sh") | crontab -
    echo -e "  --> Check for wallet updates every 48 hours"  | tee -a "$LOGFILE"
    (crontab -l ; echo "2 */48 * * * /var/tmp/nodevalet/maintenance/autoupdate.sh") | crontab -
    echo -e "  --> Clear daemon debug logs weekly to prevent clog"  | tee -a "$LOGFILE"
    (crontab -l ; echo "@weekly /var/tmp/nodevalet/maintenance/cleardebuglog.sh") | crontab -
    echo -e "  --> Check if chains are syncing or synced every 5 minutes"  | tee -a "$LOGFILE"
    (crontab -l ; echo "*/5 * * * * /var/tmp/nodevalet/maintenance/cronchecksync1.sh") | crontab -
}

#######################
###  CONFIGURE MNS  ###
#######################
function configure_mns() {
    # Do not break any existing masternodes
    if [ -s $INSTALLDIR/temp/mnsexist ]
    then echo -e "Skipping configure_mns function due to presence of $INSTALLDIR/mnsexist" | tee -a "$LOGFILE"
        echo -e "Reporting ${MNODE_DAEMON} build failure to mother" | tee -a "$LOGFILE"
        [ -e $INFODIR/fullauto.info ] && curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Error: Masternodes already exist on this VPS; stopping install."}' && echo -e " "
        exit
    else
        # echo -e "Saving genkey(s) to $INSTALLDIR/temp/genkeys \n"  | tee -a "$LOGFILE"
        touch $INSTALLDIR/temp/genkeys # Create file to store masternode genkeys
        touch $INSTALLDIR/masternode.conf # create initial masternode.conf file
        echo -e "Creating $INSTALLDIR/masternode.conf file to collect user settings" | tee -a "$LOGFILE"
        cat <<EOT >> $INSTALLDIR/masternode.conf
#######################################################
# Masternode.conf settings to paste into Local Wallet #
#######################################################
EOT
        echo -e "Creating masternode.conf variables and files for $MNS masternodes" | tee -a "$LOGFILE"
        for ((i=1;i<=$MNS;i++));
        do
            for ((P=1;P<=42;P++));
            do
                # create masternode genkeys (smart is special "smartnodes")
                if [ -e $INSTALLDIR/temp/owngenkeys ] ; then :
                
                # add something for Dash and Sierra here

                elif [ "${PROJECT,,}" = "smart" ]
                then /usr/local/bin/"${MNODE_DAEMON::-1}"-cli -conf=/etc/masternodes/"${PROJECT}"_n1.conf smartnode genkey >> $INSTALLDIR/temp/genkeys
                
                elif [ "${PROJECT,,}" = "pivx" ] || [ "${PROJECT,,}" = "squorum" ] || [ "${PROJECT,,}" = "wagerr" ] || [ "${PROJECT,,}" = "empty" ]
                then /usr/local/bin/"${MNODE_DAEMON::-1}"-cli -conf=/etc/masternodes/"${PROJECT}"_n1.conf createmasternodekey >> $INSTALLDIR/temp/genkeys

                else /usr/local/bin/"${MNODE_DAEMON::-1}"-cli -conf=/etc/masternodes/"${PROJECT}"_n1.conf masternode genkey >> $INSTALLDIR/temp/genkeys ; fi
                echo -e "$(sed -n ${i}p $INSTALLDIR/temp/genkeys)" > $INSTALLDIR/temp/GENKEY$i

                # craft line to be injected into wallet.conf
                if [ "${PROJECT,,}" = "smart" ] ; then echo "smartnodeprivkey=" > $INSTALLDIR/temp/MNPRIV1
                elif [ "${PROJECT,,}" = "zcoin" ] ; then echo "znodeprivkey=" > $INSTALLDIR/temp/MNPRIV1
                else echo "masternodeprivkey=" > $INSTALLDIR/temp/MNPRIV1
                fi
                KEYXIST=$(<$INSTALLDIR/temp/GENKEY$i)

                # add extra pause for wallets that are slow to start
                SLEEPTIME=10

                # check if GENKEY variable is empty; if so stop script and report error
                if [ ${#KEYXIST} = "0" ]
                then echo -e " ${MNODE_DAEMON::-1}-cli couldn't create genkey $i; engine likely still starting up"
                    echo -e " --> Waiting for $SLEEPTIME seconds before trying again... loop $P"
                    sleep $SLEEPTIME
                else break
                fi

                if [ ${#KEYXIST} = "0" ] && [ "${P}" = "42" ]
                then echo " "
                    [ -e $INFODIR/fullauto.info ] && curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Error: Could not generate masternode genkeys"}' && echo -e " "
                    echo -e "Problem creating masternode $i. Could not obtain masternode genkey." | tee -a "$LOGFILE"
                    echo -e "I patiently tried 42 times but something isn't working correctly.\n" | tee -a "$LOGFILE"
                    exit 1
                fi
            done
        done

        for ((i=1;i<=$MNS;i++));
        do
            # get or iterate mnprefixes
            if [ -s $INFODIR/vps.mnprefix.info ]
            then echo -e "$(sed -n ${i}p $INFODIR/vps.mnprefix.info)" >> $INFODIR/vps.mnaliases.info
            else echo -e "${MNPREFIX}-MN$i" >> $INFODIR/vps.mnaliases.info
            fi

            # create masternode prefix files
            echo -e "$(sed -n ${i}p $INFODIR/vps.mnaliases.info)" >> $INSTALLDIR/temp/MNALIAS$i

            # create masternode address files
            echo -e "$(sed -n ${i}p $INFODIR/vps.mnaddress.info)" > $INSTALLDIR/temp/MNADD$i

            # append "masternodeprivkey="
            paste $INSTALLDIR/temp/MNPRIV1 $INSTALLDIR/temp/GENKEY$i > $INSTALLDIR/temp/GENKEY${i}FIN
            tr -d '[:blank:]' < $INSTALLDIR/temp/GENKEY${i}FIN > $INSTALLDIR/temp/MNPRIVKEY$i

            # assign GENKEYVAR to the full line masternodeprivkey=xxxxxxxxxx
            GENKEYVAR=$(cat $INSTALLDIR/temp/MNPRIVKEY$i)

            # insert new genkey into project_n$i.conf files (special case for smartnodes)
            if [ "${PROJECT,,}" = "smart" ]
            then
                sed -i "s/^smartnodeprivkey=.*/$GENKEYVAR/" /etc/masternodes/"${PROJECT}"_n$i.conf
                masternodeprivkeyafter=$(grep ^smartnodeprivkey /etc/masternodes/"${PROJECT}"_n$i.conf)
                echo -e " Privkey in /etc/masternodes/${PROJECT}_n$i.conf after sub is : " >> $LOGFILE
                echo -e " $masternodeprivkeyafter" >> $LOGFILE
            elif [ "${PROJECT,,}" = "zcoin" ]
            then
                sed -i "s/^znodeprivkey=.*/$GENKEYVAR/" /etc/masternodes/"${PROJECT}"_n$i.conf
                masternodeprivkeyafter=$(grep ^znodeprivkey /etc/masternodes/"${PROJECT}"_n$i.conf)
                echo -e " Privkey in /etc/masternodes/${PROJECT}_n$i.conf after sub is : " >> $LOGFILE
                echo -e " $masternodeprivkeyafter" >> $LOGFILE

            else
                sed -i "s/^masternodeprivkey=.*/$GENKEYVAR/" /etc/masternodes/"${PROJECT}"_n$i.conf
                masternodeprivkeyafter=$(grep ^masternodeprivkey /etc/masternodes/"${PROJECT}"_n$i.conf)
                echo -e " Privkey in ${PROJECT}_n$i.conf after sub is : " >> $LOGFILE
                echo -e " $masternodeprivkeyafter" >> $LOGFILE
            fi

            # create file with IP addresses
            sed -n -e '/^bind/p' /etc/masternodes/"${PROJECT}"_n$i.conf >> $INFODIR/vps.ipaddresses.info

            # remove "bind=" from vpsipaddresses.info
            sed -i "s/bind=//" $INFODIR/vps.ipaddresses.info 2>&1

            # the next line produces the IP addresses for this masternode
            echo -e "$(sed -n ${i}p $INFODIR/vps.ipaddresses.info)" > $INSTALLDIR/temp/IPADDR$i

            PUBLICIP=$(sudo /usr/bin/wget -q -O - http://ipv4.icanhazip.com/ | /usr/bin/tail)
            PRIVATEIP=$(sudo hostname -I | awk '{print $1}')

            # to enable functionality in headless mode for LAN connected VPS, replace private IP with public IP
            if [ "$PRIVATEIP" != "$PUBLICIP" ]
            then sed -i "s/$PRIVATEIP/$PUBLICIP/" $INSTALLDIR/temp/IPADDR$i
                echo -e " Your private IP address is $PRIVATEIP " | tee -a "$LOGFILE"
                echo -e " Your public IP address is $PUBLICIP " | tee -a "$LOGFILE"
                echo -e " ${lightgreen}This masternode appears to be on a LAN, so we'll replace its private" | tee -a "$LOGFILE"
                echo -e " IPv4 address with a public one in the masternode.conf file if needed." | tee -a "$LOGFILE"
                echo -e " You may need to configure your router to forward ports for masternodes to work. ${nocolor}" | tee -a "$LOGFILE"
            fi

            # Check for presence of txid and, if present, use it for txid/txidx
            if [ -e $INFODIR/vps.mntxdata.info ]
            then echo -e "$(sed -n ${i}p $INFODIR/vps.mntxdata.info)" > $INSTALLDIR/temp/TXID$i
                TX=$(echo $(cat $INSTALLDIR/temp/TXID$i))
                echo -e "$TX" >> $INSTALLDIR/temp/txid
                echo -e "$TX" > $INSTALLDIR/temp/TXID$i
                echo -e " Read transaction ID for MN$i from vps.mntxdata.info; set to : " >> $LOGFILE
                echo -e " $TX " >> $LOGFILE

            else
                # CURLAPI="https://api.nodevalet.io/txdata.php?coin=audax&address=APKSdh4QyVGGYBLs7wFbo4MjeXwK3GBD1o&key=xxxx-xxxx-xxxx-xxxx-xxxx-xxxx"

                MNADDRESS=$(cat $INSTALLDIR/temp/MNADD$i)
                CURLAPI=$(echo -e "$BLOCKEXP$MNADDRESS&key=$VPSAPI")

                # store NoveValets response in a local file
                curl -s "$CURLAPI" > $INSTALLDIR/temp/API.response$i.json

                # log and display original curl API and response
                [[ -s $INSTALLDIR/temp/API.response$i.json ]] && echo " --> Your VPS sent NodeValet following request <--"   | tee -a "$LOGFILE"
                [[ -s $INSTALLDIR/temp/API.response$i.json ]] && echo -e " curl -s $CURLAPI \n"   | tee -a "$LOGFILE" && cat $INSTALLDIR/temp/API.response$i.json | tee -a "$LOGFILE" && echo -e "\n" | tee -a "$LOGFILE"

                # read curl API response into variable
                APIRESPONSE=$(cat $INSTALLDIR/temp/API.response$i.json)

                # check if API response is invalid
                [[ "${APIRESPONSE}" == "Invalid key" ]] && echo "NodeValet replied: Invalid API Key"   | tee -a "$LOGFILE" && echo -e "null\nnull" > $INSTALLDIR/temp/TXID$i
                [[ "${APIRESPONSE}" == "Invalid coin" ]] && echo "NodeValet replied: Invalid Coin"   | tee -a "$LOGFILE" && echo -e "null\nnull" > $INSTALLDIR/temp/TXID$i
                [[ "${APIRESPONSE}" == "Invalid address" ]] && echo "NodeValet replied: Invalid Address"   | tee -a "$LOGFILE" && echo -e "null\nnull" > $INSTALLDIR/temp/TXID$i
                [[ "${APIRESPONSE}" == "null" ]] && echo "NodeValet replied: Null (no collateral transaction found)"   | tee -a "$LOGFILE" && echo -e "null\nnull" > $INSTALLDIR/temp/TXID$i


                # check if stored file (API.response$i.json) has NOT length greater than zero
                ! [[ -s $INSTALLDIR/temp/API.response$i.json ]] && echo "--> Server did not respond or response was empty"   | tee -a "$LOGFILE" && echo -e "null\nnull" > $INSTALLDIR/temp/TXID$i

                # check if stored file (TXID$i) does NOT exist (then no errors were detected above)
                ! [[ -e $INSTALLDIR/temp/TXID$i ]] && echo "NodeValet replied: Transaction ID recorded for MN$i"  | tee -a "$LOGFILE" && cat $INSTALLDIR/temp/API.response$i.json | jq '.["txid","txindex"]' | tr -d '["]' > $INSTALLDIR/temp/TXID$i && cat $INSTALLDIR/temp/API.response$i.json | jq '.'

                TX=$(echo $(cat $INSTALLDIR/temp/TXID$i))
                echo -e "$TX" >> $INSTALLDIR/temp/txid
                echo -e "$TX" > $INSTALLDIR/temp/TXID$i
                echo -e " NodeValet API returned $TX as txid for masternode $i " >> $LOGFILE
                rm $INSTALLDIR/temp/API.response$i.json --force

            fi

            # this is a pretty display of the received JSON; suitable for headless display
            # cat $INSTALLDIR/temp/API.response$i.json | jq '.'

            # this returns the TXID as long as the API key is valid
            # it returns "null null" if the API is valid but the MN address is invalid
            # sudo -s curl "$CURLAPI"  | jq '.["txid","txindex"]' | tr -d '["]' > $INSTALLDIR/temp/TXID$i

            # run JQ on the .json response to arrive at our TXID
            # cat $INSTALLDIR/temp/API.response$i.json
            # cat $INSTALLDIR/temp/API.response$i.json | jq '.["txid","txindex"]' | tr -d '["]' > $INSTALLDIR/temp/TXID$i

            # if the TXID$i has length, assume it's good
            # [ -s $INSTALLDIR/temp/TXID$i ] && echo "NodeValet returned a TXID" || echo -e "null\nnull" >> $INSTALLDIR/temp/TXID$i

            # this line sends a good API query, saves the output, and then displays that to user
            # curl -s "https://api.nodevalet.io/txdata.php?coin=audax&address=APKSdh4QyVGGYBLs7wFbo4MjeXwK3GBD1o&key=XXXX-XXXX-XXXX-XXXX-XXXX-XXXX" > $INSTALLDIR/temp/API.response$i.json && clear && cat $INSTALLDIR/temp/API.response$i.json && echo -e "\n"

            #
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

            # Set the nosync flag for each masternode on creation
            touch $INSTALLDIR/temp/"${PROJECT}"_n${i}_nosync
            echo -e "$(date +%m.%d.%Y_%H:%M:%S) -- first created" >> $INSTALLDIR/temp/"${PROJECT}"_n${i}_nosync

            # round 1: cleanup and declutter
            rm $INSTALLDIR/temp/GENKEY${i}FIN ; rm $INSTALLDIR/temp/GENKEY$i ; rm $INSTALLDIR/temp/IPADDR$i ; rm $INSTALLDIR/temp/MNADD$i
            rm $INSTALLDIR/temp/MNALIAS$i ; rm $INSTALLDIR/temp/TXID$i ; rm $INSTALLDIR/temp/"${PROJECT}"Ds --force ; rm $INSTALLDIR/temp/DELIMETER
            rm $INSTALLDIR/0 --force

            echo -e " --> Completed masternode $i loop, moving on..."  | tee -a "$LOGFILE"
        done
        # echo -e " \n" | tee -a "$LOGFILE"

        # comment out lines that contain "collateral_output_txid tx" in masternode.conf
        sed -e '/collateral_output_txid tx/ s/^#*/# /' -i $INSTALLDIR/masternode.conf >> $INSTALLDIR/masternode.conf 2>&1

        [ -e $INFODIR/fullauto.info ] && echo -e "Converting masternode.conf to one delineated line for mother" | tee -a "$LOGFILE"
        # convert masternode.conf to one delineated line separated using | and ||

        # echo -e "complete" > $INSTALLDIR/temp/complete
        if [ -e $INFODIR/fullauto.info ]
        then echo -e "complete|${VPSAPI}|guidedui" > $INSTALLDIR/temp/complete
        else echo -e "complete|${VPSAPI}|headless" > $INSTALLDIR/temp/complete
        fi

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
        cp $INSTALLDIR/temp/genkeys $INFODIR/vps.genkeys.info
        #        cp $INSTALLDIR/temp/txid $INFODIR/vps.mntxdata.info
        rm $INSTALLDIR/temp/complete --force        ;   rm $INSTALLDIR/temp/masternode.all --force
        rm $INSTALLDIR/temp/masternode.1 --force    ;   rm $INSTALLDIR/temp/masternode.l* --force
        rm $INSTALLDIR/temp/DONATION --force        ;   rm $INSTALLDIR/temp/DONATEADDR --force
        rm $INSTALLDIR/temp/"${PROJECT}"Ds --force  ;   rm $INSTALLDIR/temp/MNPRIV* --force
        rm $INSTALLDIR/temp/ONLYNET --force         ;   rm $INSTALLDIR/temp/genkeys --force
        rm $INSTALLDIR/temp/txid --force

        # remove blank lines from installation log file and replace original
        grep -v -e '^[[:space:]]*$' "$LOGFILE" > $INSTALLDIR/logs/install.log
        mv $INSTALLDIR/logs/install.log "$LOGFILE"

    fi
}

########################
###  RESTART SERVER  ###
########################
function restart_server() {
    echo -e " Placing postinstall_api.sh in /etc/rc.local for Ubuntu 16.04/18.04/20.04 \n"
    echo -e "sudo bash /var/tmp/nodevalet/maintenance/postinstall_api.sh &" >> /etc/rc.local
    sed -i '/exit 0/d' /etc/rc.local
    echo -e "exit 0" >> /etc/rc.local

    echo -e " ${yellow}---------------------------------------------------- " | tee -a "$LOGFILE"
    echo -e " $(date +%m.%d.%Y_%H:%M:%S) : Preparing to reboot " | tee -a "$LOGFILE"
    echo -e " ---------------------------------------------------- ${nocolor}\n" | tee -a "$LOGFILE"

    clear
    echo -e "${lightcyan}This is the contents of your file $INSTALLDIR/masternode.conf ${nocolor}\n" | tee -a "$LOGFILE"
    cat $INSTALLDIR/masternode.conf | tee -a "$LOGFILE"
    echo -e "${white} Please follow the steps below to complete your masternode setup: ${nocolor}"
    echo -e " 1. Please copy the data above and paste it into the ${yellow}masternode.conf${nocolor} "
    echo -e "    file on your local wallet. (insert txid info if necessary) "
    echo -e " 2. This VPS will automatically restart now to complete the installation"
    echo -e "    and begin syncing the blockchain. "
    echo -e " 3. Once the VPS has rebooted successfully, restart your local wallet, "
    echo -e "    and then you may click ${yellow}Start Missing${nocolor} to start your new masternodes. "
    echo -e " 4. If the initial blockchain sync takes longer than a couple of hours "
    echo -e "    you may need to start the masternodes in your local wallet again.\n"
    echo -e "${lightred} * * Note: This VPS will now automatically restart to finish setup * * ${nocolor}\n"
    touch $INSTALLDIR/temp/vpsvaletreboot.txt
    sleep 1
    shutdown -r now "Server is going down for upgrade."
}

################################
###  ACTUAL START OF SCRIPT  ###
################################

setup_environment # moved initial NodeValet callback near beginning to provide faster response
check_distro
gather_info
harden_vps

[ -e $INFODIR/fullauto.info ] && curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Downloading '"$PROJECTt"' Binaries ..."}' && echo -e " "
install_binaries

[ -e $INFODIR/fullauto.info ] && curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Creating '"$MNS"' '"$PROJECTt"' Masternodes using Nodemaster VPS script ..."}' && echo -e " "
install_mns

add_scriptlets

[ -e $INFODIR/fullauto.info ] && curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Configuring '"$MNS"' '"$PROJECTt"' Masternodes ..."}' && echo -e " "
configure_mns

# install crontabs must complete before we display masternode.conf file in case user breaks there
add_cron

# create file to signal cron that reboot has occurred
[ -e $INFODIR/fullauto.info ] && curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Restarting Server to Finalize Installation ..."}' && echo -e " "

restart_server

exit 0
#!/bin/bash
# Make sure the daemon is not stuck and restart it if it is.
# authorized script to resync entire blockchain in case of catastrophic failure
# Add the following to the crontab (i.e. crontab -e)
# (crontab -l ; echo "*/30 * * * * $INSTALLDIR/maintenance/checkdaemon.sh") | crontab -

# Set common variables
. /var/tmp/nodevalet/maintenance/vars.sh

# extglob was necessary to make rm -- ! possible
shopt -s extglob

if [ -e "$INSTALLDIR/temp/bootstrapping" ] || [ -e "$INSTALLDIR/temp/checkingdaemon" ]
then echo -e " Skipping checkdaemon.sh because another process is in progress.\n"
    exit
fi

if [ -e "$INSTALLDIR/temp/shuttingdown" ]
then echo -e " Skipping checkdaemon.sh because the server is shutting down.\n" | tee -a "$LOGFILE"
    exit
fi

if [ -e "$INSTALLDIR/temp/updating" ]
then echo -e " $(date +%m.%d.%Y_%H:%M:%S) : Running checkdaemon.sh" | tee -a "$LOGFILE"
    echo -e " It looks like I'm currently running other tasks; skipping daemon check.\n"  | tee -a "$LOGFILE"
    exit
fi

touch $INSTALLDIR/temp/updating
touch $INSTALLDIR/temp/checkingdaemon
echo -e " $(date +%m.%d.%Y_%H:%M:%S) : Running checkdaemon.sh\n"  | tee -a $INSTALLDIR/temp/updating

echo -e "\n"
for ((i=1;i<=$MNS;i++));
do

    echo -e " Checking for stuck blocks on masternode ${PROJECT}_n${i}"
    if [ ! -s "$INSTALLDIR/temp/blockcount$i" ]
    then previousBlock='null'
    else previousBlock=$(cat $INSTALLDIR/temp/blockcount${i})
    fi

    /usr/local/bin/"${MNODE_DAEMON::-1}"-cli -conf=/etc/masternodes/"${PROJECT}"_n${i}.conf getblockcount > $INSTALLDIR/temp/blockcount${i}
    currentBlock=$(cat $INSTALLDIR/temp/blockcount${i})

    if [ ! -s "$INSTALLDIR/temp/blockcount$i" ]
    then currentBlock='null'
    else currentBlock=$(cat $INSTALLDIR/temp/blockcount${i})
    fi

    if [ "$currentBlock" == "-1" ]
    then
        echo -e " Current block is $currentBlock; masternode appears to be starting up\n"
    elif [ "$previousBlock" == "$currentBlock" ]
    then
        echo -e " Previous block was${white} $previousBlock ${nocolor}and current block is${white} $currentBlock${nocolor}; same\n"
        echo -e " $(date +%m.%d.%Y_%H:%M:%S) : ${lightpurple}Restarting ${PROJECT}_n${i} since it seems stuck at $currentBlock.${nocolor}"  | tee -a "$LOGFILE"
        echo -e " "
        systemctl stop "${PROJECT}"_n${i}

        # display countdown timer on screen
        seconds=5; date1=$((`date +%s` + $seconds));
        while [ "$date1" -ge `date +%s` ]; do
            echo -ne "          $(date -u --date @$(($date1 - `date +%s` )) +%H:%M:%S)\r";
            sleep 0.5
        done

        systemctl start "${PROJECT}"_n${i}

        for ((T=1;T<=3;T++));
        do
            # wait 5 minutes to ensure that the chain is unstuck, and if it isn't, nuke and resync the chain on that instance
            echo -e "\n Pausing for 5 minutes to let instance start and resume syncing"
            echo -e " It is not recommended that you cancel or interrupt or you will"
            echo -e " be left in maintenance mode and will have to delete the file :"
            echo -e " $INSTALLDIR/temp/updating before other scriptlets will work.\n"

            # display countdown timer on screen
            seconds=300; date1=$((`date +%s` + $seconds));
            while [ "$date1" -ge `date +%s` ]; do
                echo -ne "          $(date -u --date @$(($date1 - `date +%s` )) +%H:%M:%S)\r";
                sleep 0.5
            done

            echo -e " Checking if restarting solved the problem on masternode ${PROJECT}_n${i}"

            if [ ! -s "$INSTALLDIR/temp/blockcount$i" ]
            then previousBlock='null'
            else previousBlock=$(cat $INSTALLDIR/temp/blockcount${i})
            fi

            /usr/local/bin/"${MNODE_DAEMON::-1}"-cli -conf=/etc/masternodes/"${PROJECT}"_n${i}.conf getblockcount > $INSTALLDIR/temp/blockcount${i}
            if [ ! -s "$INSTALLDIR/temp/blockcount$i" ]
            then currentBlock='null'
            else currentBlock=$(cat $INSTALLDIR/temp/blockcount${i})
            fi

            if [ "$previousBlock$" == "$currentBlock$" ]; then
                echo -e " --> I have restarted the masternode and waited 5 minutes $T time(s)." | tee -a "$LOGFILE"
                echo -e " --> $(date +%H:%M:%S) ${lightred}Restarting ${PROJECT}_n${i} didn't fix chain syncing${nocolor}" | tee -a "$LOGFILE"

            else echo -e " --> Previous block was${white} $previousBlock ${nocolor}and current block is${white} $currentBlock${nocolor}." | tee -a "$LOGFILE"
                echo -e " --> $(date +%H:%M:%S) ${lightgreen}${PROJECT}_n${i} appears to be functioning normally again.${nocolor}\n" | tee -a "$LOGFILE"
                FIXED="yes"
                break
            fi
        done

        if [ ! "$FIXED" == "yes" ]; then

            unset $FIXED
            echo -e "${lightblue} Invoking Holy Hand Grenade to reset troublesome masternode ${PROJECT}_n${i}.${nocolor}\n" | tee -a "$LOGFILE"

            # occasional problems with rpcport prevent masternodes from starting
            # Holy Hand Grenade will now reset the RPC port by adding 200 to fix this
            RPCPORTIS=$(sed -n -e '/^rpcport/p' /etc/masternodes/${PROJECT}_n${i}.conf)
            RPCPORTNUMBER=$(echo -e "$RPCPORTIS" | sed 's/[^0-9]*//g')
            let "RPCPORTNUMBER=RPCPORTNUMBER+200"
            sed -i "s/${RPCPORTIS}/rpcport=${RPCPORTNUMBER}/" /etc/masternodes/${PROJECT}_n${i}.conf >> $LOGFILE 2>&1

            # stop the troublesome masternode
            echo -e -n " Stopping ${PROJECT}_n${i} now...  "
            systemctl stop "${PROJECT}"_n${i}
            
            # backup then remove wallet and blockchain data to force resync wallet in case clonesync fails
            cd /var/lib/masternodes/"${PROJECT}"${i}
            cp wallet.dat wallet_backup.$(date +%m.%d.%y).dat
            sudo rm -rf !("wallet_backup.$(date +%m.%d.%y).dat"|"masternode.conf")
            sleep 2

            sudo bash $INSTALLDIR/maintenance/clonesync.sh $i

        else unset $FIXED
            echo -e " Glad to see that worked, exiting loop for this MN \n"
        fi

    else echo -e " Previous block was${white} $previousBlock ${nocolor}and current block is${white} $currentBlock${nocolor}."
        echo -e " ${PROJECT}_n${i} appears to be syncing normally.\n"

    fi

done

# echo -e " Unsetting -update flag \n"
rm -f $INSTALLDIR/temp/updating
rm -f $INSTALLDIR/temp/checkingdaemon

exit 0

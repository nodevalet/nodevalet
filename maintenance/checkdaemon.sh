#!/bin/bash
# Make sure the daemon is not stuck and restart it if it is.
# authorized script to resync entire blockchain in case of catastrophic failure
# Add the following to the crontab (i.e. crontab -e)
# (crontab -l ; echo "*/30 * * * * $INSTALLDIR/maintenance/checkdaemon.sh") | crontab -

LOGFILE='/var/tmp/nodevalet/logs/maintenance.log'
INSTALLDIR='/var/tmp/nodevalet'
INFODIR='/var/tmp/nvtemp'
MNS=$(<$INFODIR/vpsnumber.info)
PROJECT=$(<$INFODIR/vpscoin.info)
PROJECTl=${PROJECT,,}
PROJECTt=${PROJECTl~}
MNODE_DAEMON=$(<$INFODIR/vpsmnode_daemon.info)
MNODE_BINARIES=$(<$INFODIR/vpsbinaries.info)
HNAME=$(<$INFODIR/vpshostname.info)

# extglob was necessary to make rm -- ! possible
shopt -s extglob

if [ -e "$INSTALLDIR/temp/bootstrapping" ]
then echo -e " Skipping checkdaemon.sh because bootstrap is in progress.\n"
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
        echo -e " Previous block is $previousBlock and current block is $currentBlock; same\n"
        echo -e " $(date +%m.%d.%Y_%H:%M:%S) : Auto-restarting ${PROJECT}_n${i} because it seems stuck.\n"  | tee -a "$LOGFILE"
        echo -e " "
        systemctl stop "${PROJECT}"_n${i}

        # display countdown timer on screen
        seconds=5; date1=$((`date +%s` + $seconds));
        while [ "$date1" -ge `date +%s` ]; do
            echo -ne "          $(date -u --date @$(($date1 - `date +%s` )) +%H:%M:%S)\r";
            sleep 0.5
        done

        systemctl start "${PROJECT}"_n${i}

        for ((T=1;T<=5;T++));
        do
            # wait 5 minutes to ensure that the chain is unstuck, and if it isn't, nuke and resync the chain on that instance
            echo -e " Pausing for 5 minutes to let instance start and resume syncing"
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
                echo -e " $(date +%m.%d.%Y_%H:%M:%S) : Restarting ${PROJECT}_n${i} didn't fix chain syncing" | tee -a "$LOGFILE"
                echo -e " I have restarted the MN once and waited 5 minutes $T time(s). \n" | tee -a "$LOGFILE"

            else echo -e " Previous block is $previousBlock and current block is $currentBlock." | tee -a "$LOGFILE"
                echo -e " ${PROJECT}_n${i} appears to be syncing normally again.\n" | tee -a "$LOGFILE"
                FIXED="yes"
                break
            fi
        done

        if [ ! "$FIXED" == "yes" ]; then

            unset $FIXED
            echo -e "$(date +%m.%d.%Y_%H:%M:%S) : Restarting ${PROJECT}_n${i} $T times didn't fix chain" | tee -a "$LOGFILE"
            echo -e " Invoking Holy Hand Grenade to resync entire blockchain\n" | tee -a "$LOGFILE"
            # use clonesync rather than fully resync the chain
            sudo bash $INSTALLDIR/maintenance/clonesync.sh $i
            # sudo systemctl disable "${PROJECT}"_n${i}
            # sudo systemctl stop "${PROJECT}"_n${i}
            # sleep 5
            # cd /var/lib/masternodes/"${PROJECT}"${i}
            # sudo rm -rf !("wallet.dat"|"masternode.conf")
            # sleep 5
            # sudo systemctl enable "${PROJECT}"_n${i}
            # sudo systemctl start "${PROJECT}"_n${i}

        else unset $FIXED
            echo -e " Glad to see that worked, exiting loop for this MN \n"
        fi

    else echo -e " Previous block is $previousBlock and current block is $currentBlock."
        echo -e " ${PROJECT}_n${i} appears to be syncing normally.\n"

    fi

done

# echo -e " Unsetting -update flag \n"
rm -f $INSTALLDIR/temp/updating
#echo -e " Unsetting -update flag."  | tee -a "$LOGFILE"

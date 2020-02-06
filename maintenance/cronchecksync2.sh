#!/bin/bash

# Set Variables
LOGFILE='/var/tmp/nodevalet/logs/maintenance.log'
INSTALLDIR='/var/tmp/nodevalet'
INFODIR='/var/tmp/nvtemp'
MNS=$(<$INFODIR/vpsnumber.info)
PROJECT=$(<$INFODIR/vpscoin.info)
PROJECTl=${PROJECT,,}
PROJECTt=${PROJECTl~}
MNODE_DAEMON=$(<$INFODIR/vpsmnode_daemon.info)
HNAME=$(<$INFODIR/vpshostname.info)

# set hostname variable to the name planted by API installation script
if [ -e /var/tmp/nodevalet/info/vpshostname.info ]
then HNAME=$(<$INFODIR/vpshostname.info)
else HNAME=$(hostname)
fi

# read or assign number of masternodes that are installed
if [ -e $INFODIR/vpsnumber.info ]
then MNS=$(<$INFODIR/vpsnumber.info)
else MNS=1
fi

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

# read first argument to string
i=$1

if [ -z "$i" ]
then echo -e "\n"
    echo -e " $(date +%m.%d.%Y_%H:%M:%S) : Running cronchecksync.sh" | tee -a "$LOGFILE"
    echo -e " cronchecksync.sh was called without an argument and will now exit.\n"  | tee -a "$LOGFILE"
    exit
fi

function sync_check() {
    CNT=$(/usr/local/bin/"${MNODE_DAEMON::-1}"-cli -conf=/etc/masternodes/"${PROJECT}_n${i}".conf getblockcount)
    HASH=$(/usr/local/bin/"${MNODE_DAEMON::-1}"-cli -conf=/etc/masternodes/"${PROJECT}_n${i}".conf getblockhash "${CNT}")
    TIMELINE1=$(/usr/local/bin/"${MNODE_DAEMON::-1}"-cli -conf=/etc/masternodes/"${PROJECT}_n${i}".conf getblock "${HASH}" | grep '"time"')
    TIMELINE=$(echo "$TIMELINE1" | tr -dc '0-9')
    BLOCKS=$(grep "blocks" $INSTALLDIR/getinfo_n${i} | tr -dc '0-9')
    LTRIMTIME=${TIMELINE#*time\" : }
    NEWEST=${LTRIMTIME%%,*}
    TIMEDIF=$(echo -e "$(($(date +%s)-NEWEST))")
    rm -rf $INSTALLDIR/getinfo_n${i} --force
    if ((TIMEDIF <= 300 && TIMEDIF >= -300))
    then echo -e " The blockchain is almost certainly synced.\n" && SYNCED="yes"
    else SYNCED="no"
    fi
}

function check_blocksync() {

        # echo -e "Time $SECONDS"
        rm -rf $INSTALLDIR/getinfo_n${i}
        touch $INSTALLDIR/getinfo_n${i}
        /usr/local/bin/"${MNODE_DAEMON::-1}"-cli -conf=/etc/masternodes/"${PROJECT}_n${i}".conf getinfo > $INSTALLDIR/getinfo_n${i}

        BLOCKS=$(grep "blocks" $INSTALLDIR/getinfo_n${i} | tr -dc '0-9')
        echo -e "\n${lightcyan}    --> $PROJECTt Masternode $i Sync Status <-- ${nocolor}\n"
        echo -e " The current number of synced blocks is:${yellow} ${BLOCKS}${nocolor}"

        # if masternode is just starting up, log it and move on
        if [ "$BLOCKS" == "1" ]
        then echo -e "${lightred} Masternode ${i} is starting up${nocolor}\n"
            if [ -e $INSTALLDIR/temp/"${PROJECT}"_n${i}_synced ]
            then cp $INSTALLDIR/temp/"${PROJECT}"_n${i}_synced $INSTALLDIR/temp/"${PROJECT}"_n${i}_lastnsync
                rm $INSTALLDIR/temp/"${PROJECT}"_n${i}_synced --force
            fi
        touch $INSTALLDIR/temp/"${PROJECT}"_n${i}_nosync
        echo -e "$(date +%m.%d.%Y_%H:%M:%S) -- starting up" >> $INSTALLDIR/temp/"${PROJECT}"_n${i}_nosync
        rm -rf $INSTALLDIR/getinfo_n${i} --force
        exit

        # if masternode is not running, check if there's a good reason; if not re-enable it
        elif ! [ "$BLOCKS" ]
        then echo -e "${lightred} Masternode ${i} is not running${nocolor}\n"
            if [ -e $INSTALLDIR/temp/"${PROJECT}"_n${i}_synced ]
            then cp $INSTALLDIR/temp/"${PROJECT}"_n${i}_synced $INSTALLDIR/temp/"${PROJECT}"_n${i}_lastnsync
                rm $INSTALLDIR/temp/"${PROJECT}"_n${i}_synced --force
            fi
        touch $INSTALLDIR/temp/"${PROJECT}"_n${i}_nosync
        echo -e "$(date +%m.%d.%Y_%H:%M:%S) -- not running" >> $INSTALLDIR/temp/"${PROJECT}"_n${i}_nosync

            if [ -e "$INSTALLDIR/temp/gettinginfo" ]
            then rm -rf $INSTALLDIR/getinfo_n${i} --force
            exit
            elif [ -e "$INSTALLDIR/temp/shuttingdown" ]
            then rm -rf $INSTALLDIR/getinfo_n${i} --force
            exit
            else echo -e " $(date +%m.%d.%Y_%H:%M:%S) : Re-enabling masternode ${PROJECT}_n${i}.\n" | tee -a "$LOGFILE"
                sudo systemctl enable "${PROJECT}"_n${i} > /dev/null 2>&1
                sudo systemctl start "${PROJECT}"_n${i}
                rm -rf $INSTALLDIR/getinfo_n${i} --force
                exit
            fi
        
        # find out where the sync is at
        else sync_check
        fi

        # resume after running sync_check
        if [ "$SYNCED" = "yes" ]
        then echo -e "${lightgreen} --> Masternode ${PROJECT}_n${i} is synced${nocolor}\n"
            touch $INSTALLDIR/temp/"${PROJECT}"_n${i}_synced
            echo -e "$(date +%m.%d.%Y_%H:%M:%S)" >> $INSTALLDIR/temp/"${PROJECT}"_n${i}_synced
            rm $INSTALLDIR/temp/"${PROJECT}"_n${i}_lastnsync --force
                if [ -e $INSTALLDIR/temp/"${PROJECT}"_n${i}_nosync ]
                then cp $INSTALLDIR/temp/"${PROJECT}"_n${i}_nosync $INSTALLDIR/temp/"${PROJECT}"_n${i}_lastosync
                    rm $INSTALLDIR/temp/"${PROJECT}"_n${i}_nosync --force
                fi
            exit
        else echo -e "${lightred} --> Masternode ${PROJECT}_n${i} is NOT synced${nocolor}\n"
            touch $INSTALLDIR/temp/"${PROJECT}"_n${i}_nosync
            echo -e "$(date +%m.%d.%Y_%H:%M:%S)" >> $INSTALLDIR/temp/"${PROJECT}"_n${i}_nosync
            rm $INSTALLDIR/temp/"${PROJECT}"_n${i}_lastosync --force
                if [ -e $INSTALLDIR/temp/"${PROJECT}"_n${i}_synced ]
                then cp $INSTALLDIR/temp/"${PROJECT}"_n${i}_synced $INSTALLDIR/temp/"${PROJECT}"_n${i}_lastnsync
                    rm $INSTALLDIR/temp/"${PROJECT}"_n${i}_synced --force
                fi
            exit
        fi

    # This file will contain if the chain is currently not synced
    # $INSTALLDIR/temp/"${PROJECT}"_n${i}_nosync  (eg. audax_n2_nosync)

    # This file will contain time of when the chain was fully synced
    # $INSTALLDIR/temp/"${PROJECT}"_n${i}_synced  (eg. audax_n2_synced)

    # This file will contain time of when the chain was last out-of-sync
    # $INSTALLDIR/temp/"${PROJECT}"_n${i}_lastosync  (eg. audax_n2_lastosync)

    # If no longer synced, this file will contain last time chain was synced
    # $INSTALLDIR/temp/"${PROJECT}"_n${i}_lastnsync  (eg. audax_n2_lastnsync)
}

# This is where the script actually starts
check_blocksync

exit

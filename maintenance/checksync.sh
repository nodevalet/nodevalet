#!/bin/bash

# Set common variables
. /var/tmp/nodevalet/maintenance/vars.sh

if [ -e "$INSTALLDIR/temp/activating" ]
then echo -e " Skipping checksync.sh because the server is activating masternodes.\n"
    exit
fi

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

# read first argument to string
i=$1

# if no argument was given, give instructions and ask for one

if [ -z "$i" ]
then clear
    echo -e "\n This scriptlet will check the syncing status of a masternode."
    echo -e " Which masternode would you like to look into? \n"

fi
while :; do
    if [ -z "$i" ] ; then read -p " --> " i ; fi
    [[ $i =~ ^[0-9]+$ ]] || { echo -e "{lightred}\n --> I only recognize numbers; enter a number between 1 and $MNS...${nocolor}\n"; i=""; continue; }
    if ((i >= 1 && i <= MNS)); then break
    else echo -e "\n${lightred} --> I can't find masternode $i; enter a number between 1 and $MNS.${nocolor}\n"
        i=""
    fi
done

function sync_check() {
    CNT=$(/usr/local/bin/"${MNODE_DAEMON::-1}"-cli -conf=/etc/masternodes/"${PROJECT}_n${i}".conf getblockcount)
    # echo -e "CNT is set to $CNT"
    HASH=$(/usr/local/bin/"${MNODE_DAEMON::-1}"-cli -conf=/etc/masternodes/"${PROJECT}_n${i}".conf getblockhash "${CNT}")
    #echo -e "HASH is set to $HASH"
    TIMELINE1=$(/usr/local/bin/"${MNODE_DAEMON::-1}"-cli -conf=/etc/masternodes/"${PROJECT}_n${i}".conf getblock "${HASH}" | grep '"time"')
    TIMELINE=$(echo "$TIMELINE1" | tr -dc '0-9')
    BLOCKS=$(grep "blocks" $INSTALLDIR/getinfo_n${i} | tr -dc '0-9')
    CONNECTIONS=$(grep "connections" $INSTALLDIR/getinfo_n${i} | tr -dc '0-9')
    # echo -e "TIMELINE is set to $TIMELINE"
    LTRIMTIME=${TIMELINE#*time\" : }
    # echo -e "LTRIMTIME is set to $LTRIMTIME"
    NEWEST=${LTRIMTIME%%,*}
    # echo -e "NEWEST is set to $NEWEST"
    TIMEDIF=$(echo -e "$(($(date +%s)-NEWEST))")
    echo -e " This masternode is${yellow} $TIMEDIF seconds ${nocolor}behind the latest block."
    # check if current to within 5 minutes
    if ((TIMEDIF <= 300 && TIMEDIF >= -300))
    then echo -e " The blockchain is almost certainly synced.\n"
        echo -e " $(date +%m.%d.%Y_%H:%M:%S) : ${lightgreen}Masternode ${PROJECT}_n${i} synced completely ${nocolor}" | tee -a "$LOGFILE"
        SYNCED="yes"
    else echo -e " That's the same as${yellow} $((($(date +%s)-NEWEST)/3600)) hours${nocolor} or${yellow} $((($(date +%s)-NEWEST)/86400)) days${nocolor} behind the present.\n"
        SYNCED="no"
    fi
}

function check_blocksync() {

    # check if blockchain of n1 is synced for 24 hours (86400 seconds) before reporting failure
    end=$((SECONDS+86400))
    # end=$((SECONDS+86400))

    while [ $SECONDS -lt $end ]; do
        # echo -e "Time $SECONDS"
        touch $INSTALLDIR/getinfo_n${i}
        /usr/local/bin/"${MNODE_DAEMON::-1}"-cli -conf=/etc/masternodes/"${PROJECT}_n${i}".conf getinfo > $INSTALLDIR/getinfo_n${i}
        clear

        # if  masternode not running, echo masternode not running and break
        BLOCKS=$(grep "blocks" $INSTALLDIR/getinfo_n${i} | tr -dc '0-9')
        CONNECTIONS=$(grep "connections" $INSTALLDIR/getinfo_n${i} | tr -dc '0-9')
        echo -e "\n${lightcyan}    --> $PROJECTt Masternode Sync Status <-- ${nocolor}\n"

        echo -e "${white} Masternode n$i is currently synced through block: ${lightpurple}$BLOCKS${nocolor}\n"
        echo -e " The current number of synced blocks is:${yellow} ${BLOCKS}${nocolor}"
        echo -e " The masternode has this many active connections:${yellow} ${CONNECTIONS}${nocolor}"

        if ((BLOCKS <= 1 )) ; then echo -e -n "${lightred} Masternode is not syncing,${nocolor} but "

            # check if daemon is running and report
            if ps -A | grep "$MNODE_DAEMON" > /dev/null
            then echo -e -n "${lightgreen}$MNODE_DAEMON is running.${nocolor}\n"
            else echo -e -n "${lightred}$MNODE_DAEMON is NOT running.${nocolor}\n"
                rm -rf $INSTALLDIR/getinfo_n${i} --force
                break
            fi

        else sync_check
        fi

        if [ "$SYNCED" = "yes" ]; then echo -e "              ${lightgreen}Masternode synced${nocolor}\n" ; break
        else echo -e "${white} Blockchain is ${lightred}not yet synced${nocolor}; will check again in 30 seconds${nocolor}\n"
            echo -e " I have been checking this masternode for:${lightcyan} $SECONDS seconds${nocolor}"
            echo -e "${white} Script will timeout if not synced in the next:${lightcyan} $(((86400-SECONDS) / (3600))) hours${nocolor}\n"
            # if clonesyncing, display warning not to interrupt it
            if [ -e $INSTALLDIR/temp/clonesyncing ]
            then echo -e " ${lightred}Clonesync_all in progress; DO NOT INTERRUPT THIS PROCESS!!${nocolor}"
                echo -e " ${lightred}Bootstrap will resume once your first blockchain is synced.${nocolor}\n"
            else :
            fi
            # insert a little humor
            curl -s "http://api.icndb.com/jokes/random" | jq '.value.joke'
            echo -e "\n"
            rm -rf $INSTALLDIR/getinfo_n${i} --force

            # display countdown timer on screen
            countdown=30; date1=$((`date +%s` + $countdown));
            while [ "$date1" -ge `date +%s` ]; do
                echo -ne "   ---> Refreshing in:  $(date -u --date @$(($date1 - `date +%s` )) +%H:%M:%S)\r";
                sleep 0.5
            done
        fi
    done

    if [ "$SYNCED" = "no" ]; then echo -e "${lightred} Masternode n$i did not sync in the allowed time${nocolor}\n" | tee -a "$LOGFILE"
        # exit the script because syncing did not occur
        rm -rf $INSTALLDIR/getinfo_n${i} --force
        exit
else : ; fi

    #   create file to signal that this blockchain is synced (I moved this to the cronchecksync)
    #   echo -e " Setting flag at: $INSTALLDIR/temp/${PROJECT}_n${i}_synced\n"
    #   touch $INSTALLDIR/temp/"${PROJECT}"_n${i}_synced

}

# This is where the script actually starts
check_blocksync

rm -rf $INSTALLDIR/getinfo_n${i} --force
exit

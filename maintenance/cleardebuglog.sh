#!/bin/bash
# Clear debug.log every week
# Trim excess sync flags

# exit with error if not run as root/sudo
if [ "$(id -u)" != "0" ]
then echo -e "\n Please re-run as root or sudo.\n"
    exit 1
fi

# Set common variables
. /var/tmp/nodevalet/maintenance/vars.sh

for ((i=1;i<=$MNS;i++));
do /bin/date > /var/lib/masternodes/"$PROJECT"${i}/debug.log

    # clear more then 4 hours of sync flags from 'synced'
    syncedEXISTS=$(ls $INSTALLDIR/temp/ | grep "${PROJECT}"_n${i}_synced)
    if [[ "${syncedEXISTS}" ]]
    then
        # count number of lines in the file, save to variable
        syncedLINES=$(wc -l $INSTALLDIR/temp/"${PROJECT}"_n${i}_synced | awk '{ print $1 }')
        # determine how many lines to remove
        EXTRA=$(( $syncedLINES - 50 ))
        # delete range of lines 1 through difference above
        if (( $EXTRA >= 1 ))
        then sed -i "1,${EXTRA}d" $INSTALLDIR/temp/"${PROJECT}"_n${i}_synced
        fi
    fi

    # clear more then 4 hours of sync flags from 'lastosync'
    syncedEXISTS=$(ls $INSTALLDIR/temp/ | grep "${PROJECT}"_n${i}_lastosync)
    if [[ "${syncedEXISTS}" ]]
    then
        # count number of lines in the file, save to variable
        syncedLINES=$(wc -l $INSTALLDIR/temp/"${PROJECT}"_n${i}_lastosync | awk '{ print $1 }')
        # determine how many lines to remove
        EXTRA=$(( $syncedLINES - 50 ))
        # delete range of lines 1 through difference above
        if (( $EXTRA >= 1 ))
        then sed -i "1,${EXTRA}d" $INSTALLDIR/temp/"${PROJECT}"_n${i}_lastosync
        fi
    fi

    # clear more then 4 hours of sync flags from 'nosync'
    syncedEXISTS=$(ls $INSTALLDIR/temp/ | grep "${PROJECT}"_n${i}_nosync)
    if [[ "${syncedEXISTS}" ]]
    then
        # count number of lines in the file, save to variable
        syncedLINES=$(wc -l $INSTALLDIR/temp/"${PROJECT}"_n${i}_nosync | awk '{ print $1 }')
        # determine how many lines to remove
        EXTRA=$(( $syncedLINES - 50 ))
        # delete range of lines 1 through difference above
        if (( $EXTRA >= 1 ))
        then sed -i "1,${EXTRA}d" $INSTALLDIR/temp/"${PROJECT}"_n${i}_nosync
        fi
    fi

    # clear more then 4 hours of sync flags from 'lastnsync'
    syncedEXISTS=$(ls $INSTALLDIR/temp/ | grep "${PROJECT}"_n${i}_lastnsync)
    if [[ "${syncedEXISTS}" ]]
    then
        # count number of lines in the file, save to variable
        syncedLINES=$(wc -l $INSTALLDIR/temp/"${PROJECT}"_n${i}_lastnsync | awk '{ print $1 }')
        # determine how many lines to remove
        EXTRA=$(( $syncedLINES - 50 ))
        # delete range of lines 1 through difference above
        if (( $EXTRA >= 1 ))
        then sed -i "1,${EXTRA}d" $INSTALLDIR/temp/"${PROJECT}"_n${i}_lastnsync
        fi
    fi

done

echo -e " $(date +%m.%d.%Y_%H:%M:%S) : ${lightcyan}Weekly maintenance underway; running cleardebuglog.sh${nocolor}" | tee -a "$LOGFILE"
echo -e " --> Old masterndoe debug logs and sync flag data have been purged \n"  | tee -a "$LOGFILE"

exit

# these are all my sync flags
# $INSTALLDIR/temp/"${PROJECT}"_n${i}_synced
# $INSTALLDIR/temp/"${PROJECT}"_n${i}_lastosync
# $INSTALLDIR/temp/"${PROJECT}"_n${i}_nosync
# $INSTALLDIR/temp/"${PROJECT}"_n${i}_lastnsync

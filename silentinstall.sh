#!/bin/bash
# Silently install masternodes and insert privkeys
#
clear

function setup_environment() {

# create a dummy file which will be created by CT's API
rm -rf /root/installtemp
mkdir /root/installtemp
touch /root/installtemp/vpsnumber.info
# read -p "How many masternodes will you install?" MNS
echo "10" >> /root/installtemp/vpsnumber.info
MNS=`cat /root/installtemp/vpsnumber.info`
echo -e "Going to create $MNS masternodes\n"
sleep 2

# Set Vars
LOGFILE='/root/installtemp/silentinstall.log'
INSTALLDIR='/root/installtemp'
}

function begin_log() {
# Create Log File and Begin
rm -rf $LOGFILE
echo -e "---------------------------------------------------- " | tee -a "$LOGFILE"
echo -e " `date +%m.%d.%Y_%H:%M:%S` : SCRIPT STARTED SUCCESSFULLY " | tee -a "$LOGFILE"
echo -e "---------------------------------------------------- " | tee -a "$LOGFILE"
echo -e "---------- AKcryptoGUY's Dubious Script ------------ " | tee -a "$LOGFILE"
echo -e "---------------------------------------------------- \n" | tee -a "$LOGFILE"
# sleep 1
}



function get_genkeys() {
   # Create a file containing all the masternode genkeys you want
   echo -e "Saving genkey(s) to $INSTALLDIR/genkeys \n"  | tee -a "$LOGFILE"
   rm $INSTALLDIR/genkeys 
   touch $INSTALLDIR/genkeys  | tee -a "$LOGFILE"
   for ((i=1;i<=$MNS;i++)); 
   do 
	/usr/local/bin/helium-cli -conf=/etc/masternodes/helium_n1.conf masternode genkey >> $INSTALLDIR/genkeys   | tee -a "$LOGFILE"
	echo -e "$(sed -n ${i}p $INSTALLDIR/genkeys)" >> $INSTALLDIR/GENKEY$i
	echo "masternodeprivkey=" > $INSTALLDIR/MNPRIV1
	paste $INSTALLDIR/MNPRIV1 $INSTALLDIR/GENKEY$i > $INSTALLDIR/GENKEY${i}FIN
	tr -d '[:blank:]' < $INSTALLDIR/GENKEY${i}FIN > $INSTALLDIR/MNPRIVKEY$i
	rm $INSTALLDIR/GENKEY${i}FIN ; rm $INSTALLDIR/GENKEY$i

#        echo -e "MNPRIVKEY$i is set to:"
#        cat $INSTALLDIR/MNPRIVKEY$i

	GENKEYVAR=`cat $INSTALLDIR/MNPRIVKEY$i`
	# this is an alternative that also works  GENKEYVAR=$(</root/installtemp/MNPRIVKEY$i)
	# echo -e "GENKEYVAR = $GENKEYVAR"

# sed -i 's/^masternodeprivkey=.*/$DUMMYKEY/' /etc/masternodes/helium_n$i.conf >> $LOGFILE 2>&1

done

	echo -e "This is the contents of your file $INSTALLDIR/genkeys:"
	# cat will display the entire contents of a file
	cat $INSTALLDIR/genkeys
	echo -e "\n"

echo -e "Print a few of those new genkeys"
cat $INSTALLDIR/MNPRIVKEY1
cat $INSTALLDIR/MNPRIVKEY2
cat $INSTALLDIR/MNPRIVKEY3

ls $INSTALLDIR


# read -p "Does this look the way you expected?" LOOKP
 }


function get_blocks() {
# echo "grep "blocks" $INSTALLDIR/getinfo_n1" 
BLOCKS=$(grep "blocks" $INSTALLDIR/getinfo_n1 | tr -dc '0-9')
echo -e "Masternode 1 is currently synced through block $BLOCKS.\n"
}

function sync_check() {
CNT=`/usr/local/bin/helium-cli -conf=/etc/masternodes/helium_n1.conf getblockcount`
# echo -e "CNT is set to $CNT"
HASH=`/usr/local/bin/helium-cli -conf=/etc/masternodes/helium_n1.conf getblockhash ${CNT}`
#echo -e "HASH is set to $HASH"
TIMELINE1=`/usr/local/bin/helium-cli -conf=/etc/masternodes/helium_n1.conf getblock ${HASH} | grep '"time"'`
TIMELINE=$(echo $TIMELINE1 | tr -dc '0-9')
BLOCKS=$(grep "blocks" /var/helium/getinfo_n1 | tr -dc '0-9')
# echo -e "TIMELINE is set to $TIMELINE"
LTRIMTIME=${TIMELINE#*time\" : }
# echo -e "LTRIMTIME is set to $LTRIMTIME"
NEWEST=${LTRIMTIME%%,*}
# echo -e "NEWEST is set to $NEWEST"
TIMEDIF=$(echo -e "$((`date +%s`-$NEWEST))")
echo -e "This masternode is $TIMEDIF seconds behind the latest block." 
   #check if current
   if (($TIMEDIF <= 60 && $TIMEDIF >= -60))
	then echo -e "The blockchain is almost certainly synced.\n"
	SYNCED="yes"
	else echo -e "That's the same as $(((`date +%s`-$NEWEST)/3600)) hours or $(((`date +%s`-$NEWEST)/86400)) days behind.\n"
	SYNCED="no"
   fi	
}


function install_mns() {
if [ -e /etc/masternodes/helium_n1.conf ]
then
echo -e "Masternodes seem to already be installed, skipping this part"
else

cd ~/
sudo git clone https://github.com/heliumchain/vps.git && cd vps

# this next may not be true
# masternodes will not start syncing the blockchain without a privatekey
# install the masternodes with the dummykey and replace it later on
DUMMYKEY="masternodeprivkey=7Qwk3FNnujGCf8SjovuTNTbLhyi8rs8TMT9ou1gKNonUeQmi91Z"
# sed -i 's/^masternodeprivkey=.*/$DUMMYKEY/' config/helium/helium.conf >> $LOGFILE 2>&1
sudo ./install.sh -p helium -c $MNS
activate_masternodes_helium
sleep 5
# read -p "It looks like masternodes installed correctly, can I continue? " CONTINUEP

fi
}

function check_blocksync() {
end=$((SECONDS+7200))

while [ $SECONDS -lt $end ]; do
    echo -e "Time $SECONDS"
    
	rm -rf $INSTALLDIR/getinfo_n1
	touch $INSTALLDIR/getinfo_n1
	/usr/local/bin/helium-cli -conf=/etc/masternodes/helium_n1.conf getinfo  | tee -a $INSTALLDIR/getinfo_n1
	clear
    
    # if  masternode not running, echo masternode not running and break
    BLOCKS=$(grep "blocks" $INSTALLDIR/getinfo_n1 | tr -dc '0-9')
    echo -e "$BLOCKS is the current number of blocks"
    
    if (($BLOCKS <= 1 )) ; then echo "Masternode is not syncing" ; break
    else sync_check
    fi
    
    if [ "$SYNCED" = "yes" ]; then printf "${lightcyan}" ; echo "Masternode synced" ; printf "${nocolor}" ; break
    else echo -e "Blockchain not synced; will check again in 5 seconds\n"
    sleep 5
    fi
done

    if [ "$SYNCED" = "no" ]; then printf "${lightred}" ; echo "Masternode did not sync in allowed time" ; printf "${nocolor}"
    else : ; fi

echo -e "All done."
}

function silent_harden() {

if [ -e /var/log/server_hardening.log ]
then
echo -e "System seems to already be hard, skipping this part"
else

cd ~/code-red/vps-harden
bash get-hard.sh

fi
}

setup_environment
begin_log

silent_harden
install_mns
get_genkeys

# check_blocksync
# sync_check

echo -e "Log of events saved to: $LOGFILE \n"

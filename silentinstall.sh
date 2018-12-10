#!/bin/bash
# Silently install masternodes and insert privkeys

function setup_environment() {
# Set Variables
INSTALLDIR='/root/installtemp'
LOGFILE='/root/installtemp/silentinstall.log'

# create root/installtemp if it doesn't exist
	if [ ! -d $INSTALLDIR ]
	then mkdir $INSTALLDIR
	echo -e "creating /root/installtemp"  | tee -a "$LOGFILE"
	else :
	fi

# set hostname variable to the name planted by install script
	if [ -e $INSTALLDIR/vpshostname.info ]
	then HNAME=$(<$INSTALLDIR/vpshostname.info)
	echo -e "vpshostname.info found, setting HNAME to $HNAME"  | tee -a "$LOGFILE"
	else HNAME=`hostname`
	echo -e "vpshostname.info not found, setting HNAME to $HNAME"  | tee -a "$LOGFILE"
	fi

# create or assign customssh
	if [ -s $INSTALLDIR/vpssshport.info ]
	then SSHPORT=$(<$INSTALLDIR/vpssshport.info)
	echo -e "vpssshport.info found, setting SSHPORT to $SSHPORT"  | tee -a "$LOGFILE"
	else SSHPORT='22'
	echo -e "vpssshport.info not found, setting SSHPORT to default ($SSHPORT)"  | tee -a "$LOGFILE"
	fi

# create or assign mnprefix
	if [ -s $INSTALLDIR/vpsmnprefix.info ]
	then :
	echo -e "vpsmnprefix.info found, will pull masternode aliases from that"  | tee -a "$LOGFILE"
	else MNPREFIX=`hostname`
	echo -e "vpsmnprefix.info not found, will generate aliases from hostname ($MNPREFIX)"  | tee -a "$LOGFILE"
	fi

# read or assign number of masternodes to install
	if [ -e $INSTALLDIR/vpsnumber.info ]
	then MNS=$(<$INSTALLDIR/vpsnumber.info)
	echo -e "vpsnumber.info found, setting number of masternodes to $MNS"  | tee -a "$LOGFILE"
	# create a subroutine here to check memory and size MNS appropriately
	# or prompt user how many they would like to build
	else MNS=5
	echo -e "vpsnumber.info not found, will build $MNS for now"  | tee -a "$LOGFILE"
	fi
	
# read or collect masternode addresses
	if [ -e $INSTALLDIR/vpsmnaddress.info ]
	then :
	# create a subroutine here to check memory and size MNS appropriately
	else echo -e " Before we can begin, we need to collect $MNS masternode addresses."
	echo -e "Manually gathering masternode addresses from user"  | tee -a "$LOGFILE"
	echo -e " This logic does not presently allow for any mistakes; be careful."
	echo -e " In your local wallet, generate the addresses and then paste them below. \n"
		for ((i=1;i<=$MNS;i++)); 
		do 
		echo -e " Please enter the masternode address for masternode #$i :"
		read -p "  --> " MNADDP
		echo "$MNADDP" >> $INSTALLDIR/vpsmnaddress.info
		echo -e "Masternode $i address set to: $MNADDP."  | tee -a "$LOGFILE"
		# add error checking logic and repeat if necessary
		done
	fi
	
	# enable softwrap so masternode.conf file can be easily copied
	sed -i "s/# set softwrap/set softwrap/" /etc/nanorc >> $LOGFILE 2>&1	
}

function begin_log() {
# Create Log File and Begin
echo -e "---------------------------------------------------- " | tee -a "$LOGFILE"
echo -e " `date +%m.%d.%Y_%H:%M:%S` : SCRIPT STARTED SUCCESSFULLY " | tee -a "$LOGFILE"
echo -e "---------------------------------------------------- " | tee -a "$LOGFILE"
echo -e "--------- AKcryptoGUY's Code Red Script ------------ " | tee -a "$LOGFILE"
echo -e "---------------------------------------------------- \n" | tee -a "$LOGFILE"
echo -e " I am going to create $MNS masternodes and install them\n" | tee -a "$LOGFILE"

# sleep 1
}

function add_cron() {
# reboot logic for status feedback
	echo -e "Adding crontab"  | tee -a "$LOGFILE"
	(crontab -l ; echo "*/1 * * * * /root/installtemp/postinstall_api.sh") | crontab -   | tee -a "$LOGFILE"
}

function silent_harden() {
	# modify get-hard.sh to add a file when complete, and check for that instead of server-hardening.log
	if [ -e /var/log/server_hardening.log ]
	then echo -e "System seems to already be hard, skipping this part" | tee -a "$LOGFILE"
	else echo -e "System is not yet secure, running VPS Hardening script" | tee -a "$LOGFILE"
	cd ~/code-red/vps-harden
	bash get-hard.sh
	fi
	echo -e "Installing jq package" | tee -a "$LOGFILE"
	apt-get -qqy -o=Dpkg::Use-Pty=0 -o=Acquire::ForceIPv4=true install jq | tee -a "$LOGFILE"
	echo -e "Inserting random joke because Chuck Norris told me to\n" | tee -a "$LOGFILE"
	curl -s "http://api.icndb.com/jokes/random" | jq '.value.joke' | tee -a "$LOGFILE"
	echo -e "\n"
}

function install_mns() {
	if [ -e /etc/masternodes/helium_n1.conf ]
	then touch $INSTALLDIR/mnsexist
	echo -e "Pre-existing masternodes detected; no changes to them will be made" > $INSTALLDIR/mnsexist
	echo -e "Masternodes seem to already be installed, skipping this part" | tee -a "$LOGFILE"
	else
	cd ~/
	echo -e "Downloading Nodemaster's VPS script (from heliumchain repo)" | tee -a "$LOGFILE"
	#sudo git clone https://github.com/heliumchain/vps.git && cd vps
	cd vps
	echo -e "Launching Nodemaster using ./install.sh -p helium" | tee -a "$LOGFILE"
	sudo ./install.sh -p helium -c $MNS
	
	echo -e "activating_masternodes_helium" | tee -a "$LOGFILE"
	activate_masternodes_helium echo -e | tee -a "$LOGFILE"
	sleep 3
		# check if heliumd was built correctly and started
		ps -A |  grep helium >> $INSTALLDIR/HELIUMDs
		if [ -s $INSTALLDIR/HELIUMDs ]
		then echo -e "It looks like VPS install script completed and heliumd is running... " | tee -a "$LOGFILE"
		# report back to mothership
		echo -e "Reporting heliumd build initiation to the mothership" | tee -a "$LOGFILE"
		curl -X POST https://www.heliumstats.online/code-red/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Heliumd has started..."}'
		else echo -e "It looks like VPS install script failed, heliumd is not running... " | tee -a "$LOGFILE"
		echo -e "Aborting installation, can't install masternodes without heliumd" | tee -a "$LOGFILE"
		# report error, exit script maybe or see if it can self-correct
		echo -e "Reporting heliumd build failure to the mothership" | tee -a "$LOGFILE"
		curl -X POST https://www.heliumstats.online/code-red/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Error: Heliumd failed to build or start"}'
		exit
		fi
	fi
}

function get_genkeys() {
# Iteratively create all masternode variables for masternode.conf
# Do not break any pre-existing masternodes
if [ -s $INSTALLDIR/mnsexist ]
then echo -e "Skipping get_genkeys function due to presence of $INSTALLDIR/mnsexist" | tee -a "$LOGFILE"
else
   		# Create a file containing all masternode genkeys
   		echo -e "Saving genkey(s) to $INSTALLDIR/genkeys \n"  | tee -a "$LOGFILE"
   		# rm $INSTALLDIR/genkeys --force
   		touch $INSTALLDIR/genkeys

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

	# get or iterate mnprefixes
	if [ -s $INSTALLDIR/vpsmnprefix.info ] ; then
		echo -e "$(sed -n ${i}p $INSTALLDIR/vpsmnprefix.info)" >> $INSTALLDIR/mnaliases
	else echo -e "${MNPREFIX}-MN$i" >> $INSTALLDIR/mnaliases
	fi
	
	# create masternode prefix files
	echo -e "$(sed -n ${i}p $INSTALLDIR/mnaliases)" >> $INSTALLDIR/MNALIAS$i

	# create masternode address files
	echo -e "$(sed -n ${i}p $INSTALLDIR/vpsmnaddress.info)" > $INSTALLDIR/MNADD$i

	# create masternode genkeys
	/usr/local/bin/helium-cli -conf=/etc/masternodes/helium_n1.conf masternode genkey >> $INSTALLDIR/genkeys   | tee -a "$LOGFILE"
	echo -e "$(sed -n ${i}p $INSTALLDIR/genkeys)" >> $INSTALLDIR/GENKEY$i
	echo "masternodeprivkey=" > $INSTALLDIR/MNPRIV1
	
	# append "masternodeprivkey="
	paste $INSTALLDIR/MNPRIV1 $INSTALLDIR/GENKEY$i > $INSTALLDIR/GENKEY${i}FIN
	tr -d '[:blank:]' < $INSTALLDIR/GENKEY${i}FIN > $INSTALLDIR/MNPRIVKEY$i
	
	# assign GENKEYVAR to the full line masternodeprivkey=xxxxxxxxxx
	GENKEYVAR=`cat $INSTALLDIR/MNPRIVKEY$i`
	# this is an alternative text that also works GENKEYVAR=$(</root/installtemp/MNPRIVKEY$i)

	# insert new genkey into project_n$i.conf files
	sed -i "s/^masternodeprivkey=.*/$GENKEYVAR/" /etc/masternodes/helium_n$i.conf >> $LOGFILE 2>&1

	# create file with IP addresses
	sed -n -e '/^bind/p' /etc/masternodes/helium_n$i.conf >> $INSTALLDIR/mnipaddresses
	
	# remove "bind=" from mnipaddresses
	sed -i "s/bind=//" $INSTALLDIR/mnipaddresses >> log 2>&1
	
	# the next line produces the IP addresses for this masternode
	echo -e "$(sed -n ${i}p $INSTALLDIR/mnipaddresses)" > $INSTALLDIR/IPADDR$i
	
	# obtain txid
	# curl -s "https://www.heliumchain.info/api/address/ACTUALHELIUMADDRESS" | jq '.["utxo"][0]["txId","n"]' | tr -d '["]'`
	curl -s "https://www.heliumchain.info/api/address/`cat $INSTALLDIR/MNADD$i`" | jq '.["utxo"][0]["txId","n"]' | tr -d '["]' > $INSTALLDIR/TXID$i
	TX=`echo $(cat $INSTALLDIR/TXID$i)`
	echo -e $TX >> $INSTALLDIR/txid
	echo -e $TX > $INSTALLDIR/TXID$i
	# replace null with txid info
	sed -i "s/.*null null/collateral_output_txid tx/" $INSTALLDIR/txid >> $INSTALLDIR/txid 2>&1
	sed -i "s/.*null null/collateral_output_txid tx/" $INSTALLDIR/TXID$i >> $INSTALLDIR/TXID$i 2>&1
	
	# merge all vars into masternode.conf
	# this is the output to return to MNO
	echo "|" > $INSTALLDIR/DELIMETER
	paste -d '|' $INSTALLDIR/DELIMETER $INSTALLDIR/MNALIAS$i $INSTALLDIR/IPADDR$i $INSTALLDIR/GENKEY$i $INSTALLDIR/TXID$i >> $INSTALLDIR/masternode.all
			
	# this is the output to return to consumer
	paste -d ' ' $INSTALLDIR/MNALIAS$i $INSTALLDIR/IPADDR$i $INSTALLDIR/GENKEY$i $INSTALLDIR/TXID$i >> $INSTALLDIR/masternode.conf

# declutter ; take out trash
rm $INSTALLDIR/GENKEY${i}FIN ; rm $INSTALLDIR/GENKEY$i ; rm $INSTALLDIR/IPADDR$i ; rm $INSTALLDIR/MNADD$i
rm $INSTALLDIR/MNALIAS$i ; rm $INSTALLDIR/MNPRIV*$i ; rm $INSTALLDIR/TXID$i ; rm $INSTALLDIR/MNPRIV1
rm $INSTALLDIR/HELIUMDs ; rm $INSTALLDIR/DELIMETER

# slow it down to not upset the blockchain API
sleep 2
echo -e "Completed masternode $i loop, moving on..."  | tee -a "$LOGFILE"
done
	
	echo -e "Converting masternode.conf to one delineated line for mothership" | tee -a "$LOGFILE"
	# convert masternode.conf to one delineated line separated using | and ||
	echo "complete" > $INSTALLDIR/complete

	# comment out lines that contain no txid or index
	# sed -i "s/.*collateral_output_txid tx/.*collateral_output_txid tx/" $INSTALLDIR/txid >> $INSTALLDIR/txid 2>&1

	# replace spaces with + temporarily	
	sed -i 's/ /+/g' $INSTALLDIR/masternode.all
	
	# merge "complete" line with masternode.all file and remove \n
	paste -s $INSTALLDIR/complete $INSTALLDIR/masternode.all |  tr -d '[\n]' > $INSTALLDIR/masternode.1
	tr -d '[:blank:]' < $INSTALLDIR/masternode.1 > $INSTALLDIR/masternode.return
	sed -i 's/+/ /g' $INSTALLDIR/masternode.return
	# read masternode data into string for curl
	MASTERNODERETURN=$(<$INSTALLDIR/masternode.return)
	
	# round 2: cleanup and declutter
	echo -e "Cleaning up clutter and taking out trash" | tee -a "$LOGFILE"
	rm $INSTALLDIR/complete --force
	rm $INSTALLDIR/masternode.all --force
	rm $INSTALLDIR/masternode.1 --force

# report back all critial masternode.conf information
echo -e "Beaming masternode.return back to mothership" | tee -a "$LOGFILE"
curl -X POST https://www.heliumstats.online/code-red/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "'"$MASTERNODERETURN"'"}' echo -e "Cleaning up clutter and taking out trash" | tee -a "$LOGFILE"

	echo -e "This is the contents of your file $INSTALLDIR/masternode.conf" | tee -a "$LOGFILE"
	cat $INSTALLDIR/masternode.conf | tee -a "$LOGFILE"
	echo -e "\n"  | tee -a "$LOGFILE"
	
	# lists the garbage leftover after installation
	ls $INSTALLDIR | tee -a "$LOGFILE"
fi
 }

function get_blocks() {
# echo "grep "blocks" $INSTALLDIR/getinfo_n1" 
BLOCKS=$(grep "blocks" $INSTALLDIR/getinfo_n1 | tr -dc '0-9')
echo -e "Masternode 1 is currently synced through block $BLOCKS.\n"
}

function check_blocksync() {
# set SECONDS+XXXXX to however long is reasonable to let the initial
# chain sync continue before reporting an error back to the user
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
    # radio home that blockchain sync was unsuccessful
    # add curl here
    else : ; fi

echo -e "All done."
}

function sync_check() {
CNT=`/usr/local/bin/helium-cli -conf=/etc/masternodes/helium_n1.conf getblockcount`
# echo -e "CNT is set to $CNT"
HASH=`/usr/local/bin/helium-cli -conf=/etc/masternodes/helium_n1.conf getblockhash ${CNT}`
#echo -e "HASH is set to $HASH"
TIMELINE1=`/usr/local/bin/helium-cli -conf=/etc/masternodes/helium_n1.conf getblock ${HASH} | grep '"time"'`
TIMELINE=$(echo $TIMELINE1 | tr -dc '0-9')
BLOCKS=$(grep "blocks" $INSTALLDIR/getinfo_n1 | tr -dc '0-9')
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

function install_binaries() {
#check for binaries and install if found    
cd /root/installtemp
GITAPI_URL="https://api.github.com/repos/heliumchain/helium/releases/latest"
curl -s $GITAPI_URL \
      | grep browser_download_url \
      | grep x86_64-linux-gnu.tar.gz \
      | cut -d '"' -f 4 \
      | wget -qi -
TARBALL="$(find . -name "*x86_64-linux-gnu.tar.gz")"
tar -xzf $TARBALL
EXTRACTDIR=${TARBALL%-x86_64-linux-gnu.tar.gz}
curl -s $GITAPI_URL \
             | grep tag_name > currentversion
cp -r $EXTRACTDIR/bin/. /usr/local/bin/
rm -r $EXTRACTDIR
rm -f $TARBALL
}




function restart_server() {
:
echo -e "Going to restart server in 10 seconds. . . " | tee -a "$LOGFILE"
shutdown -r now
}

# This is where the script actually starts

setup_environment
curl -X POST https://www.heliumstats.online/code-red/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Beginning Install Script..."}'

begin_log
add_cron

curl -X POST https://www.heliumstats.online/code-red/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Updating and Hardening Server..."}'
silent_harden
curl -X POST https://www.heliumstats.online/code-red/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Installing wallet binaries..."}'
install_binaries
curl -X POST https://www.heliumstats.online/code-red/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Building Helium Wallet..."}'
install_mns
curl -X POST https://www.heliumstats.online/code-red/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Configuring Masternodes..."}'
get_genkeys
curl -X POST https://www.heliumstats.online/code-red/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Masternodes Configured..."}'
# need to add a line to broadcast the masternode.conf file back to MNO

curl -X POST https://www.heliumstats.online/code-red/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Restarting Server..."}'
restart_server

# check_blocksync
# sync_check

echo -e "Log of events saved to: $LOGFILE \n"

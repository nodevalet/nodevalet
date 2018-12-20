#!/bin/bash
# Silently install masternodes and insert privkeys

function setup_environment() {
# Set Variables
INSTALLDIR='/var/temp/nodevalet/temp'
LOGFILE='/var/temp/nodevalet/log/silentinstall.log'

# create root/installtemp if it doesn't exist
	if [ ! -d $INSTALLDIR ]
	then mkdir $INSTALLDIR
	else :
	fi

touch '/var/temp/nodevalet/log/checkdaemon.log'

# Create Log File and Begin
echo -e "---------------------------------------------------- " | tee -a "$LOGFILE"
echo -e " `date +%m.%d.%Y_%H:%M:%S` : SCRIPT STARTED SUCCESSFULLY " | tee -a "$LOGFILE"
echo -e "---------------------------------------------------- " | tee -a "$LOGFILE"
echo -e "--------- AKcryptoGUY's Code Red Script ------------ " | tee -a "$LOGFILE"
echo -e "---------------------------------------------------- \n" | tee -a "$LOGFILE"

# set hostname variable to the name planted by install script
	if [ -e $INSTALLDIR/info/vpshostname.info ]
	then HNAME=$(<$INSTALLDIR/info/vpshostname.info)
	echo -e "vpshostname.info found, setting HNAME to $HNAME"  | tee -a "$LOGFILE"
	else HNAME=`hostname`
	echo -e "$HNAME" > $INSTALLDIR/info/vpshostname.info
	echo -e "vpshostname.info not found, setting HNAME to $HNAME"  | tee -a "$LOGFILE"
	fi
curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Your new VPS is now online and reporting installation status ..."}' && echo -e " "
sleep 4
	
# set project name
	if [ -s $INSTALLDIR/info/vpscoin.info ]
	then PROJECT=`cat $INSTALLDIR/info/vpscoin.info`
	echo -e "vpscoin.info found, setting project name to $PROJECT"  | tee -a "$LOGFILE"
	else echo -e "Please check the readme for a list supported coins."
		echo -e " In one word, which coin are installing today? "
		while :; do
		read -p "  --> " PROJECT
			if [ -d $INSTALLDIR/nodemaster/config/${PROJECT,,} ]
			then echo -e "Project name set to ${PROJECT}."  | tee -a "$LOGFILE"
			echo -e "${PROJECT,,}" > $INSTALLDIR/info/vpscoin.info
			PROJECT=`cat $INSTALLDIR/info/vpscoin.info`
			break
			else echo -e " --> $PROJECT is not supported, try again."  | tee -a "$LOGFILE"
			fi
		done
	fi

# read or assign number of masternodes to install
	if [ -e $INSTALLDIR/info/vpsnumber.info ]
	then MNS=$(<$INSTALLDIR/info/vpsnumber.info)
	echo -e "vpsnumber.info found, setting number of masternodes to $MNS"  | tee -a "$LOGFILE"
	# create a subroutine here to check memory and size MNS appropriately
	# or prompt user how many they would like to build
	else echo -e "Please enter the number of masternodes to install : "
		while :; do
		read -p "  --> " MNS
		if (($MNS >= 1 && $MNS <= 50))
		then echo -e "Number of masternodes set to $MNS."  | tee -a "$LOGFILE"
		echo -e "${MNS}" > $INSTALLDIR/info/vpsnumber.info
		break
		else echo -e " --> $MNS is not a number between 1 and 50, try again."  | tee -a "$LOGFILE"
		fi
		done
	fi

# read or collect masternode addresses
	if [ -e $INSTALLDIR/info/vpsmnaddress.info ]
	then :
	# create a subroutine here to check memory and size MNS appropriately
	else echo -e " Before we can begin, we need to collect $MNS masternode addresses."
	echo -e " Manually gathering masternode addresses from user" >> $LOGFILE 2>&1
	echo -e " Please double check your addresses for accuracy."
	echo -e " In your local wallet, generate the addresses and then paste them below. \n"
		for ((i=1;i<=$MNS;i++)); 
		do 
			while :; do
			printf "${cyan}"
			echo -e " Please enter the masternode address for masternode #$i :"
			read -p "  --> " MNADDP
				echo -e "You entered: ${MNADDP}. Is this correct? y/n"
				read -p "  --> " VERIFY
				if [[ $VERIFY == "y" || $VERIFY == "Y" || $VERIFY == "yes" || $VERIFY == "Yes" ]]
				then printf "${cyan}" ; break
  				fi
			done	
		echo "$MNADDP" >> $INSTALLDIR/info/vpsmnaddress.info
		echo -e "Masternode $i address is: $MNADDP.\n"  | tee -a "$LOGFILE"
		done
	fi

echo -e " OK. I am going to install $MNS $PROJECT masternodes on this VPS." | tee -a "$LOGFILE"
echo -e "\n"

# set donation percentage
	if [ -e $INSTALLDIR/info/vpsdonation.info ]
	then DONATE=`cat $INSTALLDIR/info/vpsdonation.info`
	echo -e "vpsdonation.info found, setting DONATE to $DONATE"  | tee -a "$LOGFILE"
	else DONATEN=""
		while [[ ! $DONATE =~ ^[0-9]+$ ]]; do	
		echo -e "Although this script is smart, it didn't write itself. If you"
		echo -e "would like to donate a percentage of your masternode rewards"
		echo -e "to the developers of this script, please enter a number here,"
		echo -e "or enter 0 to not leave a donation.  Recommended donation is 2%.\n"
    		read -p "  --> " DONATE
		done
		echo -e "User has chosen to donate ${DONATE}% of your masternode rewards."  | tee -a "$LOGFILE"
	fi
	
# set donation address front project.env
	curl -LJO https://raw.githubusercontent.com/akcryptoguy/nodevalet/master/nodemaster/config/$PROJECT/$PROJECT.env
	DONATION_ADDRESS=`grep ^DONATION $INSTALLDIR/nodemaster/config/$PROJECT/$PROJECT.env`
	if [ -n $DONATION_ADDRESS ] ; then 
	echo "$DONATION_ADDRESS" > $INSTALLDIR/temp/DONATEADDR
	sed -i "s/DONATION_ADDRESS=//" $INSTALLDIR/temp/DONATEADDR
	DONATEADDR=$(<$INSTALLDIR/temp/DONATEADDR)
	echo -e "Donation address set to $DONATEADDR" | tee -a "$LOGFILE"
	paste -d ':' $INSTALLDIR/temp/DONATEADDR $INSTALLDIR/info/vpsdonation.info > $INSTALLDIR/temp/DONATION
	else
	echo -e "No donation address was detected." | tee -a "$LOGFILE"
	fi

# create or assign customssh
	if [ -s $INSTALLDIR/info/vpssshport.info ]
	then SSHPORT=$(<$INSTALLDIR/info/vpssshport.info)
	echo -e "vpssshport.info found, setting SSHPORT to $SSHPORT"  | tee -a "$LOGFILE"
	else SSHPORT='22'
	echo -e "vpssshport.info not found, setting SSHPORT to default ($SSHPORT)"  | tee -a "$LOGFILE"
	fi

# create or assign mnprefix
	if [ -s $INSTALLDIR/info/vpsmnprefix.info ]
	then :
	echo -e "vpsmnprefix.info found, will pull masternode aliases from that"  | tee -a "$LOGFILE"
	else MNPREFIX=`hostname`
	echo -e "vpsmnprefix.info not found, will generate aliases from hostname ($MNPREFIX)"  | tee -a "$LOGFILE"
	fi
	
# enable softwrap so masternode.conf file can be easily copied
sed -i "s/# set softwrap/set softwrap/" /etc/nanorc >> $LOGFILE 2>&1	

}

function add_cron() {
	echo -e "Adding crontabs"  | tee -a "$LOGFILE"
	chmod 0700 $INSTALLDIR/*.sh
	chmod 0700 $INSTALLDIR/autoupdate/*.sh
	chmod 0700 $INSTALLDIR/maintenance/*.sh
# reboot logic for status feedback
	echo -e "Add crontab to run post install script upon reboot"  | tee -a "$LOGFILE"
	(crontab -l ; echo "*/1 * * * * $INSTALLDIR/maintenance/postinstall_api.sh") | crontab -   | tee -a "$LOGFILE"
# make sure all daemon are running
	echo -e "Add crontab to make sure all daemon are running every 5 minutes"  | tee -a "$LOGFILE"
	(crontab -l ; echo "*/5 * * * * $INSTALLDIR/maintenance/makerun.sh") | crontab -   | tee -a "$LOGFILE"
# automatically check that for stuck blocks and restart masternode if it is stuck
	echo -e "Add crontab to check for stuck blocks every 30 minutes"  | tee -a "$LOGFILE"
	(crontab -l ; echo "*/30 * * * * $INSTALLDIR/maintenance/checkdaemon.sh") | crontab -   | tee -a "$LOGFILE"
# automatically check for updates that require a reboot and reboot if necessary
	echo -e "Add crontab to reboot if required to install updates every ten hours"  | tee -a "$LOGFILE"
	(crontab -l ; echo "30 */10 * * * $INSTALLDIR/maintenance/rebootq.sh") | crontab -   | tee -a "$LOGFILE"
# automatically check for wallet updates every 1 day
	echo -e "Add crontab to check for wallet updates every 12 hours"  | tee -a "$LOGFILE"
	(crontab -l ; echo "0 */12 * * * $INSTALLDIR/autoupdate/autoupdate.sh") | crontab -   | tee -a "$LOGFILE"
# clear daemon debug.log every week
	echo -e "Add crontab to clear daemon debug logs weekly to prevent clog"  | tee -a "$LOGFILE"
	(crontab -l ; echo "@weekly $INSTALLDIR/maintenance/cleardebuglog.sh") | crontab - | tee -a "$LOGFILE"
}

function silent_harden() {
	# modify get-hard.sh to add a file when complete, and check for that instead of server-hardening.log
	if [ -e /var/log/server_hardening.log ]
	then echo -e "System seems to already be hard, skipping this part" | tee -a "$LOGFILE"
	else echo -e "System is not yet secure, running VPS Hardening script" | tee -a "$LOGFILE"
	cd ~ $INSTALLDIR/vps-harden
	bash get-hard.sh
	fi
	echo -e "Installing jq package" | tee -a "$LOGFILE"
	apt-get -qqy -o=Dpkg::Use-Pty=0 -o=Acquire::ForceIPv4=true install jq | tee -a "$LOGFILE"
	echo -e "Inserting random joke because Chuck Norris told me to\n" | tee -a "$LOGFILE"
	curl -s "http://api.icndb.com/jokes/random" | jq '.value.joke' | tee -a "$LOGFILE"
}

function install_mns() {
	if [ -e /etc/masternodes/$PROJECT_n1.conf ]
	then touch $INSTALLDIR/temp/mnsexist
	echo -e "Pre-existing masternodes detected; no changes to them will be made" > $INSTALLDIR/mnsexist
	echo -e "Masternodes seem to already be installed, skipping this part" | tee -a "$LOGFILE"
	else
		cd $INSTALLDIR/nodemaster
		echo -e "Invoking local Nodemaster's VPS script" | tee -a "$LOGFILE"
		# echo -e "Downloading Nodemaster's VPS script (from heliumchain repo)" | tee -a "$LOGFILE"
		# sudo git clone https://github.com/heliumchain/vps.git && cd vps
		echo -e "Launching Nodemaster using bash install.sh -p $PROJECT" | tee -a "$LOGFILE"
		sudo bash install.sh -n 6 -p $PROJECT -c $MNS
		echo -e "activating_masternodes_$PROJECT" | tee -a "$LOGFILE"
		activate_masternodes_$PROJECT echo -e | tee -a "$LOGFILE"
		sleep 1
		
		# check if $PROJECTd was built correctly and started
		ps -A | grep $PROJECT >> $INSTALLDIR/temp/${PROJECT}Ds
		cat $INSTALLDIR/temp/${PROJECT}Ds >> $LOGFILE
		if [ -s $INSTALLDIR/temp/${PROJECT}Ds ]
		then echo -e "It looks like VPS install script completed and ${PROJECT}d is running... " | tee -a "$LOGFILE"
		# report back to mother
		echo -e "Reporting ${PROJECT}d build success to mother" | tee -a "$LOGFILE"
		curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Process '"$PROJECT"'d has started..."}' && echo -e " "
		else echo -e "It looks like VPS install script failed, ${PROJECT}d is not running... " | tee -a "$LOGFILE"
		echo -e "Aborting installation, can't install masternodes without ${PROJECT}d" | tee -a "$LOGFILE"
		# report error, exit script maybe or see if it can self-correct
		echo -e "Reporting ${PROJECT}d build failure to mother" | tee -a "$LOGFILE"
		curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Error: '"$PROJECT"'d failed to build or start"}' && echo -e " "
		exit
		fi
	fi
}

function get_genkeys() {
# Iteratively create all masternode variables for masternode.conf
# Do not break any pre-existing masternodes
if [ -s $INSTALLDIR/temp/mnsexist ]
then echo -e "Skipping get_genkeys function due to presence of $INSTALLDIR/mnsexist" | tee -a "$LOGFILE"
echo -e "Reporting ${PROJECT}d build failure to mother" | tee -a "$LOGFILE"
curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Error: Masternodes already exist on this VPS."}'
		exit
else
   		# Create a file containing all masternode genkeys
   		echo -e "Saving genkey(s) to $INSTALLDIR/temp/genkeys \n"  | tee -a "$LOGFILE"
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
	# create masternode genkeys
	/usr/local/bin/${PROJECT}-cli -conf=/etc/masternodes/${PROJECT}_n1.conf masternode genkey >> $INSTALLDIR/temp/genkeys
	echo -e "$(sed -n ${i}p $INSTALLDIR/temp/genkeys)" >> $INSTALLDIR/temp/GENKEY$i
	echo "masternodeprivkey=" > $INSTALLDIR/temp/MNPRIV1
	done

for ((i=1;i<=$MNS;i++)); 
do

	# get or iterate mnprefixes
	if [ -s $INSTALLDIR/info/vpsmnprefix.info ] ; then
		echo -e "$(sed -n ${i}p $INSTALLDIR/info/vpsmnprefix.info)" >> $INSTALLDIR/temp/mnaliases
	else echo -e "${MNPREFIX}-MN$i" >> $INSTALLDIR/temp/mnaliases
	fi
	
	# create masternode prefix files
	echo -e "$(sed -n ${i}p $INSTALLDIR/temp/mnaliases)" >> $INSTALLDIR/temp/MNALIAS$i

	# create masternode address files
	echo -e "$(sed -n ${i}p $INSTALLDIR/info/vpsmnaddress.info)" > $INSTALLDIR/temp/MNADD$i

	# append "masternodeprivkey="
	paste $INSTALLDIR/temp/MNPRIV1 $INSTALLDIR/temp/GENKEY$i > $INSTALLDIR/temp/GENKEY${i}FIN
	tr -d '[:blank:]' < $INSTALLDIR/temp/GENKEY${i}FIN > $INSTALLDIR/temp/MNPRIVKEY$i
	
	# assign GENKEYVAR to the full line masternodeprivkey=xxxxxxxxxx
	GENKEYVAR=`cat $INSTALLDIR/temp/MNPRIVKEY$i`
	
	# this is an alternative text that also works GENKEYVAR=$(</var/temp/nodevalet/temp/MNPRIVKEY$i)

	# insert new genkey into project_n$i.conf files
	sed -i "s/^masternodeprivkey=.*/$GENKEYVAR/" /etc/masternodes/${PROJECT}_n$i.conf
	masternodeprivkeyafter=`grep ^masternodeprivkey /etc/masternodes/${PROJECT}_n$i.conf`
	echo -e " Privkey in ${PROJECT}_n$i.conf after sub is : " >> $LOGFILE
	echo -e " $masternodeprivkeyafter" >> $LOGFILE
	
	# create file with IP addresses
	sed -n -e '/^bind/p' /etc/masternodes/${PROJECT}_n$i.conf >> $INSTALLDIR/temp/mnipaddresses
	
	# remove "bind=" from mnipaddresses
	sed -i "s/bind=//" $INSTALLDIR/temp/mnipaddresses >> log 2>&1
	
	# the next line produces the IP addresses for this masternode
	echo -e "$(sed -n ${i}p $INSTALLDIR/temp/mnipaddresses)" > $INSTALLDIR/temp/IPADDR$i
	
	# obtain txid
	
	# Pull BLOCKEXP from $PROJECT.env
	BLOCKEX=`grep ^BLOCKEXP $INSTALLDIR/nodemaster/config/$PROJECT/$PROJECT.env`
	if [ -n $BLOCKEX ] 
		then echo "$BLOCKEX" > $INSTALLDIR/temp/BLOCKEXP
		sed -i "s/BLOCKEXP=//" $INSTALLDIR/temp/BLOCKEXP
		BLOCKEXP=$(<$INSTALLDIR/temp/BLOCKEXP)
		# echo -e " Block Explorer set to : $BLOCKEXP" | tee -a "$LOGFILE"
		else echo -e "No block explorer was identified in $PROJECT.env" | tee -a "$LOGFILE"
	fi
	
	curl -s "$BLOCKEXP`cat $INSTALLDIR/temp/MNADD$i`" | jq '.["utxo"][0]["txId","n"]' | tr -d '["]' > $INSTALLDIR/temp/TXID$i
	TX=`echo $(cat $INSTALLDIR/temp/TXID$i)`
	echo -e $TX >> $INSTALLDIR/temp/txid
	echo -e $TX > $INSTALLDIR/temp/TXID$i
	
	# replace null with txid info
	sed -i "s/.*null null/collateral_output_txid tx/" $INSTALLDIR/temp/txid >> $INSTALLDIR/temp/txid 2>&1
	sed -i "s/.*null null/collateral_output_txid tx/" $INSTALLDIR/temp/TXID$i >> $INSTALLDIR/temp/TXID$i 2>&1
	
	# merge all vars into masternode.conf
	echo "|" > $INSTALLDIR/temp/DELIMETER
	
	# merge data fields to prepare masternode.return file
	# add in donation if requested to do so
	if (( "$DONATE" > "0" )) && [ -n "$DONATEADDR" ]; then
	paste -d '|' $INSTALLDIR/temp/MNALIAS$i $INSTALLDIR/temp/IPADDR$i $INSTALLDIR/temp/GENKEY$i $INSTALLDIR/temp/TXID$i $INSTALLDIR/temp/DONATION >> $INSTALLDIR/temp/masternode.line$i
	else paste -d '|' $INSTALLDIR/temp/MNALIAS$i $INSTALLDIR/temp/IPADDR$i $INSTALLDIR/temp/GENKEY$i $INSTALLDIR/temp/TXID$i >> $INSTALLDIR/temp/masternode.line$i
	fi
	
	# if line contains collateral_tx then start the line with #
	sed -e '/collateral_output_txid tx/ s/^#*/#/' -i $INSTALLDIR/temp/masternode.line$i >> $INSTALLDIR/temp/masternode.line$i 2>&1
	# prepend line with delimeter
	paste -d '|' $INSTALLDIR/temp/DELIMETER $INSTALLDIR/temp/masternode.line$i >> $INSTALLDIR/temp/masternode.all

	# create the masternode.conf output that is returned to consumer
	# add in donation if requested to do so
	if (( "$DONATE" > "0" )) && [ -n "$DONATEADDR" ]; then
	paste -d ' ' $INSTALLDIR/temp/MNALIAS$i $INSTALLDIR/temp/IPADDR$i $INSTALLDIR/temp/GENKEY$i $INSTALLDIR/temp/TXID$i $INSTALLDIR/temp/DONATION >> $INSTALLDIR/masternode.conf
	else paste -d ' ' $INSTALLDIR/temp/MNALIAS$i $INSTALLDIR/temp/IPADDR$i $INSTALLDIR/temp/GENKEY$i $INSTALLDIR/temp/TXID$i >> $INSTALLDIR/masternode.conf
	fi	
	
# declutter ; take out trash
rm $INSTALLDIR/temp/GENKEY${i}FIN ; rm $INSTALLDIR/temp/GENKEY$i ; rm $INSTALLDIR/temp/IPADDR$i ; rm $INSTALLDIR/temp/MNADD$i
rm $INSTALLDIR/temp/MNALIAS$i ; rm $INSTALLDIR/temp/TXID$i
rm $INSTALLDIR/temp/${PROJECT}Ds --force; rm $INSTALLDIR/temp/DELIMETER

# slow it down to not upset the blockchain API
# sleep 2
echo -e "Completed masternode $i loop, moving on..."  | tee -a "$LOGFILE"
done

	# comment out lines that contain "collateral_output_txid tx" in masternode.conf	
	sed -e '/collateral_output_txid tx/ s/^#*/# /' -i $INSTALLDIR/masternode.conf >> $INSTALLDIR/masternode.conf 2>&1

	# Log whether or not a donation has been entered into masternode.conf
	if (( "$DONATE" > "0" )) && [ -n "$DONATEADDR" ]; then
	echo -e "User chose to donate $DONATE % to $DONATEADDR"  | tee -a "$LOGFILE"
	else 
	echo -e "User chose not to donate, and that's ok. We'll survive."  | tee -a "$LOGFILE"
	echo -e "DONATE is set to $(DONATE). DONATEADDR is set to $DONATEADDR"  | tee -a "$LOGFILE"
	fi
	
	echo -e "Converting masternode.conf to one delineated line for mother" | tee -a "$LOGFILE"
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
	echo -e "Cleaning up clutter and taking out trash \n" | tee -a "$LOGFILE"
	rm $INSTALLDIR/temp/complete --force
	rm $INSTALLDIR/temp/masternode.all --force
	rm $INSTALLDIR/temp/masternode.1 --force
	rm $INSTALLDIR/temp/masternode.l* --force
	rm $INSTALLDIR/temp/DONATION --force
	rm $INSTALLDIR/temp/DONATEADDR --force
	rm $INSTALLDIR/temp/txid --force
	rm $INSTALLDIR/temp/mnaliases --force
	rm $INSTALLDIR/temp/${PROJECT}Ds --force
	rm $INSTALLDIR/temp/MNPRIV* --force

	echo -e "This is the contents of your file $INSTALLDIR/masternode.conf \n" | tee -a "$LOGFILE"
	cat $INSTALLDIR/masternode.conf | tee -a "$LOGFILE"
	echo -e "\n"  | tee -a "$LOGFILE"
	
	# lists the garbage leftover after installation
	# ls $INSTALLDIR | tee -a "$LOGFILE"
fi
 }

function install_binaries() {
#check for binaries and install if found   
echo -e "\nInstalling binaries"  | tee -a "$LOGFILE"
cd $INSTALLDIR/temp
	# Pull GITAPI_URL from $PROJECT.env
	GIT_API=`grep ^GITAPI_URL $INSTALLDIR/nodemaster/config/$PROJECT/$PROJECT.env`
	if [ -n $GIT_API ] ; then 
	echo "$GIT_API" > $INSTALLDIR/temp/GIT_API
	sed -i "s/GITAPI_URL=//" $INSTALLDIR/temp/GIT_API
	GITAPI_URL=$(<$INSTALLDIR/temp/GIT_API)
	echo -e "GIT_URL set to $GITAPI_URL" | tee -a "$LOGFILE"
	else
	echo -e "Cannot download binaries; no $GITAPI_URL was detected." | tee -a "$LOGFILE"
	fi
	
# GITAPI_URL="https://api.github.com/repos/heliumchain/helium/releases/latest"
curl -s $GITAPI_URL \
      | grep tag_name > currentversion   | tee -a "$LOGFILE"
curl -s $GITAPI_URL \
      | grep browser_download_url \
      | grep x86_64-linux-gnu.tar.gz \
      | cut -d '"' -f 4 \
      | wget -qi -   | tee -a "$LOGFILE"
TARBALL="$(find . -name "*x86_64-linux-gnu.tar.gz")"
tar -xzf $TARBALL
EXTRACTDIR=${TARBALL%-x86_64-linux-gnu.tar.gz}
cp -r $EXTRACTDIR/bin/. /usr/local/bin/
rm -r $EXTRACTDIR
rm -f $TARBALL

# check if binaries already exist, skip installing crypto packages if they aren't needed
dEXIST=`ls /usr/local/bin | grep ${PROJECT}d`

if [ "$dEXIST" = "${PROJECT}d" ]
then echo -e "Binaries for ${PROJECT} were downloaded and installed."   | tee -a "$LOGFILE"
else echo -e "Binaries for ${PROJECT} could not be downloaded."  | tee -a "$LOGFILE"
fi
}

function restart_server() {
	echo -e "Going to restart server to complete installation... " | tee -a "$LOGFILE"
	cp $INSTALLDIR/maintenance/postinstall_api.sh /etc/init.d/
	update-rc.d postinstall_api.sh defaults
	shutdown -r now "Server is going down for upgrade."
}

# This is where the script actually starts


setup_environment
# curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Beginning Installation Script..."}' && echo -e " "

add_cron

# moved curl update commands into get-hard.sh to provide better detail
silent_harden

curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Downloading '"$PROJECT"' Binaries ..."}' && echo -e " "
install_binaries

curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Creating '"$PROJECT"' Masternodes ..."}' && echo -e " "
install_mns

curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Configuring '"$PROJECT"' Masternodes ..."}' && echo -e " "
get_genkeys
curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Masternode Configuration is Complete ..."}' && echo -e " "

# create file to signal cron that reboot has occurred
touch $INSTALLDIR/temp/vpsvaletreboot.txt
curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Restarting Server to Finalize Installation ..."}' && echo -e " "
restart_server

#!/bin/bash
# Silently install masternodes and insert privkeys

function setup_environment() {
# Set Variables
INSTALLDIR='/var/tmp/nodevalet'
LOGFILE='/var/tmp/nodevalet/logs/silentinstall.log'
INFODIR='/var/tmp/nvtemp'

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
sudo ln -s $INSTALLDIR/checksync.sh /usr/local/bin/checksync

# Create Log File and Begin
clear
echo -e " ---------------------------------------------------- " | tee -a "$LOGFILE"
echo -e " `date +%m.%d.%Y_%H:%M:%S` : SCRIPT STARTED SUCCESSFULLY " | tee -a "$LOGFILE"
echo -e " ---------------------------------------------------- " | tee -a "$LOGFILE"
echo -e " -------- AKcryptoGUY's NodeValet Script ------------ " | tee -a "$LOGFILE"
echo -e " -------------Masternodes Made Easy------------------ " | tee -a "$LOGFILE"
echo -e " ---------------------------------------------------- " | tee -a "$LOGFILE"

# read or set project name
	if [ -s $INFODIR/vpscoin.info ]
	then PROJECT=`cat $INFODIR/vpscoin.info`
	PROJECTl=${PROJECT,,}
	PROJECTt=${PROJECTl~}
	touch $INFODIR/fullauto.info
	echo -e " Script was invoked by NodeValet and is on full-auto\n" | tee -a "$LOGFILE"
	echo -e " Script was invoked by NodeValet and is on full-auto\n" >> $INFODIR/fullauto.info
	echo -e " Setting Project Name to $PROJECTt : vpscoin.info found" >> $LOGFILE
	else echo -e " Please choose from one of the following supported coins to install:"
	     echo -e "    helium | condominium | smart (smartcash) \n"
		echo -e " In one word, which coin are installing today? "
		while :; do
		read -p "  --> " PROJECT
			if [ -d $INSTALLDIR/nodemaster/config/${PROJECT,,} ]
			then touch $INFODIR/vpscoin.info
			echo -e "${PROJECT,,}" > $INFODIR/vpscoin.info
			PROJECT=`cat $INFODIR/vpscoin.info`
			PROJECTl=${PROJECT,,}
			PROJECTt=${PROJECTl~}
			echo -e " Setting Project Name to $PROJECTt : user provided input" >> $LOGFILE
			break
			else echo -e " --> $PROJECT is not supported, try again."
			fi
		done
	fi

# set hostname variable to the name planted by install script
	if [ -e $INFODIR/vpshostname.info ]
	then HNAME=$(<$INFODIR/vpshostname.info)
	echo -e " Setting Hostname to $HNAME : vpshostname.info found" >> $LOGFILE
	else HNAME=`hostname`
	touch $INFODIR/vpshostname.info
	echo -e "$HNAME" > $INFODIR/vpshostname.info
	echo -e " Setting Hostname to $HNAME : read from server hostname" >> $LOGFILE
	fi
if [ -e $INFODIR/fullauto.info ] ; then curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Your new VPS is online and reporting installation status ..."}' && echo -e " " ; fi
sleep 6
	
# set mnode daemon name from project.env
MNODE_DAEMON=`grep ^MNODE_DAEMON $INSTALLDIR/nodemaster/config/${PROJECT}/${PROJECT}.env`
echo -e "$MNODE_DAEMON" > $INSTALLDIR/temp/MNODE_DAEMON
sed -i "s/MNODE_DAEMON=\${MNODE_DAEMON:-\/usr\/local\/bin\///" $INSTALLDIR/temp/MNODE_DAEMON  2>&1
cat $INSTALLDIR/temp/MNODE_DAEMON | tr -d '[}]' > $INSTALLDIR/temp/MNODE_DAEMON1
MNODE_DAEMON=$(<$INSTALLDIR/temp/MNODE_DAEMON1)
cat $INSTALLDIR/temp/MNODE_DAEMON1 > $INSTALLDIR/temp/MNODE_DAEMON ; rm $INSTALLDIR/temp/MNODE_DAEMON1
echo -e " Setting masternode-daemon to $MNODE_DAEMON" >> $LOGFILE

# set BLOCKEXP to nodevalet project coin
BLOCKEXP="https://www.nodevalet.io/api/txdata.php?coin=${PROJECT}&address="
# echo -e " BlockExp set to: $BLOCKEXP" >> "$LOGFILE"

# read or assign number of masternodes to install
	if [ -e $INFODIR/vpsnumber.info ]
	then MNS=$(<$INFODIR/vpsnumber.info)
	echo -e " Setting number of masternodes to $MNS : vpsnumber.info found" >> $LOGFILE
	# create a subroutine here to check memory and size MNS appropriately
	# or prompt user how many they would like to build
	else echo -e " Please enter the number of masternodes to install : "
		while :; do
		read -p "  --> " MNS
		if (($MNS >= 1 && $MNS <= 50))
		then echo -e " Setting number of masternodes to $MNS : user provided input" >> $LOGFILE
		touch $INFODIR/vpsnumber.info
		echo -e "${MNS}" > $INFODIR/vpsnumber.info
		break
		else echo -e " --> $MNS is not a number between 1 and 50, try again."
		fi
		done
		echo -e " \n"
	fi

# create or assign mnprefix
	if [ -s $INFODIR/vpsmnprefix.info ]
	then :
	echo -e " Setting masternode aliases from vpsmnprefix.info file" >> $LOGFILE
	else MNPREFIX=`hostname`
	echo -e " Generating aliases from hostname ($MNPREFIX) : vpsmnprefix.info not found" >> $LOGFILE
	fi

# create or assign onlynet from project.env
ONLYNET=`grep ^ONLYNET $INSTALLDIR/nodemaster/config/${PROJECT}/${PROJECT}.env`
echo -e "$ONLYNET" > $INSTALLDIR/temp/ONLYNET
sed -i "s/ONLYNET=//" $INSTALLDIR/temp/ONLYNET 2>&1
ONLYNET=$(<$INSTALLDIR/temp/ONLYNET)
	if [ "$ONLYNET" > 0 ]
	then echo -e " Setting network to IPv${ONLYNET} d/t instructions in ${PROJECT}.env" >> $LOGFILE
	else ONLYNET='6'
	echo -e " Setting network to IPv${ONLYNET} d/t no reference in ${PROJECT}.env" >> $LOGFILE
	fi

# create or assign customssh
	if [ -s $INFODIR/vpssshport.info ]
	then SSHPORT=$(<$INFODIR/vpssshport.info)
	echo -e " Setting SSHPORT to $SSHPORT as found in vpsshport.info \n" >> $LOGFILE
	else
		printf "${cyan}"
		echo -e " Enter a custom port for SSH between 11000 and 65535 or use 22 : "
		while :; do
		read -p "  --> " MNS
		[[ $SSHPORT =~ ^[0-9]+$ ]] || { printf "${lightred}";echo -e " --> Try harder, that's not even a number.";printf "${nocolor}";continue; }
		if (($SSHPORT >= 11000 && $SSHPORT <= 65535)); then break
		elif [ $SSHPORT = 22 ]; then break
		else printf "${lightred}"
		echo -e " --> That number is out of range, try again. \n"
		printf "${nocolor}"
		fi
		done
		echo -e " Setting SSHPORT to $SSHPORT : user provided input \n" >> $LOGFILE
		touch $INFODIR/vpssshport.info
		echo "$SSHPORT" >> $INFODIR/vpssshport.info
	fi

# read or collect masternode addresses
	if [ -e $INFODIR/vpsmnaddress.info ]
	then :
	# create a subroutine here to check memory and size MNS appropriately
	else echo -e " Before we can begin, we need to collect $MNS masternode addresses."
	echo -e " Manually collecting masternode addresses from user" >> $LOGFILE 2>&1
	echo -e " On your local wallet, generate the masternode addresses and send"
	echo -e " your collateral transactions for masternodes you want to start now."
	echo -e " You may also add extra addresses even if you have not yet funded"
	echo -e " them, and the script will still create the masternode instance"
	echo -e " which you can later activate from your local wallet."
	echo -e " Please double check your addresses for accuracy.\n"
	touch $INFODIR/vpsmnaddress.info
		for ((i=1;i<=$MNS;i++)); 
		do 
			while :; do
			printf "${cyan}"
			echo -e " Please enter the ${PROJECT}t address for masternode #$i"
			read -p "  --> " MNADDP
				echo -e "You entered the address: ${MNADDP} "
				read -n 1 -s -r -p "  --> Is this correct? y/n  " VERIFY
				if [[ $VERIFY == "y" || $VERIFY == "Y" || $VERIFY == "yes" || $VERIFY == "Yes" ]]
				then printf "${cyan}" ; break
  				fi
			done	
		echo "$MNADDP" >> $INFODIR/vpsmnaddress.info
		echo -e "  --> Masternode $i address is: $MNADDP\n" >> $LOGFILE
		echo -e " \n"
		done
	fi

echo -e " I am going to install $MNS $PROJECTt masternodes on this VPS." >> $LOGFILE
echo -e "\n"

set donation percentage
#	if [ -e $INFODIR/vpsdonation.info ]
#	then DONATE=`cat $INFODIR/vpsdonation.info`
#	echo -e "vpsdonation.info found, setting DONATE to $DONATE"  | tee -a "$LOGFILE"
#	else DONATEN=""
#		while [[ ! $DONATE =~ ^[0-9]+$ ]]; do	
#		echo -e "Although this script is smart, it didn't write itself. If you"
#		echo -e "would like to donate a percentage of your masternode rewards"
#		echo -e "to the developers of this script, please enter a number here,"
#		echo -e "or enter 0 to not leave a donation.  Recommended donation is 2%.\n"
#		 read -p "  --> " DONATE
#		DONATE='0'
#		done
#		echo -e "User has chosen to donate ${DONATE}% of your masternode rewards."  | tee -a "$LOGFILE"
#	fi
	
# set donation address front project.env
	cd $INSTALLDIR/nodemaster/config/$PROJECT
	curl -LJO https://raw.githubusercontent.com/akcryptoguy/nodevalet/master/nodemaster/config/$PROJECT/$PROJECT.env
	echo -e "\n"
	DONATION_ADDRESS=`grep ^DONATION $INSTALLDIR/nodemaster/config/$PROJECT/$PROJECT.env`
	cd $INSTALLDIR
	if [ -n $DONATION_ADDRESS ] ; then 
	touch $INFODIR/vpsdonation.info
	echo "$DONATION_ADDRESS" > $INSTALLDIR/temp/DONATEADDR
	sed -i "s/DONATION_ADDRESS=//" $INSTALLDIR/temp/DONATEADDR
	DONATEADDR=$(<$INSTALLDIR/temp/DONATEADDR)
	# echo -e "Donation address set to $DONATEADDR" | tee -a "$LOGFILE"
	paste -d ':' $INSTALLDIR/temp/DONATEADDR $INFODIR/vpsdonation.info > $INSTALLDIR/temp/DONATION
	else
	echo -e "No donation address was detected." | tee -a "$LOGFILE"
	fi

# enable softwrap so masternode.conf file can be easily copied
sed -i "s/# set softwrap/set softwrap/" /etc/nanorc >> $LOGFILE 2>&1	
}

function add_cron() {
echo -e "\n Adding crontabs"  | tee -a "$LOGFILE"
chmod 0700 $INSTALLDIR/*.sh
chmod 0700 $INSTALLDIR/autoupdate/*.sh
chmod 0700 $INSTALLDIR/maintenance/*.sh
echo -e "  --> Run post install script after first reboot"  | tee -a "$LOGFILE"
	(crontab -l ; echo "*/1 * * * * $INSTALLDIR/maintenance/postinstall_api.sh") | crontab -
echo -e "  --> Make sure all daemon are running every 5 minutes"  | tee -a "$LOGFILE"
	(crontab -l ; echo "*/5 * * * * $INSTALLDIR/maintenance/makerun.sh") | crontab -
echo -e "  --> Check for stuck blocks every 30 minutes"  | tee -a "$LOGFILE"
	(crontab -l ; echo "*/30 * * * * $INSTALLDIR/maintenance/checkdaemon.sh") | crontab -
echo -e "  --> Check for & reboot if needed to install updates every 10 hours"  | tee -a "$LOGFILE"
	(crontab -l ; echo "30 */10 * * * $INSTALLDIR/maintenance/rebootq.sh") | crontab -
echo -e "  --> Check for wallet updates every 12 hours"  | tee -a "$LOGFILE"
	(crontab -l ; echo "0 */12 * * * $INSTALLDIR/autoupdate/fullupdater.sh") | crontab -
echo -e "  --> Clear daemon debug logs weekly to prevent clog \n"  | tee -a "$LOGFILE"
	(crontab -l ; echo "@weekly $INSTALLDIR/maintenance/cleardebuglog.sh") | crontab -
}

function silent_harden() {
	if [ -e /var/log/server_hardening.log ]
	then echo -e " This server seems to already be hardened, skipping this part \n" | tee -a "$LOGFILE"
	else echo -e " This server is not yet secure, running VPS Hardening script \n" | tee -a "$LOGFILE"
	cd $INSTALLDIR/vps-harden
	bash get-hard.sh
	fi
	echo -e "Installing jq and jp2a packages" | tee -a "$LOGFILE"
	apt-get -qqy -o=Dpkg::Use-Pty=0 -o=Acquire::ForceIPv4=true install jq jp2a | tee -a "$LOGFILE"
	echo -e "Inserting random Chuck Norris joke to avoid excessive blandness\n" | tee -a "$LOGFILE"
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
		echo -e "Launching Nodemaster using bash install.sh -n $ONLYNET -p $PROJECT" -c $MNS | tee -a "$LOGFILE"
		sudo bash install.sh -n $ONLYNET -p $PROJECT -c $MNS
		echo -e "activating_masternodes_$PROJECT" | tee -a "$LOGFILE"
		activate_masternodes_$PROJECT echo -e | tee -a "$LOGFILE"
		# sleep 1
		
		# check if $PROJECTd was built correctly and started
		ps -A | grep $MNODE_DAEMON >> $INSTALLDIR/temp/${PROJECT}Ds
		cat $INSTALLDIR/temp/${PROJECT}Ds >> $LOGFILE
		if [ -s $INSTALLDIR/temp/${PROJECT}Ds ]
		then echo -e "It looks like VPS install script completed and ${MNODE_DAEMON} is running... " | tee -a "$LOGFILE"
		# report back to mother
		echo -e "Reporting ${MNODE_DAEMON} build success to mother" | tee -a "$LOGFILE"
		if [ -e $INFODIR/fullauto.info ] ; then curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Process '"$MNODE_DAEMON"' has started ..."}' && echo -e " " ; fi
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
if [ -e $INFODIR/fullauto.info ] ; then curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Error: Masternodes already exist on this VPS."}' && echo -e " " ; fi
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
	
		for ((P=1;P<=30;P++)); 
		do
	
	# create masternode genkeys (smart is special "smartnodes")
	if [ "${PROJECT,,}" = "smart" ] ; then
	/usr/local/bin/${MNODE_DAEMON::-1}-cli -conf=/etc/masternodes/${PROJECT}_n1.conf smartnode genkey >> $INSTALLDIR/temp/genkeys ; else
	/usr/local/bin/${MNODE_DAEMON::-1}-cli -conf=/etc/masternodes/${PROJECT}_n1.conf masternode genkey >> $INSTALLDIR/temp/genkeys ; fi
	echo -e "$(sed -n ${i}p $INSTALLDIR/temp/genkeys)" > $INSTALLDIR/temp/GENKEY$i
	if [ "${PROJECT,,}" = "smart" ] ; then
	echo "smartnodeprivkey=" > $INSTALLDIR/temp/MNPRIV1 ; else
	echo "masternodeprivkey=" > $INSTALLDIR/temp/MNPRIV1 ; fi
	KEYXIST=$(<$INSTALLDIR/temp/GENKEY$i)

	# check if GENKEY file is empty; if so stop script and report error
	if [ ${#KEYXIST} = "0" ]
	then echo -e " ${MNODE_DAEMON::-1}-cli couldn't create genkey; it is probably still starting up" | tee -a "$LOGFILE"
	echo -e " --> Waiting for 2 seconds before trying again... loop $P" | tee -a "$LOGFILE"
	sleep 2
	else break
	fi
	
	if [ ${#KEYXIST} = "0" ] && [ "${P}" = "30" ]
	then if [ -e $INFODIR/fullauto.info ] ; then curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Error: Could not generate masternode genkey"}' && echo -e " " ; fi
	echo -e "Problem creating masternode $i. Could not obtain masternode genkey." | tee -a "$LOGFILE"
	echo -e "I tried for 60 seconds but something isn't working correctly.\n" | tee -a "$LOGFILE"
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
	GENKEYVAR=`cat $INSTALLDIR/temp/MNPRIVKEY$i`

	# insert new genkey into project_n$i.conf files (special case for smartnodes)
	if [ "${PROJECT,,}" = "smart" ] ; then	
	sed -i "s/^smartnodeprivkey=.*/$GENKEYVAR/" /etc/masternodes/${PROJECT}_n$i.conf
	masternodeprivkeyafter=`grep ^smartnodeprivkey /etc/masternodes/${PROJECT}_n$i.conf`
	echo -e " Privkey in ${PROJECT}_n$i.conf after sub is : " >> $LOGFILE
	echo -e " $masternodeprivkeyafter" >> $LOGFILE ; else
	sed -i "s/^masternodeprivkey=.*/$GENKEYVAR/" /etc/masternodes/${PROJECT}_n$i.conf
	masternodeprivkeyafter=`grep ^masternodeprivkey /etc/masternodes/${PROJECT}_n$i.conf`
	echo -e " Privkey in ${PROJECT}_n$i.conf after sub is : " >> $LOGFILE
	echo -e " $masternodeprivkeyafter" >> $LOGFILE
	fi
	
	# create file with IP addresses
	sed -n -e '/^bind/p' /etc/masternodes/${PROJECT}_n$i.conf >> $INSTALLDIR/temp/mnipaddresses
	
	# remove "bind=" from mnipaddresses
	sed -i "s/bind=//" $INSTALLDIR/temp/mnipaddresses 2>&1
	
	# the next line produces the IP addresses for this masternode
	echo -e "$(sed -n ${i}p $INSTALLDIR/temp/mnipaddresses)" > $INSTALLDIR/temp/IPADDR$i
	
	# obtain txid
	
	# Pull BLOCKEXP from $PROJECT.env
	# THIS code rendered obsolete when we incorporated our our block explorers
	#	BLOCKEX=`grep ^BLOCKEXP $INSTALLDIR/nodemaster/config/$PROJECT/$PROJECT.env`
	#	if [ -n $BLOCKEX ] 
	#		then echo "$BLOCKEX" > $INSTALLDIR/temp/BLOCKEXP
	#		sed -i "s/BLOCKEXP=//" $INSTALLDIR/temp/BLOCKEXP
	#		BLOCKEXP=$(<$INSTALLDIR/temp/BLOCKEXP)
	#		# echo -e " Block Explorer set to : $BLOCKEXP" | tee -a "$LOGFILE"
	#		else echo -e "No block explorer was identified in $PROJECT.env" | tee -a "$LOGFILE"
	#	fi
	
	# Check for presence of txid and, if present, use it for txid/txidx
	if [ -e $INFODIR/vpsmntxdata.info ]
		then echo -e "$(sed -n ${i}p $INFODIR/vpsmntxdata.info)" > $INSTALLDIR/temp/TXID$i
		TX=`echo $(cat $INSTALLDIR/temp/TXID$i)`
		echo -e $TX >> $INSTALLDIR/temp/txid
		echo -e $TX > $INSTALLDIR/temp/TXID$i
		# Query nodevalet block explorer for collateral transaction
		else curl -s "$BLOCKEXP`cat $INSTALLDIR/temp/MNADD$i`" | jq '.["txid","txindex"]' | tr -d '["]' > $INSTALLDIR/temp/TXID$i
		TX=`echo $(cat $INSTALLDIR/temp/TXID$i)`
		echo -e $TX >> $INSTALLDIR/temp/txid
		echo -e $TX > $INSTALLDIR/temp/TXID$i
	fi
	
	# replace null with txid info
	sed -i "s/.*null null/collateral_output_txid tx/" $INSTALLDIR/temp/txid >> $INSTALLDIR/temp/txid 2>&1
	sed -i "s/.*null null/collateral_output_txid tx/" $INSTALLDIR/temp/TXID$i >> $INSTALLDIR/temp/TXID$i 2>&1
	
	# merge all vars into masternode.conf
	echo "|" > $INSTALLDIR/temp/DELIMETER
	
	# merge data fields to prepare masternode.return file
	paste -d '|' $INSTALLDIR/temp/MNALIAS$i $INSTALLDIR/temp/IPADDR$i $INSTALLDIR/temp/GENKEY$i $INSTALLDIR/temp/TXID$i >> $INSTALLDIR/temp/masternode.line$i
	
	# add in donation if requested to do so
	# if (( "$DONATE" > "0" )) && [ -n "$DONATEADDR" ]; then
	# paste -d '|' $INSTALLDIR/temp/MNALIAS$i $INSTALLDIR/temp/IPADDR$i $INSTALLDIR/temp/GENKEY$i $INSTALLDIR/temp/TXID$i $INSTALLDIR/temp/DONATION >> $INSTALLDIR/temp/masternode.line$i
	# else paste -d '|' $INSTALLDIR/temp/MNALIAS$i $INSTALLDIR/temp/IPADDR$i $INSTALLDIR/temp/GENKEY$i $INSTALLDIR/temp/TXID$i >> $INSTALLDIR/temp/masternode.line$i
	# fi
	
	# if line contains collateral_tx then start the line with #
	sed -e '/collateral_output_txid tx/ s/^#*/#/' -i $INSTALLDIR/temp/masternode.line$i >> $INSTALLDIR/temp/masternode.line$i 2>&1
	# prepend line with delimeter
	paste -d '|' $INSTALLDIR/temp/DELIMETER $INSTALLDIR/temp/masternode.line$i >> $INSTALLDIR/temp/masternode.all

	# create the masternode.conf output that is returned to consumer
	paste -d ' ' $INSTALLDIR/temp/MNALIAS$i $INSTALLDIR/temp/IPADDR$i $INSTALLDIR/temp/GENKEY$i $INSTALLDIR/temp/TXID$i >> $INSTALLDIR/masternode.conf
	# add in donation if requested to do so
	# if (( "$DONATE" > "0" )) && [ -n "$DONATEADDR" ]; then
	# paste -d ' ' $INSTALLDIR/temp/MNALIAS$i $INSTALLDIR/temp/IPADDR$i $INSTALLDIR/temp/GENKEY$i $INSTALLDIR/temp/TXID$i $INSTALLDIR/temp/DONATION >> $INSTALLDIR/masternode.conf
	# else paste -d ' ' $INSTALLDIR/temp/MNALIAS$i $INSTALLDIR/temp/IPADDR$i $INSTALLDIR/temp/GENKEY$i $INSTALLDIR/temp/TXID$i >> $INSTALLDIR/masternode.conf
	# fi	
	
# declutter ; take out trash
# rm $INSTALLDIR/temp/GENKEY${i}FIN ; rm $INSTALLDIR/temp/GENKEY$i ; rm $INSTALLDIR/temp/IPADDR$i ; rm $INSTALLDIR/temp/MNADD$i
# rm $INSTALLDIR/temp/MNALIAS$i ; rm $INSTALLDIR/temp/TXID$i ; rm $INSTALLDIR/temp/${PROJECT}Ds --force ; rm $INSTALLDIR/temp/DELIMETER

echo -e "Completed masternode $i loop, moving on..."  | tee -a "$LOGFILE"
done
echo -e " \n" | tee -a "$LOGFILE"

	# comment out lines that contain "collateral_output_txid tx" in masternode.conf	
	sed -e '/collateral_output_txid tx/ s/^#*/# /' -i $INSTALLDIR/masternode.conf >> $INSTALLDIR/masternode.conf 2>&1

	# Log whether or not a donation has been entered into masternode.conf
	# if (( "$DONATE" > "0" )) && [ -n "$DONATEADDR" ]; then
	# echo -e "User chose to donate $DONATE % to $DONATEADDR"  | tee -a "$LOGFILE"
	# else 
	# echo -e "User chose not to donate, and that's ok. We'll survive."  | tee -a "$LOGFILE"
	# echo -e "DONATE is set to $(DONATE). DONATEADDR is set to $DONATEADDR"  | tee -a "$LOGFILE"
	# fi

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
# rm $INSTALLDIR/temp/complete --force		;	rm $INSTALLDIR/temp/masternode.all --force
# rm $INSTALLDIR/temp/masternode.1 --force	;	rm $INSTALLDIR/temp/masternode.l* --force
# rm $INSTALLDIR/temp/DONATION --force		;	rm $INSTALLDIR/temp/DONATEADDR --force
# rm $INSTALLDIR/temp/txid --force		;	rm $INSTALLDIR/temp/mnaliases --force
# rm $INSTALLDIR/temp/${PROJECT}Ds --force	;	rm $INSTALLDIR/temp/MNPRIV* --force
# rm $INSTALLDIR/temp/ONLYNET --force

clear
echo -e "This is the contents of your file $INSTALLDIR/masternode.conf \n" | tee -a "$LOGFILE"
cat $INSTALLDIR/masternode.conf | tee -a "$LOGFILE"
echo -e "\n"  >> "$LOGFILE"
	
	if [ ! -s $INFODIR/fullauto.info ]
		then cp $INSTALLDIR/maintenance/postinstall_api.sh /etc/init.d/
		update-rc.d postinstall_api.sh defaults  2>/dev/null
		echo -e " Please copy the above file and paste it into the masternode.conf "
		echo -e " file on your local wallet. Then reboot the local wallet. Next, type "
		echo -e " 'reboot' to reboot this VPS and begin syncing the blockchain. Once "
		echo -e " your local wallet has restarted, you may click Start Missing to start "
		echo -e " your new masternodes. If starting any masternodes fails, you may need "
		echo -e " to start them from debug console using 'startmasternode alias 0 MN1' "
		echo -e " where you replace MN1 with the alias of your masternode. This is due "
		echo -e " to a quirk in the wallet that doesn't always recognize IPv6 addresses. "
		read -n 1 -s -r -p "  --- Please press any key to continue ---" ANYKEY
		else echo -e "Fullauto detected, skipping masternode.conf display"  >> "$LOGFILE" ; fi
fi
 }

function install_binaries() {
#check for binaries and install if found   
echo -e "\nAttempting to download and install $PROJECTt binaries from:"  | tee -a "$LOGFILE"
cd $INSTALLDIR/temp
	# Pull GITAPI_URL from $PROJECT.env
	GIT_API=`grep ^GITAPI_URL $INSTALLDIR/nodemaster/config/$PROJECT/$PROJECT.env`
	if [ -n $GIT_API ] ; then 
	echo "$GIT_API" > $INSTALLDIR/temp/GIT_API
	sed -i "s/GITAPI_URL=//" $INSTALLDIR/temp/GIT_API
	GITAPI_URL=$(<$INSTALLDIR/temp/GIT_API)
	echo -e "$GITAPI_URL" | tee -a "$LOGFILE"
	else
	echo -e "Cannot download binaries; no GITAPI_URL was detected. \n" | tee -a "$LOGFILE"
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
tar -xzf $TARBALL 2>&1
EXTRACTDIR=${TARBALL%-x86_64-linux-gnu.tar.gz}
cp -r $EXTRACTDIR/bin/. /usr/local/bin/
rm -r $EXTRACTDIR --force
rm -f $TARBALL --force

# check if binaries already exist, skip installing crypto packages if they aren't needed
dEXIST=`ls /usr/local/bin | grep ${MNODE_DAEMON}`

if [ "$dEXIST" = "${MNODE_DAEMON}" ]
then echo -e "Binaries for ${PROJECTt} were downloaded and installed. \n"   | tee -a "$LOGFILE"
else echo -e "Binaries for ${PROJECTt} could not be downloaded. \n"  | tee -a "$LOGFILE"
fi
}

function restart_server() {
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

if [ -e $INFODIR/fullauto.info ] ; then curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Creating '"$MNS"' '"$PROJECTt"' Masternodes ..."}' && echo -e " " ; fi
install_mns

add_cron

if [ -e $INFODIR/fullauto.info ] ; then curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Configuring '"$MNS"' '"$PROJECTt"' Masternodes ..."}' && echo -e " " ; fi
get_genkeys
if [ -e $INFODIR/fullauto.info ] ; then curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Masternode Configuration is Complete ..."}' && echo -e " " ; fi

# create file to signal cron that reboot has occurred
touch $INSTALLDIR/temp/vpsvaletreboot.txt
if [ -e $INFODIR/fullauto.info ] ; then curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Restarting Server to Finalize Installation ..."}' && echo -e " " ; fi
restart_server

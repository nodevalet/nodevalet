#!/bin/bash
# This script will scrub NodeValet from your VPS

# CURLAPI="https://blockchain.info/rawaddr/13aLwk6WtaW6mNatE24oQrz65uPqgtS1hS"
BTCADDRESS=13aLwk6WtaW6mNatE24oQrz65uPqgtS1hS
BTCBLOCKEXP="https://blockchain.info/rawaddr/"
BTCCURLAPI=$(echo -e "$BTCBLOCKEXP$BTCADDRESS")
FEEAPI="https://blockchain.info/q/txfee/"

# This was helpful: https://shapeshed.com/jq-json/

# This returns balance
curl -s "https://blockchain.info/rawaddr/13aLwk6WtaW6mNatE24oQrz65uPqgtS1hS" | jq '.final_balance'

# This returns the transaction hash
curl -s "https://blockchain.info/rawaddr/13aLwk6WtaW6mNatE24oQrz65uPqgtS1hS" | jq '.txs[0].hash' | tr -d '["]'
curl -s "https://blockchain.info/rawaddr/13aLwk6WtaW6mNatE24oQrz65uPqgtS1hS" | jq '.txs[].hash' | tr -d '["]'

# This returns the fee for a transaction
curl -s "https://blockchain.info/q/txfee/7226d6eb14b69241e1ae5ed6ea2349121bdaec9bf93f23711d6bb0824b0ff413"


# store NoveValets response in a local file
curl -s "$BTCCURLAPI" | jq '.final_balance' > /var/tmp/nodevalet/temp/BTC.response.json


# this is old rubbish I haven't modified yet

while :; do
    echo -e "\n"
    read -n 1 -s -r -p " ${lightred}Would you like to destroy all masternodes now? y/n " NUKEIT
    if [[ ${NUKEIT,,} == "y" || ${NUKEIT,,} == "Y" || ${NUKEIT,,} == "N" || ${NUKEIT,,} == "n" ]]
    then
        break
    fi
done

# display original curl API response
[[ -s $INSTALLDIR/temp/API.response$i.json ]] && echo " --> NodeValet gave the following response to API curl <--"   | tee -a "$LOGFILE" && cat $INSTALLDIR/temp/API.response$i.json | tee -a "$LOGFILE" && echo -e "\n" | tee -a "$LOGFILE"

# read curl API response into variable
APIRESPONSE=$(cat $INSTALLDIR/temp/API.response$i.json)

# check if API response is invalid
[[ "${APIRESPONSE}" == "Invalid key" ]] && echo "NodeValet replied: Invalid API Key"   | tee -a "$LOGFILE" && echo -e "null\nnull" > $INSTALLDIR/temp/TXID$i
[[ "${APIRESPONSE}" == "Invalid coin" ]] && echo "NodeValet replied: Invalid Coin"   | tee -a "$LOGFILE" && echo -e "null\nnull" > $INSTALLDIR/temp/TXID$i
[[ "${APIRESPONSE}" == "Invalid address" ]] && echo "NodeValet replied: Invalid Address"   | tee -a "$LOGFILE" && echo -e "null\nnull" > $INSTALLDIR/temp/TXID$i

# check if stored file (API.response$i.json) has NOT length greater than zero
! [[ -s $INSTALLDIR/temp/API.response$i.json ]] && echo "--> Server did not respond or response was empty"   | tee -a "$LOGFILE" && echo -e "null\nnull" > $INSTALLDIR/temp/TXID$i

# check if stored file (TXID$i) does NOT exist (then no errors were detected above)
! [[ -e $INSTALLDIR/temp/TXID$i ]] && echo "NodeValet replied: Transaction ID recorded for MN$i"  | tee -a "$LOGFILE" && cat $INSTALLDIR/temp/API.response$i.json | jq '.["txid","txindex"]' | tr -d '["]' > $INSTALLDIR/temp/TXID$i && cat $INSTALLDIR/temp/API.response$i.json | jq '.'

TX=$(echo $(cat $INSTALLDIR/temp/TXID$i))
echo -e "$TX" >> $INSTALLDIR/temp/txid
echo -e "$TX" > $INSTALLDIR/temp/TXID$i
echo -e " NodeValet API returned $TX as txid for masternode $i " >> $LOGFILE
rm $INSTALLDIR/temp/API.response$i.json --force
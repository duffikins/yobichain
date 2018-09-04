#!/bin/bash
# export TERM=xterm-color

# NC='\033[0m' # No Color
# RED='\033[0;31m'
# LIGHTGREEN='\033[1;32m'
# CYAN='\033[0;36m'
# LIGHTYELLOW='\033[1;33m'
# bold=$(tput bold)
# normal=$(tput sgr0)

INSTALLER_PATH_RELATIVE="`dirname \"$0\"`"
INSTALLER_PATH="`( cd \"$INSTALLER_PATH_RELATIVE\" && pwd )`"

sudo apt-get -y install pwgen gpw
source yobichain.conf

# chainName=$1
rpcuser=$1
rpcpassword=$2
db_admin_user=$3
db_admin_pass=$4

if ! id $linux_admin_user >/dev/null 2>&1; then
	# Setting up user account
	echo '----------------------------------------'
	echo -e 'SETTING UP '$linux_admin_user' USER ACCOUNT:'
	echo '----------------------------------------'

	passwd=`< /dev/urandom tr -dc A-Za-z0-9 | head -c20; echo`
	sudo useradd -d /home/$linux_admin_user -s /bin/bash -m $linux_admin_user
	sudo usermod -a -G sudo $linux_admin_user
	echo $linux_admin_user":"$passwd | sudo chpasswd
	echo "$linux_admin_user ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers    
fi

homedir=`su -l $linux_admin_user -c 'cd ~ && pwd'`

echo '----------------------------------------'
echo -e 'INSTALLING PREREQUISITES.....'
echo '----------------------------------------'

cd .. 

sudo apt-get --assume-yes update
sudo apt-get --assume-yes install jq git vsftpd aptitude apache2-utils php7.0-curl sqlite3 libsqlite3-dev python-dev gcc python-pip
sudo pip install --upgrade pip


#sudo apt-get install python-dev
#sudo apt-get install build-essential libssl-dev libffi-dev python-dev



wget https://files.pythonhosted.org/packages/60/db/645aa9af249f059cc3a368b118de33889219e0362141e75d4eaf6f80f163/pycrypto-2.6.1.tar.gz
tar -xvzf pycrypto-2.6.1.tar.gz
cd pycrypto*
sudo python setup.py install
cd ..



#pip install pycryptodome


## Configuring PHP-Curl
sudo sed -ie 's/;extension=php_curl.dll/extension=php_curl.dll/g' $phpinipath

sudo service apache2 restart

echo ''
echo ''
echo '----------------------------------------'
echo ''
echo ''
echo ''
echo ''

sleep 3
echo '----------------------------------------'
echo -e 'CONFIGURING FIREWALL.....'
echo '----------------------------------------'

sudo ufw allow $networkPort
sudo ufw allow $rpcPort
sudo ufw allow $explorerport
sudo ufw allow 21

echo ''
echo ''
echo '----------------------------------------'
echo ''
echo ''
echo ''
echo ''

echo -e '----------------------------------------'
echo -e 'FIREWALL SUCCESSFULLY CONFIGURED!'
echo -e '----------------------------------------'

echo '----------------------------------------'
echo -e 'INSTALLING & CONFIGURING MULTICHAIN.....'
echo '----------------------------------------'

wget --no-verbose http://www.multichain.com/download/multichain-$multichainVersion.tar.gz
sudo bash -c 'tar xvf multichain-'$multichainVersion'.tar.gz'
sudo bash -c 'cp multichain-'$multichainVersion'*/multichain* /usr/local/bin/'

su -l $linux_admin_user -c  'multichain-util create '$chainName $protocol

su -l $linux_admin_user -c "sed -ie 's/.*root-stream-open =.*\#/root-stream-open = false     #/g' $homedir/.multichain/$chainName/params.dat"
su -l $linux_admin_user -c "sed -ie 's/.*mining-requires-peers =.*\#/mining-requires-peers = true     #/g' $homedir/.multichain/$chainName/params.dat"
su -l $linux_admin_user -c "sed -ie 's/.*initial-block-reward =.*\#/initial-block-reward = 0     #/g' $homedir/.multichain/$chainName/params.dat"
su -l $linux_admin_user -c "sed -ie 's/.*first-block-reward =.*\#/first-block-reward = -1     #/g' $homedir/.multichain/$chainName/params.dat"
su -l $linux_admin_user -c "sed -ie 's/.*target-adjust-freq =.*\#/target-adjust-freq = -1     #/g' $homedir/.multichain/$chainName/params.dat"
su -l $linux_admin_user -c "sed -ie 's/.*max-std-tx-size =.*\#/max-std-tx-size = 100000000     #/g' $homedir/.multichain/$chainName/params.dat"
su -l $linux_admin_user -c "sed -ie 's/.*max-std-op-returns-count =.*\#/max-std-op-returns-count = 1024     #/g' $homedir/.multichain/$chainName/params.dat"
su -l $linux_admin_user -c "sed -ie 's/.*max-std-op-return-size =.*\#/max-std-op-return-size = 8388608     #/g' $homedir/.multichain/$chainName/params.dat"
su -l $linux_admin_user -c "sed -ie 's/.*max-std-op-drops-count =.*\#/max-std-op-drops-count = 100     #/g' $homedir/.multichain/$chainName/params.dat"
su -l $linux_admin_user -c "sed -ie 's/.*max-std-element-size =.*\#/max-std-element-size = 32768     #/g' $homedir/.multichain/$chainName/params.dat"
su -l $linux_admin_user -c "sed -ie 's/.*default-network-port =.*\#/default-network-port = '$networkPort'     #/g' $homedir/.multichain/$chainName/params.dat"
su -l $linux_admin_user -c "sed -ie 's/.*default-rpc-port =.*\#/default-rpc-port = '$rpcPort'     #/g' $homedir/.multichain/$chainName/params.dat"
su -l $linux_admin_user -c "sed -ie 's/.*chain-name =.*\#/chain-name = '$chainName'     #/g' $homedir/.multichain/$chainName/params.dat"
su -l $linux_admin_user -c " sed -ie 's/.*protocol-version =.*\#/protocol-version = '$protocol'     #/g' $homedir/.multichain/$chainName/params.dat"

su -l $linux_admin_user -c "echo rpcuser='$rpcuser' > $homedir/.multichain/$chainName/multichain.conf"
su -l $linux_admin_user -c "echo rpcpassword='$rpcpassword' >> $homedir/.multichain/$chainName/multichain.conf"
su -l $linux_admin_user -c 'echo rpcPort='$rpcPort' >> '$homedir'/.multichain/'$chainName'/multichain.conf'

echo ''
echo ''
echo '----------------------------------------'
echo ''
echo ''
echo ''
echo ''

echo '----------------------------------------'
echo -e 'RUNNING BLOCKCHAIN.....'
echo '----------------------------------------'

su -l $linux_admin_user -c 'multichaind '$chainName' -daemon'

echo ''
echo ''
echo '----------------------------------------'
echo ''
echo ''
echo ''
echo ''

echo '----------------------------------------'
echo -e 'LOADING CONFIGURATION.....'
echo '----------------------------------------'

sleep 6

addr=`curl --user $rpcuser:$rpcpassword --data-binary '{"jsonrpc": "1.0", "id":"curltest", "method": "getaddresses", "params": [] }' -H 'content-type: text/json;' http://127.0.0.1:$rpcPort | jq -r '.result[0]'`


echo ''
echo ''
echo '----------------------------------------'
echo ''
echo ''
echo ''
echo ''


echo '----------------------------------------'
echo -e 'CREATING AND CONFIGURING STREAMS.....'
echo '----------------------------------------'


# CREATE STREAMS
# ------ -------

su -l $linux_admin_user -c  "multichain-cli "$chainName" createrawsendfrom "$addr" '{}' '[{\"create\":\"stream\",\"name\":\"asset_details\",\"open\":false,\"details\":{\"purpose\":\"Stores the details of assets\"}}]' send"

su -l $linux_admin_user -c  "multichain-cli "$chainName" createrawsendfrom "$addr" '{}' '[{\"create\":\"stream\",\"name\":\"offers_hex\",\"open\":false,\"details\":{\"purpose\":\"Stores hex data of an atomic exchange\"}}]' send"
su -l $linux_admin_user -c  "multichain-cli "$chainName" createrawsendfrom "$addr" '{}' '[{\"create\":\"stream\",\"name\":\"offers_details\",\"open\":false,\"details\":{\"purpose\":\"Stores details of a atomic exchange\"}}]' send"

su -l $linux_admin_user -c  "multichain-cli "$chainName" createrawsendfrom "$addr" '{}' '[{\"create\":\"stream\",\"name\":\"file_details\",\"open\":false,\"details\":{\"purpose\":\"Stores metadata of files\"}}]' send"
su -l $linux_admin_user -c  "multichain-cli "$chainName" createrawsendfrom "$addr" '{}' '[{\"create\":\"stream\",\"name\":\"file_data\",\"open\":false,\"details\":{\"purpose\":\"Stores file content\"}}]' send"


su -l $linux_admin_user -c  "multichain-cli "$chainName" createrawsendfrom "$addr" '{}' '[{\"create\":\"stream\",\"name\":\"proof_of_existence\",\"open\":false,\"details\":{\"purpose\":\"Stores Hashes\"}}]' send"


# SUBSCRIBE STREAMS
# --------- -------

su -l $linux_admin_user -c  "multichain-cli "$chainName" subscribe asset_details"
su -l $linux_admin_user -c  "multichain-cli "$chainName" subscribe offers_hex"
su -l $linux_admin_user -c  "multichain-cli "$chainName" subscribe offers_details"
su -l $linux_admin_user -c  "multichain-cli "$chainName" subscribe file_details"
su -l $linux_admin_user -c  "multichain-cli "$chainName" subscribe file_data"
su -l $linux_admin_user -c  "multichain-cli "$chainName" subscribe proof_of_existence"

echo ''
echo ''
echo '----------------------------------------'
echo ''
echo ''
echo ''
echo ''

echo -e '----------------------------------------'
echo -e 'BLOCKCHAIN SUCCESSFULLY SET UP!'
echo -e '----------------------------------------'


echo '----------------------------------------'
echo -e 'SETTING UP APPLICATIONS.....'
echo '----------------------------------------'

sudo bash -c 'chmod -R 755 '$webServerActiveDirectory
mv -f $INSTALLER_PATH/../yobichain-web $webServerActiveDirectory

cd $webServerActiveDirectory	# Changing current directory to web server's root directory

###
## INSTALLING & CONFIGURING Yobichain
###
app_directory=$webServerActiveDirectory'/yobichain-web'

# Configuring Yobichain
sudo sed -ie 's/$CHAIN_NAME =.*;/$CHAIN_NAME = "'$chainName'";/g' $app_directory/primechain_functions/config.php
sudo sed -ie 's/self::$PORT =.*;/self::$PORT = "'$explorerport'";/g' $app_directory/primechain_functions/config.php
sudo sed -ie 's/RPC_USER =.*;/RPC_USER = "'$rpcuser'";/g' $app_directory/primechain_functions/config.php
sudo sed -ie 's/RPC_PASSWORD =.*;/RPC_PASSWORD = "'$rpcpassword'";/g' $app_directory/primechain_functions/config.php
sudo sed -ie 's/RPC_PORT =.*;/RPC_PORT = "'$rpcPort'";/g' $app_directory/primechain_functions/config.php

sudo sed -ie 's/DB_HOST_NAME =.*;/DB_HOST_NAME = "'$db_host_name'";/g' $app_directory/primechain_functions/config.php
sudo sed -ie 's/DB_USER_NAME =.*;/DB_USER_NAME = "'$db_admin_user'";/g' $app_directory/primechain_functions/config.php
sudo sed -ie 's/DB_PASSWORD =.*;/DB_PASSWORD = "'$db_admin_pass'";/g' $app_directory/primechain_functions/config.php
sudo sed -ie 's/yobichain-db/'$db_name'/g' $app_directory/primechain_functions/config.php

sudo sed -ie 's/SMS_PROVIDER_API_KEY =.*;/SMS_PROVIDER_API_KEY = "'$sendinblue_api_key'";/g' $app_directory/primechain_functions/config.php

sudo sed -ie 's/EMAIL_PROVIDER_API_KEY =.*;/EMAIL_PROVIDER_API_KEY = "'$sendgrid_api_key'";/g' $app_directory/primechain_functions/config.php


###
## INSTALLING & CONFIGURING HASHCHAIN
###
git clone https://github.com/Primechain/hashchain.git

# Configuring Hashchain
sudo sed -ie 's/RPC_USER =.*;/RPC_USER = "'$rpcuser'";/g' $webServerActiveDirectory/hashchain/resources.php
sudo sed -ie 's/RPC_PASSWORD =.*;/RPC_PASSWORD = "'$rpcpassword'";/g' $webServerActiveDirectory/hashchain/resources.php
sudo sed -ie 's/RPC_PORT =.*;/RPC_PORT = "'$rpcPort'";/g' $webServerActiveDirectory/hashchain/resources.php
sudo sed -ie 's/MANAGER_ADDRESS =.*;/MANAGER_ADDRESS = "'$addr'";/g' $webServerActiveDirectory/hashchain/resources.php

###
## INSTALLING & CONFIGURING MULTICHAIN EXPLORER
###

cd $homedir
git clone https://github.com/MultiChain/multichain-explorer.git
cd multichain-explorer
sudo python setup.py install

sudo bash -c 'cp '$homedir'/multichain-explorer/chain1.example.conf '$homedir'/multichain-explorer/'$chainName'.conf'

sudo sed -ie 's/MultiChain chain1/'$explorerDisplayName'/g' $homedir/multichain-explorer/$chainName.conf
sudo sed -ie 's/2750/'$explorerport'/g' $homedir/multichain-explorer/$chainName.conf
sudo sed -ie 's/chain1/'$chainName'/g' $homedir/multichain-explorer/$chainName.conf
sudo sed -ie 's/host localhost.*\#/host  localhost 	#/g' $homedir/multichain-explorer/$chainName.conf
sudo sed -ie 's/host localhost/host 0.0.0.0/g' $homedir/multichain-explorer/$chainName.conf
sudo sed -ie 's/chain1.explorer.sqlite/'$chainName'.explorer.sqlite/g' $homedir/multichain-explorer/$chainName.conf

su -l $linux_admin_user -c "python -m Mce.abe --config "$homedir"/multichain-explorer/"$chainName".conf --commit-bytes 100000 --no-serve"
sleep 5
su -l $linux_admin_user -c "echo -ne '\n' | nohup python -m Mce.abe --config "$homedir"/multichain-explorer/"$chainName".conf > /dev/null 2>/dev/null &"

# Restarting Apache to load the changes
sudo service apache2 restart

echo ''
echo ''
echo '----------------------------------------'
echo ''
echo ''
echo ''
echo ''

echo -e '----------------------------------------'
echo -e 'APPLICATIONS SUCCESSFULLY SET UP!'
echo -e '----------------------------------------'
echo ''
echo ''
echo ''

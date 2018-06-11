#!/bin/bash

source yobichain.conf

if [ -f "$output_file_path" ]
then
	sudo mv $output_file_path $output_file_path".bak"
fi

sudo bash -e hardening.sh
sudo bash -e ftp.sh
sudo bash -e multichain.sh $1

echo -e '----------------------------------------'
echo -e 'BLOCKCHAIN SUCCESSFULLY SET UP!'
echo -e '----------------------------------------'
echo ''
echo ''

sudo cat $output_file_path
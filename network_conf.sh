#!/bin/bash

##################################
##### Configurazione di rete #####
##################################
mod_="configurazione di rete";
echo $mod_start $mod_;



echo "Modificare il file /etc/modprob.d/iwlwifi.conf e il file /etc/default/crda con le impostazioni ottimali?";
read -n1 choise;
if [ $choise == "y" ]; then
	sudo echo "# Test per rendere la connessione stabile
options iwlwifi 11n_disable=1
#options iwlwifi swcrypto=1
#options iwlwifi 11n_disable=8
#options iwlwifi wd_disable=1" >> /etc/modprobe.d/iwlwifi.conf;

	sudo echo "IT" >> /etc/default/crda;
	check_error "Modifica files iwlwifi.conf e crda";
else
	printf "${DG}${U}File iwlwifi.conf non modificato${NC}\n";
fi

check_tool "sudo_dmidecode" "tr";
check_mount $UUID_backup;
# scopro quale pc sto utilizzando e trasformo gli spazi in _ con il tool tr
# dmidecode è un tool che da informazioni sul terminale che si sta utilizzando
pc_version="`sudo dmidecode -s system-version | tr " " "_"`";
path_driver_backup=$mount_point/BACKUPs/CONFIG_LINUX/Driver/$pc_version;
path_sys_driver=/lib/firmware/;

echo "Copiare i driver contenuti in $path_driver_backup nella directory di sistema $path_sys_driver?";
read -n1 choise;
if [ "$choise" == "y" ]; then
	if [ -d "$path_driver_backup" ]; then
		for file in $path_driver_backup/*; do
			tmp=`basename $file`;
			if [ "$tmp" != "INFO" ]; then
				if [ -d $file ]; then
					sudo cp -r $file $path_sys_driver;
				else
					sudo cp $file $path_sys_driver;
				fi
				check_error "Aggiunta driver $file";
			fi
		done
	else
		printf "${R}Directory $path_driver_backup non esistene\n${NC}";
	fi
else
	printf "${DG}${U}Driver non copiati in $path_sys_driver\n${NC}";
fi



echo $mod_end $mod_;

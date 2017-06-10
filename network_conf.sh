#!/bin/bash

##################################
##### Configurazione di rete #####
##################################
mod_="configurazione di rete";
printf "\n${Y}++${NC}$mod_start $mod_\n";



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



echo "Copiare i driver contenuti in $path_driver_backup nella directory di sistema $path_sys_driver?";
read -n1 choise;
if [ "$choise" == "y" ]; then
	check_tool "sudo_dmidecode" "tr";
	check_mount $UUID_backup;
	# scopro quale pc sto utilizzando e trasformo gli spazi in _ con il tool tr
	# dmidecode è un tool che da informazioni sul terminale che si sta utilizzando
	pc_version="`sudo dmidecode -s system-version | tr " " "_"`";
	path_driver_backup=$mount_point$tree_dir/Driver/$pc_version;
	path_sys_driver=/lib/firmware/;

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


###### TODO --> da terminare
# modifica file /etc/nsswitch.conf per evitare bug di Avahi-daemon
_etc_nsswitch=/etc/nsswitch.conf;
echo "Modificare file $_etc_nsswitch per evitare bug nel software Avahi-daemon?";
read -n1 choise;
if [ "$choise" == "y" ]; then
	sudo cp $_etc_nsswitch $_etc_nsswitch"_old";
	new_str="hosts:          files dns";
	line_to_replace=hosts;
	# cerca il pattern $line_to_replace, sostituisci (s/) tutta la riga (.*) con $new_str
	# -i (in-place) --> modifica direttamente nel file originale
	sudo sed -i "/$line_to_replace/s/.*/$new_str/" $_etc_nsswitch;
	check_error "Modifica file $_etc_nsswitch";
else
	printf "${DG}${U}File $_etc_nsswitch non modificato\n${NC}";
fi



printf "${Y}--${NC}$mod_end $mod_\n";

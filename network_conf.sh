#!/bin/bash

# per evitare che lo script sia lanciato in modo diretto, cioè non lanciato dal main script
# applico l'algorimto di hashing sul numero casuale generato dal modulo
# principale e lo confronto con il file tmp
hash_check=`echo "$1" | md5sum`;
file_hash=`cat "$2" 2> /dev/null`;
[ ${#1} -eq 0 ] ||
[ ${#2} -eq 0 ] ||
[ "$hash_check" != "$file_hash" ] &&
printf "Attenzione! Questo script DEVE essere lanciato dallo script principale.\n" &&
exit 1;
##################################
##### Configurazione di rete #####
##################################
mod_="configurazione di rete";
printf "\n${Y}++${NC}$mod_start $mod_\n";
str_end="${Y}--${NC}$mod_end $mod_\n";



printf "Modificare impostazioni protocollo TCP?\n$choise_opt";
read -n1 choise;
printf "\n";
if [ "$choise" == "y" ]; then
	net_conf_file="/etc/sysctl.conf";
	$cmd "echo 'net.core.wmem_max=12582912' >> $net_conf_file";
	$cmd "echo 'net.core.rmem_max=12582912' >> $net_conf_file";
	$cmd "echo 'net.ipv4.tcp_rmem= 10240 87380 12582912' >> $net_conf_file";
	$cmd "echo 'net.ipv4.tcp_wmem= 10240 87380 12582912' >> $net_conf_file";
	$cmd "echo 'net.ipv4.tcp_window_scaling = 1' >> $net_conf_file";
	$cmd "echo 'net.ipv4.tcp_timestamps = 1' >> $net_conf_file";
	$cmd "echo 'net.ipv4.tcp_sack = 1' >> $net_conf_file";
	$cmd "echo 'net.ipv4.tcp_no_metrics_save = 1' >> $net_conf_file";
	$cmd "echo 'net.core.netdev_max_backlog = 5000' >> $net_conf_file";
	sudo sysctl -p;
	check_error "Modifica impostazioni protocollo TCP";
else
	printf "${DG}${U}Impostazioni protocollo TCP non modificate${NC}\n";
fi



printf "Modificare il file /etc/modprob.d/iwlwifi.conf e il file /etc/default/crda con le impostazioni ottimali?\n$choise_opt";
read -n1 choise;
printf "\n";
if [ "$choise" == "y" ]; then
	$cmd 'echo "# Test per rendere la connessione stabile
options iwlwifi 11n_disable=1
#options iwlwifi swcrypto=1
#options iwlwifi 11n_disable=8
#options iwlwifi wd_disable=1" >> /etc/modprobe.d/iwlwifi.conf';
  	check_error "Modifica files iwlwifi.conf";

	$cmd "sed -i 's/REGDOMAIN=/REGDOMAIN=IT/' /etc/default/crda";
	check_error "Modifica files crda";
else
	printf "${DG}${U}File iwlwifi.conf non modificato${NC}\n";
fi



printf "Copiare i driver contenuti in $path_driver_backup nella directory di sistema $path_sys_driver?\n$choise_opt";
read -n1 choise;
printf "\n";
if [ "$choise" == "y" ] && check_tool "sudo_dmidecode" "tr" && check_mount $UUID_backup; then
	# scopro quale pc sto utilizzando e trasformo gli spazi in _ con il tool tr
	# dmidecode è un tool che da informazioni sul terminale che si sta utilizzando
	pc_version="`sudo dmidecode -s system-version | tr " " "_"`";
	path_driver_backup=$mount_point/$tree_dir/$driver_backup/$pc_version;
	path_sys_driver=/lib/firmware/;

	if [ -d "$path_driver_backup" ]; then
		for file in $path_driver_backup/*; do
			tmp=`basename $file`;
			if [ "$tmp" != "INFO" ]; then
				sudo cp -r $file $path_sys_driver;
				check_error "Aggiunta driver $file";
			fi
		done
	else
		printf "${R}Directory $path_driver_backup non esistene\n${NC}";
	fi
else
	printf "${DG}${U}Driver non copiati in $path_sys_driver\n${NC}";
fi



# modifica file /etc/nsswitch.conf per evitare bug di Avahi-daemon
_etc_nsswitch=/etc/nsswitch.conf;
printf "Modificare file $_etc_nsswitch per evitare il bug nel software Avahi-daemon?\n$choise_opt";
read -n1 choise;
printf "\n";
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



printf "$str_end";

#!/bin/bash

######################################################
##### Configurazione impostazioni protocollo TCP #####
######################################################
mod_="configurazione impostazioni protocollo TCP";
printf "\n${Y}++${NC}$mod_start $mod_\n";



printf "Modificare impostazioni protocollo TCP?\n";
read -n1 choise;
if [ $choise == "y" ]; then
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



printf "${Y}--${NC}$mod_end $mod_\n";

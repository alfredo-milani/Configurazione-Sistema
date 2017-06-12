#!/bin/bash

if [ ${#1} == 0 ] || [ $1 != 16 ]; then
	printf "Attenzione! Questo script DEVE essere lanciato dallo script principale.\n";
	exit 1;
fi
####################################
##### Creazione link simbolici #####
####################################
mod_="configurazione link simbolici";
printf "\n${Y}++${NC}$mod_start $mod_\n";



xdg="xdg-user-dir";
check_tool $xdg;
scaricati="`$xdg DOWNLOAD`";
echo "Vuoi creare un link simbolico di un file system temporaneo in $scaricati?";
read -n1 choise;
if [ $choise == "y" ]; then
	if ! [ -d $scaricati"/shm" ]; then
		ln -s $_dev_shm_ $scaricati;
		check_error "Creazione link simbolico in $scaricati";
	else
		printf "${DG}${U}File $scaricati/shm già esistente\n${NC}";
	fi
else
	printf "${DG}${U}Link simbolico in $scaricati non creato${NC}\n";
fi

scrivania="`$xdg DESKTOP`";
nome_link="Alfredo_files";
dir_data_relative="Alfredo";
echo "Vuoi creare il link simbolico in $scrivania?";
read -n1 choise;
if [ $choise == "y" ]; then
	if ! [ -d $scrivania/$nome_link ]; then
		check_mount $UUID_data;
		ln -s $mount_point/$dir_data_relative $scrivania/$nome_link;
		check_error "Creazione link simbolico in $scrivania";
	else
		printf "${DG}${U}File $scrivania/Alfredo_files già esistente${NC}\n";
	fi
else
	printf "${DG}${U}Link simbolico in $scrivania non creato${NC}\n";
fi



printf "${Y}--${NC}$mod_end $mod_\n";

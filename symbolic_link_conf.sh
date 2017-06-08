#!/bin/bash

####################################
##### Creazione link simbolici #####
####################################
mod_="configurazione link simbolici";
echo ++$mod_start $mod_;



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
echo "Vuoi creare il link simbolico in $scrivania?";
read -n1 choise;
if [ $choise == "y" ]; then
	if ! [ -d $scrivania"/Alfredo_files" ]; then
		mount_point=/media/Data/;
		# Se directory $mount_point NON esiste
		# -d --> esiste la directory?
		# -f --> esiste il file?
		if ! [ -d $mount_point ]; then
			sudo mkdir $mount_point;
		fi
		sudo mount UUID=$UUID_data $mount_point;
		ln -s $mount_point"Alfredo" $scrivania"/Alfredo_files";
		check_error "Creazione link simbolico in $scrivania";
	else
		printf "${DG}${U}File $scrivania/Alfredo_files già esistente${NC}\n";
	fi
else
	printf "${DG}${U}Link simbolico in $scrivania non creato${NC}\n";
fi



mod_="configurazione link simbolici";
echo --$mod_end $mod_;

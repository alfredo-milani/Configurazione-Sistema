#!/bin/bash

# per evitare che lo script sia lanciato in modo diretto, cioù non lanciato dal main script
if [ ${#1} == 0 ] || [ $1 != 16 ]; then
	printf "Attenzione! Questo script DEVE essere lanciato dallo script principale.\n";
	exit 1;
fi
#####################################
##### Configurazione file fstab #####
#####################################
mod_="configurazione file fstab";
printf "\n${Y}++${NC}$mod_start $mod_\n";
str_end="${Y}--${NC}$mod_end $mod_\n";



# tool per vedere il path assoluto di una specifica direzione
xdg="xdg-user-dir";
echo "Vuoi modificare il file /etc/fstab per aggiungere RAMDISK? Premi y per OK";
read -n1 ready;
if [ "$ready" == "y" ] && check_tool $xdg; then
	home="`$xdg HOME`";

	echo "Configurazione file '/etc/fstab'";
	user=`id -u`;
	group=`id -g`;
	echo "Utilizzare l'UUID di default (UUID default = $UUID_data)? Premi y per OK";
	read -n1 choise;
	while ! [ $choise == "y" ]; do
		echo "Esecuzione del comando 'lsblk -f' per vedere l'UUID del device...";
		lsblk -f;
		echo "Digita l'UUID del device che si vuole utilizzare:";
		read UUID_data;
		echo "L'UUID = '$UUID_data' è corretto? Premi y per OK";
		read -n1 choise;
	done

	fstab="#########################################################\n
	### RAMDISK ###\n
	####################################################################################################################\n
	# File di log, cache di browser e temporanei montati su ramdisk\n
	tmpfs /tmp tmpfs defaults,noatime 0 0\n\n

	#tmpfs $home/.cache/google-chrome/Default tmpfs defaults,noatime 0 0\n
	#tmpfs $home/.cache/chromium/Default tmpfs defaults,noatime 0 0\n
	#tmpfs $home/.cache/mozilla/firefox/k7t3gsx4.default/cache2 tmpfs defaults,noatime 0 0\n\n

	tmpfs /var/tmp tmpfs defaults,noatime 0 0\n
	tmpfs /var/log tmpfs defaults,noatime 0 0\n
	####################################################################################################################\n\n\n


	#################################################################################\n
	### Windows partition ###\n
	####################################################################################################################\n
	# VEDI ~/INFORMATICA/ISTRUZIONI UTILI/Bash per maggiori informazioni\n
	UUID=\"$UUID_data\" /media/Data ntfs auto,uid=$user,gid=$group,umask=037,nls=utf8 0 0\n
	####################################################################################################################";

	# metodo alternativo all'uso del comando '/bin/su -c "cmd"'
	cd $_dev_shm_;
	tmp_etc="tmp_etc";
	file_fstab="fstab";
	_etc_="/etc/";
	mkdir $tmp_etc;
	cd $tmp_etc;
	cp $_etc_$file_fstab .;
	# flag '-e' per abilitare l'interpretazione del backslash
	echo -e $fstab >> $file_fstab;
	sudo mv $_etc_$file_fstab $_etc_$file_fstab"_old";
	sudo cp $file_fstab $_etc_;
	check_error "Modifica file $_etc_$file_fstab";
else
	printf "${DG}${U}File /etc/fstab non moficato${NC}\n";
fi



printf "$str_end";

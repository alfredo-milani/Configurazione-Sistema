#!/bin/bash

# Autore: Alfredo Milani
# Data: 10 - 06 - 2017

# per evitare che lo script sia lanciato in modo diretto, cioè non lanciato dal main script
# applico l'algorimto di hashing sul numero casuale generato dal modulo
# principale e lo confronto con il file tmp
hash_check=`echo "$1" | md5sum`;
file_hash=`cat "$2" 2> /dev/null`;
[ ${#1} -eq 0 ] ||
[ ${#2} -eq 0 ] ||
[ "$hash_check" != "$file_hash" ] &&
printf "\nAttenzione! Lo script `basename $0` DEVE essere lanciato dallo script principale.\n\n" &&
exit 1;
#####################################
##### Configurazione file fstab #####
#####################################
mod_="configurazione file fstab";
printf "\n${Y}++${NC}$mod_start $mod_\n";
str_end="${Y}--${NC}$mod_end $mod_\n";
father_file=$2;



# tool per vedere il path assoluto di una specifica direzione
xdg="xdg-user-dir";
printf "Vuoi modificare il file /etc/fstab per aggiungere RAMDISK?\n$choise_opt";
read choise;
if [ "$choise" == "y" ] && check_tool $xdg; then
	home="`$xdg HOME`";

	echo "Configurazione file '/etc/fstab'";
	user=`id -u`;
	group=`id -g`;
	printf "Utilizzare l'UUID di default (UUID default = $UUID_data)?\n$choise_opt";
	read choise;
	while ! [ "$choise" == "y" ]; do
		echo "Esecuzione del comando 'lsblk -f' per vedere l'UUID del device...";
		lsblk -f;
		printf "Digitare l'UUID del device che si vuole utilizzare:\t";
		read UUID_data;
		printf "L'UUID = '$UUID_data' è corretto?\n$choise_opt";
		read choise;
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

	# riavvio richiesto
	reboot_req "$father_file";
else
	printf "${DG}${U}File /etc/fstab non moficato${NC}\n";
fi



restore_tmp_file $1 $2;
printf "$str_end";

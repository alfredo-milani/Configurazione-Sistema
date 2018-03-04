#!/bin/bash
# Per evitare che lo script sia lanciato in modo diretto, cioè non lanciato dal main script
# applico l'algorimto di hashing sul numero casuale generato dal modulo
# principale e lo confronto con il file tmp
hash_check=`echo "$1" | md5sum`
file_hash=`cat "$2" 2> /dev/null`
[ ${#1} -eq 0 ] ||
[ ${#2} -eq 0 ] ||
[ "$hash_check" != "$file_hash" ] &&
printf "\nAttenzione! Lo script `basename $0` DEVE essere lanciato dallo script principale.\n\n" &&
exit 1
#####################################
##### Configurazione file fstab #####
#####################################
mod_="configurazione file fstab"
printf "\n${Y}++${NC}$mod_start $mod_\n"
str_end="${Y}--${NC}$mod_end $mod_\n"
father_file=$2



# tool per vedere il path assoluto di una specifica direzione
xdg="xdg-user-dir"
printf "Vuoi modificare il file /etc/fstab per aggiungere RAMDISK?\n$choise_opt"
read choise
if [ "$choise" == "y" ] && check_tool $xdg; then
	home="`$xdg HOME`"

	echo "Configurazione file '/etc/fstab'"
	user=`id -u`
	group=`id -g`
	printf "Utilizzare l'UUID di default (UUID default = $UUID_data) per motare il device secondario?\n$choise_opt"
	read choise
	while ! [ "$choise" == "y" ]; do
		printf "\nEsecuzione del comando 'lsblk -f' per vedere l'UUID del device:\n"
		lsblk -f
		printf "Digitare l'UUID del device che si vuole utilizzare:\t"
		read UUID_data
		printf "L'UUID = '$UUID_data' è corretto?\n$choise_opt"
		read choise
	done

    _etc_fstab_="/etc/fstab"
    sudo mv ${_etc_fstab_} ${_etc_fstab_}"_old"
    sudo tee -a <<EOF ${_etc_fstab_} 1> ${null}



#########################################################
### RAMDISK ###
####################################################################################################################
# File di log, cache di browser e temporanei montati su ramdisk
tmpfs /tmp tmpfs defaults,noatime 0 0

tmpfs $home/.cache tmpfs defaults,noatime 0 0
# tmpfs $home/.cache/google-chrome/ tmpfs defaults,noatime 0 0
# tmpfs $home/.cache/chromium/ tmpfs defaults,noatime 0 0
# tmpfs $home/.cache/mozilla/firefox/ tmpfs defaults,noatime 0 0

tmpfs /var/tmp tmpfs defaults,noatime 0 0
tmpfs /var/log tmpfs defaults,noatime 0 0
####################################################################################################################


#########################################################
### Windows partition ###
####################################################################################################################
# VEDI ~/INFORMATICA/ISTRUZIONI UTILI/Bash per maggiori informazioni
UUID="$UUID_data" /media/Data ntfs auto,uid=$user,gid=$group,umask=037,nls=utf8 0 0
####################################################################################################################
EOF

	check_error "Modifica file $_etc_fstab_"

	# riavvio richiesto
	reboot_req "$father_file"
else
	printf "${DG}${U}File /etc/fstab non moficato${NC}\n"
fi



restore_tmp_file $1 $2
printf "$str_end"

#!/bin/bash
# ============================================================================

# Titolo:           tracker_disable_conf.sh
# Descrizione:      Disabilitazione tracker-tool*
# Autore:           Alfredo Milani  (alfredo.milani.94@gmail.com)
# Data:             mar 25 lug 2017, 16.59.26, CEST
# Licenza:          MIT License
# Versione:         1.5.0
# Note:             --/--
# Versione bash:    4.4.12(1)-release
# ============================================================================



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
####################################
##### Disabilitazione tracker* #####
####################################
mod_="disabilitazione tracker-*";
printf "\n${Y}++${NC}$mod_start $mod_\n";
str_end="${Y}--${NC}$mod_end $mod_\n";
father_file=$2;



printf "Vuoi disabilitare tracker* tools?\n$choise_opt";
read choise;
if [ "$choise" == "y" ]; then
	files_da_modificare="tracker-*";
	path_as="/etc/xdg/autostart/";
	old_str="X-GNOME-Autostart-enabled=true";
	new_str="X-GNOME-Autostart-enabled=false";
	sudo sed -i "s/$old_str/$new_str/g" "$path_as$files_da_modificare";
	check_error "Modifica files tracker-* in $path_as";
	echo "Lancio del comando 'tracker-preferences' per disabilitare tracker-* completamente";
	tracker-preferences &> $null;

	# riavvio richiesto
	reboot_req "$father_file";
else
	printf "${DG}${U}tracker* tools non disabilitato${NC}\n";
fi



restore_tmp_file $1 $2;
printf "$str_end";

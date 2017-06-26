#!/bin/bash

# per evitare che lo script sia lanciato in modo diretto, cioè non lanciato dal main script
# applico l'algorimto di hashing sul numero casuale generato dal modulo
# principale e lo confronto con il file tmp
hash_check=`echo "$1" | md5sum`;
[ ${#1} -eq 0 ] ||
[ ${#2} -eq 0 ] ||
[ "$hash_check" != "`cat "$2" &> /dev/null`" ] &&
printf "Attenzione! Questo script DEVE essere lanciato dallo script principale.\n" &&
exit 1;
####################################
##### Disabilitazione tracker* #####
####################################
mod_="disabilitazione tracker-*";
printf "\n${Y}++${NC}$mod_start $mod_\n";
str_end="${Y}--${NC}$mod_end $mod_\n";



echo "Vuoi disabilitare tracker* tools?";
read -n1 choise;
if [ $choise == "y" ]; then
	files_da_modificare="tracker-*";
	path_as="/etc/xdg/autostart/";
	old_str="X-GNOME-Autostart-enabled=true";
	new_str="X-GNOME-Autostart-enabled=false";
	sudo sed -i "s/$old_str/$new_str/g" $path_as$files_da_modificare;
	check_error "Modifica files tracker-* in $path_as";
	echo "Lancio del comando 'tracker-preferences' per disabilitare tracker-* completamente";
	tracker-preferences &> $null;
else
	printf "${DG}${U}tracker* tools non disabilitato${NC}\n";
fi



printf "$str_end";

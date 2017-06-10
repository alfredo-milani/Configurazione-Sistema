#!/bin/bash

####################################
##### Disabilitazione tracker* #####
####################################
mod_="disabilitazione tracker-*";
printf "\n${Y}++${NC}$mod_start $mod_\n";



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



printf "${Y}--${NC}$mod_end $mod_\n";

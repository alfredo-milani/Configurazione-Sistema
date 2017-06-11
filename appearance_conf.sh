#!/bin/bash

##################################
##### Configurazione aspetto #####
##################################
mod_="configurazione aspetto";
printf "\n${Y}++${NC}$mod_start $mod_\n";



check_tool "gsettings";
echo "Vuoi configurare il tema GTK+ del sistema? Premi y per OK";
read -n1 ready;
if [ "$ready" = "y" ]; then
	check_mount $UUID_backup;

	theme_scelto="T4G_3.0_theme";
	path_backup_theme=$mount_point/$tree_dir/$themes_backup;
	path_sys_theme=/usr/share/themes/;
	sudo cp -r $path_backup_theme/$theme_scelto $path_sys_theme;
	check_error "Copia tema in $path_sys_theme";
	gsettings set org.gnome.desktop.interface gtk-theme $theme_scelto;
	check_error "Impostazione del tema $theme_scelto in $path_sys_theme";
else
	printf "${DG}${U}Tema non configurato${NC}\n";
fi

echo "Vuoi configurare le icone del sistema? Premi y per OK";
read -n1 ready;
if [ "$ready" = "y" ]; then
	check_mount $UUID_backup;

	icon_scelto="Flat_Remix";
	path_backup_icon=$mount_point/$tree_dir/$icons_backup;
	path_sys_icon="/usr/share/icons/";
	sudo cp -r $path_backup_icon/$icon_scelto $path_sys_icon;
	check_error "Copia set di icone in $path_sys_icon";
	gsettings set org.gnome.desktop.interface icon-theme $icon_scelto;
	check_error "Impostazione del set di icone $icon_scelto in $path_sys_icon";
else
	printf "${DG}${U}Icone non configurate${NC}\n";
fi



printf "${Y}--${NC}$mod_end $mod_\n";

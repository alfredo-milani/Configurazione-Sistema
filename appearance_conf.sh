#!/bin/bash

##################################
##### Configurazione aspetto #####
##################################
mod_="configurazione aspetto\n";
printf "${Y}++${NC}$mod_start $mod_";



check_tool "gsettings";
check_mount $UUID_backup;
echo "Vuoi configurare il tema GTK+ del sistema? Premi y per OK";
read -n1 ready;
if [ "$ready" = "y" ]; then
	theme_scelto="T4G_3.0_theme";
	path_backup_theme=$mount_point/BACKUPs/CONFIG_LINUX/Aspetto/Themes/;
	path_sys_theme=/usr/share/themes/;
	sudo cp -r $path_backup_theme$theme_scelto $path_sys_theme;
	gsettings set org.gnome.desktop.interface gtk-theme $theme_scelto;
	check_error "Impostazione del tema $theme_scelto in $path_sys_theme";
else
	printf "${DG}${U}Tema non configurato${NC}\n";
fi

echo "Vuoi configurare le icone del sistema? Premi y per OK";
read -n1 ready;
if [ "$ready" = "y" ]; then
	icon_scelto="Flat_Remix";
	path_backup_icon=$mount_point/BACKUPs/CONFIG_LINUX/Aspetto/Icons/;
	path_sys_icon="/usr/share/icons/";
	sudo cp -r $path_backup_icon$icon_scelto $path_sys_icon;
	gsettings set org.gnome.desktop.interface icon-theme $icon_scelto;
	check_error "Impostazione del set di icone $icon_scelto in $path_sys_icon";
else
	printf "${DG}${U}Icone non configurate${NC}\n";
fi



printf "${Y}--${NC}$mod_end $mod_";

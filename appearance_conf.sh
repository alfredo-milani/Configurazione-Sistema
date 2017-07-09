#!/bin/bash

# per evitare che lo script sia lanciato in modo diretto, cioè non lanciato dal main script
# applico l'algorimto di hashing sul numero casuale generato dal modulo
# principale e lo confronto con il file tmp
hash_check=`echo "$1" | md5sum`;
file_hash=`cat "$2" 2> /dev/null`;
[ ${#1} -eq 0 ] ||
[ ${#2} -eq 0 ] ||
[ "$hash_check" != "$file_hash" ] &&
printf "Attenzione! Questo script DEVE essere lanciato dallo script principale.\n" &&
exit 1;
##################################
##### Configurazione aspetto #####
##################################
mod_="configurazione aspetto";
printf "\n${Y}++${NC}$mod_start $mod_\n";
str_end="${Y}--${NC}$mod_end $mod_\n";



# funzione per decomprimere archivi
# argomento #1 --> path di locazione
# argomento #2 --> nome file
function extract_files {
	# se è un file compresso --> decomprimilo
	if [ -f "$1/$2" ]; then
		tmp="${2##*.}";
		case "$tmp" in
			tar ) 	tar -xf "$1/$2" -C "$1" &> $null ;;
			xz )	tar -xvf "$1/$2" -C "$1" &> $null ;;
			gz )	tar -zxvf "$1/$2" -C "$1" &> $null ;;
			bz2 )	tar -jxvf "$1/$2" -C "$1" &> $null ;;
			zip ) 	unzip "$1/$2" -d "$1" &> $null ;;
			7z ) 	7z x "$1/$2" -o"$1" &> $null ;;
			* )
					printf "${R}Formato sconosciuto: $tmp. Estrazione non riuscita.\n${NC}";
					return $EXIT_FAILURE;
		esac

		printf "Vuoi rimuovere il file compresso?\n$choise_opt";
		read choise;
		[ "$choise" == "y" ] && rm -rf "$1/$2";

	# se non è neanche una directory --> il nome del file è errato
	elif ! [ -d "$1/$2" ]; then
		printf "${R}Errore. Il file: $2 non esiste\n${NC}";
		return $EXIT_FAILURE;
	fi

	return $EXIT_SUCCESS;
}

printf "Vuoi configurare il tema GTK+ del sistema?\n$choise_opt";
read choise;
if [ "$choise" == "y" ] && check_tool "gsettings" && check_mount $UUID_backup; then
	path_backup_theme=$mount_point/$tree_dir/$themes_backup;
	path_sys_theme=/usr/share/themes/;

	! extract_files $path_backup_theme $theme_scelto &&
	printf "$str_end" && exit $EXIT_FAILURE;

	sudo cp -r $path_backup_theme/$theme_scelto $path_sys_theme;
	check_error "Copia tema in $path_sys_theme";
	gsettings set org.gnome.desktop.interface gtk-theme $theme_scelto;
	check_error "Impostazione del tema $theme_scelto in $path_sys_theme";
else
	printf "${DG}${U}Tema non configurato${NC}\n\n";
fi

printf "Vuoi configurare le icone del sistema?\n$choise_opt";
read choise;
if [ "$choise" = "y" ] && check_tool "gsettings" && check_mount $UUID_backup; then
	path_backup_icon=$mount_point/$tree_dir/$icons_backup;
	path_sys_icon="/usr/share/icons/";

	! extract_files $path_backup_icon $icon_scelto &&
	printf "$str_end" && exit $EXIT_FAILURE;

	sudo cp -r $path_backup_icon/$icon_scelto $path_sys_icon;
	check_error "Copia set di icone in $path_sys_icon";
	gsettings set org.gnome.desktop.interface icon-theme $icon_scelto;
	check_error "Impostazione del set di icone $icon_scelto in $path_sys_icon";
else
	printf "${DG}${U}Icone non configurate${NC}\n";
fi



printf "$str_end";

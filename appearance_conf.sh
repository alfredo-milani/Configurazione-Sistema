#!/bin/bash

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
##################################
##### Configurazione aspetto #####
##################################
mod_="configurazione aspetto";
printf "\n${Y}++${NC}$mod_start $mod_\n";
str_end="${Y}--${NC}$mod_end $mod_\n";
father_file=$2;



# funzione per decomprimere archivi
# argomento #1 --> path di locazione
# argomento #2 --> nome file
function extract_files {
	# se è un file compresso --> decomprimilo
	if [ -f "$1/$2" ]; then
		printf "Estrarre il file $2 all'interno della cartella $1?\n(Defalt path: $_dev_shm_)\n$choise_opt";
		read choise;
		[ "$choise" == "y" ] && dest_path="$1" || dest_path="$_dev_shm_";

		tmp="${2##*.}";
		case "$tmp" in
			tar ) 	tar -xf "$1/$2" -C "$dest_path" &> $null ;;
			xz )	tar -xvf "$1/$2" -C "$dest_path" &> $null ;;
			gz )	tar -zxvf "$1/$2" -C "$dest_path" &> $null ;;
			bz2 )	tar -jxvf "$1/$2" -C "$dest_path" &> $null ;;
			zip ) 	unzip "$1/$2" -d "$dest_path" &> $null ;;
			7z ) 	7z x "$1/$2" -o"$dest_path" &> $null ;;
			* )
					printf "${R}Formato sconosciuto: $tmp. Estrazione non riuscita.\n${NC}";
					return $EXIT_FAILURE;
		esac

		printf "Vuoi rimuovere il file compresso?\n$choise_opt";
		read choise;
		[ "$choise" == "y" ] && rm -rf "$1/$2";

	# se non è neanche una directory --> il nome del file è errato
	elif ! [ -d "$1/$2" ]; then
		printf "${R}Errore. Il file: $1/$2 non esiste\n${NC}";
		return $EXIT_FAILURE;
	fi

	return $EXIT_SUCCESS;
}

function manage_theme {
	path_backup_theme=$mount_point/$tree_dir/$themes_backup;
	path_sys_theme=/usr/share/themes/;

	! extract_files $path_backup_theme $theme_scelto &&
	return $EXIT_FAILURE;

	sudo cp -r $path_backup_theme/$theme_scelto $path_sys_theme;
	check_error "Copia tema in $path_sys_theme";
	gsettings set org.gnome.desktop.interface gtk-theme $theme_scelto;
	check_error "Impostazione del tema $theme_scelto in $path_sys_theme";
}

function manage_icon {
	path_backup_icon=$mount_point/$tree_dir/$icons_backup;
	path_sys_icon="/usr/share/icons/";

	! extract_files $path_backup_icon $icon_scelto &&
	return $EXIT_FAILURE;

	sudo cp -r $path_backup_icon/$icon_scelto $path_sys_icon;
	check_error "Copia set di icone in $path_sys_icon";
	gsettings set org.gnome.desktop.interface icon-theme $icon_scelto;
	check_error "Impostazione del set di icone $icon_scelto in $path_sys_icon";
}



printf "Vuoi configurare il tema GTK+ del sistema?\n$choise_opt";
read choise;
if ! ([ "$choise" == "y" ] && check_tool "gsettings" && check_mount $UUID_backup &&
	# () --> subshell
	([ ${#theme_scelto} == 0 ] && print_missing_val "theme_scelto" && exit 1 || exit 0) &&
	manage_theme); then
	printf "${DG}${U}Tema non configurato${NC}\n\n";
fi

printf "Vuoi configurare le icone del sistema?\n$choise_opt";
read choise;
if ! ([ "$choise" = "y" ] && check_tool "gsettings" &&
	check_mount $UUID_backup &&
	([ ${#icon_scelto} == 0 ] && print_missing_val "icon_scelto" && exit 1 || exit 0) &&
	manage_icon); then
	printf "${DG}${U}Icone non configurate${NC}\n";
fi



restore_tmp_file $1 $2;
printf "$str_end";

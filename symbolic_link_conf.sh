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
####################################
##### Creazione link simbolici #####
####################################
mod_="configurazione link simbolici";
printf "\n${Y}++${NC}$mod_start $mod_\n";
str_end="${Y}--${NC}$mod_end $mod_\n";



xdg="xdg-user-dir";
echo "Vuoi creare un link simbolico di un file system temporaneo nella sezione Download?";
read -n1 choise;
if [ $choise == "y" ] && check_tool $xdg; then
	scaricati="`$xdg DOWNLOAD`";

	if ! [ -d $scaricati"/shm" ]; then
		ln -s $_dev_shm_ $scaricati;
		check_error "Creazione link simbolico in $scaricati";
	else
		printf "${DG}${U}File $scaricati/shm già esistente\n${NC}";
	fi
else
	printf "${DG}${U}Link simbolico in $scaricati non creato${NC}\n";
fi



echo "Vuoi creare il link simbolico nella Scrivania?";
read -n1 choise;
if [ $choise == "y" ] && check_tool $xdg; then
	scrivania="`$xdg DESKTOP`";
	nome_link="Alfredo_files";
	dir_data_relative="Alfredo";

	# TODO cercare possibile bug...
	if ! [ -d $scrivania/$nome_link ] && check_mount $UUID_data; then
		ln -s $mount_point/$dir_data_relative $scrivania/$nome_link;
		check_error "Creazione link simbolico in $scrivania";
	else
		printf "${DG}${U}File $scrivania/Alfredo_files già esistente${NC}\n";
	fi
else
	printf "${DG}${U}Link simbolico in $scrivania non creato${NC}\n";
fi



printf "$str_end";

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
####################################
##### Creazione link simbolici #####
####################################
mod_="configurazione link simbolici"
printf "\n${Y}++${NC}$mod_start $mod_\n"
str_end="${Y}--${NC}$mod_end $mod_\n"
father_file=$2



xdg="xdg-user-dir"
printf "Vuoi creare un link simbolico di un file system temporaneo nella sezione Downloads?\n$choise_opt"
read choise
if [ "$choise" == "y" ] && check_tool $xdg; then
	scaricati="`$xdg DOWNLOAD`"

	if ! [ -d "$scaricati/shm" ]; then
		ln -s $_dev_shm_ $scaricati
		check_error "Creazione link simbolico in $scaricati"
	else
		printf "${DG}${U}File $scaricati/shm già esistente\n\n${NC}"
	fi
else
	printf "${DG}${U}Link simbolico in $scaricati non creato${NC}\n\n"
fi



printf "Vuoi creare il link simbolico nella Scrivania (Alfredo e TODO)?\n$choise_opt"
read choise
if [ "$choise" == "y" ] && check_tool $xdg; then
	scrivania="`$xdg DESKTOP`"
	nome_link="Alfredo"
	todo_nome_link="TODO"
	dir_data_relative="Alfredo"

	if ! [ -d "$scrivania/$nome_link" ] && check_mount $UUID_data; then
		ln -s $mount_point/$dir_data_relative $scrivania/$nome_link
		check_error "Creazione link simbolico di $mount_point/$dir_data_relative in $scrivania"
	else
		printf "${DG}${U}File $scrivania/Alfredo_files già esistente${NC}\n"
	fi

	if ! [ -d "$scrivania/$nome_link" ] && check_mount $UUID_data; then
		ln -s $mount_point/$dir_data_relative/${todo_nome_link} $scrivania/$todo_nome_link
		check_error "Creazione link simbolico di $mount_point/$dir_data_relative/${todo_nome_link} in $scrivania"
	else
		printf "${DG}${U}File $scrivania/Alfredo_files già esistente${NC}\n"
	fi
else
	printf "${DG}${U}Link simbolico in $scrivania non creato${NC}\n"
fi



restore_tmp_file $1 $2
printf "$str_end"

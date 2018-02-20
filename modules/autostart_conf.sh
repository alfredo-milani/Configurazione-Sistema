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
##### Disabilitazione tracker* #####
####################################
mod_="disabilitazione autostart tools"
printf "\n${Y}++${NC}$mod_start $mod_\n"
str_end="${Y}--${NC}$mod_end $mod_\n"
father_file=$2


path_as="/etc/xdg/autostart"
printf "Vuoi disabilitare l'avvio automatico di tracker* tools?\n$choise_opt"
read choise
if [ "$choise" == "y" ]; then
	file="tracker-*"

	<<COMM
	old_str="X-GNOME-Autostart-enabled=true"
	new_str="X-GNOME-Autostart-enabled=false"
	for file in "$path_as/"$file; do
		sudo sed -i "s/$old_str/$new_str/g" "$file"
		sudo tee -a <<< `printf "\nHidden=true\n"` "$file"
	done
COMM

	for file in "$path_as/"$file; do
		sudo mv "$file" "$file"_old
	done
	check_error "Modifica files $file in $path_as"

	gsettings set org.freedesktop.Tracker.Miner.Files crawling-interval -2
	gsettings set org.freedesktop.Tracker.Miner.Files enable-monitors false
	tracker reset --hard
	echo "Lancio del comando 'tracker-preferences' per disabilitare $file completamente"
	tracker-preferences &> $null

	# riavvio richiesto
	reboot_req "$father_file"
else
	printf "${DG}${U}$file tools non disabilitato${NC}\n"
fi

printf "Vuoi disabilitare l'avvio automatico di orca tool?\n$choise_opt"
read choise
if [ "$choise" == "y" ]; then
	file="orca-autostart.desktop"

	<<COMM
	old_str="NoDisplay=true"
	new_str="NoDisplay=false"
	sudo sed -i "s/$old_str/$new_str/g" "$path_as/$file"
	check_error "Modifica files orca-autostart #1 in $path_as"

	old_str="X-GNOME-AutoRestart=true"
	new_str="X-GNOME-AutoRestart=false"
	sudo sed -i "s/$old_str/$new_str/g" "$path_as/$file"
	check_error "Modifica files orca-autostart #2 in $path_as"
COMM

	sudo mv "$path_as/$file" "$path_as/$file"_old
	check_error "Modifica files $file in $path_as"

	# riavvio richiesto
	reboot_req "$father_file"
else
	printf "${DG}${U}$file tools non disabilitato${NC}\n"
fi

printf "Vuoi disabilitare l'avvio automatico di caribou tool (tastiera a schermo)?\n$choise_opt"
read choise
if [ "$choise" == "y" ]; then
	# tastiera on screen
	file="caribou-autostart.desktop"

	sudo mv "$path_as/$file" "$path_as/$file"_old
	check_error "Modifica files $file in $path_as"

	# riavvio richiesto
	reboot_req "$father_file"
else
	printf "${DG}${U}$file tools non disabilitato${NC}\n"
fi

printf "Vuoi impostare l'avvio automatico del tool redshift?\n$choise_opt"
read choise
if [ "$choise" == "y" ]; then
	file="redshift.desktop"

	sudo tee << EOF "$path_as/$file" 1> $null
[Desktop Entry]
Exec=/usr/bin/redshift_regolator.sh %f
Terminal=false
Type=Application
NoDisplay=true
EOF
	check_error "Modifica files $file in $path_as"

	# riavvio richiesto
	reboot_req "$father_file"
else
	printf "${DG}${U}$file non impostato per l'autostart${NC}\n"
fi



restore_tmp_file $1 $2
printf "$str_end"

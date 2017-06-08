#!/bin/bash

##############################
##### Modifica shortcuts #####
##############################
mod_="configurazione shortcuts";
echo ++$mod_start $mod_;



gs="gsettings";
str_esito="Impostazione della chiave [%s] con valore [%s]\n";
media_keys="org.gnome.settings-daemon.plugins.media-keys";
# The characters in the value of the IFS variable are used to split the input line into words or tokens
IFS=';'
# sintassi:
#	nome_var="Nome_Comando;'Combinazione_tasti'"
browser_sc="www;'<Ctrl>G'";
control_c="control-center;'<Ctrl>I'";
# NOTA: le virgolette sono NECESSARIE
shortcuts_array=("$browser_sc" "$control_c");
# custom keybindings
path_custom_sc="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/";
custom_kb="custom-keybinding";

terminal="Terminal;gnome-terminal;'<Ctrl><Alt>T'";
redshift="RedShift;redshift -l 41.6:13.4;'<Ctrl><Shift>F'";
home_sc="Home;nautilus;'<Ctrl>N'";
home_sc2="Home2;nautilus;'<Ctrl>M'";
chrome_sc="Google-Chrome;google-chrome --disk-cache-dir='/dev/shm';'<Ctrl>G'";
ping_sc="Ping;gnome-terminal -e 'ping google.com';'<Ctrl><Shift>minus'";
network_manager_sc="Network Manager Restart;gksudo service network-manager restart;'<Ctrl>R'";
# aggiungere le var che si vogliono attivare in quest'array
custom_kb_array=("$terminal" "$redshift" "$home_sc2" "$chrome_sc" "$ping_sc");

keybindings="org.gnome.desktop.wm.keybindings";
maximize="maximize;['<Super>Up']";
minimize="minimize;['<Super>Down']";
move_ne="move-to-corner-ne;['<Alt>Down']";
move_nw="move-to-corner-nw;['<Alt>Up']";
move_se="move-to-corner-se;['<Alt>Right']";
move_sw="move-to-corner-sw;['<Alt>Left']";
other_shortcut_array=("$maximize" "$minimize" "$move_ne" "$move_nw" "$move_se" "$move_sw");
echo "Vuoi impostare i keyboard shortcuts?";
read -n1 choise;
if [ "$choise" == "y" ]; then
	# The command str="$(printf "$str_esito" $browser_sc $browser_sc_val)"
	# is very similar to the backticks ``.
	# It's called command substitution (posix specification) and it invokes a
	# subshell. The command in the braces of $() or beween the backticks (``)
	# is executed in a subshell and the output is then placed in the original command.

	# elementi in org.gnome.settings-daemon.plugins.media-keys
	# NOTA: sintassi commento:
	#	: <<'COMMENT'
	#	qui c'è il commento
	#	COMMENT
	#	Il plugin dell'editor atom non riconosce questo come commento

	for el in "${shortcuts_array[@]}"; do
		# <<< --> It redirects the string to stdin of the command.
		read -ra tmp_array <<< $el;
		# flag -v: simile alla sprintf, stampa su una stringa
		printf -v str "$str_esito" ${tmp_array[0]} ${tmp_array[1]};
		$gs set $media_keys ${tmp_array[0]} ${tmp_array[1]};
		check_error "$str";
	done

	# costruzione valore della chiave in org.gnome.settings-daemon.plugins.media-keys custom-keybindings
	# NOTA: array[@] --> espande tutti gli elementi dell'array
	# 		# --> per contare il numero di elementi dell'array
	index=$(( ${#custom_kb_array[*]} - 1 ));
	last=${custom_kb_array[$index]};
	# NOTA: le virgolette sono NECESSARIE
	for el in "${custom_kb_array[@]}"; do
		read -ra tmp_array <<< $el;
		printf -v tmp "'%s'" $path_custom_sc${tmp_array[0]}"/";
		# se è l'ultimo elemento non inserire ", "
		if [[ $el == $last ]]; then
			custom_list+=$tmp;
		else
			custom_list+=$tmp", ";
		fi
	done
	# inizializzazione valore della chiave custom-keybindings
	printf -v custom_list "[%s]" "$custom_list";
	#$gs set $media_keys $custom_kb"s" "$custom_list";
	check_error "Impostazione chiave per abilitare una custom-list";

	# inizializzazione valore sottochiavi custom
	for el in "${custom_kb_array[@]}"; do
		read -ra tmp_array <<< $el;
		# set name
		printf -v str "$str_esito" ${tmp_array[0]} ${tmp_array[0]};
		$gs set "$media_keys.$custom_kb:$path_custom_sc${tmp_array[0]}/" name "${tmp_array[0]}";
		check_error "$str";
		# set command
		printf -v str "$str_esito" ${tmp_array[0]} ${tmp_array[1]};
		$gs set "$media_keys.$custom_kb:$path_custom_sc${tmp_array[0]}/" command "${tmp_array[1]}";
		check_error "$str";
		# set key binding
		printf -v str "$str_esito" ${tmp_array[0]} ${tmp_array[2]};
		$gs set "$media_keys.$custom_kb:$path_custom_sc${tmp_array[0]}/" binding "${tmp_array[2]}";
		check_error "$str";
	done

	for el in "${other_shortcut_array[@]}"; do
		read -ra tmp_array <<< $el;
		printf -v str "$str_esito" ${tmp_array[0]} ${tmp_array[1]};
		$gs set $keybindings ${tmp_array[0]} ${tmp_array[1]};
		check_error "$str";
	done
else
	printf "${DG}${U}Keyboard shortcuts non impostati${NC}\n";
fi



mod_="configurazione shortcuts";
echo --$mod_end $mod_;

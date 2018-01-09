#!/bin/bash
# ============================================================================

# Titolo:           kb_shortcut_conf.sh
# Descrizione:      Impostazione keyboard shortcuts
# Autore:           Alfredo Milani  (alfredo.milani.94@gmail.com)
# Data:             mar 25 lug 2017, 16.56.52, CEST
# Licenza:          MIT License
# Versione:         1.5.0
# Note:             --/--
# Versione bash:    4.4.12(1)-release
# ============================================================================



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
##############################
##### Modifica shortcuts #####
##############################
mod_="configurazione shortcuts";
printf "\n${Y}++${NC}$mod_start $mod_\n";
str_end="${Y}--${NC}$mod_end $mod_\n";
father_file=$2;



gs="gsettings";
str_esito="Configurazione entry: key - [%s] | value - [%s]\n";
str_esito2="Configurazione entry: key - [%s] | action - [%s] | value - [%s]\n";
media_keys="org.gnome.settings-daemon.plugins.media-keys";
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
redshift="RedShift;$script_path/redshift_regolator.sh;'<Ctrl><Shift>F'";
home_sc="Home;nautilus;'<Ctrl>N'";
home_sc2="Home 2;nautilus;'<Ctrl>M'";
chrome_sc="Google Chrome;google-chrome --disk-cache-dir='/dev/shm';'<Ctrl>G'";
ping_sc="Ping;gnome-terminal -e 'ping google.com';'<Ctrl><Shift>minus'";
network_manager_sc="Network Manager Restart;$script_path/check_psw.sh service network-manager restart;'<Ctrl><Shift>R'";
disable_threads="Disable Threads;$script_path/check_psw.sh $script_path/manage_threads.sh /;'<Ctrl><Shift>D'";
enable_threads="Enable Threads;$script_path/check_psw.sh $script_path/manage_threads.sh °°;'<Ctrl><Shift>E'";
system_monitor="System Monitor;gnome-system-monitor;'<Ctrl><Shift>M'";
gpu_monitor="GPU Monitor;gpui;'<Ctrl><Shift>I'";
# aggiungere le var che si vogliono attivare in quest'array
custom_kb_array=("$terminal" "$redshift" "$home_sc2" "$chrome_sc" "$ping_sc" "$system_monitor");

keybindings="org.gnome.desktop.wm.keybindings";
maximize="maximize;['<Super>Up']";
minimize="minimize;['<Super>Down']";
move_ne="move-to-corner-ne;['<Alt>Down']";
move_nw="move-to-corner-nw;['<Alt>Up']";
move_se="move-to-corner-se;['<Alt>Right']";
move_sw="move-to-corner-sw;['<Alt>Left']";
other_shortcut_array=("$maximize" "$minimize" "$move_ne" "$move_nw" "$move_se" "$move_sw");
printf "Vuoi impostare i keyboard shortcuts?\n$choise_opt";
read choise;
if [ "$choise" == "y" ] && check_mount $UUID_backup; then
    # modo alternativo per esprimere uno if statement...
    # il comando "[]" server per valutare espressioni
    ! [ -d "$script_path" ] && sudo mkdir $script_path;
    # redirezione verso /dev/null per evitare che il warning dovuto alla presenza di una directory
    # copia di tutti gli scripts
    sudo cp $mount_point/$tree_dir/$scripts_backup/* $script_path 2> $null;
    # creazione link simbolici in /usr/bin
    sudo ln -s $script_path/* /usr/bin;

    # The command str="$(printf "$str_esito" $browser_sc $browser_sc_val)"
    # is very similar to the backticks ``.
    # It's called command substitution (posix specification) and it invokes a
    # subshell. The command in the bracnes of $() or beween the backticks (``)
    # is executed in a subshell and the output is then placed in the original command.

    # elementi in org.gnome.settings-daemon.plugins.media-keys
    for el in "${shortcuts_array[@]}"; do
        # The characters in the value of the IFS variable are used to split the input line into words or tokens
        # <<< --> It redirects the string to stdin of the command.
        IFS=';' read -ra tmp_array <<< $el;
        # flag -v: simile alla sprintf, stampa su una stringa
        printf -v str "$str_esito" "${tmp_array[0]}" "${tmp_array[1]}";
        $gs set "$media_keys" "${tmp_array[0]}" "${tmp_array[1]}";
        check_error "$str";
    done

    # costruzione valore della chiave in org.gnome.settings-daemon.plugins.media-keys custom-keybindings
    # NOTA: array[@] --> espande tutti gli elementi dell'array
    #       # --> per contare il numero di elementi dell'array
    index=$(( ${#custom_kb_array[*]} - 1 ));
    last=${custom_kb_array[$index]};
    # NOTA: le virgolette sono NECESSARIE
    for el in "${custom_kb_array[@]}"; do
        IFS=';' read -ra tmp_array <<< $el;

        # eliminazione spazi
        tmp=`echo "${tmp_array[0]}" | tr " " "-"`;
        printf -v tmp "'%s'" "$path_custom_sc$tmp/";
        # se è l'ultimo elemento non inserire ", "
        if [ "$el" == "$last" ]; then
            custom_list+="$tmp";
        else
            custom_list+="$tmp, ";
        fi
    done
    # inizializzazione valore della chiave custom-keybindings
    printf -v custom_list "[%s]" "$custom_list";
    $gs set "$media_keys" $custom_kb"s" "$custom_list";
    check_error "Impostazione chiave per abilitare una custom-list";

    # inizializzazione valore sottochiavi custom
    for el in "${custom_kb_array[@]}"; do
        IFS=';' read -ra tmp_array <<< $el;

        # eliminazione spazi
        tmp=`echo "${tmp_array[0]}" | tr " " "-"`;
        tmp_array[0]="$tmp";

        # set name
        printf -v str "$str_esito2" "${tmp_array[0]}" "set name" "${tmp_array[0]}";
        $gs set "$media_keys.$custom_kb:$path_custom_sc${tmp_array[0]}/" name "${tmp_array[0]}";
        check_error "$str";

        # set command
        printf -v str "$str_esito2" "${tmp_array[0]}" "set command" "${tmp_array[1]}";
        $gs set "$media_keys.$custom_kb:$path_custom_sc${tmp_array[0]}/" command "${tmp_array[1]}";
        check_error "$str";

        # set key binding
        printf -v str "$str_esito2" "${tmp_array[0]}" "set binding" "${tmp_array[2]}";
        $gs set "$media_keys.$custom_kb:$path_custom_sc${tmp_array[0]}/" binding "${tmp_array[2]}";
        check_error "$str";
    done

    for el in "${other_shortcut_array[@]}"; do
        IFS=';' read -ra tmp_array <<< $el;

        printf -v str "$str_esito" "${tmp_array[0]}" "${tmp_array[1]}";
        $gs set "$keybindings" "${tmp_array[0]}" "${tmp_array[1]}";
        check_error "$str";
    done

    # riavvio richiesto
    reboot_req "$father_file";
else
    printf "${DG}${U}Keyboard shortcuts non impostati${NC}\n";
fi



restore_tmp_file $1 $2;
printf "$str_end";
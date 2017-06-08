#!/bin/bash

# Configurazione sistema

##### TODO --> SCRIVI NOTE NEL FILE BASH


# path temporaneo su RAM
export _dev_shm_="/dev/shm/";
export null="/dev/null";
# nome root script
export current_script_name="`basename "$0"`";
export mod_start="Avvio modulo";
export mod_end="Fine modulo";
export mount_point;
export cmd="sudo /bin/su -c";
export UUID_backup="A6B0EE5DB0EE3409";
export UUID_data="08AB0FD608AB0FD6";

# colori utilizzati
export R='\033[0;31m'; # red
export Y='\033[1;33m'; # yellow
export G='\033[0;32m'; # green
export DG='\033[1;30m'; # dark gray
export U='\033[4m'; # underlined
export NC='\033[0m'; # No Color
# stringhe per la funzione check_error
export check_error_str="Azione: %s\tEsito: %s\n";
export success="Positivo";
export failure="Negativo";
# line di comando con cui è stato lanciato lo script
export cmd_line1="`cat /proc/$$/cmdline | cut -c 1-2`";
export cmd_line2="`cat /proc/$$/cmdline | cut -c 6-7`";



#################################
##### Controllo preliminare #####
# non mi è possibile usare la funzione check_tool perchè è possibile che si stia utilizzando
# una shell sh che ha una sintassi diversa per la dichiarazione di funzioni
for tool in "basename" "realpath"; do
    # la shell sh non conosce il comando &>
    which $tool 1> $null;
    if [ $? != 0 ]; then
        printf "${R}Tool $el necessario per l'esecuzione di questo script\n${NC}";
		exit 1;
    fi
done

# $$ --> indica il pid del processo corrente
# il file /proc/pid/cmdline contiene la riga di comando con la quale è stato lanciato il processo identificato da pid.
# cut -c 1-4 restituisce i primi 4 caratteri della stringa presa in input
# la linea di comando dello script può essere: /bin/bash; bash; ./
# il seguente script deve essere eseguito da una shell bash perchè alcuni tool sono implementati diversamente il altre shell
shell_to_not_use="sh";
if [ "$cmd_line1" = "$shell_to_not_use" ] || [ "$cmd_line2" = "$shell_to_not_use" ]; then
	printf "${R}Lo script $current_script_name deve essere eseguito da una shell bash e NON sh${NC}\n"
	exit 1;
fi
##### Fine controllo preliminare #####
######################################



# funzione che verifica se il device il cui UUID è ricevuto in input è montato
# e restituisce il punto di mount nella variabile globale mount_point COMUNE A TUTTI MODULI
# grep -w restituisce output sse la stringa ha un matching completo
function check_mount {
    # operatore var=($"str1 str2 strn") crea un array con le stringhe che sono separate da uno spazio
    # oppure si poteva usare il comando awk --> var=`lsblk -o UUID,MOUNTPOINT | grep -w "$1"| awk '{if (NF == 2) print $2;}'`
    UUID_dev=($`lsblk -o UUID,MOUNTPOINT | grep -w "$1"`);
    mount_point=${UUID_dev[1]};
    if [ "$mount_point" == "" ]; then
        printf "${R}Per questa operazione è necesario che il device $1 sia montato.\n${NC}";
        lsblk -o UUID,MOUNTPOINT;
        exit 1;
    fi
}

# funzione per verificare l'esistenza di tutti i tools necessari nel sistema
# return code 127 indica che il comando digitato è sconosciuto
function check_tool {
	for tool in $@; do
        delimiter='_';
        tmp=`cut -d$delimiter -f1 <<< $tool`;
        if [ "$tmp" == "sudo" ]; then
            sudo_tool=`cut -d$delimiter -f2 <<< $tool`
            sudo which $sudo_tool &> $null;
        else
            which $tool &> $null;
        fi

    	if [ $? != 0 ]; then
    		printf "${R}Tool '%s' necessario per l'esecuzione di questo script\n${NC}" "$tool";
    		exit 1;
    	fi
    done
}

# "$@" --> expands to multiple words without performing expansions for the words (like "$1" "$2" ...).
# "$*" --> joins positional parameters with the first character in IFS (or space if IFS is unset or nothing if IFS is empty).
# funzione per verificare l'esito di una azione
function check_error {
	if [ $? == 0 ]; then
		printf "${G}$check_error_str${NC}" "$@" $success;
	else
		printf "${R}***$check_error_str${NC}" "$@" $failure;
	fi
}

##### controllo connessione
function get_header {
	host_to_check="google.com";
	# -q --> cut output
	# --spider --> get only header
	wget -q --spider $host_to_check;
}
function check_connection {
	# una funzione (o comando) risulta verificata se rotorna il codice 0 --> non ha riscontrato problemi
	# mentre get_header ritorna una valore maggiore di 0 ()--> mentre wget riscontra errori) chiedi all'utente come procedere
	while ! get_header; do
		printf "${Y}Connessione assente. Premi 'j' per saltare questa parte oppure premi qualsiasi tasto per ritestare la connessione.${NC}\n";
		read -n1 choise;
		if [ $choise == "j" ]; then
			return 1;
		fi
	done

	printf "${G}Connessione internet presente${NC}\n";
}

export -f check_mount;
export -f check_tool;
export -f check_error;
export -f get_header;
export -f check_connection;



# la shell sh non riconosce la sintassi ${string::-n}
# path assoluto script corrente
absolute_current_script_path=`realpath $0`;
# l'operatore unario # restituisce la lunghezza della scringa/array
lenght=${#current_script_name};
# sintassi: ${string::-n} --> taglia gli ultimi (-n) n elementi di string
absolute_script_path=${absolute_current_script_path::-$lenght};
# -gt --> greater than
# il comando shift n sposta il parametro posizionale di n posti (default n = 1)
# si possono usare pattern del tipo: -h|--help) per selezione multipla
# i pattern del tipo --action* : The * (wildcard) is for the case where
#   someone types --action=[ACTION] as well as the case where someone types
#   --action [ACTION]
# si usa l'operatore [xX] per avere scelte multiple
while [ $# -gt 0 ]; do
    case "$1" in
        --all | --ALL )
            for script in $absolute_script_path/*; do
                tmp_script=`basename $script`;
                ext=".sh"; ext_lenght=${#ext}; lenght_tmp_script=${#script};
                lenght=$(($lenght_tmp_script - $ext_lenght));
                # l'estensione di $script deve essere .sh
                # per effettuare operazioni aritmetiche si usa l'espressione: var3=$(($var1 + $var2));
                tmp_ext=`echo $script | cut -c $(($lenght + 1))-$lenght_tmp_script`;
                if [ "$tmp_ext" == "$ext" ] && [ "$current_script_name" != "$tmp_script" ]; then
                    $script;
                fi
            done
            break
            ;;

        -[aA] )
            # configurazione aspetto
            $absolute_script_path"/appearance_conf.sh";
            shift
            ;;

        -[bB] )
            # configurazione del file .bashrc
            $absolute_script_path"/bashrc_conf.sh";
            shift
            ;;

        -[fF] )
            # configurazione file /etc/fstab
            $absolute_script_path"/fstab_conf.sh";
            shift
            ;;

        -[hH] | -help | -HELP | --[hH] | --help | --HELP )
            echo "$current_script_name -options";
            echo "";
            echo -e "\t--all | --ALL )\t\tConfigurazione completa del sistema";
            echo -e "\t-a | -A )\t\tConfigurazione di tema ed icone";
            echo -e "\t-b | -B )\t\tConfigurazione del file .bashrc";
            echo -e "\t-f | -F )\t\tConfigurazione del file /etc/fstab";
            echo -e "\t-j | -J )\t\tConfigurazione del JDK Oracle";
            echo -e "\t-l | -L )\t\tCreazione link simbolici";
            echo -e "\t-n | -N )\t\tConfigurazione di rete";
            echo -e "\t-r | -R )\t\tConfigurazione dei repository";
            echo -e "\t-s | -S )\t\tConfigurazione dei keyboard shortcuts";
            echo -e "\t-tcp | -TCP )\t\tConfigurazione impostazioni protocollo TCP";
            echo -e "\t-tr | -TR )\t\tDisabilitazione tracker-* tools";
            echo -e "\t-u | -U )\t\tAggiornamento tools del sistema";
            exit 0
            ;;

        -[jJ] )
            # configurazione JDK Oracle
            $absolute_script_path"/jdk_conf.sh";
            shift
            ;;

        -[lL] )
            # configurazione link simbolici
            $absolute_script_path"/symbolic_link_conf.sh";
            shift
            ;;

        -[nN] )
            # configurazione di rete
            $absolute_script_path"/network_conf.sh";
            shift
            ;;

        -[rR] )
            # configurazione repository
            $absolute_script_path"/repo_conf.sh";
            shift
            ;;

        -[sS] )
            # configurazione keyboard shortcuts
            $absolute_script_path"/kb_shortcut_conf.sh";
            shift
            ;;

        -tcp | -TCP )
            # configurazione impostazioni protocollo TCP
            $absolute_script_path"/tcp_conf.sh";
            shift
            ;;

        -tr | -TR )
            # disabilitazione tracker-*
            $absolute_script_path"/tracker_disable_conf.sh";
            shift
            ;;

        -[uU] )
            # aggiornamento tools sistema
            $absolute_script_path"/tools_upgrade_conf.sh";
            shift
            ;;

        * )
            printf "${R}Comando $1 non risconosciuto\n${NC}";
            echo "Usa il flag -h per ottenere più informazioni";
            shift
            ;;
    esac
done

##### Mancanti
printf "${Y}\n\nTODO: \nInstallare software in /opt;\n\nRiavvia il PC per rendere effettive le modifiche${NC}\n";

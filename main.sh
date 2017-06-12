#!/bin/bash

# Configurazione sistema

##### TODO --> SCRIVI NOTE NEL FILE BASH

##### ##################################
##### Inizio controllo preliminare #####
# $$ --> indica il pid del processo corrente
# il file /proc/pid/cmdline contiene la riga di comando con la quale è stato lanciato il processo identificato da pid.
# cut -c 1-4 restituisce i primi 4 caratteri della stringa presa in input
line_acc1="bash"; line_acc2="/bin/bash";
# la shell sh non riconosce la sintassi ${string::-n}
# sostituzione del carattere terminatore di stringa '\0' per evitare
# il warning: "command substitution: ignored null byte in input"
cmd_line=`cat /proc/$$/cmdline | tr '\0' ' '`;
# verifica che tra i primi caratteri della riga di comando c'è la stringa "bash"
cmd_acc=`echo $cmd_line | cut -c 1-${#line_acc1}`;
if [ "$line_acc1" != "$cmd_acc" ]; then
    cmd_acc=`echo $cmd_line | cut -c 1-${#line_acc2}`;
    if [ "$line_acc2" != "$cmd_acc" ]; then
        echo "Lo script corrente deve essere eseguito da una shell bash e NON sh";
    	exit 1;
    fi
fi
##### Fine controllo preliminare #####
######################################



# variabili di sola lettura (declare -r)
# path temporaneo su RAM
declare -r _dev_shm_="/dev/shm/";
declare -r null="/dev/null";
declare -r mod_start="Avvio modulo";
declare -r mod_end="Fine modulo";
declare -r cmd="sudo /bin/su -c";
# colori utilizzati
declare -r R='\033[0;31m'; # red
declare -r Y='\033[1;33m'; # yellow
declare -r G='\033[0;32m'; # green
declare -r DG='\033[1;30m'; # dark gray
declare -r U='\033[4m'; # underlined
declare -r NC='\033[0m'; # No Color
# stringhe per la funzione check_error
declare -r check_error_str="Azione: %s\tEsito: %s\n";
declare -r success="Positivo";
declare -r failure="Negativo";

export _dev_shm_ null;
export mod_start mod_end;
export cmd;
export R Y G DG U NC;
export check_error_str success failure;




# leggi i valori dal file di configurazione e inizializza gli arrays keys e values
function fill_arrays {
    if ! [ -f $conf_file ]; then
        printf "${R}Devi specificare un file di configurazione valido.\nIl file $conf_file non è stato trovato.\n${NC}";
        exit 1;
    fi

    # redirigo il file di configurazione all'input della funzione read
    IFS='=';
    while read -r key value; do
        keys+=("$key");
        values+=("$value");
    done < $conf_file;
}

# restituisce il valore corrispondente alla chiave in input
# restituisce 0 in caso di errore
# restituisce n > 0 che corrisponde al valore i + 1
function get_value {
    if [ $# == 0 ]; then
        printf "${R}Errore nella funzione ${FUNCNAME[0]}. Nessun argomento ricevuto\n${NC}";
        # la shell bash ritornerà un valore tra 0 e 255 --> -2 -> 254
        return -2;
    fi

    # se trovo un matching ritorno il valore dell'indice
    for ((i = 0; i < ${#keys[@]}; ++i)); do
        [ "${keys[$i]}" == "$1" ] && return $i;
    done

    # la shell bash ritornerà un valore tra 0 e 255 --> -1 -> 255
    return -1;
}

# funzione che verifica se il device il cui UUID è ricevuto in input è montato
# e restituisce il punto di mount nella variabile globale mount_point COMUNE A TUTTI MODULI
# grep -w restituisce output sse la stringa ha un matching completo
function check_mount {
    # oppure si poteva usare il comando awk --> var=`lsblk -o UUID,MOUNTPOINT | grep -w "$1" | awk '{if (NF == 2) print $2;}'`
    # oppure UUID_dev=(`lsblk -o UUID,MOUNTPOINT | grep -w "$1"`);
    IFS=' ' read -ra UUID_dev <<< `lsblk -o UUID,MOUNTPOINT | grep -w $1`;
    mount_point=${UUID_dev[1]};
    if [ ${#mount_point} == 0 ]; then
        echo "Montare il device UUID=$1?";
        read -n1 choise;
        if [ "$choise" == "y" ]; then
            mount_point=$_dev_shm_$1;
            echo "Montare il device in un punto particolare (default: $mount_point)?"
            read -n1 choise;
            if [ "$choise" == "y" ]; then
                echo "Digita il punto di mount";
                read mount_point;
                ! [ -d $mount_point ] && printf "${Y}Directory $mount_point non esistente. Utilizzo di quella di default\n${NC}";
            fi
            mkdir $mount_point;
            sudo mount UUID=$1 $mount_point;
        else
            printf "${R}Per questa operazione è necesario che il device $1 sia montato.\n${NC}";
            printf "${R}--${NC}$mod_end $mod_\n";
            exit 1;
        fi
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
            printf "${R}--${NC}$mod_end $mod_\n";
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
        return 0;
	else
		printf "${R}***$check_error_str${NC}" "$@" $failure;
        return 1;
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

function give_help {
    echo "$current_script_name -options";
    echo "";
    echo -e "\t--all | --ALL )\t\tConfigurazione completa del sistema";
    echo -e "\t-a | -A )\t\tConfigurazione di tema ed icone";
    echo -e "\t-b | -B )\t\tConfigurazione del file .bashrc";
    echo -e "\t-c | -C )\t\tIndirizzo file di configurazione sys.conf";
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
}

# flag -f per esportare le funzioni
export -f get_value;
export -f check_mount;
export -f check_tool;
export -f check_error;
export -f get_header;
export -f check_connection;



check_tool "basename" "realpath";

export mount_point;
# nome root script
export current_script_name=`basename "$0"`;
# path assoluto script corrente
absolute_current_script_path=`realpath $0`;
# l'operatore unario # restituisce la lunghezza della scringa/array
lenght=${#current_script_name};
# sintassi: ${string::-n} --> taglia gli ultimi (-n) n elementi di string
absolute_script_path=${absolute_current_script_path::-$lenght};
# chiavi/valori dal file di configurazione
# NOTA: gli array non possono essere esportati
keys=();
values=();
# contiene i moduli invocati dall'utente
scripts_array=();
# codice di avvio per scripts
start_script_code=16;
# file di default contenuto nella stessa directory dello script corrente
conf_file=$absolute_script_path"sys.conf";
export mod_="preliminare";
export tree_dir;
export UUID_backup;
export UUID_data;
export script_path;
export software;
export themes_backup;
export icons_backup;
export driver_backup;
export scripts_backup;



# controllo se l'utente non ha specificato il modulo da avviare
if [ $# == 0 ]; then
    printf "${U}Utilizza il flag -h per conoscere le operazioni disponibili\n${NC}";
    exit 0;
fi

# controllo se l'utente ha inserito il flag -h
for arg in $@; do
    if [ "$arg" == "-h" ] ||
        [ "$arg" == "-H" ] ||
        [ "$arg" == "-help" ] ||
        [ "$arg" == "-HELP" ] ||
        [ "$arg" == "--h" ] ||
        [ "$arg" == "--H" ] ||
        [ "$arg" == "--help" ] ||
        [ "$arg" == "--HELP" ]; then
            give_help;
    fi
done

# -gt --> greater than
# il comando shift;; n sposta il parametro posizionale di n posti (default n = 1)
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
                    scripts_array+=("$script");
                fi
            done
            break;
            ;;

        -[aA] )
            # configurazione aspetto
            scripts_array+=("$absolute_script_path/appearance_conf.sh");
            shift;
            ;;

        -[bB] )
            # configurazione del file .bashrc
            scripts_array+=("$absolute_script_path/bashrc_conf.sh");
            shift;
            ;;

        -[cC] )
            shift;
            # path file di configurazione
            if [ ${#1} != 0 ] && [ -f $1 ]; then
                conf_file=$1;
            else
                printf "${Y}File specificato ($arg) non trovato. Verrà usato il file di default ($conf_file).\n${NC}";
            fi
            shift;
            ;;

        -[fF] )
            # configurazione file /etc/fstab
            scripts_array+=("$absolute_script_path/fstab_conf.sh");
            shift;
            ;;

        -[hH] | -help | -HELP | --[hH] | --help | --HELP )
            # verificato in precedenza
            give_help;
            ;;

        -jdk | -JDK )
            # configurazione JDK Oracle
            scripts_array+=("$absolute_script_path/jdk_conf.sh");
            shift;
            ;;

        -[lL] )
            # configurazione link simbolici
            scripts_array+=("$absolute_script_path/symbolic_link_conf.sh");
            shift;
            ;;

        -[nN] )
            # configurazione di rete
            scripts_array+=("$absolute_script_path/network_conf.sh");
            shift;
            ;;

        -[rR] )
            # configurazione repository
            scripts_array+=("$absolute_script_path/repo_conf.sh");
            shift;
            ;;

        -[sS] )
            # configurazione keyboard shortcuts
            scripts_array+=("$absolute_script_path/kb_shortcut_conf.sh");
            shift;
            ;;

        -tcp | -TCP )
            # configurazione impostazioni protocollo TCP
            scripts_array+=("$absolute_script_path/tcp_conf.sh");
            shift;
            ;;

        -tr | -TR )
            # disabilitazione tracker-*
            scripts_array+=("$absolute_script_path/tracker_disable_conf.sh");
            shift;
            ;;

        -[uU] )
            # aggiornamento tools sistema
            scripts_array+=("$absolute_script_path/tools_upgrade_conf.sh");
            shift;
            ;;

        * )
            printf "${R}Comando $1 non risconosciuto\n${NC}";
            echo "Usa il flag -h per ottenere più informazioni";
            shift;
            ;;
    esac
done



# ottenimento valori delle chiavi
fill_arrays;

get_value tree_dir; tree_dir=${values[$?]};
get_value UUID_backup; UUID_backup=${values[$?]};
get_value UUID_data; UUID_data=${values[$?]};
get_value script_path; script_path=${values[$?]};
get_value software; software=${values[$?]};
get_value themes_backup; themes_backup=${values[$?]};
get_value icons_backup; icons_backup=${values[$?]};
get_value driver_backup; driver_backup=${values[$?]};
get_value scripts_backup; scripts_backup=${values[$?]};

# avvio moduli selezionati dall'utente
for script in "${scripts_array[@]}"; do
    $script $start_script_code;
done

##### Mancanti
printf "${Y}\n\nTODO: \nInstallare software in /opt;\n\nRiavvia il PC per rendere effettive le modifiche${NC}\n";

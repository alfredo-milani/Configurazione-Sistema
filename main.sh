#!/bin/bash

# Configurazione sistema Debian based.
# Testato su Linux debian 4.9.0-3-amd64 #1 SMP x86_64 GNU/Linux.
#
# Autore: Alfredo Milani
# Data: 10 - 06 - 2017
#
# (script in utils/gnomeshell_extension_manage.sh di N. Bernaerts)



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
# verifica se tra i primi caratteri della riga di comando c'è la stringa "bash"
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
declare -r cmd="sudo /bin/su -c";
declare -r null="/dev/null";
declare -r mod_start="Avvio modulo";
declare -r mod_end="Fine modulo";
declare -r choise_opt="[y=procedi / others=annulla]\t";
declare -r choise_opt_net="[j=riprova più tardi / others=riprova ora]\t";
# colori utilizzati
declare -r R='\033[0;31m'; # red
declare -r Y='\033[1;33m'; # yellow
declare -r G='\033[0;32m'; # green
declare -r DG='\033[1;30m'; # dark gray
declare -r U='\033[4m'; # underlined
declare -r NC='\033[0m'; # No Color
# stringhe per la funzione check_error
declare -r check_error_str="Azione: %s\tEsito: %s\n";
declare -r missing_val="Valore non definito per la chiave: %s.\nModifica il file %s con le informazioni mancanti.\n";
declare -r success="Positivo";
declare -r failure="Negativo";
declare -r EXIT_SUCCESS=0;
declare -r EXIT_FAILURE=1;
declare _dev_shm_="/dev/shm";

export null _dev_shm_ cmd;
export mod_start mod_end;
export choise_opt choise_opt_net;
export R Y G DG U NC;
export check_error_str missing_val success failure;
export EXIT_SUCCESS EXIT_FAILURE;



# leggi i valori dal file di configurazione e inizializza gli arrays keys e values
function fill_arrays {
    if ! [ -f "$conf_file" ]; then
        printf "${R}Devi specificare un file di configurazione valido.\nIl file $conf_file non è stato trovato.\n${NC}";
        return $EXIT_FAILURE;
    fi

    # tmp=`cut -d'.' -f2 <<< $conf_file`;
    # accesso agli ultimi 4 caratteri del nome del file
    tmp=${conf_file:(-4)};
    [ "$tmp" != "conf" ] && [ $warnings == 0 ] &&
    printf "${Y}Attenzione: formato del file --> $conf_file <-- insolito\n${NC}";

: <<'COMMENTO'
    sed -e 's/[[:space:]]*#.*// ; /^[[:space:]]*$/d' "$conf_file" |
    while IFS='=' read -r key value; do
        echo "K: $key      V: $value";
        # le variabili NON vengono assegnate agli arrays
        keys+=("$key");
        values+=("$value");
    done
COMMENTO

    # esportazione di tutte le variabili comuni a tutti i moduli
    for var in ${var_array[@]}; do
        export $var;
    done

    # workaround
    # eliminazione commenti all'inizio riga ed inline prima di parsare i dati
    file_to_parse=`mktemp -p $_dev_shm_`;
    # nota: la d finale serve per cancellare gli spazi bianchi
    #   le chiavi preceduta da spazi bianchi non saranno considerate
    sed -e 's/[[:space:]]*#.*// ; /^[[:space:]]*$/d' "$conf_file" >> $file_to_parse;
    while IFS='=' read -r key value; do
        case "$key" in
            tree_dir )          tree_dir=$value ;;
            UUID_backup )       UUID_backup=$value ;;
            UUID_data )         UUID_data=$value ;;
            script_path )       script_path=$value ;;
            software )          software=$value ;;
            themes_backup )     themes_backup=$value ;;
            theme_scelto )      theme_scelto=$value ;;
            icons_backup )      icons_backup=$value ;;
            icon_scelto )       icon_scelto=$value ;;
            driver_backup )     driver_backup=$value ;;
            scripts_backup )    scripts_backup=$value ;;
            extensions_id )     extensions_id=$value ;;
            sdk )               sdk=$value ;;
            tmp )
                                tmp_dev_shm_=$value;
                                if [ ${#tmp_dev_shm_} == 0 ] || ! [ -d "$tmp_dev_shm_" ]; then
                                    printf "${R}Errore, il path $tmp_dev_shm_ non esiste o non è una directory valida.\nUtilizzo di quella di default ($_dev_shm_).\n${NC}";
                                else
                                    _dev_shm_=$tmp_dev_shm_;
                                fi
                                ;;
        esac
    done < $file_to_parse;

    rm -f $file_to_parse;

    # verifica sintattica varibili esportate
    if [ $warnings == 0 ]; then
        for var in ${var_array[@]}; do
            check_value $var;
        done
    fi

    return $EXIT_SUCCESS;
}

function check_value {
    # sintassi per ottenere il valore della variabile
    var_val=${!1};
    if [ ${#var_val} == 0 ]; then
        printf "${Y}Attenzione! Non è stato trovato alcun valore corretto per la chiave --> $1 <-- nel file di configurazione $conf_file\n${NC}";

        return $EXIT_FAILURE;
    fi

    return $EXIT_SUCCESS;
}

# funzione che verifica se il device il cui UUID è ricevuto in input è montato
# e restituisce il punto di mount nella variabile globale mount_point COMUNE A TUTTI MODULI
# grep -w restituisce output sse la stringa ha un matching completo
function check_mount {
    if [ $# == 0 ]; then
        printf "${R}Per questa operazione è necessario specificare un device valido nel file di configurazione\n${NC}";
        return $EXIT_FAILURE;
    fi
    # oppure si poteva usare il comando awk --> var=`lsblk -o UUID,MOUNTPOINT | grep -w "$1" | awk '{if (NF == 2) print $2;}'`
    # oppure UUID_dev=(`lsblk -o UUID,MOUNTPOINT | grep -w "$1"`);
    IFS=' ' read -ra UUID_dev <<< `lsblk -o UUID,MOUNTPOINT | grep -w $1`;
    mount_point=${UUID_dev[1]};
    if [ ${#mount_point} == 0 ]; then
        printf "Montare il device UUID=$1?\n$choise_opt";
        read choise;
        if [ "$choise" == "y" ]; then
            mount_point=$_dev_shm_/$1;
            printf "Montare il device in un punto particolare (default: $mount_point)?\n$choise_opt"
            read choise;
            if [ "$choise" == "y" ]; then
                printf "Digita il punto di mount:\t";
                read mount_point;
            fi
            sudo mkdir -p $mount_point;
            echo "Montaggio device UUID=$1 in $mount_point";

            sudo mount UUID=$1 $mount_point && return $EXIT_SUCCESS;
            printf "${R}Errore durante il montaggio del device $1. Verifica che l'UUID sia corretto\n${NC}" &&
            return $EXIT_FAILURE;
        fi

        printf "${R}Per questa operazione è necesario che il device $1 sia montato.\n${NC}";
        return $EXIT_FAILURE;
    fi

    return $EXIT_SUCCESS;
}

# funzione per verificare l'esistenza di tutti i tools necessari nel sistema
# return code 127 indica che il comando digitato è sconosciuto
function check_tool {
    for tool in $@; do
        delimiter='_';
        tmp=`cut -d$delimiter -f1 <<< $tool`;
        if [ "$tmp" == "sudo" ]; then
            sudo_tool=`cut -d$delimiter -f2 <<< $tool`
            echo "Checking tool --> $sudo_tool <-- nel sistema";
            sudo which $sudo_tool &> $null;
        else
            which $tool &> $null;
        fi

        [ $? != 0 ] &&
        printf "${R}Tool '%s' necessario per l'esecuzione di questo script\n${NC}" "$tool" &&
        return $EXIT_FAILURE;
    done

    return $EXIT_SUCCESS;
}

# "$@" --> expands to multiple words without performing expansions for the words (like "$1" "$2" ...).
# "$*" --> joins positional parameters with the first character in IFS (or space if IFS is unset or nothing if IFS is empty).
# funzione per verificare l'esito di una azione
function check_error {
	if [ $? == 0 ]; then
		printf "${G}$check_error_str${NC}" "$@" "$success";
        return $EXIT_SUCCESS;
	else
		printf "${R}***$check_error_str${NC}" "$@" "$failure";
        return $EXIT_FAILURE;
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
    echo "Controllo accesso ad Internet. Attendere...";
	while ! get_header; do
		printf "${Y}Connessione assente.\n$choise_opt_net${NC}\n";
		read choise;
		if [ "$choise" == "j" ]; then
			return $EXIT_FAILURE;
		fi
	done

	printf "${G}Connessione internet presente${NC}\n";
    return $EXIT_SUCCESS;
}

function give_help {
    echo "$current_script_name -options";
    echo "";
    echo -e "\t--all | --ALL )\t\tConfigurazione completa del sistema";
    echo -e "\t-a | -A )\t\tConfigurazione di tema ed icone";
    echo -e "\t-b | -B )\t\tConfigurazione del file .bashrc";
    echo -e "\t-c | -C )\t\tIndirizzo file di configurazione sys.conf";
    echo -e "\t-f | -F )\t\tConfigurazione del file /etc/fstab";
    echo -e "\t-gpu | -GPU\t\tConfigurazione bumblebee per gestione GPU NVIDIA";
    echo -e "\t-jdk | -JDK )\t\tConfigurazione della JDK Oracle";
    echo -e "\t-l | -L )\t\tCreazione link simbolici";
    echo -e "\t-m | -M )\t\tPer creare più istanze contemporaneamente";
    echo -e "\t-n | -N )\t\tConfigurazione di rete";
    echo -e "\t-s | -S )\t\tConfigurazione dei keyboard shortcuts";
    echo -e "\t-tr | -TR )\t\tDisabilitazione tracker-* tools";
    echo -e "\t-u | -U )\t\tAggiornamento tools del sistema";
    echo -e "\t--w | --W )\t\tDisabilitazione warnings";
    exit $EXIT_SUCCESS
}

function check_script {
    for script in ${scripts_array[@]}; do
        # script trovato in scripts_array
        [ "$script" == "$1" ] && return $EXIT_SUCCESS;
    done

    return $EXIT_FAILURE;
}

function print_missing_val {
    printf "${R}$missing_val${NC}" "$@" "$conf_file";
}

# per ripristinare il file temporaneo in caso di errori sconosciuti
function restore_tmp_file {
    ! [ -f "$2" ] && echo "$1" | md5sum > $_dev_shm_/`basename $2`;
}

# richiesta di reboot
function reboot_req {
    grep -r -w "reboot" "$1" &> $null ||
    echo "reboot" >> $1;
}

# on exit
function on_signal {
    rm -f $tmp_file &> $null;
    printf "${R}\nProcesso interrotto... Uscita.\n${NC}";
    exit $EXIT_FAILURE;
}

# flag -f per esportare le funzioni
export -f check_mount;
export -f check_tool;
export -f check_error;
export -f get_header;
export -f check_connection;
export -f print_missing_val;
export -f restore_tmp_file;
export -f reboot_req;



# creazione file tmp perevitare l'esecuzione dei singoli moduli
declare -r -i private_rand=$RANDOM;
# file temporaneo
declare -r tmp_file=`mktemp -p $_dev_shm_`;
# applica un algoritmo di hashing su un numero random e scrivilo su un file temporaneo
echo "$private_rand" | md5sum >> $tmp_file;

# intercetta SIGINT SIGKILL e SIGTERM
trap on_signal SIGINT SIGKILL SIGTERM SIGUSR1 SIGUSR2;
! check_tool "basename" "realpath" && exit $?;

export mount_point;
# nome root script
export current_script_name=`basename "$0"`;
# path assoluto script corrente
absolute_current_script_path=`realpath $0`;
# l'operatore unario # restituisce la lunghezza della scringa/array
lenght=${#current_script_name};
# sintassi: ${string::-n} --> taglia gli ultimi (-n) n elementi di string
export absolute_script_path=${absolute_current_script_path::-$lenght};
# contiene i moduli invocati dall'utente
scripts_array=();
# file di default contenuto nella stessa directory dello script corrente
conf_file=$absolute_script_path"sys.conf";
# apt-manager di default
apt_manager=apt-get;
# verifica rimozione files di autenticazione
tmp_code=1;
# flag per abilitare/disabilitare i warnings
declare -i warnings=0;

export mod_="preliminare";
export apt_manager;
export tree_dir;
export warnings conf_file;
# array contenete i nomi delle variabili da parsare contenute nel file di configurazione
var_array=(UUID_backup themes_backup icons_backup software script_path scripts_backup UUID_data driver_backup extensions_id sdk theme_scelto icon_scelto);



# controllo se l'utente non ha specificato il modulo da avviare
if [ $# == 0 ]; then
    printf "${U}Utilizza il flag -h per conoscere le operazioni disponibili\n${NC}";
    exit $EXIT_SUCCESS;
fi

# controllo se l'utente ha inserito il flag -h o se ha specificato l'opzione --all
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
    elif [ "$arg" == "--all" ] ||
        [ "$arg" == "--ALL" ]; then
            for script in $absolute_script_path*; do
                tmp_script=`basename $script`;
                ext=".sh"; ext_lenght=${#ext}; lenght_tmp_script=${#script};
                lenght=$(($lenght_tmp_script - $ext_lenght));
                # l'estensione di $script deve essere .sh
                # per effettuare operazioni aritmetiche si usa l'espressione: var3=$(($var1 + $var2));
                tmp_ext=`echo $script | cut -c $(($lenght + 1))-$lenght_tmp_script`;

                # aggiunta script corrente all array scripts_array
                [ "$tmp_ext" == "$ext" ] &&
                [ "$current_script_name" != "$tmp_script" ] &&
                scripts_array+=("$script");
            done
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
            shift;
            ;;

        -[aA] )
            shift;
            # configurazione aspetto
            current_script="appearance_conf.sh";
            ! check_script $absolute_script_path$current_script &&
            scripts_array+=($absolute_script_path$current_script);
            ;;

        -[bB] )
            shift;
            # configurazione del file .bashrc
            current_script="bashrc_conf.sh";
            ! check_script $absolute_script_path$current_script &&
            scripts_array+=($absolute_script_path$current_script);
            ;;

        -[cC] )
            shift;
            # path file di configurazione
            if [ ${#1} != 0 ] && [ -f "$1" ]; then
                realpath_conf=`realpath $1`;
                printf "${G}Utilizzo di --> $realpath_conf <-- come file di configurazione\n${NC}";
                conf_file=$1;
            else
                printf "${Y}File specificato dal flag -c / -C --> $1 <-- non trovato.\nSarà usato il file: $conf_file\n${NC}";
            fi
            shift;
            ;;

        -[fF] )
            shift;
            # configurazione file /etc/fstab
            current_script="fstab_conf.sh";
            ! check_script $absolute_script_path$current_script &&
            scripts_array+=($absolute_script_path$current_script);
            ;;

        -gpu | -GPU )
            shift;
            # configurazione bumblebee
            current_script="gpu_conf.sh";
            ! check_script $absolute_script_path$current_script &&
            scripts_array+=($absolute_script_path$current_script);
            ;;

        -jdk | -JDK )
            shift;
            # configurazione JDK Oracle
            current_script="jdk_conf.sh";
            ! check_script $absolute_script_path$current_script &&
            scripts_array+=($absolute_script_path$current_script);
            ;;

        -[lL] )
            shift;
            # configurazione link simbolici
            current_script="symbolic_link_conf.sh";
            ! check_script $absolute_script_path$current_script &&
            scripts_array+=($absolute_script_path$current_script);
            ;;

        -[mM] )
            shift;
            # tmp_code viene impostata ad 1 --> è possibile creare più istanze contemporaneamente dello script
            tmp_code=0;
            ;;

        -[nN] )
            shift;
            # configurazione di rete
            current_script="network_conf.sh";
            ! check_script $absolute_script_path$current_script &&
            scripts_array+=($absolute_script_path$current_script);
            ;;

        -[sS] )
            shift;
            # configurazione keyboard shortcuts
            current_script="kb_shortcut_conf.sh";
            ! check_script $absolute_script_path$current_script &&
            scripts_array+=($absolute_script_path$current_script);
            ;;

        -tr | -TR )
            shift;
            # disabilitazione tracker-*
            current_script="tracker_disable_conf.sh";
            ! check_script $absolute_script_path$current_script &&
            scripts_array+=($absolute_script_path$current_script);
            ;;

        -[uU] )
            shift;
            # aggiornamento tools sistema
            current_script="tools_upgrade_conf.sh";
            ! check_script $absolute_script_path$current_script &&
            scripts_array+=($absolute_script_path$current_script);
            ;;

        --[wW] )
            shift;
            # disabilitazine warnings
            warnings=1;
            ;;

        * )
            printf "${R}Comando $1 non risconosciuto\n${NC}";
            echo "Usa il flag -h per ottenere più informazioni";
            shift;
            ;;
    esac
done



[ ${#scripts_array[@]} == 0 ] &&
printf "${R}Specificare un'azione!\n${NC}" &&
give_help;

# lettura file di configurazione
! fill_arrays && exit $EXIT_FAILURE;

# avvio moduli selezionati dall'utente
for script in "${scripts_array[@]}"; do
    $script $private_rand $tmp_file $$;
done

if [ -f "$tmp_file" ]; then
    grep -r -w "reboot" "$tmp_file" &> $null &&
    printf "${Y}\n\nOccorre riavvia il PC per rendere effettive le modifiche.\n${NC}" &&
    printf "${Y}Riavviare ora?\n$choise_opt${NC}" &&
    read choise &&
    [ "$choise" == "y" ] && sudo reboot;
else
    printf "${R}Errore: file temporaneo ($tmp_file) non trovato.\n${NC}";
fi

# eliminazione codice per evitarne il riutilizzo
rm -f $tmp_file;
# successo
exit $EXIT_SUCCESS;

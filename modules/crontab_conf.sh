#!/bin/bash
# ============================================================================

# Titolo:           crontab_conf.sh
# Descrizione:      Configurazione job
# Autore:           Alfredo Milani (alfredo.milani.94@gmail.com)
# Data:             mer 20 set 2017, 17.39.07, CEST
# Licenza:          MIT License
# Versione:         1.1.0
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
##### Configurazione job #####
##############################
mod_="configurazione crontab";
printf "\n${Y}++${NC}$mod_start $mod_\n";
str_end="${Y}--${NC}$mod_end $mod_\n";
father_file=$2;



header_crontab="# Edit this file to introduce tasks to be run by cron.
#
# Each task to run has to be defined through a single line
# indicating with different fields when the task will be run
# and what command to run for the task
#
# To define the time you can provide concrete values for
# minute (m), hour (h), day of month (dom), month (mon),
# and day of week (dow) or use '*' in these fields (for 'any').#
# Notice that tasks will be started based on the cron's system
# daemon's notion of time and timezones.
#
# Output of the crontab jobs (including errors) is sent through
# email to the user the crontab file belongs to (unless redirected).
#
# For example, you can run a backup of all your user accounts
# at 5 a.m every week with:
# 0 5 * * 1 tar -zcf /var/backups/home.tgz /home/
#
# For more information see the manual pages of crontab(5) and cron(8)
#
# m h  dom mon dow   command";
printf "Aggiungere le definizioni di cron job?$choise_opt";
read choise;
if [ "$choise" == "y" ]; then
    crontabs_path="/var/spool/cron/crontabs";
    current_username=`whoami`;
    root_username=`sudo /bin/su -c "whoami"`;
    group="crontab";

    # Inizializzazione fle con header se non dovessro esistere già
    cd $_dev_shm_;
    _tmp_crontabs=`mktemp -d` && cd $_tmp_crontabs;
    ! [ -e "$crontabs_path/$current_username" ] && echo "$header_crontab" > $current_username;
    ! [ -e "$crontabs_path/$root_username" ] && echo "$header_crontab" > $root_username;

    # User job
    trash_dir=`xdg-user-dir DOWNLOAD`/shm/Trash;
    # Creazione cartella Trash nella directory di download all'avvio
    echo -e "\n\n\n# Creazione directory Trash in ~/Scaricati/shm con frequenza giornaliera\n@reboot\t! [ -e $trash_dir ] && mkdir $trash_dir;\n" >> $current_username;
    # Avvio del tool redshift per regolare l'emissione di blue ray
    ### TODO non ancora funzionante
    # echo -e "\n# Lancio del tool redshift per la correzione della temperatura dei colori dello schermo\nDISPLAY=:0.0;\n30 15 * * * redshift -l 41.6:13.4 -t 5000:3500;\n" >> $current_username;



    sudo cp $current_username $crontabs_path;
    # Cambio permessi/proprietario/gruppo
    sudo chown $current_username:$group $crontabs_path/$current_username;
    sudo chmod 600 $crontabs_path/$current_username;
    check_error "Configurazione dei proncipali jobs per l'utente: $current_username";

    # Root job
    # Per evitare di ricevere notifiche sui job in esecuzione
    echo -e "\n\n\n# To disable default behaviour's cron that send mail to user account about executing cronjob.\n* * * * * > $null 2>&1;\n" >> $root_username;

    sudo cp $root_username $crontabs_path;
    # Cambio permessi/proprietario/gruppo
    sudo chown $root_username:$group $crontabs_path/$root_username;
    sudo chmod 600 $crontabs_path/$root_username;
    check_error "Configurazione dei proncipali jobs per l'utente: $root_username";

    # Rimozione files temporanei
    rm -rf $_tmp_crontabs;
else
    printf "${DG}${U}Definizioni crontabs non aggiorante${NC}\n";
fi



restore_tmp_file $1 $2;
printf "$str_end";

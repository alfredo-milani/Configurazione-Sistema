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
##############################
##### Configurazione job #####
##############################
mod_="configurazione crontab"
printf "\n${Y}++${NC}$mod_start $mod_\n"
str_end="${Y}--${NC}$mod_end $mod_\n"
father_file=$2



printf "Aggiungere le definizioni di cron job?$choise_opt"
read choise
if [ "$choise" == "y" ]; then
    crontabs_path="/var/spool/cron/crontabs"
    current_username=`whoami`
    root_username=`sudo /bin/su -c "whoami"`
    group="crontab"

    # User job
    trash_dir=`xdg-user-dir DOWNLOAD`/shm/Trash
    sudo tee -a << EOF ${crontabs_path}/${current_username} 1> $null



# Creazione directory Trash in ~/Scaricati/shm con frequenza giornaliera
@reboot ! [ -e $trash_dir ] && mkdir $trash_dir
EOF
    check_error "Configurazione dei principali jobs per l'utente: $current_username"
    # Cambio permessi/proprietario/gruppo
    sudo chown $current_username:$group $crontabs_path/$current_username
    sudo chmod 600 $crontabs_path/$current_username

    # Root job
    sudo tee -a << EOF ${crontabs_path}/${root_username} 1> $null



# To disable default behaviour's cron that send mail to user account about executing cronjob
* * * * * > $null 2>&1
EOF
    check_error "Configurazione dei proncipali jobs per l'utente: $root_username"
    # Cambio permessi/proprietario/gruppo
    sudo chown $root_username:$group $crontabs_path/$root_username
    sudo chmod 600 $crontabs_path/$root_username
else
    printf "${DG}${U}Definizioni crontabs non aggiorante${NC}\n"
fi



restore_tmp_file $1 $2
printf "$str_end"

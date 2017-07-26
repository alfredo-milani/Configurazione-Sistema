#!/bin/bash
# ============================================================================

# Titolo:           jdk_conf.sh
# Descrizione:      Configurazione JDK Oracle
# Autore:           Alfredo Milani  (alfredo.milani.94@gmail.com)
# Data:             mar 25 lug 2017, 16.56.09, CEST
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
#####################################
##### Configurazione JDK Oracle #####
#####################################
mod_="configurazione JDK Oracle";
printf "\n${Y}++${NC}$mod_start $mod_\n";
str_end="${Y}--${NC}$mod_end $mod_\n";
father_file=$2;



# funzione per impostare il file /etc/profile
# NOTA: $0 --> script name
#		$1 --> primo param; $2 --> secondo param; ecc...
#		${FUNCNAME[0]} --> nome funzione chiamante;
#			FUNCNAME: An  array  variable  containing the names of all shell functions
# 			currently in the execution call stack.
function config_profile {
	if [ ${#1} == 0 ] || [ ${#2} == 0 ]; then
		printf "${R}Errore di sintassi nella funzione ${FUNCNAME[0]}\n${NC}";
	else
		f_path_jdk="$1";
		f_new_jdk="$2";
		file_profile="/etc/profile";

		echo "Impostazione di java e javaws come default di sistema";
		sudo update-alternatives --install "/usr/bin/java" "java" "$f_path_jdk$f_new_jdk/bin/java" 1;
		sudo update-alternatives --install "/usr/bin/javaws" "javaws" "$f_path_jdk$f_new_jdk/bin/javaws" 1;
		sudo update-alternatives --set java "$f_path_jdk$f_new_jdk/bin/java";
		sudo update-alternatives --set javaws "$f_path_jdk$f_new_jdk/bin/javaws";
		check_error "Impostazione JDK Oracle come default di sistema";

		echo "Impostazione variabili globali nel file $file_profile";
		sudo /bin/su -c "echo JAVA_HOME=$f_path_jdk$f_new_jdk >> $file_profile";
		sudo /bin/su -c "echo JRE_HOME=$f_path_jdk$f_new_jdk/jre >> $file_profile";
		sudo /bin/su -c "echo 'PATH=$PATH:$JAVA_HOME/bin:$JRE_HOME/bin' >> $file_profile";
		sudo /bin/su -c "echo 'export JAVA_HOME' >> $file_profile";
		sudo /bin/su -c "echo 'export JRE_HOME' >> $file_profile";
		sudo /bin/su -c "echo 'export PATH' >> $file_profile";
		check_error "Modifica file $file_profile";

		echo "Blocco aggiornamento OpenJDK";
		sudo apt-mark hold openjdk*
		check_error "Blocco aggiornamenti OpenJDK";
	fi

	# riavvio richiesto
	reboot_req "$father_file";
}

# Impostazione JDK Oracle come default di sistema
printf "Impostare JDK Oracole java come default di sistema?\n$choise_opt";
read choise;
if [ "$choise" == "y" ]; then
	path_jdk=/opt/;
	cd $path_jdk;
	new_jdk=`ls | grep jdk`;
	if [ ${#new_jdk} == 0 ]; then
		printf "${Y}Nessuna cartella jdk trovata in $path_jdk\n${NC}";
		check_mount $UUID_backup
		path_backup_jdk=$mount_point/$software;
		backup_jdk=`ls $path_backup_jdk | grep jdk`;
		if [ ${#backup_jdk} != 0 ]; then
			printf "Vuoi utilizzare la JDK $path_backup_jdk/$backup_jdk?\n$choise_opt";
			read choise;
			if [ "$choise" == "y" ]; then
				sudo tar -xvf $path_backup_jdk/$backup_jdk -C $path_jdk &> $null;
				check_error "Estrazione di $backup_jdk in $path_jdk";
				backup_jdk=`ls $path_jdk | grep jdk`;
				config_profile $path_jdk $backup_jdk;
			else
				printf "${DG}${U}JDK di backup non installata\n${NC}";
			fi
		else
			printf "${R}Errore: JDK di backup non trovata in $path_backup_jdk\n${NC}";
		fi
	else
		config_profile $path_jdk $new_jdk;
	fi
else
	printf "${DG}${U}JDK Oracle non impostato come default\n${NC}";
fi



restore_tmp_file $1 $2;
printf "$str_end";

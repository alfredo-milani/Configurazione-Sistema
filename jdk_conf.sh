#!/bin/bash

#####################################
##### Configurazione JDK Oracle #####
#####################################
mod_="configurazione JDK Oracle";
printf "\n${Y}++${NC}$mod_start $mod_\n";



# funzione per impostare il file /etc/profile
# NOTA: $0 --> script name
#		$1 --> primo param; $2 --> secondo param; ecc...
#		${FUNCNAME[0]} --> nome funzione chiamante;
#			FUNCNAME: An  array  variable  containing the names of all shell functions
# 			currently in the execution call stack.
function config_profile() {
	if [ "$1" == "" ] || [ "$2" == "" ]; then
		printf "${R}Errore di sintassi nella funzione ${FUNCNAME[0]}\n${NC}";
	else
		f_path_jdk="$1";
		f_new_jdk="$2";
		file_profile="/etc/profile";
		echo "Impostazione variabili globali nel file $file_profile";
		sudo /bin/su -c "echo JAVA_HOME=$f_path_jdk$f_new_jdk >> $file_profile";
		sudo /bin/su -c "echo JRE_HOME=$f_path_jdk$f_new_jdk'/jre' >> $file_profile";
		sudo /bin/su -c "echo 'PATH=$PATH:$JAVA_HOME/bin:$JRE_HOME/bin' >> $file_profile";
		sudo /bin/su -c "echo 'export JAVA_HOME' >> $file_profile";
		sudo /bin/su -c "echo 'export JRE_HOME' >> $file_profile";
		sudo /bin/su -c "echo 'export PATH' >> $file_profile";
		check_error "Modifica file $file_profile";

		echo "Impostazione di java e javaws come default di sistema";
		sudo update-alternatives --install "/usr/bin/java" "java" "$f_path_jdk$f_new_jdk/bin/java" 1;
		sudo update-alternatives --install "/usr/bin/javaws" "javaws" "$f_path_jdk$f_new_jdk/bin/javaws" 1;
		sudo update-alternatives --set java "$f_path_jdk$f_new_jdk/bin/java";
		sudo update-alternatives --set javaws "$f_path_jdk$f_new_jdk/bin/javaws";
		check_error "Impostazione JDK Oracle come default di sistema";
	fi
}



# Impostazione JDK Oracle come default di sistema
echo "Impostare JDK Oracole java come default di sistema?";
read -n1 choise;
if [ "$choise" == "y" ]; then
	path_jdk=/opt/;
	cd $path_jdk;
	new_jdk=`ls | grep jdk`;
	if [ "$new_jdk" == "" ]; then
		printf "${R}Nessuna cartella jdk trovata in $path_jdk\n${NC}";
		check_mount $UUID_backup;
		path_backup_jdk=$mount_point/SOFTWARE/LINUX/;
		backup_jdk=`ls $path_backup_jdk | grep jdk`;
		if [ "$backup_jdk" != "" ]; then
			echo "Vuoi utilizzare la JDK $path_backup_jdk$backup_jdk?";
			read -n1 choise;
			if [ "$choise" == "y" ]; then
				tar -xvf $path_backup_jdk$backup_jdk -C $path_jdk &> $null;
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



printf "${Y}--${NC}$mod_end $mod_\n";

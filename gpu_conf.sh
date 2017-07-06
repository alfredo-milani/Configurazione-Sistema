#!/bin/bash

# per evitare che lo script sia lanciato in modo diretto, cioè non lanciato dal main script
# applico l'algorimto di hashing sul numero casuale generato dal modulo
# principale e lo confronto con il file tmp
hash_check=`echo "$1" | md5sum`;
file_hash=`cat "$2" 2> /dev/null`;
[ ${#1} -eq 0 ] ||
[ ${#2} -eq 0 ] ||
[ "$hash_check" != "$file_hash" ] &&
printf "Attenzione! Questo script DEVE essere lanciato dallo script principale.\n" &&
exit 1;
###########################################################
##### Installazione bumblebee per utilizzo GPU NVIDIA #####
###########################################################
mod_="installazione bumblebee";
printf "\n${Y}++${NC}$mod_start $mod_\n";
str_end="${Y}--${NC}$mod_end $mod_\n";



# return --> OS
#        1 --> Debian
#        2 --> Ubuntu
function get_OS {
	IFS='=';
	while read -r key val; do
		case $val in
			[dD]ebian ) return $EXIT_SUCCESS ;;

			[uU]buntu ) return 2 ;;
		esac
	done < "/etc/"*"-release";

	# errore sconosciuto
	return $EXIT_FAILURE;
}
# Configurazione KVM
printf "Installare i componenti necessari per KVM?\n$choise_opt";
read -n1 choise;
printf "\n";
if [ "$choise" == "y" ]; then
	kvm_pre_inst=`egrep -c '(vmx|svm)' /proc/cpuinfo`;
	get_OS;
	case $? in
		0 )
			printf "${R}Errore sconosciuto durante l'acquisizione dell'OS\n${NC}";
			;;

		1 )
			if [ $kvm_pre_inst != 0 ]; then
				sudo $apt_manager install qemu-kvm libvirt-clients libvirt-daemon-system;
				sudo adduser $USER libvirt;
				check_error "Aggiunta $USER al gruppo libvirt";

				sudo adduser $USER libvirt-qemu;
				check_error "Aggiunta $USER al gruppo libvirt-qemu";

				correct_virsh=" Id    Name                           State
		----------------------------------------------------";
				current_virsh=`virsh list --all`;
				[ "$correct_virsh" == "$current_virsh" ];
				check_error "Configurazione KVM";
			else
				printf "${R}Errore! Sembra che non sia possibile configurare KVM sul terminale corrente\n${NC}";
			fi
			;;

		* )
			printf "${R}Funzione ancora non implementata per il sistema corrente\n${NC}";
			;;
	esac
else
	printf "${DG}${U}KVM non configurato\n${NC}";
fi



# funzione iterativa che copia in current_latest il numero di versione più alto
function get_latest_vers {
	if [ ${#1} == 0 ] || [ ${#2} == 0 ]; then
		printf "${R}Errore in ${FUNCNAME[0]}: argomenti mancanti\n${NC}";
		return $EXIT_SUCCESS;
	fi

	# scomposizione numero versione
	arr1=(`echo $1 | tr "." " "`);
	arr2=(`echo $2 | tr "." " "`);
	if [ ${#arr1[@]} -gt ${#arr2[@]} ]; then
		max_lenght=${#arr1[@]};
	else
		max_lenght=${#arr2[@]};
	fi
	for (( i=0; i < $max_lenght; ++i )); do
		# se uno dei campi è vuoto
		[ ${#arr1[$i]} == 0 ] && current_latest=$2 && return $EXIT_FAILURE;
		[ ${#arr2[$i]} == 0 ] && current_latest=$1 && return $EXIT_FAILURE;
		# arr1[i] < arr2[i] --> aggiorna il massimo corrente e ritorna con esito positivo
		[ ${arr1[$i]} -lt ${arr2[$i]} ] && current_latest=$2 && return $EXIT_FAILURE;
		# arr1[i] > arr2[i] --> aggiorna il massimo corrente e ritorna con esito positivo
		[ ${arr1[$i]} -gt ${arr2[$i]} ] && current_latest=$1 && return $EXIT_FAILURE;
	done

	# errore sconosciuto
	return $EXIT_SUCCESS;
}
# check lib in /usr/lib/ e ~/sdk/emulator/
printf "Correggere l'errore 'libstdc++.so.6: version GLIBCXX_3.4.21 not found'?\n$choise_opt";
read -n1 choise;
printf "\n";
if [ "$choise" == "y" ]; then
	libstd=libstdc++.so.;
	libstd_lenght=${#libstd};
	lib_usr_path=/usr/lib/x86_64-linux-gnu;
	arr_lib_usr_path=(`ls $lib_usr_path | grep $libstd`);
	sdk_path=$sdk/emulator/lib64/libstdc++;
	arr_sdk_path=(`ls $sdk_path | grep $libstd`);

	echo "Checking delle librerie in $lib_usr_path e $sdk_path";
	if [ -d "$lib_usr_path" ] && [ -d "$sdk_path" ]; then
		# numero di versione corrente più alto in lib_usr_path
		current_latest="0";

		# scrittura del numero di versione in current_latest
		for lib in ${arr_lib_usr_path[@]}; do
			lib_lenght=${#lib};
			tmp_vers=`echo $lib | cut -c $(($libstd_lenght + 1))-$lib_lenght`;
			get_latest_vers $current_latest $tmp_vers;
		done

		for lib in ${arr_sdk_path[@]}; do
			sudo mv $lib $lib"_orig";
		done
		# link simbolico della versione più recente delle lib
		sudo ln -s $lib_usr_path/$libstd$current_latest $sdk_path;
		check_error "Correzione errore libstdc++.so.6: version 'GLIBCXX_3.4.21'";
	else
		printf "${R}Path $lib_usr_path o $sdk_path non esisteni\n${NC}";
	fi
else
	printf "${DG}${U}Errore non corretto\n${NC}";
fi



printf "Installare e configurare bumblebee?\n$choise_opt";
read -n1 choise;
printf "\n";
if [ "$choise" == "y" ]; then
	# controllo presenza GPU nel sistema
	check_gpu=`lspci -v | egrep -i 'vga|3d|nvidia' | grep -i 'nvidia'`;
	[ ${#check_gpu} != 0 ];
	! check_error "Verifica presenza GPU discreta" && printf "$str_end" && exit $EXIT_FAILURE;

	echo "Disabilitazione driver nouveau";
	sudo modprobe -r nouveau;
	! check_error "Disabilitazione driver nouveau" &&
	printf "${Y}Prova ad aggiungere il flag 'nomodeset' durante la fase di boot\n${NC}" &&
	printf "$str_end" && exit $EXIT_FAILURE;

	printf "Assicurati che il modulo 'vga_switcheroo' sia disabilitato (oppure che sia mancante)";
	sudo modprobe -r vga_switcheroo;

	printf "Abilita i repository 'main', 'contrib', 'non-free'. Chiudi la finestra per continuare\n";
	software-properties-gtk &> $null;
	if [ $? != 0 ]; then
		# TODO --> modifica automatica del file /etc/apt/source.list
		printf "software-properties-gtk mancante.
		Modifica il file /etc/apt/source.list manualmente per abilitare i repository 'main', 'contrib', 'non-free'";
		sudo vi /etc/apt/source.list;
	fi

	printf "Update, update del sistema e download tools necessari";
	tmp=`lscpu | grep 'CPU op-mode(s):' | awk '{print $4}'`;
	arch=`echo $tmp | cut -c 1-2`;
	[ $arch != 64 ] && [ $arch != 32 ] &&
	check_error "Controllo architettura di sistema" &&
	printf "$str_end" && exit $EXIT_FAILURE;

	sudo $apt_manager update;
	sudo $apt_manager install gcc make linux-headers-amd$arch;
	sudo $apt_manager install dkms bbswitch-dkms;

	# load the bbswitch module
	sudo modprobe bbswitch load_state=0;
	# test bbswitch
	bbswitch_=(`cat /proc/acpi/bbswitch`);
	bbswitch_online=${bbswitch[1]};
	[ "$bbswitch_online" != "ON" ] && [ "$bbswitch_online" != "OFF" ] &&
	check_error "Test bbswitch" &&
	printf "$str_end" && exit $EXIT_FAILURE;

	$cmd 'echo "blacklist nouveau" >> /etc/modprobe.d/nouveau-blacklist.conf';
	check_error "Modulo nouveau in blacklist";

	printf "Installazione dirver nvidia, bumblebee e dipendenze varie";
	sudo $apt_manager install nvidia-kernel-dkms nvidia-xconfig nvidia-settings;
	sudo $apt_manager install nvidia-vdpau-driver vdpau-va-driver mesa-utils;
	sudo $apt_manager install bumblebee-nvidia;

	sito_visualgl="https://sourceforge.net/projects/virtualgl/files/";
	printf "${Y}Apertura sito $sito_visualgl\n${NC}";
	firefox $sito_visualgl &> $null;
	echo "Premere un pulsante una volta scaricato il file nella directory $_dev_shm_";
	read -n1;
	printf "\n";
	cd $_dev_shm_;
	sudo dpkg -i virtual*.deb;
	check_error "Installazione tool virtualgl";

	printf "Per utilizzare la GPU NVIDIA sono necessari i peremessi di root quindi aggiungiamo l'username al gruppo bumblebee\n";
	sudo usermod -aG bumblebee $USER;

	bumblebee_conf=/etc/bumblebee/bumblebee.conf;
	printf "Ottimizzare il file di configurazione $bumblebee_conf?\n$choise_opt";
	read -n1 choise;
	printf "\n";
	if [ "$choise" == "y" ]; then
		# sed: ^ --> inizio riga
		#      $ --> fine riga
		#	   I --> case sensitive
		#	  .* --> sostituzione intera riga
		line_to_replace="VGLTransport="; new_str="VGLTransport=proxy";
		sudo sed -i "/^$line_to_replace/s/.*/$new_str/" $bumblebee_conf;
		check_error "Modificare chiave $line_to_replace"

		line_to_replace="PMMethod="; new_str="PMMethod=bbswitch";
		sudo sed -i "/^$line_to_replace/s/.*/$new_str/" $bumblebee_conf;
		check_error "Modificare chiave $line_to_replace"

		line_to_replace="Bridge="; new_str="Bridge=primus";
		sudo sed -i "/^$line_to_replace/s/.*/$new_str/" $bumblebee_conf;
		check_error "Modificare chiave $line_to_replace"

		line_to_replace="Driver="; new_str="Driver=nvidia";
		sudo sed -i "/^$line_to_replace/s/.*/$new_str/" $bumblebee_conf;
		check_error "Modificare chiave $line_to_replace"
	else
		printf "${DG}${U}File $bumblebee_conf non ottimizzato\n${NC}";
	fi

	sudo service bumblebeed restart;

	printf "NOTA: è consigliato usare primusrun rispetto ad optirun perchè più veloce\n";
	printf "NOTA: per testare bumblebee: $ primusrun/optirun -vv glxgears\n";
	printf "Per tools di benchmarking visitare questo sito: 'http://www.geeks3d.com/gputest/download/'\n";
	printf "Per utilizzare nvidia-settings usare il comando: 'optirun nvidia-settings -c :8'\n";
	printf "${Y}Bisogna riavviare il pc per completare l'installazione.\n${NC}";
	printf "${Y}Riavviare ora?\n$choise_opt${NC}";
	read -n1 choise;
	printf "\n";
	[ "$choise" == "y" ] && sudo reboot;
else
	printf "${DG}${U}Modulo bulmbelee non installato\n${NC}";
fi



printf "$str_end";

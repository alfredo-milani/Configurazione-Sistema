#!/bin/bash
# ============================================================================

# Titolo:           gpu_conf.sh
# Descrizione:      Installazione driver GPU Nvidia, KVM e correzione bugs relativi all'emulatore di Android Studio
# Autore:           Alfredo Milani  (alfredo.milani.94@gmail.com)
# Data:             mar 25 lug 2017, 16.54.32, CEST
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
###########################################################
##### Installazione bumblebee per utilizzo GPU NVIDIA #####
###########################################################
mod_="installazione bumblebee";
printf "\n${Y}++${NC}$mod_start $mod_\n";
str_end="${Y}--${NC}$mod_end $mod_\n";
father_file=$2;



# return --> OS
#        1 --> Debian
#        2 --> Ubuntu
function get_OS {
	IFS='=';
	while read -r key val; do
		case $val in
			[dD]ebian | DEBIAN ) return 1 ;;
			[uU]buntu | UBUNTU ) return 2 ;;
		esac
	done < "/etc/"*"-release";

	# errore sconosciuto
	return 0;
}

# Configurazione KVM
printf "Installare i componenti necessari per KVM?\n$choise_opt";
read choise;
if [ "$choise" == "y" ]; then
	kvm_pre_inst=`egrep -c '(vmx|svm)' /proc/cpuinfo`;
	if [ $kvm_pre_inst != 0 ]; then
		if check_connection; then
			get_OS;
			OS_type=$?;
			correct_virsh=" Id    Name                           State
----------------------------------------------------";
			case $OS_type in
				1 )
					sudo $apt_manager install qemu-kvm libvirt-clients libvirt-daemon-system;
					sudo adduser $USER libvirt;
					check_error "Aggiunta $USER al gruppo libvirt";

					sudo adduser $USER libvirt-qemu;
					check_error "Aggiunta $USER al gruppo libvirt-qemu";

					current_virsh=`virsh list --all`;
					[ "$correct_virsh" == "$current_virsh" ];
					check_error "Configurazione KVM";
					;;

				2 )
					sudo $apt_manager install qemu-kvm libvirt-bin ubuntu-vm-builder bridge-utils;
					sudo adduser $USER kvm;
					check_error "Aggiunta $USER al gruppo kvm";
					sudo adduser $USER libvirtd;
					check_error "Aggiunta $USER al gruppo libvirtd";

					OS_arch=`uname -m`;
					[ "$OS_arch" != "x86_64" ] &&
					sudo $apt_manager install libstdc++6:i386 libgcc1:i386 zlib1g:i386 libncurses5:i386;

					current_virsh=`virsh list --all`;
					[ "$correct_virsh" == "$current_virsh" ];
					check_error "Configurazione KVM";
					;;

				* )
					printf "${R}Errore sconosciuto durante l'acquisizione dell'OS\n\n${NC}";
					;;
			esac

			# riavvio richiesto
			reboot_req "$father_file";
		else
			printf "${DG}${U}KVM non installata: impossibile connettersi ad Internet\n${NC}";
		fi
	else
		printf "${R}Errore! KVM non supportata sul terminale corrente\n\n${NC}";
	fi
else
	printf "${DG}${U}KVM non configurato\n\n${NC}";
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
read choise;
if [ "$choise" == "y" ]; then
	libstd=libstdc++.so.;
	libstd_lenght=${#libstd};
	lib_usr_path=/usr/lib/x86_64-linux-gnu;
	arr_lib_usr_path=(`ls $lib_usr_path | grep $libstd`);
	sdk_path=$sdk/emulator/lib64/libstdc++;
	arr_sdk_path=(`ls $sdk_path | grep $libstd`);
	old_libs="old_libs";

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

		# copia vecchie libs in old_libs dir
		sudo mkdir $sdk_path/$old_libs;
		for file in $sdk_path/*; do
			[ -f $file ] && sudo mv $file $sdk_path/$old_libs;
		done

		# link simbolico della versione più recente delle lib
		sudo ln -s $lib_usr_path/$libstd$current_latest $sdk_path;
		check_error "Correzione errore libstdc++.so.6: version 'GLIBCXX_3.4.21'";
	else
		printf "${R}Path $lib_usr_path o $sdk_path non esisteni\n${NC}";
	fi
else
	printf "${DG}${U}Errore non corretto\n\n${NC}";
fi



function manage_bumblebee {
	# controllo presenza GPU nel sistema
	check_gpu=`lspci -v | egrep -i 'vga|3d|nvidia' | grep -i 'nvidia'`;
	[ ${#check_gpu} != 0 ];
	! check_error "Verifica presenza GPU discreta" && return $EXIT_FAILURE;

	echo "Disabilitazione driver nouveau";
	sudo modprobe -r nouveau;
	! check_error "Disabilitazione driver nouveau" &&
	printf "${Y}Prova ad aggiungere il flag 'nomodeset' durante la fase di boot\n${NC}" &&
	return $EXIT_FAILURE;

	# riavvio richiesto
	reboot_req "$father_file";

	printf "Assicurati che il modulo 'vga_switcheroo' sia disabilitato (oppure che sia mancante)";
	sudo modprobe -r vga_switcheroo;

	printf "Abilita i repository 'main', 'contrib', 'non-free'. Chiudi la finestra per continuare\n";
	software-properties-gtk &> $null;
	if [ $? != 0 ]; then
		# TODO --> modifica automatica del file /etc/apt/source.list
		printf "software-properties-gtk mancante.
		Modifica il file /etc/apt/source.list manualmente per abilitare i repository 'main', 'contrib', 'non-free'";
		sudo nano /etc/apt/source.list;
	fi

	printf "Update, update del sistema e download tools necessari";
	tmp=`lscpu | grep 'CPU op-mode(s):' | awk '{print $4}'`;
	arch=`echo $tmp | cut -c 1-2`;
	[ $arch != 64 ] && [ $arch != 32 ] &&
	printf "${R}Controllo architettura di sistema: architettura sconosciuta\n${NC}" &&
	return $EXIT_FAILURE;

	! check_connection &&
	printf "${R}Connessiona assente: impossibile installare bumblebee\n${NC}" &&
	return $EXIT_FAILURE;

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
	return $EXIT_FAILURE;

	$cmd 'echo "blacklist nouveau" >> /etc/modprobe.d/nouveau-blacklist.conf';
	check_error "Modulo nouveau in blacklist";

	! check_connection &&
	printf "${R}Connessiona assente: impossibile installare bumblebee\n${NC}" &&
	return $EXIT_FAILURE;

	printf "Installazione dirver nvidia, bumblebee e dipendenze varie\n";
	sudo $apt_manager install nvidia-kernel-dkms nvidia-xconfig nvidia-settings;
	sudo $apt_manager install nvidia-vdpau-driver vdpau-va-driver mesa-utils;
	sudo $apt_manager install bumblebee-nvidia;

	sito_visualgl="https://sourceforge.net/projects/virtualgl/files/";
	printf "${Y}Apertura sito $sito_visualgl\n${NC}";
	firefox $sito_visualgl &> $null;
	echo "Premere un pulsante una volta scaricato il file nella directory $_dev_shm_";
	read;
	printf "\n";
	cd $_dev_shm_;
	sudo dpkg -i virtual*.deb;
	check_error "Installazione tool virtualgl";

	printf "Per utilizzare la GPU NVIDIA sono necessari i peremessi di root quindi aggiungiamo l'username al gruppo bumblebee\n";
	sudo usermod -aG bumblebee $USER;
	check_error "Aggiunta di $USER al gruppo bumblebee";

	bumblebee_conf=/etc/bumblebee/bumblebee.conf;
	printf "Ottimizzare il file di configurazione $bumblebee_conf?\n$choise_opt";
	read choise;
	if [ "$choise" == "y" ]; then
		# sed: ^ --> inizio riga
		#      $ --> fine riga
		#	   I --> case sensitive
		#	  .* --> sostituzione intera riga
		line_to_replace="VGLTransport="; new_str="VGLTransport=proxy";
		sudo sed -i "/^$line_to_replace/s/.*/$new_str/" "$bumblebee_conf";
		check_error "Modificare chiave $line_to_replace"

		line_to_replace="PMMethod="; new_str="PMMethod=bbswitch";
		sudo sed -i "/^$line_to_replace/s/.*/$new_str/" "$bumblebee_conf";
		check_error "Modificare chiave $line_to_replace"

		line_to_replace="Bridge="; new_str="Bridge=primus";
		sudo sed -i "/^$line_to_replace/s/.*/$new_str/" "$bumblebee_conf";
		check_error "Modificare chiave $line_to_replace"

		line_to_replace="Driver="; new_str="Driver=nvidia";
		sudo sed -i "/^$line_to_replace/s/.*/$new_str/" "$bumblebee_conf";
		check_error "Modificare chiave $line_to_replace"
	else
		printf "${DG}${U}File $bumblebee_conf non ottimizzato\n\n${NC}";
	fi

	sudo service bumblebeed restart;
	check_error "Riavvio del servizio bumblebeed";

	printf "NOTA: è consigliato usare primusrun rispetto ad optirun perchè più veloce\n";
	printf "NOTA: per testare bumblebee: $ primusrun/optirun -vv glxgears\n";
	printf "Per tools di benchmarking visitare questo sito: 'http://www.geeks3d.com/gputest/download/'\n";
	printf "Per utilizzare nvidia-settings usare il comando: 'optirun nvidia-settings -c :8'\n";
	printf "${Y}Bisogna riavviare il pc per completare l'installazione.\n${NC}";
}

printf "Installare e configurare bumblebee?\n$choise_opt";
read choise;
if ! ([ "$choise" == "y" ] && manage_bumblebee); then
	printf "${DG}${U}Modulo bulmbelee non installato\n${NC}";
fi



restore_tmp_file $1 $2;
printf "$str_end";

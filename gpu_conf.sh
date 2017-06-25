#!/bin/bash

# per evitare che lo script sia lanciato in modo diretto, cioù non lanciato dal main script
if [ ${#1} == 0 ] || [ $1 != 16 ]; then
	printf "Attenzione! Questo script DEVE essere lanciato dallo script principale.\n";
	exit 1;
fi
###########################################################
##### Installazione bumblebee per utilizzo GPU NVIDIA #####
###########################################################
mod_="installazione bumblebee";
printf "\n${Y}++${NC}$mod_start $mod_\n";
str_end="${Y}--${NC}$mod_end $mod_\n";



# Configurazione KVM
echo "Installare i componenti necessari per KVM?";
read -n1 choise;
kvm_pre_inst=`egrep -c '(vmx|svm)' /proc/cpuinfo`;
if [ "$choise" == "y" ]; then
	if [ $kvm_pre_inst != 0 ]; then
		sudo $apt_manager install qemu-kvm libvirt-clients libvirt-daemon-system;
		sudo adduser $USER libvirt;
		check_error "Aggiunta $USER al gruppo libvirt";
		sudo adduser $USER libvirt-qemu;
		check_error "Aggiunta $USER al gruppo libvirt-qemu";
		virsh list --all;
	else
		printf "${R}Errore! Sembra che non è possibile configurare KVM sul terminale corrente\n${NC}";
	fi
else
	printf "${DG}${U}KVM non configurato\n${NC}";
fi



# funzione ricorsiva che copia in current_latest il numero di versione più alto
function get_latest_vers {
	if [ ${#1} == 0 ] || [ ${#2} == 0 ]; then
		printf "${R}Errore in ${FUNCNAME[0]}: argomenti mancanti\n${NC}";
		return 1;
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
		[ ${#arr1[$i]} == 0 ] && current_latest=$2 && return 0;
		[ ${#arr2[$i]} == 0 ] && current_latest=$1 && return 0;
		# arr1[i] < arr2[i] --> aggiorna il massimo corrente e ritorna con esito positivo
		[ ${arr1[$i]} -lt ${arr2[$i]} ] && current_latest=$2 && return 0;
		# arr1[i] > arr2[i] --> aggiorna il massimo corrente e ritorna con esito positivo
		[ ${arr1[$i]} -gt ${arr2[$i]} ] && current_latest=$1 && return 0;
	done

	# errore sconosciuto
	return 1;
}
# check lib in /usr/lib/ e ~/sdk/emulator/
libstd=libstdc++.so.;
libstd_lenght=${#libstd};
lib_usr_path=/usr/lib/x86_64-linux-gnu;
arr_lib_usr_path=(`ls $lib_usr_path | grep $libstd`);
sdk_path=$sdk/emulator/lib64/libstdc++;
arr_sdk_path=(`ls $sdk_path | grep $libstd`);
echo "Correggere l'errore 'libstdc++.so.6: version GLIBCXX_3.4.21 not found'?";
read -n1 choise;
if [ "$choise" == "y" ]; then
	echo "Checking delle librerie in $lib_usr_path e $sdk_path";
	! [ -d $lib_usr_path ] || ! [ -d $sdk_path ] && printf "${R}Path $lib_usr_path o $sdk_path non esisteni\n${NC}" && return 1;
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
	printf "${DG}${U}Errore non corretto\n${NC}";
fi



echo "Installare e configurare bumblebee?";
read -n1 choise;
if [ "$choise" == "y" ]; then
	# controllo presenza GPU nel sistema
	check_gpu=`lspci -v | egrep -i 'vga|3d|nvidia' | grep -i 'nvidia'`;
	if [ ${#check_gpu} == 0 ]; then
	    printf "${R}Il sistema corrente sembra non avere una GPU discreta\n${NC}";
		printf $str_end;
	    exit 1;
	fi

	echo "Disabilitazione driver nouveau";
	sudo modprobe -r nouveau;
	check_error "Disabilitazione driver nouveau";
	if [ $? != 0 ]; then
		printf "${R}Impossibile continuare l'installazione\n${NC}";
		printf "${Y}Prova ad aggiungere il flag 'nomodeset' durante la fase di boot\n${NC}";
		printf $str_end;
		exit 1;
	fi

	printf "Assicurati che il modulo 'vga_switcheroo' sia disabilitato (oppure che sia mancante)";
	sudo modprobe -r vga_switcheroo;

	printf "Abilita i repository 'main', 'contrib', 'non-free'. Chiudi la finestra per continuare\n";
	software-properties-gtk &> $null;
	if [ $? != 0 ]; then
		# TODO --> modifica automatica del file /etc/apt/source.list
		printf "software-properties-gtk mancante. Modifica il file /etc/apt/source.list manualmente per abilitare i repository 'main', 'contrib', 'non-free'";
		sudo vi /etc/apt/source.list;
	fi

	printf "Update, update del sistema e download tools necessari";
	tmp=`lscpu | grep 'CPU op-mode(s):' | awk '{print $4}'`;
	arch=`${tmp::2}`;
	if [ $arch != 64 ] && [ $arch != 32 ]; then
		printf "${R}Architettura sconosciuta\n${NC}";
		printf $str_end;
		exit 1;
	fi

	sudo $apt_manager update;
	sudo $apt_manager install gcc make linux-headers-amd$arch;
	sudo $apt_manager install dkms bbswitch-dkms;

	# load the bbswitch module
	sudo modprobe bbswitch load_state=0;
	# test bbswitch
	bbswitch_=(`cat /proc/acpi/bbswitch`);
	bbswitch_online=${bbswitch[1]};
	if [ "$bbswitch_online" != "ON" ] && [ "$bbswitch_online" != "OFF" ]; then
		printf "${R}Errore: test bbswitch fallito\n${NC}";
		printf $str_end;
		exit 1;
	fi

	$cmd 'echo "blacklist nouveau" >> /etc/modprobe.d/nouveau-blacklist.conf';
	check_connection "Nouveau modulo in blacklist";

	printf "Installazione dirver nvidia, bumblebee e dipendenze varie";
	sudo $apt_manager install nvidia-kernel-dkms nvidia-xconfig nvidia-settings;
	sudo $apt_manager install nvidia-vdpau-driver vdpau-va-driver mesa-utils;
	sudo $apt_manager install bumblebee-nvidia;

	sito_visualgl="https://sourceforge.net/projects/virtualgl/files/";
	printf "${Y}Apertura sito $sito_visualgl\n${NC}";
	firefox $sito_visualgl &> $null;
	echo "Premere un pulsante una volta scaricato il file nella directory $_dev_shm_";
	read -n1;
	cd $_dev_shm_;
	sudo dpkg -i virtual*.deb;

	printf "Per utilizzare la GPU NVIDIA sono necessari i peremessi di root quindi aggiungiamo l'username al gruppo bumblebee\n";
	sudo usermod -aG bumblebee $USER;

	bumblebee_conf=/etc/bumblebee/bumblebee.conf;
	echo "Ottimizzare il file di configurazione $bumblebee_conf?";
	read -n1 choise;
	if [ "$choise" == "y" ]; then
		# sed: ^ --> inizio riga
		#      $ --> fine riga
		#	   I --> case sensitive
		#	  .* --> sostituzione intera riga
		line_to_replace="VGLTransport="; new_str="VGLTransport=proxy";
		sudo sed -i "/^$line_to_replace/s/.*/$new_str/" $bumblebee_conf;

		line_to_replace="PMMethod="; new_str="PMMethod=bbswitch";
		sudo sed -i "/^$line_to_replace/s/.*/$new_str/" $bumblebee_conf;

		line_to_replace="Bridge="; new_str="Bridge=primus";
		sudo sed -i "/^$line_to_replace/s/.*/$new_str/" $bumblebee_conf;

		line_to_replace="Driver="; new_str="Driver=nvidia";
		sudo sed -i "/^$line_to_replace/s/.*/$new_str/" $bumblebee_conf;
	else
		printf "${DG}${U}File $bumblebee_conf non ottimizzato\n${NC}";
	fi

	sudo service bumblebeed restart;

	printf "${Y}Bisogna riavviare il pc per completare l'installazione. Premere y per riavviare\n${NC}";
	printf "NOTA: è consigliato usare primusrun rispetto ad optirun perchè più veloce\n";
	printf "NOTA: per testare bumblebee: $ primusrun/optirun -vv glxgears\n";
	printf "Per tools di benchmarking visitare questo sito: 'http://www.geeks3d.com/gputest/download/'\n";
	printf "Per utilizzare nvidia-settings usare il comando: 'optirun nvidia-settings -c :8'\n";
	read -n1 choise;
	if [ "$choise" == "y" ]; then
		sudo reboot;
	fi
else
	printf "${DG}${U}Modulo bulmbelee non installato\n${NC}";
fi



printf $str_end;

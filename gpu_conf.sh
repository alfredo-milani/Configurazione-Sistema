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

printf "Abilita i repository 'main', 'contrib', 'non-free. Chiudi la finestra per continuare\n";
software-properties-gtk &> &null;
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
bbswitch_=()`cat /proc/acpi/bbswitch`);
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
sudo service bumblebeed restart;



# check lib in /usr/lib/ e ~/sdk/emulator/
libstd=libstdc++.so.;
libstd_lenght=${#libstd};
lib_usr_path=/usr/lib/x86_64-linux-gnu/;
arr_lib_usr_path=(`ls $lib_usr_path | grep $libstd`);
sdk_path=$sdk/emulator/lib64/$libstd;
echo "Checking delle librerie in $lib_usr_path e $sdk_path";

##########
# TODO --> funzione ricorsiva che restituisce la versione più aggiornata della libstdc++
##########
for lib in ${arr_lib_usr_path[@]}; do
	lib_lenght=${#lib};
	tmp_vers=`echo $lib | cut -c $(($libstd_lenght + 1))-$lib_lenght`;
	echo $tmp_vers;
done



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



printf "${Y}Bisogna riavviare il pc per completare l'installazione. Premere y per riavviare\n${NC}";
printf "NOTA: è consigliato usare primusrun rispetto ad optirun perchè più veloce\n";
printf "NOTA: per testare bumblebee: $ primusrun/optirun -vv glxgears\n";
printf "Per tools di benchmarking visitare questo sito: 'http://www.geeks3d.com/gputest/download/'\n";
printf "Per utilizzare nvidia-settings usare il comando: 'optirun nvidia-settings -c :8'\n";
read -n1 choise;
if [ "$choise" == "y" ]; then
	sudo reboot;
fi



printf $str_end;

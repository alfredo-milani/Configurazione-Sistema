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

$apt_manager update;
$apt_manager install gcc make linux-headers-amd$arch;
$apt_manager install dkms bbswitch-dkms;

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
$apt_manager install nvidia-kernel-dkms nvidia-xconfig nvidia-settings;
$apt_manager install nvidia-vdpau-driver vdpau-va-driver mesa-utils;
$apt_manager install bumblebee-nvidia;

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
printf "${Y}Bisogna riavviare il pc per completare l'installazione. Premere y per riavviare\n${NC}";
printf "NOTA: per testare bumblebee: $ optirun -vv glxgears\n";
printf "Per tools di benchmarking visitare questo sito: 'http://www.geeks3d.com/gputest/download/'\n";
printf "Per utilizzare nvidia-settings usare il comando: 'optirun nvidia-settings -c :8'\n";
read -n1 choise;
if [ "$choise" == "y" ]; then
	sudo reboot;
fi



printf $str_end;

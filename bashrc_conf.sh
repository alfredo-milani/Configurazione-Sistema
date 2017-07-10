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
##################################
##### Copia alias in .bashrc #####
##################################
mod_="configurazione .bashrc";
printf "\n${Y}++${NC}$mod_start $mod_\n";
str_end="${Y}--${NC}$mod_end $mod_\n";



printf "Aggiungere gli alias in .bashrc?\n$choise_opt";
read choise;
if [ "$choise" == "y" ]; then
	echo "# custom alias
alias udug='sudo apt-fast update && sudo apt-fast upgrade'
alias uu='sudo apt update && sudo apt upgrade'
alias inst='sudo apt-fast install'
alias shutdown='sudo shutdown -h now'

# to use GPU NVIDIA
alias gpu='primusrun'

# to launch Android emulator (with name device1, device2 and device 3) with NVIDIA GPU and KVM
alias emu1='primusrun /opt/Sdk/tools/emulator -avd device1 -netdelay none -netspeed full -qemu -m 1536 -enable-kvm'
alias emu2='primusrun /opt/Sdk/tools/emulator -avd device2 -netdelay none -netspeed full -qemu -m 1536 -enable-kvm'
alias emu3='primusrun /opt/Sdk/tools/emulator -avd device3 -netdelay none -netspeed full -qemu -m 1536 -enable-kvm'

# alias per impostare i diritti in lettura/scrittura su /dev/ttyACM0 per Arduino
alias setele='sudo chmod a+rw /dev/ttyACM0'" >> ~/.bashrc;

	check_error "Inserimento alias in .bashrc"

	# riavvio richiesto
	reboot_req=0;
else
	printf "${DG}${U}Il file .bashrc non è stato modificato${NC}\n";
fi



printf "$str_end";

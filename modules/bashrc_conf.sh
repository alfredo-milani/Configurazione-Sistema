#!/bin/bash
# ============================================================================

# Titolo:           bashrc_conf.sh
# Descrizione:      Modifica file bashrc per aggiungere alias
# Autore:           Alfredo Milani  (alfredo.milani.94@gmail.com)
# Data:             mar 25 lug 2017, 16.51.47, CEST
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
##################################
##### Copia alias in .bashrc #####
##################################
mod_="configurazione file .bashrc";
printf "\n${Y}++${NC}$mod_start $mod_\n";
str_end="${Y}--${NC}$mod_end $mod_\n";
father_file=$2;



declare -r bashrc="~/.bashrc";
printf "Aggiungere gli alias in $bashrc?\n$choise_opt";
read choise;
if [ "$choise" == "y" ]; then
	echo "# custom alias
alias udug='sudo apt-fast update && sudo apt-fast upgrade'
alias uu='sudo apt update && sudo apt upgrade'
alias inst='sudo apt-fast install'
alias shutdown='sudo shutdown -h now'

# to use GPU NVIDIA
alias gpu='primusrun'
# NVIDIA settings
bumblebee_conf='/etc/bumblebee/bumblebee.conf';
display_key='VirtualDisplay';
[ -f \$bumblebee_conf ] && while IFS='=' read -r key value; do
	[ \"\$key\" == \"\$display_key\" ] &&
	declare -r display=\"\$value\" &&
	break;
done < \$bumblebee_conf;
alias gpui=\"gpu nvidia-settings -c \$display\";

# to launch Android emulator (with name device1, device2 and device 3) with NVIDIA GPU and KVM
alias emu1='primusrun /opt/Sdk/tools/emulator -avd device1 -netdelay none -netspeed full -qemu -m 1536 -enable-kvm'
alias emu2='primusrun /opt/Sdk/tools/emulator -avd device2 -netdelay none -netspeed full -qemu -m 1536 -enable-kvm'
alias emu3='primusrun /opt/Sdk/tools/emulator -avd device3 -netdelay none -netspeed full -qemu -m 1536 -enable-kvm'

# alias per impostare i diritti in lettura/scrittura su /dev/ttyACM0 per Arduino
alias setele='sudo chmod a+rw /dev/ttyACM0'" >> $bashrc;

	check_error "Inserimento alias in $bashrc";

	# riavvio richiesto
	reboot_req "$father_file";
else
	printf "${DG}${U}Il file .bashrc non è stato modificato${NC}\n";
fi



restore_tmp_file $1 $2;
printf "$str_end";

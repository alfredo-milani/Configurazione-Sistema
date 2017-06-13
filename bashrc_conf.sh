#!/bin/bash

# per evitare che lo script sia lanciato in modo diretto, cioù non lanciato dal main script
if [ ${#1} == 0 ] || [ $1 != 16 ]; then
	printf "Attenzione! Questo script DEVE essere lanciato dallo script principale.\n";
	exit 1;
fi
##################################
##### Copia alias in .bashrc #####
##################################
mod_="configurazione .bashrc";
printf "\n${Y}++${NC}$mod_start $mod_\n";



echo "Aggiungere gli alias in .bashrc?";
read -n1 choise;
if [ "$choise" == "y" ]; then
	sudo echo "# custom alias
alias udug='sudo apt-fast update && sudo apt-fast upgrade'
alias uu='sudo apt update && sudo apt upgrade'
alias inst='sudo apt-fast install'
alias shutdown='sudo shutdown -h now'

# alias per impostare i diritti in lettura/scrittura su /dev/ttyACM0 per Arduino
alias setele='sudo chmod a+rw /dev/ttyACM0'" >> ~/.bashrc;

	check_error "Inserimento alias in .bashrc"
else
	printf "${DG}${U}Il file .bashrc non è stato modificato${NC}\n";
fi



printf "${Y}--${NC}$mod_end $mod_\n";

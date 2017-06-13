#!/bin/bash

# per evitare che lo script sia lanciato in modo diretto, cioù non lanciato dal main script
if [ ${#1} == 0 ] || [ $1 != 16 ]; then
	printf "Attenzione! Questo script DEVE essere lanciato dallo script principale.\n";
	exit 1;
fi
###################################
##### Impostazione repository #####
###################################
mod_="configurazione repository";
printf "\n${Y}++${NC}$mod_start $mod_\n";



printf "${Y}Prima di proseguire VERIFICA di avere i repository corretti della versione corretta dell'OS${NC}\n";
sito_repo="http://guide.debianizzati.org/index.php/Repository_ufficiali";
echo "sito: $sito_repo";
echo "file da modificare: '/etc/apt/sources.list'";
printf "${Y}NOTA:${NC} ricorda di commentare la riga relativa al repository che punta al cd-rom\n";
if check_connection; then
	echo "Apertura del browser firefox per ottenere il sito contenente le informazioni necessarie";
	echo "(Chiudere il browser per continuare con la configurazione)";
	# 0 --> stdin; 1 --> stdout; 2 --> stderr;
	firefox $sito_repo &> $null
	if [ $? == 127 ]; then
		echo "Browser firefox non trovato. Utilizzo del tool wget per scaricare la pagina HTML";
		cd $_dev_shm_;
		mkdir tmp_HTML;
		cd tmp_HTML;
		wget $sito_repo;
	fi
fi
echo "Premi un tasto per continuare una volta aggiornato il file 'source.list'";
read -n1 ready;



printf "${Y}--${NC}$mod_end $mod_\n";

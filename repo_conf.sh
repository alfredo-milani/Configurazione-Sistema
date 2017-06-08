#!/bin/bash

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
	echo "Apertura del browser firefox per ottenere il sito contenente le informazioni necessarie"
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

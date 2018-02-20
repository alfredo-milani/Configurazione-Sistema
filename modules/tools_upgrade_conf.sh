#!/bin/bash
# Per evitare che lo script sia lanciato in modo diretto, cioè non lanciato dal main script
# applico l'algorimto di hashing sul numero casuale generato dal modulo
# principale e lo confronto con il file tmp
hash_check=`echo "$1" | md5sum`
file_hash=`cat "$2" 2> /dev/null`
[ ${#1} -eq 0 ] ||
[ ${#2} -eq 0 ] ||
[ "$hash_check" != "$file_hash" ] &&
printf "\nAttenzione! Lo script `basename $0` DEVE essere lanciato dallo script principale.\n\n" &&
exit 1
##########################################
##### Aggiornamento tools di sistema #####
##########################################
mod_="aggiornamento sistema"
printf "\n${Y}++${NC}$mod_start $mod_\n"
str_end="${Y}--${NC}$mod_end $mod_\n"
father_file=$2



# TODO --> modifica automatica file /etc/apt/sources.list
printf "${Y}Prima di proseguire VERIFICA di avere i repository corretti della versione corretta dell'OS${NC}\n"
sito_repo="http://guide.debianizzati.org/index.php/Repository_ufficiali"
echo "sito: $sito_repo"
echo "file da modificare: '/etc/apt/sources.list'"
printf "${Y}NOTA:${NC} ricorda di commentare la riga relativa al repository che punta al cd-rom\n"
if check_connection; then
	echo "Apertura del browser firefox per ottenere il sito contenente le informazioni necessarie"
	echo "(Chiudere il browser per continuare con la configurazione)"
	# 0 --> stdin; 1 --> stdout; 2 --> stderr
	firefox $sito_repo &> $null
	if [ $? == 127 ]; then
		echo "Browser firefox non trovato. Utilizzo del tool wget per scaricare la pagina HTML"
		cd $_dev_shm_
		mkdir tmp_HTML
		cd tmp_HTML
		wget $sito_repo
	fi
fi
echo "Premi un tasto per continuare una volta aggiornato il file 'source.list'"
read choise
printf "\n"



# selezione apt-manager
which apt &> $null && apt_manager=apt
which apt-fast &> $null && apt_manager=apt-fast

echo "Upgrade e update dei pacchetti del sistema."
check_connection && sudo $apt_manager update -y &&
sudo $apt_manager upgrade -y &&
# riavvio richiesto
reboot_req "$father_file"



# Installazione e configurazione del tool apt-fast
printf "Installare apt-fast?\n$choise_opt"
read choise
# la scrittura 'if check_connection; then' si può usare solo nel caso si debbano testare valori di ritorno di funzioni
if [ "$choise" == "y" ] && check_connection; then
	apt_fast="https://github.com/ilikenwf/apt-fast/archive/master.zip"
	cd $_dev_shm_
	mkdir apt-fast
	cd apt-fast
	sudo $apt_manager install -y aria2
	wget $apt_fast
	unzip master.zip &> $null
	cd apt-fast-master
	sudo cp apt-fast /usr/bin
	check_error "Installazione apt-fast"
	sudo cp ./man/apt-fast.8 /usr/share/man/man8
	sudo gzip /usr/share/man/man8/apt-fast.8
	sudo cp ./man/apt-fast.conf.5 /usr/share/man/man5
	sudo gzip /usr/share/man/man5/apt-fast.conf.5

	echo "Configurazione apt-fast.conf"
	mirror_apt_fast="MIRRORS=( 'http://ftp.it.debian.org/debian/,http://mi.mirror.garr.it/mirrors/debian/,http://mirror.units.it/debian/,http://debian.e4a.it/debian/' )"
	apt_fast_conf_file="/etc/apt-fast.conf"
	sudo tee -a << EOF ${apt_fast_conf_file} 1> $null



################################################################
###	Configurazione con script $current_script_name    ###
################################################################
###	Mirrors di rete
$mirror_apt_fast
###	Modificato in modo da utilizzare la nuova versione del gestore dei pacchetti apt
_APTMGR=/usr/bin/apt
###	Soppressione alert dialog di apt-fast
DOWNLOADBEFORE=true
################################################################
###	Fine configurazione    ###
################################################################
EOF
	check_error "Cofgurazione apt-fast.conf"

	# riavvio richiesto
	reboot_req "$father_file"
else
	printf "${DG}${U}apt-fast non installato${NC}\n\n"
fi



##### Installazione tools principali
printf "Vuoi installare gksu, vim, vlc, preload, curl, redshift, alacarte, g++, gparted?\n$choise_opt"
read choise
if [ "$choise" = "y" ] && check_connection; then
	echo "Installazione dei princiali tools: gksu, vim, vlc, preload, curl, redshift, alacarte, g++, gparted"
	sudo $apt_manager install gksu vim vlc preload curl redshift alacarte g++ gparted -y
	check_error "Installazione dei tools: vim, vlc, preload, curl, redshift, alacarte, g++, gparted"

	printf "Vuoi installare e configurare anche prelink?\n$choise_opt"
	read choise
	if [ "$choise" = "y" ] && check_connection; then
		sudo $apt_manager install prelink -y
		path_prelink="/etc/default/prelink"
		files_da_modificare="prelink"
		old_str="PRELINKING=unknown"
		new_str="PRELINKING=yes"
		cd $path_prelink
		sudo sed -i "s/$old_str/$new_str/g" "$files_da_modificare"
		sudo /etc/cron.daily/prelink
		check_error "Installazione ed avvio del tool prelink"
	else
		printf "${DG}${U}Il tool prelink non è stato installato${NC}\n\n"
	fi

	printf "Vuoi installare il tool ulatency per migliore le prestazioni del sistema?\n"
	printf "(Maggiori informazioni al sito: https://github.com/poelzi/ulatencyd/wiki/Faq#how-can-i-see-if-it-s-working)\n$choise_opt"
	read choise
	if [ "$choise" == "y" ] && check_connection; then
		$apt_manager install ulatency ulatencyd
		check_error "Installazione ulatency\n" && printf "Il demone si avvierà in automatico al prossimo riavvio del sistema\n"
	else
		printf "${DG}${U}Il tool ulatency non è stato installato${NC}\n\n"
	fi

	# riavvio richiesto
	reboot_req "$father_file"
else
	printf "${DG}${U}Tools non installati${NC}\n\n"
fi

printf "Vuoi installare atom e google-chrome?\n$choise_opt"
read choise
if [ "$choise" = "y" ] && check_connection; then
	sudo $apt_manager install git
	mkdir $_dev_shm_"/atom"
	cd $_dev_shm_"/atom"
	atom_link="https://atom.io/download/deb"
	wget $atom_link
	sudo dpkg -i *deb
	check_error "Installazione editor atom"

	echo "Installazione google-chrome attraverso wget (molto simile a curl, ma wget è esclusivamente un command line tool)"
	mkdir $_dev_shm_"/google"
	cd $_dev_shm_"/google"
	chrome_link="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
	wget $chrome_link
	sudo dpkg -i *deb
	sudo $apt_manager -f install -y
	check_error "Installazione broswer google-chrome"

	echo "Il modulo fstab_conf.sh provvederà a montare la directory di default di Google-Chrome su RAMDISK"
    <<COMM
    NOTA: 2 meccanismi per evitare che Chrome salvi cache: nel file fstab la cartella .cache/google-chrome è montata su RAMDISK
	(l'opzione --disk-cache-dir="/dev/shm/Trash" in alacarte non è più necessaria)
	if [ $? == 0 ]; then
		printf "${Y}Sposta la cache di Google-Chrome su RAMDISK con alacarte${NC}\n"
		alacarte 2> $null
		echo "Una volta spostata la cache con alacarte premi un pulsante per continuare"
		read choise
		printf "\n"
	fi
COMM

	# riavvio richiesto
	reboot_req "$father_file"
else
	printf "${DG}${U}Atom e Google-Chrome non installati${NC}\n\n"
fi



# Installazioe estensioni
printf "Vuoi installare le estensioni con id: $extensions_id?\n$choise_opt"
read choise
if [ "$choise" == "y" ] && check_connection; then
	# abilitazione percentuale batteria
	gsettings set org.gnome.desktop.interface show-battery-percentage true
	check_error "Abilitazione percentuale batteria"

	for el in $extensions_id; do
		# disabilitazione intel_pstate a fronte dell'installazione di un'estensione per regolare la frequenza della CPU
		if [ $el == 1082 ] || [ $el == 47 ] || [ $el == 444 ] && [ -f "/etc/default/grub" ]; then
			printf "NOTA: le estensioni che modificano il numero di threads del sistema potrebbero andare in conflitto con i driver nouveau e provocare freeze del sistema.\nInstallare l'estensione ID: $el comunque?\n$choise_opt"
			read choise
			[ "$choise" != "y" ] && continue

			printf "Disabilitare i driver intel_pstate?\nNOTA: Disabilitando il driver, con l'estensione cpufreq (ID: 1082) il Turbo Boost potrebbe non funzionare\n$choise_opt"
			read choise
			if [ "$choise" == "y" ]; then
				! [ -f "/etc/default/grub" ] &&
				printf "${R}File /etc/default/grub non trovato.\nImpossibile disabilitare il Turbo Boost\n${NC}" &&
				continue

				old_str='GRUB_CMDLINE_LINUX_DEFAULT=\"quiet'
				new_str='GRUB_CMDLINE_LINUX_DEFAULT=\"quiet intel_pstate=disable'
				sudo sed -i "s/$old_str/$new_str/" "/etc/default/grub"
				check_error "Modifica file /etc/default/grub"
				sudo update-grub
			else
				printf "${DG}${U}Driver intel_pstate non disabilitato\n\n${NC}"
			fi
		fi

		#########################
		# script by N. Bernaerts#
		#########################
		$absolute_script_path"utils/gnomeshell_extension_manage.sh" --system --install --extension-id $el
		check_error "Installazione estensione con id: $el"
	done

	# riavvio richiesto
	reboot_req "$father_file"
else
	printf "${DG}${U}Estensioni non installate${NC}\n\n"
fi



# Installazione librerie per il motore GTK
missing_libs="murrine-themes libcanberra-gtk-module"
printf "Installare le librerie mancanti del motore GTK ($missing_libs)?\n$choise_opt"
read choise
if [ "$choise" == "y" ] && check_connection; then
	$apt_manager install $missing_libs

	# riavvio richiesto
	reboot_req "$father_file"
else
	printf "${DG}${U}Librerie --> $missing_libs <-- non installate\n${NC}"
fi



restore_tmp_file $1 $2
printf "$str_end"

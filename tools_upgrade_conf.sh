#!/bin/bash

##########################################
##### Aggiornamento tools di sistema #####
##########################################
mod_="aggiornamento sistema";
echo $mod_start $mod_;



# Installazione e configurazione del tool apt-fast
echo "Installare apt-fast? Premi 'y' per OK";
read -n1 choise;
# la scrittura 'if check_connection; then' si può usare solo nel caso si debbano testare valori di ritorno di funzioni
if [ $choise == "y" ] && check_connection; then
	apt_fast="https://github.com/ilikenwf/apt-fast/archive/master.zip";
	cd $_dev_shm_;
	mkdir apt-fast;
	cd apt-fast;
	sudo apt-get install -y aria2;
	wget $apt_fast;
	unzip master.zip &> $null;
	cd apt-fast-master;
	sudo cp apt-fast /usr/bin;
	check_error "Installazione apt-fast";
	sudo cp ./man/apt-fast.8 /usr/share/man/man8;
	sudo gzip /usr/share/man/man8/apt-fast.8;
	sudo cp ./man/apt-fast.conf.5 /usr/share/man/man5;
	sudo gzip /usr/share/man/man5/apt-fast.conf.5;

	echo "Configurazione apt-fast.conf";
	mirror_apt_fast="MIRRORS=( 'http://ftp.it.debian.org/debian/,http://mi.mirror.garr.it/mirrors/debian/,http://mirror.units.it/debian/,http://debian.e4a.it/debian/' )";
	apt_fast_conf_file="apt-fast.conf";
	echo "################################################################" >> $apt_fast_conf_file;
	echo "###	Configurazione con script $current_script_name    ###" >> $apt_fast_conf_file;
	echo "################################################################" >> $apt_fast_conf_file;
	echo "###	Mirrors di rete" >> $apt_fast_conf_file;
	echo "$mirror_apt_fast" >> $apt_fast_conf_file;
	echo "###	Modificato in modo da utilizzare la nuova versione del gestore dei pacchetti apt" >> $apt_fast_conf_file;
	echo "_APTMGR=/usr/bin/apt" >> $apt_fast_conf_file;
	echo "###	Soppressione alert dialog di apt-fast" >> $apt_fast_conf_file;
	echo "DOWNLOADBEFORE=true" >> $apt_fast_conf_file;
	echo "################################################################" >> $apt_fast_conf_file;
	echo "###	Fine configurazione    ###" >> $apt_fast_conf_file;
	echo "################################################################" >> $apt_fast_conf_file;
	sudo cp apt-fast.conf /etc;
	check_error "Cofgurazione apt-fast.conf";
else
	printf "${DG}${U}apt-fast non installato${NC}\n";
fi



echo "Upgrade e update dei pacchetti del sistema. Attendere...";
if check_connection; then
	sudo apt-fast update -y; sudo apt-fast upgrade -y;
fi



##### Installazione tools principali
echo "Vuoi installare vlc, preload, curl, redshift, alacarte, g++, gparted? Premi y per OK";
read -n1 ready;
if [ "$ready" = "y" ] && check_connection; then
	echo "Installazione dei princiali tools: vlc, preload, curl, redshift, alacarte, g++, gparted";
	sudo apt-fast install vlc preload curl redshift alacarte g++ gparted -y;
	check_error "Installazione dei tools: vlc, preload, curl, redshift, alacarte, g++, gparted";

	printf "Vuoi installare e configurare anche prelink? Premi y per OK\n";
	read -n1 ready;
	if [ "$ready" = "y" ]; then
		sudo apt-fast install prelink -y;
		path_prelink="/etc/default/prelink";
		files_da_modificare="prelink";
		old_str="PRELINKING=unknown";
		new_str="PRELINKING=yes";
		cd $path_prelink;
		sudo sed -i "s/$old_str/$new_str/g" $files_da_modificare;
		sudo /etc/cron.daily/prelink;
		check_error "Installazione ed avvio del tool prelink";
	else
		printf "${DG}${U}Il tool prelink non è stato installato${NC}\n";
	fi
else
	printf "${DG}${U}Tools non installati${NC}\n";
fi

echo "Vuoi installare atom e google-chrome? Premi y per OK";
read -n1 choise;
if [ "$choise" = "y" ] && check_connection; then
	mkdir $_dev_shm_"atom";
	cd $_dev_shm_"atom";
	atom_link="https://atom.io/download/deb";
	wget $atom_link;
	sudo dpkg -i *deb;
	check_error "Installazione editor atom";

	echo "Installazione google-chrome attraverso wget (molto simile a curl, ma wget è esclusivamente un command line tool)";
	mkdir $_dev_shm_"google";
	cd $_dev_shm_"google";
	chrome_link="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb";
	wget $chrome_link;
	sudo dpkg -i *deb;
	sudo apt-fast -f install -y;
	check_error "Installazione broswer google-chrome";

	printf "${Y}Sposta la cache di Google-Chrome su RAMDISK con alacarte${NC}\n";
	alacarte 2> $null;
	echo "Una volta spostata la cache con alacarte premi un pulsante per continuare";
	read -n1 ready;
else
	printf "${DG}${U}Atom e Google-Chrome non installati${NC}\n";
fi



# Installazioe estensioni
echo "Vuoi aprire il software center ed installare ora le estensioni?";
read -n1 choise;
if [ "$choise" == "y" ] && check_connection; then
	printf "Estensioni da installare:\n-Appfolders management extension\n-Application menu (dovrebbe essere già presente);\n-Battery status;\n-Dash to dock;\n-Dynamic panel transparency;\n";
	gnome-software 2> $null;
	if [ $? == 127 ]; then
		gnome_ext="https://extensions.gnome.org/";
		ext_dir="/usr/share/gnome-shell/extensions/";
		echo "Il tool gnome-software non è stato trovato."
		echo "Vai sul sito $gnome_ext per installarle manualmente."
		echo "Decomprimi le singole estensioni e copiale in $ext_dir";
	fi
	echo "Premi un pulsante una volta installate le estensioni";
	read -n1 ready;
else
	printf "${DG}${U}Estensioni non installate${NC}\n";
fi



mod_="aggiornamento sistema";
echo $mod_end $mod_;

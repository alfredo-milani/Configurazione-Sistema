# Configurazione-Sistema

Semplici script per configurare un sistema (*debian-based* - *gnome*).

- [Configurazione-Sistema](#configurazione-sistema)
    - [Descrizione](#descrizione)
    - [Personalizzazione](#personalizzazione)
    - [Utilizzo](#utilizzo)
    - [Note](#note)
    - [Riferimenti](#riferimenti)

------

## Descrizione
Lo script principale è **main.sh** che ha il compito di invocare gli altri moduli a seconda della richiesta dell'utente. <br/>
I moduli sono:

- **appearance_conf.sh** - configurazione del *tema* e delle *icone*:
    * imposta il tema specificato dalla chiave *`theme_scelto`* locato in *`themes_backup`*;
    * imposta il set di icone specificato dalla chiave *`icon_scelto`* locato in *`icons_backup`*;
- **bashrc_conf.sh** - configurazione del file `~/.bashrc`:
    * aggiunge gli alias di alcuni comandi nel file ~/.bashrc;
- **fstab.sh** - configurazione del file `/etc/fstab`:
    * crea ramdisk nelle locazioni: /var/tmp; /var/log; /tmp;
    * monta su ramdisk le cache dei principali browser (Chrome, Firefox, Chromium);
    * monta il volume contenete dati condivisi da altri OS (e.g. Windows) nella posizione /media/Data. L'UUID del device che sarà montato può essere specificato dalla chiave *`UUID_data`*;
- **gpu_conf.sh** - configurazione *bumblebee* per gestione GPU discreta NVIDIA:
    * scarica e configura KVM nel terminale dell'utente (per ora c'è il supporto solo a distribuzioni Debian ed Ubuntu);
    * corregge l'errore "libstdc++.so.6: version GLIBCXX_3.4.XXX not found" che si manifesta quando si utilizza l'IDE Android Studio con l'emulatore e la virtualizzazione KVM;
    * scarica e configura il tool bumblebee per gestire le GPU NVidia con tecnologia Optimus;
- **jdk_conf.sh** - copia e configurazione della *JDK Oracle*:
    * configura la Oracle JDK locata in *`sdk`* come default di sistema; <br/>
    se in *`sdk`* non c'è alcuna JDK, provvede a cercarla nel device con UUID *`UUID_backup`* nella directory specificata dalla chiava *`software`*;
- **kb_shortcut_conf.sh** - impostazione dei *keyboard shortcuts*:
    * copia gli script dalla directory *`scripts_backup`* (contenuta nel device *`UUID_backup`*) alla directory *`script_path`*;
    * imposta le principali scorciatoie da tastiera;
- **network_conf.sh** - ottimizzazione impostazioni protocollo *TCP* / *NIC*:
    * ottimizza le impostazioni del protocollo TCP;
    * ottimizza le impostazioni per la NIC Intel AC7260;
    * copia i dirvers contenuti in *`driver_backup`* del device *`UUID_backup`* nella directory di sistema; <br/>
    NOTA: i drivers contenuti nella direcotry *`driver_backup`* devono essere contenuti in una cartella avente come nome l'output del comando: `$ sudo dmidecode -s system-version | tr " " "_"`;
    * risolve il bug dovuto al daemon Avahi-daemon che ostacola il corretto funzionamento delle NIC;
- **symbolic_link_conf.sh** - creazione *link simbolici*:
    * crea un collegamento di un path temporaneo (montato su ramdisk) nella directory di Download di default;
    * crea un collegamento sul Desktop che punta ai files in comune (contenuti nel device *`UUID_data`*) tra i vari OS che il terminale ospita;
- **tools_upgrade_conf.sh** - aggiornamento *tools* sistema:
    * assiste la configurazione dei repository;
    * scarica ed installa il gestore dei pacchetti apt-fast;
    * installa i principali tools di utilità (e.g. gksu, vim, preload, redshift, gparted, ecc... );
    * scarica ed installa l'editor Atom e il browser Google-Chrome;
    * installa le estensioni con identificativo *`extensions_id`*; <br/> l'identificativo in questione è ricavabile dal sito "https://extensions.gnome.org/"; <br/>
    e.g. vogliamo installare l'estensione dashToDock --> il suo URL è "https://extensions.gnome.org/extension/307/dash-to-dock/" --> *`extensions_id`*=307;
    * scarica ed installa le principali librerie mancanti del motore GTK;
- **tracker_disable_conf.sh** - disabilitazione _tracker-* tools_:
    * disabilitazione dei tools di indicizzazione tracker-\*;
- **utils/gnomeshell_extension_manage.sh** - download e installazione estensioni dal gnome-center (autore: *N. Bernaerts*);
- **sys.conf** - definizione variabili:
    * *`tree_dir`*: directory radice; tutti gli altri indirizzi hanno questa radice. Il suo valore può essere nullo;
    * *`UUID_backup`*: UUID del device contenente le risorse necessarie alla configurazione del sistema;
    * *`themes_backup`*: directory dove è locato il tema da configurare (partendo da tree_dir) ;
    * *`theme_scelto`*: nome del file (se il file è compresso sarà estratto) contenente il tema desiderato;
    * *`icons_backup`*: directory dove è locato il set di icone da configurare (partendo da tree_dir);
    * *`icon_scelto`*: nome del file (se il file è compresso sarà estratto) contenente il set di icone desiderato;
    * *`software`*: directory dove è locato il software necessario alla configurazione del sistema (partendo da tree_dir);
    * *`script_path`*: directory dove si vogliono copiare gli scripts del sistema;
    * *`scripts_backup`*: sirectory dove sono locati gli scripts da copiare (partendo da tree_dir);
    * *`UUID_data`*: UUID del device contenente i files comuni ai vari OS contenuti nel terminale corrente;
    * *`driver_backup`*: directory dove sono locati i drivers necessari al sistema (partendo da tree_dir);
    * *`extensions_id`*: ID delle estensioni che si vogliono installare nel sistema. L'ID delle estensioni è ottenibile dal sito "https://extensions.gnome.org/";
    * *`sdk`*: directory assoluta del sistema dove si trova la SDK Android;
    * *`tmp`*: directory usata per la gestione dei files temporanei. Il suo valore può essere nullo;


> Il file *sys.conf* **deve essere modificato** in funzione della struttura di directory ove sono locate le risorse. </br>
Le chiavi non devo essere precedute da spazi altrimenti non verranno considerate.



## Personalizzazione
La configurazione di default del file *sys.conf* rappresenta la seguente struttura di directory (prendere `~/example_dir` come esempio):

    example_dir
    |
    |--> CONFIG_LINUX --> Aspetto --> Themes
    |                 |           |-> Icons
    |                 |
    |                 |-> Driver
    |                 |
    |                 |-> scripts
    |
    |
    |--> SOFTWARE --> LINUX

Questo è un file di tipo *key/value*:

keys | values
--- | ---
tree_dir | Directory di partenza. *Tutti gli altri indirizzi hanno questa radice di partenza* (opzionale).
   |   
UUID_backup | UUID del device contenente le risorse necessarie (temi, icone, softwares, extensions.
   |   
themes_backup | Directory dove è locato il tema da configurare (partendo da *tree_dir*)
theme_scelto | Nome del file compresso/directory contenente il tema
icons_backup | Directory dove è locato il set di icone da configurare (partendo da *tree_dir*).
icon_scelto | Nome del file compresso/directory contenente il set di icone
   |   
software | Directory dove è locato il software necessario (es. jdk*.tar.gz) (partendo da *tree_dir*).
   |   
script_path | Directory dove si vogliono copiare gli scripts necessari
scripts_backup | Directory dove sono locati gli scripts da copiare (partendo da *tree_dir*).
   |   
UUID_data | UUID del device dal quale si vogliono creare dei *link simbolici*.
   |   
driver_backup | Directory dove si trovano i drivers necessari al sistema (partendo da *tree_dir*).All'interno di questa cartella lo script cercherà una cartella avente il nome del dispositivo in uso (*il nome della cartella il questione deve coincidere con l'output del comando* **$ sudo dmidecode -s system-version &#124; tr " " "_"**).
   |   
extensions_id | ID delle estensioni ottenibili dal sito "https://extensions.gnome.org/".
   |   
sdk | Directory assoluta dove si trova la SDK.
   |   
tmp | Direzione files temporanei (default /dev/shm).




## Utilizzo
```markdown
# Utilizzo

    ./main.sh -[options]

# Options

    --all | --ALL )     Configurazione completa del sistema
    -a | -A )           Configurazione di tema ed icone
    -b | -B )           Configurazione del file .bashrc
    -c | -C )           Indirizzo file di configurazione sys.conf
    -f | -F )           Configurazione del file /etc/fstab
    -gpu | -GPU )       Configurazione bumblebee per gestione GPU NVIDIA
    -jdk | -JDK )       Configurazione della JDK Oracle
    -l | -L )           Creazione link simbolici
    -m | -M )           Per creare più istanze contemporaneamente
    -n | -N )           Configurazione di rete
    -s | -S )           Configurazione dei keyboard shortcuts
    -tr | -TR )         Disabilitazione tracker-* tools
    -u | -U )           Aggiornamento tools del sistema
    --w | --W )         Disabilitazione warnings

```



## Note
**Autore: Alfredo Milani** <br/>
Data creazione: 10 - 06 - 2017

Testato su: *Linux debian 4.9.0-3-amd64 #1 SMP x86_64 GNU/Linux;* <br/>
Notebook: *Lenovo Y50-70;* <br/>
CPU: *Intel Core-i7;* <br/>
GPU: *NVidia GTX 960M;* <br/>
NIC: *Intel AC7260.*


In `example_dir/CONFIG_LINUX/scripts/` ci sono degli scripts utili:
* *`manage_cores.sh`*: per gestire il numero di cores attivi nel sistema;
* *`check_psw.sh`*: per eseguire il tool/script passatogli come argomento come super utente;
* *`redshift_regolator.sh`*: gestisce il tool redshift per ridurre l'emissione dei raggi blu dello schermo;



## Riferimenti
Lo script ~/utils/gnomeshell_extension_manage.sh è stato creato da [**N. Bernaerts**](https://github.com/NicolasBernaerts/ubuntu-scripts/blob/master/ubuntugnome/gnomeshell-extension-manage).

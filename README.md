# Configurazione-Sistema

Semplici script per configurare un sistema (*debian-based* - *gnome*).

- [Configurazione-Sistema](#configurazione-sistema)
    - [Descrizione](#descrizione)
    - [Personalizzazione](#personalizzazione)
    - [Utilizzo](#utilizzo)
    - [Note](#note)

------

## Descrizione
Lo script principale è **_main.sh_** che ha il compito di invocare gli altri moduli a seconda della richiesta dell'utente.
Gli altri moduli sono:

- appearance_conf.sh - per la configurazione del *tema* e delle *icone*;
- bashrc_conf.sh - configurazione del file `~/.bashrc`;
- fstab.sh - configurazione del file `/etc/fstab`;
- gpu_conf.sh - configurazione bumblebee per gestione GPU discreta NVIDIA;
- jdk_conf.sh - copia e configurazione della *JDK Oracle*;
- kb_shortcut_conf.sh - impostazione dei *keyboard shortcuts*;
- network_conf.sh - ottimizzazione impostazioni protocollo *TCP* / *NIC*;
- symbolic_link_conf.sh - creazione *link simbolici*;
- tools_upgrade_conf.sh - *aggiornamento tools* sistema;
- tracker_disable_conf.sh - disabilitazione _tracker-* tools_;
- utils/gnomeshell_extension_manage.sh - download e installazione estensioni dal gnome-center (autore: *N. Bernaerts*);

- sys.conf - definizione variabili.

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

Lo script ~/utils/gnomeshell_extension_manage.sh è stato creato da [**N. Bernaerts**](https://github.com/NicolasBernaerts/ubuntu-scripts/blob/master/ubuntugnome/gnomeshell-extension-manage).

Testato su: *Linux debian 4.9.0-3-amd64 #1 SMP x86_64 GNU/Linux;* <br/>
Notebook: *Lenovo Y50-70;* <br/>
CPU: *Intel Core-i7;* <br/>
GPU: *NVidia GTX 960M;* <br/>
NIC: *Intel AC7260.*

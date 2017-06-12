# Configurazione-Sistema

Semplici script per configurare un sistema (*debian-based* - *gnome*).

- [Configurazione-Sistema](#configurazione-sistema)
    - [Descrizione](#descrizione)
    - [Personalizzazione](#personalizzazione)
    - [Utilizzo](#utilizzo)

------

## Descrizione
Lo script principale è **_main.sh_** che ha il compito di invocare gli altri moduli a seconda della richiesta dell'utente.
Gli altri moduli sono:

- appearance_conf.sh - per la configurazione del *tema* e delle *icone*;
- bashrc_conf.sh - configurazione del file `~/.bashrc`;
- fstab.sh - configurazione del file `/etc/fstab`;
- jdk_conf.sh - copia e configurazione della *JDK Oracle*;
- kb_shortcut_conf.sh - impostazione dei *keyboard shortcuts*;
- network_conf.sh - ottimizzazione impostazioni protocollo *TCP* / *NIC*;
- repo_conf.sh - configurazione *repository*;
- symbolic_link_conf.sh - creazione *link simbolici*;
- tools_upgrade_conf.sh - *aggiornamento tools* sistema;
- tracker_disable_conf.sh - disabilitazione _tracker-* tools_;

- sys.conf - definizione variabili.

> Il file *sys.conf* **deve essere modificato** in funzione della struttura di directory ove sono locate le risorse.



## Personalizzazione
La configurazione di default del file *sys.conf* rappresenta la seguente struttura di directory:

    ..
    |
    |--> CONFIG_LINUX --> Aspetto --> Themes
                      |           |-> Icons
                      |
                      |-> Driver
                      |
                      |-> scripts
    |
    |--> SOFTWARE --> LINUX

Questo è un file di tipo *key/value*:

keys | values
--- | ---
tree_dir | Directory di partenza. *Tutti gli altri indirizzi hanno questa radice di partenza*. Questa chiave può avere anche un valore vuoto
   |   
UUID_backup | UUID del device contenente le risorse necessarie (temi, icone, softwares, extensions
   |   
themes_backup | Directory dove è locato il tema da configurare (partendo da *tree_dir*)
icons_backup | Directory dove è locato il set di icone da configurare (partendo da *tree_dir*)
   |   
software | Directory dove è locato il software necessario (es. jdk*.tar.gz) (partendo da *tree_dir*)
   |   
script_path | Directory dove si vogliono copiare gli scripts necessari
scripts_backup | Directory dove sono locati gli scripts da copiare (partendo da *tree_dir*)
   |   
UUID_data | UUID del device dal quale si vogliono creare dei *link simbolici*
   |   
driver_backup | Directory dove si trovano i drivers necessari al sistema (partendo da *tree_dir*)




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
    -jdk | -JDK )       Configurazione della JDK Oracle
    -l | -L )           Creazione link simbolici
    -n | -N )           Configurazione di rete
    -r | -R )           Configurazione dei repository
    -s | -S )           Configurazione dei keyboard shortcuts
    -tr | -TR )         Disabilitazione tracker-* tools
    -u | -U )           Aggiornamento tools del sistema

```

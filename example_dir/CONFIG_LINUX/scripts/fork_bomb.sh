#!/bin/bash
# ============================================================================
# Titolo:           fork_bomb.sh
# Descrizione:      Fork bomb script
# Autore:           Alfredo Milani  (alfredo.milani.94@gmail.com)
# Data:             mer 26 lug 2017, 01.15.15, CEST
# Licenza:          MIT License
# Versione:         1.0.0
# Note:             Prima di eseguire questo script assicurarsi di aver salvato tutto il lavoro corrente
# Versione bash:    4.4.12(1)-release
# ============================================================================



printf "Assicurati di aver salvato il lavoro corrente prima di continuare.\n";
printf "Sei sicuro di voler eseguire questo script?\t[Yes=procedi / altrimenti=esci]\n";
read -t 20 tmp;
[ "$tmp" != "Yes" ] && exit 0;

TERM=xterm
# choosing terminal
# default Unix system under gnome
which gnome-terminal &> /dev/null
[ $? -eq 0 ] && TERM=gnome-terminal
# default under mac
which Terminal &> /dev/null
[ $? -eq 0 ] && TERM=Terminal

fork_bomb() {
    text_to_show="$@"
    # esegui in background il comando in altri terminali
    # gnome-terminal -e "bash -c ':() { : | : & }; while true; do :; done; sleep infinity'" &> /dev/null &
    $TERM -e "bash -c 'for el in {1..20}; do echo $text_to_show; done; sleep infinity'" &&
    # invia l'output come input della funzione stessa ed esegui il tutto in background
    fork_bomb | fork_bomb &
}

fork_bomb $@

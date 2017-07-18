#!/bin/bash
# ============================================================================

# Titolo:           init_script.sh
# Descrizione:      Inizializza uno script inserendo un header
# Autore:           Alfredo Milani
# Data:             sab 15 lug 2017, 15.48.36, CEST
# Licenza:          MIT License
# Versione:         1.0.0
# Note:             Usage: ./init_script.sh  [ -h | ../path_salavataggio/ ]
# Versione bash:    4.4.12(1)-release
# ============================================================================

declare -r data=`date`;
declare -r div="======================================";
declare -r clear=/usr/bin/clear;
declare -r EXIT_SUCCESS=0;
declare -r EXIT_FAILURE=1;
declare -r null=/dev/null;
declare shell='/bin/bash';
declare path_to_store='.';
declare description="--/--";
declare name="$USER";
# versione secondo le sintassi: version.revision.release
declare version="0.0.1";
declare notes="--/--";
declare editor;
declare title;
declare license="MIT License";

# selezione titolo
function select_title {
    # titolo script
    printf "Inserisci un titolo:\t";
    read -r title;
    printf "\n";

    [ ${#title} == 0 ] && select_title;

    # sostituisci gli spazi bianchi con _
    title=${title// /_};

    # conversione uppercase to lowercase.
    title=${title,,};

    # aggiungi l'estensione .sh se non presente
    [ "${title: -3}" != '.sh' ] && title="$title.sh";

    # controlla l'esistenza di un file con lo stesso nome nella directory corrente
    if [ -e "$path_to_store/$title" ] ; then
        printf "File \"$title\" già esistente in \"$path_to_store\".\n" \
        "Inserisci un nome diverso per continuare.\n";

        select_title;
    fi
}

# controllo esistenza editor
function check_editor {
    which $1 &> $null;
    [ $? == 0 ] && return $EXIT_SUCCESS;
    return $EXIT_FAILURE;
}

# selezione editor
function select_editor {
    # seleziona l'editor preferito
    printf "Seleziona un editor per aprire lo script appena creato:\n
    1 - vi
    2 - vim
    3 - emacs
    4 - nano
    5 - atom
    6 - gedit\n";
    read -r editor;

    case $editor in
        1 )
            ed="vi";
            check_editor $ed ||
            ($clear && printf "$ed non installato nel sistema.\nRiprovare.\n" && select_editor);

            $ed +13 "$path_to_store/$title";
            ;;

        2 )
            ed="vim";
            check_editor $ed ||
            ($clear && printf "$ed non installato nel sistema.\nRiprovare.\n" && select_editor);

            $ed +13 "$path_to_store/$title";
            ;;

        3 )
            ed="emacs";
            check_editor $ed ||
            ($clear && printf "$ed non installato nel sistema.\nRiprovare.\n" && select_editor);

            $ed +13 "$path_to_store/$title";
            ;;

        4 )
            ed="nano";
            check_editor $ed ||
            ($clear && printf "$ed non installato nel sistema.\nRiprovare.\n" && select_editor);

            $ed +13 "$path_to_store/$title";
            ;;

        5 )
            ed="atom";
            check_editor $ed ||
            ($clear && printf "$ed non installato nel sistema.\nRiprovare.\n" && select_editor);

            $ed "$path_to_store/$title";
            ;;

        6 )
            ed="gedit";
            check_editor $ed ||
            ($clear && printf "$ed non installato nel sistema.\nRiprovare.\n" && select_editor);

            $ed +13 "$path_to_store/$title";
            ;;

        * )
            $clear;
            printf "Comando non riconosciuto.\nRiprocare.\n\n";
            select_editor;
            ;;
    esac
}

function select_shell {
    printf "\nInserisci il path della shell da utilizzare (default: /bin/bash):\t";
    read -r tmp_shell;
    printf "\n";
    if [ ${#tmp_shell} != 0 ]; then
        if which $tmp_shell &> $null; then
            shell=$tmp_shell;
            return $EXIT_SUCCESS;
        else
            printf "Shell \"$tmp_shell\" non esistente.\nInserire una shell valida oppure clicca invio per la shell di default ($shell).\n";
            select_shell;
        fi
    fi

    return $EXIT_SUCCESS;
}

# uso
function usage {
    echo "$0 [args]";
    echo "";
    echo -e "\t\t      -h :\tmostra questo aiuto\n";
    echo -e "\t\t../path/ :\tpath di salvataggio del file";
    echo "";

    exit $EXIT_SUCCESS;
}

# controllo sull'input dell'utente
function check_input {
    [ $# -gt 1 ] && return $EXIT_FAILURE;

    for arg in $@; do
        case "$arg" in
            ? | -[hH] | --[hH] | -help | --help | -HELP | --HELP ) return $EXIT_FAILURE ;;
        esac
    done

    return $EXIT_SUCCESS;
}


# controllo sul numero di argomenti ricevuti in input
! check_input $@ && usage;
# impostazione path di salvataggio
[ ${#1} != 0 ] && if [ -d "$1" ]; then
        path_to_store=$1;
    else
        printf "Directory \"$1\" non valida\n";
    fi
printf "Directory selezionata: `realpath $path_to_store`\n\n";

select_shell;

select_title;

printf "Inserisci una descrizione:\t";
read -r tmp;
[ ${#tmp} != 0 ] && description="$tmp";

printf "Inserisci il tuo nome (default: $USER):\t";
read -r tmp;
[ ${#tmp} != 0 ] && name=$tmp;

printf "Inserisci il numero di versione (default: 0.0.1):\t";
read -r tmp;
[ ${#tmp} != 0 ] && version="$tmp";

printf "Inserisci la licenza di rilascio (default: MIT License):\t";
read -r tmp;
[ ${#tmp} != 0 ] && license="$tmp";

printf "Inserisci le note:\t";
read -r tmp;
[ ${#tmp} != 0 ] && notes="$tmp";

# nota: %-Xs --> lascia un segnaposto lungo X caratteri per una stringa
printf "\
%s
# $div$div\n
%-20s%s
%-20s%s
%-20s%s
%-20s%s
%-20s%s
%-20s%s
%-20s%s
%-20s%s
# $div$div\n" "#!$shell" "# Titolo:" "$title" "# Descrizione:" "$description" "# Autore:" "$name" "# Data:" "$data" "# Licenza:" "$license" "# Versione:" "$version" "# Note:" "$notes" "# Versione bash:" "$BASH_VERSION" > "$path_to_store/$title";

# rendi eseguibile lo script
chmod +x "$path_to_store/$title";

$clear;

select_editor;

exit $EXIT_SUCCESS;

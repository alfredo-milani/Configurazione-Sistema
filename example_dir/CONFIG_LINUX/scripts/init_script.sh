#!/bin/bash
#
# Titolo:           init_script.sh
# Descrizione:      Inizializza uno script inserendo un header
# Autore:           Alfreod Milani
# Data:             sab 15 lug 2017, 15.48.36, CEST
# Versione:         1.0.0
# Note:             Usage: ./init_script.sh
# Versione bash:    4.4.12(1)-release
# ============================================================================

declare -r data=`date`;
declare -r div="======================================";
declare -r clear=/usr/bin/clear;
declare -r EXIT_SUCCESS=0;
declare -r EXIT_FAILURE=1;
declare -r null=/dev/null;
declare description;
declare name;
declare version;
declare notes;
declare editor;
declare title;

# selezione titolo
function select_title {
    # titolo script
    printf "Inserisci un titolo:\t";
    read -r title;
    printf "\n";

    # sostituisci gli spazi bianchi con _
    title=${title// /_};

    # conversione uppercase to lowercase.
    title=${title,,};

    # aggiungi l'estensione .sh se non presente
    [ "${title: -3}" != '.sh' ] && title="$title.sh";

    # controlla l'esistenza di un file con lo stesso nome nella directory corrente
    if [ -e "$title" ] ; then
        printf "File \"$title\" già esistente.\n" \
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

            $ed +13 $title;
            ;;

        2 )
            ed="vim";
            check_editor $ed ||
            ($clear && printf "$ed non installato nel sistema.\nRiprovare.\n" && select_editor);

            $ed +13 $title;
            ;;

        3 )
            ed="emacs";
            check_editor $ed ||
            ($clear && printf "$ed non installato nel sistema.\nRiprovare.\n" && select_editor);

            $ed +13 $title;
            ;;

        4 )
            ed="nano";
            check_editor $ed ||
            ($clear && printf "$ed non installato nel sistema.\nRiprovare.\n" && select_editor);

            $ed +13 $title;
            ;;

        5 )
            ed="atom";
            check_editor $ed ||
            ($clear && printf "$ed non installato nel sistema.\nRiprovare.\n" && select_editor);

            $ed $title;
            ;;

        6 )
            ed="gedit";
            check_editor $ed ||
            ($clear && printf "$ed non installato nel sistema.\nRiprovare.\n" && select_editor);

            $ed +13 $title;
            ;;

        * )
            $clear;
            printf "Comando non riconosciuto.\nRiprocare.\n\n";
            select_editor;
            ;;
    esac
}



printf "Directory corrente: `realpath .`\n\n";

select_title;

printf "Inserisci una descrizione:\t";
read -r description;
[ ${#description} == 0 ] && description="--/--";

printf "Inserisci il tuo nome (default: $USER):\t";
read -r name;
[ ${#name} == 0 ] && name=$USER;

printf "Inserisci il numero di versione
(default: 0.0.1 - versione.revisione.release):\t";
read -r version;
[ ${#version} == 0 ] && version="0.0.1";

printf "Inserisci le note:\t";
read -r notes;
[ ${#notes} == 0 ] && notes="--/--";

printf "\
# $div$div
%s
#
%-20s%s
%-20s%s
%-20s%s
%-20s%s
%-20s%s
%-20s%s
%-20s%s
# $div$div\n" "#!/bin/bash" "# Titolo:" "$title" "# Descrizione:" "$description" "# Autore:" "$name" "# Data:" "$data" "# Versione:" "$version" "# Note:" "$notes" "# Versione bash:" "$BASH_VERSION" > "$title";

# rendi eseguibile lo script
chmod +x $title;

$clear;

select_editor;

exit $EXIT_SUCCESS;

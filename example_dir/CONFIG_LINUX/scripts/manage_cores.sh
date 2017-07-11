#!/bin/bash

# NOTA: questo scritp DEVE essere eseguito da gksudo per ottenere i privilegi necessari (vedi script ./check_psw.sh)
#####
# FUNZIONAMENTO: 4 operazioni possibili: n +  -->  abilita n cores del sistema;
#										 n -  -->  disabilita n cores del sistema;
#										 n °  -->  abilita cores_tot/n cores attivi nel del sistema;
#										 n /  -->  disabilita cores_tot/n cores attivi nel sistema;
#															 NOTA: di default n=2;
#										 °°   -->  abilita tutti i cores disattivati;
#										 //   -->  porta il sistema al numero di default (n=2) di cores attivi.



# presenza del tool zenity nel sistema
declare zen;
# dimensioni alert dialog
declare -r dialog_width=600;
declare -r dialog_height=20;
# timeout read
declare -r read_to=45;
# exit status
declare -r EXIT_SUCCESS=0;
declare -r EXIT_FAILURE=5;
# redir trash output
declare -r null=/dev/null;
# path di sistema contenente i files necessari
declare -r path=/sys/devices/system/cpu;
# operazione da performare
declare -i operation;
declare OP='?';
# numero TOTALI di cores presenti nel sistema
# tmp=(`lscpu | egrep 'CPU\(s\):'`);
# cores=${tmp[1]};
# oppure:
declare -r cores=`nproc --all`;
# nproc restituisce il numero di cpu ATTIVE
# 	si potrebbe anche elaborare meglio la stringa ottenuta dal comando lscpu
# varrà sempre metà del valore iniziale
declare -r cores_online=`nproc`;
# numero di cores di default
declare -r cores_default=2;
# numero di cores da gestire; input dell'utente
declare -i cores_to_manage=$cores_default;
# cores utili --> cores attivi
declare -i cores_available=$((cores - cores_online));



function usage {
	printf "\n";
	printf "`realpath $0` [cores to manage] [operations]\n";
	printf "\n";
	printf "\tCores to manage\n";
	printf "\t\tn :  numero di cores su cui operare (default n=2)\n";
	printf "\n";
	printf "\tOperations\n";
	printf "\t\tn + :  attiva n cores\n";
	printf "\t\tn - :  disattiva n cores\n";
	printf "\t\tn / :  disabilita cores_tot/n cores attivi del sistema\n";
	printf "\t\t  / :  come sopra ma con n=2\n";
	printf "\t\t // :  porta il sistema al numero di default (n=2) di cores attivi\n"
	printf "\t\tn ° :  abilita cores_tot*n cores del sistema\n";
	printf "\t\t  ° :  come sopra ma con n=2\n";
	printf "\t\t °° :  attiva tutti cores del sistema\n";
	printf "\n";
	printf "Esempio: ./`basename $0` + 3 -->  attiva 3 cores del sistema\n";
	printf "Esempio: ./`basename $0` / 3 -->  se ad esempio il sistema ha 12 cores attivi, ne verranno disattivati 4\n";

	exit $EXIT_SUCCESS;
}

# stampa una stringa con output su CLI e su GUI
# se il primo argomento è 0 --> stampa una scritta di errore
function print_str {
	reason="\t\t*** $2 ***\n";
	if [ "$1" == "0" ]; then
		printf "$reason";

		[ $zen == 0 ] &&
		zenity --width=$dialog_width --height=$dialog_height --error --text="$reason" &> $null;

		return $EXIT_FAILURE;
	fi

	printf "$1" && return $EXIT_SUCCESS;
}

# alert dialog con richiesta interazione utente
function decision {
	question="\t\t $1 \n";
	if [ $zen == 0 ]; then
		zenity --width=$dialog_width --height=$dialog_height --question --text="$question" &> $null &&
		return $EXIT_SUCCESS;
		return $EXIT_FAILURE;
	else
		printf "$question";
		printf "[y=procedi / others=annulla]\t";
		read -t $read_to choise || return $EXIT_FAILURE;

		[ "$choise" == "y" ] && return $EXIT_SUCCESS ||
		return $EXIT_FAILURE;
	fi
}

# scelta operazione
function get_op {
	case "$OP" in
		'+' | '°' | '°°' ) return 1 ;;
		'-' | '/' | '//' ) return 0 ;;
		* ) return -1 ;;
	esac
}

# gestione operazioni '+' e '*'
function enable_cores {
	get_op;
	operation=$?;
	[ $operation == -1 ] && return $EXIT_FAILURE;

	# l'indice parte da 1 perché la cpu0 non può essere
	# disabilitata per problemi di stabilità e sicurezza
	for ((j = 1; j < $cores && $cores_to_manage > 0; ++j)); do
		status_file=$path'/cpu'$j'/online';

		! [ -f "$status_file" ] &&
		! print_str 0 "Funzionalità non supportata dalla CPU (cpu$j)" &&
		return $EXIT_FAILURE;

		cpu_status=`cat $status_file`;
		if [ $cpu_status == 0 ]; then
			(echo $operation > $status_file) &> $null;

			[ $? != 1 ] &&
			! print_str 0 "Permessi non sufficienti per eseguire lo script" &&
			return $EXIT_FAILURE;

			cores_to_manage=$((cores_to_manage - 1));
		fi
	done
	return $EXIT_SUCCESS;
}

# gestione operazioni '-' e '/'
function disable_cores {
	get_op;
	operation=$?;
	[ $operation == -1 ] && return $EXIT_FAILURE;

	# l'indice parte da 1 perché la cpu0 non può essere
	# disabilitata per problemi di stabilità e sicurezza
	for ((j = $((cores - 1)); j > 0 && $cores_to_manage > 0; --j)); do
		status_file=$path'/cpu'$j'/online';

		! [ -f "$status_file" ] &&
		! print_str 0 "Funzionalità non supportata dalla CPU (cpu$j)" &&
		return $EXIT_FAILURE;

		cpu_status=`cat $status_file`;
		if [ $cpu_status == 1 ]; then
			(echo $operation > $status_file) &> $null;

			[ $? != 1 ] &&
			! print_str 0 "Permessi non sufficienti per eseguire lo script" &&
			return $EXIT_FAILURE;

			cores_to_manage=$((cores_to_manage - 1));
		fi
	done
	return $EXIT_SUCCESS;
}



# controllo presenza tools necessari per l'operazione
which egrep nproc 1> $null;
[ $? != 0 ] && ! print_str 0 "Tool egrep o nproc non presenti nel sistema" && exit $EXIT_FAILURE;
which zenity 1> $null;
zen=$?;
# verifica numero argomenti ricevuti
(
([ $# -gt 2 ] && ! print_str 0 "Troppi argomenti ricevuti!") ||
([ $# -lt 1 ] && ! print_str 0 "Argomenti mancanti!")
) && usage;



# parsing input utente
while [ $# -gt 0 ]; do
	case "$1" in
		'+' | '°' | '°°' )
			[ "$OP" == "?" ] && OP=$1 && shift && continue;

			! print_str 0 "Errore interno sconosciuto" && exit $EXIT_FAILURE;
			;;

		'-' | '/' | '//' )
			[ "$OP" == "?" ] && OP=$1 && shift && continue;

			! print_str 0 "Errore interno sconosciuto" && exit $EXIT_FAILURE;
			;;

		[0-9] )
			cores_to_manage=$1;
			shift;
			;;

		* )
			! print_str 0 "Sintassi errata!" && usage;
			;;
	esac
done

# verifica presenza operazione
[ "$OP" == "?" ] && ! print_str 0 "Operazione non specificata." && exit $EXIT_FAILURE;

# gestione operazioni
case "$OP" in
	'+' )
		# controllo sul numero di cores da gestire
		[ $cores_to_manage -gt $cores_available ] &&
		! print_str 0 "Errore! Non è possibile attivare più di $cores_available cores." &&
		exit $EXIT_FAILURE;

		enable_cores || exit $EXIT_FAILURE;
		;;

	'°' )
		# controllo sul numero di cores da gestire
		cores_to_manage=$((cores_online * cores_to_manage));
		[ $cores_to_manage -gt $cores_available ] &&
		! print_str 0 "Errore! Non è possibile attivare più di $cores_available cores." &&
		exit $EXIT_FAILURE;

		enable_cores || exit $EXIT_FAILURE;
		;;

	'°°' )
		# numero di cores da gestire
		cores_to_manage=$cores_available;

		enable_cores || exit $EXIT_FAILURE;
		;;

	'-' )
		# controllo sul numero di cores da gestire
		[ $cores_to_manage -ge $cores_online ] &&
		! print_str 0 "Errore! Non è possibile disattivare più di $cores_online cores." &&
		exit $EXIT_FAILURE;

		# verifica che ci sia un numero sufficiente di cores da poter gestire
		if [ $((cores_online - cores_to_manage)) -lt 2 ]; then
			decision "Attenzione: numero di cores online=$cores_online;
			            numero di cores da disattivare=$cores_to_manage.\n\t\t Procedere comunque?" ||
			exit $EXIT_FAILURE;
		fi


		disable_cores || exit $EXIT_FAILURE;
		;;

	'/' )
		# controllo sul numero di cores da gestire
		cores_to_manage=$((cores_online / cores_to_manage));
		[ $cores_to_manage -ge $cores_online ] &&
		! print_str 0 "Errore! Non è possibile disattivare più di $cores_online cores." &&
		exit $EXIT_FAILURE;

		# verifica che ci sia un numero sufficiente di cores da poter gestire
		cores_to_use=$((cores_online - cores_to_manage));
		if [ $cores_to_use -ge 0 ] && [ $cores_to_use -lt 2 ]; then
			decision "Attenzione: numero di cores online=$cores_online;
			            numero di cores da disattivare=$cores_to_manage.\n\t\t Procedere comunque?" ||
			exit $EXIT_FAILURE;
		fi

		disable_cores || exit $EXIT_FAILURE;
		;;

	'//' )
		# numero di cores da gestire
		cores_to_manage=$((cores_online - cores_default));

		# verifica che ci sia un numero sufficiente di cores da poter gestire
		if [ $cores_to_manage -lt 0 ]; then
			if decision "Attenzione: numero di cores online=$cores_online.\n\t\t Vuoi portare il numero di cores attivi a $cores_default?"; then
				cores_to_manage=1; OP='+';
				enable_cores && exit $EXIT_SUCCESS ||
				exit $EXIT_FAILURE;
			fi
		fi

		disable_cores || exit $EXIT_FAILURE;
		;;
esac

# successo
exit $EXIT_SUCCESS;

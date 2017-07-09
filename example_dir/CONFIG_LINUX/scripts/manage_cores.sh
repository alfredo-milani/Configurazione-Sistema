#!/bin/bash

# NOTA: questo scritp DEVE essere eseguito da gksudo per ottenere i privilegi necessari
# Questo script è usato per disattivare temporanemante la metà dei threads di una CPU sse sono >= 2

# FUNZIONAMENTO: se questo script non riceve come argomento alcun valore --> alla prima invocazione: disabilita metà dei cores attivi
# 																			 alla seconda invocazione: riabilita i cores non attivi
# 				 se riceve un valore --> valore '1': attiva tutti i cores disabilitati
# 				 						 valore '0': disabilita

# controllo presenza tools
which egrep nproc 1> /dev/null;
if [ $? != 0 ]; then
	err_str="Tool egrep o nproc non presenti nel sistema";
	echo $err_str;
	zenity --error --text="$err_str";
	exit 5;
fi



# numero TOTALI di cores presenti nel sistema
# tmp=(`lscpu | egrep 'CPU\(s\):'`);
# cores=${tmp[1]};
# oppure:
cores=`nproc --all`;
# nproc restituisce il numero di cpu ATTIVE
# 	si potrebbe anche elaborare meglio la stringa ottenuta dal comando lscpu
# varrà sempre metà del valore iniziale
cores_online=`nproc`;
# numero di cores da disattivare
cores_to_change=$(($cores_online >> 1));



if  [ $cores -le 2 ] || ([ $cores_online -le 2 ] &&
	[ ${#1} != 0 ] && [ $1 != 1 ]); then
	# errore
	err_str='Attenzione: numero di cores online minore o uguale a 2!';
	zenity --error --text="$err_str";
	echo $err_str;
	exit 5;
fi



# scelta operazione: 1 --> attivazione; 0 --> disattivazione cores
if [ ${#1} != 0 ]; then
	# disabilitazione metà cores alla volta
	if [ $1 == 0 ]; then
		# disabilitazione
		cores=$cores_online;
	elif [ $1 == 1 ]; then
		cores_to_change=$(($cores - $cores_online));
	else
		err_str="Argomento ---  $1  --- non valido";
		zenity --error --text="$err_str";
		echo $err_str;
		exit 5;
	fi

	op=$1;
else
	# disabilitazione metà cores
	if [ $cores_online -lt $cores ]; then
		# abilitazione
		op=1;
		cores_to_change=$(($cores - $cores_online));
	else
		# disabilitazione
		op=0;
	fi
fi



# path di sistema contenente i files necessari
path=/sys/devices/system/cpu;
for (( ; $cores_to_change > 0; cores_to_change=$(($cores_to_change - 1)) )); do
	# disabilito i cores partendo dagli ultimi
	echo $op > $path'/cpu'$(($cores - 1))'/online';
	cores=$(($cores - 1));
done



# successo
exit 0;

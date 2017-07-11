#!/bin/bash

# Autore: Alfredo Milani
# Data: 15 - 05 - 2017

gksudo $@;

if [ $? == 1 ]; then
    err_str="Password sbagliata";
    echo $err_str;
    zenity --error --text="$err_str" &> /dev/null;
    exit 1;
fi

exit 0;

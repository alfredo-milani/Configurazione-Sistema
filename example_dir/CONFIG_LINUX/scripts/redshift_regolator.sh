#!/bin/bash

icon_path="/usr/share/icons/Adwaita/48x48/status/display-brightness-symbolic.symbolic.png";
tool="redshift";
lat=41.6;
long=13.4;
daytime=5000;
nighttime=3000;
tool_is_on=(`ps -A | grep -w $tool`);
pid="${tool_is_on[0]}";

if [ ${#pid} != 0 ]; then
    # str="Chiusura $tool";
    # zenity --notification --window-icon="$icon_path" --text="$str";
    kill -15 $pid;
else
    # str="Avvio $tool";
    # zenity --notification --window-icon="$icon_path" --text="$str";
    $tool -l $lat:$long -t $daytime:$nighttime;
fi

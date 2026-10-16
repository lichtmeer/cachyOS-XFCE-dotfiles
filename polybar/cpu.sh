#!/bin/bash
S=/tmp/polybar-cpu-prev.$UID
read -r _ a b c d e f g h i < /proc/stat
T=$((a+b+c+d+e+f+g+h)); I=$((d+e))
P=0
if [ -r "$S" ]; then
    read -r PT PI < "$S"
    DT=$((T-PT)); DI=$((I-PI))
    [ "$DT" -gt 0 ] && P=$((100*(DT-DI)/DT)); [ "$P" -gt 100 ] && P=100
fi
echo "$T $I" > "$S"
printf '\uec19 %%{F#C3C7CF}%%{F#E6E1E5}%02d%%\n' "$P"

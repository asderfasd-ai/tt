#!/bin/bash
LOGFILE="spells.log"
ACTIVE_FILE="active_spells.txt"
> "$LOGFILE"
> "$ACTIVE_FILE"

while read -r line; do
    if [[ $line =~ ([^[:space:]]+[[:space:]]+)?([0-5]?[0-9]):([0-5][0-9]) ]]; then
        SPELL="${BASH_REMATCH[1]:-Spell}"
        MIN="${BASH_REMATCH[2]}"
        SEC="${BASH_REMATCH[3]}"
        TOTAL=$((MIN*60 + SEC))
        END=$(( $(date +%s) + TOTAL ))
        echo "$(date '+%H:%M:%S') | $SPELL($MIN:$SEC) | ends $(date -d @$END '+%H:%M:%S')" | tee -a "$LOGFILE"
        echo "$END|$SPELL" >> "$ACTIVE_FILE"
    fi
done

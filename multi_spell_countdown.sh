#!/bin/bash
LOGFILE="spells.log"
ACTIVE_FILE="active_spells.txt"

(tail -f "$LOGFILE" &)

while true; do
    sleep 1
    NOW=$(date +%s)
    > temp_active.txt
    while IFS='|' read -r end spell || [ -n "$end" ]; do
        [ -z "$end" ] && continue
        if [ "$end" -gt "$NOW" ]; then
            rem=$((end - NOW))
            echo "$end|$spell|$rem" >> temp_active.txt
        fi
    done < "$ACTIVE_FILE"
    mv temp_active.txt "$ACTIVE_FILE" 2>/dev/null
    
    clear
    echo "=== Active Spell Timers ($(date '+%H:%M:%S')) ==="
    while IFS='|' read -r end spell rem || [ -n "$end" ]; do
        [ -z "$end" ] && continue
        printf "   %s → %02d:%02d\n" "$spell" $((rem/60)) $((rem%60))
    done < "$ACTIVE_FILE"
    echo "-------------------------------------"
done

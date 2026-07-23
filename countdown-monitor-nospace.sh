#!/bin/bash
# spelltest-countdown.sh - Robust version with flexible whitespace

INPUT_FILE="spelltest.log"
REFRESH=1

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: $INPUT_FILE not found!"
    exit 1
fi

# Load original lines
mapfile -t ORIGINAL_LINES < "$INPUT_FILE"

# Store initial countdown duration for each line
declare -A INITIAL_SECONDS

if [[ $line =~ \[([0-9]+):([0-9]{2}):([0-9]{2})\]$ ]]; then
    # hh:mm:ss
    INITIAL_SECONDS[$i]=$(( BASH_REMATCH[1] * 3600 +
                            BASH_REMATCH[2] * 60 +
                            BASH_REMATCH[3] ))
elif [[ $line =~ \[([0-9]+):([0-9]{2})\]$ ]]; then
    # mm:ss
    INITIAL_SECONDS[$i]=$(( BASH_REMATCH[1] * 60 +
                            BASH_REMATCH[2] ))
else
    INITIAL_SECONDS[$i]=0
fi

START_TIME=$(date +%s)

while true; do
    clear
    echo "=== Live Spell Countdown ==="
    echo "Updated: $(date '+%I:%M:%S %p')"
    echo "────────────────────────────────────────────"

    ELAPSED=$(( $(date +%s) - START_TIME ))

    for i in "${!ORIGINAL_LINES[@]}"; do
        line="${ORIGINAL_LINES[$i]}"
        [[ -z "$line" ]] && continue

        # Very flexible match - works with extra spaces
        if [[ $line =~ ^(.*[^[:space:]])[[:space:]]*\[([0-9:]+)\][[:space:]]*$ ]]; then
#        if [[ $line =~ ^(.*[^[:space:]])[[:space:]]*\[([0-9:]+)\][[:space:]]*$ ]]; then
            prefix="${BASH_REMATCH[1]}"          # Everything before the [timer]
            initial_sec="${INITIAL_SECONDS[$i]:-0}"

            remaining=$(( initial_sec - ELAPSED ))

            if [ $remaining -le 0 ]; then
                countdown="EXPIRED"
            elif [ $remaining -ge 3600 ]; then
                printf -v countdown "%d:%02d:%02d" $((remaining/3600)) $(((remaining%3600)/60)) $((remaining%60))
            else
                printf -v countdown "%02d:%02d" $((remaining/60)) $((remaining%60))
            fi

            echo "${prefix} [${countdown}]"
        else
            # Fallback: print original line if it doesn't match
            echo "$line"
        fi
    done

    echo "────────────────────────────────────────────"
    sleep "$REFRESH"
done

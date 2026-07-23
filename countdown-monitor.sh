#!/bin/bash
# countdown-monitor.sh

INPUT_FILE="spelltest.log"
REFRESH=1

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: $INPUT_FILE not found!"
    exit 1
fi

# Read original lines
mapfile -t ORIGINAL_LINES < "$INPUT_FILE"

declare -A INITIAL_SECONDS

#
# Parse the original timers
#
for i in "${!ORIGINAL_LINES[@]}"; do
    line="${ORIGINAL_LINES[$i]}"

    # Strip ANSI escape sequences
    clean_line=$(printf '%s' "$line" | sed -E 's/\x1B\[[0-9;]*[[:alpha:]]//g')

    if [[ $clean_line =~ \[([0-9]+):([0-9]{2}):([0-9]{2})\][[:space:]]*$ ]]; then
        INITIAL_SECONDS[$i]=$(( \
            BASH_REMATCH[1]*3600 +
            BASH_REMATCH[2]*60 +
            BASH_REMATCH[3] ))

    elif [[ $clean_line =~ \[([0-9]+):([0-9]{2})\][[:space:]]*$ ]]; then
        INITIAL_SECONDS[$i]=$(( \
            BASH_REMATCH[1]*60 +
            BASH_REMATCH[2] ))

    else
        INITIAL_SECONDS[$i]=0
    fi
done

START_TIME=$(date +%s)

while true
do
    clear


    ELAPSED=$(( $(date +%s) - START_TIME ))

    for i in "${!ORIGINAL_LINES[@]}"
    do
        line="${ORIGINAL_LINES[$i]}"

        # Strip ANSI sequences for parsing
        clean_line=$(printf '%s' "$line" | sed -E 's/\x1B\[[0-9;]*[[:alpha:]]//g')

        if [[ $clean_line =~ ^(.*[^[:space:]])[[:space:]]*\[[0-9:]+\][[:space:]]*$ ]]; then

            prefix="${BASH_REMATCH[1]}"

            remaining=$(( INITIAL_SECONDS[$i] - ELAPSED ))

            if (( remaining <= 0 )); then
                countdown="EXPIRED"
            elif (( remaining >= 3600 )); then
                printf -v countdown "%d:%02d:%02d" \
                    $((remaining/3600)) \
                    $(((remaining%3600)/60)) \
                    $((remaining%60))
            else
                printf -v countdown "%02d:%02d" \
                    $((remaining/60)) \
                    $((remaining%60))
            fi

            echo "${prefix} [${countdown}]"
        else
            echo "$clean_line"
        fi
    done

    sleep "$REFRESH"
done

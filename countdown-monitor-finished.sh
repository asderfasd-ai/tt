#!/bin/bash
# countdown-monitor.sh

INPUT_FILE="spelltest.log"
REFRESH=1

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: $INPUT_FILE not found!"
    exit 1
fi

# Colors
PURPLE='\033[1;35m'
CYAN='\033[1;36m'
GREEN='\033[1;32m'
RESET='\033[0m'

LAST_MTIME=0
CHECK_INTERVAL=10
last_check=0

reload_log() {
    mapfile -t ORIGINAL_LINES < "$INPUT_FILE"
    INITIAL_SECONDS=()
    for i in "${!ORIGINAL_LINES[@]}"; do
        line="${ORIGINAL_LINES[$i]}"
        clean_line=$(printf '%s' "$line" | sed -E 's/\\x1B\\[[0-9;]*[[:alpha:]]//g')
        if [[ $clean_line =~ \[([0-9]+):([0-9]{2}):([0-9]{2})\][[:space:]]*$ ]]; then INITIAL_SECONDS[$i]=$((BASH_REMATCH[1]*3600+BASH_REMATCH[2]*60+BASH_REMATCH[3]));
        elif [[ $clean_line =~ \[([0-9]+):([0-9]{2})\][[:space:]]*$ ]]; then INITIAL_SECONDS[$i]=$((BASH_REMATCH[1]*60+BASH_REMATCH[2])); else INITIAL_SECONDS[$i]=0; fi; done
    START_TIME=$(date +%s)
}
reload_log
LAST_MTIME=$(stat -c %Y "$INPUT_FILE")

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

    now=$(date +%s)
    if (( now-last_check>=CHECK_INTERVAL )); then last_check=$now; mtime=$(stat -c %Y "$INPUT_FILE"); if (( mtime!=LAST_MTIME )); then LAST_MTIME=$mtime; reload_log; fi; fi

    ELAPSED=$(( $(date +%s) - START_TIME ))

    for i in "${!ORIGINAL_LINES[@]}"
    do
        line="${ORIGINAL_LINES[$i]}"

        # Strip ANSI sequences for parsing
        clean_line=$(printf '%s' "$line" | sed -E 's/\x1B\[[0-9;]*[[:alpha:]]//g')

        if [[ $clean_line =~ ^[[:space:]]*([^[]+)\(([[:space:]]*[0-9]+)\)[[:space:]]*\[[0-9:]+\][[:space:]]*$ ]]; then

            spell="${BASH_REMATCH[1]}"
            value="${BASH_REMATCH[2]}"

            # Trim trailing spaces from spell name
            spell="${spell%"${spell##*[![:space:]]}"}"

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

#            printf "%b%-24s%b (%b%4s%b) [%b%s%b]\n" \
            printf "%b%-24s%b (%b%4s%b) [%b%s%b]\n" \
                "$PURPLE" "$spell" "$RESET" \
                "$CYAN" "$value" "$RESET" \
                "$GREEN" "$countdown" "$RESET"

        else
            echo "$clean_line"
        fi
    done

    sleep "$REFRESH"
done

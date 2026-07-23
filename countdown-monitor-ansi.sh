#!/bin/bash
INPUT_FILE="spelltest.log"
REFRESH=1

[[ -f "$INPUT_FILE" ]] || { echo "Missing $INPUT_FILE"; exit 1; }

mapfile -t ORIGINAL_LINES < "$INPUT_FILE"

declare -A INITIAL_SECONDS

strip_ansi() {
    sed -E 's/\x1B\[[0-9;]*[[:alpha:]]//g'
}

for i in "${!ORIGINAL_LINES[@]}"; do
    clean=$(printf '%s' "${ORIGINAL_LINES[$i]}" | strip_ansi)

    if [[ $clean =~ \[([0-9]+):([0-9]{2}):([0-9]{2})\][[:space:]]*$ ]]; then
        INITIAL_SECONDS[$i]=$((BASH_REMATCH[1]*3600+BASH_REMATCH[2]*60+BASH_REMATCH[3]))
    elif [[ $clean =~ \[([0-9]+):([0-9]{2})\][[:space:]]*$ ]]; then
        INITIAL_SECONDS[$i]=$((BASH_REMATCH[1]*60+BASH_REMATCH[2]))
    else
        INITIAL_SECONDS[$i]=0
    fi
done

START_TIME=$(date +%s)

while true; do
    clear
    elapsed=$(( $(date +%s)-START_TIME ))

    for i in "${!ORIGINAL_LINES[@]}"; do
        original="${ORIGINAL_LINES[$i]}"
        clean=$(printf '%s' "$original" | strip_ansi)

        remaining=$(( INITIAL_SECONDS[$i]-elapsed ))

        if (( remaining<=0 )); then
            timer="EXPIRED"
        elif (( remaining>=3600 )); then
            printf -v timer "%d:%02d:%02d" $((remaining/3600)) $(((remaining%3600)/60)) $((remaining%60))
        else
            printf -v timer "%02d:%02d" $((remaining/60)) $((remaining%60))
        fi

        # Replace only the timer digits inside the original ANSI-colored line.
        NEW_TIMER="$timer" output=$(printf '%s' "$original" | perl -pe '
            BEGIN{$t=$ENV{"NEW_TIMER"}}
            s/(\[[^\d]*)(\d+(?::\d{2}){1,2})(.*?\])/$1.$t.$3/e;
        ' )
        echo "$output"
    done

    sleep "$REFRESH"
done

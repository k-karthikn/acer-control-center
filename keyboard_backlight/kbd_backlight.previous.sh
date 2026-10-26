#!/usr/bin/env bash

# Paths and Configuration
BL_DIR="/sys/class/leds/white:kbd_backlight"
BL_FILE="$BL_DIR/brightness"
MAX_FILE="$BL_DIR/max_brightness"
STATE_FILE="$HOME/.cache/kbd_backlight_state"

# Ensure the cache directory exists
mkdir -p "$(dirname "$STATE_FILE")"

# Read current values (fallback to 5 if max_brightness is unreadable)
CUR_VAL=$(cat "$BL_FILE" 2>/dev/null || echo 0)
MAX_VAL=$(cat "$MAX_FILE" 2>/dev/null || echo 5)

set_brightness() {
    echo "$1" > "$BL_FILE"
}

save_state() {
    if [ "$1" -gt 0 ]; then
        echo "$1" > "$STATE_FILE"
    fi
}

get_last_state() {
    if [ -f "$STATE_FILE" ]; then
        val=$(cat "$STATE_FILE")
        # Ensure the cached value is strictly greater than 0
        if [ -n "$val" ] && [ "$val" -gt 0 ]; then
            echo "$val"
            return
        fi
    fi
    echo 1 # Fallback default state
}

case "$1" in
    up)
        if [ "$CUR_VAL" -lt "$MAX_VAL" ]; then
            NEW_VAL=$((CUR_VAL + 1))
            set_brightness "$NEW_VAL"
            save_state "$NEW_VAL"
        fi
        ;;
    down)
        if [ "$CUR_VAL" -gt 0 ]; then
            NEW_VAL=$((CUR_VAL - 1))
            set_brightness "$NEW_VAL"
            save_state "$NEW_VAL"
        fi
        ;;
    toggle)
        if [ "$CUR_VAL" -eq 0 ]; then
            RESTORE_VAL=$(get_last_state)
            set_brightness "$RESTORE_VAL"
        else
            save_state "$CUR_VAL"
            set_brightness 0
        fi
        ;;
    *)
        echo "Usage: $0 {up|down|toggle}"
        exit 1
        ;;
esac

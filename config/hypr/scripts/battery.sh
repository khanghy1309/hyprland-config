#!/usr/bin/env bash
# In mức pin, ví dụ "BAT 82%" hoặc "BAT 82% ↑" khi đang sạc. Máy bàn không có pin thì không in gì.
for b in /sys/class/power_supply/BAT*; do
    [ -r "$b/capacity" ] || continue
    cap="$(cat "$b/capacity")"
    st="$(cat "$b/status" 2>/dev/null)"
    if [ "$st" = "Charging" ]; then
        printf 'BAT %s%% ↑\n' "$cap"
    else
        printf 'BAT %s%%\n' "$cap"
    fi
    exit 0
done

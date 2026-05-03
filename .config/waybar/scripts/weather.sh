#!/usr/bin/env bash

set -u -o pipefail

json_escape() {
    local value=$1
    value=${value//\\/\\\\}
    value=${value//\"/\\\"}
    value=${value//$'\n'/\\n}
    value=${value//$'\r'/}
    printf '%s' "$value"
}

emit_json() {
    local text=$1
    local tooltip=$2
    local css_class=${3:-normal}

    if command -v jq >/dev/null 2>&1; then
        jq -nc \
            --arg text "$text" \
            --arg tooltip "$tooltip" \
            --arg class "$css_class" \
            '{text: $text, tooltip: $tooltip, class: $class}'
        return
    fi

    printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' \
        "$(json_escape "$text")" \
        "$(json_escape "$tooltip")" \
        "$(json_escape "$css_class")"
}

if ! command -v curl >/dev/null 2>&1; then
    emit_json "󰖐 N/A" "Missing dependency: curl" "red"
    exit 0
fi

weather_raw=$(curl --silent --show-error \
    --connect-timeout 5 \
    --max-time 10 \
    "https://wttr.in/?format=%C|%t|%f|%h|%w|%l" 2>/dev/null || true)

if [ -z "$weather_raw" ]; then
    emit_json "󰖐 N/A" "Weather unavailable (network/API error)." "yellow"
    exit 0
fi

IFS='|' read -r condition temp feels humidity wind location <<EOF
$weather_raw
EOF

if [ -z "${condition:-}" ] || [ -z "${temp:-}" ]; then
    emit_json "󰖐 N/A" "Weather parse error." "yellow"
    exit 0
fi

condition_lc=$(printf '%s' "$condition" | tr '[:upper:]' '[:lower:]')
icon="󰖐"
css_class="mild"

if [[ "$condition_lc" == *"thunder"* || "$condition_lc" == *"storm"* ]]; then
    icon="󰙾"
    css_class="storm"
elif [[ "$condition_lc" == *"snow"* || "$condition_lc" == *"blizzard"* || "$condition_lc" == *"sleet"* || "$condition_lc" == *"ice"* ]]; then
    icon="󰼶"
    css_class="snow"
elif [[ "$condition_lc" == *"rain"* || "$condition_lc" == *"drizzle"* || "$condition_lc" == *"shower"* ]]; then
    icon="󰖗"
    css_class="rain"
elif [[ "$condition_lc" == *"fog"* || "$condition_lc" == *"mist"* || "$condition_lc" == *"haze"* ]]; then
    icon="󰖑"
    css_class="fog"
elif [[ "$condition_lc" == *"cloud"* || "$condition_lc" == *"overcast"* ]]; then
    icon="󰖐"
    css_class="cloudy"
elif [[ "$condition_lc" == *"clear"* || "$condition_lc" == *"sun"* ]]; then
    icon="󰖙"
    css_class="sunny"
fi

temp_num=$(printf '%s' "$temp" | sed -E 's/[^0-9+-]//g')
if [[ "$temp_num" =~ ^-?[0-9]+$ ]]; then
    if [ "$temp_num" -ge 35 ]; then
        css_class="hot"
    elif [ "$temp_num" -le 10 ] && [ "$css_class" = "mild" ]; then
        css_class="cold"
    fi
fi

display_temp=$(printf '%s' "$temp" | tr -d '+')
weather_text="${icon} ${display_temp}"
tooltip="Location: ${location:-Unknown}
Condition: ${condition}
Temp: ${temp}
Feels: ${feels:-N/A}
Humidity: ${humidity:-N/A}
Wind: ${wind:-N/A}"

emit_json "$weather_text" "$tooltip" "$css_class"

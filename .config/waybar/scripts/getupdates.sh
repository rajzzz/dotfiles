#!/usr/bin/env bash

set -u -o pipefail

threshold_yellow=15
threshold_red=100

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
    local css_class=$3

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

missing_deps=()
for cmd in checkupdates yay; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        missing_deps+=("$cmd")
    fi
done

if [ "${#missing_deps[@]}" -gt 0 ]; then
    emit_json "0" "Missing dependency: ${missing_deps[*]}" "red"
    exit 0
fi

strip_ansi='s/\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]//g'
arch_updates=$(checkupdates 2>/dev/null || true)
aur_updates=$(yay -Qua 2>/dev/null || true)

arch_updates=$(printf '%s' "$arch_updates" | sed -r "$strip_ansi")
aur_updates=$(printf '%s' "$aur_updates" | sed -r "$strip_ansi")

count_lines() {
    local value=$1
    if [ -z "$value" ]; then
        printf '0'
    else
        printf '%s\n' "$value" | sed '/^[[:space:]]*$/d' | wc -l
    fi
}

updates_arch=$(count_lines "$arch_updates")
updates_aur=$(count_lines "$aur_updates")
updates=$((updates_arch + updates_aur))

list_updates=""
if [ "$updates_arch" -gt 0 ]; then
    list_updates=$arch_updates
fi
if [ "$updates_aur" -gt 0 ]; then
    if [ -n "$list_updates" ]; then
        list_updates+=$'\n'
    fi
    list_updates+=$aur_updates
fi

if [ "$updates" -lt "$threshold_yellow" ]; then
    css_class="green"
elif [ "$updates" -lt "$threshold_red" ]; then
    css_class="yellow"
else
    css_class="red"
fi

if [ -n "$list_updates" ]; then
    tooltip="Updates (<span size=\"small\">${updates} package(s)</span>):"$'\n'"${list_updates}"
else
    tooltip="System is up to date."
fi

emit_json "$updates" "$tooltip" "$css_class"

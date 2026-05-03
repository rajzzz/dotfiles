#!/usr/bin/env bash

set -u -o pipefail

threshold_yellow=5
threshold_red=50
token_file="$HOME/.config/.secrets/notifications.token"

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

if ! command -v curl >/dev/null 2>&1; then
    emit_json "0" "Missing dependency: curl" "red"
    exit 0
fi

if [ ! -r "$token_file" ]; then
    emit_json "0" "Missing GitHub token at $token_file" "yellow"
    exit 0
fi

token=$(tr -d '\r\n' < "$token_file")
if [ -z "$token" ]; then
    emit_json "0" "GitHub token file is empty." "yellow"
    exit 0
fi

response_file=$(mktemp)
http_code=$(curl --silent --show-error \
    --connect-timeout 5 \
    --max-time 10 \
    --user "token:$token" \
    --header "Accept: application/vnd.github+json" \
    --header "X-GitHub-Api-Version: 2022-11-28" \
    --output "$response_file" \
    --write-out "%{http_code}" \
    "https://api.github.com/notifications" 2>/dev/null || true)

if [ "$http_code" != "200" ]; then
    rm -f "$response_file"
    emit_json "0" "GitHub API request failed (HTTP $http_code)." "yellow"
    exit 0
fi

if command -v jq >/dev/null 2>&1; then
    count=$(jq 'length' "$response_file" 2>/dev/null || printf '0')
else
    count=$(grep -o '"id"' "$response_file" | wc -l | tr -d ' ')
fi
rm -f "$response_file"

if ! [[ "$count" =~ ^[0-9]+$ ]]; then
    count=0
fi

css_class="green"
if [ "$count" -gt "$threshold_red" ]; then
    css_class="red"
elif [ "$count" -gt "$threshold_yellow" ]; then
    css_class="yellow"
fi

tooltip="GitHub notifications: ${count}"
emit_json "$count" "$tooltip" "$css_class"

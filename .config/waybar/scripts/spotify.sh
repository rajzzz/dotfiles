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

escape_pango() {
    local value=$1
    value=${value//&/&amp;}
    value=${value//</&lt;}
    value=${value//>/&gt;}
    printf '%s' "$value"
}

map_rgb_to_class() {
    local r=$1
    local g=$2
    local b=$3

    local max=$r
    local min=$r
    if [ "$g" -gt "$max" ]; then max=$g; fi
    if [ "$b" -gt "$max" ]; then max=$b; fi
    if [ "$g" -lt "$min" ]; then min=$g; fi
    if [ "$b" -lt "$min" ]; then min=$b; fi

    local delta=$((max - min))
    if [ "$max" -lt 30 ]; then
        printf 'spotify-dark'
        return
    fi
    if [ "$delta" -lt 20 ]; then
        printf 'spotify-muted'
        return
    fi

    if [ "$r" -ge "$g" ] && [ "$r" -ge "$b" ]; then
        if [ "$g" -gt $((b + 25)) ]; then
            printf 'spotify-orange'
        elif [ "$b" -gt $((g + 25)) ]; then
            printf 'spotify-magenta'
        else
            printf 'spotify-red'
        fi
        return
    fi

    if [ "$g" -ge "$r" ] && [ "$g" -ge "$b" ]; then
        if [ "$b" -gt $((r + 25)) ]; then
            printf 'spotify-teal'
        else
            printf 'spotify-green'
        fi
        return
    fi

    if [ "$r" -gt $((g + 25)) ]; then
        printf 'spotify-purple'
    else
        printf 'spotify-blue'
    fi
}

get_spotify_class() {
    local art_url=$1
    local cache_dir=/tmp/waybar-spotify
    mkdir -p "$cache_dir"

    if [ -z "$art_url" ]; then
        printf 'spotify-default'
        return
    fi

    local key
    key=$(printf '%s' "$art_url" | sha1sum | awk '{print $1}')
    local cache_file="${cache_dir}/class-${key}.txt"

    if [ -r "$cache_file" ]; then
        cat "$cache_file"
        return
    fi

    local image_file="${cache_dir}/cover-${key}.img"
    if [[ "$art_url" == file://* ]]; then
        local local_path=${art_url#file://}
        if [ -r "$local_path" ]; then
            cp "$local_path" "$image_file" 2>/dev/null || true
        fi
    else
        if command -v curl >/dev/null 2>&1; then
            curl -L --silent --show-error --connect-timeout 4 --max-time 8 \
                --output "$image_file" "$art_url" >/dev/null 2>&1 || true
        fi
    fi

    if [ ! -s "$image_file" ] || ! command -v magick >/dev/null 2>&1; then
        printf 'spotify-default' | tee "$cache_file" >/dev/null
        return
    fi

    local rgb
    rgb=$(magick "$image_file" -resize 1x1\! \
        -format "%[fx:int(255*r+.5)],%[fx:int(255*g+.5)],%[fx:int(255*b+.5)]" info:- 2>/dev/null || true)

    if ! printf '%s' "$rgb" | grep -Eq '^[0-9]+,[0-9]+,[0-9]+$'; then
        printf 'spotify-default' | tee "$cache_file" >/dev/null
        return
    fi

    local r g b
    IFS=',' read -r r g b <<EOF
$rgb
EOF
    local mapped_class
    mapped_class=$(map_rgb_to_class "$r" "$g" "$b")
    printf '%s' "$mapped_class" | tee "$cache_file" >/dev/null
}

if ! command -v playerctl >/dev/null 2>&1; then
    exit 0
fi

status=$(playerctl --player=spotify status 2>/dev/null || true)
if [ "$status" != "Playing" ] && [ "$status" != "Paused" ]; then
    emit_json " Idle" "Spotify is not currently playing." "spotify-default"
    exit 0
fi

artist=$(playerctl --player=spotify metadata artist 2>/dev/null || true)
title=$(playerctl --player=spotify metadata title 2>/dev/null || true)
album=$(playerctl --player=spotify metadata album 2>/dev/null || true)
art_url=$(playerctl --player=spotify metadata mpris:artUrl 2>/dev/null || true)

if [ -z "$artist" ] && [ -z "$title" ]; then
    emit_json " Spotify" "No track metadata available." "spotify-default"
    exit 0
fi

css_class=$(get_spotify_class "$art_url")
icon=""
if [ "$status" = "Paused" ]; then
    icon=""
else
    icon=""
fi

artist_escaped=$(escape_pango "${artist}")
title_escaped=$(escape_pango "${title}")
album_escaped=$(escape_pango "${album}")

text=" ${icon} ${artist_escaped} - ${title_escaped}"
tooltip="Status: ${status}
Artist: ${artist_escaped:-Unknown}
Title: ${title_escaped:-Unknown}
Album: ${album_escaped:-Unknown}"

emit_json "$text" "$tooltip" "$css_class"

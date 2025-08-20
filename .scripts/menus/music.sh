#!/bin/bash

# Konstanta global
ENABLED_COLOR="#9ece6a"
DISABLED_COLOR="#f7768e"
ICON_PLAY=""
ICON_STOP=""
ICON_PLAYLIST=""
ICON_ADD=""

# Path penting
PID_FILE="/tmp/mpv_music.pid"
SCRIPTS_DIR="$HOME/.scripts"
PLAYLIST_FILE="$SCRIPTS_DIR/music-fav.txt"

# Buat folder skrip jika belum ada
mkdir -p "$SCRIPTS_DIR"

# Fungsi untuk menghentikan musik
stop_music() {
    if [[ -f $PID_FILE ]]; then
        local pid=$(cat "$PID_FILE")
        if kill "$pid" 2>/dev/null; then
            rm -f "$PID_FILE"
            notify-send "Music Player" "Music stopped successfully."
        else
            rm -f "$PID_FILE"
            notify-send "Music Player" "Music process not found. PID file removed."
        fi
    else
        notify-send "Music Player" "No music is currently running."
    fi
}

# Fungsi untuk memutar musik dari URL
start_music() {
    local url="$1"

    if [[ -f $PID_FILE ]]; then
        notify-send "Music Player" "Music is already running."
        return
    fi

    nohup mpv --really-quiet --ytdl-format=ba --loop "$url" > /dev/null 2>&1 &
    echo $! > "$PID_FILE"
    notify-send "Music Player" "Now playing:\n$url"
}

# Fungsi untuk memutar playlist
start_playlist() {
    if [[ ! -f $PLAYLIST_FILE ]]; then
        notify-send "Music Player" "Playlist not found at $PLAYLIST_FILE"
        return
    fi

    if [[ -f $PID_FILE ]]; then
        notify-send "Music Player" "Music is already running."
        return
    fi

    nohup mpv --really-quiet --ytdl-format=ba --loop-playlist=inf --playlist="$PLAYLIST_FILE" > /dev/null 2>&1 &
    echo $! > "$PID_FILE"
    notify-send "Music Player" "Playlist started in background."
}

# Fungsi untuk menambahkan URL ke playlist
add_to_playlist() {
    local url=$(rofi -dmenu -p "Add URL " -theme ~/.config/rofi/input.rasi)

    if [[ -n $url && $url =~ ^https?:// ]]; then
        echo "$url" >> "$PLAYLIST_FILE"
        notify-send "Music Player" "URL added to playlist:\n$url"
    else
        notify-send "Music Player" "Invalid or empty URL. Nothing added."
    fi
}

# Fungsi untuk memutar musik dari input (folder/file/URL)
play_from_input() {
    local input=$(rofi -dmenu -p "Enter URL " -theme ~/.config/rofi/input.rasi)

    if [[ -z "$input" ]]; then
        notify-send "Music Player" "No input provided."
        return
    fi

    if [[ -d "$input" ]]; then
        local files=$(find "$input" -type f \( -iname "*.mp3" -o -iname "*.ogg" -o -iname "*.flac" -o -iname "*.wav" \))
        if [[ -z "$files" ]]; then
            notify-send "Music Player" "No audio files found in directory."
            return
        fi

        if [[ -f $PID_FILE ]]; then
            notify-send "Music Player" "Music is already running."
            return
        fi

        nohup mpv --really-quiet --loop $files > /dev/null 2>&1 &
        echo $! > "$PID_FILE"
        notify-send "Music Player" "Playing music from folder:\n$input"
    else
        start_music "$input"
    fi
}

# Menu utama
main_menu() {
    local options=$(printf "$ICON_PLAY   Start Music\n$ICON_STOP   Stop Music\n$ICON_PLAYLIST   Start Playlist\n$ICON_ADD   Add URL")
    local choice=$(echo "$options" | rofi -dmenu -p "MPV Music" -theme ~/.config/rofi/menu.rasi)

    case "$choice" in
        "$ICON_PLAY   Start Music") play_from_input ;;
        "$ICON_STOP   Stop Music") stop_music ;;
        "$ICON_PLAYLIST   Start Playlist") start_playlist ;;
        "$ICON_ADD   Add URL") add_to_playlist ;;
        *) exit 0 ;;
    esac
}

# Entry point
main_menu

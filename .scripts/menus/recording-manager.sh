#!/bin/bash

# ================================
# Konfigurasi
# ================================
ENABLED_COLOR="#9ece6a"
DISABLED_COLOR="#f7768e"

RECORDING_ICON="⏺"
STOPPED_ICON="⏹"

# Nama sink audio internal dan mic
# Cek dengan: pactl list sources short & pactl list sinks short
AUDIO_INTERNAL="alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Headphones__sink.monitor"
AUDIO_MICROPHONE="alsa_input.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Mic1__source"

OUTPUT_DIR="$HOME/Videos/Recording"
mkdir -p "$OUTPUT_DIR"

WF_PID_FILE="/tmp/wf-recorder.pid"
FF_PID_FILE="/tmp/ffmpeg_audio.pid"

# ================================
# Fungsi Status
# ================================
get_status() {
    if [[ -f "$WF_PID_FILE" || -f "$FF_PID_FILE" ]]; then
        echo "<span color=\"$ENABLED_COLOR\">$RECORDING_ICON ON</span>"
    else
        echo "<span color=\"$DISABLED_COLOR\">$STOPPED_ICON OFF</span>"
    fi
}

# ================================
# Cek PID sebelum start
# ================================
check_and_clean_pid() {
    # wf-recorder
    if [ -f "$WF_PID_FILE" ]; then
        PID=$(cat "$WF_PID_FILE")
        if ! ps -p $PID > /dev/null 2>&1; then
            rm -f "$WF_PID_FILE"
        fi
    fi
    # ffmpeg
    if [ -f "$FF_PID_FILE" ]; then
        PID=$(cat "$FF_PID_FILE")
        if ! ps -p $PID > /dev/null 2>&1; then
            rm -f "$FF_PID_FILE"
        fi
    fi
}

# ================================
# Mulai Rekaman
# ================================
start_recording() {
    check_and_clean_pid

    if [[ -f "$WF_PID_FILE" || -f "$FF_PID_FILE" ]]; then
        notify-send "⚠ Rekaman Gagal" "Proses rekaman masih berjalan!"
        exit 1
    fi

    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    OUTPUT_FILE="$OUTPUT_DIR/recording_${TIMESTAMP}.mkv"
    MIC_FILE="$OUTPUT_DIR/recording_${TIMESTAMP}_mic.aac"

    # Mulai wf-recorder (kualitas tinggi + encode cepat)
    wf-recorder -f "$OUTPUT_FILE" \
        --audio="$AUDIO_INTERNAL" \
        --codec libx264 \
        --preset ultrafast \
        --crf 20 \
        --pixel-format yuv420p \
        --audio-codec aac \
        --muxer matroska \
        --resolution 1366x768 \
        --framerate 30 \
        2> "$OUTPUT_DIR/wf-error.log" &
    
    echo $! > "$WF_PID_FILE"

    # Rekam mic terpisah
    ffmpeg -loglevel quiet -y \
        -f pulse -ac 2 -i "$AUDIO_MICROPHONE" \
        -c:a aac -b:a 128k "$MIC_FILE" &
    
    echo $! > "$FF_PID_FILE"

    notify-send "🎥 Recording Started" "Video: $OUTPUT_FILE"
}

# ================================
# Hentikan Rekaman
# ================================
stop_recording() {
    for pidfile in "$WF_PID_FILE" "$FF_PID_FILE"; do
        if [ -f "$pidfile" ]; then
            PID=$(cat "$pidfile")
            kill -SIGINT $PID 2>/dev/null
            sleep 2
            if ps -p $PID > /dev/null; then kill -TERM $PID; sleep 1; fi
            if ps -p $PID > /dev/null; then kill -9 $PID; fi
            wait $PID 2>/dev/null
            rm -f "$pidfile"
        fi
    done

    notify-send "✅ Recording Stopped" "File disimpan di $OUTPUT_DIR"
}

# ================================
# Menu Utama (via Rofi)
# ================================
main_menu() {
    local status=$(get_status)
    if [[ -f "$WF_PID_FILE" || -f "$FF_PID_FILE" ]]; then
        options="⏹ Stop Recording"
    else
        options="⏺ Start Recording"
    fi

    local choice=$(echo -e "$options" | rofi -dmenu -p "Recording:" -theme ~/.config/rofi/menu.rasi)
    case "$choice" in
        "⏺ Start Recording") start_recording ;;
        "⏹ Stop Recording") stop_recording ;;
    esac
}

# ================================
# Jalankan
# ================================
case "$1" in
    --status) get_status ;;
    *) main_menu ;;
esac

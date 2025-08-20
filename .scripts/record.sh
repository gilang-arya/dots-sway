#!/bin/bash

# Nama perangkat audio
# Audio internal dari headphones
AUDIO_INTERNAL="alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Headphones__sink.monitor"

# Audio eksternal (Mic1 atau Mic2)
AUDIO_MICROPHONE="alsa_input.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Mic1__source"

# Direktori penyimpanan
OUTPUT_DIR="$HOME/Videos/Recording"
mkdir -p "$OUTPUT_DIR"

# Nama file output
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
VIDEO_OUTPUT="$OUTPUT_DIR/video_$TIMESTAMP.mp4"
AUDIO_EXTERNAL_OUTPUT="$OUTPUT_DIR/audio_mic_$TIMESTAMP.mp3"

# Start recording function
start_recording() {
    echo "Starting recording..."

    # Rekam video + audio internal menggunakan wf-recorder
    wf-recorder -f "$VIDEO_OUTPUT" --fps=60 --audio="$AUDIO_INTERNAL" > /dev/null 2>&1 &
    echo $! > /tmp/wf-recorder.pid

    # Rekam audio eksternal menggunakan ffmpeg
    ffmpeg -loglevel quiet -y -f pulse -ac 2 -i "$AUDIO_MICROPHONE" \
           -c:a libmp3lame "$AUDIO_EXTERNAL_OUTPUT" > /dev/null 2>&1 &
    echo $! > /tmp/ffmpeg_audio.pid

    echo "Recording started: $VIDEO_OUTPUT (internal audio) & $AUDIO_EXTERNAL_OUTPUT (external mic)"
}

# Stop recording function
stop_recording() {
    echo "Stopping recording..."
    
    # Hentikan wf-recorder
    if [ -f /tmp/wf-recorder.pid ]; then
        kill -SIGINT $(cat /tmp/wf-recorder.pid)
        rm /tmp/wf-recorder.pid
    else
        echo "No wf-recorder process found."
    fi

    # Hentikan ffmpeg
    if [ -f /tmp/ffmpeg_audio.pid ]; then
        kill -INT $(cat /tmp/ffmpeg_audio.pid)
        rm /tmp/ffmpeg_audio.pid
    else
        echo "No ffmpeg process found."
    fi

    echo "Recording stopped."
}

case "$1" in
    start)
        start_recording
        ;;
    stop)
        stop_recording
        ;;
    *)
        echo "Usage: $0 {start|stop}"
        ;;
esac

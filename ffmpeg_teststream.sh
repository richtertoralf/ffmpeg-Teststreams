#!/bin/bash
set -e

# ============================
# FFmpeg Teststream Generator
# ============================
# Aufruf: ./ffmpeg_teststream.sh <stream-name>
# Erwartet eine .ini-Datei in /etc/ffmpeg_streams/<stream-name>.ini
# mit den Variablen: TARGET_HOST, TARGET_PORT, STREAM_ID, TYPE, FPS, BITRATE

NAME="$1"
CONFIG="/etc/ffmpeg_streams/${NAME}.ini"

if [ -z "$NAME" ]; then
    echo "Usage: $0 <stream-name>"
    exit 1
fi

if [ ! -f "$CONFIG" ]; then
    echo "Config file $CONFIG not found"
    exit 1
fi

# Konfiguration einlesen
source "$CONFIG"

# Ziel-URL zusammensetzen
URL="srt://${TARGET_HOST}:${TARGET_PORT}?streamid=publish:${STREAM_ID}&pkt_size=1316"

# Info-Ausgabe
echo "Starting FFmpeg stream: ${NAME}"
echo "Target: $URL"
echo "Type: $TYPE | FPS: $FPS | BITRATE: $BITRATE"

# FFmpeg je nach TYPE starten
case "$TYPE" in
    basic)
        ffmpeg -re -f lavfi -i "testsrc=size=1920x1080:rate=${FPS}" \
               -f lavfi -i "sine=frequency=1000" \
               -vcodec libx264 -preset ultrafast -pix_fmt yuv420p -b:v "$BITRATE" \
               -c:a aac -b:a 128k -ar 44100 \
               -f mpegts "$URL"
        ;;
    motion)
        ffmpeg -re -f lavfi -i "testsrc2=size=1920x1080:rate=${FPS}" \
               -f lavfi -i "sine=frequency=1000" \
               -vcodec libx264 -preset ultrafast -pix_fmt yuv420p -b:v "$BITRATE" \
               -c:a aac -b:a 128k -ar 44100 \
               -f mpegts "$URL"
        ;;
    sport)
        ffmpeg -re -f lavfi -i "testsrc2=size=1920x1080:rate=${FPS}" \
               -f lavfi -i "sine=frequency=1000" \
               -vcodec libx264 -preset ultrafast -b:v "$BITRATE" \
               -c:a aac -b:a 128k \
               -f mpegts "$URL"
        ;;
    scoreboard)
        ffmpeg -re -f lavfi -i "testsrc2=size=1920x1080:rate=${FPS}" \
               -vf "drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf:text='%{pts\\:hms} SCORE %{eif\\:random(100)}-%{eif\\:random(100)}':fontsize=60:fontcolor=white:x=100:y=100" \
               -vcodec libx264 -preset ultrafast -pix_fmt yuv420p -b:v "$BITRATE" \
               -an \
               -f mpegts "$URL"
        ;;
    black)
        ffmpeg -re -f lavfi -i "color=black:size=1920x1080:rate=${FPS}" \
               -vcodec libx264 -preset ultrafast -pix_fmt yuv420p -b:v "$BITRATE" \
               -an \
               -f mpegts "$URL"
        ;;
    clock)
        ffmpeg -re -f lavfi -i "testsrc=size=1920x1080:rate=${FPS}" \
               -vf "drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf:text='%{localtime}':fontsize=60:fontcolor=white:x=100:y=100" \
               -vcodec libx264 -preset ultrafast -pix_fmt yuv420p -b:v "$BITRATE" \
               -an \
               -f mpegts "$URL"
        ;;
    sport-motion)
        ffmpeg -re -f lavfi -i "testsrc2=size=1920x1080:rate=${FPS}" \
               -vf "minterpolate='mc_mode=mi',format=yuv420p" \
               -vcodec libx264 -preset veryfast -b:v "$BITRATE" \
               -an \
               -f mpegts "$URL"
        ;;
    smptebars)
        ffmpeg -re -f lavfi -i "smptebars=size=1920x1080:rate=${FPS}" \
               -f lavfi -i "sine=frequency=1000" \
               -vcodec libx264 -preset ultrafast -pix_fmt yuv420p -b:v "$BITRATE" \
               -c:a aac -b:a 128k \
               -f mpegts "$URL"
        ;;
    noise)
        ffmpeg -re -f lavfi -i "nullsrc=size=1920x1080:rate=${FPS}" \
               -f lavfi -i "anoisesrc=color=white" \
               -filter_complex "[0:v][1:v]overlay=format=yuv420" \
               -vcodec libx264 -preset ultrafast -pix_fmt yuv420p -b:v "$BITRATE" \
               -an \
               -f mpegts "$URL"
        ;;
    full-noise)
        ffmpeg -re -f lavfi -i "anoisesrc=color=white:size=1920x1080:rate=${FPS}" \
               -vcodec libx264 -preset veryfast -b:v "$BITRATE" \
               -an \
               -f mpegts "$URL"
        ;;
    smpte-noise)
        ffmpeg -re -f lavfi -i "smptebars=size=1920x1080:rate=${FPS}" \
               -f lavfi -i "cellauto=size=1920x1080:rate=${FPS}" \
               -filter_complex "[0:v][1:v]overlay=format=yuv420" \
               -vcodec libx264 -preset veryfast -b:v "$BITRATE" \
               -an \
               -f mpegts "$URL"
        ;;
    *)
        echo "Unknown TYPE: $TYPE"
        echo "Valid types: basic, motion, sport, scoreboard, black, clock, sport-motion, smptebars, noise, full-noise, smpte-noise"
        exit 1
        ;;
esac

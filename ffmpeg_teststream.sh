#!/bin/bash
set -e

NAME="$1"
CONFIG="/etc/ffmpeg_streams/${NAME}.ini"

if [ -z "$NAME" ]; then echo "Usage: $0 <stream-name>"; exit 1; fi
if [ ! -f "$CONFIG" ]; then echo "Config file $CONFIG not found"; exit 1; fi

source "$CONFIG"
URL="srt://${TARGET_HOST}:${TARGET_PORT}?streamid=publish:${STREAM_ID}&pkt_size=1316"

echo "Starting FFmpeg stream: ${NAME}"
echo "Target: $URL"
echo "Type: $TYPE | FPS: $FPS | BITRATE: $BITRATE"

case "$TYPE" in
  basic)
    ffmpeg -re -f lavfi -i "testsrc=size=1920x1080:rate=${FPS}" \
           -f lavfi -i "sine=frequency=1000" \
           -vcodec libx264 -preset ultrafast -pix_fmt yuv420p -b:v "$BITRATE" \
           -c:a aac -b:a 128k -ar 44100 -f mpegts "$URL"
    ;;
  motion)
    ffmpeg -re -f lavfi -i "testsrc2=size=1920x1080:rate=${FPS}" \
           -f lavfi -i "sine=frequency=1000" \
           -vcodec libx264 -preset ultrafast -pix_fmt yuv420p -b:v "$BITRATE" \
           -c:a aac -b:a 128k -ar 44100 -f mpegts "$URL"
    ;;
  scoreboard)
    ffmpeg -re -f lavfi -i "testsrc2=size=1920x1080:rate=${FPS}" \
           -vf "drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf:text='%{pts\:hms} SCORE %{eif\:random(100)}-%{eif\:random(100)}':fontsize=60:fontcolor=white:x=100:y=100" \
           -vcodec libx264 -preset ultrafast -pix_fmt yuv420p -b:v "$BITRATE" \
           -an -f mpegts "$URL"
    ;;
  black)
    ffmpeg -re -f lavfi -i "color=black:size=1920x1080:rate=${FPS}" \
           -vcodec libx264 -preset ultrafast -pix_fmt yuv420p -b:v "$BITRATE" \
           -an -f mpegts "$URL"
    ;;
  *)
    echo "Unknown TYPE: $TYPE"
    exit 1
    ;;
esac

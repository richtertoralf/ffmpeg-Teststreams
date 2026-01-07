#!/bin/bash
set -e

# LEGACY SCRIPT
# Früher Stream-Runner mit eingebauter Stream-Logik.
# Wird durch streams.conf + ini-gen.py + systemd-Template ersetzt.

# ============================================
# FFmpeg Teststream Generator für SRT-Ausgabe
# ============================================
# Aufruf: ./ffmpeg_teststream.sh <stream-name>
# Erwartet eine .ini-Datei in /etc/ffmpeg_streams/<stream-name>.ini
# mit folgenden Variablen:
#   - TARGET_HOST, TARGET_PORT
#   - STREAM_ID
#   - TYPE (z. B. basic, motion, clock, ...)
#   - FPS (z. B. 25, 30, 50)
#   - BITRATE (z. B. 2M)
#
# Optional: WIDTH, HEIGHT, AUDIO_ENABLED, DURATION, PRESET

NAME="$1"
CONFIG="/etc/ffmpeg_streams/${NAME}.ini"

if [ -z "$NAME" ]; then
    echo "Usage: $0 <stream-name>"
    exit 1
fi

if [ ! -f "$CONFIG" ]; then
    echo "❌ Config file $CONFIG not found"
    exit 1
fi

# INI-Datei laden
source "$CONFIG"

# Standardwerte setzen
URL="srt://${TARGET_HOST}:${TARGET_PORT}?streamid=publish:${STREAM_ID}&pkt_size=1316"
PRESET=${PRESET:-ultrafast}
WIDTH=${WIDTH:-1920}
HEIGHT=${HEIGHT:-1080}
FPS=${FPS:-30}
DURATION=${DURATION:-3600}
BITRATE=${BITRATE:-2M}
AUDIO_ENABLED=${AUDIO_ENABLED:-yes}

# Infoausgabe
echo "🎬 Starting FFmpeg stream: $NAME"
echo "→ URL:      $URL"
echo "→ TYPE:     $TYPE"
echo "→ FPS:      $FPS"
echo "→ BITRATE:  $BITRATE"
echo "→ PRESET:   $PRESET"
echo "→ AUDIO:    $AUDIO_ENABLED"

# Typbezogene Video- und Audioquellen vorbereiten
case "$TYPE" in
    basic)
        VIDEO_ARGS=(-f lavfi -i "testsrc=duration=${DURATION}:size=${WIDTH}x${HEIGHT}:rate=${FPS}")
        ;;
    smptebars)
        VIDEO_ARGS=(-f lavfi -i "smptebars=size=${WIDTH}x${HEIGHT}:rate=${FPS}")
        ;;
    motion)
        VIDEO_ARGS=(-f lavfi -i "testsrc2=size=${WIDTH}x${HEIGHT}:rate=${FPS}")
        ;;
    noise)
        VIDEO_ARGS=(-f lavfi -i "nullsrc=size=${WIDTH}x${HEIGHT}:rate=${FPS},format=yuv420p")
        ;;
    black)
        VIDEO_ARGS=(-f lavfi -i "color=black:size=${WIDTH}x${HEIGHT}:rate=${FPS}")
        ;;
    clock)
        VIDEO_ARGS=(-f lavfi -i "testsrc=size=${WIDTH}x${HEIGHT}:rate=${FPS},drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf:text='%{localtime}':fontsize=60:fontcolor=white:x=100:y=100")
        ;;
    sport-motion)
        VIDEO_ARGS=(-f lavfi -i "testsrc2=size=${WIDTH}x${HEIGHT}:rate=${FPS},minterpolate=mc_mode=aobmc:vsbmc=1,format=yuv420p")
        ;;
    smpte-noise)
        VIDEO_ARGS=(
            -f lavfi -i "smptebars=size=${WIDTH}x${HEIGHT}:rate=${FPS}"
            -f lavfi -i "cellauto=size=${WIDTH}x${HEIGHT}:rate=${FPS}"
        )
        FILTER_COMPLEX="[0:v][1:v]overlay,format=yuv420p"
        ;;
    full-noise)
        VIDEO_ARGS=(-f lavfi -i "cellauto=size=${WIDTH}x${HEIGHT}:rate=${FPS}")
        ;;
    sport)
        VIDEO_ARGS=(-f lavfi -i "testsrc2=size=${WIDTH}x${HEIGHT}:rate=${FPS}")
        ;;
    scoreboard)
        VIDEO_ARGS=(-f lavfi -i "testsrc2=size=${WIDTH}x${HEIGHT}:rate=${FPS},drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf:text='%{pts\:hms} LIVE SCORE: %{eif\:random(100)}-%{eif\:random(100)}':fontsize=60:fontcolor=white:x=100:y=50")
        ;;
    *)
        echo "❌ Unknown TYPE: $TYPE"
        echo "ℹ️  Valid types: basic, smptebars, motion, noise, black, clock, sport-motion, smpte-noise, full-noise, sport, scoreboard"
        exit 1
        ;;
esac

# Audioquelle vorbereiten
if [ "$AUDIO_ENABLED" = "yes" ]; then
    AUDIO_ARGS=(-f lavfi -i "sine=frequency=1000" -c:a aac -b:a 128k -ar 44100)
else
    AUDIO_ARGS=(-an)
fi

# FFmpeg-Aufruf zusammensetzen
if [ "$TYPE" = "smpte-noise" ]; then
    ffmpeg -re "${VIDEO_ARGS[@]}" "${AUDIO_ARGS[@]}" \
        -filter_complex "$FILTER_COMPLEX" \
        -vcodec libx264 -preset "$PRESET" -pix_fmt yuv420p -b:v "$BITRATE" \
        -f mpegts "$URL"
else
    ffmpeg -re "${VIDEO_ARGS[@]}" "${AUDIO_ARGS[@]}" \
        -vcodec libx264 -preset "$PRESET" -pix_fmt yuv420p -b:v "$BITRATE" \
        -f mpegts "$URL"
fi

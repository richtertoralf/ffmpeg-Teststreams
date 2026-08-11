#!/bin/bash
set -e


# ============================================
# FFmpeg Stream Runner (Runtime)
# ============================================
#
# Dieses Skript wird von den systemd-Diensten (ffmpeg_stream@.service) aufgerufen.
# Es liest eine generierte Stream-INI aus /etc/ffmpeg_streams/<name>.ini
# und startet den entsprechenden FFmpeg-Prozess.
#
# Die Konfigurationslogik (welche Streams existieren, Parameter, Defaults)
# liegt in streams.conf und ini-gen.py.
# Dieses Skript ist bewusst schlank und enthält keine eigene Persistenz.
#
# Aufruf: ./ffmpeg_teststream.sh <stream-name>
# Erwartet eine .ini-Datei in /etc/ffmpeg_streams/<stream-name>.ini
# mit folgenden Variablen:
#   - TARGET_HOST, TARGET_PORT
#   - STREAM_ID
#   - TYPE (z. B. basic, motion, clock, ...)
#   - FPS (z. B. 25, 30, 50)
#   - BITRATE (z. B. 2M)
#
# Optional: WIDTH, HEIGHT, AUDIO_ENABLED, PRESET

if [ "$#" -ne 1 ] || [ -z "$1" ]; then
    echo "❌ Usage: $0 <stream-name>" >&2
    exit 1
fi

NAME="$1"
CONFIG_DIR="${CONFIG_DIR:-/etc/ffmpeg_streams}"
CONFIG="${CONFIG_DIR}/${NAME}.ini"

if [ ! -f "$CONFIG" ]; then
    echo "❌ Config file $CONFIG not found" >&2
    exit 1
fi

# INI-Datei laden
source "$CONFIG"

# Notwendige Konfigurationswerte prüfen
for required_var in TYPE TARGET_HOST TARGET_PORT STREAM_ID; do
    if [ -z "${!required_var:-}" ]; then
        echo "❌ Required config value $required_var is missing or empty in $CONFIG" >&2
        exit 1
    fi
done

# Standardwerte setzen
URL="srt://${TARGET_HOST}:${TARGET_PORT}?streamid=publish:${STREAM_ID}&pkt_size=1316"
PRESET=${PRESET:-ultrafast}
WIDTH=${WIDTH:-1920}
HEIGHT=${HEIGHT:-1080}
FPS=${FPS:-30}
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
        VIDEO_ARGS=(-re -f lavfi -i "testsrc=size=${WIDTH}x${HEIGHT}:rate=${FPS}")
        ;;
    smptebars)
        VIDEO_ARGS=(-re -f lavfi -i "smptebars=size=${WIDTH}x${HEIGHT}:rate=${FPS}")
        ;;
    motion)
        VIDEO_ARGS=(-re -f lavfi -i "testsrc2=size=${WIDTH}x${HEIGHT}:rate=${FPS}")
        ;;
    noise)
        VIDEO_ARGS=(-re -f lavfi -i "nullsrc=size=${WIDTH}x${HEIGHT}:rate=${FPS},format=yuv420p")
        ;;
    black)
        VIDEO_ARGS=(-re -f lavfi -i "color=black:size=${WIDTH}x${HEIGHT}:rate=${FPS}")
        ;;
    clock)
        VIDEO_ARGS=(-re -f lavfi -i "testsrc=size=${WIDTH}x${HEIGHT}:rate=${FPS},drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf:text='%{localtime}':fontsize=60:fontcolor=white:x=100:y=100")
        ;;
    sport-motion)
        VIDEO_ARGS=(-re -f lavfi -i "testsrc2=size=${WIDTH}x${HEIGHT}:rate=${FPS}")
        ;;
    smpte-noise)
        VIDEO_ARGS=(
            -re -f lavfi -i "smptebars=size=${WIDTH}x${HEIGHT}:rate=${FPS}"
            -re -f lavfi -i "cellauto=size=${WIDTH}x${HEIGHT}:rate=${FPS}"
        )
        FILTER_COMPLEX="[0:v][1:v]overlay,format=yuv420p"
        ;;
    full-noise)
        VIDEO_ARGS=(-re -f lavfi -i "cellauto=size=${WIDTH}x${HEIGHT}:rate=${FPS}")
        ;;
    sport)
        VIDEO_ARGS=(-re -f lavfi -i "testsrc2=size=${WIDTH}x${HEIGHT}:rate=${FPS}")
        ;;
    scoreboard)
        VIDEO_ARGS=(-re -f lavfi -i "testsrc2=size=${WIDTH}x${HEIGHT}:rate=${FPS},drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf:text='%{pts\:hms} LIVE SCORE: %{eif\:random(100)}-%{eif\:random(100)}':fontsize=60:fontcolor=white:x=100:y=50")
        ;;
    *)
        echo "❌ Unknown TYPE: $TYPE"
        echo "ℹ️  Valid types: basic, smptebars, motion, noise, black, clock, sport-motion, smpte-noise, full-noise, sport, scoreboard"
        exit 1
        ;;
esac

# Audioquelle vorbereiten
if [ "$AUDIO_ENABLED" = "yes" ]; then
    AUDIO_ARGS=(-re -f lavfi -i "sine=frequency=1000" -c:a aac -b:a 128k -ar 44100)
else
    AUDIO_ARGS=(-an)
fi

# FFmpeg-Aufruf zusammensetzen
if [ "$TYPE" = "smpte-noise" ]; then
    exec ffmpeg -hide_banner -nostats -loglevel warning \
        "${VIDEO_ARGS[@]}" "${AUDIO_ARGS[@]}" \
        -filter_complex "$FILTER_COMPLEX" \
        -vcodec libx264 -preset "$PRESET" -pix_fmt yuv420p -b:v "$BITRATE" \
        -f mpegts "$URL"
else
    exec ffmpeg -hide_banner -nostats -loglevel warning \
        "${VIDEO_ARGS[@]}" "${AUDIO_ARGS[@]}" \
        -vcodec libx264 -preset "$PRESET" -pix_fmt yuv420p -b:v "$BITRATE" \
        -f mpegts "$URL"
fi

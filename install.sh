#!/usr/bin/env bash
set -euo pipefail

# -------------------------------
# Pfade & Defaults
# -------------------------------
REPO_URL="${REPO_URL:-https://github.com/richtertoralf/ffmpeg-Teststreams.git}"
TMP_DIR="$(mktemp -d)"
CONFIG_DIR="/etc/ffmpeg_streams"
BIN_DIR="/usr/local/bin"
SYSTEMD_DIR="/etc/systemd/system"
CONF_FILE="$CONFIG_DIR/streams.conf"

FILE_INI_GEN="ini-gen.py"
FILE_MAIN_SCRIPT="ffmpeg_teststream.sh"
FILE_MANAGER="manage-teststreams.sh"
FILE_SYSTEMD="ffmpeg_stream@.service"

NON_INTERACTIVE="false"
TARGET_HOST_ARG=""
TARGET_PORT_ARG=""

usage() {
  cat <<EOF
Usage: sudo ./install.sh [--non-interactive] [--host 10.10.11.11] [--port 8890]

Optionen:
  --non-interactive   Keine Abfragen (nutzt Defaults/Argumente)
  --host <HOST>       Ziel-Host für neu zu erstellende streams.conf
  --port <PORT>       Ziel-Port (Default 8890) für neu zu erstellende streams.conf
  -h, --help          Hilfe
EOF
  exit 0
}

# -------------------------------
# Argumente
# -------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --non-interactive) NON_INTERACTIVE="true"; shift ;;
    --host) TARGET_HOST_ARG="${2:-}"; shift 2 ;;
    --port) TARGET_PORT_ARG="${2:-}"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Unbekanntes Argument: $1"; usage ;;
  esac
done

# -------------------------------
# Root prüfen
# -------------------------------
if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "❌ Bitte als root oder mit sudo ausführen."
  exit 1
fi

# -------------------------------
# Cleanup
# -------------------------------
cleanup() { [[ -d "$TMP_DIR" ]] && rm -rf "$TMP_DIR"; }
trap cleanup EXIT

# -------------------------------
# Vorab-Prüfungen
# -------------------------------
command -v git >/dev/null 2>&1 || { echo "❌ git fehlt."; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "❌ python3 fehlt."; exit 1; }
command -v systemctl >/dev/null 2>&1 || { echo "❌ systemd/systemctl fehlt."; exit 1; }

# -------------------------------
# Repo klonen
# -------------------------------
echo "📥 Klone Repository nach $TMP_DIR ..."
git clone --depth=1 "$REPO_URL" "$TMP_DIR"

for f in "$FILE_INI_GEN" "$FILE_MAIN_SCRIPT" "$FILE_MANAGER" "$FILE_SYSTEMD"; do
  [[ -f "$TMP_DIR/$f" ]] || { echo "❌ Datei im Repo fehlt: $f"; exit 1; }
done

# -------------------------------
# Installationsziele
# -------------------------------
echo "📁 Erzeuge $CONFIG_DIR (falls nötig) ..."
mkdir -p "$CONFIG_DIR"

echo "📦 Installiere Skripte nach $BIN_DIR ..."
install -m 0755 "$TMP_DIR/$FILE_MAIN_SCRIPT" "$BIN_DIR/$FILE_MAIN_SCRIPT"
install -m 0755 "$TMP_DIR/$FILE_MANAGER"    "$BIN_DIR/$FILE_MANAGER"
install -m 0755 "$TMP_DIR/$FILE_INI_GEN"    "$BIN_DIR/$FILE_INI_GEN"

echo "🖇️  Installiere systemd-Unit nach $SYSTEMD_DIR ..."
install -m 0644 "$TMP_DIR/$FILE_SYSTEMD" "$SYSTEMD_DIR/$FILE_SYSTEMD"
systemctl daemon-reload

# -------------------------------
# streams.conf behandeln
#   - Falls bereits vorhanden -> unverändert lassen
#   - Falls nicht vorhanden:
#       a) Wenn im Repo vorhanden: Vorlage kopieren
#       b) Sonst: minimalen Standard generieren (mit Host/Port)
# -------------------------------
RESOLVED_HOST="$TARGET_HOST_ARG"
RESOLVED_PORT="${TARGET_PORT_ARG:-8890}"

create_minimal_streams_conf() {
  local host="$1" port="$2"
  cat > "$CONF_FILE" <<EOF
# ============================
# /etc/ffmpeg_streams/streams.conf
# ============================

# Globale Defaults
WIDTH=1920
HEIGHT=1080
PRESET=ultrafast
DEFAULT_PORT=${port}

# Streams (NAME;TYPE;FPS;BITRATE;TARGET_HOST;TARGET_PORT;AUDIO)
# AUDIO = yes nur für: basic, motion, smptebars, sport

testpattern-basic;basic;30;2M;${host};${port};yes
testpattern-smptebars;smptebars;30;3M;${host};${port};yes
testpattern-motion;motion;30;4M;${host};${port};yes
testpattern-noise;noise;30;5M;${host};${port};no
testpattern-black;black;30;1M;${host};${port};no
testpattern-clock;clock;30;3M;${host};${port};no
testpattern-sport-motion;sport-motion;50;4M;${host};${port};no
testpattern-smpte-noise;smpte-noise;30;2M;${host};${port};no
testpattern-full-noise;full-noise;30;1M;${host};${port};no
testpattern-sport;sport;60;2M;${host};${port};yes
testpattern-scoreboard;scoreboard;50;4M;${host};${port};no
EOF
}

if [[ -f "$CONF_FILE" ]]; then
  echo "✅ $CONF_FILE existiert – unverändert belassen."
else
  if [[ -f "$TMP_DIR/streams.conf" ]]; then
    echo "🧾 Kopiere Vorlage streams.conf aus dem Repo nach $CONF_FILE ..."
    install -m 0644 "$TMP_DIR/streams.conf" "$CONF_FILE"
  else
    if [[ -z "$RESOLVED_HOST" && "$NON_INTERACTIVE" != "true" ]]; then
      echo "🔧 Ziel-Host (MediaMTX) für neue streams.conf:"
      read -rp "TARGET_HOST [z. B. 10.10.11.11]: " RESOLVED_HOST
      RESOLVED_HOST="${RESOLVED_HOST:-127.0.0.1}"
      read -rp "TARGET_PORT [${RESOLVED_PORT}]: " _p
      RESOLVED_PORT="${_p:-$RESOLVED_PORT}"
    fi
    [[ -z "$RESOLVED_HOST" ]] && RESOLVED_HOST="127.0.0.1"
    echo "🧾 Erzeuge minimale $CONF_FILE mit Host=$RESOLVED_HOST Port=$RESOLVED_PORT ..."
    create_minimal_streams_conf "$RESOLVED_HOST" "$RESOLVED_PORT"
  fi
fi

# -------------------------------
# INIs generieren
# -------------------------------
echo "🧾 Erzeuge INI-Dateien via $BIN_DIR/$FILE_INI_GEN ..."
python3 "$BIN_DIR/$FILE_INI_GEN"

# -------------------------------
# Hinweise & Abschluss
# -------------------------------
echo "✅ Installation abgeschlossen."

echo "ℹ️  Nützliche Befehle:"
echo "   - Streams starten:   sudo manage-teststreams.sh start testpattern-sport"
echo "   - Streams stoppen:   sudo manage-teststreams.sh stop  testpattern-sport"
echo "   - Alle INIs neu:     sudo python3 $BIN_DIR/$FILE_INI_GEN"
echo "   - Dienst starten:    sudo systemctl start 'ffmpeg_stream@testpattern-sport.service'"

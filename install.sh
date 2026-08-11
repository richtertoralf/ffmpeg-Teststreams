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

usage() {
  cat <<EOF
Usage: sudo ./install.sh

Dieses Skript:
  - installiert Skripte und systemd-Unit,
  - erwartet eine vorhandene streams.conf:
      * entweder bereits unter $CONF_FILE
      * oder als Datei 'streams.conf' im Repo-Root
  - erzeugt KEINE streams.conf mehr automatisch.
EOF
  exit 0
}

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
# streams.conf bereitstellen (ohne Generierung)
# -------------------------------
if [[ -f "$CONF_FILE" ]]; then
  echo "✅ Bestehende $CONF_FILE gefunden – unverändert belassen."
elif [[ -f "$TMP_DIR/streams.conf" ]]; then
  echo "🧾 Kopiere streams.conf aus dem Repo nach $CONF_FILE ..."
  install -m 0644 "$TMP_DIR/streams.conf" "$CONF_FILE"
else
  echo "❌ Keine streams.conf gefunden."
  echo "   Erstelle eine streams.conf im Repo-Root ODER lege sie unter $CONF_FILE ab und starte das Skript erneut."
  exit 1
fi

# -------------------------------
# INIs generieren
# -------------------------------
echo "🧾 Erzeuge INI-Dateien via $BIN_DIR/$FILE_INI_GEN ..."
python3 "$BIN_DIR/$FILE_INI_GEN"

# -------------------------------
# Abschluss
# -------------------------------
echo "✅ Installation abgeschlossen."
echo "ℹ️  Nützliche Befehle:"
echo "   - Streams starten:   sudo manage-teststreams.sh start testpattern-sport"
echo "   - Streams stoppen:   sudo manage-teststreams.sh stop  testpattern-sport"
echo "   - Alle INIs neu:     sudo python3 $BIN_DIR/$FILE_INI_GEN"
echo "   - Dienst starten:    sudo systemctl start 'ffmpeg_stream@testpattern-sport.service'"

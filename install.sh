#!/bin/bash
set -e

REPO_URL="https://github.com/richtertoralf/ffmpeg-Teststreams.git"
TMP_DIR="$(mktemp -d)"
CONFIG_DIR="/etc/ffmpeg_streams"
BIN_DIR="/usr/local/bin"
SYSTEMD_DIR="/etc/systemd/system"

echo "📥 Klone Repository temporär nach $TMP_DIR..."
git clone --depth=1 "$REPO_URL" "$TMP_DIR"

echo "📦 Installiere Skripte..."
sudo mkdir -p "$CONFIG_DIR"
sudo cp "$TMP_DIR"/ffmpeg_teststream.sh "$BIN_DIR/"
sudo chmod +x "$BIN_DIR/ffmpeg_teststream.sh"

sudo cp "$TMP_DIR"/manage-teststreams.sh "$BIN_DIR/"
sudo chmod +x "$BIN_DIR/manage-teststreams.sh"

echo "🖇️ Installiere systemd Unit..."
sudo cp "$TMP_DIR"/ffmpeg_stream@.service "$SYSTEMD_DIR/"
sudo systemctl daemon-reexec

# Wechsel ins geklonte Repo
cd "$TMP_DIR"

# 🐍 INI-Dateien automatisch erzeugen, falls ini-gen.py vorhanden ist
if [ -f "ini-gen.py" ]; then
  echo "🧾 Erzeuge INI-Dateien mit ini-gen.py..."
  python3 ini-gen.py
else
  echo "⚠️ ini-gen.py nicht gefunden – keine INI-Dateien erzeugt."
fi

echo "🧹 Lösche temporären Ordner..."
rm -rf "$TMP_DIR"

echo "✅ Installation abgeschlossen!"
echo "👉 Beispiel: sudo manage-teststreams.sh start testpattern-sport"

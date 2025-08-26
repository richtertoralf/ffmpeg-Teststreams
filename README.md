# FFmpeg Teststreams mit systemd

>Dieses Repository erzeugt und verwaltet FFmpeg-Teststreams per systemd.
>Die Konfiguration erfolgt zentral über /etc/ffmpeg_streams/streams.conf.
>Aus dieser Datei generiert ini-gen.py automatisch die einzelnen .ini-Dateien.

## 🧪 Getestet auf:
- Ubuntu 22.04 LTS
- Ubuntu 24.04 LTS
- Debian 12
>Hinweis Debian 12:
>In den Quellen ist FFmpeg 5.1.6. Komplexe drawtext-Expressions (z. B. '%{pts\:hms} LIVE SCORE: %{eif\:random(100)}-%{eif\:random(100)}') sind erst ab libavfilter 9 (FFmpeg 6+) zuverlässig.
>FFmpeg 5.x hat bekannte Parser-Einschränkungen bei eif und mehrfachen %{}-Platzhaltern.

## 🎯 Kompatible Streaming-Empfänger:
- MediaMTX (SRT → HLS/WebRTC)
- Datarhei Restreamer
- NGINX mit RTMP-Modul
- Wowza Streaming Engine
- OBS (als SRT-Receiver)

## ⚡ Schnellinstallation

```bash
sudo apt update
sudo apt install -y git ffmpeg python3 fonts-dejavu-core
wget -qO- https://raw.githubusercontent.com/richtertoralf/ffmpeg-Teststreams/main/install.sh | sudo bash
```
Die Installation:
- kopiert Skripte und systemd-Unit
- legt /etc/ffmpeg_streams/ an
- kopiert die streams.conf aus dem Repo nach /etc/ffmpeg_streams/streams.conf
- erzeugt daraus die .ini-Dateien

Passe danach bei Bedarf /etc/ffmpeg_streams/streams.conf an (z. B. Ziel-Host), und führe erneut aus:
```
sudo python3 /usr/local/bin/ini-gen.py
```

## 🔧 Manuelle Installation

```bash
# Verzeichnis + zentrale Konfig
sudo install -d -m 0755 /etc/ffmpeg_streams
sudo install -m 0644 streams.conf /etc/ffmpeg_streams/streams.conf

# Skripte
sudo install -m 0755 ffmpeg_teststream.sh   /usr/local/bin/ffmpeg_teststream.sh
sudo install -m 0755 manage-teststreams.sh  /usr/local/bin/manage-teststreams.sh
sudo install -m 0755 ini-gen.py             /usr/local/bin/ini-gen.py

# INIs aus streams.conf erzeugen (erst jetzt, damit Konfig sicher da ist)
sudo python3 /usr/local/bin/ini-gen.py

# systemd-Unit installieren und neu einlesen
sudo install -m 0644 ffmpeg_stream@.service /etc/systemd/system/ffmpeg_stream@.service
sudo systemctl daemon-reload

```

## ⚙️ Zentrale Konfiguration (streams.conf)
Ort: /etc/ffmpeg_streams/streams.conf  
Erzeuge für jeden Stream eine .ini-Datei im Verzeichnis /etc/ffmpeg_streams/.  
**Format:**  
- Globale Defaults als KEY=VALUE  
- Pro Stream eine Zeile: NAME;TYPE;FPS;BITRATE;TARGET_HOST;TARGET_PORT;AUDIO  

**Beispiel:** `/etc/ffmpeg_streams/testpattern-sport.ini`

```ini
# Globale Defaults
WIDTH=1920
HEIGHT=1080
PRESET=ultrafast
DEFAULT_PORT=8890

# Streams (NAME;TYPE;FPS;BITRATE;TARGET_HOST;TARGET_PORT;AUDIO)
# AUDIO=yes typischerweise bei: basic, motion, smptebars, sport

testpattern-basic;basic;30;2M;10.10.11.11;8890;yes
testpattern-smptebars;smptebars;30;3M;10.10.11.11;8890;yes
testpattern-motion;motion;30;4M;10.10.11.11;8890;yes
testpattern-noise;noise;30;5M;10.10.11.11;8890;no
testpattern-black;black;30;1M;10.10.11.11;8890;no
testpattern-clock;clock;30;3M;10.10.11.11;8890;no
testpattern-sport-motion;sport-motion;50;4M;10.10.11.11;8890;no
testpattern-smpte-noise;smpte-noise;30;2M;10.10.11.11;8890;no
testpattern-full-noise;full-noise;30;1M;10.10.11.11;8890;no
testpattern-sport;sport;60;2M;10.10.11.11;8890;yes
testpattern-scoreboard;scoreboard;50;4M;10.10.11.11;8890;no

```
Nach jeder Änderung an streams.conf:
```
sudo python3 /usr/local/bin/ini-gen.py

```


## 🚀 Streams starten/stoppen

```bash
sudo systemctl start ffmpeg_stream@testpattern-sport
sudo systemctl stop  ffmpeg_stream@testpattern-sport

```
Alternativ mit Helper:
```
sudo manage-teststreams.sh list        # alle verfügbaren Streams (.ini)
sudo manage-teststreams.sh running     # aktuell aktive Dienste
sudo manage-teststreams.sh start NAME
sudo manage-teststreams.sh stop  NAME
sudo manage-teststreams.sh status NAME
sudo manage-teststreams.sh start-all
sudo manage-teststreams.sh stop-all
sudo manage-teststreams.sh status-all  # kompakt (✅ ⚠️ ❌ ❓)

```

## 📜 systemd-Template

`/etc/systemd/system/ffmpeg_stream@.service`:

```ini
[Unit]
Description=FFmpeg Test Stream (%i)
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/ffmpeg_teststream.sh %i
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target

```
## 🔗 Ablauf

```swift
systemd → ffmpeg_stream@<name>.service
      → /usr/local/bin/ffmpeg_teststream.sh <name>
      → /etc/ffmpeg_streams/<name>.ini (automatisch aus streams.conf erzeugt)
      → ffmpeg mit passenden Filtern/Codecs/Ziel (SRT)

```
## 🔗 Zusammenspiel: systemd, Skript, INI

```text
systemd unit → ffmpeg_stream@<name>.service
        ↓
Bash-Skript → /usr/local/bin/ffmpeg_teststream.sh <name>
        ↓
INI-Datei → /etc/ffmpeg_streams/<name>.ini
        ↓
FFmpeg wird mit passenden Filtern, Codecs und Zielen ausgeführt
```

## 🐞 Diagnose
```bash
journalctl -u ffmpeg_stream@testpattern-sport.service -n 100 --no-pager

```

## 🛠 manage-teststreams.sh – Steuerung aller Teststreams

### 🧭 Verfügbare Befehle
```bash
sudo manage-teststreams.sh list
# Zeigt alle verfügbaren Streams (.ini-Dateien)

sudo manage-teststreams.sh running
# Zeigt alle aktiven systemd-Dienste

sudo manage-teststreams.sh start <name>
# Startet den Stream mit dem angegebenen Namen

sudo manage-teststreams.sh stop <name>
# Stoppt den Stream

sudo manage-teststreams.sh status <name>
# Zeigt vollständigen systemctl status für diesen Stream

sudo manage-teststreams.sh start-all
# Startet alle konfigurierten Streams

sudo manage-teststreams.sh stop-all
# Stoppt alle laufenden Streams

sudo manage-teststreams.sh status-all
# Kompakter Status aller Streams (✅ ⚠️ ❌ ❓)

```

## 🔍 FFmpeg-Hinweise
FFmpeg wird mit `-re` aufgerufen, um eine realistische Echtzeit-Wiedergabe zu gewährleisten. Du kannst durch Anpassung von `FPS` und `BITRATE` deine Testlast gezielt steuern.

### Beispielaufruf im Skript `ffmpeg_testsream.sh`
```bash
    ffmpeg -re "${VIDEO_ARGS[@]}" "${AUDIO_ARGS[@]}" \
        -vcodec libx264 -preset "$PRESET" -pix_fmt yuv420p -b:v "$BITRATE" \
        -f mpegts "$URL"
```

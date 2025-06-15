# FFmpeg Teststreams mit systemd

Dieses Repository enthält ein Bash-Skript zur Erzeugung von FFmpeg-Teststreams für verschiedene Anwendungszwecke. Die Streams werden über systemd als Dienste verwaltet und basieren auf `.ini`-Konfigurationsdateien.

## ⚡ Schnellinstallation

```bash
sudo apt update
sudo apt install -y git ffmpeg python3 fonts-dejavu-core
wget -qO- https://raw.githubusercontent.com/richtertoralf/ffmpeg-Teststreams/main/install.sh | bash
```
Diese Befehle klonen das Repository, installieren alle benötigten Skripte, kopieren die systemd-Unit-Datei und erzeugen automatisch Beispiel-INI-Dateien.

## 🔧 Installation per Hand

```bash
sudo mkdir -p /etc/ffmpeg_streams
sudo cp ffmpeg_teststream.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/ffmpeg_teststream.sh
sudo cp ffmpeg_stream@.service /etc/systemd/system/
sudo systemctl daemon-reexec
```

## ⚙️ Konfiguration

Erzeuge für jeden Stream eine .ini-Datei im Verzeichnis /etc/ffmpeg_streams/.

>Dazu kannst du auch das Skript https://github.com/richtertoralf/ffmpeg-Teststreams/blob/main/ini-gen.py verwenden.

**Beispiel:** `/etc/ffmpeg_streams/testpattern-sport.ini`

```ini
TYPE=sport
FPS=50
BITRATE=2M
WIDTH=1920
HEIGHT=1080
PRESET=ultrafast
AUDIO_ENABLED=yes
TARGET_HOST=192.168.95.241
TARGET_PORT=8890
STREAM_ID=testpattern-sport
```
Die Parameter WIDTH, HEIGHT, PRESET, AUDIO_ENABLED und DURATION sind optional. Falls sie fehlen, werden im Skript sinnvolle Standardwerte gesetzt.

## 🚀 Starten eines Streams

```bash
sudo systemctl start ffmpeg_stream@testpattern-sport
```

Dies lädt die Datei /etc/ffmpeg_streams/testpattern-sport.ini und übergibt sie an /usr/local/bin/ffmpeg_teststream.sh, das den passenden FFmpeg-Befehl ausführt.

## 📜 systemd Unit-Datei

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

## 🛠 manage-teststreams.sh – Steuerung aller Teststreams
Das Zusatzskript manage-teststreams.sh vereinfacht die Verwaltung aller FFmpeg-Teststreams, die per systemd als Dienst laufen. Es erkennt automatisch alle .ini-Dateien im Verzeichnis /etc/ffmpeg_streams/ und steuert die zugehörigen Dienste über systemctl.

### 📦 Installation
```bash
sudo cp manage-teststreams.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/manage-teststreams.sh

```
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

>Hinweis:  
>Alle Streams werden über die Template-Unit ffmpeg_stream@.service gestartet, z. B. ffmpeg_stream@testpattern-basic.service.  
>Die .ini-Dateien enthalten dabei Konfigurationsparameter wie TYPE, FPS, BITRATE, WIDTH, HEIGHT usw., die das Verhalten des Streams steuern.  

## 🔍 Empfehlung nach Einsatzzweck

| Name                     | Nutzen                                              | Empfehlung                                         |
|--------------------------|-----------------------------------------------------|----------------------------------------------------|
| testpattern-basic        | Statisches Bild + Ton                               | ✅ Minimal-Check für Encoder/Verbindung             |
| testpattern-smptebars    | Farbbalken                                          | ✅ Farbraum-/Kontrasttests                          |
| testpattern-motion       | Bewegtes Testbild                                   | ✅ Für allgemeine Bewegung / moderate Belastung     |
| testpattern-noise        | Bild + Rauschen                                     | 🔧 Für Encoder-Stresstest                          |
| testpattern-black        | Schwarzbild, kein Ton                               | ✅ Für Platzhalter oder Latenztests                 |
| testpattern-clock        | Testbild mit eingeblendeter Uhrzeit                 | ✅ Perfekt für Synchronisation und Vergleich        |
| testpattern-sport-motion | Bewegtes Bild mit Motion Interpolation             | ✅ Für Sport-Streams (hohe Decoder-Last)            |
| testpattern-smpte-noise  | SMPTE + Zellmuster                                  | 🔧 Belastungstest für Dekoder bei 2 Mbit            |
| testpattern-full-noise   | Nur Rauschen                                        | 🔧 Worst-case für Decoder                          |
| testpattern-sport        | Bewegtes Testbild + Ton                             | ✅ Ideal für realistische Sporttests                |
| testpattern-scoreboard   | Bewegung + Lauftext                                 | ✅ Simuliert echten Sportstream mit Anzeige         |

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
- Das **systemd-Template** `ffmpeg_stream@.service` startet `/usr/local/bin/ffmpeg_teststream.sh <name>`
- Das Bash-**Skript** liest die passende `.ini`-Datei aus `/etc/ffmpeg_streams/<name>.ini`
- Die `.ini` enthält den Typ (z. B. `basic`, `motion`, `scoreboard`), Ziel-IP, Port und Bitrate
- Je nach Typ wird ein anderer FFmpeg-Befehl ausgeführt

## 🐞 Fehlerdiagnose
```bash
# Letzte Logs für einen Stream anzeigen
journalctl -u ffmpeg_stream@testpattern-sport.service -n 50 --no-pager

```

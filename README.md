# FFmpeg Teststreams mit systemd

Dieses Repository enthält ein Bash-Skript zur Erzeugung von FFmpeg-Teststreams für verschiedene Anwendungszwecke. Die Streams werden über systemd als Dienste verwaltet und basieren auf `.ini`-Konfigurationsdateien.

## 🔧 Installation

```bash
sudo mkdir -p /etc/ffmpeg_streams
sudo cp ffmpeg_teststream.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/ffmpeg_teststream.sh
sudo cp ffmpeg_stream@.service /etc/systemd/system/
sudo systemctl daemon-reexec
```

## ⚙️ Konfiguration

Erzeuge für jeden Stream eine INI-Datei im Verzeichnis `/etc/ffmpeg_streams/`:

**Beispiel:** `/etc/ffmpeg_streams/testpattern-sport.ini`

```ini
TYPE=sport
FPS=50
BITRATE=2M
TARGET_HOST=192.168.95.241
TARGET_PORT=8890
STREAM_ID=testpattern-sport
```

## 🚀 Starten eines Streams

```bash
sudo systemctl start ffmpeg_stream@testpattern-sport
```

Beim Start wird die Datei `/etc/ffmpeg_streams/testpattern-sport.ini` geladen und an das Bash-Skript `/usr/local/bin/ffmpeg_teststream.sh` übergeben. Dieses startet den passenden FFmpeg-Befehl basierend auf dem `TYPE`.

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

## 🔗 Zusammenhang: Skript, INI, systemd

- Das **systemd-Template** `ffmpeg_stream@.service` startet `/usr/local/bin/ffmpeg_teststream.sh <name>`
- Das Bash-**Skript** liest die passende `.ini`-Datei aus `/etc/ffmpeg_streams/<name>.ini`
- Die `.ini` enthält den Typ (z. B. `basic`, `motion`, `scoreboard`), Ziel-IP, Port und Bitrate
- Je nach Typ wird ein anderer FFmpeg-Befehl ausgeführt

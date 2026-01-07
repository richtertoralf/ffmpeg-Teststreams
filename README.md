# FFmpeg Teststreams mit systemd

![Status](https://img.shields.io/badge/status-stable-brightgreen)
![Operation](https://img.shields.io/badge/operation-continuous-green)
![FFmpeg](https://img.shields.io/badge/ffmpeg-%E2%89%A56.x-blue)
![systemd](https://img.shields.io/badge/systemd-template--unit-blue)

> **Stabile Betriebsvariante**  
> Zentrale Konfiguration, systemd-Templates und reproduzierbare FFmpeg-Teststreams – geeignet für Dauerbetrieb.

Frühere experimentelle Skripte, Filter-Playgrounds und Entwicklungsstufen sind im Archiv-Repository dokumentiert:  
👉 https://github.com/richtertoralf/testStreamGenerator

Dieses Repository verwaltet FFmpeg-Teststreams **deklarativ** über systemd.
Alle Streams werden zentral beschrieben und automatisch in systemd-Dienste überführt.

---

## Beispiele

Siehe **[Examples.md](./Examples.md)** für Muster-Streams, Konfigurationsbeispiele und getestete Setups.

---

## Getestet auf

- Ubuntu 22.04 LTS  
- Ubuntu 24.04 LTS  
- Debian 12  

**Hinweis zu Debian 12:**  
Die Paketquellen enthalten FFmpeg 5.1.6.  
Komplexe `drawtext`-Expressions (z. B. mit `eif` oder mehrfachen `%{}`) sind erst ab **libavfilter 9 (FFmpeg 6+)** zuverlässig.  
FFmpeg 5.x hat bekannte Parser-Einschränkungen.  

---

## Kompatible Streaming-Empfänger

- MediaMTX (SRT → HLS / WebRTC)
- Datarhei Restreamer
- NGINX mit RTMP-Modul
- Wowza Streaming Engine
- OBS Studio (als SRT-Receiver)

---

## Schnellinstallation

```bash
sudo apt update
sudo apt install -y git ffmpeg python3 fonts-dejavu-core
wget -qO- https://raw.githubusercontent.com/richtertoralf/ffmpeg-Teststreams/main/install.sh | sudo bash

```
`install.sh` installiert Dateien, legt aber noch keine Dienste automatisch an und startet keine Streams.

### Quick Start (nach der Installation)

1. Beispiel-`streams.conf` unter `/etc/ffmpeg_streams/streams.conf` anpassen
2. INI-Dateien erzeugen: `sudo python3 /usr/local/bin/ini-gen.py`
3. Stream starten: `sudo manage-teststreams.sh start testpattern-sport`

### Info

Die Installation:
- legt /etc/ffmpeg_streams/ an
- installiert Skripte nach /usr/local/bin
- installiert das systemd-Template
- kopiert streams.conf
- erzeugt initial die .ini-Dateien

**Die Installation kopiert eine Beispiel-`streams.conf` aus dem Repository nach `/etc/ffmpeg_streams/streams.conf`.**

Diese Datei dient als Startkonfiguration und **muss anschließend an die eigene Umgebung angepasst werden**
(z. B. Ziel-Host, Port, Anzahl und Typ der Streams).


## Bedienung
**manage-teststreams.sh – Steuerung aller Teststreams**

Verfügbare Befehle:

```bash
manage-teststreams.sh list
# Zeigt alle verfügbaren Streams (.ini-Dateien)

manage-teststreams.sh running
# Zeigt alle aktiven systemd-Dienste

sudo manage-teststreams.sh start <name>
# Startet den Stream mit dem angegebenen Namen

sudo manage-teststreams.sh stop <name>
# Stoppt den Stream

manage-teststreams.sh status <name>
# Zeigt vollständigen systemctl status für diesen Stream

sudo manage-teststreams.sh start-all
# Startet alle konfigurierten Streams

sudo manage-teststreams.sh stop-all
# Stoppt alle laufenden Streams

manage-teststreams.sh status-all
# Kompakter Status aller Streams (✅ ⚠️ ❌ ❓)

manage-teststreams.sh -h
# zeigt die integrierte Hilfe

```

## Manuelle Installation

### install.sh

Das Installationsskript:

- installiert Skripte und systemd-Unit-Dateien
- erzeugt keine eigene Konfiguration, sondern kopiert eine Beispiel-streams.conf
- überschreibt keine bestehende streams.conf
- ist idempotent und kann mehrfach ausgeführt werden
- startet keine Streams automatisch



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

## Zentrale Konfiguration (streams.conf)

Bei der Installation wird eine Beispiel-`streams.conf` aus dem Repository nach
`/etc/ffmpeg_streams/streams.conf` kopiert.

Diese Datei ist als **Startpunkt** gedacht und sollte nicht unverändert produktiv verwendet werden.

Erzeuge für jeden Stream eine .ini-Datei im Verzeichnis /etc/ffmpeg_streams/.  
**Format:**  
- globale Defaults als KEY=VALUE  
- Pro Stream eine Zeile:
```ini
NAME;TYPE;FPS;BITRATE;TARGET_HOST;TARGET_PORT;AUDIO  
```

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

**Die erzeugten .ini-Dateien sind abgeleitete Artefakte und sollten nicht manuell bearbeitet werden.**


## Bedienung

Hinweis zu Berechtigungen

* Das Helper-Skript selbst benötigt keine Root-Rechte
* Root-Rechte sind nur erforderlich, wenn systemd-Dienste gestartet oder gestoppt werden
* Es werden System-Units (/etc/systemd/system) verwendet

### Mit systemd (direkt)

```bash
sudo systemctl start ffmpeg_stream@testpattern-sport
sudo systemctl stop  ffmpeg_stream@testpattern-sport

```
### Mit Helper-Skript
```bash
manage-teststreams.sh list
manage-teststreams.sh status-all

sudo manage-teststreams.sh start testpattern-sport
sudo manage-teststreams.sh stop  testpattern-sport

```

## Architektur

### Ablauf

```text
streams.conf
   ↓
ini-gen.py
   ↓
/etc/ffmpeg_streams/<name>.ini
   ↓
systemd template: ffmpeg_stream@.service
   ↓
ffmpeg_teststream.sh <name>
   ↓
FFmpeg → SRT / RTMP / MPEG-TS

```

### Komponenten

- `streams.conf`  
  Zentrale, deklarative Beschreibung aller Teststreams (Single Source of Truth)

- `ini-gen.py`  
  Generator: erzeugt aus `streams.conf` einzelne Stream-INI-Dateien

- `ffmpeg_teststream.sh`  
  Runner: startet FFmpeg anhand einer Stream-INI-Datei

- `ffmpeg_stream@.service`  
  systemd-Template zur Verwaltung der Streams

- `manage-teststreams.sh`  
  Komfort-Wrapper für systemctl (kein eigenes Zustandsmodell)


## systemd-Template

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


## 🐞 Diagnose
```bash
manage-teststreams.sh status testpattern-sport
journalctl -u ffmpeg_stream@testpattern-sport.service -n 100 --no-pager

```



## 🔍 FFmpeg-Hinweise
FFmpeg wird mit `-re` aufgerufen, um eine realistische Echtzeit-Wiedergabe zu gewährleisten. Du kannst durch Anpassung von `FPS` und `BITRATE` deine Testlast gezielt steuern.

### Beispielaufruf im Skript `ffmpeg_testsream.sh`
```bash
    ffmpeg -re "${VIDEO_ARGS[@]}" "${AUDIO_ARGS[@]}" \
        -vcodec libx264 -preset "$PRESET" -pix_fmt yuv420p -b:v "$BITRATE" \
        -f mpegts "$URL"
```

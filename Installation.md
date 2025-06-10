# 🎥 FFmpeg Teststream Generator (Systemd-basiert)

Erzeugt realistische Teststreams (Farbbalken, Bewegtbild, Scoreboard, Schwarzbild) über FFmpeg und sendet sie via **SRT/MPEG-TS** an z. B. MediaMTX oder einen CDN-Eingang. Ideal für Monitoring, Load-Test oder Replay-Setup.

---

## 🔧 Voraussetzungen

- Linux (z. B. Ubuntu 22.04 oder 24.04)
- `ffmpeg` (empfohlen: `>= 6.x`)
- Systemd aktiviert
- Netzwerkzugriff auf Ziel-Streaming-Server

---

## ⚙️ Installation

```bash
sudo apt update && sudo apt install ffmpeg jq curl -y

# Bash-Skript speichern
sudo mkdir -p /usr/local/bin
sudo nano /usr/local/bin/ffmpeg_teststream.sh
sudo chmod +x /usr/local/bin/ffmpeg_teststream.sh
```

---

## 📁 Konfiguration

```bash
sudo mkdir -p /etc/ffmpeg_streams
sudo nano /etc/ffmpeg_streams/testpattern-sport.ini
```

## 🖥️ Systemd-Unit erstellen

```bash
sudo nano /etc/systemd/system/ffmpeg_stream@.service
```

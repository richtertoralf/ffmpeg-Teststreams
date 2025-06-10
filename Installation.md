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

---

## 🖥️ Systemd-Unit erstellen

```bash
sudo nano /etc/systemd/system/ffmpeg_stream@.service
```

## 🚀 Starten & Verwalten

```bash
# Aktivieren
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable --now ffmpeg_stream@testpattern-sport

# Status prüfen
systemctl status ffmpeg_stream@testpattern-sport

# Logs verfolgen
journalctl -u ffmpeg_stream@testpattern-sport -f

# Neustart
sudo systemctl restart ffmpeg_stream@testpattern-sport
```

---

## 🧪 Testen im Browser
Falls du mit MediaMTX + WebRTC arbeitest, erreichst du den Stream z. B. unter:

```
http://<MediaMTX-IP>:8889/testpattern-sport/
```

## 📝 Hinweise
- -re hinter ffmpeg ist entscheidend, damit der Stream nicht zu schnell für Live-Wiedergabe wird.
- Die Framerate FPS und BITRATE kannst du je nach Testziel anpassen.
- Die Unit wird bei Absturz automatisch neu gestartet (Restart=always).

# 📺 Beispiele für FFmpeg-Teststreams

Diese Sammlung zeigt konkrete FFmpeg-Befehle zur Erzeugung von Teststreams. Die Beispiele eignen sich zum lokalen Testen oder zur direkten Übertragung via SRT, RTMP, HLS oder MPEG-TS.

---

## ⚠️ Wichtige Hinweise

- Verwende **immer `-re`**, wenn du testweise streamst. Dadurch sendet FFmpeg in Echtzeit – ideal für Livestreaming.
- Als Ziel kannst du z. B. verwenden:
  - `srt://192.168.0.10:8890`
  - `rtmp://live.example.com/stream`
  - `-f mpegts output.ts` für lokale Datei

---

## 🧪 FFmpeg Teststream Beispiele

> Ziel anpassen: z. B. `srt://192.168.0.10:8890`, `rtmp://...` oder `-f mpegts output.ts`

```bash
# 1️⃣ testpattern-basic – statisches Bild + Sinuston
ffmpeg -re -f lavfi -i testsrc=duration=3600:size=1920x1080:rate=30 \
       -f lavfi -i sine=frequency=1000:sample_rate=44100 \
       -vcodec libx264 -preset ultrafast -pix_fmt yuv420p -b:v 2M \
       -c:a aac -b:a 128k -ar 44100 \
       -f mpegts srt://192.168.0.10:8890

# 2️⃣ testpattern-smptebars – SMPTE-Balken + Ton
ffmpeg -re -f lavfi -i smptebars=size=1920x1080:rate=30 \
       -f lavfi -i sine=frequency=1000 \
       -vcodec libx264 -preset ultrafast -pix_fmt yuv420p -b:v 3M \
       -c:a aac -b:a 128k \
       -f mpegts srt://192.168.0.10:8891

# 3️⃣ testpattern-motion – bewegtes Testbild
ffmpeg -re -f lavfi -i testsrc2=size=1920x1080:rate=30 \
       -f lavfi -i sine=frequency=1000 \
       -vcodec libx264 -preset ultrafast -pix_fmt yuv420p -b:v 4M \
       -c:a aac -b:a 128k \
       -f mpegts srt://192.168.0.10:8892

# 4️⃣ testpattern-noise – Bild + Rauschen
ffmpeg -re -f lavfi -i testsrc2=size=1920x1080:rate=30 \
       -f lavfi -i noise=size=1920x1080:rate=30:flags=grey \
       -filter_complex "[0:v][1:v]overlay=format=yuv420" \
       -vcodec libx264 -preset ultrafast -pix_fmt yuv420p -b:v 5M \
       -an \
       -f mpegts srt://192.168.0.10:8893

# 5️⃣ testpattern-black – Schwarzbild ohne Ton
ffmpeg -re -f lavfi -i color=color=black:size=1920x1080:rate=30 \
       -an \
       -vcodec libx264 -preset ultrafast -pix_fmt yuv420p -b:v 1M \
       -f mpegts srt://192.168.0.10:8894

# 6️⃣ testpattern-clock – Bild + Uhrzeit
ffmpeg -re -f lavfi -i testsrc=size=1920x1080:rate=30 \
       -vf "drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf:text='%{localtime}':fontsize=60:fontcolor=white:x=100:y=100" \
       -vcodec libx264 -preset ultrafast -pix_fmt yuv420p -b:v 3M \
       -an \
       -f mpegts srt://192.168.0.10:8895

# 7️⃣ testpattern-sport-motion – Interpolation für Sport
ffmpeg -re -f lavfi -i testsrc2=size=1920x1080:rate=50 \
       -vf "minterpolate='mc_mode=mi',format=yuv420p" \
       -vcodec libx264 -preset veryfast -b:v 4M \
       -an \
       -f mpegts srt://192.168.0.10:8896

# 8️⃣ testpattern-smpte-noise – Balken + Zellmuster
ffmpeg -re -f lavfi -i smptebars=size=1920x1080:rate=30 \
       -f lavfi -i cellauto=size=1920x1080:rate=30 \
       -filter_complex "[0:v][1:v]overlay=format=yuv420" \
       -vcodec libx264 -preset veryfast -b:v 2M \
       -an \
       -f mpegts srt://192.168.0.10:8897

# 9️⃣ testpattern-full-noise – Vollrauschen (Worst Case)
ffmpeg -re -f lavfi -i noise=size=1920x1080:rate=30:flags=grey \
       -vcodec libx264 -preset veryfast -b:v 1M \
       -an \
       -f mpegts srt://192.168.0.10:8898

# 🔟 testpattern-sport – Bewegung + Sinus-Ton
ffmpeg -re -f lavfi -i testsrc2=size=1920x1080:rate=50 \
       -f lavfi -i sine=frequency=1000 \
       -vcodec libx264 -preset ultrafast -b:v 2M \
       -c:a aac -b:a 128k \
       -f mpegts srt://192.168.0.10:8899

# 1️⃣1️⃣ testpattern-scoreboard – Bewegung + Lauftext
ffmpeg -re -f lavfi -i testsrc2=size=1920x1080:rate=50 \
       -vf "drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf:text='%{pts\\:hms} LIVE SCORE: %{eif\\:random(100)}-%{eif\\:random(100)}':fontsize=60:fontcolor=white:x=100:y=50" \
       -vcodec libx264 -preset ultrafast -b:v 4M \
       -an \
       -f mpegts srt://192.168.0.10:8900
```

# 🔍 Empfehlung nach Einsatzzweck

| Name                       | Nutzen                   | Empfehlung                              |
| -------------------------- | ------------------------ | --------------------------------------- |
| `testpattern-basic`        | Statisches Bild + Ton    | ✅ Minimal-Check für Encoder/Verbindung  |
| `testpattern-smptebars`    | Farbbalken               | ✅ Farbraum-/Kontrasttests               |
| `testpattern-motion`       | Bewegtbild               | ✅ Für moderate Bewegung / Encoder-Tests |
| `testpattern-noise`        | Rauschüberlagerung       | 🔧 Stresstest für Encoder               |
| `testpattern-black`        | Schwarzbild              | ✅ Platzhalter, Latenzprüfung            |
| `testpattern-clock`        | Uhrzeit eingeblendet     | ✅ Synchronisations-/Latenzvergleiche    |
| `testpattern-sport-motion` | Bewegung + Interpolation | ✅ Realistischer Sportstream, hohe Last  |
| `testpattern-smpte-noise`  | Zellmuster + Balken      | 🔧 Decoder-/Bandbreiten-Stresstest      |
| `testpattern-full-noise`   | Rauschen (grau)          | 🔧 Worst-case Encoding                  |
| `testpattern-sport`        | Sport-Testbild + Ton     | ✅ Typischer SRT-Teststream mit Ton      |
| `testpattern-scoreboard`   | Scoreboard / Bauchbinde  | ✅ Realistische Übertragungssimulation   |

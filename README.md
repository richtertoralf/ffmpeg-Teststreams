# ffmpeg-Teststreams
Varianten von Teststreams die direkt mit ffmpeg erzeugt werden können  
>anstatt von `-f mpegts output.ts` in den folgenden Beispielen das Streamingziel einsetzen, z.B.  
>`srt://x.x.x.x:port`  
>`rtmp://x.x.x.x`

## 1️⃣ Einfaches Testbild + Sinuston
`testpattern-basic`
```bash
ffmpeg -f lavfi -i testsrc=duration=3600:size=1920x1080:rate=30 \
       -f lavfi -i sine=frequency=1000:sample_rate=44100 \
       -vcodec libx264 -preset ultrafast -pix_fmt yuv420p -b:v 2M \
       -c:a aac -b:a 128k -ar 44100 \
       -f mpegts output.ts
```
→ Standard testsrc, 1h lang, 1920x1080@30fps, 2 MBit Video, 1000 Hz Sinus-Ton  
Ziel: Player-Test, Decoder-Test
## 2️⃣ Buntes Testbild (smptebars) + Sinuston
`testpattern-smptebars`
```bash
ffmpeg -f lavfi -i smptebars=size=1920x1080:rate=30 \
       -f lavfi -i sine=frequency=1000 \
       -vcodec libx264 -preset ultrafast -pix_fmt yuv420p -b:v 3M \
       -c:a aac -b:a 128k \
       -f mpegts output.ts
```
→ SMPTE-Balken  
→ gut zum Testen von Farbräumen, Helligkeit/Kontrast
## 3️⃣ Bewegtes Testbild (testsrc2)
`testpattern-motion`
```bash
ffmpeg -f lavfi -i testsrc2=size=1920x1080:rate=30 \
       -f lavfi -i sine=frequency=1000 \
       -vcodec libx264 -preset ultrafast -pix_fmt yuv420p -b:v 4M \
       -c:a aac -b:a 128k \
       -f mpegts output.ts
```
→ testsrc2 hat Bewegung  
→ gut zum Encoder-Stresstest (GOP-Effizienz prüfen)  
## 4️⃣ Rauschen / Stresstest für Encoder
`testpattern-noise`
```bash
ffmpeg -f lavfi -i nullsrc=size=1920x1080:rate=30 \
       -f lavfi -i anoisesrc=color=white \
       -filter_complex "[0:v][1:v]overlay=format=yuv420" \
       -vcodec libx264 -preset ultrafast -pix_fmt yuv420p -b:v 5M \
       -an \
       -f mpegts output.ts
```
→ Weißes Rauschen über Schwarz  
→ maximal schlechte Kompression → Worst-Case-Test  
## 5️⃣ Schwarzbild + Stumm (nur leeres Video)
`testpattern-black`
```bash
ffmpeg -f lavfi -i color=color=black:size=1920x1080:rate=30 \
       -an \
       -vcodec libx264 -preset ultrafast -pix_fmt yuv420p -b:v 1M \
       -f mpegts output.ts
```
→ Minimaler Stream (leerer schwarzer Stream)  
→ praktisch für Latenztests / Dummy-Streams
## 6️⃣ Moving Clock / Timer im Video
`testpattern-clock`
```bash
ffmpeg -f lavfi -i testsrc=size=1920x1080:rate=30 \
       -vf "drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf:text='%{localtime}':fontsize=60:fontcolor=white:x=100:y=100" \
       -vcodec libx264 -preset ultrafast -pix_fmt yuv420p -b:v 3M \
       -an \
       -f mpegts output.ts
```
→ Live-Zeit eingeblendet  
→ super für Sync- und Latenztests bei mehreren Streams!
## 7️⃣ testsrc2 + Bewegungsunschärfe → simuliert sportliche Bewegung
`testpattern-sport-motion`
```bash
ffmpeg -f lavfi -i testsrc2=size=1920x1080:rate=50 \
       -vf "minterpolate='mc_mode=mi',format=yuv420p" \
       -vcodec libx264 -preset veryfast -b:v 4M \
       -an \
       -f mpegts output.ts
```
👉 Bewegtes Testbild, künstlich "flüssiger" durch Motion Compensation  
→ Sehr brauchbar für Sport → Decoder-Last hoch  
→ z.B. 50 fps bei 4 Mbit → realistisch für deine Streams  
## 8️⃣ smptebars + random noise overlay → hohe Bewegung / Detail
`testpattern-smpte-noise`
```bash
ffmpeg -f lavfi -i smptebars=size=1920x1080:rate=30 \
       -f lavfi -i cellauto=size=1920x1080:rate=30 \
       -filter_complex "[0:v][1:v]overlay=format=yuv420" \
       -vcodec libx264 -preset veryfast -b:v 2M \
       -an \
       -f mpegts output.ts
```
👉 SMPTE Balken + animiertes Zellmuster → dauernde Bildveränderung  
→ Encoder- und Decoder-Stresstest  
→ Gut für 2 Mbit/s Sportprofil  
## 9️⃣ Vollbild Noise (maximale Bewegung) → worst case
`testpattern-full-noise`
```bash
ffmpeg -f lavfi -i anoisesrc=color=white:size=1920x1080:rate=30 \
       -vcodec libx264 -preset veryfast -b:v 1M \
       -an \
       -f mpegts output.ts
```
👉 Weißes Rauschen → maximal schlecht komprimierbar  
→ Ideal für 1 Mbit Profil testen  
→ bleibt Decoder stabil?  
## 🔟 testsrc2 + Sinus-Ton → "Sport-Teststream normal"
`testpattern-sport`
```bash
ffmpeg -f lavfi -i testsrc2=size=1920x1080:rate=50 \
       -f lavfi -i sine=frequency=1000 \
       -vcodec libx264 -preset ultrafast -b:v 2M \
       -c:a aac -b:a 128k \
       -f mpegts output.ts
```
👉 Bewegung + Ton  
→ so wie dein typischer Sportstream  
→ 50 fps + 2 Mbit  
## 1️⃣1️⃣ Testsrc2 + Random Texte (simuliert Scoreboard / Bauchbinde)
`testpattern-scoreboard`
```bash
ffmpeg -f lavfi -i testsrc2=size=1920x1080:rate=50 \
       -vf "drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf:text='%{pts\:hms} LIVE SCORE: %{eif\:random(100)}-%{eif\:random(100)}':fontsize=60:fontcolor=white:x=100:y=50" \
       -vcodec libx264 -preset ultrafast -b:v 4M \
       -an \
       -f mpegts output.ts
```
👉 Bewegung + Lauftext / Scoreboard  
→ typisch Sportübertragung  
→ 4 Mbit Profil  

---

# 🔍 Empfehlung nach Einsatzzweck

| Name                    | Nutzen                                          | Empfehlung                                      |
|-------------------------|--------------------------------------------------|--------------------------------------------------|
| `testpattern-basic`     | Statisches Bild + Ton                           | ✅ Minimal-Check für Encoder/Verbindung          |
| `testpattern-smptebars` | Farbbalken                                      | ✅ Farbraum-/Kontrasttests                       |
| `testpattern-motion`    | Bewegtes Testbild                               | ✅ Für allgemeine Bewegung / moderate Belastung  |
| `testpattern-noise`     | Bild + Rauschen                                 | 🔧 Für Encoder-Stresstest                        |
| `testpattern-black`     | Schwarzbild, kein Ton                           | ✅ Für Platzhalter oder Latenztests              |
| `testpattern-clock`     | Testbild mit eingeblendeter Uhrzeit             | ✅ Perfekt für Synchronisation und Vergleich     |
| `testpattern-sport-motion` | Bewegtes Bild mit Motion Interpolation     | ✅ Für Sport-Streams (hohe Decoder-Last)         |
| `testpattern-smpte-noise` | SMPTE + Zellmuster                          | 🔧 Belastungstest für Dekoder bei 2 Mbit         |
| `testpattern-full-noise` | Nur Rauschen                                 | 🔧 Worst-case für Decoder                        |
| `testpattern-sport`     | Bewegtes Testbild + Ton                         | ✅ Ideal für realistische Sporttests             |
| `testpattern-scoreboard`| Bewegung + Lauftext                             | ✅ Simuliert echten Sportstream mit Anzeige      |

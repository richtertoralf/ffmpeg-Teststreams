# ffmpeg-Teststreams
Varianten von Teststreams die direkt mit ffmpeg erzeugt werden können
## 1️⃣ Einfaches Testbild + Sinuston
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
```bash
ffmpeg -f lavfi -i smptebars=size=1920x1080:rate=30 \
       -f lavfi -i sine=frequency=1000 \
       -vcodec libx264 -preset ultrafast -pix_fmt yuv420p -b:v 3M \
       -c:a aac -b:a 128k \
       -f mpegts output.ts
```
→ SMPTE-Balken → gut zum Testen von Farbräumen, Helligkeit/Kontrast
## 3️⃣ Bewegtes Testbild (testsrc2)
```bash
ffmpeg -f lavfi -i testsrc2=size=1920x1080:rate=30 \
       -f lavfi -i sine=frequency=1000 \
       -vcodec libx264 -preset ultrafast -pix_fmt yuv420p -b:v 4M \
       -c:a aac -b:a 128k \
       -f mpegts output.ts
```
→ testsrc2 hat Bewegung → gut zum Encoder-Stresstest (GOP-Effizienz prüfen)
## 4️⃣ Rauschen / Stresstest für Encoder
```bash
ffmpeg -f lavfi -i nullsrc=size=1920x1080:rate=30 \
       -f lavfi -i anoisesrc=color=white \
       -filter_complex "[0:v][1:v]overlay=format=yuv420" \
       -vcodec libx264 -preset ultrafast -pix_fmt yuv420p -b:v 5M \
       -an \
       -f mpegts output.ts
```
→ Weißes Rauschen über Schwarz → maximal schlechte Kompression → Worst-Case-Test
## 5️⃣ Schwarzbild + Stumm (nur leeres Video)
```bash
ffmpeg -f lavfi -i color=color=black:size=1920x1080:rate=30 \
       -an \
       -vcodec libx264 -preset ultrafast -pix_fmt yuv420p -b:v 1M \
       -f mpegts output.ts
```
→ Minimaler Stream (leerer schwarzer Stream) → praktisch für Latenztests / Dummy-Streams
## 6️⃣ Moving Clock / Timer im Video
```bash
ffmpeg -f lavfi -i testsrc=size=1920x1080:rate=30 \
       -vf "drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf:text='%{localtime}':fontsize=60:fontcolor=white:x=100:y=100" \
       -vcodec libx264 -preset ultrafast -pix_fmt yuv420p -b:v 3M \
       -an \
       -f mpegts output.ts
```
→ Live-Zeit eingeblendet → super für Sync- und Latenztests bei mehreren Streams!

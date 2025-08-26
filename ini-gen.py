#!/usr/bin/env python3
from pathlib import Path

CONF_FILE = Path("/etc/ffmpeg_streams/streams.conf")
OUTPUT_DIR = Path("/etc/ffmpeg_streams")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

def parse_conf(path: Path):
    """
    Liest die zentrale streams.conf.
    - KEY=VALUE Zeilen => globale Defaults
    - NAME;TYPE;FPS;BITRATE;TARGET_HOST;TARGET_PORT;AUDIO => Stream-Definition
    """
    globals_ = {}
    streams = []
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if "=" in line and ";" not in line:
            k, v = line.split("=", 1)
            globals_[k.strip()] = v.strip()
        elif ";" in line:
            parts = [p.strip() for p in line.split(";")]
            if len(parts) < 7:
                raise ValueError(f"Ungültige Zeile in {path}: {line}")
            name, typ, fps, bitrate, host, port, audio = parts
            streams.append({
                "NAME": name,
                "TYPE": typ,
                "FPS": fps,
                "BITRATE": bitrate,
                "HOST": host,
                "PORT": port,
                "AUDIO": audio.lower(),
            })
    return globals_, streams

def main():
    if not CONF_FILE.exists():
        raise SystemExit(f"❌ Config {CONF_FILE} nicht gefunden.")

    globals_, streams = parse_conf(CONF_FILE)

    width = globals_.get("WIDTH", "1920")
    height = globals_.get("HEIGHT", "1080")
    preset = globals_.get("PRESET", "ultrafast")
    default_port = globals_.get("DEFAULT_PORT", "8890")

    for s in streams:
        ini_text = (
            f"TYPE={s['TYPE']}\n"
            f"FPS={s['FPS']}\n"
            f"BITRATE={s['BITRATE']}\n"
            f"WIDTH={width}\n"
            f"HEIGHT={height}\n"
            f"PRESET={preset}\n"
            f"AUDIO_ENABLED={s['AUDIO']}\n"
            f"TARGET_HOST={s['HOST']}\n"
            f"TARGET_PORT={s['PORT'] or default_port}\n"
            f"STREAM_ID={s['NAME']}\n"
        )
        ini_path = OUTPUT_DIR / f"{s['NAME']}.ini"
        ini_path.write_text(ini_text)

    print(f"✅ {len(streams)} INI-Dateien wurden in '{OUTPUT_DIR}' erzeugt.")

if __name__ == "__main__":
    main()

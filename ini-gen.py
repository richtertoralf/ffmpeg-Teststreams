from pathlib import Path

# Konfiguration für jeden Streamtyp
default_width = 1920
default_height = 1080
default_preset = "ultrafast"

# Typen, die über den gemeinsamen FFmpeg-Audioblock laufen
types_with_audio = {"basic", "motion", "smptebars", "sport"}

# Definition der Teststream-Varianten
streams = [
    ("testpattern-basic",       "basic",        30, "2M"),
    ("testpattern-smptebars",   "smptebars",    30, "3M"),
    ("testpattern-motion",      "motion",       30, "4M"),
    ("testpattern-noise",       "noise",        30, "5M"),
    ("testpattern-black",       "black",        30, "1M"),
    ("testpattern-clock",       "clock",        30, "3M"),
    ("testpattern-sport-motion","sport-motion", 50, "4M"),
    ("testpattern-smpte-noise", "smpte-noise",  30, "2M"),
    ("testpattern-full-noise",  "full-noise",   30, "1M"),
    ("testpattern-sport",       "sport",        60, "2M"),
    ("testpattern-scoreboard",  "scoreboard",   50, "4M")
]

# Zielverzeichnis
output_dir = Path("teststream_inis")
output_dir.mkdir(parents=True, exist_ok=True)

# Dateien erzeugen
for name, typ, fps, bitrate in streams:
    audio_enabled = "yes" if typ in types_with_audio else "no"
    content = f"""TYPE={typ}
FPS={fps}
BITRATE={bitrate}
WIDTH={default_width}
HEIGHT={default_height}
PRESET={default_preset}
AUDIO_ENABLED={audio_enabled}
TARGET_HOST=192.168.95.241
TARGET_PORT=8890
STREAM_ID={name}
"""
    ini_path = output_dir / f"{name}.ini"
    ini_path.write_text(content)

print(f"{len(streams)} INI-Dateien wurden erfolgreich generiert im Verzeichnis '{output_dir}'")

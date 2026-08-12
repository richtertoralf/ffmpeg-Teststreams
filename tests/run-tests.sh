#!/usr/bin/env bash
set -euo pipefail

REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_TMP=$(mktemp -d)
trap 'rm -rf "$TEST_TMP"' EXIT

pass_count=0

pass() {
    printf 'ok - %s\n' "$1"
    pass_count=$((pass_count + 1))
}

fail() {
    printf 'not ok - %s\n' "$1" >&2
    exit 1
}

assert_fails() {
    description="$1"
    shift
    if "$@" >"$TEST_TMP/output" 2>&1; then
        fail "$description"
    fi
    pass "$description"
}

generate_inis() {
    config_file="$1"
    output_dir="$2"
    python3 - "$REPO_DIR" "$config_file" "$output_dir" <<'PY'
import importlib.util
import sys
from pathlib import Path

repo_dir, config_file, output_dir = map(Path, sys.argv[1:])
spec = importlib.util.spec_from_file_location("ini_gen", repo_dir / "ini-gen.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
module.CONF_FILE = config_file
module.OUTPUT_DIR = output_dir
module.main()
PY
}

mkdir -p "$TEST_TMP/bin" "$TEST_TMP/config"

cat >"$TEST_TMP/bin/ffmpeg" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >"$FFMPEG_ARGS_FILE"
EOF
chmod +x "$TEST_TMP/bin/ffmpeg"

cat >"$TEST_TMP/bin/systemctl" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$SYSTEMCTL_LOG"
EOF
chmod +x "$TEST_TMP/bin/systemctl"

assert_realtime_inputs() {
    args_file="$1"
    input_count=$(grep -c '^-i$' "$args_file")
    realtime_count=$(grep -c '^-re$' "$args_file")
    [ "$input_count" -eq "$realtime_count" ] || return 1

    awk '
        /^-re$/ { realtime = 1; next }
        /^-i$/ {
            if (!realtime) exit 1
            realtime = 0
        }
    ' "$args_file"
}

types=(basic smptebars motion noise black clock sport-motion smpte-noise full-noise sport scoreboard)
audio_types=(basic smptebars motion sport)

for type in "${types[@]}"; do
    audio=no
    for audio_type in "${audio_types[@]}"; do
        [ "$type" = "$audio_type" ] && audio=yes
    done

    cat >"$TEST_TMP/config/$type.ini" <<EOF
TYPE=$type
FPS=30
BITRATE=2M
AUDIO_ENABLED=$audio
TARGET_HOST=127.0.0.1
TARGET_PORT=8890
STREAM_ID=$type
EOF

    args_file="$TEST_TMP/ffmpeg-$type.args"
    PATH="$TEST_TMP/bin:$PATH" CONFIG_DIR="$TEST_TMP/config" FFMPEG_ARGS_FILE="$args_file" \
        bash "$REPO_DIR/ffmpeg_teststream.sh" "$type" >"$TEST_TMP/runner-output"

    if grep -Eiq 'duration=|^-t$|^-to$|^-shortest$' "$args_file"; then
        fail "$type ist als unbegrenzte Standardquelle aufgebaut"
    fi
    assert_realtime_inputs "$args_file" || fail "$type taktet jeden Input in Echtzeit"
done
pass "alle 11 Standardvideoquellen sind unbegrenzt"
pass "alle Video- und Audioinputs werden in Echtzeit aufgebaut"

basic_args="$TEST_TMP/ffmpeg-basic.args"
grep -qx 'srt://127.0.0.1:8890?streamid=publish:basic&pkt_size=1316&latency=2000000' "$basic_args" || \
    fail "Runner rechnet die Standardlatenz in Mikrosekunden um"
pass "FFmpeg-SRT-URL enthält 2000000 Mikrosekunden Standardlatenz"

if grep -qi 'duration' "$basic_args" || grep -q 'DURATION' "$REPO_DIR/ffmpeg_teststream.sh"; then
    fail "basic enthält keine feste duration"
fi
pass "basic enthält keine feste duration"

sport_motion_args="$TEST_TMP/ffmpeg-sport-motion.args"
grep -qx 'testsrc2=size=1920x1080:rate=30' "$sport_motion_args" || \
    fail "sport-motion nutzt testsrc2 mit konfigurierter Auflösung und FPS"
if grep -qi 'minterpolate' "$sport_motion_args" || grep -A2 '^[[:space:]]*sport-motion)' "$REPO_DIR/ffmpeg_teststream.sh" | grep -qi 'minterpolate'; then
    fail "sport-motion verwendet kein minterpolate"
fi
pass "sport-motion nutzt testsrc2 ohne minterpolate"

grep -q '^-nostats$' "$basic_args" || fail "FFmpeg-Fortschrittsausgaben sind reduziert"
grep -q '^warning$' "$basic_args" || fail "FFmpeg-Warnungen bleiben sichtbar"
grep -q '^[[:space:]]*exec ffmpeg ' "$REPO_DIR/ffmpeg_teststream.sh" || fail "Runner ersetzt sich durch FFmpeg"
pass "Runner nutzt exec und journalfreundliche FFmpeg-Optionen"

assert_fails "Runner erkennt fehlenden Streamnamen" bash "$REPO_DIR/ffmpeg_teststream.sh"

cat >"$TEST_TMP/config/incomplete.ini" <<'EOF'
TYPE=basic
TARGET_PORT=8890
STREAM_ID=incomplete
EOF
assert_fails "Runner erkennt fehlende Pflichtwerte" env PATH="$TEST_TMP/bin:$PATH" \
    CONFIG_DIR="$TEST_TMP/config" FFMPEG_ARGS_FILE="$TEST_TMP/incomplete.args" \
    bash "$REPO_DIR/ffmpeg_teststream.sh" incomplete

cat >"$TEST_TMP/config/invalid-latency.ini" <<'EOF'
TYPE=basic
TARGET_HOST=127.0.0.1
TARGET_PORT=8890
STREAM_ID=invalid-latency
SRT_LATENCY_MS=invalid
EOF
assert_fails "Runner erkennt ungültige SRT-Latenz" env PATH="$TEST_TMP/bin:$PATH" \
    CONFIG_DIR="$TEST_TMP/config" FFMPEG_ARGS_FILE="$TEST_TMP/invalid-latency.args" \
    bash "$REPO_DIR/ffmpeg_teststream.sh" invalid-latency

mkdir -p "$TEST_TMP/generated"
cat >"$TEST_TMP/streams.conf" <<'EOF'
WIDTH=1920
HEIGHT=1080
PRESET=ultrafast
DEFAULT_PORT=8890
SRT_LATENCY_MS=2000
seven-fields;basic;30;2M;127.0.0.1;8890;yes
empty-override;basic;30;2M;127.0.0.1;8890;yes;
custom-latency;basic;30;2M;127.0.0.1;8890;yes;500
EOF
generate_inis "$TEST_TMP/streams.conf" "$TEST_TMP/generated" >"$TEST_TMP/generator-output"
grep -qx 'SRT_LATENCY_MS=2000' "$TEST_TMP/generated/seven-fields.ini" || \
    fail "7-Felder-Stream erhält globale SRT-Latenz"
grep -qx 'SRT_LATENCY_MS=2000' "$TEST_TMP/generated/empty-override.ini" || \
    fail "leeres achtes Feld erhält globale SRT-Latenz"
grep -qx 'SRT_LATENCY_MS=500' "$TEST_TMP/generated/custom-latency.ini" || \
    fail "Stream-spezifische SRT-Latenz überschreibt globalen Wert"
pass "Generator unterstützt globale und Stream-spezifische SRT-Latenz"
pass "bestehendes 7-Felder-Format bleibt kompatibel"

PATH="$TEST_TMP/bin:$PATH" CONFIG_DIR="$TEST_TMP/generated" \
    FFMPEG_ARGS_FILE="$TEST_TMP/custom-latency.args" \
    bash "$REPO_DIR/ffmpeg_teststream.sh" custom-latency >"$TEST_TMP/custom-runner-output"
grep -qx 'srt://127.0.0.1:8890?streamid=publish:custom-latency&pkt_size=1316&latency=500000' \
    "$TEST_TMP/custom-latency.args" || fail "individuelle SRT-Latenz wird in Mikrosekunden umgerechnet"
pass "individuelle SRT-Latenz erreicht die FFmpeg-URL in Mikrosekunden"

cat >"$TEST_TMP/invalid-streams.conf" <<'EOF'
SRT_LATENCY_MS=0
invalid;basic;30;2M;127.0.0.1;8890;yes
EOF
assert_fails "Generator erkennt ungültige globale SRT-Latenz" \
    generate_inis "$TEST_TMP/invalid-streams.conf" "$TEST_TMP/generated"

cat >"$TEST_TMP/invalid-stream-latency.conf" <<'EOF'
SRT_LATENCY_MS=2000
invalid;basic;30;2M;127.0.0.1;8890;yes;-1
EOF
assert_fails "Generator erkennt ungültige Stream-spezifische SRT-Latenz" \
    generate_inis "$TEST_TMP/invalid-stream-latency.conf" "$TEST_TMP/generated"

touch "$TEST_TMP/config/alpha.ini" "$TEST_TMP/config/beta.ini"
export SYSTEMCTL_LOG="$TEST_TMP/systemctl.log"
: >"$SYSTEMCTL_LOG"

INI_DIR="$TEST_TMP/config" SYSTEMCTL="$TEST_TMP/bin/systemctl" \
    bash "$REPO_DIR/manage-teststreams.sh" restart alpha >"$TEST_TMP/manager-output"
grep -qx 'restart ffmpeg_stream@alpha.service' "$SYSTEMCTL_LOG" || fail "restart steuert die richtige Unit"
pass "restart steuert die richtige Unit"

: >"$SYSTEMCTL_LOG"
INI_DIR="$TEST_TMP/config" SYSTEMCTL="$TEST_TMP/bin/systemctl" \
    bash "$REPO_DIR/manage-teststreams.sh" restart-all >"$TEST_TMP/manager-output"
for type in alpha beta; do
    grep -qx "restart ffmpeg_stream@$type.service" "$SYSTEMCTL_LOG" || fail "restart-all berücksichtigt $type"
done
pass "restart-all startet alle konfigurierten Units neu"

assert_fails "Manager erkennt fehlenden Befehl" bash "$REPO_DIR/manage-teststreams.sh"
assert_fails "Manager erkennt fehlenden restart-Namen" bash "$REPO_DIR/manage-teststreams.sh" restart
assert_fails "Manager erkennt überzählige restart-all-Argumente" bash "$REPO_DIR/manage-teststreams.sh" restart-all extra

printf '%s Tests erfolgreich.\n' "$pass_count"

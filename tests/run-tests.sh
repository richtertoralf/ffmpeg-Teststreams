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

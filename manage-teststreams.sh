#!/bin/bash

INI_DIR="/etc/ffmpeg_streams"
UNIT_PREFIX="ffmpeg_stream@"
SYSTEMCTL="sudo systemctl"

list_streams() {
    echo "📄 Verfügbare Teststreams (INI-Dateien):"
    for file in "$INI_DIR"/*.ini; do
        name=$(basename "$file" .ini)
        echo "  - $name"
    done
}

running_streams() {
    echo "✅ Aktive Teststreams:"
    $SYSTEMCTL list-units --type=service --state=running | grep "$UNIT_PREFIX" | awk '{print "  - " $1}'
}

start_stream() {
    name="$1"
    if [ -f "$INI_DIR/$name.ini" ]; then
        $SYSTEMCTL start "${UNIT_PREFIX}${name}.service" && echo "🔄 gestartet: $name"
    else
        echo "❌ Stream $name nicht gefunden."
    fi
}

stop_stream() {
    name="$1"
    $SYSTEMCTL stop "${UNIT_PREFIX}${name}.service" && echo "⏹️ gestoppt: $name"
}

start_all() {
    echo "🚀 Starte alle verfügbaren Teststreams:"
    for file in "$INI_DIR"/*.ini; do
        name=$(basename "$file" .ini)
        $SYSTEMCTL start "${UNIT_PREFIX}${name}.service"
        echo "  ➤ gestartet: $name"
    done
}

stop_all() {
    echo "🛑 Stoppe alle laufenden Teststreams:"
    for unit in $($SYSTEMCTL list-units --type=service --state=running | grep "$UNIT_PREFIX" | awk '{print $1}'); do
        $SYSTEMCTL stop "$unit"
        echo "  ➤ gestoppt: $unit"
    done
}

status_stream() {
    name="$1"
    $SYSTEMCTL status "${UNIT_PREFIX}${name}.service"
}

status_all() {
    echo "🔍 Statusübersicht:"
    for file in "$INI_DIR"/*.ini; do
        name=$(basename "$file" .ini)
        state=$($SYSTEMCTL is-active "${UNIT_PREFIX}${name}.service")
        case "$state" in
            active)
                echo "  ✅ $name: running"
                ;;
            failed)
                echo "  ❌ $name: failed"
                ;;
            inactive)
                echo "  ⚠️ $name: inactive"
                ;;
            *)
                echo "  ❓ $name: $state"
                ;;
        esac
    done
}

show_help() {
    cat << EOF
Verwendung: $0 {list|running|start NAME|stop NAME|start-all|stop-all|status NAME|status-all|help}

Befehle:
  list             Zeigt alle verfügbaren Streams (INI-Dateien)
  running          Zeigt alle derzeit laufenden Streams
  start NAME       Startet den angegebenen Stream
  stop NAME        Stoppt den angegebenen Stream
  start-all        Startet alle verfügbaren Streams
  stop-all         Stoppt alle laufenden Streams
  status NAME      Zeigt den Status eines bestimmten Streams
  status-all       Zeigt eine Statusübersicht aller Streams
  help             Zeigt diese Hilfe

Beispiel:
  sudo $0 start testpattern-sport
EOF
}

# Hauptlogik
case "$1" in
    list)
        list_streams
        ;;
    running)
        running_streams
        ;;
    start)
        start_stream "$2"
        ;;
    stop)
        stop_stream "$2"
        ;;
    start-all)
        start_all
        ;;
    stop-all)
        stop_all
        ;;
    status)
        status_stream "$2"
        ;;
    status-all)
        status_all
        ;;
    help|-h|--help)
        show_help
        ;;
    *)
        echo "❓ Unbekannter Befehl: '$1'"
        show_help
        ;;
esac

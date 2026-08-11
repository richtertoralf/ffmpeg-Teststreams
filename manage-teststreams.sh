#!/bin/bash

INI_DIR="${INI_DIR:-/etc/ffmpeg_streams}"
UNIT_PREFIX="ffmpeg_stream@"
SYSTEMCTL="${SYSTEMCTL:-sudo systemctl}"

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
        echo "❌ Stream $name nicht gefunden." >&2
        return 1
    fi
}

stop_stream() {
    name="$1"
    $SYSTEMCTL stop "${UNIT_PREFIX}${name}.service" && echo "⏹️ gestoppt: $name"
}

restart_stream() {
    name="$1"
    if [ -f "$INI_DIR/$name.ini" ]; then
        $SYSTEMCTL restart "${UNIT_PREFIX}${name}.service" && echo "🔁 neu gestartet: $name"
    else
        echo "❌ Stream $name nicht gefunden." >&2
        return 1
    fi
}

start_all() {
    echo "🚀 Starte alle verfügbaren Teststreams:"
    for file in "$INI_DIR"/*.ini; do
        name=$(basename "$file" .ini)
        $SYSTEMCTL start "${UNIT_PREFIX}${name}.service"
        echo "  ➤ gestartet: $name"
    done
}

restart_all() {
    echo "🔁 Starte alle verfügbaren Teststreams neu:"
    for file in "$INI_DIR"/*.ini; do
        name=$(basename "$file" .ini)
        $SYSTEMCTL restart "${UNIT_PREFIX}${name}.service"
        echo "  ➤ neu gestartet: $name"
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
Verwendung: $0 {list|running|start NAME|stop NAME|restart NAME|start-all|stop-all|restart-all|status NAME|status-all|help}

Befehle:
  list             Zeigt alle verfügbaren Streams (INI-Dateien)
  running          Zeigt alle derzeit laufenden Streams
  start NAME       Startet den angegebenen Stream
  stop NAME        Stoppt den angegebenen Stream
  restart NAME     Startet den angegebenen Stream neu
  start-all        Startet alle verfügbaren Streams
  stop-all         Stoppt alle laufenden Streams
  restart-all      Startet alle verfügbaren Streams neu
  status NAME      Zeigt den Status eines bestimmten Streams
  status-all       Zeigt eine Statusübersicht aller Streams
  help             Zeigt diese Hilfe

Beispiel:
  sudo $0 start testpattern-sport
EOF
}

# Hauptlogik
command="${1:-}"

case "$command" in
    list)
        [ "$#" -eq 1 ] || { echo "❌ Verwendung: $0 list" >&2; exit 1; }
        list_streams
        ;;
    running)
        [ "$#" -eq 1 ] || { echo "❌ Verwendung: $0 running" >&2; exit 1; }
        running_streams
        ;;
    start)
        [ "$#" -eq 2 ] && [ -n "$2" ] || { echo "❌ Verwendung: $0 start NAME" >&2; exit 1; }
        start_stream "$2"
        ;;
    stop)
        [ "$#" -eq 2 ] && [ -n "$2" ] || { echo "❌ Verwendung: $0 stop NAME" >&2; exit 1; }
        stop_stream "$2"
        ;;
    restart)
        [ "$#" -eq 2 ] && [ -n "$2" ] || { echo "❌ Verwendung: $0 restart NAME" >&2; exit 1; }
        restart_stream "$2"
        ;;
    start-all)
        [ "$#" -eq 1 ] || { echo "❌ Verwendung: $0 start-all" >&2; exit 1; }
        start_all
        ;;
    stop-all)
        [ "$#" -eq 1 ] || { echo "❌ Verwendung: $0 stop-all" >&2; exit 1; }
        stop_all
        ;;
    restart-all)
        [ "$#" -eq 1 ] || { echo "❌ Verwendung: $0 restart-all" >&2; exit 1; }
        restart_all
        ;;
    status)
        [ "$#" -eq 2 ] && [ -n "$2" ] || { echo "❌ Verwendung: $0 status NAME" >&2; exit 1; }
        status_stream "$2"
        ;;
    status-all)
        [ "$#" -eq 1 ] || { echo "❌ Verwendung: $0 status-all" >&2; exit 1; }
        status_all
        ;;
    help|-h|--help)
        [ "$#" -eq 1 ] || { echo "❌ Verwendung: $0 help" >&2; exit 1; }
        show_help
        ;;
    *)
        if [ -z "$command" ]; then
            echo "❌ Kein Befehl angegeben." >&2
        else
            echo "❓ Unbekannter Befehl: '$command'" >&2
        fi
        show_help
        exit 1
        ;;
esac

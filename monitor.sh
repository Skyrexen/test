#!/bin/bash

LOG_FILE="/var/log/monitoring.log"

MONITORING_URL="https://test.com/monitoring/test/api"

PROCESS_NAME="test"

STATUS_FILE="/tmp/test_process_status.txt"

{
    if pgrep -x "$PROCESS_NAME" >/dev/null; then
        echo "running"
    else
        echo "stopped"
    fi
}

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

check_server() {
    if curl -s --head --request GET "$MONITORING_URL" | grep "200 OK" >/dev/null; then
        return 0
    else
        log "Monitoring server is not available"
        return 1
    fi
}

main() {
    current=$(current_status)
    previous=$(cat "$STATUS_FILE" 2>/dev/null || echo "stopped")


    if [[ "$current" == "running" && "$previous" == "running" ]]; then
        if [[ -f "/tmp/was_stopped" ]]; then
            log "Process $PROCESS_NAME was restarted"
            rm -f "/tmp/was_stopped"
        fi
    fi

    if [[ "$current" == "running" && "$previous" == "stopped" ]]; then
        log "Process $PROCESS_NAME was started"
        touch "/tmp/was_stopped"
    fi

    if [[ "$current" == "running" ]]; then
        if ! check_server; then
            exit 1
        fi
        curl -s -X POST "$MONITORING_URL" -d "status=running" >/dev/null || log "Failed to send monitoring data"
    fi
    echo "$current" > "$STATUS_FILE"
}

main

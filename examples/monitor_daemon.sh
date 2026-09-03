#!/usr/bin/env bash
# Continuous Zyphor background telemetry logger
INTERVAL=5

echo "Starting Zyphor continuous telemetry monitoring (interval: ${INTERVAL}s)..."
while true; do
    zyphor --json >> /var/log/zyphor_telemetry.jsonl 2>/dev/null || true
    sleep $INTERVAL
done

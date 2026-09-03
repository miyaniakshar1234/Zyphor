#!/usr/bin/env python3
"""
Zyphor Webhook Bridge
Periodically queries Zyphor health score and posts alerts if stability drops.
"""
import subprocess
import json
import time

THRESHOLD_CRITICAL = 60

def check_system():
    try:
        res = subprocess.run(["zyphor", "--json"], capture_output=True, text=True, check=True)
        snap = json.loads(res.stdout)
        score = snap["health"]["overall_score"]
        if score < THRESHOLD_CRITICAL:
            print(f"[ALERT] System health degraded: {score}/100! Status: {snap['health']['status']}")
        else:
            print(f"[HEALTHY] System score: {score}/100")
    except Exception as e:
        print(f"Error checking telemetry: {e}")

if __name__ == "__main__":
    check_system()

#!/usr/bin/env python3
"""
Zyphor JSON Telemetry Exporter
Consumes `zyphor --json` and prints structured metrics for monitoring pipelines.
"""
import subprocess
import json
import sys

def main():
    try:
        res = subprocess.run(["zyphor", "--json"], capture_output=True, text=True, check=True)
        data = json.loads(res.stdout)
        print(f"Host CPU: {data['cpu']['model_name']} ({data['cpu']['logical_cores']} threads)")
        print(f"RAM Usage: {data['memory']['used_percent']:.1f}%")
        print(f"Health Score: {data['health']['overall_score']}/100 [{data['health']['status']}]")
    except Exception as e:
        print(f"Failed to query Zyphor: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()

#!/usr/bin/env python3
# Copyright 2026 Lusoris Authors
# Licensed under the Apache License, Version 2.0
"""Cluster tunnel daemon for Hindsight semantic-memory backend.

Maintains a localhost port-forward to service/hindsight in the ai namespace:
  kubectl --namespace=ai port-forward service/hindsight 8888:8888 --address=127.0.0.1

Usage:
  python scripts/tunnel_hindsight.py [--check] [--port 8888]
"""

from __future__ import annotations

import argparse
import subprocess
import sys
import time
import urllib.error
import urllib.request

DEFAULT_PORT = 8888
NAMESPACE = "ai"
SERVICE = "service/hindsight"


def check_health(port: int = DEFAULT_PORT) -> bool:
    """Probe Hindsight health endpoint on loopback."""
    if not (1 <= port <= 65535):
        return False
    url = f"http://127.0.0.1:{port}/v1/default/banks"
    try:
        req = urllib.request.Request(url, method="GET")
        # nosemgrep: python.lang.security.audit.dynamic-urllib-use-detected
        with urllib.request.urlopen(req, timeout=3) as resp:
            return 200 <= resp.status < 300
    except Exception:
        return False


def run_tunnel(port: int = DEFAULT_PORT) -> int:
    """Launch and supervise kubectl port-forward subprocess."""
    print(f"[*] Starting Hindsight tunnel on 127.0.0.1:{port} -> {SERVICE} (ns: {NAMESPACE})...")
    cmd = [
        "kubectl",
        f"--namespace={NAMESPACE}",
        "port-forward",
        SERVICE,
        f"{port}:8888",
        "--address=127.0.0.1",
    ]

    while True:
        try:
            proc = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
            )
            time.sleep(2)
            if check_health(port):
                print(f"[+] Hindsight tunnel active on http://127.0.0.1:{port}.")
            proc.wait()
            print("[!] Port-forward process terminated. Reconnecting in 5s...", file=sys.stderr)
            time.sleep(5)
        except KeyboardInterrupt:
            print("\n[*] Stopping Hindsight tunnel.")
            if "proc" in locals() and proc.poll() is None:
                proc.terminate()
            return 0
        except Exception as exc:
            print(f"[!] Tunnel error: {exc}. Retrying in 10s...", file=sys.stderr)
            time.sleep(10)


def main() -> int:
    """CLI entrypoint for Hindsight tunnel supervisor."""
    parser = argparse.ArgumentParser(description="Hindsight cluster port-forward supervisor")
    parser.add_argument("--check", action="store_true", help="Check if Hindsight is currently reachable")
    parser.add_argument("--port", type=int, default=DEFAULT_PORT, help=f"Local port (default: {DEFAULT_PORT})")
    args = parser.parse_args()

    if args.check:
        healthy = check_health(args.port)
        if healthy:
            print(f"[OK] Hindsight service is reachable on http://127.0.0.1:{args.port}.")
            return 0
        print(f"[FAIL] Hindsight is unreachable on http://127.0.0.1:{args.port}.", file=sys.stderr)
        return 1

    return run_tunnel(args.port)


if __name__ == "__main__":
    sys.exit(main())

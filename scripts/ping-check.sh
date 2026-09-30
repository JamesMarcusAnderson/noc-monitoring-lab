#!/usr/bin/env bash
# ping-check.sh — quick independent latency/loss check against a lab target.
# Usage: ./scripts/ping-check.sh <target> [count]
# Example: ./scripts/ping-check.sh lab-gateway 60
# Exit 0 when loss is under 5%, exit 1 otherwise (usable as a smoke check).
set -euo pipefail

TARGET="${1:?usage: ping-check.sh <target> [count]}"
COUNT="${2:-20}"

echo "Probing ${TARGET} with ${COUNT} ICMP echo requests..."
OUT="$(ping -c "${COUNT}" -i 0.5 -W 2 "${TARGET}" 2>&1)" || true
echo "${OUT}" | tail -n 4

LOSS="$(echo "${OUT}" | grep -oE '[0-9]+% packet loss' | grep -oE '[0-9]+' || echo 100)"
AVG="$(echo "${OUT}" | grep -oE 'min/avg/max[^=]*= [0-9.]+/[0-9.]+' | grep -oE '[0-9.]+/[0-9.]+$' | cut -d/ -f2 || echo '?')"
echo "loss=${LOSS}% avg_rtt_ms=${AVG}"

if [ "${LOSS}" -ge 5 ]; then
  echo "RESULT: DEGRADED (loss >= 5%)"
  exit 1
fi
echo "RESULT: OK"

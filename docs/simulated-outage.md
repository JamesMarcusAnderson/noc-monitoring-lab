# Simulated Outage — Worked Incident Report

> **This is an illustrative example, not a real event.** It shows the shape of
> a useful NOC incident report: what was observed, how it was diagnosed, what
> fixed it, and how the fix was verified. No production system was involved;
> everything below describes a hypothetical lab scenario against the
> `lab-gateway` / `lab-switch-01` targets in `prometheus.yml`.

## Incident: INC-LAB-001 — Loss of connectivity to lab-gateway

| Field | Value |
|---|---|
| Detected | Example: 2026-09-30 02:14 UTC (hypothetical) |
| Detected by | Prometheus alert `ProbeFailed` (ICMP probe to `lab-gateway` failing 3m) |
| Severity | Critical (lab) |
| Duration | ~22 minutes (hypothetical) |
| Reporter | On-call (simulated) |

## Symptoms

1. `ProbeFailed` fired for `lab-gateway` at 02:14; `HighLatency` had been
   warning on the same target since 02:09 (latency climbing 40ms → 900ms).
2. Grafana "NOC Overview" dashboard: Probe Latency panel showed a steady ramp
   on `lab-gateway` only; `lab-switch-01` and `lab-dns-01` stayed flat.
3. `InstanceDown` did **not** fire — node_exporter on the lab host was still
   scraping, so the monitoring pipeline itself was healthy.

## Diagnosis steps

1. **Scoped the blast radius.** Only one target degraded while the others were
   clean, and the monitoring host was fine. That ruled out a monitoring-side
   problem and pointed at the path or the target itself.
2. **Checked the alert sequence.** Latency ramped *before* probes failed —
   classic congestion or dying-link signature, not a sudden power loss.
3. **Correlated with bandwidth.** Interface Bandwidth panel: `lab-gateway`'s
   uplink receive rate had been pinned near the `BandwidthSaturation`
   threshold for ~10 minutes before the incident. A saturated link explains
   both the latency ramp and eventual probe loss.
4. **Ran the local check script** (`scripts/ping-check.sh lab-gateway`) from
   the monitoring host to confirm the Prometheus data independently —
   same ramp, same loss. Two independent measurements agreeing rules out a
   blackbox_exporter misconfiguration.
5. **Hypothesis:** a runaway process on `lab-gateway` flooding its uplink
   (simulated cause for this exercise).

## Root cause (hypothetical)

A simulated bulk-transfer job on `lab-gateway` saturated the uplink,
starving ICMP and management traffic. Not a hardware failure, not a routing
change — congestion.

## Fix (hypothetical)

Rate-limited the offending transfer at the source and confirmed the link
drained. In a real NOC this would be: identify the top talker, throttle or
kill the job per runbook, and confirm with the link owner.

## Verification

- `ProbeFailed` resolved at 02:36; `HighLatency` cleared at 02:38.
- Latency returned to the 35–45ms baseline on the dashboard.
- `scripts/ping-check.sh lab-gateway` showed 0% loss over 60 packets.
- No other alerts fired during or after the window.

## Lessons / follow-ups

- The `BandwidthSaturation` warning fired 10 minutes *before* user-visible
  impact — the early-warning chain worked. Keep that threshold.
- Add a runbook link to the `ProbeFailed` annotation pointing at this doc.
- Consider a separate alert for "latency ramping but probes still passing"
  to catch the next congestion event even earlier.

## What a reviewer should take from this

The value is the method, not the outage: scope first, trust the alert
sequence, correlate across panels, verify with an independent measurement,
then act. That is the whole NOC job in one page.

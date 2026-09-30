# noc-monitoring-lab

NOCs live or die by what they can see. When a link degrades at 2 AM, the
difference between a 5-minute fix and a 2-hour outage is whether anyone was
watching the right metric — and whether the alert that fired actually meant
something. This repo is a small, working network monitoring lab built the way
a NOC would run it: Prometheus scraping, blackbox probes measuring, Grafana
showing, and alerts firing with runbook-grade annotations.

## What the lab monitors

- **Host availability** — `node_exporter` scraped by Prometheus; `up == 0`
  fires `InstanceDown`.
- **Interface status** — per-interface operstate from `node_exporter`;
  `InterfaceDown` fires on non-loopback links.
- **Latency** — ICMP probes via `blackbox_exporter`; `HighLatency` fires
  above 200ms sustained, `ProbeFailed` fires when ping dies entirely.
- **Bandwidth** — per-interface RX/TX rates; `BandwidthSaturation` warns
  near ~800 Mbit/s sustained so you catch congestion before it drops packets.

## Repo structure

```
docker-compose.yml              Prometheus + Grafana + blackbox/node exporters
prometheus.yml                  scrape jobs (self, node, ICMP + HTTP probes)
blackbox.yml                    blackbox_exporter probe modules (icmp, http_2xx)
alerts.yml                      5 alerting rules: availability + performance
grafana/dashboards/noc-overview.json   "NOC Overview" dashboard (auto-provisioned)
grafana/provisioning/dashboards/lab.yml  dashboard provisioning config
docs/simulated-outage.md        worked incident report (illustrative example)
scripts/ping-check.sh           independent ping/latency smoke check
```

## Setup

```bash
docker compose up -d
```

- Grafana: http://localhost:3000 (admin/admin) — the "NOC Overview"
  dashboard loads automatically under the "NOC Lab" folder.
- Prometheus: http://localhost:9090 — check Status > Targets, then
  Alerts to see the rules evaluating.
- Replace the `lab-gateway` / `lab-switch-01` / `lab-dns-01` targets in
  `prometheus.yml` with your own lab hosts, then
  `docker compose restart prometheus`.

## What a reviewer will see

1. A real, `docker compose up`-able monitoring stack — not screenshots of
   one.
2. Alerting rules with honest, tunable thresholds and annotations that read
   like runbook entries.
3. A Grafana dashboard with availability, latency, bandwidth, and an active
   alert list.
4. A worked incident report (`docs/simulated-outage.md`) showing the
   diagnostic method: scope the blast radius, read the alert sequence,
   correlate across panels, verify independently, then act.

## Scope

Lab and simulated environment only. Nothing here touches production systems
or third-party networks — all targets are lab-local placeholders you replace
with your own.

## Attribution

Built on [Prometheus](https://prometheus.io/) (metrics + alerting),
[Grafana](https://grafana.com/) (dashboards), and the Prometheus
`blackbox_exporter` / `node_exporter` — all upstream open-source projects.
This repo contains only original configuration and documentation.

## Keywords

network monitoring, Prometheus, Grafana, alerting, incident response, NOC,
blackbox_exporter, node_exporter, observability, network operations.

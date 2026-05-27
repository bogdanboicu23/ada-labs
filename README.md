# ADA Labs — UTM

Repo cu lucrările de laborator pentru cursul *Arhitectura Datelor și Algoritmilor* (ADA), Universitatea Tehnică a Moldovei.

## Structură

```
ada-labs/
├── lab1/   (TBD)
├── lab2/   (TBD)
└── lab3/   Monitorizarea sistemelor distribuite — Grafana + Prometheus
```

Fiecare folder de lab conține propriul `README` și instrucțiuni de rulare.

## Lab 3 — Grafana + Prometheus

**Temă:** Monitorizarea sistemelor distribuite cu Grafana și Prometheus.

**Stack:**
- `prom/prometheus` — scrape + TSDB
- `prom/node-exporter` — metrici hardware/OS
- `grafana/grafana:10.4.2` — dashboards
- Aplicație externă monitorizată: `DocumentStorage.API` (.NET 8, expune `/metrics` via `prometheus-net.AspNetCore`)

**Pornire:**

```bash
cd lab3
./start_cluster.sh
```

Apoi:
- Grafana → http://localhost:3000 (admin/admin)
- Prometheus → http://localhost:9090
- Node-exporter → http://localhost:9100/metrics



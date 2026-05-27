# ADA Labs — UTM

Repo cu lucrările de laborator pentru cursul *Arhitectura Datelor și Algoritmilor* (ADA), Universitatea Tehnică a Moldovei.

## Structură

```
ada-labs/
├── lab1/   Cripto-puzzle SHA-256 — baseline, OpenMP, OpenMPI
├── lab2/   Cripto-puzzle distribuit — RabbitMQ + multi-language consumers
└── lab3/   Monitorizarea sistemelor distribuite — Grafana + Prometheus
```

Fiecare folder de lab conține propriul `README` și instrucțiuni de rulare.

## Lab 1 — Paralelism: OpenMP & OpenMPI

**Temă:** Algoritm de rezolvare a unui cripto-puzzle SHA-256, în trei variante pentru comparație de performanță.

**Variante:**
- `lab1/default/` — implementare baseline C++ single-threaded
- `lab1/openmp/` — paralelizare automată pe un singur nod cu OpenMP (rulează într-un container Docker)
- `lab1/openmpi/` — distribuit pe mai multe noduri cu OpenMPI (cluster Docker Compose cu SSH)

**Pornire (varianta OpenMPI cluster):**

```bash
cd lab1/openmpi
./start_cluster.sh
./run_computations_on_cluster.sh
```

Binarele compilate (`lab1`, `lab1_openmp`, `lab1_openmpi`) sunt git-ignored — recompilează cu `./compile.sh` în fiecare variantă.

## Lab 2 — RabbitMQ Cripto-Puzzle

**Temă:** Sistem distribuit pentru rezolvarea unui cripto-puzzle, cu producer/consumer-i scriși în mai multe limbaje (Ruby, Python, C#) comunicând prin RabbitMQ.

**Stack:**
- `rabbitmq:3-management-alpine` — broker de mesaje (UI: http://localhost:15672, guest/guest)
- `lab2_producer` / `lab2_consumer` — containere SSH cu Ruby (`ruby_server.rb`, `ruby_computer.rb`)
- `python_computer` — consumer Python (`python_computer.py`, librăria `pika`)
- `cs_computer` — consumer C# (.NET, în `CsComputer/`)

**Pornire:**

```bash
cd lab2
./start_cluster.sh
```

Vezi [lab2/README](lab2/README) pentru pașii compleți (rulare producer + consumer Ruby) și [lab2/REPORT.md](lab2/REPORT.md) pentru raportul detaliat al laboratorului.

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



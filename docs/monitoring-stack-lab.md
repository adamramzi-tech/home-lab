# Monitoring Stack Lab

## Overview

This project focused on building a containerized infrastructure monitoring stack using Docker Compose, Prometheus, Node Exporter, and Grafana.

The monitoring environment was designed to collect, store, and visualize real-time system metrics from an Ubuntu Server host while demonstrating foundational observability and infrastructure monitoring concepts.

The stack consisted of:
- Prometheus for metrics collection and time-series storage
- Node Exporter for exposing host-level system metrics
- Grafana for dashboard visualization and monitoring analytics
- Docker Compose for orchestration and container networking

The project introduced key monitoring and observability concepts including:
- metrics scraping
- exporters
- time-series monitoring
- infrastructure visualization
- service health monitoring
- containerized monitoring architecture
- operational visibility into system performance

---

## Objectives

The primary goals of this lab were to:
- deploy a containerized monitoring stack using Docker Compose
- collect host-level system metrics using Node Exporter
- configure Prometheus for metrics scraping
- visualize infrastructure metrics using Grafana dashboards
- understand exporter-based monitoring architectures
- demonstrate internal container networking between monitoring services
- gain familiarity with infrastructure observability concepts
- monitor real-time server resource utilization

---

## Technologies Used

- Docker Engine
- Docker Compose
- Prometheus
- Node Exporter
- Grafana
- Ubuntu Server 26.04 LTS

---

## Core Technologies

### Prometheus

Prometheus is an open-source monitoring and alerting platform designed for collecting and storing time-series metrics data.

Prometheus operates using a pull-based monitoring model where it periodically scrapes HTTP endpoints exposed by monitoring exporters.

In this project, Prometheus:
- collected metrics from Node Exporter
- stored metrics as time-series data
- served as the primary monitoring database
- provided query capabilities for Grafana dashboards

Prometheus was configured to scrape metrics every 15 seconds.

---

### Node Exporter

Node Exporter is a Prometheus exporter designed to expose Linux host system metrics in a Prometheus-compatible format.

In this project, Node Exporter provided visibility into:
- CPU utilization
- memory usage
- filesystem statistics
- network activity
- system load
- disk usage

Node Exporter acted as the metrics source for the monitoring stack.

---

### Grafana

Grafana is a visualization and analytics platform used to create dashboards from monitoring and observability data.

In this project, Grafana:
- connected to Prometheus as a data source
- visualized collected infrastructure metrics
- provided operational dashboards for monitoring the Ubuntu Server host
- served as the frontend visualization layer of the monitoring stack

---

## Monitoring Stack Architecture

The monitoring stack followed a layered metrics collection and visualization architecture:

```text
Ubuntu Server Metrics
        ↓
Node Exporter
        ↓
Prometheus Scraping
        ↓
Time-Series Database
        ↓
Grafana Queries
        ↓
Dashboards & Visualization
```

In this deployment:
- Node Exporter exposed system metrics from the Ubuntu Server host
- Prometheus scraped and stored metrics data
- Grafana queried Prometheus and visualized infrastructure data through dashboards
- Docker Compose managed service orchestration and networking

---

## Project Deployment

### Project Directory Creation

A dedicated infrastructure directory structure was created to organize the monitoring stack deployment and supporting configuration files.

Commands used:

```bash
mkdir -p ~/infrastructure/monitoring-stack
cd ~/infrastructure/monitoring-stack
```

<p align="center">
  <img src="../images/monitoring-stack-lab/01-making-project-directories.jpeg" width="700">
</p>

<p align="center">
  <em>Creating the infrastructure project directory for the monitoring stack deployment.</em>
</p>

---

### Creating the Docker Compose Configuration

A Docker Compose stack was created containing:
- Prometheus
- Node Exporter
- Grafana

The services were connected using a shared Docker bridge network named `monitoring`.

Initial compose configuration:

```yaml
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
    networks:
      - monitoring

  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    ports:
      - "9100:9100"
    networks:
      - monitoring

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    networks:
      - monitoring

networks:
  monitoring:
    driver: bridge
```

<p align="center">
  <img src="../images/monitoring-stack-lab/02-creating-docker-compose-file.jpeg" width="700">
</p>

<p align="center">
  <em>Docker Compose configuration defining Prometheus, Node Exporter, and Grafana services on a shared monitoring bridge network.</em>
</p>

---

### Creating the Prometheus Configuration

A dedicated directory and configuration file were created for Prometheus.

Commands used:

```bash
mkdir -p prometheus
nano prometheus/prometheus.yml
```

<p align="center">
  <img src="../images/monitoring-stack-lab/03-prometheus-directory.jpeg" width="700">
</p>

<p align="center">
  <em>Creating the Prometheus configuration directory and configuration file.</em>
</p>

Initial configuration:

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: "node-exporter"
    static_configs:
      - targets: ["node-exporter:9100"]
```

<p align="center">
  <img src="../images/monitoring-stack-lab/04-prometheus-config.jpeg" width="700">
</p>

<p align="center">
  <em>Prometheus scrape configuration targeting the Node Exporter service over the internal Docker network.</em>
</p>

---

### Internal Container Networking

Prometheus communicated with Node Exporter using Docker's internal bridge networking and embedded DNS-based service discovery.

Instead of relying on static IP addresses, Prometheus targeted the Node Exporter service directly using the container service name:

```yaml
targets: ["node-exporter:9100"]
```

This allowed services to communicate reliably within the isolated monitoring network created by Docker Compose.

The monitoring stack demonstrated:
- internal Docker DNS resolution
- service-to-service communication
- bridge networking
- isolated infrastructure segmentation

---

### Deploying the Docker Compose Stack

The monitoring stack was deployed using Docker Compose.

Command used:

```bash
docker compose up -d
```

<p align="center">
  <img src="../images/monitoring-stack-lab/05-running-docker-compose-stack.jpeg" width="700">
</p>

<p align="center">
  <em>Deployment of the monitoring stack including Prometheus, Node Exporter, and Grafana containers.</em>
</p>

---

### Inspecting Running Containers

Running containers were inspected to validate successful deployment and active service status.

Command used:

```bash
docker ps
```

<p align="center">
  <img src="../images/monitoring-stack-lab/06-validating-running-containers.jpeg" width="800">
</p>

<p align="center">
  <em>Validation of active monitoring stack containers and published service ports.</em>
</p>

The deployment successfully exposed:
- Prometheus on port 9090
- Node Exporter on port 9100
- Grafana on port 3000

---

## Service Validation

### Prometheus Browser Test

Prometheus accessibility was validated from the Windows 11 management workstation using a web browser.

URL used:

```text
http://192.168.1.226:9090
```

The Prometheus interface loaded successfully, confirming:
- successful container deployment
- active port exposure
- operational web interface access
- functional Docker networking

<p align="center">
  <img src="../images/monitoring-stack-lab/07-prometheus-test.jpeg" width="800">
</p>

<p align="center">
  <em>Successful validation of the Prometheus web interface from the Windows 11 management workstation.</em>
</p>

---

### Grafana Browser Test

Grafana accessibility was validated from the Windows 11 management workstation using a web browser.

URL used:

```text
http://192.168.1.226:3000
```

The Grafana login interface loaded successfully.

<p align="center">
  <img src="../images/monitoring-stack-lab/08-grafana-test.jpeg" width="800">
</p>

<p align="center">
  <em>Successful validation of the Grafana web interface from the Windows 11 management workstation.</em>
</p>

---

### Grafana Dashboard Access

Grafana was initially accessed using the default administrator credentials:

```text
Username: admin
Password: admin
```

After initial authentication:
- the default password was rotated
- administrative dashboard access was established
- Grafana was confirmed operational

<p align="center">
  <img src="../images/monitoring-stack-lab/09-grafana-dash.jpeg" width="800">
</p>

<p align="center">
  <em>Grafana dashboard interface after successful authentication and initial configuration.</em>
</p>

---

# Outcome

At completion:
- Prometheus was successfully configured for metrics collection
- Node Exporter exposed live Ubuntu Server host metrics
- Grafana was operational and accessible from the Windows 11 management workstation
- Internal container networking functioned correctly through Docker Compose
- The monitoring stack provided real-time infrastructure visibility
- Containerized monitoring services were successfully orchestrated using Docker Compose

---

# Lessons Learned

Key takeaways included:
- Prometheus scrape-based monitoring architecture
- exporter-based metrics collection
- Docker Compose service orchestration
- internal Docker DNS resolution
- infrastructure observability concepts
- Grafana dashboard visualization workflows
- containerized monitoring deployment practices
- operational monitoring fundamentals
- service-to-service communication within Docker networks
- real-time infrastructure visibility and metrics analysis

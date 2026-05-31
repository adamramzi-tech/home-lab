# Linux Infrastructure

This directory contains infrastructure configuration files for the Linux infrastructure track.

---

## Active Deployments

These directories reflect services currently deployed and running on the Ubuntu Server host.

| Directory | Description |
|---|---|
| `monitoring-stack/` | Prometheus, Node Exporter, and Grafana with persistent storage |
| `reverse-proxy-lab/` | NGINX Proxy Manager and shared proxy Docker network |

---

## Retained Lab Configurations

These directories contain configuration files from infrastructure labs. They are kept for reference and reproducibility but do not represent active deployments.

| Directory | Lab | Description |
|---|---|---|
| `docker-networking/` | [05 - Docker Networking Lab](../../docs/linux-infrastructure/05-docker-networking-lab.md) | Experimental bridge networking stack with a simple nginx frontend and echo backend, used to explore Docker DNS and container-to-container communication |


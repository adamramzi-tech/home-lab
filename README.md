# Home Lab Infrastructure Project

## Overview

This repository documents the deployment, administration, and ongoing development of a Linux-based homelab environment built on repurposed consumer desktop hardware.

The lab is a hands-on systems administration portfolio built through real deployment, troubleshooting, and iteration — not guided tutorials. Each project documents the full workflow: planning, deployment, validation, and lessons learned.

Current focus areas:
- Linux systems administration
- Docker and containerized service management
- Reverse proxy and ingress architecture
- Infrastructure monitoring and observability
- Remote access and secure administration
- Git-based documentation workflows

---

# Infrastructure Overview

```text
Windows 11 Workstation
        ↓ SSH / Tailscale
Ubuntu Server 26.04 LTS (Headless)
        ↓
Docker Engine
        ↓
NGINX Proxy Manager (Centralized Ingress)
        ↓
┌──────────┬────────────┬───────────┐
Grafana  Prometheus  Portainer
(internal) (internal) (internal)
        ↓
Node Exporter → Prometheus (internal metrics pipeline)
```

All backend services are internal-only. External access is centralized through NGINX Proxy Manager. Services are routed by hostname through a shared Docker bridge network using Docker DNS service discovery.

---

# Server Hardware

| Component | Details |
|---|---|
| CPU | Intel Core i5-9600KF |
| Motherboard | MSI Z390 GAMING PRO CARBON |
| RAM | XPG 16GB (2x8GB) DDR4-3200 |
| GPU | NVIDIA GTX 1060 (required for POST — no iGPU) |
| Case | NZXT H500 ATX Mid Tower |
| Storage | Western Digital Blue 1TB HDD |
| Cooler | Thermalright Assassin X120 Refined SE |
| PSU | Corsair CX500 500W |

The server was built from repurposed desktop gaming hardware. The hardware is not optimized for power efficiency, but it provides a capable and cost-effective environment for Docker workloads, networking labs, and systems administration practice.

---

# Technology Stack

## Operating Systems
- Ubuntu Server 26.04 LTS
- Windows 11

## Systems Administration and Remote Access
- OpenSSH
- Tailscale (WireGuard-based mesh VPN)
- Wake-on-LAN
- systemd
- Git / GitHub
- Linux CLI utilities (htop, btop, sensors, journalctl, ethtool, fastfetch)

## Containerization
- Docker Engine
- Docker Compose
- Portainer Community Edition

## Networking and Ingress
- NGINX Proxy Manager
- Docker bridge networking
- Docker DNS service discovery
- Cross-stack Docker network federation
- Hostname-based service routing
- Internal-only backend service architecture

## Monitoring and Observability
- Prometheus
- Node Exporter
- Grafana
- docker logs
- journalctl

---

# Key Concepts Demonstrated

- Linux server deployment and administration
- Headless server management
- Remote systems administration over SSH and VPN
- Docker deployment and orchestration
- Containerized service management
- Reverse proxy and centralized ingress architecture
- Docker bridge networking and DNS-based service discovery
- Cross-stack container network federation
- Infrastructure monitoring and observability pipelines
- Persistent storage management for stateful services
- YAML configuration management
- Service isolation and reduced attack surface
- Git-based documentation and change tracking workflows

---

# Project Documentation

| Document | Description |
|---|---|
| [Hardware Build](docs/hardware-build.md) | Physical server preparation, hardware assembly, and BIOS configuration |
| [Ubuntu Server Installation](docs/ubuntu-server-install.md) | Ubuntu Server deployment and baseline system configuration |
| [Remote Access and SSH](docs/remote-access-and-ssh.md) | SSH, Tailscale VPN, and Wake-on-LAN configuration |
| [Docker Setup](docs/docker-setup.md) | Docker Engine and Portainer deployment |
| [Docker Networking Lab](docs/docker-networking-lab.md) | Docker bridge networking, container communication, and reverse proxy fundamentals |
| [Monitoring Stack Lab](docs/monitoring-stack-lab.md) | Prometheus, Node Exporter, and Grafana deployment with persistent storage |
| [Reverse Proxy Lab](docs/reverse-proxy-lab.md) | Centralized ingress architecture using NGINX Proxy Manager and cross-stack Docker networking |

---

# Repository Structure

```text
home-lab/
├── docs/            → deployment walkthroughs, lab documentation, and operational notes
├── images/          → screenshots and visual references organized by lab
├── infrastructure/  → Docker Compose files and service configurations
└── README.md        → project overview and repository navigation
```

---

# Documentation Workflow

This repository follows a documentation-first operational workflow.

Each deployment follows this sequence:
1. plan and research the deployment
2. deploy or modify services and configurations
3. validate functionality and troubleshoot issues
4. capture screenshots and relevant command output
5. document procedures, architecture decisions, and lessons learned
6. commit updates incrementally through Git and GitHub

Administration is performed remotely from the Windows 11 workstation using SSH through Windows Terminal, VS Code remote workflows, and browser-based management interfaces. No physical console access is required during normal operations.

---

# Current Progress

## Completed

- Physical server assembly and hardware validation
- BIOS firmware update and configuration
- Ubuntu Server 26.04 LTS deployment
- SSH remote administration setup
- Tailscale mesh VPN deployment
- Wake-on-LAN configuration
- Docker Engine installation and validation
- Portainer Community Edition deployment
- Docker networking lab (bridge networking, DNS resolution, reverse proxy fundamentals)
- Monitoring stack deployment (Prometheus, Node Exporter, Grafana)
- Prometheus metrics collection and scrape target validation
- Grafana dashboard deployment with live infrastructure metrics
- Persistent storage configuration for stateful monitoring services
- Centralized reverse proxy deployment (NGINX Proxy Manager)
- Hostname-based service routing (grafana.local, prometheus.local, portainer.local)
- Cross-stack Docker network federation
- Internal-only backend service architecture
- Service isolation and reduced direct LAN exposure

---

## In Progress

- Network and architecture diagrams
- Additional monitoring dashboards
- Expanded Docker service deployments

---

## Planned

### Systems Administration and Virtualization
- Proxmox virtualization platform
- Windows Server deployment
- Active Directory domain configuration
- Group Policy management

### Security and Logging
- Wazuh SIEM deployment
- Centralized log management
- Backup automation
- Authentication and access control improvements

### Advanced Networking
- HTTPS/TLS with SSL certificate management
- DNS and DHCP services
- Additional reverse proxy improvements

---

# Long-Term Goals

This homelab will continue evolving as a broader systems administration and infrastructure engineering environment covering virtualization, security, automation, and operational best practices.

The long-term objective is to build practical real-world experience through iterative hands-on work across systems administration, networking, containerization, monitoring, and security domains.
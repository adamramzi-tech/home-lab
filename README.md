# Home Lab Infrastructure Project

## Overview

This repository documents the deployment, administration, and ongoing development of a Linux-based homelab environment built using repurposed consumer desktop hardware.

The project is focused on developing practical hands-on experience with:
- Linux systems administration
- Docker and containerized services
- Networking and remote access
- Monitoring and observability
- Systems troubleshooting
- Documentation workflows
- Modern operational concepts

The homelab functions as both a long-term technical learning platform and a systems administration portfolio project.

---

# Purpose

This homelab was built to develop practical systems administration and platform engineering experience through hands-on deployment, troubleshooting, documentation, and iterative learning using self-hosted Linux and Docker-based environments.

---

# Infrastructure Overview

```text
Windows 11 Workstation
        ↓ SSH / Tailscale
Ubuntu Server Host
        ↓
Docker Engine
        ↓
Containerized Services
├── Portainer
├── NGINX Reverse Proxy
├── Backend Services
├── Prometheus
├── Node Exporter
└── Grafana
```

---

# Environment Summary

The current lab environment includes:
- Ubuntu Server host deployment
- Remote administration through SSH and Tailscale
- Docker and Docker Compose-based service management
- Container networking and reverse proxy architecture
- Monitoring and observability tooling
- Linux system diagnostics and troubleshooting
- Git/GitHub documentation workflows
- Headless Linux server administration

---

# Technology Stack

## Operating Systems

- Ubuntu Server 26.04 LTS
- Windows 11

---

## Systems Administration and Remote Access

- OpenSSH
- Tailscale
- systemd
- Git
- GitHub
- Linux CLI utilities

---

## Containerization

- Docker Engine
- Docker Compose
- Portainer

---

## Monitoring and Observability

- Prometheus
- Node Exporter
- Grafana
- htop
- btop
- sensors
- docker logs
- journalctl

---

## Networking

- Docker bridge networking
- Reverse proxy architecture
- WireGuard-based VPN networking
- Internal DNS-based service discovery
- Container isolation and segmentation

---

# Key Concepts Demonstrated

- Linux systems administration
- Headless server management
- Remote systems administration
- Docker deployment and orchestration
- Container networking
- Reverse proxy architecture
- Monitoring and observability
- Persistent storage management
- YAML configuration management
- Docker Compose workflows
- VPN-based remote access
- Systems troubleshooting and diagnostics
- Git-based documentation workflows

---

# Server Hardware

- Intel Core i5-9600KF
- MSI Z390 GAMING PRO CARBON
- XPG 16GB (2x8GB) DDR4-3200
- NVIDIA GTX 1060
- NZXT H500 ATX Mid Tower Case
- Western Digital Blue 1TB HDD
- Thermalright Assassin X120 Refined SE
- Corsair CX500 500W PSU

This server environment was built primarily using repurposed consumer desktop hardware that was already available. While the platform is not optimized for enterprise efficiency or power consumption, it provides an effective and practical environment for developing hands-on experience with systems administration, networking, containerization, and operational troubleshooting.

---

# Project Documentation

| Document | Description |
|---|---|
| [Hardware Build](docs/hardware-build.md) | Physical server preparation and hardware configuration |
| [Ubuntu Server Installation](docs/ubuntu-server-install.md) | Ubuntu Server deployment and baseline system configuration |
| [Remote Access and SSH](docs/remote-access-and-ssh.md) | SSH, Tailscale, and Wake-on-LAN configuration |
| [Docker Setup](docs/docker-setup.md) | Docker Engine and Portainer deployment |
| [Docker Networking Lab](docs/docker-networking-lab.md) | Docker networking and reverse proxy architecture |
| [Monitoring Stack Lab](docs/monitoring-stack-lab.md) | Prometheus, Node Exporter, and Grafana deployment |

---

# Repository Structure

```text
docs/        → project documentation and deployment walkthroughs
images/      → deployment screenshots and visual documentation
docker/      → Docker Compose files and service configurations
diagrams/    → network and systems diagrams
notes/       → operational notes and planning
```

---

# Documentation Workflow

This repository is maintained using a documentation-first workflow during deployment, testing, and systems administration tasks.

Operational changes are typically performed in the following order:
1. deploy or modify services and configurations
2. validate functionality and troubleshoot issues
3. capture screenshots and relevant command output
4. document deployment procedures and architecture decisions
5. commit updates incrementally through Git and GitHub

Most administration and documentation tasks are performed remotely from the Windows 11 workstation using:
- SSH through Windows Terminal
- VS Code remote workflows
- Git and GitHub for version control

The goal of this workflow is to reinforce:
- operational documentation habits
- troubleshooting discipline
- change tracking
- reproducible deployment workflows
- technical communication skills
- remote systems administration practices

---

# Operational Challenges and Lessons Learned

Some of the most valuable learning experiences throughout this project have involved:
- troubleshooting Docker networking behavior
- diagnosing Linux permissions and ownership issues
- troubleshooting YAML configuration and parsing errors
- understanding container communication concepts
- validating VPN-isolated networking behavior
- configuring secure remote administration workflows
- building troubleshooting discipline in headless Linux environments
- learning systems administration concepts through iterative deployment and testing

The project emphasizes practical operational understanding through hands-on implementation, troubleshooting, validation, and documentation.

---

# Current Progress

## Completed

- Physical server assembly
- CPU cooler installation
- BIOS update and configuration
- Ubuntu Server deployment
- SSH remote administration setup
- Docker installation and validation
- Portainer deployment
- Docker networking lab
- Reverse proxy deployment
- Monitoring stack deployment
- Prometheus metrics collection
- Grafana dashboard deployment
- Tailscale remote connectivity setup

---

## In Progress

- Infrastructure documentation
- Network and architecture diagrams
- Additional monitoring dashboards
- Expanded Docker service deployments

---

## Planned

### Advanced Infrastructure Labs

- NGINX Proxy Manager
- HTTPS/TLS configuration
- DNS and DHCP services
- Reverse proxy improvements

### Systems Administration and Virtualization

- Active Directory
- Windows Server
- Group Policy
- Proxmox virtualization

### Security and Logging

- Wazuh SIEM deployment
- Centralized logging
- Backup automation
- Authentication and access control improvements

---

# Long-Term Goals

This homelab will continue evolving into a broader systems administration and platform engineering environment focused on:
- systems administration
- networking
- virtualization
- monitoring and observability
- security
- automation
- troubleshooting workflows
- operational best practices

The long-term objective is to continue developing practical real-world experience through iterative hands-on learning and operational problem solving.

---

# Purpose of This Repository

This repository is intended to function as:
- a technical learning journal
- a systems administration portfolio
- a documentation repository
- a long-term homelab project

The primary goal is to demonstrate practical technical growth through hands-on implementation, troubleshooting, documentation, and continuous improvement.
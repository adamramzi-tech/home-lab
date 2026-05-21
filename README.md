# Home Lab Infrastructure Project

## Overview

This repository documents the deployment, administration, and ongoing development of a Linux-based homelab environment built using repurposed consumer desktop hardware.

The project is focused on developing practical hands-on experience with:

- Linux systems administration
- Docker and containerized services
- Networking and remote access
- Infrastructure troubleshooting
- Monitoring and diagnostics
- Documentation and operational workflows
- Enterprise-oriented infrastructure concepts

The homelab functions as both a long-term technical learning platform and a systems administration portfolio project.

---

# Infrastructure Summary

Current environment includes:

- Ubuntu Server host deployment
- Remote administration through SSH and Tailscale
- Docker and Docker Compose-based service management
- Container networking and VPN-isolated networking
- Linux system monitoring and diagnostics
- Git/GitHub documentation workflow
- Ongoing infrastructure documentation and troubleshooting

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

This server environment was built primarily using repurposed consumer desktop hardware that was already available. While the platform is not optimized for enterprise efficiency or power consumption, it provides an effective and practical environment for developing hands-on experience with systems administration, networking, containerization, and infrastructure troubleshooting.

---

# Operating Systems

## Server Environment

- Ubuntu Server

## Client Environment

- Windows 11

---

# Current Technologies

## Infrastructure and Administration

- SSH
- Tailscale
- systemd
- Git
- GitHub
- Linux CLI utilities

## Containerization

- Docker
- Docker Compose
- Docker networking concepts

## Monitoring and Diagnostics

- btop
- htop
- sensors
- docker logs
- journalctl
- Networking diagnostics and troubleshooting tools

## Networking

- WireGuard
- VPN container networking
- Docker bridge networking

---

# Planned Technologies

## Monitoring and Observability

- Grafana
- Prometheus
- Uptime Kuma

## Infrastructure and Networking

- Nginx Proxy Manager
- HTTPS/TLS configuration
- DNS and DHCP services
- Reverse proxy deployment

## Enterprise-Oriented Labs

- Active Directory
- Windows Server
- Group Policy
- Proxmox virtualization

## Security and Logging

- Wazuh
- Centralized logging
- Backup automation
- Authentication and access control

---

# Skills and Concepts Practiced

This project emphasizes practical experience with:

- Linux administration
- Command-line operations
- Docker deployment and management
- Container networking
- YAML configuration
- Persistent storage management
- Remote server administration
- VPN-isolated networking
- System monitoring and diagnostics
- Infrastructure troubleshooting
- Documentation workflows
- Git and version control fundamentals

---

# Operational Challenges and Lessons Learned

Some of the most valuable learning experiences so far have involved:

- Troubleshooting Docker networking issues
- Diagnosing Linux permissions and ownership problems
- Troubleshooting YAML configuration and parsing errors
- Understanding container communication concepts
- Validating VPN-isolated networking behavior
- Configuring remote administration securely through SSH
- Developing troubleshooting and diagnostic workflows
- Building confidence working in headless Linux environments

The project emphasizes iterative learning, troubleshooting discipline, and operational understanding through hands-on implementation rather than prebuilt lab environments.

---

# Repository Structure

## Documentation

- [Hardware Build](docs/hardware-build.md)
- [Ubuntu Server Installation](docs/ubuntu-server-install.md)
- [Remote Access and SSH](docs/remote-access-and-ssh.md)
- [Docker Setup](docs/docker-setup.md)
- [Docker Networking Lab](docs/docker-networking-lab.md)
- [Monitoring and System Tools](docs/monitoring-and-system-tools.md)
- [VPN Container Networking](docs/vpn-container-networking.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Lessons Learned](docs/lessons-learned.md)
- [Future Roadmap](docs/future-roadmap.md)

## Additional Directories

- `diagrams/` → infrastructure and network diagrams
- `images/` → visual documentation and deployment screenshots
- `docker/` → Docker Compose files and container configurations
- `notes/` → operational notes and planning

---

# Project Roadmap

## Completed

- Physical server assembly
- CPU cooler installation
- BIOS update and configuration
- Ubuntu Server deployment
- SSH remote administration setup
- Docker installation
- Initial containerized infrastructure deployment
- Tailscale remote connectivity setup

## In Progress

- Infrastructure documentation
- Network and architecture diagrams
- Monitoring stack deployment
- Docker networking documentation

## Planned

### Monitoring and Observability

- Grafana dashboards
- Prometheus metrics collection
- Uptime Kuma monitoring

### Infrastructure and Networking

- Reverse proxy deployment
- HTTPS/TLS configuration
- DNS and networking improvements

### Enterprise-Oriented Labs

- Active Directory environment
- Windows Server deployment
- Group Policy testing
- DHCP and DNS service configuration
- Proxmox virtualization

### Security and Logging

- Wazuh SIEM deployment
- Centralized logging
- Backup automation
- Authentication and access control improvements

---

# Purpose of This Repository

This repository is intended to function as:

- A technical learning journal
- A systems administration portfolio
- A documentation repository
- A long-term infrastructure project

The primary goal is to demonstrate practical technical growth through hands-on implementation, troubleshooting, documentation, and continuous improvement.

---

# Long-Term Goals

This homelab will continue evolving into a broader infrastructure and enterprise simulation environment focused on:

- Systems administration
- Networking
- Virtualization
- Monitoring and observability
- Security
- Automation
- Troubleshooting workflows
- Operational best practices

The long-term objective is to continue developing practical real-world infrastructure and operational experience through iterative hands-on learning.

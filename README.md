# Home Lab Infrastructure Project

## Overview

This repository documents the deployment, administration, and ongoing development of a hybrid homelab environment spanning Linux infrastructure, containerized services, and planned Windows enterprise infrastructure.

Each project documents the full workflow:
- planning
- research
- deployment
- validation
- troubleshooting
- lessons learned

The environment is currently organized into two primary tracks:

- **Linux Infrastructure** — Ubuntu Server, Docker, reverse proxy, monitoring, and remote administration
- **Enterprise Infrastructure (Planned)** — Virtualization, Windows Server, Active Directory, Group Policy, and cross-platform integration

The Linux infrastructure track is currently operational and documented. The enterprise infrastructure track is currently in the planning and research phase and will be implemented incrementally through dedicated labs.

---

# Current Project Status

## Operational Environment

The following infrastructure is currently deployed and operational:

- Ubuntu Server 26.04 LTS
- Docker Engine + Docker Compose
- Portainer Community Edition
- NGINX Proxy Manager
- Prometheus
- Grafana
- Node Exporter
- SSH remote administration
- Tailscale mesh VPN
- Reverse proxy architecture
- Internal-only backend services
- Cross-stack Docker networking

## Current Focus

The current focus of the project is expanding the existing Linux infrastructure into a broader hybrid enterprise environment.

Research and planning are currently underway for:
- virtualization architecture
- Windows Server deployment
- Active Directory integration
- centralized identity services
- Group Policy management
- cross-platform authentication
- centralized DNS
- security monitoring expansion
- SIEM integration

The next phase of the project will introduce enterprise infrastructure concepts incrementally through dedicated labs.

---

# Planned Hybrid Infrastructure Architecture

```text
ISP Fiber Connection
        ↓
Primary WiFi 6E Router
        ↓
WiFi 6E Mesh Extender
(Desk Infrastructure Node)

├── Cat6 → Windows 11 Workstation
│
│   ├── VMware Workstation
│   │   ├── DC01
│   │   │   └── Windows Server 2022
│   │   │       ├── Active Directory Domain Services
│   │   │       └── AD-Integrated DNS
│   │   │
│   │   └── WIN11-CLIENT01
│   │       └── Domain-Joined Windows 11 Client
│   │
│   ├── Management Plane
│   │   ├── RDP
│   │   ├── SSH
│   │   ├── Browser-Based Administration
│   │   └── VS Code Remote Workflows
│   │
│   └── General Workstation Usage
│
└── Cat6 → Ubuntu Server 26.04 LTS
    (Headless Linux Infrastructure Host)

    ├── Docker Engine
    │   ├── NGINX Proxy Manager
    │   ├── Grafana
    │   ├── Prometheus
    │   ├── Portainer
    │   └── Future Linux Infrastructure Services
    │
    ├── Node Exporter
    │   └── Metrics Pipeline → Prometheus
    │
    ├── OpenSSH + Tailscale
    │   └── Remote Administration Layer
    │
    └── Planned Cross-Platform Integration
        ├── Linux + AD Authentication
        ├── Windows Metrics Exporting
        ├── Centralized Logging
        └── SIEM Integration
```

This diagram represents the planned target architecture currently being researched and designed.

The existing Ubuntu Server infrastructure remains the operational foundation of the environment. Future enterprise infrastructure components will be layered on incrementally while preserving stability of the existing Linux platform.

---

# Hardware

## Ubuntu Server

| Component | Details |
|---|---|
| CPU | Intel Core i5-9600KF |
| Motherboard | MSI Z390 Pro Carbon |
| RAM | 16GB DDR4-3200 |
| Storage | Western Digital Blue 1TB HDD |
| GPU | NVIDIA GTX 1060 (required for POST — no iGPU) |
| Case | NZXT H500 ATX Mid Tower |
| PSU | Corsair CX500 500W |

## Windows 11 Workstation

Primary management workstation and planned virtualization host for enterprise infrastructure labs.

| Component | Details |
|---|---|
| CPU | AMD Ryzen 5 7600X3D |
| Motherboard | ASUS TUF B650-PLUS WIFI |
| RAM | 32GB DDR5-6000 |
| Storage | Samsung 990 EVO Plus 1TB NVMe + Klevv CRAS C910 1TB NVMe |
| GPU | NVIDIA RTX 5070 |
| Case | NZXT H5 Flow (2024) |
| PSU | Corsair RM750e 750W |

---

# Technology Stack

## Linux Infrastructure

- Ubuntu Server 26.04 LTS
- Docker Engine + Docker Compose
- Portainer Community Edition
- NGINX Proxy Manager
- Prometheus + Node Exporter + Grafana
- OpenSSH + Tailscale (WireGuard mesh VPN)
- Wake-on-LAN
- Git / GitHub

## Planned Enterprise Infrastructure

- VMware Workstation (hypervisor)
- Windows Server 2022
- Active Directory Domain Services
- AD-Integrated DNS
- Group Policy Management
- Windows 11 Enterprise Client

## Planned Cross-Platform Integrations

- Windows metrics pipeline (windows-exporter → Prometheus → Grafana)
- Linux + Active Directory integration (Kerberos, SSSD)
- Centralized logging and SIEM integration (Wazuh)
- Centralized internal DNS and service discovery

---

# Key Concepts Demonstrated

## Linux and Containers

- Linux server deployment and headless administration
- Remote systems administration over SSH and VPN
- Docker orchestration and containerized service management
- Reverse proxy and centralized ingress architecture
- Docker bridge networking and DNS-based service discovery
- Cross-stack container network federation
- Infrastructure monitoring and observability pipelines
- Persistent storage management for stateful services
- Service isolation and reduced attack surface

## Planned Enterprise Infrastructure Concepts

- Hypervisor deployment and VM lifecycle management
- Windows Server deployment and administration
- Active Directory domain controller promotion
- Centralized identity, authentication, and authorization
- Organizational Unit structure and delegation
- Group Policy design and enforcement
- Domain client integration and management
- File services and NTFS permission management

## Planned Cross-Platform Infrastructure Concepts

- Distributed infrastructure across physical machines
- Cross-platform monitoring and observability
- Linux and Windows identity integration
- Centralized authentication and DNS concepts
- Centralized security logging and SIEM architecture

---

# Project Documentation

## Linux Infrastructure Track

| Document | Description |
|---|---|
| [Hardware Build](docs/linux-infrastructure/hardware-build.md) | Physical server preparation, hardware assembly, and BIOS configuration |
| [Ubuntu Server Installation](docs/linux-infrastructure/ubuntu-server-install.md) | Ubuntu Server deployment and baseline system configuration |
| [Remote Access and SSH](docs/linux-infrastructure/remote-access-and-ssh.md) | SSH, Tailscale VPN, and Wake-on-LAN configuration |
| [Docker Setup](docs/linux-infrastructure/docker-setup.md) | Docker Engine and Portainer deployment |
| [Docker Networking Lab](docs/linux-infrastructure/docker-networking-lab.md) | Docker bridge networking, container communication, and reverse proxy fundamentals |
| [Monitoring Stack Lab](docs/linux-infrastructure/monitoring-stack-lab.md) | Prometheus, Node Exporter, and Grafana deployment with persistent storage |
| [Reverse Proxy Lab](docs/linux-infrastructure/reverse-proxy-lab.md) | Centralized ingress architecture using NGINX Proxy Manager and cross-stack Docker networking |

## Planned Enterprise Infrastructure Labs

| Planned Lab | Focus Area |
|---|---|
| Virtualization Lab | Hypervisor deployment, VM lifecycle management, snapshots, and virtual networking |
| Windows Server Lab | Windows Server deployment, baseline configuration, and remote administration |
| Active Directory Lab | AD DS promotion, domain configuration, DNS integration, and identity structure |
| Domain Client Lab | Domain-joined workstation deployment, authentication testing, and client management |
| Group Policy Lab | GPO design, policy inheritance, security baselines, and endpoint management |
| Linux and AD Integration Lab | Cross-platform identity integration, Kerberos, SSSD, and domain-authenticated Linux |
| Security and Monitoring Lab | Wazuh SIEM, Sysmon, Windows event forwarding, and centralized telemetry |

## Planned Architecture Documentation

Future architecture documentation will include:
- topology diagrams
- authentication flows
- network segmentation diagrams
- service relationships
- monitoring pipelines
- identity integration workflows

---

# Repository Structure

```text
home-lab/
├── docs/
│   ├── linux-infrastructure/
│   │   └── Linux, Docker, networking, and monitoring labs
│   │
│   └── enterprise-infrastructure/
│       └── Planned virtualization, Windows Server, AD, and security labs
│
├── images/
│   ├── linux-infrastructure/
│   └── enterprise-infrastructure/
│
├── infrastructure/
│   ├── linux-infrastructure/
│   │   └── Docker Compose files and Linux service configs
│   │
│   └── enterprise-infrastructure/
│       └── Planned VM configs and Windows infrastructure references
│
└── README.md
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

Infrastructure changes are documented with emphasis on:
- architecture evolution
- operational reasoning
- networking and service relationships
- validation and troubleshooting workflows
- security and segmentation considerations

---

# Current Progress

## Linux Infrastructure Track — Completed

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

## Enterprise Infrastructure Track — Planning and Research Phase

- [ ] Virtualization architecture planning
- [ ] Hypervisor selection and networking design
- [ ] Windows Server deployment planning
- [ ] Active Directory architecture research
- [ ] Domain structure and naming conventions
- [ ] Group Policy planning
- [ ] Linux and Active Directory integration research
- [ ] Security monitoring architecture planning

---

# Long-Term Goals

This homelab will continue evolving as a hybrid infrastructure environment covering:

- Linux systems administration
- Windows enterprise infrastructure
- Virtualization
- Containerization
- Monitoring and observability
- Centralized identity management
- Cross-platform authentication
- Security monitoring and SIEM workflows
- Infrastructure architecture and operational design

The long-term objective is to build practical real-world experience that reflects the operational complexity of modern IT environments where:
- Linux and Windows systems coexist
- identity is centralized
- infrastructure is observable
- services are segmented
- networking is layered
- security is integrated throughout the environment
- operational changes are documented and validated incrementally
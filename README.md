# Home Lab Infrastructure Project

## Overview

This repository documents the design, deployment, administration, and ongoing development of a hybrid homelab environment spanning Linux infrastructure, containerized services, and planned Windows enterprise infrastructure.

The project is organized into two tracks:

- **Linux Infrastructure** - Ubuntu Server, Docker, reverse proxy, monitoring, and remote administration
- **Enterprise Infrastructure (Planned)** - Virtualization, Windows Server, Active Directory, Group Policy, and cross-platform integration

The Linux infrastructure track is operational and documented. The enterprise infrastructure track is currently in the planning and research phase and will be introduced incrementally through dedicated labs.

---

## Project Focus

The current environment is centered on practical systems administration and infrastructure operations.

The project emphasizes:
- Linux server administration
- Docker and containerized services
- networking and remote access
- observability and monitoring
- reverse proxy architecture
- documentation discipline
- incremental infrastructure growth

---

## Current Environment

The current lab environment includes:

- Ubuntu Server 26.04 LTS
- Docker Engine and Docker Compose
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

The Windows 11 workstation serves as the primary management endpoint and the future virtualization host for enterprise labs.

---

## Infrastructure Tracks

### Linux Infrastructure Track

The Linux infrastructure track focuses on:
- Ubuntu Server administration
- Docker-based infrastructure
- monitoring and observability
- container networking
- reverse proxy architecture
- remote administration
- infrastructure foundations

### Enterprise Infrastructure Track

The enterprise infrastructure track focuses on:
- virtualization
- Windows Server administration
- Active Directory
- Group Policy
- centralized authentication
- cross-platform identity integration
- security monitoring

---

## Architecture and Standards

This repository includes dedicated architecture documentation covering:

- infrastructure topology
- naming and operational standards
- architecture decision records
- recovery and rollback planning
- enterprise resource planning

Related documentation:

- `docs/architecture/topology.md`
- `docs/architecture/naming-and-scope-standards.md`
- `docs/architecture/recovery-and-rollback.md`
- `docs/architecture/enterprise-resource-plan.md`
- `docs/architecture/decisions/`

These documents live separately from the lab walkthroughs so implementation detail, operational standards, and long-term design reasoning remain organized and scalable.

---

## Project Documentation

### Linux Infrastructure

| Phase | Description |
|---|---|
| [01 - Hardware Build](docs/linux-infrastructure/01-hardware-build.md) | Physical server preparation, hardware assembly, and BIOS configuration |
| [02 - Ubuntu Server Installation](docs/linux-infrastructure/02-ubuntu-server-install.md) | Ubuntu Server deployment and baseline system configuration |
| [03 - Remote Access and SSH](docs/linux-infrastructure/03-remote-access-and-ssh.md) | SSH, Tailscale VPN, and Wake-on-LAN configuration |
| [04 - Docker Setup](docs/linux-infrastructure/04-docker-setup.md) | Docker Engine and Portainer deployment |
| [05 - Docker Networking Lab](docs/linux-infrastructure/05-docker-networking-lab.md) | Docker bridge networking, container communication, and reverse proxy fundamentals |
| [06 - Monitoring Stack Lab](docs/linux-infrastructure/06-monitoring-stack-lab.md) | Prometheus, Node Exporter, and Grafana deployment with persistent storage |
| [07 - Reverse Proxy Lab](docs/linux-infrastructure/07-reverse-proxy-lab.md) | Centralized ingress architecture using NGINX Proxy Manager and cross-stack Docker networking |

### Enterprise Infrastructure

| Planned Lab | Focus Area |
|---|---|
| [01 - Virtualization Lab](docs/enterprise-infrastructure/01-virtualization-lab.md) | Hypervisor deployment, VM lifecycle management, snapshots, and virtual networking |
| [02 - Windows Server Lab](docs/enterprise-infrastructure/02-windows-server-lab.md) | Windows Server deployment, baseline configuration, and remote administration |
| [03 - Active Directory Lab](docs/enterprise-infrastructure/03-active-directory-lab.md) | AD DS promotion, domain configuration, DNS integration, and identity structure |
| [04 - Domain Client Lab](docs/enterprise-infrastructure/04-domain-client-lab.md) | Domain-joined workstation deployment, authentication testing, and client management |
| [05 - Group Policy Lab](docs/enterprise-infrastructure/05-group-policy-lab.md) | GPO design, policy inheritance, security baselines, and endpoint management |
| [06 - Linux and AD Integration Lab](docs/enterprise-infrastructure/06-linux-ad-integration-lab.md) | Cross-platform identity integration, Kerberos, SSSD, and domain-authenticated Linux |
| [07 - Security and Monitoring Lab](docs/enterprise-infrastructure/07-security-monitoring-lab.md) | Wazuh SIEM, Sysmon, Windows event forwarding, and centralized telemetry |

---

## Repository Structure

```text
home-lab/
├── docs/
│   ├── linux-infrastructure/
│   ├── enterprise-infrastructure/
│   ├── architecture/
│   └── templates/
│
├── images/
│   ├── linux-infrastructure/
│   └── enterprise-infrastructure/
│
├── infrastructure/
│   ├── linux-infrastructure/
│   └── enterprise-infrastructure/
│
└── README.md
```

---

## Documentation Workflow

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

## Current Status

### Linux Infrastructure Track

Completed:

- Physical server assembly and hardware validation
- BIOS firmware update and configuration
- Ubuntu Server deployment
- SSH remote administration setup
- Tailscale mesh VPN deployment
- Wake-on-LAN configuration
- Docker Engine installation and validation
- Portainer Community Edition deployment
- Docker networking lab
- Monitoring stack deployment
- Prometheus metrics collection and validation
- Grafana dashboard deployment
- Persistent storage configuration for stateful services
- Centralized reverse proxy deployment
- Hostname-based service routing
- Cross-stack Docker network federation
- Internal-only backend service architecture
- Service isolation and reduced direct LAN exposure

### Enterprise Infrastructure Track

Planning and research phase:

- virtualization architecture planning
- hypervisor selection and networking design
- Windows Server deployment planning
- Active Directory architecture research
- domain structure and naming conventions
- Group Policy planning
- Linux and Active Directory integration research
- security monitoring architecture planning

---

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

---

## Long-Term Direction

The long-term objective is to build practical real-world experience that reflects the operational complexity of modern IT environments where:

- Linux and Windows systems coexist
- identity is centralized
- infrastructure is observable
- services are segmented
- networking is layered
- security is integrated throughout the environment
- operational changes are documented and validated incrementally

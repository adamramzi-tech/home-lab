# Home Lab Infrastructure Project

## Overview

This repository documents the design, deployment, administration, and ongoing development of a hybrid homelab environment spanning Linux infrastructure, containerized services, and Windows enterprise infrastructure.

The project is organized into two tracks:

- **Linux Infrastructure** - Ubuntu Server, Docker, reverse proxy, monitoring, and remote administration
- **Enterprise Infrastructure** - Virtualization, Windows Server, Active Directory, Group Policy, and cross-platform integration

Both tracks are operational and actively documented. The enterprise infrastructure track has progressed through virtualization, Windows Server configuration, Active Directory deployment, and domain client configuration, and is now advancing into Group Policy.

---

## Project Focus

The current environment is centered on practical systems administration and infrastructure operations.

The project emphasizes:
- Linux server administration
- Docker and containerized services
- networking and remote access
- observability and monitoring
- reverse proxy architecture
- Windows Server and Active Directory administration
- hybrid infrastructure operations
- documentation discipline
- incremental infrastructure growth

---

## Current Environment

### Linux Infrastructure

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

### Enterprise Infrastructure

- VMware Workstation Pro (hosted on Windows 11 workstation)
- DC01: Windows Server 2022 Standard Evaluation, static IP `192.168.1.10`, Active Directory Domain Services deployed, AD-integrated DNS operational, RDP enabled
- WIN11-CLIENT01: Windows 11 Enterprise Evaluation, static IP `192.168.1.20`, RSAT installed, domain-joined enterprise workstation, computer account in `OU=Workstations`
- Both VMs on bridged networking with direct LAN presence
- Active Directory Domain Services deployed: domain `corp.home.arpa` operational, DC01 promoted to domain controller, AD-integrated DNS active, OU structure created, domain user and group accounts created, post-promotion snapshots taken
- WIN11-CLIENT01 joined to `corp.home.arpa`: computer account confirmed in `OU=Workstations`, domain authentication validated, Kerberos TGT confirmed, secure channel verified, Group Policy processing validated

The Windows 11 workstation serves as the primary management endpoint and virtualization host for enterprise labs.

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

#### Completed Labs

| Lab | Focus Area |
|---|---|
| [01 - Virtualization Lab](docs/enterprise-infrastructure/01-virtualization-lab.md) | VMware Workstation deployment, enterprise VM provisioning, snapshot management, and virtual networking |
| [02 - Windows Server Lab](docs/enterprise-infrastructure/02-windows-server-lab.md) | Windows Server baseline configuration, bridged networking, static IP assignment, RDP, RSAT, and pre-AD snapshots |
| [03 - Active Directory Lab](docs/enterprise-infrastructure/03-active-directory-lab.md) | Active Directory Domain Services deployment, AD-integrated DNS, OU structure, domain accounts, and enterprise identity architecture |
| [04 - Domain Client Lab](docs/enterprise-infrastructure/04-domain-client-lab.md) | Domain join, computer account placement, domain authentication, Kerberos validation, secure channel verification, Group Policy processing, and AD service discovery from the joined client |

#### Planned Labs

| Planned Lab | Focus Area |
|---|---|
| [05 - Group Policy Lab](docs/enterprise-infrastructure/05-group-policy-lab.md) | Group Policy design, policy inheritance, security baselines, and endpoint management |
| [06 - Linux and AD Integration Lab](docs/enterprise-infrastructure/06-linux-ad-integration-lab.md) | Cross-platform identity integration using Kerberos, SSSD, and centralized authentication |
| [07 - Security and Monitoring Lab](docs/enterprise-infrastructure/07-security-monitoring-lab.md) | Wazuh SIEM, Sysmon, Windows event forwarding, and centralized security telemetry |

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

Completed:

- VMware Workstation deployment
- enterprise VM provisioning (DC01, WIN11-CLIENT01)
- snapshot and rollback workflows
- virtual networking validation
- bridged networking transition for both VMs
- static IP assignment: DC01 (`192.168.1.10`), WIN11-CLIENT01 (`192.168.1.20`)
- DC01 hostname configuration
- Windows updates applied to both VMs: DC01 build 20348.5139, WIN11-CLIENT01 build 26200.8457
- RDP enabled on DC01 and validated from Windows 11 workstation
- RSAT installed on WIN11-CLIENT01 (Active Directory, DNS, Server Manager tools)
- Server Manager baseline familiarization
- Windows Defender Firewall and Defender Antivirus validated
- pre-AD snapshot created for DC01
- pre-domain snapshot created for WIN11-CLIENT01
- Active Directory Domain Services deployed on DC01
- DC01 promoted to domain controller for `corp.home.arpa`
- AD-integrated DNS operational; DC01 self-referencing for DNS
- NTP configured and syncing on DC01
- DNS forwarders configured to `1.1.1.1` and `8.8.8.8`
- OU structure created: IT, User Accounts, Workstations, Groups
- default containers redirected to new OUs
- domain accounts created: `labadmin` (Domain Admins, IT-Admins), `testuser01` (Domain-Users-Standard)
- security groups created: IT-Admins, Domain-Users-Standard, Lab-Workstations
- DC01 advertising as KDC, GC, and PDC Emulator confirmed
- Kerberos TGT validated for `labadmin`
- post-promotion snapshots created for DC01 and WIN11-CLIENT01
- WIN11-CLIENT01 joined to `corp.home.arpa`
- computer account confirmed in `OU=Workstations` via `redircmp` redirect
- domain authentication validated using `testuser01`
- Kerberos TGT confirmed for `testuser01@CORP.HOME.ARPA` via AES-256
- secure channel integrity verified via `nltest /sc_verify`
- DC01 discoverable from WIN11-CLIENT01 via `nltest /dsgetdc`
- Group Policy processing validated via `gpupdate /force` and `gpresult /r`
- AD DNS SRV record resolution confirmed from the joined client
- IPv6 disabled on WIN11-CLIENT01 to resolve competing DNS resolution path
- post-domain-join snapshots created for DC01 and WIN11-CLIENT01

Current focus:
- Group Policy design and deployment (Lab 05)

---

## Current Focus

The project is currently focused on Group Policy design and deployment and the next phase of enterprise infrastructure buildout.

Current areas of focus include:

- Group Policy design and deployment (Lab 05)
- centralized authentication validation
- cross-platform authentication planning
- security monitoring expansion

---

## Long-Term Direction

The long-term objective is to build practical real-world experience that reflects the operational complexity of modern IT environments where:

- Linux and Windows systems coexist
- identity is centralized
- infrastructure is observable and monitored centrally
- services are segmented through layered networking
- security is integrated throughout the environment
- networking is layered
- operational changes are documented and validated incrementally

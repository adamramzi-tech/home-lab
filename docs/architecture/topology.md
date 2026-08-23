# Infrastructure Topology

## Overview

This document describes the physical and logical topology of the homelab environment, including network layout, hardware roles, service relationships, and the management plane.

The environment spans two physical machines connected over a wired LAN, with clearly separated responsibilities:

- **Windows 11 Workstation**: primary management endpoint and virtualization host for enterprise infrastructure labs
- **Ubuntu Server 26.04 LTS**: dedicated Linux infrastructure host running containerized services and a domain member of `corp.home.arpa`

---

## Physical Network Topology

```text
ISP Fiber Connection
        ↓
Primary ISP Router (WiFi 6E)
        ↓
WiFi 6E Mesh Extender
(Located at desk infrastructure node)
        ↓
        ├── Cat6 Ethernet → Windows 11 Workstation (192.168.1.x)
        │
        └── Cat6 Ethernet → Ubuntu Server 26.04 LTS (192.168.1.226)
```

Both machines maintain dedicated wired connections through the mesh extender. The mesh extender provides wireless backhaul to the primary router.

---

## Logical Infrastructure Topology

```text
Windows 11 Workstation
│
├── Management Plane
│   ├── SSH → Ubuntu Server
│   ├── RDP → DC01 (192.168.1.10), WIN11-CLIENT01 (192.168.1.20)
│   ├── Browser → grafana.local, portainer.local, prometheus.local, npm.local
│   │             https://192.168.1.226:8443 (Wazuh Dashboard)
│   └── VS Code Remote Workflows
│
└── VMware Workstation (Hypervisor)
    │
    ├── DC01 (192.168.1.10)
    │   └── Windows Server 2022 Standard Evaluation
    │       ├── Static IP: 192.168.1.10
    │       ├── Hostname: DC01
    │       ├── RDP enabled
    │       ├── Active Directory Domain Services
    │       ├── AD-Integrated DNS
    │       ├── Domain: corp.home.arpa
    │       ├── Group Policy: three custom GPOs deployed and validated
    │       └── Wazuh Agent: enrolled and Active (Windows Security event forwarding)
    │
    └── WIN11-CLIENT01 (192.168.1.20)
        └── Windows 11 Enterprise Evaluation
            ├── Static IP: 192.168.1.20
            ├── Bridged networking
            ├── RSAT installed
            ├── Domain: corp.home.arpa
            ├── Computer account: CN=WIN11-CLIENT01,OU=Workstations,DC=corp,DC=home,DC=arpa
            ├── IPv6 disabled (Ethernet0); DNS: 192.168.1.10 (DC01) only
            ├── Group Policy: Workstation-Security-Baseline, Standard-User-Environment
            │   (or IT-Admin-Environment for labadmin) applied and validated
            └── Wazuh Agent: enrolled and Active (Windows Security event forwarding)

                        ↕ LAN (Cat6, bridged networking)

Ubuntu Server 26.04 LTS (192.168.1.226)
│
├── Active Directory Integration
│   ├── Domain: corp.home.arpa (member)
│   ├── Computer account: CN=UBUNTU-SERVER,OU=Workstations,DC=corp,DC=home,DC=arpa
│   ├── realmd: domain join tooling
│   ├── SSSD: identity and authentication broker
│   │   ├── AD provider: identity sourced from DC01
│   │   ├── Kerberos: authentication tickets from DC01 KDC
│   │   ├── PAM integration: authentication pipeline
│   │   └── NSS integration: identity resolution pipeline
│   └── Access control: Linux-Admins group membership required
│
├── Docker Engine
│   │
│   ├── Security Monitoring Layer
│   │   └── Wazuh Stack (Docker Compose, v4.14.5)
│   │       ├── wazuh-manager (agent comms, rule processing, alert generation)
│   │       ├── wazuh-indexer (OpenSearch data storage and search backend)
│   │       └── wazuh-dashboard (https://192.168.1.226:8443)
│   │
│   ├── Reverse Proxy Layer
│   │   └── NGINX Proxy Manager (ports 80, 443, 81)
│   │       ├── grafana.local → grafana:3000
│   │       ├── prometheus.local → prometheus:9090
│   │       ├── portainer.local → portainer:9443
│   │       └── npm.local → nginx-proxy-manager:81
│   │
│   ├── Monitoring Layer (internal-only)
│   │   ├── Prometheus (metrics collection)
│   │   ├── Node Exporter (host metrics)
│   │   └── Grafana (visualization)
│   │
│   └── Management Layer (internal-only)
│       └── Portainer (Docker administration)
│
├── Wazuh Agent
│   └── wazuh-agent service: enrolled and Active (Linux auth event forwarding)
│
└── Remote Access
    ├── OpenSSH (LAN): AD credentials accepted for Linux-Admins members
    └── Tailscale (WireGuard mesh VPN): remote access
```

---

## Docker Network Topology

```text
Docker Networks on Ubuntu Server
│
├── reverse-proxy-lab_proxy (bridge)
│   ├── nginx-proxy-manager
│   ├── grafana
│   ├── prometheus
│   └── portainer
│
└── monitoring_monitoring (bridge)
    ├── prometheus
    ├── node-exporter
    └── grafana

Note: Grafana and Prometheus are attached to both networks.
Node Exporter is internal-only with no external port exposure.
The Wazuh stack runs on its own internal Docker network (single-node default).
```

---

## Wazuh Agent Coverage

```text
DC01 (192.168.1.10)           ──┐
WIN11-CLIENT01 (192.168.1.20)  ─┼──► wazuh-manager (192.168.1.226:1514)
Ubuntu Server (192.168.1.226)  ──┘         │
                                            ▼
                                     wazuh-indexer
                                            │
                                            ▼
                                     wazuh-dashboard
                                (https://192.168.1.226:8443)
```

---

## Group Policy Topology

```text
corp.home.arpa [domain]
│
├── Default Domain Policy [not modified]
│
├── IT [OU]
│   ├── IT-Admin-Environment GPO (user-scoped: desktop wallpaper)
│   └── labadmin
│
├── User Accounts [OU]
│   ├── Standard-User-Environment GPO (user-scoped: Control Panel, Run, display, LAN restrictions)
│   └── testuser01
│
└── Workstations [OU]
    ├── Workstation-Security-Baseline GPO (computer-scoped: inactivity limit, firewall, audit)
    │   └── Security Filter: Lab-Workstations (Authenticated Users removed)
    ├── WIN11-CLIENT01 (computer account; member of Lab-Workstations)
    └── UBUNTU-SERVER (computer account)
```

---

## Service Access Map

| Service | Access Method | URL / Address | Notes |
|---|---|---|---|
| Grafana | Reverse proxy | `http://grafana.local` | Internal only, hosts file required |
| Prometheus | Reverse proxy | `http://prometheus.local` | Internal only |
| Portainer | Reverse proxy | `http://portainer.local` | Internal only |
| NPM Admin | Reverse proxy | `http://npm.local` | Internal only |
| Wazuh Dashboard | Direct HTTPS | `https://192.168.1.226:8443` | Internal only |
| Ubuntu SSH | Direct LAN | `ssh user@192.168.1.226` | Key-based auth |
| Ubuntu SSH | Tailscale | `ssh user@<tailscale-ip>` | Remote access |
| DC01 | RDP | `192.168.1.10` | Active Directory domain controller; AD DS and DNS operational; Group Policy deployed; Wazuh agent Active |
| WIN11-CLIENT01 | RDP | `192.168.1.20` | Domain-joined; computer account in OU=Workstations; Group Policy applied and validated; Wazuh agent Active |

---

## Management Plane

All infrastructure is administered remotely from the Windows 11 workstation. No direct physical console access is required during normal operations.

Management tools in use:

| Tool | Purpose |
|---|---|
| Windows Terminal | SSH sessions to Ubuntu Server |
| VS Code Remote | Remote file editing on Ubuntu Server |
| Browser | Grafana, Portainer, NPM, Prometheus, Wazuh Dashboard |
| VMware Workstation | VM console, lifecycle, snapshots |
| RDP | Windows Server and client VM administration |
| RSAT (WIN11-CLIENT01) | Remote Active Directory, DNS, and Group Policy administration |
| PowerShell script library (WIN11-CLIENT01) | AD user and group lifecycle, OU and account inventory, Group Policy reporting, and scheduled environment health reporting, per [ADR-016](decisions/016-run-automation-scripts-from-domain-joined-client.md) |
| Task Scheduler (WIN11-CLIENT01) | Daily unattended run of `Invoke-LabHealthReport.ps1`, reporting AD service state, Wazuh agent enrollment, and Docker container status |
| Git / GitHub | Documentation version control |

---

## Infrastructure Boundaries

| Boundary | Description |
|---|---|
| Linux ↔ Enterprise | Two separate physical machines. No shared hypervisor. LAN-connected only. |
| Docker internal | No backend service exposes ports directly. All access through NPM or direct IP where applicable. |
| VM networking | DC01 and WIN11-CLIENT01 operate on bridged networking with direct LAN presence. Enterprise VMs are LAN participants alongside the Ubuntu Server host. |
| AD domain scope | Active Directory domain (`corp.home.arpa`) spans both enterprise VMs and the Ubuntu Server host. DC01 is the authoritative DNS server for the domain. WIN11-CLIENT01 uses DC01 exclusively for DNS (IPv4 only; IPv6 disabled on Ethernet0). Ubuntu Server uses DC01 as its primary DNS server via Netplan. |
| Group Policy scope | Computer policy scoped to `OU=Workstations`; user policy scoped independently to `OU=User Accounts` and `OU=IT`. Security group filtering on `Workstation-Security-Baseline` restricts application to `Lab-Workstations` members. |
| Wazuh agent scope | All three systems (DC01, WIN11-CLIENT01, Ubuntu Server) enrolled as Wazuh agents reporting to wazuh-manager on Ubuntu Server at `192.168.1.226:1514`. |
| Remote access | Tailscale provides encrypted remote access without exposing SSH publicly. |

---

## Evolution

The environment evolves across the three tracks defined in ADR-014. The first is complete, the second is established and in planning, and the third remains planned.

**Track 3: Infrastructure Automation and Scripting (completed)**

PowerShell automation of Active Directory administration workflows, run from WIN11-CLIENT01 against DC01 per [ADR-016](decisions/016-run-automation-scripts-from-domain-joined-client.md). The track introduced no new hosts, services, or network segments; the existing environment served as the automation target throughout.

It did add two management-plane paths that did not exist before, both from WIN11-CLIENT01 and both read-only queries against services already running rather than new remoting technology. Lab 05 (Scheduled Health Reporting) reaches the Wazuh Manager REST API at `192.168.1.226:55000` over HTTPS, and the Portainer REST API through `http://portainer.local` via NGINX Proxy Manager, which requires a `192.168.1.226 portainer.local` hosts-file entry on WIN11-CLIENT01 because ADR-009 removed Portainer's direct LAN port and the proxy host is HTTP-only. It also queries DC01's service state through the Service Control Manager's remote RPC interface, distinct from PowerShell Remoting. The resulting health report runs unattended as a daily Task Scheduler job on WIN11-CLIENT01, making that client the environment's only scheduled, non-interactive execution point.

**Track 4: Cloud and Hybrid Identity (next)**

Extension of the on-premises AD environment into Microsoft Entra ID through Entra Connect Sync, scoped by [ADR-019](decisions/019-establish-cloud-and-hybrid-identity-track.md). The topology will expand to include a hybrid identity boundary between `corp.home.arpa` and an Entra tenant. This is the first track to place part of the environment's own identity plane on the public internet: the tenant's administration portals cannot be published through NGINX Proxy Manager or confined to Tailscale the way every existing service is. External consoles are not themselves new, since Tailscale and the domain registrar both have one, but neither holds the directory.

Two on-premises changes are planned. A third virtual machine, `SYNC01`, running Windows Server 2022 and joined to `corp.home.arpa`, will host Entra Connect Sync, since the synchronization engine requires a server operating system and ADR-019 deliberately keeps it off DC01. And a routable user principal name suffix, supplied by a registered public domain, will be added alongside the existing `corp.home.arpa` suffix, because `home.arpa` is reserved by RFC 8375 and cannot be verified in a tenant. Neither changes the domain name, the Kerberos realm, `sAMAccountName` values, DNS, or Group Policy scoping.

Connectivity is outbound only. Password hash synchronization is the chosen authentication method precisely because it requires no publicly reachable on-premises endpoint, so `SYNC01` reaches Microsoft Entra ID outbound and nothing new is exposed inbound.

**Track 5: Network Infrastructure (planned)**

Perimeter firewall deployment and VLAN segmentation. This track will introduce the most significant topology changes: the current flat LAN will be replaced with a segmented architecture. The topology document will be updated substantially when Track 5 planning begins.

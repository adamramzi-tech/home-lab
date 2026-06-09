# Infrastructure Topology

## Overview

This document describes the physical and logical topology of the homelab environment, including network layout, hardware roles, service relationships, and the management plane.

The environment spans two physical machines connected over a wired LAN, with clearly separated responsibilities:

- **Windows 11 Workstation**: primary management endpoint and virtualization host for enterprise infrastructure labs
- **Ubuntu Server 26.04 LTS**: dedicated Linux infrastructure host running containerized services

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
    │       └── Group Policy: three custom GPOs deployed and validated
    │
    └── WIN11-CLIENT01 (192.168.1.20)
        └── Windows 11 Enterprise Evaluation
            ├── Static IP: 192.168.1.20
            ├── Bridged networking
            ├── RSAT installed
            ├── Domain: corp.home.arpa
            ├── Computer account: CN=WIN11-CLIENT01,OU=Workstations,DC=corp,DC=home,DC=arpa
            ├── IPv6 disabled (Ethernet0); DNS: 192.168.1.10 (DC01) only
            └── Group Policy: Workstation-Security-Baseline, Standard-User-Environment
                (or IT-Admin-Environment for labadmin) applied and validated

                        ↕ LAN (Cat6, bridged networking)

Ubuntu Server 26.04 LTS (192.168.1.226)
│
├── Docker Engine
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
├── Remote Access
│   ├── OpenSSH (LAN)
│   └── Tailscale (WireGuard mesh VPN): remote access
│
└── Planned Cross-Platform Integration
    ├── windows-exporter → Prometheus (Windows metrics)
    ├── SSSD + Kerberos (Linux AD authentication) [Lab 06]
    ├── Wazuh Agent (security monitoring) [Lab 07]
    └── Centralized logging pipeline
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
    └── WIN11-CLIENT01 (computer account; member of Lab-Workstations)
```

---

## Service Access Map

| Service | Access Method | URL / Address | Notes |
|---|---|---|---|
| Grafana | Reverse proxy | `http://grafana.local` | Internal only, hosts file required |
| Prometheus | Reverse proxy | `http://prometheus.local` | Internal only |
| Portainer | Reverse proxy | `http://portainer.local` | Internal only |
| NPM Admin | Reverse proxy | `http://npm.local` | Internal only |
| Ubuntu SSH | Direct LAN | `ssh user@192.168.1.226` | Key-based auth |
| Ubuntu SSH | Tailscale | `ssh user@<tailscale-ip>` | Remote access |
| DC01 | RDP | `192.168.1.10` | Active Directory domain controller; AD DS and DNS operational; Group Policy deployed |
| WIN11-CLIENT01 | RDP | `192.168.1.20` | Domain-joined; computer account in OU=Workstations; Group Policy applied and validated |

---

## Management Plane

All infrastructure is administered remotely from the Windows 11 workstation. No direct physical console access is required during normal operations.

Management tools in use:

| Tool | Purpose |
|---|---|
| Windows Terminal | SSH sessions to Ubuntu Server |
| VS Code Remote | Remote file editing on Ubuntu Server |
| Browser | Grafana, Portainer, NPM, Prometheus |
| VMware Workstation | VM console, lifecycle, snapshots |
| RDP | Windows Server and client VM administration |
| RSAT (WIN11-CLIENT01) | Remote Active Directory, DNS, and Group Policy administration |
| Git / GitHub | Documentation version control |

---

## Infrastructure Boundaries

| Boundary | Description |
|---|---|
| Linux ↔ Enterprise | Two separate physical machines. No shared hypervisor. LAN-connected only. |
| Docker internal | No backend service exposes ports directly. All access through NPM. |
| VM networking | DC01 and WIN11-CLIENT01 operate on bridged networking with direct LAN presence. Enterprise VMs are LAN participants alongside the Ubuntu Server host. |
| AD domain scope | Active Directory domain (`corp.home.arpa`) is scoped to enterprise VMs. DC01 is the authoritative DNS server for the domain. WIN11-CLIENT01 is joined to the domain and uses DC01 exclusively for DNS (IPv4 only; IPv6 disabled on Ethernet0). |
| Group Policy scope | Computer policy scoped to `OU=Workstations`; user policy scoped independently to `OU=User Accounts` and `OU=IT`. Security group filtering on `Workstation-Security-Baseline` restricts application to `Lab-Workstations` members. |
| Remote access | Tailscale provides encrypted remote access without exposing SSH publicly. |

---

## Planned Evolution

As the enterprise infrastructure track progresses, the topology will evolve to include:

- Ubuntu Server authenticating against Active Directory via SSSD and Kerberos (Lab 06)
- Windows metrics flowing into the existing Prometheus/Grafana stack
- Wazuh SIEM collecting logs from both Linux and Windows systems (Lab 07)
- Additional systems integrated with the `corp.home.arpa` Active Directory domain
- Potential future Proxmox node for dedicated virtualization capacity

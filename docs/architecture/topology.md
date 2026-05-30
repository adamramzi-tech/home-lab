# Infrastructure Topology

## Overview

This document describes the physical and logical topology of the homelab environment, including network layout, hardware roles, service relationships, and the management plane.

The environment spans two physical machines connected over a wired LAN, with clearly separated responsibilities:

- **Windows 11 Workstation** — primary management endpoint and virtualization host for enterprise infrastructure labs
- **Ubuntu Server 26.04 LTS** — dedicated Linux infrastructure host running containerized services

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
│   ├── RDP → DC01, WIN11-CLIENT01
│   ├── Browser → grafana.local, portainer.local, prometheus.local, npm.local
│   └── VS Code Remote Workflows
│
└── VMware Workstation (Hypervisor)
    │
    ├── DC01 (planned)
    │   └── Windows Server 2022
    │       ├── Active Directory Domain Services
    │       ├── AD-Integrated DNS
    │       └── Domain: ad.home.lab (planned)
    │
    └── WIN11-CLIENT01 (planned)
        └── Windows 11 Enterprise
            └── Domain-Joined Client

                        ↕ LAN (Cat6)

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
│   └── Tailscale (WireGuard mesh VPN — remote access)
│
└── Planned Cross-Platform Integration
    ├── windows-exporter → Prometheus (Windows metrics)
    ├── SSSD + Kerberos (Linux AD authentication)
    ├── Wazuh Agent (security monitoring)
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
Node Exporter is internal-only — no external port exposure.
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
| DC01 | RDP | `192.168.1.10` | Planned |
| WIN11-CLIENT01 | RDP | `192.168.1.20` | Planned |

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
| Git / GitHub | Documentation version control |

---

## Infrastructure Boundaries

| Boundary | Description |
|---|---|
| Linux ↔ Enterprise | Two separate physical machines. No shared hypervisor. LAN-connected only. |
| Docker internal | No backend service exposes ports directly. All access through NPM. |
| VM isolation | VMware virtual networking is used to isolate enterprise lab traffic from the primary workstation environment while maintaining LAN connectivity where required. AD domain does not affect workstation DNS. |
| Remote access | Tailscale provides encrypted remote access without exposing SSH publicly. |

---

## Planned Evolution

As the enterprise infrastructure track progresses, the topology will evolve to include:

- Windows metrics flowing into the existing Prometheus/Grafana stack
- Ubuntu Server authenticating against Active Directory via SSSD
- Wazuh SIEM collecting logs from both Linux and Windows systems
- Centralized DNS provided by DC01 for the AD domain, scoped to `ad.home.lab`
- Potential future Proxmox node for dedicated virtualization capacity

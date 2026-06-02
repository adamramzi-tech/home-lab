# Enterprise Infrastructure Resource Plan

## Purpose

This document defines the virtualization architecture, resource allocation strategy, and operational design for the enterprise infrastructure phase of the homelab environment.

The enterprise environment operates using VMware Workstation hosted on the primary Windows 11 workstation.

The objective of this phase is to introduce:
- virtualization workflows
- Windows enterprise infrastructure
- Active Directory
- centralized authentication
- Group Policy
- Windows administration
- enterprise networking concepts
- cross-platform integration

while remaining within the practical limits of available hardware resources.

The environment is intentionally designed as a learning-focused infrastructure platform rather than a high-availability production environment.

---

# Architectural Context

The enterprise infrastructure environment is a secondary infrastructure track alongside the existing Linux infrastructure platform.

The current Linux infrastructure environment remains the operational foundation of the homelab and currently hosts:
- Docker infrastructure
- monitoring services
- reverse proxy services
- remote administration tooling
- containerized infrastructure workloads

The enterprise infrastructure environment is intended primarily for:
- virtualization administration
- Windows Server deployment
- Active Directory experimentation
- Group Policy testing
- enterprise authentication workflows
- hybrid infrastructure integration

The virtualization environment is hosted on separate hardware from the Ubuntu Server host in order to:
- preserve Linux infrastructure stability
- isolate experimental enterprise workloads
- simplify rollback and recovery workflows
- reduce operational risk to existing services
- allow independent infrastructure evolution

This separation strategy is considered foundational to maintaining infrastructure stability while introducing more complex enterprise technologies incrementally.

---

# Current State

Labs 01 and 02 are complete. The enterprise infrastructure environment is fully configured and ready for Active Directory deployment.

Current state of the enterprise infrastructure environment:

- VMware Workstation Pro is deployed and operational on the Windows 11 workstation
- DC01 is provisioned with Windows Server 2022 Standard Evaluation (Desktop Experience)
- WIN11-CLIENT01 is provisioned with Windows 11 Enterprise Evaluation
- VMware Tools is installed and operational on both virtual machines
- both VMs are configured on bridged networking with direct LAN presence
- DC01 static IP: `192.168.1.10`, hostname: `DC01`
- WIN11-CLIENT01 static IP: `192.168.1.20`
- Windows updates applied, DC01 OS Build 20348.5139 (Version 21H2), WIN11-CLIENT01 OS Build 26200.8457 (Version 25H2)
- RDP is enabled on DC01 and validated from the Windows 11 workstation
- RSAT is installed on WIN11-CLIENT01 (Active Directory, DNS, and Server Manager tools)
- WIN11-CLIENT01 DNS points to DC01 (`192.168.1.10`) in preparation for AD-integrated DNS
- DC01 DNS temporarily uses public resolvers (`1.1.1.1` / `8.8.8.8`) pending AD promotion
- pre-AD snapshot created for DC01: `DC01 - Configured Windows Server Base, Pre-AD`
- pre-domain snapshot created for WIN11-CLIENT01: `WIN11-CLIENT01 - Configured Client Base, Pre-Domain`
- Active Directory infrastructure has not yet been implemented
- the Linux infrastructure environment remains the primary operational platform

The environment is now prepared for Active Directory Domain Services deployment in Lab 03.

---

# Virtualization Host

## Primary Hypervisor Platform

Platform:
- VMware Workstation

Host System:
- Windows 11 workstation

Host Hardware:
- AMD Ryzen 5 7600X3D
- 32GB DDR5 RAM
- NVMe SSD storage
- NVIDIA RTX 5070

The Windows workstation was selected because it provides:
- significantly stronger hardware resources
- fast NVMe-backed virtualization storage
- strong single-core virtualization performance
- sufficient memory capacity for concurrent VM workloads
- operational separation from the Linux infrastructure host

The workstation functions as:
- the primary virtualization host
- the primary enterprise administration workstation
- the management platform for hybrid infrastructure operations

---

# Virtualization Design Philosophy

The enterprise virtualization environment is intentionally designed around:
- operational simplicity
- conservative resource allocation
- recoverability
- snapshot-based experimentation
- incremental infrastructure expansion
- low operational overhead

The environment is intentionally lightweight during the initial deployment phase.

The goal is not to simulate large-scale enterprise infrastructure, but rather to build practical operational understanding involving:
- Active Directory
- Windows administration
- identity management
- Group Policy
- DNS architecture
- virtualization workflows
- hybrid infrastructure concepts

Initial deployments prioritize:
- stability
- observability
- maintainability
- ease of recovery
- controlled experimentation

More advanced enterprise concepts will be introduced incrementally as the environment matures.

---

# Host Resource Allocation Strategy

## Available Host Resources

| Resource | Capacity |
|---|---|
| CPU | AMD Ryzen 5 7600X3D |
| Memory | 32GB DDR5 |
| Storage | NVMe SSD storage |

## Allocation Philosophy

Virtual machine resource allocation is intentionally conservative during the initial deployment phase.

The virtualization environment must coexist with:
- the Windows 11 host operating system
- browser-based management workflows
- documentation workflows
- development tooling
- remote administration tooling
- normal workstation usage

Initial deployments are therefore designed to:
- avoid excessive host memory pressure
- preserve workstation responsiveness
- maintain virtualization stability
- simplify troubleshooting workflows
- leave room for future expansion

The initial environment operates comfortably within available workstation resources without requiring aggressive resource overcommitment.

---

# Storage Planning

The enterprise virtualization environment utilizes local NVMe SSD storage hosted directly on the Windows 11 workstation.

Advantages of NVMe-backed virtualization storage include:
- low latency VM performance
- rapid snapshot creation
- improved Windows update performance
- responsive VM administration
- simplified deployment workflows

Virtual disks use:
- dynamically expanding disks
- thin provisioning

This approach:
- reduces unnecessary storage consumption
- simplifies early-stage experimentation
- preserves host storage flexibility
- supports incremental infrastructure growth

Snapshot usage is limited primarily to:
- pre-deployment rollback points
- Active Directory configuration changes
- Group Policy experimentation
- major networking or DNS modifications

Long-term snapshot accumulation is avoided to reduce:
- storage fragmentation
- performance degradation
- excessive disk consumption

---

# Virtual Machine Inventory

## DC01

### Role

- Active Directory Domain Controller (planned)
- DNS Server (planned)

### Operating System

- Windows Server 2022 Standard Evaluation (Desktop Experience)

### Deployed Resources

| Resource | Allocation |
|---|---|
| vCPU | 2 |
| Memory | 4 GB |
| Storage | 80 GB thin provisioned |

### Current Configuration

- Hostname: `DC01`
- Static IP: `192.168.1.10`
- Subnet mask: `255.255.255.0`
- Default gateway: `192.168.1.1`
- DNS (temporary): `1.1.1.1` / `8.8.8.8`
- Networking: VMware Bridged (direct LAN)
- RDP: Enabled
- OS Build: 20348.5139 (Version 21H2)
- Snapshot: `DC01 - Configured Windows Server Base, Pre-AD`

### Planned Responsibilities

- Active Directory Domain Services
- AD-integrated DNS
- centralized authentication
- Group Policy management
- domain identity services
- internal enterprise DNS resolution

---

## WIN11-CLIENT01

### Role

- Enterprise admin workstation
- Domain-joined Windows workstation (pending Lab 04)

### Operating System

- Windows 11 Enterprise Evaluation

### Deployed Resources

| Resource | Allocation |
|---|---|
| vCPU | 4 |
| Memory | 8 GB |
| Storage | 120 GB thin provisioned |

### Current Configuration

- Hostname: `WIN11-CLIENT01`
- Static IP: `192.168.1.20`
- Subnet mask: `255.255.255.0`
- Default gateway: `192.168.1.1`
- DNS (primary): `192.168.1.10` (DC01)
- Networking: VMware Bridged (direct LAN)
- RSAT: Installed (Active Directory, DNS, Server Manager tools)
- OS Build: 26200.8457 (Version 25H2)
- Snapshot: `WIN11-CLIENT01 - Configured Client Base, Pre-Domain`

### Planned Usage

- domain authentication testing
- Group Policy validation
- Windows administration workflows
- RSAT tooling
- endpoint management testing
- enterprise client administration
- cross-platform integration testing

---

# Identity and DNS Strategy

## Planned Internal Domain

Planned internal domain:

```text
ad.home.lab
```

## DNS Strategy

The enterprise environment will utilize:
- AD-integrated DNS
- centralized internal name resolution
- DNS forwarding for external resolution

Planned DNS flow:

```text
Domain Clients
        ↓
DC01 DNS Server (192.168.1.10)
        ↓
Upstream Router or Public Resolver
```

WIN11-CLIENT01 is already configured to use DC01 (`192.168.1.10`) as its primary DNS server. DC01 itself will be reconfigured to point to itself (`192.168.1.10`) as primary DNS at the time of Active Directory promotion.

This architecture supports:
- Active Directory service discovery
- Kerberos authentication
- LDAP functionality
- Group Policy processing
- centralized internal name resolution

---

# Networking

## Virtual Network Configuration

Both DC01 and WIN11-CLIENT01 operate on VMware bridged networking, giving each VM a direct LAN presence through the Windows 11 workstation's physical adapter.

Confirmed addressing:

```text
DC01               192.168.1.10
WIN11-CLIENT01     192.168.1.20
Ubuntu Server      192.168.1.226
Router             192.168.1.1
```

DC01 has been validated as reachable from:
- the Windows 11 host (ping and RDP)
- WIN11-CLIENT01 (ping)
- the Ubuntu Server host (ping)

WIN11-CLIENT01 has been validated as reachable from:
- the Windows 11 host (ping)

ICMPv4 inbound firewall rules have been enabled on both VMs to support LAN ping validation.

More advanced virtualization networking concepts may later include:
- isolated virtual lab segments
- routed internal networks
- VLAN-backed virtualization
- segmented enterprise lab environments

These concepts will be introduced incrementally rather than during the initial deployment phase.

---

# Infrastructure Separation Strategy

The environment intentionally separates:
- Linux infrastructure workloads
- virtualization workloads
- enterprise experimentation
- operational container infrastructure

This reduces the likelihood that:
- virtualization instability
- Active Directory experimentation
- Windows networking changes
- Group Policy testing
- DNS misconfiguration

will negatively impact the operational Linux infrastructure environment.

The Ubuntu Server host continues functioning as:
- the primary infrastructure services platform
- the Docker services platform
- the monitoring platform
- the reverse proxy platform
- the Linux administration environment

The Windows virtualization environment functions primarily as:
- the enterprise experimentation platform
- the identity infrastructure platform
- the virtualization learning environment

---

# Planned Cross-Platform Integration

The enterprise infrastructure environment is not intended to replace the existing Linux infrastructure platform.

The long-term objective is to build a hybrid infrastructure environment where:
- Linux and Windows systems coexist
- authentication becomes centralized
- monitoring pipelines span multiple platforms
- infrastructure visibility remains unified
- services remain segmented appropriately

Planned future integrations may include:
- Linux authentication against Active Directory
- centralized DNS integration
- Windows metrics exporting
- Prometheus integration for Windows systems
- Grafana dashboards for hybrid infrastructure visibility
- centralized logging workflows
- SIEM integration using Wazuh
- cross-platform monitoring and telemetry

---

# Operational Constraints

The environment currently operates within the limits of:
- consumer desktop hardware
- shared workstation resources
- non-redundant infrastructure
- single-host virtualization
- limited memory capacity
- local storage constraints

These constraints are intentional and accepted as part of the learning-focused design of the environment.

The objective of the project is not to simulate enterprise-scale hardware availability, but rather to develop practical infrastructure administration and architectural understanding using accessible hardware resources.

---

# Future Expansion Planning

The initial enterprise environment is focused primarily on:
- Active Directory fundamentals
- virtualization workflows
- Windows administration
- Group Policy management
- centralized identity concepts
- enterprise DNS architecture

Future infrastructure expansion may include:
- additional Windows Server roles
- Windows Server Core deployments
- secondary infrastructure servers
- Linux and Active Directory integration
- centralized logging infrastructure
- SIEM platforms
- Windows monitoring agents
- security telemetry pipelines
- segmented virtual networks
- centralized authentication workflows

Resource allocation strategies will evolve incrementally as additional enterprise services are introduced.

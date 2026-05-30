# Enterprise Infrastructure Resource Plan

## Purpose

This document defines the planned virtualization architecture, resource allocation strategy, and operational design for the enterprise infrastructure phase of the homelab environment.

The enterprise environment will initially operate using VMware Workstation hosted on the primary Windows 11 workstation.

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

The enterprise infrastructure environment is being introduced as a secondary infrastructure track alongside the existing Linux infrastructure platform.

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

The virtualization environment is intentionally hosted on separate hardware from the Ubuntu Server host in order to:
- preserve Linux infrastructure stability
- isolate experimental enterprise workloads
- simplify rollback and recovery workflows
- reduce operational risk to existing services
- allow independent infrastructure evolution

This separation strategy is considered foundational to maintaining infrastructure stability while introducing more complex enterprise technologies incrementally.

---

# Current State

At this stage of the project:
- VMware Workstation has not yet been deployed
- enterprise virtual machines do not yet exist
- Active Directory infrastructure has not yet been implemented
- virtualization architecture remains in the planning phase
- the Linux infrastructure environment remains the primary operational platform

This document defines the intended initial enterprise infrastructure strategy before deployment begins.

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

The workstation will function as:
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

The initial environment is expected to operate comfortably within available workstation resources without requiring aggressive resource overcommitment.

---

# Storage Planning

The enterprise virtualization environment will initially utilize local NVMe SSD storage hosted directly on the Windows 11 workstation.

Advantages of NVMe-backed virtualization storage include:
- low latency VM performance
- rapid snapshot creation
- improved Windows update performance
- responsive VM administration
- simplified deployment workflows

Virtual disks will initially use:
- dynamically expanding disks
- thin provisioning

This approach:
- reduces unnecessary storage consumption
- simplifies early-stage experimentation
- preserves host storage flexibility
- supports incremental infrastructure growth

Snapshot usage will be limited primarily to:
- pre-deployment rollback points
- Active Directory configuration changes
- Group Policy experimentation
- major networking or DNS modifications

Long-term snapshot accumulation will be avoided to reduce:
- storage fragmentation
- performance degradation
- excessive disk consumption

---

# Planned Virtual Machine Inventory

## DC01

### Role

- Active Directory Domain Controller
- DNS Server

### Operating System

- Windows Server 2022

### Planned Resources

| Resource | Allocation |
|---|---|
| vCPU | 2 |
| Memory | 4GB |
| Storage | 100GB thin provisioned |

### Planned Responsibilities

- Active Directory Domain Services
- AD-integrated DNS
- centralized authentication
- Group Policy management
- domain identity services
- internal enterprise DNS resolution

### Notes

The domain controller is intentionally lightweight because the environment is expected to support only a small number of systems during the initial deployment phase.

---

## WIN11-CLIENT01

### Role

- Domain-joined Windows workstation

### Operating System

- Windows 11 Enterprise

### Planned Resources

| Resource | Allocation |
|---|---|
| vCPU | 4 |
| Memory | 8GB |
| Storage | 120GB thin provisioned |

### Planned Usage

- domain authentication testing
- Group Policy validation
- Windows administration workflows
- RSAT tooling
- endpoint management testing
- enterprise client administration
- cross-platform integration testing

### Notes

The Windows client VM is allocated additional memory and storage to accommodate:
- Windows update growth
- enterprise administration tooling
- browser-based management workflows
- future monitoring agents
- security tooling
- operational flexibility

---

# Planned Identity and DNS Strategy

## Planned Internal Domain

Planned internal domain:

```text
ad.home.lab
```

This naming convention may evolve before deployment, but the initial environment will utilize a dedicated internal Active Directory namespace.

## Planned DNS Strategy

The enterprise environment will utilize:
- AD-integrated DNS
- centralized internal name resolution
- DNS forwarding for external resolution

Planned DNS flow:

```text
Domain Clients
        ↓
DC01 DNS Server
        ↓
Upstream Router or Public Resolver
```

Enterprise domain clients will ultimately use:
- DC01 as primary DNS

This architecture supports:
- Active Directory service discovery
- Kerberos authentication
- LDAP functionality
- Group Policy processing
- centralized internal name resolution

---

# Planned Networking

## Virtual Network Strategy

The enterprise virtualization environment will initially prioritize:
- simplicity
- recoverability
- observability
- ease of troubleshooting
- compatibility with the existing Linux infrastructure

Initial deployments may utilize VMware NAT networking during early experimentation phases.

This allows:
- simplified VM deployment
- outbound internet connectivity
- access to the existing Linux infrastructure environment
- reduced initial networking complexity

As the enterprise environment matures, core infrastructure systems such as:
- domain controllers
- enterprise clients
- monitoring-integrated systems

may transition toward bridged networking in order to support:
- direct LAN participation
- centralized DNS workflows
- hybrid Linux and Windows integration
- cross-platform monitoring
- more realistic enterprise communication patterns

More advanced virtualization networking concepts may later include:
- isolated virtual lab segments
- routed internal networks
- VLAN-backed virtualization
- segmented enterprise lab environments

These concepts will be introduced incrementally rather than during the initial deployment phase.

---

# Planned Addressing

Initial planned addressing:

```text
DC01               192.168.1.10
WIN11-CLIENT01     192.168.1.20
Ubuntu Server      192.168.1.226
```

These values may evolve during implementation.

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

The Ubuntu Server host will continue functioning as:
- the primary infrastructure services platform
- the Docker services platform
- the monitoring platform
- the reverse proxy platform
- the Linux administration environment

The Windows virtualization environment will function primarily as:
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

The initial enterprise environment is intentionally minimal and focused primarily on:
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
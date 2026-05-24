# 01 - Virtualization Lab

## Objective

The goal of this lab is to establish the virtualization foundation for the enterprise infrastructure track using VMware Workstation on the primary Windows 11 workstation.

This environment will provide isolated virtual infrastructure for future Windows Server, Active Directory, Group Policy, and cross-platform integration labs.

The objective is not only to deploy virtual machines, but also to understand:
- virtual networking
- resource allocation
- VM lifecycle management
- snapshots and rollback workflows
- infrastructure segmentation
- enterprise lab design considerations

---

# Project Context

## Why Virtualization Was Introduced

The next phase of the homelab project expands beyond Linux infrastructure into enterprise infrastructure concepts such as:
- Windows Server administration
- Active Directory
- Group Policy
- centralized identity management
- domain-joined clients
- cross-platform integration

These technologies require isolated systems that can be deployed, modified, reset, and managed independently without affecting the primary workstation or existing Linux infrastructure environment.

Virtualization provides the ability to:
- create isolated enterprise lab environments
- run multiple operating systems simultaneously
- simulate real-world client/server infrastructure
- snapshot and roll back systems safely
- experiment without impacting production infrastructure
- scale the environment incrementally over time

The existing Ubuntu Server infrastructure is already running a live Docker environment that supports:
- monitoring
- reverse proxy services
- container networking
- remote administration workflows

While virtualization could technically be deployed directly onto the Ubuntu Server using KVM/libvirt, the long-term goal of the project is to preserve the Ubuntu environment as a dedicated Linux infrastructure platform for future containerized services, networking labs, monitoring expansion, and additional infrastructure experimentation.

The current Ubuntu Server hardware is fully capable of supporting the existing Docker infrastructure, but introducing multiple Windows virtual machines alongside live infrastructure services would significantly reduce available system resources and limit flexibility for future Linux-focused projects.

After evaluating:
- available hardware resources
- future infrastructure growth
- operational scalability
- virtualization performance
- long-term infrastructure goals

the decision was made to host enterprise virtualization workloads on the primary Windows 11 workstation instead.

This approach allows:
- separation between Linux infrastructure and enterprise labs
- improved virtualization performance
- reduced risk to the existing Docker environment
- simplified Windows VM management
- greater flexibility for future enterprise infrastructure expansion

---

# Existing Environment

## Current Infrastructure State

At the beginning of this lab, the following infrastructure was already operational:

### Ubuntu Server Infrastructure
- Ubuntu Server 26.04 LTS
- Docker Engine
- Portainer
- Prometheus
- Grafana
- NGINX Proxy Manager
- Tailscale
- SSH remote administration

### Windows 11 Workstation
- Primary management endpoint
- Documentation workstation
- Future virtualization host

---

# Planned Virtual Infrastructure

## Target VM Layout

```text
VMware Workstation
├── DC01
│   └── Windows Server 2022
│
└── WIN11-CLIENT01
    └── Windows 11 Enterprise Client
```

Future labs will build additional services on top of this environment incrementally.

---

# Hardware Considerations

## Virtualization Host Resources

| Component | Details |
|---|---|
| CPU | AMD Ryzen 5 7600X3D |
| RAM | 32GB DDR5 |
| Storage | Dual NVMe SSDs |
| GPU | NVIDIA RTX 5070 |

The workstation hardware provides substantially more headroom for virtualization workloads than the current Ubuntu Server infrastructure.

This allows:
- simultaneous VM operation
- snapshot management
- better memory allocation flexibility
- future expansion without impacting Linux infrastructure services

---

# Hypervisor Selection

## VMware Workstation Evaluation

VMware Workstation was selected for the initial virtualization platform due to:
- mature virtualization tooling
- strong snapshot support
- straightforward VM management
- flexible networking configuration
- broad community documentation
- compatibility with Windows enterprise labs

Alternative hypervisors considered:
- Hyper-V
- VirtualBox
- KVM/libvirt

Additional hypervisor evaluation may occur in future labs.

---

# Planned Networking Design

## Initial Virtual Networking Goals

The virtualization environment will eventually support:
- isolated enterprise lab networking
- domain controller communication
- domain client authentication
- DNS resolution workflows
- future Linux and Active Directory integration

Initial planning includes evaluation of:
- NAT networking
- bridged networking
- host-only networking
- VM isolation strategies

---

# Planned VM Specifications

## DC01

| Resource | Allocation |
|---|---|
| OS | Windows Server 2022 |
| vCPU | Planned |
| RAM | Planned |
| Storage | Planned |

## WIN11-CLIENT01

| Resource | Allocation |
|---|---|
| OS | Windows 11 |
| vCPU | Planned |
| RAM | Planned |
| Storage | Planned |

Final allocations will be determined during deployment and performance testing.

---

# Risks and Considerations

## Operational Separation

A major design priority for this phase is preserving stability of the existing Linux infrastructure environment.

The Ubuntu Server currently hosts live containerized infrastructure services. Introducing virtualization directly onto the server at this stage would:
- increase operational complexity
- complicate networking architecture
- introduce additional resource pressure
- increase troubleshooting scope

Separating virtualization onto the workstation reduces risk while maintaining clear infrastructure boundaries.

---

# Planned Validation Steps

The following validation tasks are planned during deployment:
- VMware installation verification
- VM creation testing
- virtual networking validation
- snapshot testing
- VM startup/shutdown validation
- resource utilization monitoring
- LAN connectivity testing
- remote management validation

---

# Lessons Learned

## Architectural Planning Matters

One major takeaway from this planning phase was that infrastructure architecture decisions should occur before deployment rather than during troubleshooting.

Separating:
- Linux infrastructure
- enterprise infrastructure
- virtualization workloads

created a cleaner and more scalable long-term environment design.

---

# Current Status

## Planning and Research Phase

At this stage:
- virtualization architecture has been planned
- workstation resource allocation has been evaluated
- infrastructure boundaries have been defined
- repository structure has been reorganized
- future enterprise lab progression has been documented

VMware deployment and VM creation will occur in the next phase of the project.
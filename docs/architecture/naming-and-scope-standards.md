# Infrastructure Standards and Naming Conventions

## Purpose

This document defines the operational standards and naming conventions used throughout the homelab project.

The objective is to maintain:

- consistency
- readability
- predictable structure
- scalable documentation organization
- infrastructure clarity as the environment grows

These standards apply to:

- documentation
- infrastructure resources
- virtual machines
- screenshots
- networking references
- folder organization
- future infrastructure labs

---

# Documentation Standards

## Numbered Lab Structure

Infrastructure labs are organized using numbered prefixes.

Example:

```text
01-hardware-build.md
02-ubuntu-server-install.md
03-remote-access-and-ssh.md
```

This structure:

- preserves chronological deployment order
- documents infrastructure evolution
- improves repository readability
- prevents organizational drift

Numbering reflects implementation sequence rather than importance.

---

## Lab Documentation Structure

All major labs should follow a consistent structure.

Standard sections include:

1. Overview or Objective
2. Context and Architectural Reasoning
3. Technologies Used
4. Topology or Architecture
5. Deployment or Build Steps
6. Validation
7. Troubleshooting or Operational Adjustments
8. Security Considerations
9. Outcome
10. Lessons Learned

Not every lab requires every section, but structure should remain broadly consistent.

---

## Planned vs Implemented Infrastructure

The repository distinguishes between:

- implemented infrastructure
- planned infrastructure

### Implemented

Infrastructure is considered implemented only when:

- deployed successfully
- validated operationally
- documented with screenshots or command output
- reproducible through documented workflows

### Planned

Infrastructure is considered planned when:

- architecture or research exists
- deployment has not yet occurred
- validation has not yet been completed

Planned infrastructure should remain clearly labeled to avoid overstating operational capabilities.

---

# Infrastructure Naming Standards

## VM Naming

Virtual machine names should remain:

- short
- descriptive
- role-oriented
- scalable

Examples:

```text
DC01
WIN11-CLIENT01
UBUNTU-UTILITY01
WAZUH01
```

Naming convention:

- role identifier
- optional platform reference
- numeric suffix

---

## Hostname Naming

Infrastructure hostnames should match their operational role whenever possible.

Examples:

```text
dc01
grafana
prometheus
portainer
ubuntu-server
```

Container names should remain readable and operationally descriptive.

---

## Docker Network Naming

Docker networks should describe their operational role.

Examples:

```text
monitoring
proxy
lab-network
```

Avoid random or temporary naming for persistent infrastructure.

---

# Screenshot Standards

## Screenshot Naming

Screenshots should:

- use numbered ordering
- describe the operational action being shown
- remain human readable

Examples:

```text
01-making-project-directories.jpeg
02-creating-docker-compose-file.jpeg
03-validating-running-containers.jpeg
```

This structure improves:

- documentation readability
- image organization
- future maintenance

---

# Folder Organization Standards

## Infrastructure Separation

Infrastructure should remain logically separated by operational domain.

Example:

```text
linux-infrastructure/
enterprise-infrastructure/
automation-and-scripting/
cloud-and-hybrid-identity/
network-infrastructure/
architecture/
```

This separation reflects:

- infrastructure scope boundaries
- operational domains
- implementation phases

---

# Infrastructure Phase Organization

The repository is organized into separate infrastructure phases that reflect the evolution of the environment over time.

Current and planned phases include:

```text
linux-infrastructure/       (completed)
enterprise-infrastructure/  (completed)
automation-and-scripting/   (planned)
cloud-and-hybrid-identity/  (planned)
network-infrastructure/     (planned)
architecture/
```

## Linux Infrastructure Track

The Linux infrastructure track focuses on:

- Ubuntu Server administration
- Docker-based infrastructure
- monitoring and observability
- container networking
- reverse proxy architecture
- remote administration
- infrastructure foundations

This phase represents the operational base environment of the homelab.

Associated directories include:

```text
docs/linux-infrastructure/
images/linux-infrastructure/
infrastructure/linux-infrastructure/
```

---

## Enterprise Infrastructure Track

The enterprise infrastructure track focuses on:

- virtualization
- Windows Server administration
- Active Directory
- Group Policy
- centralized authentication
- cross-platform identity integration
- security monitoring

This phase builds on top of the Linux infrastructure foundation while remaining operationally separated.

Associated directories include:

```text
docs/enterprise-infrastructure/
images/enterprise-infrastructure/
infrastructure/enterprise-infrastructure/
```

---

## Infrastructure Automation and Scripting Track

The infrastructure automation and scripting track focuses on:

- PowerShell scripting against the existing Active Directory environment
- user and group provisioning automation
- GPO reporting and administration workflows
- scheduled maintenance task automation
- log parsing and operational scripting

This phase deepens the operational value of existing infrastructure without requiring new hardware or topology changes.

Associated directories include:

```text
docs/automation-and-scripting/
images/automation-and-scripting/
infrastructure/automation-and-scripting/
```

---

## Cloud and Hybrid Identity Track

The cloud and hybrid identity track focuses on:

- Microsoft Entra ID and Entra Connect configuration
- hybrid identity integration between on-premises AD and Azure
- Entra ID user and group management
- Microsoft 365 administration workflows
- cloud identity architecture

This phase extends the on-premises identity foundation established in the enterprise infrastructure track into a hybrid architecture.

Associated directories include:

```text
docs/cloud-and-hybrid-identity/
images/cloud-and-hybrid-identity/
infrastructure/cloud-and-hybrid-identity/
```

---

## Network Infrastructure Track

The network infrastructure track focuses on:

- perimeter firewall deployment and management
- VLAN design and segmentation
- inter-VLAN routing and access control policy
- firewall rule documentation
- network-layer intrusion detection integrated with the existing Wazuh SIEM deployment
- self-hosted VPN infrastructure

This phase introduces network segmentation and perimeter enforcement across the full environment.

Associated directories include:

```text
docs/network-infrastructure/
images/network-infrastructure/
infrastructure/network-infrastructure/
```

---

## Architecture Documentation

Architecture documentation exists separately from implementation-focused lab documentation.

Architecture documentation includes:

- topology documentation
- naming and operational standards
- architecture decision records
- recovery planning
- long-term infrastructure planning

Associated directory:

```text
docs/architecture/
```

Related documentation templates are maintained in:

```text
docs/templates/
```

This separation helps preserve:

- clear infrastructure boundaries
- implementation sequencing
- documentation scalability
- long-term maintainability

## Architecture Documentation Standards

Architecture documentation should focus on:

- infrastructure-wide decisions
- topology relationships
- operational boundaries
- long-term design evolution
- infrastructure planning and scope separation

### Architecture Decision Record Standards

Architecture Decision Records (ADRs) document major infrastructure and architectural decisions that materially influence the direction of the environment.

ADR naming should follow sequential numbering:

```text
001-example-decision.md
002-example-decision.md
```

ADR numbering reflects implementation chronology rather than importance.

---

# Documentation Philosophy

This repository follows a documentation-first workflow.

Infrastructure changes should prioritize:

- operational reasoning
- architecture evolution
- validation workflows
- troubleshooting visibility
- reproducibility
- incremental implementation

The goal is not only to deploy infrastructure, but to document:

- why decisions were made
- how systems interact
- how the environment evolved over time

This mirrors operational documentation practices commonly used in infrastructure and systems administration environments.

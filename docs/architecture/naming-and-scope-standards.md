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

Lab documents follow the structure defined in the [lab template](../templates/lab-template.md), which is the authoritative list of sections and the order they appear in. It is kept in one place rather than restated here, so that the two cannot drift apart.

Structure is a floor rather than a cage, and the reason is worth stating plainly. As the project has grown across tracks, it has become clear that different kinds of work need genuinely different things from their documentation. An infrastructure build lab earns its keep on deployment steps and topology. A scripting lab needs somewhere to record static analysis and test results that a build lab has no use for. An administration lab conducted almost entirely in web consoles produces findings, contradictions between vendor documentation and observed behavior, and readings taken against dated entitlements, none of which fit a section list written for building servers.

So a lab carries the sections its own work calls for, in the template's order, and omits the ones that would stand empty. A lab that needs something the template does not have should add a section rather than distorting an existing one to hold it, and where the same addition recurs across labs it belongs in the template.

What does not flex is naming. A section that is present uses the template's exact heading, unmodified, so that the same kind of content is always findable in the same place regardless of which track produced it. Flexibility is in which sections a lab carries, never in what they are called.

---

## Revising a Completed Lab

A change to a lab that is already complete is appended as a new section at the end of that document, in past tense, rather than written into the original narrative.

The original text is the record of what the lab found when it ran, and rewriting it destroys the thing the document exists to preserve. An appended section states what changed and why, and the original paragraphs stand as written even where a later lab proved them wrong.

Where a correction belongs beside a specific claim rather than at the end of the document, it is placed there and dated, and the original claim is left standing with a note explaining why it did not hold. A claim that was hedged when it was written is a particularly good candidate for this, since the hedge is what a later reading is supposed to be able to land on.

This rule protects findings and claims, not formatting. Correcting a broken link, a wrong file path, or a typo is maintenance and is made in place. The test is whether the edit changes what the lab is understood to have found: if it does, it is appended and dated; if it does not, it is simply fixed.

Two labs established this pattern and show what it looks like in practice: [04 - Docker Setup](../linux-infrastructure/04-docker-setup.md) under "Later Infrastructure Changes," and [01 - User Lifecycle Automation](../automation-and-scripting/01-user-lifecycle-automation.md) under "Later Revision."

---

## Commit Messages

Commits use a single-line subject with no body:

```text
docs(cloud-03): document Step Ten - group deletion blocked by an active license
docs(automation-02): add planning and research
fix(cloud-02): restore unredacted Wazuh dashboard screenshot
```

The scope names the track in short form, `linux`, `enterprise-infrastructure`, `automation`, `cloud`, `monitoring-stack`, followed by the lab number where the commit belongs to a single lab. A change spanning a whole track drops the number.

The type is `docs` for documentation work, which is most of this repository, `fix` for correcting something already pushed, `feat` for new infrastructure or capability, and `chore` for maintenance that changes no documented behavior.

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

## Organizational Unit Organization

Organizational units are organized by operational role by default. An OU groups objects by what they are and what they are for, and its name says so.

Examples:

```text
OU=IT
OU=User Accounts
OU=Workstations
OU=Groups
OU=Service Accounts
```

Protection level is a deliberate exception to that default, taken only where an object's exposure rather than its function determines where it belongs. `OU=Protected Objects`, added in Lab 02 of the Cloud and Hybrid Identity track, is the first of these. It holds `AZUREADSSOACC`, the computer account seamless single sign-on shares a Kerberos decryption key with, which Microsoft's guidance says only Domain Admins should be able to manage and which should be safe from accidental deletion. An OU sized for ordinary domain-joined machines does not provide that, so the OU was created directly under the domain root with inheritance disabled and Full control reduced to Domain Admins, Enterprise Admins, Administrators, and SYSTEM. The `redircmp` redirect was left untouched; new computer objects still land in `OU=Workstations`.

An OU created on that basis is named for what it protects, not with a tier or sensitivity label. The exception is not a licence to organize by sensitivity generally: an object belongs in a protection-level OU only when the role-based OU it would otherwise sit in cannot give it the administrative boundary it needs.

---

## Service Account Naming

Accounts that exist for a service or an integration rather than for a person are prefixed `svc-` and named for what they serve, not for the product version or the lab that created them.

Examples:

```text
svc-entraconnect
```

Service accounts live in `OU=Service Accounts` rather than in the redirected default new-user location, so that placement is a deliberate act and so that they can be excluded from scoping decisions, such as directory synchronization, that apply to ordinary user OUs. They are granted the specific rights their service needs and nothing more, and they are not members of administrative groups by default.

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

- use numbered ordering, contiguous from `01`, in the order the document references them
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

Images live in `images/<track>/<lab>/`, one folder per lab, named for the lab document the images belong to. An image that has been superseded is deleted rather than left beside its replacement, so that the folder and the document always hold the same set.

---

## Screenshot Captions

Every image carries a caption describing what is visible in that frame.

A caption states what the frame actually shows and stops there. A caption that claims content the image does not contain is a defect, and it is not one any text search will find: checking it means opening the image and reading it against its own caption. Numbering, filenames, and counts can all be correct while a caption describes the wrong screen.

Where a value is masked in an image, the caption must not name that value. Masking an identifier in the frame and then writing it out in the caption underneath defeats the masking entirely.

This convention settled after the enterprise infrastructure track was already underway. [01 - Virtualization Lab](../enterprise-infrastructure/01-virtualization-lab.md) and [02 - Windows Server Lab](../enterprise-infrastructure/02-windows-server-lab.md) predate it and carry their images without captions, describing each one in the surrounding prose instead. They are left as written rather than retrofitted, on the same reasoning that governs any change to a completed lab. Every lab from [03 - Active Directory Lab](../enterprise-infrastructure/03-active-directory-lab.md) onward follows the convention above.

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
automation-and-scripting/   (completed)
cloud-and-hybrid-identity/  (in progress)
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
- static analysis and automated testing of the script library

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
- hybrid identity integration between on-premises AD and Microsoft Entra ID
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

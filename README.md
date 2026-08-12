# Home Lab Infrastructure Project

A documentation-first homelab portfolio spanning Linux infrastructure, Windows enterprise infrastructure, and PowerShell automation, built, validated, and documented as a single evolving environment rather than a set of disconnected tutorials.

**What this demonstrates:** end-to-end systems administration across Linux and Windows, centralized identity with Active Directory, cross-platform authentication, security monitoring, and repeatable PowerShell automation, with every significant decision recorded as an architecture decision record and every deployment documented through a plan, validation, and lessons-learned lifecycle.

**Core stack:** Ubuntu Server, Docker, NGINX Proxy Manager, Prometheus, Grafana, Tailscale, Windows Server 2022, Active Directory, AD-integrated DNS, Group Policy, PowerShell (RSAT), SSSD and Kerberos, Wazuh SIEM.

**Current focus:** Infrastructure Automation and Scripting track, PowerShell against the live `corp.home.arpa` domain. The Linux and Enterprise Infrastructure tracks are complete; Automation Labs 01 and 02 are complete, with Lab 03 in planning.

New here? Skim the [Current Environment](#current-environment) for what is running, or the [architecture decision records](docs/architecture/decisions/) for the reasoning behind it.

---

## Overview

This repository documents the design, deployment, administration, and ongoing development of a hybrid homelab environment spanning Linux infrastructure, containerized services, and Windows enterprise infrastructure.

The project is organized into five tracks:

- **Linux Infrastructure** - Ubuntu Server, Docker, reverse proxy, monitoring, and remote administration
- **Enterprise Infrastructure** - Virtualization, Windows Server, Active Directory, Group Policy, cross-platform integration, and security monitoring
- **Infrastructure Automation and Scripting** - PowerShell automation against the existing Active Directory environment *(in progress)*
- **Cloud and Hybrid Identity** - Entra ID, Microsoft Entra Connect, and hybrid identity architecture *(planned)*
- **Network Infrastructure** - Perimeter firewall, VLAN segmentation, access control policy, and network-layer security *(planned)*

The Linux and enterprise infrastructure tracks are completed and fully documented. The infrastructure automation and scripting track is in progress, with Lab 01 (User Lifecycle Automation) and Lab 02 (Group and OU Administration) complete. The remaining two tracks are planned and will be implemented sequentially as documented in [ADR-014](docs/architecture/decisions/014-establish-long-term-infrastructure-expansion-roadmap.md).

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
- security monitoring and event collection
- infrastructure automation and scripting
- cloud and hybrid identity integration
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
- Wazuh SIEM stack (Manager, Indexer, Dashboard)

### Enterprise Infrastructure

- VMware Workstation Pro (hosted on Windows 11 workstation)
- DC01: Windows Server 2022 Standard Evaluation, static IP `192.168.1.10`, Active Directory Domain Services deployed, AD-integrated DNS operational, RDP enabled
- WIN11-CLIENT01: Windows 11 Enterprise Evaluation, static IP `192.168.1.20`, RSAT installed, domain-joined enterprise workstation, computer account in `OU=Workstations`
- Both VMs on bridged networking with direct LAN presence
- Active Directory Domain Services deployed: domain `corp.home.arpa` operational, DC01 promoted to domain controller, AD-integrated DNS active, OU structure created, domain user and group accounts created, post-promotion snapshots taken
- WIN11-CLIENT01 joined to `corp.home.arpa`: computer account confirmed in `OU=Workstations`, domain authentication validated, Kerberos TGT confirmed, secure channel verified, Group Policy processing validated
- Group Policy deployed: three purpose-built GPOs created, linked, and validated; security group filtering operational on `Workstation-Security-Baseline` using `Lab-Workstations`; RSoP confirmed on WIN11-CLIENT01 and DC01
- Ubuntu Server joined to `corp.home.arpa`: SSSD and Kerberos configured, identity resolution operational, access restricted to `Linux-Admins` group, SSH authentication validated for permitted and denied users, AD-side computer account and group membership confirmed
- Wazuh SIEM deployed: Manager, Indexer, and Dashboard running as Docker Compose stack on Ubuntu Server; agents enrolled on DC01, WIN11-CLIENT01, and Ubuntu Server; Windows Security and Linux authentication event collection validated

The Windows 11 workstation serves as the primary management endpoint and virtualization host for enterprise labs.

### Infrastructure Automation and Scripting

- `New-LabUser.ps1` and `Remove-LabUser.ps1`: PowerShell scripts run from WIN11-CLIENT01 via RSAT, provisioning and offboarding Active Directory users end to end, including optional `Linux-Admins` access validated over SSH against Ubuntu Server
- both scripts self-validate by querying Active Directory back after execution rather than trusting cmdlet exit codes
- cross-platform identity chain (AD → SSSD → PAM → SSH) proven in both directions against a live test account (`jdoe`)
- `Add-LabGroupMembers.ps1`, `Get-LabOUReport.ps1`, and `Get-LabAccountInventory.ps1`: PowerShell scripts run from WIN11-CLIENT01, covering CSV-driven bulk group membership with a partial-success batch model, per-OU user/computer census reporting, and full account inventory reporting with resolved group memberships
- every script's reported result independently cross-checked against a standalone Active Directory query, not just trusted on its own self-validation

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
- security monitoring and SIEM deployment

### Infrastructure Automation and Scripting Track *(in progress)*

The infrastructure automation and scripting track focuses on:
- PowerShell scripting against the existing Active Directory environment
- user and group provisioning automation
- GPO reporting and administration workflows
- scheduled maintenance task automation
- log parsing and operational scripting
- static analysis and automated testing of the script library

### Cloud and Hybrid Identity Track *(planned)*

The cloud and hybrid identity track focuses on:
- Microsoft Entra ID and Entra Connect configuration
- hybrid identity integration between on-premises AD and Azure
- Entra ID user and group management
- Microsoft 365 administration workflows
- cloud identity architecture

### Network Infrastructure Track *(planned)*

The network infrastructure track focuses on:
- perimeter firewall deployment and management
- VLAN design and segmentation
- inter-VLAN routing and access control policy
- firewall rule documentation
- network-layer intrusion detection integrated with the existing Wazuh SIEM deployment
- self-hosted VPN infrastructure

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
| [05 - Group Policy Lab](docs/enterprise-infrastructure/05-group-policy-lab.md) | GPO design and deployment, OU-based computer and user policy targeting, security group filtering, gpresult and RSoP validation, and post-GPO snapshots |
| [06 - Linux and AD Integration Lab](docs/enterprise-infrastructure/06-linux-ad-integration-lab.md) | Cross-platform identity integration using realmd, SSSD, Kerberos, and centralized authentication; Linux-Admins group-based access control; SSH authentication and denial validation |
| [07 - Security and Monitoring Lab](docs/enterprise-infrastructure/07-security-monitoring-lab.md) | Wazuh SIEM deployment as a Docker Compose stack; agent enrollment on DC01, WIN11-CLIENT01, and Ubuntu Server; Windows Security and Linux authentication event collection validated |

### Infrastructure Automation and Scripting

#### Completed Labs

| Lab | Focus Area |
|---|---|
| [01 - User Lifecycle Automation](docs/automation-and-scripting/01-user-lifecycle-automation.md) | `New-LabUser.ps1` and `Remove-LabUser.ps1`: scripted AD user provisioning and offboarding with OU placement, group assignment, self-validation, and cross-platform SSH access validation on Ubuntu Server |
| [02 - Group and OU Administration](docs/automation-and-scripting/02-group-and-ou-administration.md) | `Add-LabGroupMembers.ps1`, `Get-LabOUReport.ps1`, and `Get-LabAccountInventory.ps1`: CSV-driven bulk group membership with a partial-success batch model, per-OU user/computer census reporting, and full account inventory reporting, each independently cross-checked against standalone AD queries |

#### Planned Labs

See the [Automation and Scripting Track README](docs/automation-and-scripting/README.md) for the full lab sequence (Static Analysis and Unit Testing, Group Policy Reporting and Audit, Cross-Platform Validation, Scheduled Health Reporting).

---

## Repository Structure

```text
home-lab/
├── docs/
│   ├── linux-infrastructure/
│   ├── enterprise-infrastructure/
│   ├── automation-and-scripting/
│   ├── cloud-and-hybrid-identity/
│   ├── network-infrastructure/
│   ├── architecture/
│   └── templates/
│
├── images/
│   ├── linux-infrastructure/
│   ├── enterprise-infrastructure/
│   └── automation-and-scripting/
│
├── infrastructure/
│   ├── linux-infrastructure/
│   ├── enterprise-infrastructure/
│   └── automation-and-scripting/
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
- `Workstation-Security-Baseline` GPO created and linked to `OU=Workstations`; User Configuration disabled; inactivity limit, Windows Firewall domain profile, and audit policies configured
- `Standard-User-Environment` GPO created and linked to `OU=User Accounts`; Computer Configuration disabled; Control Panel, Run, display, and LAN restrictions configured
- `IT-Admin-Environment` GPO created and linked to `OU=IT`; Computer Configuration disabled; desktop wallpaper policy configured
- GPO application validated via `gpupdate /force` and `gpresult /r` in both `testuser01` and `labadmin` sessions
- functional restrictions confirmed for `testuser01`; wallpaper policy confirmed applied for `labadmin` via RSoP
- Windows Firewall domain profile confirmed active on WIN11-CLIENT01
- `WIN11-CLIENT01$` added to `Lab-Workstations`; security filtering on `Workstation-Security-Baseline` switched from `Authenticated Users` to `Lab-Workstations`; GPO confirmed still applied after `gpupdate /force`
- RSoP validated with no denied GPOs and security filtering reflected correctly
- post-GPO snapshots created: `DC01 - Group Policy Deployed`, `WIN11-CLIENT01 - Group Policy Applied`
- `Linux-Admins` security group created in `OU=Groups`; `labadmin` added as member
- Ubuntu Server hostname standardized to `ubuntu-server`; DNS corrected to use DC01 (`192.168.1.10`) via Netplan; Kerberos SRV records confirmed resolvable
- Ubuntu Server joined to `corp.home.arpa` using `realm join`; `UBUNTU-SERVER` computer account confirmed in `OU=Workstations`
- SSSD configured with `access_provider = simple` and `simple_allow_groups = Linux-Admins@corp.home.arpa`
- `pam-auth-update` run to enable `pam_mkhomedir` for automatic home directory creation
- AD user identity resolution confirmed via `id` and `getent` for both `labadmin` and `testuser01`
- Kerberos TGT acquired for `labadmin` via `kinit`; ticket confirmed via `klist`
- `labadmin` SSH session established with AD credentials; home directory created on first login; Kerberos ticket present in session
- `testuser01` SSH session denied at PAM authorization step; Kerberos authentication succeeded but authorization failed due to absent `Linux-Admins` membership
- AD-side validation confirmed from DC01: computer account, group membership, `labadmin` member status, and `testuser01` non-member status confirmed via PowerShell and ADUC
- post-integration snapshots created: `DC01 - Linux AD Integration Complete`, `WIN11-CLIENT01 - Linux AD Integration Validated`
- Wazuh single-node stack (Manager, Indexer, Dashboard) deployed as Docker Compose on Ubuntu Server at `v4.14.5`
- SSL certificates generated via `wazuh-certs-generator` container; dashboard host port remapped to `8443`
- stack health validated: all three containers confirmed running, indexer accepting connections, dashboard accessible and error-free
- DC01 enrolled as Wazuh Windows agent; WIN11-CLIENT01 enrolled as Wazuh Windows agent; Ubuntu Server enrolled as Wazuh Linux agent; all three confirmed Active in dashboard
- Windows Security event collection validated on DC01 and WIN11-CLIENT01 via intentional failed logon events
- Linux authentication event collection validated on Ubuntu Server via failed SSH attempt
- default Wazuh credentials documented; passwords changed after lab completion

### Infrastructure Automation and Scripting Track

Completed:

- `New-LabUser.ps1` authored and run from WIN11-CLIENT01: pre-flight duplicate check, AD account creation, OU placement, role group assignment, optional `Linux-Admins` membership, and four-point self-validation querying AD back after creation
- `Remove-LabUser.ps1` authored and run from WIN11-CLIENT01: pre-flight existence check, account disablement, removal of removable group memberships while preserving the primary group and account object, and three-point self-validation
- both scripts run end to end against a live test account (`jdoe`): provisioned with Linux access, SSH access confirmed via an authenticated session with a valid Kerberos ticket, offboarded, and SSH access confirmed denied afterward
- cross-platform identity chain (AD group membership → SSSD resolution → PAM authorization → SSH) validated in both directions against a real account
- SSSD cache behavior documented: a negative-cache entry for a never-resolved new account required a full `systemctl restart sssd` rather than `sss_cache -u`; post-offboarding cache updates were observed to apply per-attribute rather than atomically per-account
- [ADR-016](docs/architecture/decisions/016-run-automation-scripts-from-domain-joined-client.md) established WIN11-CLIENT01, not DC01, as the standing execution endpoint for all scripts in this track
- `Add-LabGroupMembers.ps1` authored and run from WIN11-CLIENT01: CSV-driven bulk group membership additions grouped by target group, per-member pre-validation before `Add-ADGroupMember` is called (confirmed via live diagnostic that the cmdlet validates its `-Members` array atomically), and a partial-success batch model proven with a real negative test (an invalid account excluded and reported while a valid account in the same batch still succeeded)
- `Get-LabOUReport.ps1` authored and run from WIN11-CLIENT01: per-OU user and computer census using `-SearchScope OneLevel`, correctly enumerating all 5 OUs in the domain including the built-in `Domain Controllers` OU, with console output and optional `-ExportPath` CSV export confirmed to match exactly
- `Get-LabAccountInventory.ps1` authored and run from WIN11-CLIENT01: full domain account inventory with resolved group memberships, reusing `Remove-LabUser.ps1`'s primary-group exclusion pattern, blank `LastLogonDate` values preserved rather than substituted, and console output and optional `-ExportPath` CSV export confirmed to match exactly
- every script's reported result independently cross-checked against a standalone AD query run outside of any script (`Get-ADGroupMember`, `Get-ADUser`/`Get-ADComputer`, `Get-ADPrincipalGroupMembership`), rather than relying solely on each script's own internal self-validation

---

## Long-Term Direction

The long-term objective is to build practical real-world experience that reflects the operational complexity of modern IT environments where:

- Linux and Windows systems coexist
- identity is centralized and extended to the cloud
- infrastructure is observable and monitored centrally
- services are segmented through layered networking
- security is integrated throughout the environment
- administrative workflows are automated and repeatable
- operational changes are documented and validated incrementally

The planned track sequence (Infrastructure Automation and Scripting, Cloud and Hybrid Identity, Network Infrastructure) is documented in [ADR-014](docs/architecture/decisions/014-establish-long-term-infrastructure-expansion-roadmap.md).

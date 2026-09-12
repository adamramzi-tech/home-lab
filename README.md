# Home Lab Infrastructure Project

A documentation-first homelab portfolio spanning Linux infrastructure, Windows enterprise infrastructure, and PowerShell automation, built, validated, and documented as a single evolving environment rather than a set of disconnected tutorials.

**What this demonstrates:** end-to-end systems administration across Linux and Windows, centralized identity with Active Directory, cross-platform authentication, security monitoring, and repeatable PowerShell automation, with every significant decision recorded as an architecture decision record and every deployment documented through a plan, validation, and lessons-learned lifecycle.

**Core stack:** Ubuntu Server, Docker, NGINX Proxy Manager, Prometheus, Grafana, Tailscale, Windows Server 2022, Active Directory, AD-integrated DNS, Group Policy, PowerShell (RSAT), SSSD and Kerberos, Wazuh SIEM, Microsoft Entra ID.

**Current status:** The Linux Infrastructure, Enterprise Infrastructure, and Infrastructure Automation and Scripting tracks are all complete. The automation track closed with Lab 05 (Scheduled Health Reporting), leaving a thirteen-script PowerShell library against the live `corp.home.arpa` domain and a Task Scheduler job that reports the environment's health unattended. Cloud and Hybrid Identity is the current track, established by [ADR-019](docs/architecture/decisions/019-establish-cloud-and-hybrid-identity-track.md). Lab 01 (Tenant Foundation and Custom Domain) is complete: a Microsoft Entra tenant exists with `brindeck.com` verified as its primary domain, a cloud-only Global Administrator, and a tested emergency access account. Lab 02 (Hybrid Identity with Entra Connect) is complete: `SYNC01` is built and joined to the domain, Entra Connect Sync is installed and synchronizing an organizational-unit-scoped population into the tenant, a synchronized user has signed in to a cloud service with their on-premises password, seamless single sign-on is validated from WIN11-CLIENT01, and the synchronization cycle and a deliberately induced failure are documented as observed rather than as described. Lab 03 (Entra ID User, Group, and License Administration) is complete: the tenant holds Microsoft Entra ID P1 on a Business Premium trial with recurring billing off, its group population has grown from five to nine including the environment's first dynamic membership and role-assignable groups, licenses are assigned under both the per-user and group-based models, and what can and cannot be edited on a synchronized object is established per field against the live directory rather than from documentation.

New here? Skim the [Current Environment](#current-environment) for what is running, or the [architecture decision records](docs/architecture/decisions/) for the reasoning behind it.

---

## Overview

This repository documents the design, deployment, administration, and ongoing development of a hybrid homelab environment spanning Linux infrastructure, containerized services, and Windows enterprise infrastructure.

The project is organized into five tracks:

- **Linux Infrastructure** - Ubuntu Server, Docker, reverse proxy, monitoring, and remote administration
- **Enterprise Infrastructure** - Virtualization, Windows Server, Active Directory, Group Policy, cross-platform integration, and security monitoring
- **Infrastructure Automation and Scripting** - PowerShell automation against the existing Active Directory environment
- **Cloud and Hybrid Identity** - Entra ID, Microsoft Entra Connect, and hybrid identity architecture *(in progress)*
- **Network Infrastructure** - Perimeter firewall, VLAN segmentation, access control policy, and network-layer security *(planned)*

The Linux, enterprise infrastructure, and infrastructure automation and scripting tracks are completed and fully documented. The automation track ran to five labs: Lab 01 (User Lifecycle Automation), Lab 02 (Group and OU Administration), Lab 03 (Static Analysis and Unit Testing), Lab 04 (Group Policy Reporting and Audit), and Lab 05 (Scheduled Health Reporting), which closed the track per [ADR-018](docs/architecture/decisions/018-retire-cross-platform-validation-lab.md). Cloud and Hybrid Identity is underway, established by [ADR-019](docs/architecture/decisions/019-establish-cloud-and-hybrid-identity-track.md), which defines its scope, design decisions, and boundaries. Its first three labs are complete, taking the track from tenant creation through directory synchronization to operating the resulting hybrid environment. Network Infrastructure remains planned and will follow, as documented in [ADR-014](docs/architecture/decisions/014-establish-long-term-infrastructure-expansion-roadmap.md).

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
- SYNC01: Windows Server 2022 Standard Evaluation, static IP `192.168.1.30`, domain-joined member server, computer account in `OU=Workstations`, hosting Microsoft Entra Connect Sync (Cloud and Hybrid Identity track, Lab 02)
- All three VMs on bridged networking with direct LAN presence
- Active Directory Domain Services deployed: domain `corp.home.arpa` operational, DC01 promoted to domain controller, AD-integrated DNS active, OU structure created, domain user and group accounts created, post-promotion snapshots taken
- WIN11-CLIENT01 joined to `corp.home.arpa`: computer account confirmed in `OU=Workstations`, domain authentication validated, Kerberos TGT confirmed, secure channel verified, Group Policy processing validated
- Group Policy deployed: three purpose-built GPOs created, linked, and validated; security group filtering operational on `Workstation-Security-Baseline` using `Lab-Workstations`; RSoP confirmed on WIN11-CLIENT01 and DC01
- Ubuntu Server joined to `corp.home.arpa`: SSSD and Kerberos configured, identity resolution operational, access restricted to `Linux-Admins` group, SSH authentication validated for permitted and denied users, AD-side computer account and group membership confirmed
- Wazuh SIEM deployed: Manager, Indexer, and Dashboard running as Docker Compose stack on Ubuntu Server; agents enrolled on DC01, WIN11-CLIENT01, Ubuntu Server, and SYNC01; Windows Security and Linux authentication event collection validated

The Windows 11 workstation serves as the primary management endpoint and virtualization host for enterprise labs.

### Infrastructure Automation and Scripting

- `New-LabUser.ps1` and `Remove-LabUser.ps1`: PowerShell scripts run from WIN11-CLIENT01 via RSAT, provisioning and offboarding Active Directory users end to end, including optional `Linux-Admins` access validated over SSH against Ubuntu Server
- both scripts self-validate by querying Active Directory back after execution rather than trusting cmdlet exit codes
- cross-platform identity chain (AD → SSSD → PAM → SSH) proven in both directions against a live test account (`jdoe`)
- `Add-LabGroupMembers.ps1`, `Get-LabOUReport.ps1`, and `Get-LabAccountInventory.ps1`: PowerShell scripts run from WIN11-CLIENT01, covering CSV-driven bulk group membership with a partial-success batch model, per-OU user/computer census reporting, and full account inventory reporting with resolved group memberships
- `Get-LabGPOInventory.ps1`, `Get-LabGPOLinkReport.ps1`, and `Get-LabRSoPReport.ps1`: read-only Group Policy reporting run from WIN11-CLIENT01, covering GPO inventory, per-OU link and inheritance state, and Resultant Set of Policy for a named user and computer
- `Get-LabADServiceHealth.ps1`, `Get-LabWazuhAgentStatus.ps1`, `Get-LabDockerServiceStatus.ps1`, and `Invoke-LabHealthReport.ps1`: an environment health report covering DC01's Active Directory service state, Wazuh agent enrollment across every enrolled system, and Docker container state on Ubuntu Server, each check classified `Healthy`/`Unhealthy`/`Unknown` and aggregated worst-wins
- a Task Scheduler job on WIN11-CLIENT01, registered by `Register-LabHealthReportTask.ps1`, runs that report daily at 07:00 as `labadmin` at `RunLevel Limited` and writes a timestamped report file on every firing; observed firing unattended with no one logged on
- every script's reported result independently cross-checked against a source outside the script that produced it, not just trusted on its own self-validation: standalone Active Directory queries for the directory-side scripts, and a direct DC01 service query, the Wazuh dashboard, and a raw `docker ps -a` on Ubuntu Server for the health checks
- the full thirteen-script library passes a documented PSScriptAnalyzer standard (`PSScriptAnalyzerSettings.psd1`) with zero findings, and carries 174 Pester unit tests against mocked Active Directory, Group Policy, Windows service, REST, and Task Scheduler calls, all runnable on WIN11-CLIENT01 without a live domain, a reachable API, or credentials; the suite stood at 172 when the track closed and gained two when Cloud Lab 02 changed `New-LabUser.ps1`

### Cloud and Hybrid Identity

- Microsoft Entra tenant `brindeck.onmicrosoft.com`, with `brindeck.com` registered through Cloudflare Registrar, verified by DNS TXT record, and set as the tenant's primary domain
- a cloud-only Global Administrator operating the tenant, and a separate emergency access account kept on the `onmicrosoft.com` domain with its password and a second, device-independent sign-in method stored offline, validated by a full cold sign-in rather than by registration alone
- multifactor authentication required for administrative sign-in through security defaults, which also block legacy authentication protocols and device code flow
- Microsoft Entra ID Premium P1, carried by a Microsoft 365 Business Premium thirty-day trial started inside the tenant with recurring billing disabled the same day, expiring 2026-10-05 and taking P1 with it; the earlier Microsoft 365 Business Basic trial lapses on 2026-09-22 rather than converting, and Microsoft Entra ID Free remains the tenant's non-assignable base plan underneath both
- `SYNC01`, a Windows Server 2022 member server joined to `corp.home.arpa` at `192.168.1.30`, running Microsoft Entra Connect Sync v2.6.84.0 installed with Custom settings, authenticating to the directory as `svc-entraconnect` in a purpose-built `OU=Service Accounts`
- `brindeck.com` added to Active Directory as an alternative user principal name suffix and applied to the users in `OU=User Accounts`, since `home.arpa` is reserved by RFC 8375 and cannot be verified in a tenant; `OU=IT` deliberately keeps the on-premises suffix
- one-way synchronization scoped to `OU=User Accounts` and `OU=Groups`, with `ms-DS-ConsistencyGuid` as the source anchor: the tenant holds ten users and one enterprise application registered by Entra Connect Sync's own installation, six of those users and four groups arriving along the synchronization boundary, and `labadmin` and the cloud-only administrative accounts remain outside the synchronized population by design
- password hash synchronization confirmed working end to end, with a synchronized user signing in to a Microsoft cloud service as `testuser01@brindeck.com` using their existing on-premises password
- seamless single sign-on enabled and validated from WIN11-CLIENT01: a password-free sign-in to `myapps.microsoft.com`, confirmed independently by a Kerberos service ticket for the autologon endpoint rather than inferred from the smooth sign-in alone
- `AZUREADSSOACC` held in `OU=Protected Objects`, a new organizational unit with inheritance disabled and Full control reduced to Domain Admins, Enterprise Admins, Administrators, and SYSTEM, with the account's Kerberos key rolled and its encryption type set explicitly to AES
- the synchronization scheduler observed rather than assumed: `SyncCycleEnabled` was found `False` since installation, corrected, and confirmed by three unattended Delta cycles landing roughly thirty minutes apart
- a deliberately induced user principal name collision quarantined by Duplicate Attribute Resiliency and diagnosed from the tenant's provisioning error record, the synchronization client reporting a clean export throughout
- nine groups in the tenant: the four synchronized from `OU=Groups`, which are read-only in the cloud behind a portal banner; the pre-existing cloud-only `All Company`; `Finance` and `Company Announcements`, the environment's first cloud-only security and Microsoft 365 groups, both carrying group-level license assignments and both consequently undeletable while those assignments stand; `IT-Department`, its first dynamic membership group, on `(user.department -eq "IT")`; and `Groups-Administrators`, its first role-assignable group, holding Groups Administrator at Directory scope with its membership type locked by the product
- `department` populated on all six synchronized users on-premises and `title` on `mjohnson`, the first organizational attributes this domain has carried, with a dynamic membership rule keyed to `department` evaluating across the synchronization boundary in roughly five minutes end to end
- licensing on both models: five accounts licensed directly, two cloud-only and three synchronized with no behavioral difference between them, and one account licensed purely through group membership, with `testuser01` holding License Administrator at Directory scope

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

### Infrastructure Automation and Scripting Track

The infrastructure automation and scripting track focuses on:
- PowerShell scripting against the existing Active Directory environment
- user and group provisioning automation
- GPO reporting and administration workflows
- scheduled maintenance task automation
- log parsing and operational scripting
- static analysis and automated testing of the script library

### Cloud and Hybrid Identity Track *(in progress)*

The cloud and hybrid identity track focuses on:
- Microsoft Entra tenant foundation, custom domain verification, and administrative role design
- hybrid identity between `corp.home.arpa` and Microsoft Entra ID through Entra Connect Sync
- Entra ID user, group, and license administration across synchronized and cloud-only objects
- Microsoft 365 administration workflows including Exchange Online mailboxes, shared mailboxes, and groups
- access control and device management: multifactor authentication, conditional access, self-service password reset with writeback to Active Directory, and device enrollment
- hybrid identity automation using the Microsoft Graph PowerShell SDK

Scope, design decisions, and boundaries are defined in [ADR-019](docs/architecture/decisions/019-establish-cloud-and-hybrid-identity-track.md). Planned labs, prerequisites, and success criteria are in the [track README](docs/cloud-and-hybrid-identity/README.md).

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
| [03 - Static Analysis and Unit Testing](docs/automation-and-scripting/03-static-analysis-and-unit-testing.md) | PSScriptAnalyzer static analysis and 49 Pester unit tests across the Lab 01 and Lab 02 script library, all mock-based and runnable without a live domain, complementing the earlier labs' live-environment validation |
| [04 - Group Policy Reporting and Audit](docs/automation-and-scripting/04-group-policy-reporting-and-audit.md) | `Get-LabGPOInventory.ps1`, `Get-LabGPOLinkReport.ps1`, and `Get-LabRSoPReport.ps1`: read-only GPO inventory, per-OU link and inheritance reporting, and Resultant Set of Policy reporting, with 21 Pester unit tests bringing the suite to 70, each report cross-checked against native Group Policy cmdlets and `gpresult` |
| [05 - Scheduled Health Reporting](docs/automation-and-scripting/05-scheduled-health-reporting.md) | `Get-LabADServiceHealth.ps1`, `Get-LabWazuhAgentStatus.ps1`, `Get-LabDockerServiceStatus.ps1`, `Invoke-LabHealthReport.ps1`, and `Register-LabHealthReportTask.ps1`: a three-state (`Healthy`/`Unhealthy`/`Unknown`) health report over DC01's AD services, Wazuh agent enrollment, and Docker container state, aggregated worst-wins and registered as an unattended Task Scheduler job, bringing the suite to 172 tests across thirteen scripts |

This track is complete. Per [ADR-018](docs/architecture/decisions/018-retire-cross-platform-validation-lab.md), Scheduled Health Reporting was its fifth and final lab.

### Cloud and Hybrid Identity

Planned labs, prerequisites, licensing constraints, and success criteria are documented in the [track README](docs/cloud-and-hybrid-identity/README.md).

| Phase | Status | Description |
|---|---|---|
| [01 - Tenant Foundation and Custom Domain](docs/cloud-and-hybrid-identity/01-tenant-foundation-and-custom-domain.md) | Complete | Microsoft Entra tenant creation, custom domain verification through DNS, a cloud-only Global Administrator and emergency access account, and multifactor authentication on administrative sign-in |
| [02 - Hybrid Identity with Entra Connect](docs/cloud-and-hybrid-identity/02-hybrid-identity-with-entra-connect.md) | Complete | `SYNC01` build and domain join, a routable user principal name suffix in Active Directory, Entra Connect Sync with organizational unit scoped synchronization and password hash synchronization, seamless single sign-on, and observed synchronization cycle and failure behavior |
| [03 - Entra ID User, Group, and License Administration](docs/cloud-and-hybrid-identity/03-entra-id-user-group-and-license-administration.md) | Complete | A Microsoft 365 Business Premium trial started inside the tenant for Microsoft Entra ID P1, what can and cannot be edited on a synchronized object compared with a cloud-only one, the tenant's group catalogue and its first dynamic membership and role-assignable groups, per-user and group-based license assignment, directory role assignment, and delete and restore across both user and group object types |

Remaining lab documents are added here as each is implemented.

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
│   ├── automation-and-scripting/
│   └── cloud-and-hybrid-identity/
│
├── infrastructure/
│   ├── linux-infrastructure/
│   ├── enterprise-infrastructure/
│   ├── automation-and-scripting/
│   └── cloud-and-hybrid-identity/
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
- PSScriptAnalyzer and Pester 5.6.1 adopted per [ADR-017](docs/architecture/decisions/017-adopt-powershell-static-analysis-and-unit-testing.md): `PSAvoidUsingWriteHost` deliberately excluded via `PSScriptAnalyzerSettings.psd1` with a written justification, every other default rule active
- 49 Pester unit tests authored across all five scripts (22 for the Lab 01 scripts, 27 for the Lab 02 scripts), every Active Directory cmdlet mocked so the suite runs on WIN11-CLIENT01 without a live domain or credentials
- a full-library `Invoke-ScriptAnalyzer` scan (including the test files, not just the production scripts) surfaced a real `PSAvoidUsingConvertToSecureStringWithPlainText` finding in `New-LabUser.Tests.ps1`, resolved by switching to an empty `[System.Security.SecureString]::new()`; the library passes a clean, zero-finding scan and the combined 49-test suite still passes in full
- `Get-LabGPOInventory.ps1`, `Get-LabGPOLinkReport.ps1`, and `Get-LabRSoPReport.ps1` authored and run from WIN11-CLIENT01: read-only GPO inventory, per-OU link and inheritance reporting, and Resultant Set of Policy reporting, each cross-checked against native Group Policy cmdlets and `gpresult`
- `Get-GPResultantSetOfPolicy` in logging mode confirmed by diagnostic to require both an elevated session and a prior (not necessarily current) interactive logon by the target user on the client
- 21 further Pester tests authored alongside the Lab 04 scripts rather than retrofitted, bringing the suite to 70
- [ADR-018](docs/architecture/decisions/018-retire-cross-platform-validation-lab.md) retired the planned standalone cross-platform validation lab as redundant with Lab 01, making Scheduled Health Reporting the track's fifth and final lab
- `Get-LabADServiceHealth.ps1`, `Get-LabWazuhAgentStatus.ps1`, and `Get-LabDockerServiceStatus.ps1` authored and run from WIN11-CLIENT01: DC01's `NTDS`, `DNS`, `Netlogon`, `Kdc`, `W32Time`, and `ADWS` service state via `Get-Service -ComputerName`, Wazuh agent enrollment via the Wazuh Manager REST API, and Docker container state via the Portainer REST API, with no new remoting technology introduced to reach Ubuntu Server
- each check classified `Healthy`, `Unhealthy`, or `Unknown`, so an unreachable host or API is reported as neither a false all-clear nor a false incident; `Unknown` earned that place three separate times rather than once at design time, twice as a live-only misclassification a fully passing Pester suite had not caught and once as the reason a least-privileged run-as account was rejected
- `Invoke-LabHealthReport.ps1` authored as the orchestrator: worst-wins aggregation across the three checks, a console table for interactive runs, and a timestamped report file written on every run
- least-privileged API accounts pursued on both platforms: a `labhealthcheck-wazuh` account under the built-in `agents_readonly` role succeeded; Portainer Community Edition was found to have no equivalent, since it hides existing resources from non-admin users by design, so the admin account stayed as a named, accepted exposure
- both API credentials stored as DPAPI-protected `Export-CliXml` files outside the repository and loaded non-interactively by the scheduled run, with no plaintext credential in any script, argument, or configuration file
- `Register-LabHealthReportTask.ps1` authored, the track's first state-changing script and first real `SupportsShouldProcess` implementation: registers the orchestrator as a daily 07:00 Task Scheduler job running as `labadmin` at `RunLevel Limited`, a documented compromise after a live probe proved a plain domain account cannot open the Service Control Manager on DC01
- the task observed firing unattended twice, once as a `StartWhenAvailable` catch-up after a real power outage and once as a genuine 07:00 time trigger with no one logged on, confirmed by `LastTaskResult 0` and operational-log event `107`
- a live `Unhealthy` report root-caused to a two-month-old monitoring-stack outage the report itself surfaced, remediated, and followed by a `Healthy` result from the next scheduled firing, demonstrating the classification discriminates a real fault from a clean environment
- the full combined library, all thirteen scripts and thirteen test files, swept together for the first time: a clean `Invoke-ScriptAnalyzer -Recurse` pass and 172 of 172 Pester tests, closing the track's final success criterion and the track itself

### Cloud and Hybrid Identity Track

Completed:

- Microsoft Entra tenant created through a Microsoft 365 Business Basic trial signup, with `brindeck.onmicrosoft.com` as its initial domain
- `brindeck.com` registered through Cloudflare Registrar, verified in the tenant by DNS TXT record, and set as the primary domain
- a cloud-only Global Administrator operating the tenant, and a separate emergency access account on the `onmicrosoft.com` domain validated by a full cold sign-in rather than by registration alone
- multifactor authentication required for administrative sign-in through security defaults, which also block legacy authentication protocols and device code flow
- `SYNC01` provisioned as a third virtual machine, static IP `192.168.1.30`, joined to `corp.home.arpa`, and enrolled as a Wazuh agent
- `brindeck.com` added as an alternative user principal name suffix in Active Directory and applied to the five users in `OU=User Accounts`, with `OU=IT` deliberately untouched
- `New-LabUser.ps1` changed to derive the user principal name suffix from the target OU rather than hardcoding `@corp.home.arpa`, with both branches covered by new Pester cases and proven live against a synchronized and a non-synchronized OU
- `OU=Service Accounts` created to hold `svc-entraconnect`, the AD DS connector account, outside the synchronization scope, rather than letting the installer place it wherever `redirusr` points
- Microsoft Entra Connect Sync v2.6.84.0 installed on `SYNC01` with Custom settings, password hash synchronization as the sign-in method, and `ms-DS-ConsistencyGuid` confirmed as the source anchor
- synchronization scoped to `OU=User Accounts` and `OU=Groups`, verified through Synchronization Service Manager after a Container Picker defect in that version forced a documented workaround
- first synchronization cycle completed cleanly across all six connector operations; the tenant went from three users and one group to nine users and five groups, all synchronized objects carrying `@brindeck.com` and `On-premises sync: Yes`
- password hash synchronization proven by a live sign-in as `testuser01@brindeck.com` using an existing on-premises password
- `IT-Admins` observed synchronizing with a partially invisible membership, the predicted consequence of organizational-unit filtering rather than a defect
- seamless single sign-on enabled and validated from WIN11-CLIENT01 by a password-free sign-in to `myapps.microsoft.com`, confirmed independently by a `klist` service ticket for `HTTP/autologon.microsoftazuread-sso.com` issued with AES-256
- `AZUREADSSOACC` moved into a new, delegation-restricted `OU=Protected Objects`, its delegation state confirmed clean from every angle available and its Kerberos key rolled with the encryption type set explicitly to AES128 and AES256
- `Seamless-SSO-Zone-Configuration` created and linked to `OU=User Accounts`, its effective values confirmed from the registry after `Standard-User-Environment`'s Control Panel restriction closed off the usual GUI check
- `SyncCycleEnabled` found `False` since installation, meaning nothing had synchronized unattended in the first week; corrected, then proven by three consecutive Delta cycles landing roughly thirty minutes apart with nothing forced
- a deliberate user principal name collision quarantined by Duplicate Attribute Resiliency, visible only in the tenant's provisioning error record while the synchronization client reported a successful export, after a first attempt reproduced UPN soft match instead
- DC01, WIN11-CLIENT01, Ubuntu Server, and all four Wazuh agents confirmed unchanged by the lab, with the automation library's health report clean and its full thirteen-script Pester suite passing 174 of 174
- a Microsoft 365 Business Premium thirty-day trial started from inside the existing tenant, accepted despite a Basic trial already having been consumed, with recurring billing turned off the same day and its Microsoft Entra ID P1, Exchange Online Plan 1, and Microsoft Intune Plan 1 service plans confirmed by name off the SKU rather than inferred from the tier name
- the Business Basic trial question the track deferred to Lab 04 resolved in both halves: the trial lapses on 2026-09-22 rather than converting, and what replaced it is a trial rather than a purchase
- what can and cannot be edited on a synchronized object established per field rather than per object: Job title and Mobile refused with an error naming on-premises mastered Directory Sync objects by category, while user principal name and account enabled state were both genuinely writable in the cloud, the first explained afterward by the tenant's own `SynchronizeUpnForManagedUsersEnabled` reading `True`
- the environment's first dynamic membership group, role-assignable group, and cloud-only security and Microsoft 365 groups, with `department` populated on all six synchronized users on-premises to give the dynamic rule a real attribute to key to
- license assignment documented on both models, with the collision between a direct assignment and a group assignment on the same user found by accident and then characterized: the direct component is permanently consumed while the group keeps supplying the license
- delete and restore exercised across both user object types and both cloud-only group types, settling Microsoft's own documentation contradiction in favor of its recoverability architecture guidance, and finding that a group carrying an active license assignment cannot be deleted at all
- two authoritative seat counts reconciled by enumeration rather than recomputation: the product page counts assignment targets and `Get-MgSubscribedSku` counts consumed seats, which differ by exactly one for every licensed group holding no members
- security defaults left enabled and untouched and no conditional access policy created, so the entitlement that makes conditional access available arrived without the obligation that comes with using it

Carrying forward:

- the Active Directory Recycle Bin, recommended by the Entra Connect installer but forest-wide and irreversible once enabled, left to the Enterprise Infrastructure track rather than applied mid-lab; Lab 03 produced a concrete cost for that decision when a recreated synchronized account arrived as an unrelated new cloud object under a new source anchor
- security defaults found to enforce multifactor authentication tenant-wide rather than for administrators only, to be scoped properly in Lab 05
- ten items opened by Lab 03 and held in the [track README](docs/cloud-and-hybrid-identity/README.md): three unresolved findings, two objects kept deliberately for later labs, and five defects or changes owed elsewhere, among them a stale Entra Connect scheduler after a `SYNC01` VM suspend and a Microsoft Graph gap where a group's own license assignment reads as empty while the platform enforces it on deletion
- two defects in the automation library, recorded in [that track's README](docs/automation-and-scripting/README.md): a stale Wazuh default agent list that leaves the scheduled health report never checking `SYNC01`, confirmed again by Lab 03, and a Portainer documentation mismatch

Closed rather than carried:

- `AZUREADSSOACC`'s Kerberos key rollover, opened by Lab 02 as a standing obligation of unknown severity, is answered. Microsoft's Quickstart, Technical Deep Dive, and FAQ all say "we highly recommend" rolling at least every thirty days, none describes the key as expiring, and Defender for Identity does not flag the account until ninety days. Thirty days is a hygiene interval rather than a deadline, so Lab 06 would be automating a good habit rather than meeting a clock. The key was deliberately not rolled at eleven days elapsed, leaving 2026-09-30 as an interval a later lab can watch elapse.

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

The planned track sequence (Infrastructure Automation and Scripting, Cloud and Hybrid Identity, Network Infrastructure) is documented in [ADR-014](docs/architecture/decisions/014-establish-long-term-infrastructure-expansion-roadmap.md). The first of those three is now complete. Cloud and Hybrid Identity is underway, established in detail by [ADR-019](docs/architecture/decisions/019-establish-cloud-and-hybrid-identity-track.md), with its tenant foundation built, directory synchronization operational, and the resulting hybrid environment now administered rather than only constructed as of Lab 03.

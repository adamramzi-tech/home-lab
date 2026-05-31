# 02 - Windows Server Lab 

## Status

Planning and research phase.

---

## Overview

This lab configures DC01 as a production-ready Windows Server environment and establishes the remote administration workflows that all subsequent enterprise infrastructure labs will depend on.

The lab picks up from the clean baseline snapshot created at the end of Lab 01, where DC01 was provisioned with Windows Server 2022 and VMware Tools was installed. At that point, the VM was functional but unconfigured — operating on VMware NAT networking, with a dynamically assigned IP address, a default hostname, and no remote administration capability.

This lab completes the foundational configuration required before Active Directory can be deployed:

- transitioning DC01 from NAT to bridged networking to establish LAN presence
- assigning a static IP address aligned with the planned addressing scheme
- renaming the server hostname to match infrastructure naming standards
- running Windows updates to establish a fully patched baseline
- enabling and validating RDP remote administration from the Windows 11 workstation
- installing RSAT on the management workstation
- performing baseline Server Manager familiarization
- creating a pre-AD snapshot as the rollback point for Lab 03

The networking transition is the most architecturally significant step in this lab. Moving DC01 onto bridged networking makes it a first-class participant on the local LAN, which is a prerequisite for Active Directory service discovery, Kerberos authentication, DNS resolution, and eventual hybrid integration with the Ubuntu Server environment.

---

## Objectives

- transition DC01 from VMware NAT networking to bridged networking
- assign DC01 a static IP address of `192.168.1.10`
- rename the server hostname to `DC01`
- apply Windows updates to establish a fully patched baseline
- enable RDP and validate remote administration from the Windows 11 workstation
- install RSAT on the management workstation
- validate Server Manager and core server management workflows
- create a pre-AD deployment snapshot

---

## Project Context

Lab 01 established the virtualization foundation for the enterprise infrastructure track. VMware Workstation was deployed on the Windows 11 workstation, and both DC01 and WIN11-CLIENT01 were provisioned with clean operating system installations and baseline snapshots.

However, both VMs were left in a deliberately minimal state — functional but not yet configured for enterprise infrastructure roles. This was intentional: the goal of Lab 01 was to validate the virtualization platform and establish clean rollback points before introducing configuration complexity.

This lab addresses the gap between a clean Windows Server installation and a server that is properly configured, remotely administrable, and ready to receive Active Directory services.

The networking transition from NAT to bridged networking is worth calling out specifically. During Lab 01, NAT networking was selected because it simplified the initial deployment and reduced risk during VM provisioning. At that stage, the VMs only needed outbound internet access for validation purposes, and exposing them directly onto the LAN was unnecessary.

By Lab 02, the requirements change. DC01 needs to be reachable from:

- the Windows 11 management workstation, for RDP administration
- WIN11-CLIENT01, for future domain join workflows
- the Ubuntu Server host, for future hybrid integration

All of these communication paths require DC01 to have a real LAN-routable address. Bridged networking provides exactly this by connecting the VM's virtual network adapter directly to the physical LAN as if it were an independent host.

This lab also introduces RSAT on the Windows 11 workstation. Remote Server Administration Tools provide the management utilities needed to administer Windows Server and Active Directory from a remote workstation rather than directly from the server console. Installing and validating RSAT here means Lab 03 can move directly into Active Directory deployment without needing to stop for tooling setup.

---

## Technologies Used

- VMware Workstation Pro
- Windows Server 2022 Standard Evaluation (Desktop Experience)
- VMware Bridged Networking
- Remote Desktop Protocol (RDP)
- Remote Server Administration Tools (RSAT)
- Windows Server Manager
- Windows PowerShell

---

## Architecture and Topology

After this lab, DC01 will be a fully configured Windows Server host with a static LAN presence.

```text
Windows 11 Workstation (192.168.1.x)
│
├── VMware Workstation
│   └── DC01 (192.168.1.10)
│       └── Windows Server 2022
│           ├── Static IP: 192.168.1.10
│           ├── Hostname: DC01
│           ├── RDP enabled
│           └── Ready for Active Directory deployment
│
└── Management Plane
    ├── RDP → DC01 (192.168.1.10)
    └── RSAT tools installed on workstation

                    ↕ LAN

Ubuntu Server 26.04 LTS (192.168.1.226)
```

The networking model shifts from this:

```text
DC01 → VMware NAT → Windows 11 Host → LAN
```

To this:

```text
DC01 → VMware Bridged Adapter → LAN (direct)
```

This gives DC01 a first-class LAN presence independent of the host workstation's NAT layer.

---

## Prerequisites

- Lab 01 completed and validated
- DC01 baseline snapshot (`DC01 - Clean Windows Server Base Install`) available
- Router DHCP reservation configured or available for `192.168.1.10`
- Windows 11 workstation available for RDP validation and RSAT installation
- Administrative access to VMware Workstation

---

## Deployment Steps

### Step One - Restore and Verify the Baseline Snapshot

Before making any configuration changes, DC01 will be restored to the clean baseline snapshot created at the end of Lab 01.

This ensures:

- the lab begins from a known-good state
- any configuration drift introduced during Lab 01 validation is eliminated
- the rollback chain remains clean and predictable

Snapshot to restore:

```text
DC01 - Clean Windows Server Base Install
```

After restoring, DC01 will be booted and verified to confirm:

- the operating system loads cleanly
- Server Manager opens on first boot
- VMware Tools is operational
- the VM is in a stable pre-configuration state

This step establishes the habit of always validating baseline state before beginning lab work.

---

### Step Two - Transition to Bridged Networking

DC01's VMware network adapter will be reconfigured from NAT to bridged networking.

This is performed through the VMware Workstation VM settings while the VM is powered off.

Configuration change:

| Setting | Before | After |
|---|---|---|
| Network Adapter | NAT (VMnet8) | Bridged (VMnet0) |

Bridged networking connects DC01's virtual network interface directly to the physical LAN through the Windows 11 workstation's physical adapter. From the perspective of the network, DC01 becomes a standalone host with its own MAC address and IP address.

This change is required because:

- Active Directory service discovery relies on DNS and Kerberos, which require direct LAN reachability
- domain join workflows from WIN11-CLIENT01 require client-to-DC connectivity over the LAN
- RDP administration from the Windows 11 workstation requires a routable DC01 address
- future hybrid integration with the Ubuntu Server host requires LAN-level reachability

After switching to bridged networking, DC01 will initially receive a DHCP-assigned address from the router. The static IP configuration in the following step will replace this with a fixed address.

---

### Step Three - Assign a Static IP Address

DC01 will be assigned a static IP address through the Windows Server network adapter settings.

Planned addressing:

| Parameter | Value |
|---|---|
| IP Address | `192.168.1.10` |
| Subnet Mask | `255.255.255.0` |
| Default Gateway | Router LAN address |
| Preferred DNS | `1.1.1.1` (temporary) |
| Alternate DNS | `8.8.8.8` (temporary) |

The DNS servers configured here are temporary public resolvers. They will be replaced in Lab 03 when DC01 is promoted to a domain controller and begins hosting AD-integrated DNS. At that point, DC01 will point to itself (`127.0.0.1`) as the primary DNS server.

Static addressing is required rather than DHCP because:

- Active Directory domain controllers must have stable, predictable addresses
- DNS records for the domain rely on the DC having a consistent IP
- Kerberos authentication uses IP addressing as part of its validation workflow
- RSAT and RDP connections from the management workstation target a fixed address

After configuring the static address, validation will confirm:

- `ipconfig /all` shows the correct static IP, subnet, gateway, and DNS
- ping to the router gateway succeeds
- ping to the Ubuntu Server (`192.168.1.226`) succeeds
- ping from the Windows 11 workstation to DC01 succeeds

---

### Step Four - Rename the Server Hostname

DC01's hostname will be set to `DC01` to align with the infrastructure naming standards defined in the architecture documentation.

This is performed through:

- System Properties
- or PowerShell:

```powershell
Rename-Computer -NewName \"DC01\" -Restart
```

The VM will reboot after the rename. Following the restart, the hostname will be validated through:

```powershell
hostname
```

or through Server Manager, which displays the local server name in the dashboard.

The hostname must be set correctly before Active Directory promotion because the domain controller's DNS records, Kerberos service tickets, and AD replication metadata are tied to the server hostname at promotion time. Renaming after promotion is significantly more complex and disruptive.

---

### Step Five - Apply Windows Updates

Windows updates will be run to completion before any server roles are installed.

This is important because:

- patching after AD promotion introduces additional complexity and risk
- some role installations require a fully patched base OS
- establishing a known-good patched baseline improves reproducibility

The update workflow:

1. Open Settings → Windows Update
2. Check for updates and install all available updates
3. Reboot as required
4. Repeat until no further updates are available

After updates complete, the build version and patch level will be documented.

---

### Step Six - Enable and Validate RDP

Remote Desktop will be enabled on DC01 to establish the remote administration workflow used for all future enterprise lab sessions.

RDP will be enabled through:

- Server Manager → Local Server → Remote Desktop → Enable
- or PowerShell:

```powershell
Set-ItemProperty -Path 'HKLM:\\System\\CurrentControlSet\\Control\\Terminal Server' -Name \"fDenyTSConnections\" -Value 0
Enable-NetFirewallRule -DisplayGroup \"Remote Desktop\"
```

After enabling RDP, a connection will be validated from the Windows 11 workstation using the built-in Remote Desktop client:

```text
mstsc /v:192.168.1.10
```

A successful RDP session confirms:

- static IP is correctly configured and routable
- bridged networking is functioning correctly
- Windows Firewall is allowing RDP traffic
- the remote administration workflow is operational

From this point forward, all DC01 administration will be performed via RDP rather than the VMware console, which mirrors real enterprise operational practice.

---

### Step Seven - Install RSAT on the Management Workstation

Remote Server Administration Tools will be installed on the Windows 11 workstation to provide the management utilities needed for Windows Server and future Active Directory administration.

RSAT components to install:

- RSAT: Active Directory Domain Services and Lightweight Directory Tools
- RSAT: DNS Server Tools
- RSAT: Group Policy Management Tools

Installation via PowerShell on the Windows 11 workstation:

```powershell
Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0
Add-WindowsCapability -Online -Name Rsat.Dns.Tools~~~~0.0.1.0
Add-WindowsCapability -Online -Name Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0
```

Or via Settings → Optional Features → Add a feature → search RSAT.

After installation, the presence of Active Directory Users and Computers, DNS Manager, and Group Policy Management Console will be validated in the Windows Administrative Tools menu.

Installing RSAT now rather than during Lab 03 means the tooling is ready and validated before it is needed, keeping the Active Directory lab focused on deployment rather than tooling setup.

---

### Step Eight - Server Manager Familiarization

A brief walkthrough of Server Manager will be performed to establish baseline familiarity with the primary Windows Server management interface.

Areas to review:

- Dashboard overview — server status, events, services, performance
- Local Server panel — hostname, IP configuration, Windows Update status, RDP state, time zone
- Event Viewer — reviewing System and Application event logs for baseline health
- Services — confirming core Windows services are running and stable

This mirrors the system validation approach used in the Linux infrastructure labs, where `fastfetch` and `ethtool` were used to establish hardware and network baseline visibility before proceeding with service deployment.

The goal is not deep administration at this stage, but rather building operational familiarity with the tools and interface that will be used throughout the enterprise infrastructure track.

---

### Step Nine - Baseline Hardening

A lightweight baseline hardening pass will be performed before Active Directory deployment.

This is not intended as a comprehensive security hardening exercise, but rather a set of foundational hygiene steps appropriate for a lab domain controller:

- confirm Windows Firewall is active and enabled for all profiles
- verify no unnecessary Windows features are enabled
- review local security policy basics through `secpol.msc`
- confirm the local Administrator account has a strong password set
- verify Windows Defender is active

These steps establish good operational habits that mirror enterprise pre-deployment baselines, even in a lab context.

---

### Step Ten - Pre-AD Snapshot

After all configuration steps are complete and validated, a new snapshot will be created as the rollback point for Lab 03.

Snapshot name:

```text
DC01 - Configured Windows Server Base, Pre-AD
```

Snapshot description:

```text
Windows Server 2022 fully configured with static IP (192.168.1.10), hostname DC01, bridged networking, RDP enabled, Windows updates applied, and baseline hardening complete. Ready for Active Directory Domain Services deployment.
```

This snapshot represents the clean starting point for Active Directory promotion and will be the primary recovery point if Lab 03 requires a rollback.

---

## Validation

Validation at completion will confirm:

- DC01 is operating on bridged networking with a stable LAN presence
- static IP `192.168.1.10` is correctly configured and routable
- hostname is set to `DC01`
- Windows updates are fully applied
- RDP is enabled and a successful remote session has been established from the Windows 11 workstation
- RSAT tools are installed and visible on the management workstation
- Server Manager shows a healthy local server baseline
- Windows Firewall is active
- pre-AD snapshot has been created

---

## Security Considerations

### Bridged Networking Exposure

Transitioning DC01 to bridged networking places it directly on the local LAN. While this is necessary for Active Directory functionality, it means DC01's services are reachable from other LAN devices.

This is acceptable in a home lab context given:

- the LAN is a trusted private network
- Windows Firewall remains active and restricts inbound traffic
- no public internet-facing exposure is introduced
- the VM can be powered off or snapshotted at any time

### RDP Access

RDP is being enabled specifically for LAN-local administration from the management workstation. The Windows Firewall rules for RDP will restrict access to the local subnet only where possible.

RDP will not be exposed externally. Tailscale provides remote access to the management workstation, from which RDP sessions can be initiated if needed.

### Local Administrator Account

The local Administrator account initialized during Windows Server installation will be used for all administration until Active Directory is deployed and domain-based authentication is available. A strong password policy will be validated during the baseline hardening step.

---

## Outcome

At completion of this lab, DC01 will be a fully configured, remotely administrable Windows Server environment with a stable LAN presence and a clean pre-AD baseline snapshot.

The environment will be prepared for:

- Active Directory Domain Services deployment
- AD-integrated DNS configuration
- domain join workflows for WIN11-CLIENT01
- Group Policy management
- hybrid integration with the Ubuntu Server host

This lab also completes the management tooling setup on the Windows 11 workstation, establishing the RSAT-based administration workflow that will be used throughout the remaining enterprise infrastructure labs.

---

## Lessons Learned

To be completed after lab execution.
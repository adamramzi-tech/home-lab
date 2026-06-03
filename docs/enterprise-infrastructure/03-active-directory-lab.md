# 03 - Active Directory Lab

## Status

Planning and research phase

---

## Overview

This lab deploys Active Directory Domain Services on DC01, establishing the enterprise identity foundation for the CORP environment. It represents the most architecturally significant step in the enterprise infrastructure track: the transition from a collection of independently configured Windows systems into a centrally managed domain.

The lab picks up from the pre-AD snapshot created at the end of Lab 02, where DC01 is a fully configured Windows Server host with a static LAN presence, RDP enabled, and Windows updates applied. The server is ready to receive its first role. This lab introduces that role.

The deployment covers:

- installing the Active Directory Domain Services role on DC01
- promoting DC01 to domain controller and establishing the `corp.home.arpa` domain
- configuring AD-integrated DNS to replace the temporary public resolvers
- reconfiguring DC01's DNS to point to itself after promotion
- creating the foundational Organizational Unit structure
- creating domain user and group accounts
- validating domain controller health and DNS resolution
- confirming WIN11-CLIENT01 can locate the domain and its services via DNS
- creating post-promotion snapshots for both VMs as rollback points for Lab 04

Active Directory is the core identity infrastructure that all subsequent enterprise labs depend on. Group Policy, domain join workflows, centralized authentication, Linux AD integration, and security monitoring pipelines all require a functional AD domain as a prerequisite. Getting this right is foundational.

---

## Objectives

- install the Active Directory Domain Services role on DC01
- promote DC01 to domain controller for the `corp.home.arpa` domain
- configure AD-integrated DNS on DC01
- reconfigure DC01's DNS to point to itself (`192.168.1.10`) immediately after promotion
- create a foundational Organizational Unit structure
- create domain user accounts and security groups
- validate domain controller health using built-in diagnostic tools
- validate AD-integrated DNS resolution from WIN11-CLIENT01
- confirm WIN11-CLIENT01 can resolve the domain and locate domain controller services
- create post-promotion snapshots for both DC01 and WIN11-CLIENT01

---

## Project Context

Labs 01 and 02 established the virtualization foundation and configured both VMs as standalone Windows systems with LAN presence and remote administration capability. That work was deliberately scoped to infrastructure preparation rather than identity deployment. The goal was to bring both systems to a stable, validated, fully patched baseline before introducing any server roles.

Active Directory changes that calculus significantly. Once AD is deployed, DC01 is no longer just a Windows Server. It becomes the authoritative identity store, DNS server, Kerberos Key Distribution Center, and domain replication endpoint for the entire enterprise environment. Configuration decisions made during promotion are difficult or impossible to cleanly reverse without either a full demotion and re-promotion cycle or a snapshot rollback. This is why the snapshot discipline established in earlier labs matters so much at this stage.

The domain name `corp.home.arpa` was chosen deliberately. The `home.arpa` zone is reserved for home network use under RFC 8375, making it the standards-aligned choice for private home lab namespacing. The `corp.` subdomain prefix clearly distinguishes this as an Active Directory domain rather than a general-purpose home network zone. This scoping keeps the AD domain functionally separate from the broader home LAN. DC01 will serve as the authoritative DNS server for `corp.home.arpa` and its subzones, but will not act as the general upstream resolver for the home network.

One of the most important post-promotion steps, and one the wizard does not handle automatically, is updating DC01's network adapter to use itself as the DNS server. After promotion, DC01 must point to `192.168.1.10` for DNS. This is a hard requirement: domain controllers use DNS for service record registration, Kerberos realm lookup, LDAP locator queries, and replication. A domain controller still pointing at a public resolver after promotion cannot correctly locate its own services and will produce misleading diagnostic output. This step should be treated as the very first action taken after the post-promotion reboot.

WIN11-CLIENT01 was already pre-configured in Lab 02 to point at DC01 (`192.168.1.10`) as its primary DNS server in anticipation of this deployment. That means once DC01 is promoted and hosting AD-integrated DNS, WIN11-CLIENT01 will automatically begin resolving AD service records without any DNS reconfiguration needed on the client side.

The Organizational Unit structure planned for this lab is intentionally minimal. The goal is to establish a clean, logical identity hierarchy that Group Policy can target in Lab 05, not to design a production-scale OU tree in a single step. The structure will evolve as subsequent labs introduce Group Policy Objects, additional user accounts, and domain-joined endpoints.

---

## Technologies Used

- Active Directory Domain Services (AD DS)
- AD-Integrated DNS
- Kerberos Authentication Protocol
- LDAP (Lightweight Directory Access Protocol)
- Group Policy Management Console (GPMC)
- Active Directory Users and Computers (ADUC)
- Active Directory Administrative Center (ADAC)
- DNS Manager
- Windows Server Manager
- PowerShell (Server Manager and AD cmdlets)
- Remote Server Administration Tools (RSAT) on WIN11-CLIENT01
- VMware Workstation Snapshot Management
- Windows Server 2022 Standard Evaluation
- Windows 11 Enterprise Evaluation

---

## Architecture and Topology

After this lab, DC01 will operate as the authoritative domain controller and DNS server for the `corp.home.arpa` domain.

```text
Windows 11 Workstation (192.168.1.x) [hypervisor and access device]
│
└── VMware Workstation
    │
    ├── DC01 (192.168.1.10) [domain controller]
    │   └── Windows Server 2022 Standard Evaluation
    │       ├── Static IP: 192.168.1.10
    │       ├── Hostname: DC01
    │       ├── Domain: corp.home.arpa
    │       ├── Roles: AD DS, DNS Server
    │       ├── DNS: 192.168.1.10 (self)
    │       ├── Kerberos KDC: active
    │       ├── LDAP: active on port 389
    │       ├── Global Catalog: active on port 3268
    │       └── AD-Integrated DNS: authoritative for corp.home.arpa
    │
    └── WIN11-CLIENT01 (192.168.1.20) [enterprise admin workstation]
        └── Windows 11 Enterprise Evaluation
            ├── Static IP: 192.168.1.20
            ├── DNS: 192.168.1.10 (DC01) [pre-configured in Lab 02]
            ├── RSAT: installed
            ├── Resolves: corp.home.arpa via DC01 DNS
            └── Lab 04: domain join pending

                    ↕ LAN

Ubuntu Server 26.04 LTS (192.168.1.226)
└── Future: SSSD + Kerberos AD authentication (Lab 06)
```

### DNS Architecture

```text
WIN11-CLIENT01 DNS query: corp.home.arpa
        ↓
DC01 DNS Server (192.168.1.10)
        ↓ (authoritative for corp.home.arpa)
AD-Integrated DNS Zone
        ↓ (forwarding for external names)
Public Resolver (1.1.1.1 / 8.8.8.8)
```

DC01 will be authoritative for the `corp.home.arpa` zone and all subzones created during promotion, including `_msdcs.corp.home.arpa`, which holds the service locator records that clients use to discover domain controller services. External name resolution will be handled through conditional forwarders pointing to public resolvers.

### Planned Identity Architecture

```text
corp.home.arpa [domain]
│
├── Domain Controllers
│   └── DC01.corp.home.arpa
│
└── corp.home.arpa [OU structure]
    │
    ├── IT
    │   └── [IT administrator accounts]
    │
    ├── Users
    │   └── [standard domain user accounts]
    │
    ├── Computers
    │   └── [domain-joined workstations - Lab 04]
    │
    └── Groups
        └── [security groups for policy targeting]
```

---

## Prerequisites

- Lab 01 completed and validated
- Lab 02 completed and validated
- DC01 pre-AD snapshot (`DC01 - Configured Windows Server Base, Pre-AD`) available and verified
- WIN11-CLIENT01 pre-domain snapshot (`WIN11-CLIENT01 - Configured Client Base, Pre-Domain`) available and verified
- DC01 at static IP `192.168.1.10` with RDP enabled and reachable from the management workstation
- WIN11-CLIENT01 DNS already configured to `192.168.1.10` (established in Lab 02)
- RSAT installed on WIN11-CLIENT01 (established in Lab 02)
- Administrative access to VMware Workstation for snapshot management

---

## Deployment Steps

### Step One - Restore and Verify the Pre-AD Snapshot

Before beginning AD deployment, restore DC01 to the pre-AD snapshot created at the end of Lab 02. This ensures the lab begins from a known-good, fully validated baseline and that any accidental configuration drift since Lab 02 is eliminated before introducing the domain controller role.

Restore the snapshot via VMware Workstation's snapshot menu using the revert-to-snapshot workflow.

<p align="center">
  <img src="../../images/enterprise-infrastructure/03-active-directory-lab/01-restore-pre-ad-snapshot.jpg" width="700">
</p>

<p align="center">
  <em>Restoring DC01 to the pre-AD snapshot before beginning Active Directory deployment.</em>
</p>

After restoring, boot DC01 and verify it is in the expected pre-configuration state:

- hostname: `DC01`
- static IP: `192.168.1.10`
- RDP: enabled
- Windows updates: applied
- Server Manager: opening on first boot

Only proceed once the baseline state is confirmed.

---

### Step Two - Install the Active Directory Domain Services Role

All administration from this point forward is performed via RDP from WIN11-CLIENT01. Open an RDP session to `192.168.1.10` before continuing.

Install the AD DS role through Server Manager → Add Roles and Features → Role-based or feature-based installation.

Select the following role on the Server Roles page:

- Active Directory Domain Services

The wizard will automatically prompt to include required features. Accept all dependencies when prompted, which will include:

- DNS Server
- Group Policy Management
- Remote Server Administration Tools for AD DS

<p align="center">
  <img src="../../images/enterprise-infrastructure/03-active-directory-lab/02-ad-ds-role-selection.jpg" width="700">
</p>

<p align="center">
  <em>Selecting the Active Directory Domain Services role for installation.</em>
</p>

<p align="center">
  <img src="../../images/enterprise-infrastructure/03-active-directory-lab/03-ad-ds-feature-dependencies.jpg" width="700">
</p>

<p align="center">
  <em>Additional features required by AD DS, including Group Policy Management and RSAT tools.</em>
</p>

<p align="center">
  <img src="../../images/enterprise-infrastructure/03-active-directory-lab/04-ad-ds-role-installation-progress.jpg" width="700">
</p>

<p align="center">
  <em>Active Directory Domain Services role installation in progress.</em>
</p>

<p align="center">
  <img src="../../images/enterprise-infrastructure/03-active-directory-lab/05-ad-ds-role-installation-complete.jpg" width="700">
</p>

<p align="center">
  <em>Role installation complete. The post-deployment configuration notification is visible in Server Manager.</em>
</p>

Installing the AD DS role adds the binaries and management tools to the server but does not yet configure it as a domain controller. That transition happens during promotion in the next step.

---

### Step Three - Promote DC01 to Domain Controller

Once the role installation is complete, a yellow notification flag will appear in the Server Manager toolbar. Click it and select **Promote this server to a domain controller** to launch the Active Directory Domain Services Configuration Wizard.

**Deployment configuration:**

Select **Add a new forest** and set the root domain name to `corp.home.arpa`.

<p align="center">
  <img src="../../images/enterprise-infrastructure/03-active-directory-lab/06-ad-new-forest-configuration.jpg" width="700">
</p>

<p align="center">
  <em>Configuring the new forest with root domain name corp.home.arpa.</em>
</p>

**Domain controller options:**

Configure the following on the Domain Controller Options page:

| Setting | Value |
|---|---|
| Forest functional level | Windows Server 2016 |
| Domain functional level | Windows Server 2016 |
| Domain Name System (DNS) server | Enabled |
| Global Catalog (GC) | Enabled |
| Directory Services Restore Mode (DSRM) password | Set and record securely |

<p align="center">
  <img src="../../images/enterprise-infrastructure/03-active-directory-lab/07-dc-options-configuration.jpg" width="700">
</p>

<p align="center">
  <em>Domain controller options including functional levels, DNS server role, and DSRM password.</em>
</p>

Set the forest and domain functional levels to Windows Server 2016. This is the highest level supported across the planned VM inventory and enables the full modern Active Directory feature set without creating compatibility constraints for future lab expansion.

The DSRM password must be set and stored somewhere secure and separate from domain credentials. This password is used to log into the domain controller in Directory Services Restore Mode during AD recovery scenarios. It is completely independent of the domain Administrator account. Losing it reduces recovery options significantly.

**DNS delegation warning:**

The DNS delegation page will display a warning that a delegation for `corp.home.arpa` cannot be created. This is expected in most home lab environments where the parent `home.arpa` zone is not managed locally. Acknowledge the warning and continue.

<p align="center">
  <img src="../../images/enterprise-infrastructure/03-active-directory-lab/08-dns-delegation-warning.jpg" width="700">
</p>

<p align="center">
  <em>DNS delegation warning. Expected behavior in a standalone lab environment where the parent zone is not locally managed. Acknowledge and continue.</em>
</p>

**NetBIOS name:**

The NetBIOS domain name will be automatically derived from the domain name. Verify it reads `CORP` and leave it unchanged.

<p align="center">
  <img src="../../images/enterprise-infrastructure/03-active-directory-lab/09-netbios-name-configuration.jpg" width="700">
</p>

<p align="center">
  <em>NetBIOS domain name automatically configured as CORP.</em>
</p>

**Paths:**

Retain the default paths for the AD database, log files, and SYSVOL. There is no reason to deviate from defaults in a single-server lab environment.

| Path | Default Location |
|---|---|
| Database folder | `C:\Windows\NTDS` |
| Log files folder | `C:\Windows\NTDS` |
| SYSVOL folder | `C:\Windows\SYSVOL` |

<p align="center">
  <img src="../../images/enterprise-infrastructure/03-active-directory-lab/10-ad-paths-configuration.jpg" width="700">
</p>

<p align="center">
  <em>Default AD database, log file, and SYSVOL paths retained.</em>
</p>

**Prerequisites check:**

Before allowing promotion to proceed, the wizard will run a prerequisites check. All critical tests should pass. There will likely be informational warnings about DNS delegation and cryptography policy. These are expected and do not affect functionality.

<p align="center">
  <img src="../../images/enterprise-infrastructure/03-active-directory-lab/11-prerequisites-check-passed.jpg" width="700">
</p>

<p align="center">
  <em>Prerequisites check passed. Informational warnings can be safely acknowledged.</em>
</p>

Click **Install**. DC01 will promote itself and reboot automatically. After the reboot, the login screen should reflect the `CORP` domain context.

<p align="center">
  <img src="../../images/enterprise-infrastructure/03-active-directory-lab/12-dc01-post-promotion-login.jpg" width="700">
</p>

<p align="center">
  <em>DC01 login screen after promotion showing the CORP domain context.</em>
</p>

---

### Step Four - Update DC01 DNS to Point to Itself

Immediately after the post-promotion reboot, before doing anything else, update DC01's network adapter DNS configuration to point to itself. The promotion wizard does not do this automatically.

Run the following from an elevated PowerShell session on DC01:

```powershell
Set-DnsClientServerAddress -InterfaceAlias "Ethernet0" -ServerAddresses ("192.168.1.10", "127.0.0.1")
```

Validate the change with `ipconfig /all`:

<p align="center">
  <img src="../../images/enterprise-infrastructure/03-active-directory-lab/13-dc01-dns-self-referral.jpg" width="700">
</p>

<p align="center">
  <em>DC01 DNS updated to 192.168.1.10 (self) as primary resolver after promotion.</em>
</p>

Expected adapter configuration after the update:

| Parameter | Value |
|---|---|
| IP Address | `192.168.1.10` |
| Subnet Mask | `255.255.255.0` |
| Default Gateway | `192.168.1.1` |
| DNS Server (Primary) | `192.168.1.10` |
| DNS Server (Secondary) | `127.0.0.1` |

The loopback address `127.0.0.1` as the secondary entry provides a DNS fallback in the event of a transient NIC configuration issue. This is a common and recommended post-promotion pattern.

Do not proceed to validation or further configuration until this step is confirmed.

---

### Step Five - Configure NTP Time Synchronization

Kerberos authentication enforces a maximum clock skew of five minutes between domain members. Clocks that drift beyond this threshold cause authentication failures that are difficult to diagnose. Configure DC01 to synchronize against an external NTP source immediately after the DNS self-referral is in place.

Run the following from an elevated PowerShell session on DC01:

```powershell
w32tm /config /manualpeerlist:"time.cloudflare.com,0x8 time.windows.com,0x8" /syncfromflags:manual /reliable:YES /update
Restart-Service w32tm
w32tm /resync /force
```

Validate that the time service is syncing correctly:

```powershell
w32tm /query /status
```

The output should show a reachable NTP source and a small offset (well under one second on a healthy VM). The `Stratum` field should be 2 or 3, indicating DC01 is syncing from an upstream time source rather than running as a free-running clock.

Once domain members join in subsequent labs, they will automatically sync their clocks against DC01 via the domain hierarchy. DC01 itself must sync against an external source to anchor the entire domain's time.

This step resolves the `dcdiag` informational warning about the time service not using an authoritative external NTP source.

---

### Step Six - Validate DNS and Domain Controller Health

Before building out the OU structure or creating accounts, validate that the domain controller is healthy and DNS is correctly configured. Finding and resolving issues at this stage is significantly easier than troubleshooting them after additional configuration has been layered on top.

**DNS zone validation:**

Open DNS Manager via RSAT on WIN11-CLIENT01 and connect it to DC01. Confirm the following zones are present:

| Zone | Type | Purpose |
|---|---|---|
| `corp.home.arpa` | AD-Integrated Primary | Forward lookup zone for the domain |
| `_msdcs.corp.home.arpa` | AD-Integrated Primary | Service locator records for DC discovery |
| `192.168.1.x Subnet` | AD-Integrated Primary | Reverse lookup zone for PTR records |

<p align="center">
  <img src="../../images/enterprise-infrastructure/03-active-directory-lab/14-dns-manager-zones.jpg" width="700">
</p>

<p align="center">
  <em>DNS Manager showing the corp.home.arpa forward lookup zone and _msdcs subdelegation created by AD promotion.</em>
</p>

The `_msdcs` zone is created automatically by the promotion process and contains the SRV records that clients use to locate Kerberos, LDAP, and Global Catalog services. Its presence confirms that service record registration completed successfully.

If the reverse lookup zone was not automatically created during promotion, create it manually... If it is not present, create it manually via DNS Manager: expand Reverse Lookup Zones, right-click, select New Zone, choose AD-Integrated Primary, and enter `192.168.1` as the network ID. The reverse zone enables PTR record resolution and is required for some `dcdiag` tests to pass cleanly.

**SRV record validation:**

From WIN11-CLIENT01, validate that the critical AD service records are resolvable:

```powershell
nslookup -type=SRV _ldap._tcp.corp.home.arpa 192.168.1.10
nslookup -type=SRV _kerberos._tcp.corp.home.arpa 192.168.1.10
```

<p align="center">
  <img src="../../images/enterprise-infrastructure/03-active-directory-lab/15-srv-record-validation.jpg" width="700">
</p>

<p align="center">
  <em>SRV record validation confirming LDAP and Kerberos service records are registered and resolvable from WIN11-CLIENT01.</em>
</p>

Both queries should return DC01 as the service host. This confirms that the domain controller has registered its services correctly and that WIN11-CLIENT01 can locate them. That client-side perspective is what matters for all downstream lab work.

**dcdiag validation:**

Run `dcdiag` on DC01 to perform a comprehensive domain controller health check:

```powershell
dcdiag /v
```

<p align="center">
  <img src="../../images/enterprise-infrastructure/03-active-directory-lab/16-dcdiag-validation.jpg" width="700">
</p>

<p align="center">
  <em>dcdiag output confirming domain controller health across connectivity, replication, and services tests.</em>
</p>

All of the following critical tests should pass:

- Connectivity
- Advertising
- FrsEvent / DFSREvent
- SysVolCheck
- KccEvent
- MachineAccount
- NetLogons
- ObjectsReplicated
- Replications
- RidManager
- Services
- SystemLog
- VerifyReferences

Informational warnings about DNS root zones or NTP configuration are expected and do not indicate a problem. Any failing test should be investigated and resolved before continuing.

**Netlogon and SYSVOL share validation:**

Confirm the Netlogon service is running and the SYSVOL and NETLOGON shares are accessible:

```powershell
Get-Service Netlogon
Test-Path \\DC01\SYSVOL
Test-Path \\DC01\NETLOGON
```

<p align="center">
  <img src="../../images/enterprise-infrastructure/03-active-directory-lab/17-netlogon-sysvol-validation.jpg" width="700">
</p>

<p align="center">
  <em>Netlogon service running and SYSVOL and NETLOGON shares accessible.</em>
</p>

Note: SYSVOL may take a few minutes to initialize after the first promotion reboot. If `Test-Path \\DC01\SYSVOL` returns false immediately after reboot, wait five minutes and retry before troubleshooting.

---

### Step Seven - Configure DNS Forwarders

Configure DNS forwarders on DC01 so that names outside `corp.home.arpa` can be resolved. Without forwarders, DC01 will attempt to resolve all external names through the DNS root hints, which introduces unnecessary latency and complexity.

Open DNS Manager, right-click DC01, select Properties, and navigate to the Forwarders tab. Add the following forwarders:

| Forwarder | Purpose |
|---|---|
| `1.1.1.1` | Cloudflare public DNS (primary) |
| `8.8.8.8` | Google public DNS (secondary) |

<p align="center">
  <img src="../../images/enterprise-infrastructure/03-active-directory-lab/18-dns-forwarders-configuration.jpg" width="700">
</p>

<p align="center">
  <em>DNS forwarders configured to 1.1.1.1 and 8.8.8.8 for external name resolution.</em>
</p>

Validate external resolution from WIN11-CLIENT01 after configuring the forwarders:

```powershell
Resolve-DnsName google.com -Server 192.168.1.10
```

<p align="center">
  <img src="../../images/enterprise-infrastructure/03-active-directory-lab/19-external-dns-resolution-validation.jpg" width="700">
</p>

<p align="center">
  <em>External DNS resolution through DC01 forwarding to public resolvers confirmed operational.</em>
</p>

---

### Step Eight - Build the Organizational Unit Structure

Create the foundational OU structure in Active Directory Users and Computers, accessed via RSAT on WIN11-CLIENT01.

The OU structure is designed to:

- organize identity objects by operational role
- provide clean Group Policy targeting surfaces for Lab 05
- reflect the separation between administrative and standard user accounts
- mirror the logical organization of the planned enterprise environment

Create the following OUs directly under the `corp.home.arpa` domain root:

| OU | Purpose |
|---|---|
| `IT` | IT administrator and privileged user accounts |
| `Users` | Standard domain user accounts |
| `Computers` | Domain-joined workstations (populated in Lab 04) |
| `Groups` | Security groups for policy targeting and access control |

<p align="center">
  <img src="../../images/enterprise-infrastructure/03-active-directory-lab/20-ou-structure-creation.jpg" width="700">
</p>

<p align="center">
  <em>Organizational Unit structure created under the corp.home.arpa domain root.</em>
</p>

Create the OUs directly under the domain root, not inside the default `Users` or `Computers` containers. The default containers are not OU objects and cannot be directly linked to Group Policy Objects. Creating a parallel OU structure from the start avoids having to migrate objects later and establishes clean GPO targeting surfaces before Lab 05.

The `Domain Controllers` OU should not be modified. It is managed by Active Directory itself.

PowerShell equivalent for reproducibility:

```powershell
$domain = "DC=corp,DC=home,DC=arpa"
New-ADOrganizationalUnit -Name "IT"        -Path $domain
New-ADOrganizationalUnit -Name "Users"     -Path $domain
New-ADOrganizationalUnit -Name "Computers" -Path $domain
New-ADOrganizationalUnit -Name "Groups"    -Path $domain
```

---

### Step Nine - Create Domain User and Group Accounts

Create the initial domain user accounts and security groups to populate the OU structure and establish the identity objects needed for Group Policy targeting and domain join testing in subsequent labs.

**User accounts:**

Create the following accounts in Active Directory Users and Computers, placing each in the appropriate OU:

| Account | OU | Role |
|---|---|---|
| `labadmin` | `IT` | Domain administrator account for lab management |
| `testuser01` | `Users` | Standard domain user for domain join and policy testing |

After creating `labadmin`, add it to both `Domain Admins` and `IT-Admins`. The `Domain Admins` membership grants built-in administrative rights across the domain. The `IT-Admins` group membership is what Group Policy in Lab 05 will use for policy targeting, so both are required. This account will be used for domain administration in subsequent labs rather than the built-in `Administrator` account, which should be retained as a recovery credential only.

`testuser01` should be a standard user with no elevated privileges. It will be used to test domain authentication, Group Policy application, and standard user desktop behavior after WIN11-CLIENT01 is domain-joined in Lab 04.

<p align="center">
  <img src="../../images/enterprise-infrastructure/03-active-directory-lab/21-domain-user-creation.jpg" width="700">
</p>

<p align="center">
  <em>Domain user accounts created and placed in the appropriate Organizational Units.</em>
</p>

PowerShell equivalent for user creation only — run this block first, before the security groups exist:

```powershell
New-ADUser -Name "labadmin" `
           -SamAccountName "labadmin" `
           -UserPrincipalName "labadmin@corp.home.arpa" `
           -Path "OU=IT,DC=corp,DC=home,DC=arpa" `
           -AccountPassword (ConvertTo-SecureString "P@ssw0rd!" -AsPlainText -Force) `
           -Enabled $true

New-ADUser -Name "testuser01" `
           -SamAccountName "testuser01" `
           -UserPrincipalName "testuser01@corp.home.arpa" `
           -Path "OU=Users,DC=corp,DC=home,DC=arpa" `
           -AccountPassword (ConvertTo-SecureString "P@ssw0rd!" -AsPlainText -Force) `
           -Enabled $true

Add-ADGroupMember -Identity "Domain Admins" -Members "labadmin"
```

**Security groups:**

Create the following security groups in the `Groups` OU:

| Group | Type | Scope | Purpose |
|---|---|---|---|
| `IT-Admins` | Security | Global | IT administrator accounts for GPO targeting |
| `Domain-Users-Standard` | Security | Global | Standard user accounts for GPO targeting |
| `Lab-Workstations` | Security | Global | Domain-joined workstations for computer policy targeting |

Add `labadmin` to `IT-Admins` and `testuser01` to `Domain-Users-Standard`. These group memberships will be used to scope Group Policy Objects in Lab 05.

PowerShell equivalent for group creation:

```powershell
$groupsOU = "OU=Groups,DC=corp,DC=home,DC=arpa"
New-ADGroup -Name "IT-Admins"             -GroupScope Global -GroupCategory Security -Path $groupsOU
New-ADGroup -Name "Domain-Users-Standard" -GroupScope Global -GroupCategory Security -Path $groupsOU
New-ADGroup -Name "Lab-Workstations"      -GroupScope Global -GroupCategory Security -Path $groupsOU
```

PowerShell equivalent for group membership — run this block after the security groups are created:

```powershell
Add-ADGroupMember -Identity "IT-Admins" -Members "labadmin"
Add-ADGroupMember -Identity "Domain-Users-Standard" -Members "testuser01"
```

<p align="center">
  <img src="../../images/enterprise-infrastructure/03-active-directory-lab/22-security-group-creation.jpg" width="700">
</p>

<p align="center">
  <em>Security groups created in the Groups OU for policy targeting.</em>
</p>

---

### Step Ten - Validate Domain Controller Advertising and Kerberos

Run a final validation pass before creating snapshots to confirm the domain controller is advertising correctly and Kerberos authentication is operational.

**Domain controller advertising:**

```powershell
nltest /dsgetdc:corp.home.arpa
```

<p align="center">
  <img src="../../images/enterprise-infrastructure/03-active-directory-lab/23-nltest-dc-advertising.jpg" width="700">
</p>

<p align="center">
  <em>nltest confirming DC01 is advertising as the domain controller for corp.home.arpa.</em>
</p>

The output should show DC01 as the located domain controller and include the following flags:

- `KDC`: Kerberos Key Distribution Center is active
- `GC`: Global Catalog is operational
- `PDC`: DC01 holds the PDC Emulator FSMO role

All five FSMO roles will be held by DC01 as the single domain controller in this environment. This is expected and normal.

**Kerberos ticket validation:**

Log into DC01 as `labadmin@corp.home.arpa` and run:

```powershell
klist
```

**LDAP signing verification:**

Confirm that LDAP signing is enforced on DC01:

```powershell
Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\NTDS\Parameters" `
                 -Name "LDAPServerIntegrity"
```

A value of `2` confirms LDAP signing is required. If the key is absent, Windows Server 2022 is enforcing LDAP signing through its default security configuration. Either result is acceptable for this lab.

<p align="center">
  <img src="../../images/enterprise-infrastructure/03-active-directory-lab/24-kerberos-ticket-validation.jpg" width="700">
</p>

<p align="center">
  <em>Kerberos ticket cache showing a valid TGT issued by DC01 for the corp.home.arpa realm.</em>
</p>

The ticket cache should show a valid TGT for `labadmin@CORP.HOME.ARPA` issued by `krbtgt/CORP.HOME.ARPA@CORP.HOME.ARPA` using AES256 encryption. A valid TGT confirms the Kerberos authentication infrastructure is operational and the domain is ready for domain join workflows in Lab 04.

**WIN11-CLIENT01 DNS resolution validation:**

From WIN11-CLIENT01, run:

```powershell
Resolve-DnsName corp.home.arpa
Resolve-DnsName DC01.corp.home.arpa
Resolve-DnsName google.com
```

<p align="center">
  <img src="../../images/enterprise-infrastructure/03-active-directory-lab/25-win11-dns-resolution-validation.jpg" width="700">
</p>

<p align="center">
  <em>DNS resolution from WIN11-CLIENT01 confirming domain, DC hostname, and external name resolution through DC01.</em>
</p>

All three should resolve correctly:

- `corp.home.arpa` resolves to `192.168.1.10`
- `DC01.corp.home.arpa` resolves to `192.168.1.10`
- `google.com` resolves through DC01 forwarding

If all three resolve, WIN11-CLIENT01 can locate the domain and its services. Domain join in Lab 04 is ready to proceed.

---

### Step Eleven - Create Post-Promotion Snapshots

Once all validation steps pass, create snapshots for both VMs before Lab 04 begins. These snapshots are the rollback points for the domain join and client configuration work ahead.

**DC01 post-promotion snapshot:**

<p align="center">
  <img src="../../images/enterprise-infrastructure/03-active-directory-lab/26-dc01-post-promotion-snapshot.jpg" width="700">
</p>

<p align="center">
  <em>DC01 post-promotion snapshot created as the rollback point for Lab 04.</em>
</p>

Snapshot name:

```text
DC01 - Active Directory Deployed, corp.home.arpa
```

Snapshot description:

```text
DC01 promoted to domain controller for corp.home.arpa. AD DS and DNS roles installed and operational. OU structure created (IT, Users, Computers, Groups). Domain accounts created: labadmin (Domain Admins), testuser01 (standard user). Security groups created: IT-Admins, Domain-Users-Standard, Lab-Workstations. DNS forwarders configured to 1.1.1.1 and 8.8.8.8. dcdiag passed. Kerberos operational. Ready for Lab 04 domain join.
```

**WIN11-CLIENT01 pre-domain-join snapshot:**

<p align="center">
  <img src="../../images/enterprise-infrastructure/03-active-directory-lab/27-win11-pre-domain-join-snapshot.jpg" width="700">
</p>

<p align="center">
  <em>WIN11-CLIENT01 snapshot created before domain join in Lab 04.</em>
</p>

Snapshot name:

```text
WIN11-CLIENT01 - Pre-Domain Join, DNS Validated
```

Snapshot description:

```text
WIN11-CLIENT01 DNS pointing to DC01 (192.168.1.10). Domain name corp.home.arpa and DC01 hostname resolving correctly. SRV records for LDAP and Kerberos resolvable from client. Ready for domain join in Lab 04.
```

---

## Validation Checklist

Use this checklist to confirm the lab is complete before moving to Lab 04.

| Check | Expected Result |
|---|---|
| AD DS role installed on DC01 | Visible in Server Manager Roles summary |
| DC01 promoted to domain controller | Login screen shows CORP domain context |
| Forest root domain `corp.home.arpa` created | Visible in Active Directory Domains and Trusts |
| NetBIOS domain name `CORP` configured | Confirmed via `nltest` output |
| DC01 DNS updated to self-reference (`192.168.1.10`) | Confirmed via `ipconfig /all` |
| NTP configured and syncing | `w32tm /query /status` shows reachable source and low offset |
| DNS forwarders configured to `1.1.1.1` and `8.8.8.8` | Confirmed via DNS Manager |
| `corp.home.arpa` forward lookup zone present | Confirmed via DNS Manager |
| `_msdcs.corp.home.arpa` zone present with SRV records | Confirmed via DNS Manager and `nslookup` |
| Reverse lookup zone present | Confirmed via DNS Manager |
| `dcdiag /v` all critical tests passed | No failing tests |
| Netlogon service running | `Get-Service Netlogon` returns Running |
| SYSVOL and NETLOGON shares accessible | `Test-Path` returns True for both |
| DC01 advertising as KDC, GC, PDC | Confirmed via `nltest /dsgetdc:corp.home.arpa` |
| Kerberos TGT issued for `labadmin` | Confirmed via `klist` |
| LDAP signing enforced | `LDAPServerIntegrity` value is `2` or absent (WS2022 default) |
| OU structure created: IT, Users, Computers, Groups | Visible in ADUC |
| Domain accounts created: `labadmin`, `testuser01` | Visible in ADUC |
| `labadmin` in Domain Admins and IT-Admins | Confirmed via `Get-ADGroupMember` |
| `testuser01` in Domain-Users-Standard | Confirmed via `Get-ADGroupMember` |
| Security groups created: IT-Admins, Domain-Users-Standard, Lab-Workstations | Visible in ADUC |
| WIN11-CLIENT01 resolves `corp.home.arpa` | Returns `192.168.1.10` |
| WIN11-CLIENT01 resolves `DC01.corp.home.arpa` | Returns `192.168.1.10` |
| WIN11-CLIENT01 external DNS forwarding functional | `google.com` resolves through DC01 |
| DC01 post-promotion snapshot created | Visible in VMware snapshot manager |
| WIN11-CLIENT01 pre-domain-join snapshot created | Visible in VMware snapshot manager |

---

## Potential Issues and How to Handle Them

### DNS Self-Referral Not Set Automatically After Promotion

The promotion wizard installs the DNS role and creates AD-integrated zones but does not update the network adapter's DNS server configuration. DC01 will emerge from its post-promotion reboot still pointing at the public resolvers from Lab 02. Update the NIC DNS to `192.168.1.10` immediately after first login, before opening any other tools or running any diagnostics.

### DNS Delegation Warning During Promotion

The promotion wizard will display a warning that a delegation for `corp.home.arpa` cannot be created in a parent zone. This is expected in most home lab environments where the parent `home.arpa` zone is not managed locally. Acknowledge the warning and continue.

### SYSVOL Share Not Immediately Accessible After Reboot

After the post-promotion reboot, the SYSVOL share may take several minutes to become available while DFS-R initializes the SYSVOL replication group. If `Test-Path \\DC01\SYSVOL` returns false immediately after reboot, wait five minutes and retry before investigating further.

### dcdiag Informational Warnings

Running `dcdiag /v` will likely produce informational warnings alongside passing test results. Common ones include warnings about the DNS root zone not being present on the server (expected when forwarders handle external resolution rather than root hints) and the time service not using an authoritative external NTP source. Neither indicates a functional problem. Focus on any tests that explicitly fail rather than warnings.

### Kerberos or LDAP SRV Records Not Resolving From WIN11-CLIENT01

If `nslookup -type=SRV _ldap._tcp.corp.home.arpa 192.168.1.10` returns no records, confirm that:

- DC01's NIC DNS is pointing at itself (`192.168.1.10`), not a public resolver
- the Netlogon service is running on DC01
- the `_msdcs.corp.home.arpa` zone is present in DNS Manager

If the Netlogon service was started before DC01's NIC DNS was updated to self-reference, it may not have registered SRV records correctly. Restart the Netlogon service after the NIC DNS update to force re-registration:

```powershell
Restart-Service Netlogon
```

Then re-run the `nslookup` queries from WIN11-CLIENT01.

---

## Security Considerations

### Domain Controller Attack Surface

Once promoted, DC01 becomes the most sensitive system in the environment. It holds the AD database (NTDS.dit) containing all domain credential hashes, operates as the Kerberos Key Distribution Center, and distributes Group Policy through the SYSVOL share. Windows Defender Firewall should remain active throughout the lab. No unnecessary inbound firewall rules beyond those required for Active Directory and remote administration should be opened.

### DSRM Password

The Directory Services Restore Mode password must be set during promotion and stored securely, separate from domain credentials. It is used to boot the domain controller into a recovery mode where AD services are not running. Loss of this password meaningfully reduces recovery options if the AD database becomes corrupted.

### Built-in Administrator vs labadmin

The built-in `Administrator` account will be used for the initial post-promotion login before domain accounts are available. Once `labadmin` is created and added to `Domain Admins`, switch to using `labadmin` for all subsequent domain administration. Retain the built-in `Administrator` account as a recovery credential only.

### LDAP Without TLS

LDAP in this environment will operate over port 389 without TLS encryption. Windows Server 2022 ships with stronger LDAP security defaults, including LDAP signing protections, which prevents unauthenticated LDAP binds and provides session integrity, but LDAP traffic will not be encrypted in transit. LDAPS (port 636) would require certificate infrastructure. For a lab environment on a trusted LAN, LDAP signing with no channel encryption is an acceptable baseline.

To confirm the Windows Server 2022 default is in place rather than assuming it, run the following on DC01:

```powershell
Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\NTDS\Parameters" `
                 -Name "LDAPServerIntegrity"
```

A value of `2` confirms LDAP signing is required. A value of `1` means it is enabled but not enforced. If the value is missing, Windows Server 2022 is enforcing LDAP signing through its default security configuration. For this lab, confirming the value is `2` or absent is sufficient.

---

## Outcome

At completion of this lab, DC01 will be a fully operational Active Directory domain controller and DNS server for the `corp.home.arpa` domain. The enterprise identity infrastructure that all subsequent labs depend on will be in place.

The environment will be prepared for:

- domain join workflows for WIN11-CLIENT01 (Lab 04)
- Group Policy design, deployment, and validation (Lab 05)
- Linux AD integration via SSSD and Kerberos on the Ubuntu Server host (Lab 06)
- Windows event log collection and SIEM integration via Wazuh (Lab 07)
- Windows metrics export into the existing Prometheus and Grafana monitoring stack

WIN11-CLIENT01 will be able to locate the domain and resolve all required service records. All that remains before domain join is the Lab 04 deployment sequence.

---

## Research Notes

### Why the Domain Must Use Its Own DNS

Active Directory is deeply dependent on DNS. Service locator records (SRV records) in the `_msdcs` zone tell clients where to find Kerberos, LDAP, and the Global Catalog. If DC01 is not using itself for DNS, it cannot register these records correctly, and clients will not be able to locate domain services. This is the most common cause of AD deployment problems and the reason the NIC DNS update must be the first post-promotion action.

### Functional Levels

The forest and domain functional levels set during promotion determine which AD features are available and which Windows Server versions can be added as additional domain controllers in the future. Setting both to Windows Server 2016 is a reasonable choice for this environment. It enables modern features like Privileged Access Management and improved Kerberos armoring, while remaining compatible with any reasonably current Windows Server version that might be added later. Raising functional levels after the fact is straightforward but is a one-way operation.

### FSMO Roles in a Single DC Environment

With only one domain controller, DC01 will hold all five FSMO (Flexible Single Master Operations) roles: Schema Master, Domain Naming Master, PDC Emulator, RID Master, and Infrastructure Master. This is normal. FSMO roles become operationally important when a second domain controller is introduced. At that point, decisions about which DC holds which role affect replication behavior and failure tolerance. For this lab, confirming that DC01 holds the PDC Emulator role via `nltest` is sufficient.

### OU vs Container

The default `Users` and `Computers` objects in Active Directory are containers, not Organizational Units. The distinction matters for Group Policy: GPOs can only be linked to domains, sites, and OUs, not to containers. Objects placed in `CN=Users` or `CN=Computers` will still inherit GPOs linked at the domain level, but you cannot link a GPO directly to the default containers. Creating a parallel OU structure from the start avoids having to migrate objects out of the default containers later when Group Policy targeting is needed.

### SYSVOL and Group Policy

The SYSVOL share on DC01 is where Group Policy template files are stored and replicated. In a single-DC environment, there is no replication partner, but SYSVOL still needs to initialize correctly via DFS-R before it becomes accessible. The share hosts the `Policies` and `Scripts` folders that clients reference when applying Group Policy. Its health is validated by `dcdiag` and the `SysVolCheck` test specifically.

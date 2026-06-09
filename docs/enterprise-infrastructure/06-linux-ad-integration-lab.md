# 06 - Linux and AD Integration Lab

## Status

Planning and research phase.

---

## Overview

This lab extends the Active Directory identity infrastructure deployed in Labs 03, 04, and 05 into the Linux environment, making Active Directory the authoritative identity provider for both Windows and Linux systems in the `corp.home.arpa` domain.

Labs 03 through 05 established a complete Windows-centric identity platform: a fully promoted domain controller, a domain-joined workstation, and Group Policy infrastructure governing both machine behavior and user environments. Every authentication event in the enterprise environment currently flows through DC01. Every identity is resolved from Active Directory. Group Policy governs what users can and cannot do on Windows endpoints.

Linux has been absent from that picture until now. The Ubuntu Server host at `192.168.1.226` operates entirely outside the AD domain. It authenticates users against local `/etc/passwd` and `/etc/shadow` files. It has no awareness of `corp.home.arpa`, no relationship with DC01, and no way to resolve AD identities. That is the gap this lab closes.

The lab deploys SSSD (System Security Services Daemon) and its supporting components on the Ubuntu Server host, joins the host to the `corp.home.arpa` domain, and configures it to resolve identity information and authenticate users directly against Active Directory via Kerberos. A dedicated Active Directory security group (`Linux-Admins`) will gate access to the Linux host, demonstrating not just centralized authentication but centralized authorization across the hybrid environment.

This is not a Linux administration lab. It is an identity integration lab. The central outcome is that Active Directory becomes the single authoritative identity provider across both Windows and Linux infrastructure, and that identity, authentication, and authorization all flow from the same source regardless of the target platform.

This lab represents the first major convergence point between the Linux Infrastructure track and the Enterprise Infrastructure track.

---

## Objectives

- create the `Linux-Admins` security group in Active Directory and populate it with `labadmin`
- validate DNS resolution of `corp.home.arpa` from the Ubuntu Server host before attempting domain join
- validate time synchronization between the Ubuntu Server host and DC01 before attempting domain join
- install `realmd`, `sssd`, `adcli`, `krb5-user`, and supporting packages on the Ubuntu Server host
- perform realm discovery against `corp.home.arpa` from the Ubuntu Server host
- join the Ubuntu Server host to the `corp.home.arpa` domain using `realm join`
- confirm the Ubuntu Server computer account is created in Active Directory
- configure SSSD to allow access exclusively to members of the `Linux-Admins` group
- validate that Active Directory user and group identities resolve on the Ubuntu Server host
- validate Kerberos ticket acquisition for AD users from the Ubuntu Server host
- validate that `labadmin` (a member of `Linux-Admins`) can authenticate to the Ubuntu Server host
- validate that `testuser01` (not a member of `Linux-Admins`) is denied access to the Ubuntu Server host
- validate SSH authentication to the Ubuntu Server host using Active Directory credentials
- create a post-integration snapshot for DC01

---

## Project Context

Labs 03, 04, and 05 built the identity foundation this lab depends on. That sequence mattered: a domain had to exist before anything could join it, a client had to join before Group Policy could be meaningfully validated, and Group Policy had to be validated before expanding identity infrastructure into new platforms. Each lab in the enterprise track was designed to produce a validated baseline that the next lab could rely on.

This lab is the first point where the Linux Infrastructure track and the Enterprise Infrastructure track converge. The Ubuntu Server host has been operating as a standalone infrastructure platform: running Docker, hosting the monitoring stack, operating as the reverse proxy endpoint, and serving as the primary Linux administration environment. None of those workloads are being modified here. The integration being planned is purely at the identity layer: how users authenticate to the host, how identity is resolved, and who is permitted access.

The identity architecture problem this lab addresses is a common one in real enterprise environments. Linux systems that authenticate against local accounts are identity islands. They have no relationship to the centralized identity store the rest of the environment depends on. Access management becomes a per-system problem: accounts must be created manually, passwords managed independently, and access audited without any organizational structure. Active Directory integration solves this. Once the Ubuntu Server host joins the domain, `labadmin` is `labadmin` everywhere. Identity is sourced from one place. Access is controlled through AD group membership. Audit events carry consistent identities across platforms.

The decision to use `realmd` and SSSD rather than manual Kerberos and LDAP configuration is deliberate. `realmd` handles the domain join workflow in a way that is operationally clean and well-tested against Active Directory. SSSD provides caching, PAM integration, and NSS integration through a single service rather than a collection of independent configuration files. This is the standard, well-supported path for Linux AD integration in enterprise environments. It is also the most maintainable: the configuration surfaces are well-documented, the failure modes are well-understood, and the tooling for validation is mature.

The `Linux-Admins` security group is new to this lab. The existing groups (`IT-Admins`, `Domain-Users-Standard`, `Lab-Workstations`) were designed around Windows policy targeting. `Linux-Admins` serves a different purpose: it is the authorization gate for the Linux infrastructure layer. Not every AD user should be permitted to log into the Ubuntu Server host. `Linux-Admins` defines who can. This group will remain useful in future labs as additional Linux systems are introduced.

---

## Technologies Used

- Active Directory Domain Services (AD DS)
- Kerberos Authentication Protocol
- SSSD (System Security Services Daemon)
- realmd
- adcli
- PAM (Pluggable Authentication Modules)
- NSS (Name Service Switch)
- Ubuntu Server 26.04 LTS
- Windows Server 2022 Standard Evaluation
- Active Directory Users and Computers (ADUC)
- PowerShell (AD cmdlets for group management)
- OpenSSH

---

## Planned Architecture and Topology

### Post-Integration Identity Topology

After this lab, the Ubuntu Server host will be a domain member with identity sourced from Active Directory.

```text
Windows 11 Workstation (192.168.1.x) [hypervisor and management endpoint]
|
+-- VMware Workstation
    |
    +-- DC01 (192.168.1.10) [domain controller]
    |   +-- Windows Server 2022 Standard Evaluation
    |   +-- Active Directory Domain Services
    |   +-- AD-Integrated DNS (corp.home.arpa)
    |   +-- Kerberos KDC
    |   +-- Linux-Admins group (labadmin member)
    |   +-- Group Policy: three custom GPOs deployed and validated
    |
    +-- WIN11-CLIENT01 (192.168.1.20) [domain-joined workstation]
        +-- corp.home.arpa domain member
        +-- Group Policy applied and validated

            <-> LAN (192.168.1.0/24)

Ubuntu Server 26.04 LTS (192.168.1.226) [domain-joined Linux host]
+-- realmd: domain join tooling
+-- SSSD: identity and authentication broker
|   +-- AD Provider: identity sourced from DC01
|   +-- Kerberos: authentication tickets from DC01 KDC
|   +-- PAM integration: authentication pipeline
|   +-- NSS integration: identity resolution pipeline
+-- Access Control: Linux-Admins group membership required
+-- Docker infrastructure: unchanged
+-- Monitoring stack: unchanged
+-- Reverse proxy: unchanged
```

### Authentication and Authorization Flow

```text
User
  |
  v
Active Directory (DC01 - 192.168.1.10)
  |
  v
Kerberos KDC (ticket issuance and validation)
  |
  v
SSSD (identity and authentication broker on Ubuntu Server)
  |
  +-- NSS: resolves uid, gid, group membership from AD
  +-- PAM: validates Kerberos ticket against DC01
  |
  v
Authorization check: Linux-Admins group membership
  |
  +-- member     --> access granted
  +-- non-member --> access denied
  |
  v
SSH / Linux login session
  |
  v
Ubuntu Server 26.04 LTS
```

### Identity Resolution Flow

```text
getent passwd labadmin@corp.home.arpa
  |
  v
NSS (Name Service Switch)
  |
  v
SSSD AD Provider
  |
  v
LDAP query to DC01 (192.168.1.10)
  |
  v
Active Directory: labadmin UID, GID, home directory, shell
  |
  v
Response returned to calling process
```

### DNS Architecture (Post-Integration)

The Ubuntu Server host must be configured to use DC01 as its DNS server, or at minimum be able to resolve `corp.home.arpa` through the network, before domain join is possible. Kerberos realm discovery and domain controller location both depend on DNS SRV record resolution.

```text
Ubuntu Server DNS query: corp.home.arpa
  |
  v
DC01 DNS (192.168.1.10)
  |
  v (authoritative for corp.home.arpa)
AD-Integrated DNS Zone
  |
  v
SRV records: _kerberos._tcp.corp.home.arpa, _ldap._tcp.corp.home.arpa
  |
  v
DC01 located: 192.168.1.10
```

### Active Directory Structure After Lab 06

```text
corp.home.arpa [domain]
|
+-- Default Domain Policy [not modified]
|
+-- Domain Controllers [OU]
|   +-- DC01.corp.home.arpa
|
+-- IT [OU]
|   +-- IT-Admin-Environment GPO
|   +-- labadmin
|
+-- User Accounts [OU]
|   +-- Standard-User-Environment GPO
|   +-- testuser01
|
+-- Workstations [OU]
|   +-- Workstation-Security-Baseline GPO
|   |   +-- Security Filter: Lab-Workstations
|   +-- WIN11-CLIENT01 (computer account)
|   +-- ubuntu-server (computer account) <-- created on domain join
|
+-- Groups [OU]
    +-- IT-Admins
    +-- Domain-Users-Standard
    +-- Lab-Workstations
    +-- Linux-Admins                     <-- new in this lab
        +-- labadmin (member)
```

---

## Prerequisites

- Lab 03 completed and validated
- Lab 04 completed and validated
- Lab 05 completed and validated
- DC01 post-GPO snapshot (`DC01 - Group Policy Deployed`) verified
- WIN11-CLIENT01 post-GPO snapshot (`WIN11-CLIENT01 - Group Policy Applied`) verified
- DC01 at static IP `192.168.1.10` with RDP operational
- Ubuntu Server at static IP `192.168.1.226` with SSH operational
- Ubuntu Server can reach DC01 (`192.168.1.10`) via ICMP before beginning
- Ubuntu Server can resolve `corp.home.arpa` via DNS before beginning
- Domain accounts operational: `labadmin` (Domain Admins, IT-Admins), `testuser01` (Domain-Users-Standard)
- OU structure intact: IT, User Accounts, Workstations, Groups
- Administrative access to DC01 via RDP or WIN11-CLIENT01 RSAT for AD configuration steps
- SSH access to Ubuntu Server from management workstation

---

## Planned Deployment Phases

### Phase One: Active Directory Preparation

Before touching the Ubuntu Server host, the Active Directory environment must be prepared to receive a Linux domain member. This means creating the group structure the integration depends on.

#### 1.1 Create the Linux-Admins Security Group

A new security group named `Linux-Admins` will be created in the `Groups` OU. This group is the authorization gate for access to Linux infrastructure systems. Only members of this group will be permitted to authenticate to the Ubuntu Server host after SSSD is configured.

```powershell
New-ADGroup -Name "Linux-Admins" `
            -GroupScope Global `
            -GroupCategory Security `
            -Path "OU=Groups,DC=corp,DC=home,DC=arpa" `
            -Description "Authorized administrators of Linux infrastructure systems"
```

`labadmin` will be added to `Linux-Admins`:

```powershell
Add-ADGroupMember -Identity "Linux-Admins" -Members "labadmin"
```

`testuser01` will deliberately not be added to `Linux-Admins`. This account will be used to validate that access denial works correctly in Phase Four.

Group membership will be validated from DC01 before proceeding:

```powershell
Get-ADGroupMember "Linux-Admins"
```

The expected output will show `labadmin` as the sole member.

---

### Phase Two: Ubuntu Server Pre-Join Validation

The Ubuntu Server host must satisfy three prerequisites before domain join is possible: correct DNS configuration, time synchronization within the Kerberos skew tolerance, and network reachability to DC01. These are not optional formalities. Kerberos authentication will fail silently or produce misleading error messages if any of these conditions are not met. Validating them before proceeding eliminates a large class of troubleshooting scenarios.

#### 2.1 DNS Validation

The Ubuntu Server host must be able to resolve `corp.home.arpa` and the AD service records that realm discovery depends on. At minimum, the host must be able to query DC01's DNS service directly. Depending on the current DNS configuration on the Ubuntu Server host, it may already be forwarding to a resolver that can handle the domain, or it may need to be pointed at DC01 directly.

Planned validation commands:

```bash
# Confirm DC01 is reachable
ping -c 4 192.168.1.10

# Review current DNS resolver configuration
resolvectl status

# Resolve the domain name against DC01 directly
nslookup corp.home.arpa 192.168.1.10

# Confirm Kerberos SRV records are resolvable
nslookup -type=SRV _kerberos._tcp.corp.home.arpa 192.168.1.10

# Confirm LDAP SRV records are resolvable
nslookup -type=SRV _ldap._tcp.corp.home.arpa 192.168.1.10
```

All four queries must succeed before proceeding. If the SRV record queries fail but the domain name resolves, the DNS server in use does not have access to the AD-integrated zones. This will prevent `realm discover` from locating DC01 as the domain's Kerberos and LDAP endpoint.

The Ubuntu Server host's DNS configuration lives in `/etc/systemd/resolved.conf` (if `systemd-resolved` is in use) or `/etc/resolv.conf` directly. The appropriate fix depends on which resolver is managing DNS on the host. The goal is to ensure `corp.home.arpa` SRV records are reachable from the host, either by pointing the resolver at `192.168.1.10` directly or by confirming the current upstream resolver forwards the zone correctly.

#### 2.2 Time Synchronization Validation

Kerberos enforces a maximum clock skew of five minutes between the client and the KDC. If the Ubuntu Server host's clock is more than five minutes off from DC01, Kerberos authentication will fail. The error messages produced by this failure are often confusing and do not clearly identify clock drift as the cause.

Ubuntu Server 26.04 uses `systemd-timesyncd` or `chrony` for NTP. Either is acceptable. The configuration needs to be validated before the domain join, not discovered during troubleshooting afterward.

Planned validation:

```bash
# Check current time and NTP synchronization status
timedatectl status

# Or if chrony is in use
chronyc tracking
```

The output should show the clock synchronized, the NTP server identified, and the offset small. If the clock is not synchronized, the NTP service configuration will need to be corrected before proceeding.

Kerberos requires the Ubuntu Server host and DC01 to maintain synchronized time within the permitted clock skew tolerance. Time synchronization is provided by the host's NTP service (`systemd-timesyncd` or `chrony`), not by SSSD. The lab environment's LAN has access to public NTP servers, and DC01 synchronizes against `time.cloudflare.com`. Time synchronization will be validated before the domain join to prevent Kerberos authentication failures.

#### 2.3 Hostname Validation

The hostname the Ubuntu Server presents during the domain join determines its computer account name in Active Directory. `realm join` creates the computer account automatically using the host's current hostname. The hostname should be confirmed before running the join so the resulting computer account name in AD is known and expected.

Planned validation:

```bash
hostname
hostnamectl status
```

#### 2.4 Hostname Standardization

The Ubuntu Server host was originally deployed with the hostname `homeserver`. Before joining the Active Directory domain, the hostname will be standardized to `ubuntu-server` to align with the documented infrastructure naming convention and ensure the resulting Active Directory computer account name is predictable and consistent with the project documentation.

Because `realm join` uses the host's current hostname when creating the computer account in Active Directory, this change must occur before the domain join.

Planned commands:

```bash
sudo hostnamectl set-hostname ubuntu-server

hostname
hostnamectl status
```

Expected result:

```text
ubuntu-server
```

The host will then be rebooted to ensure all services recognize the updated hostname:

```bash
sudo reboot
```

After reboot:

```bash
hostname
hostnamectl status
```

The hostname should continue to report as `ubuntu-server` before proceeding to Phase Three.

---

### Phase Three: Domain Join

#### 3.1 Package Installation

The following packages must be installed on the Ubuntu Server host before domain join is possible:

| Package | Purpose |
|---|---|
| `realmd` | Domain discovery and join tooling |
| `sssd` | Core SSSD daemon and identity broker |
| `sssd-tools` | SSSD command-line utilities |
| `adcli` | AD connector used by realmd for join operations |
| `krb5-user` | Kerberos client utilities (kinit, klist, kdestroy) |
| `samba-common-bin` | Samba utilities needed by realmd |
| `packagekit` | Required by realmd's package management integration |
| `oddjob` | PAM oddjobd integration for home directory creation |
| `oddjob-mkhomedir` | Automatic home directory creation on first login |

Installation:

```bash
sudo apt update
sudo apt install -y realmd sssd sssd-tools adcli krb5-user \
    samba-common-bin packagekit oddjob oddjob-mkhomedir
```

During `krb5-user` installation, the installer will prompt for a default Kerberos realm. Enter `CORP.HOME.ARPA` in uppercase. Kerberos realm names are case-sensitive by convention and must be uppercase.

#### 3.2 Realm Discovery

Before joining, `realm discover` queries DNS for the AD domain's SRV records and attempts to contact DC01 directly to gather information about the realm. The output of a successful discovery confirms that:

- the domain is reachable from the Ubuntu Server host
- DC01 has been identified as the domain controller
- the Kerberos realm name has been confirmed
- realm software requirements are identified

Planned command:

```bash
realm discover corp.home.arpa
```

A successful discovery will produce output identifying `corp.home.arpa` as an active-directory realm, listing DC01 as the domain controller, and indicating the required packages are installed. If discovery fails, the DNS and network prerequisites from Phase Two must be re-examined before proceeding.

#### 3.3 Domain Join

With prerequisites validated and realm discovery successful, the domain join can proceed:

```bash
sudo realm join -U labadmin corp.home.arpa
```

The `-U labadmin` flag specifies the AD account that authorizes the join. This account must have permission to create computer accounts in Active Directory. Since `labadmin` is a member of `Domain Admins`, it has this permission by default.

`realm join` will:

1. Acquire a Kerberos ticket for `labadmin` to authenticate the operation
2. Create the computer account in Active Directory
3. Configure SSSD on the Ubuntu Server host
4. Write a basic `/etc/sssd/sssd.conf`
5. Register the host's keytab file at `/etc/krb5.keytab`
6. Restart SSSD

A successful join produces no output and exits with code 0. Errors are explicit and informative.

Immediately after the join, `realm list` should be run to confirm the domain is active:

```bash
realm list
```

The expected output will show `corp.home.arpa` as the configured realm with `sssd` as the client software and the domain join confirmed. Login access will currently be unrestricted; this will be tightened in Phase Four.

#### 3.4 Active Directory Computer Account Validation

From DC01, the Ubuntu Server computer account should be visible in Active Directory Users and Computers immediately after the join. Because `redircmp` in Lab 03 redirected the default computer container to `OU=Workstations`, the computer account will land there automatically.

Planned validation from DC01 (PowerShell):

```powershell
Get-ADComputer -Filter {Name -eq "ubuntu-server"} -Properties DistinguishedName, OperatingSystem
```

The output should confirm the computer account's distinguished name, OU placement, and DNS hostname.

---

### Phase Four: SSSD Configuration and Access Control

By default, after a successful `realm join`, SSSD permits all domain users to authenticate to the host. This is not the desired behavior. The Ubuntu Server host should only be accessible to members of `Linux-Admins`.

#### 4.1 The Authentication vs. Authorization Distinction

Authentication and authorization are distinct concepts that are frequently conflated. In the context of this lab:

**Authentication** answers the question: "Is this identity valid?"

When a user attempts to log in, SSSD contacts DC01 via Kerberos to verify the user's credentials. If the credentials are valid, authentication succeeds. At this point, Active Directory has confirmed the identity, but the system has not yet decided whether to allow the user in.

**Authorization** answers the question: "Is this identity permitted access to this specific resource?"

A user can be a valid member of the AD domain (`testuser01` is), but still be denied access to a particular system if they are not a member of the appropriate access-control group (`Linux-Admins`).

The `realm permit` mechanism and SSSD's `simple_allow_groups` directive both implement authorization, not authentication. They run after authentication succeeds and determine whether an authenticated identity is permitted to open a session on this specific host.

This distinction is architecturally important. It means that a single AD credential store can serve multiple Linux systems with different authorization policies. `labadmin` might have access to all Linux systems. A developer account might have access to application servers but not infrastructure hosts. The access decisions are controlled per-system through SSSD configuration or group membership, but the identity and credential verification always goes through the same domain controller.

#### 4.2 Restrict Access to Linux-Admins

The access restriction will be implemented by configuring SSSD to only permit members of the `Linux-Admins` group.

The simplest approach uses `realm permit`:

```bash
sudo realm permit -g 'Linux-Admins@corp.home.arpa'
```

This command modifies `/etc/sssd/sssd.conf` to use `simple` access provider with `Linux-Admins@corp.home.arpa` as the permitted group.

Alternatively, the `/etc/sssd/sssd.conf` can be modified directly. After `realm join`, the configuration file will contain an `[domain/corp.home.arpa]` section. The access control directives to add or confirm:

```ini
access_provider = simple
simple_allow_groups = Linux-Admins@corp.home.arpa
```

After modifying `sssd.conf`, the file permissions must be `0600` and owned by `root`. SSSD will refuse to start if the configuration file has incorrect permissions:

```bash
sudo chmod 0600 /etc/sssd/sssd.conf
sudo chown root:root /etc/sssd/sssd.conf
```

SSSD must be restarted after any configuration change:

```bash
sudo systemctl restart sssd
```

#### 4.3 Home Directory Configuration

When an AD user logs into a Linux system for the first time, no local home directory exists for them. The `pam_mkhomedir` PAM module handles automatic home directory creation at login time. The `oddjob-mkhomedir` package installed in Phase Three provides this capability.

The PAM configuration for this is handled by `realm join` automatically when `oddjob-mkhomedir` is installed. The relevant line in `/etc/pam.d/common-session` or the equivalent:

```text
session optional pam_mkhomedir.so skel=/etc/skel umask=0077
```

This line may already be present after `realm join`. If not, it will need to be added. Home directories will be created under `/home/` by default with the format `/home/username@corp.home.arpa` or `/home/username` depending on the `use_fully_qualified_names` setting in `sssd.conf`.

#### 4.4 SSSD Configuration Review

The complete planned `sssd.conf` after Phase Four will look conceptually similar to the following. The exact values will be confirmed against the file written by `realm join` and modified only where necessary:

```ini
[sssd]
domains = corp.home.arpa
config_file_version = 2
services = nss, pam

[domain/corp.home.arpa]
default_shell = /bin/bash
krb5_store_password_if_offline = True
cache_credentials = True
krb5_realm = CORP.HOME.ARPA
realmd_tags = manages-system joined-with-adcli
id_provider = ad
fallback_homedir = /home/%u@%d
ad_domain = corp.home.arpa
use_fully_qualified_names = True
ldap_id_mapping = True
access_provider = simple
simple_allow_groups = Linux-Admins@corp.home.arpa
```

Key directives explained:

| Directive | Purpose |
|---|---|
| `id_provider = ad` | Identity information (UID, GID, groups) sourced from Active Directory |
| `ldap_id_mapping = True` | UIDs and GIDs are derived algorithmically from the AD object's SID rather than requiring explicit uidNumber attributes in AD |
| `access_provider = simple` | Access control uses the simple allow/deny list |
| `simple_allow_groups` | Only members of the listed groups are permitted access |
| `cache_credentials = True` | Allows authentication when DC01 is temporarily unreachable (offline login) |
| `use_fully_qualified_names = True` | Users must be referenced as `username@corp.home.arpa` to avoid ambiguity with local accounts |
| `fallback_homedir` | Home directory path template for AD users without a homeDirectory attribute set in AD |

---

### Phase Five: Identity and Authentication Validation

Validation is the most important part of this lab. Configuration that has not been proven is not complete. This phase validates every layer of the integration from both the Linux side and the Active Directory side.

#### 5.1 Linux-Side Identity Validation

**Realm state:**

```bash
realm list
```

Expected output: `corp.home.arpa` configured as an active-directory realm, SSSD as the client, and the `simple_allow_groups` restriction reflected.

**AD user identity resolution:**

```bash
id labadmin@corp.home.arpa
```

This command asks the operating system to resolve the identity of `labadmin@corp.home.arpa` through NSS. If SSSD is correctly configured and able to reach DC01, the output will return a UID, GID, and group list sourced from Active Directory. A result here proves that Linux identity resolution is now backed by AD, not local files.

```bash
id testuser01@corp.home.arpa
```

`testuser01` is not a member of `Linux-Admins` but is a valid AD user. The `id` command should still return identity information for `testuser01`, because identity resolution and access control are separate. SSSD will resolve the identity of any domain user. Whether that user is permitted to log in is a separate question answered at PAM evaluation time.

**NSS database queries:**

```bash
getent passwd labadmin@corp.home.arpa
getent passwd testuser01@corp.home.arpa
getent group Linux-Admins@corp.home.arpa
```

`getent passwd` queries the system's NSS configuration to retrieve a full passwd-format entry for the specified user. If SSSD is functioning correctly as an NSS provider, these commands will return entries sourced from Active Directory rather than local files. The UID and GID values will be derived from the user's AD SID via SSSD's ID mapping.

`getent group` verifies that AD group membership is visible to the Linux system. The output should show `Linux-Admins@corp.home.arpa` with `labadmin` listed as a member.

#### 5.2 Kerberos Authentication Validation

**Ticket acquisition:**

```bash
kinit labadmin@CORP.HOME.ARPA
```

`kinit` requests a Kerberos Ticket Granting Ticket (TGT) from DC01's Key Distribution Center on behalf of the specified principal. This is a direct authentication test against the domain: it bypasses SSSD entirely and speaks the Kerberos protocol directly to DC01. A successful `kinit` proves that:

- the Ubuntu Server host can reach DC01 on the Kerberos port (TCP/UDP 88)
- DC01's KDC is issuing tickets for the realm
- the keytab and Kerberos configuration on the Ubuntu Server host are correct

After `kinit` succeeds, `klist` displays the current ticket cache:

```bash
klist
```

The output will show a valid TGT for `labadmin@CORP.HOME.ARPA` with a start time, end time, and renew-until time. The encryption type will be AES-256, consistent with what was observed in Lab 03.

After validation, the ticket cache should be cleared:

```bash
kdestroy
```

**What a Kerberos ticket is and how the flow works:**

Kerberos is a mutual authentication protocol built around short-lived cryptographic tokens called tickets. When a user authenticates to a Kerberos-protected service, they do not send their password to the service. Instead, they obtain a TGT from the Key Distribution Center (DC01 in this environment) by proving knowledge of their password. This TGT is then used to obtain service-specific tickets (Service Tickets) for individual services like SSH or LDAP without re-entering credentials.

The KDC never sends passwords over the network. The password is used locally to decrypt a response from the KDC. This design means that credential material is not exposed in transit, and compromising a service does not expose the user's password.

In this environment:

1. The user runs `kinit` or initiates an SSH connection
2. SSSD (or the Kerberos client) sends an Authentication Service Request (AS-REQ) to DC01
3. DC01's KDC responds with an Authentication Service Reply (AS-REP) containing a TGT encrypted with the user's key
4. The client decrypts the TGT using the user's credentials
5. When access to a specific service is needed, the client sends a Ticket Granting Service Request (TGS-REQ) to the KDC, presenting the TGT
6. DC01 issues a Service Ticket (TGS-REP) for the requested service
7. The client presents the Service Ticket to the target service (SSH daemon, LDAP server, etc.)
8. The service validates the ticket using the shared keytab key

SSSD integrates this flow into PAM so that interactive logins and SSH connections trigger the Kerberos exchange automatically.

#### 5.3 SSH Authentication Validation

SSH authentication using Active Directory credentials will be validated from the management workstation or another host on the LAN. The exact username format used in the SSH command will depend on the final SSSD configuration, specifically the `use_fully_qualified_names` setting, and will be confirmed during execution. With fully qualified names enabled, the format is `username@domain`; with them disabled, the short username may work directly. Both will be tested and the working form documented.

**Successful authentication (labadmin - Linux-Admins member):**

After login, the following commands will be run from within the session to confirm the identity is sourced from AD:

```bash
whoami
id
klist
```

`klist` from within the authenticated session will show whether a Kerberos ticket was forwarded or issued during the SSH authentication. The session identity confirmed via `whoami` and `id` should reflect the AD-sourced identity, not a local account.

**Denied authentication (testuser01 - not a Linux-Admins member):**

`testuser01` will be used to attempt SSH access. The expected result is an authentication failure. The exact error will be observed and documented. The failure should occur at the PAM authorization step, not at the Kerberos authentication step. `testuser01` has valid AD credentials and Kerberos will authenticate the identity. The denial happens because SSSD's `simple_allow_groups` check determines that `testuser01` is not a member of `Linux-Admins`.

This distinction is the lab's most important demonstration of the authentication vs. authorization separation described in Phase Four.

#### 5.4 Active Directory-Side Validation

Validation is not complete until the state is confirmed from the Active Directory side as well. The Linux-side commands prove that SSSD is working. The AD-side commands prove the state is correct in the authoritative source.

Planned validation from DC01 (PowerShell):

```powershell
# Confirm the Ubuntu Server computer account exists
Get-ADComputer -Filter {Name -eq "ubuntu-server"} -Properties DistinguishedName, OperatingSystem

# Confirm Linux-Admins group membership
Get-ADGroupMember -Identity "Linux-Admins"

# Confirm labadmin is a member of Linux-Admins
(Get-ADUser labadmin -Properties MemberOf).MemberOf

# Confirm testuser01 is NOT a member of Linux-Admins
(Get-ADUser testuser01 -Properties MemberOf).MemberOf
```

From ADUC (visual validation):

- Computer account for Ubuntu Server visible in `OU=Workstations`
- `Linux-Admins` group visible in `OU=Groups`
- `labadmin` shown as a member of `Linux-Admins` in group properties
- `testuser01` not shown as a member of `Linux-Admins`

---

## Validation Strategy

The validation approach for this lab mirrors the philosophy established in Labs 03, 04, and 05: prove functionality at every layer, from both sides of the integration, before declaring the lab complete.

### Linux-Side Validation Checklist

| Check | Command | Expected Result |
|---|---|---|
| DC01 reachable from Ubuntu Server | `ping -c 4 192.168.1.10` | 0% packet loss |
| Domain name resolves from Ubuntu Server | `nslookup corp.home.arpa 192.168.1.10` | Returns DC01 IP |
| Kerberos SRV record resolves | `nslookup -type=SRV _kerberos._tcp.corp.home.arpa 192.168.1.10` | Returns DC01 |
| LDAP SRV record resolves | `nslookup -type=SRV _ldap._tcp.corp.home.arpa 192.168.1.10` | Returns DC01 |
| Time synchronized | `timedatectl status` | NTP: synchronized |
| Realm discovery successful | `realm discover corp.home.arpa` | Domain type: active-directory |
| Domain join successful | `realm list` | corp.home.arpa, sssd, configured |
| SSSD service running | `systemctl status sssd` | Active (running) |
| labadmin identity resolves | `id labadmin@corp.home.arpa` | UID, GID, groups returned from AD |
| testuser01 identity resolves | `id testuser01@corp.home.arpa` | UID, GID returned (identity is resolvable regardless of access control) |
| NSS passwd entry for labadmin | `getent passwd labadmin@corp.home.arpa` | Entry returned from AD |
| NSS group entry for Linux-Admins | `getent group Linux-Admins@corp.home.arpa` | Group entry with labadmin member |
| Kerberos TGT acquisition | `kinit labadmin@CORP.HOME.ARPA` | Succeeds without error |
| Kerberos ticket visible | `klist` | TGT for labadmin@CORP.HOME.ARPA |
| SSH login: labadmin (permitted) | username format confirmed during execution | Session opened |
| Session identity correct | `whoami` from within session | labadmin@corp.home.arpa (or short form per SSSD config) |
| SSH login: testuser01 (denied) | username format confirmed during execution | Access denied |

### Active Directory-Side Validation Checklist

| Check | Method | Expected Result |
|---|---|---|
| Ubuntu Server computer account exists | `Get-ADComputer` / ADUC | Visible in OU=Workstations |
| Computer account OU placement confirmed | DistinguishedName property | CN=ubuntu-server,OU=Workstations,DC=corp,DC=home,DC=arpa |
| Linux-Admins group exists | ADUC / Get-ADGroup | Visible in OU=Groups |
| labadmin is member of Linux-Admins | `Get-ADGroupMember` | labadmin listed as member |
| testuser01 is NOT member of Linux-Admins | `Get-ADUser MemberOf` | Linux-Admins absent from testuser01's memberships |

### Two-Sided Validation Principle

The most important validation events in this lab require proving a claim from both sides simultaneously. The SSH denial test is the clearest example: the Linux side shows `testuser01` is denied. The AD side shows `testuser01` is not a member of `Linux-Admins`. The two observations together prove the authorization is working correctly, not just that something went wrong on one side. Each layer of the integration has both a Linux-facing proof and an AD-facing proof.

---

## Potential Issues and Considerations

### DNS Configuration on Ubuntu Server

Ubuntu Server 26.04 uses `systemd-resolved` as its default DNS resolver. In some configurations, the DNS search domains and upstream resolvers are managed through `/etc/systemd/resolved.conf` and the link-local stub resolver at `127.0.0.53`. In others, `/etc/resolv.conf` is a symlink to the resolved stub.

The critical outcome is that the host can resolve `corp.home.arpa` SRV records. This requires that either:

- The host is configured to use DC01 (`192.168.1.10`) directly as its DNS server, or
- The host's upstream resolver can forward queries for `corp.home.arpa` to DC01

The test in Phase Two (SRV record resolution) will reveal whether the current configuration satisfies this requirement. If it does not, the DNS configuration must be corrected before proceeding. `realm discover` will fail with a confusing error if SRV records are not resolvable.

### Time Synchronization

Kerberos clock skew failures produce errors like `kinit: Clock skew too great while getting initial credentials`. These are easy to misread as network or configuration problems. The pre-join time validation in Phase Two exists specifically to catch this before it becomes a troubleshooting scenario.

In the lab environment, both DC01 and the Ubuntu Server host are on the same LAN with access to public NTP servers. Significant clock drift is unlikely but should be verified rather than assumed.

### SSSD Configuration File Permissions

SSSD is deliberately strict about its configuration file. If `/etc/sssd/sssd.conf` is not owned by `root` with mode `0600`, SSSD will refuse to start. The error in the systemd journal will reference configuration file permissions. This is a common issue after manually editing the file and is resolved by:

```bash
sudo chmod 0600 /etc/sssd/sssd.conf
sudo chown root:root /etc/sssd/sssd.conf
sudo systemctl restart sssd
```

### Fully Qualified User Names

With `use_fully_qualified_names = True` in `sssd.conf`, all AD users must be referenced using their full principal name (`labadmin@corp.home.arpa`). This prevents ambiguity between local accounts and AD accounts with the same short name. Commands like `id labadmin` (without the domain suffix) will return the local `labadmin` account if one exists. Commands like `id labadmin@corp.home.arpa` will return the AD account.

The impact on SSH username syntax will be confirmed during execution and documented in the completed lab.

### UID and GID Mapping

AD users do not have Unix UID and GID attributes set by default. SSSD's `ldap_id_mapping = True` resolves this by deriving UID and GID values algorithmically from the user's AD SID. The mapping is deterministic: the same user on the same domain will always get the same UID on any SSSD-joined Linux host using the same algorithm. This is acceptable for the lab environment.

In a production environment with shared filesystems (NFS), consistent UID/GID values across hosts matter significantly. The algorithmic mapping handles this well for simple environments, but environments with pre-existing Unix UID requirements would set `ldap_id_mapping = False` and configure uidNumber and gidNumber attributes in Active Directory directly.

### SSSD Caching

SSSD caches identity and authentication information locally to handle periods when DC01 is unreachable. With `cache_credentials = True`, users who have previously authenticated can continue to log in even if DC01 is temporarily down. In the lab environment this is convenient but also means that access policy changes (such as removing a user from `Linux-Admins`) may not take effect immediately. The SSSD cache can be flushed manually:

```bash
sudo sss_cache -E
```

Or by restarting SSSD:

```bash
sudo systemctl restart sssd
```

---

## Expected Outcomes

At the conclusion of this lab, the following state is expected:

**Active Directory:**

- `Linux-Admins` security group created in `OU=Groups`
- `labadmin` is a member of `Linux-Admins`
- `testuser01` is not a member of `Linux-Admins`
- Ubuntu Server computer account present in `OU=Workstations`

**Ubuntu Server:**

- Joined to the `corp.home.arpa` domain
- SSSD running and communicating with DC01
- Identity for AD users resolvable via `id` and `getent`
- Access restricted to members of `Linux-Admins@corp.home.arpa`
- Kerberos ticket acquisition working via `kinit`
- SSH authentication using AD credentials functional for permitted users
- SSH authentication denied for non-permitted users

**Validated behavior:**

- `labadmin@corp.home.arpa` can authenticate via SSH and open a session
- `testuser01@corp.home.arpa` is denied access at the PAM authorization step
- AD identity is visible to the Linux system via NSS
- Kerberos tickets are issued by DC01 and visible via `klist`

---

## Post-Lab State

After this lab, the `corp.home.arpa` domain will be the authoritative identity provider for both Windows and Linux systems in the environment. The Ubuntu Server host will authenticate and authorize users through Active Directory. The same `labadmin` credentials that administer DC01 and WIN11-CLIENT01 will authenticate to the Ubuntu Server host. Identity is centralized.

This completes the first convergence between the Linux Infrastructure track and the Enterprise Infrastructure track. The environment now represents a basic hybrid identity platform: Windows domain controller, Windows domain-joined workstation, Linux domain-joined server, all sharing a single identity source.

**Post-Lab Snapshot:**

Once all validation is complete, a snapshot will be created for DC01.

Planned snapshot name:

```text
DC01 - Linux Integration Complete
```

Planned snapshot description:

```text
Linux-Admins security group created in OU=Groups. labadmin added as member.
Ubuntu Server joined to corp.home.arpa. SSSD configured with Linux-Admins
access restriction. Identity resolution, Kerberos authentication, SSH access
for labadmin, and SSH denial for testuser01 all validated. AD-side computer
account and group membership confirmed. Hybrid identity platform operational.
```

The Ubuntu Server host is a physical machine and is not snapshotted. The SSSD and domain join configuration on Ubuntu Server can be reversed by:

1. Running `sudo realm leave corp.home.arpa` to remove the domain join
2. Removing the SSSD packages if a clean slate is needed
3. Deleting the computer account from AD manually after leaving the domain

**The environment is now ready for:**

- Security monitoring and event collection via Wazuh (Lab 07): both Windows and Linux endpoints are in scope, and having centralized identity in place means log events will carry consistent AD identities across platforms
- Future Linux infrastructure expansion: any additional Linux hosts can join `corp.home.arpa` and inherit the same identity and access control infrastructure established here
- Windows metrics export into the Prometheus and Grafana monitoring stack

---

## Research Notes

### Why DNS Is the Foundation of Kerberos

Kerberos authentication does not use IP addresses to locate the KDC. It uses DNS SRV records to discover where the Key Distribution Center is listening. When a client attempts to authenticate to `CORP.HOME.ARPA`, it issues a DNS query for `_kerberos._tcp.corp.home.arpa` to find the KDC's hostname and port. If this query fails, Kerberos cannot proceed, and the failure mode is often a generic "cannot contact KDC" error that does not clearly identify DNS as the root cause.

This is why Phase Two validates SRV record resolution before touching SSSD or attempting realm discovery. The SRV record test is the real pre-flight check. Basic hostname resolution (`ping corp.home.arpa`) is insufficient on its own because it tests only A record resolution, not the SRV records that Kerberos and LDAP depend on.

### SSSD Architecture: AD Provider, PAM, and NSS

SSSD is a daemon that acts as a broker between the local operating system's identity and authentication interfaces and one or more remote identity providers. In this lab, the provider is Active Directory.

The operating system accesses identity information through the Name Service Switch (NSS) interface. When a process calls `getpwnam("labadmin@corp.home.arpa")`, NSS consults `/etc/nsswitch.conf` to determine which backends to query. With SSSD configured as an NSS provider, the query is routed to SSSD, which contacts Active Directory via LDAP to retrieve the user's attributes and returns them in the standard passwd format.

Authentication goes through PAM (Pluggable Authentication Modules). PAM is a framework that routes authentication requests through a configurable stack of modules. With SSSD configured as a PAM provider, authentication requests are routed to SSSD, which performs a Kerberos AS-REQ against DC01 to verify the credential. SSSD then checks the access provider (in this lab, `simple`) to determine whether the authenticated identity is permitted. If both checks pass, PAM returns success and the session is opened.

This architecture is what makes the authentication vs. authorization distinction concrete. NSS handles identity resolution (who is this user). PAM handles authentication (is this credential valid) and authorization (is this user permitted here). They are separate subsystems with separate configuration paths, and SSSD bridges both.

### Why realmd Over Manual Configuration

Manually configuring Kerberos and LDAP for AD integration involves maintaining `/etc/krb5.conf`, `/etc/ldap/ldap.conf`, and an `sssd.conf` by hand, coordinating their values, and ensuring the keytab is created and populated correctly. `realmd` handles all of this as an atomic operation: it discovers the realm, negotiates the join, writes the configuration files, and registers the keytab. The result is a configuration that is consistent and that matches what the AD domain actually advertises, rather than a manually maintained configuration that may drift.

`realmd` is also the operationally correct tool for this environment because it is the integration layer tested and maintained by the upstream SSSD developers for Active Directory compatibility. Using it means inheriting a known-good configuration baseline rather than starting from scratch.

### ID Mapping and the SID-to-UID Algorithm

Windows systems identify users and groups using Security Identifiers (SIDs). Linux systems use integer UIDs and GIDs. These are fundamentally different identity namespaces with no inherent correspondence.

SSSD's `ldap_id_mapping = True` bridges this gap by deriving a UID from the user's SID using a consistent hash algorithm. The algorithm takes the domain SID and the user's relative identifier (RID) within that domain and produces a UID in a configurable range. The same input always produces the same output, so the UID for a given AD user is stable across all Linux hosts in the domain that use the same algorithm and range configuration.

This approach works well for environments where Linux systems do not share filesystems. File ownership on the Ubuntu Server host will be consistent with itself. If two SSSD-joined Linux hosts are compared, the UID for a given user will be the same on both (assuming identical SSSD configuration), which is sufficient for most use cases.

The alternative, `ldap_id_mapping = False`, requires that uidNumber and gidNumber attributes are explicitly set on user and group objects in Active Directory. This is the correct approach for environments with NFS-mounted filesystems where consistent UID/GID values across hosts are required for file permission correctness. It is not necessary for this lab.

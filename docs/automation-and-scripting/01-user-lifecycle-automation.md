# 01 - User Lifecycle Automation

## Status

In progress

---

## Overview

This lab replaces the manual account provisioning and offboarding workflow used throughout the enterprise infrastructure track with a scripted, repeatable PowerShell process against the existing `corp.home.arpa` Active Directory domain.

Every user account created during the enterprise infrastructure track (`labadmin`, `testuser01`, established during the Active Directory and Linux/AD integration labs) was created by hand through Active Directory Users and Computers: create the account, assign it to the correct OU, add it to the correct security groups, and separately validate that the resulting access behaves as expected on both Windows and Linux. That process is slow, error-prone at scale, and undocumented as a repeatable procedure. This lab formalizes it into two scripts, `New-LabUser.ps1` and `Remove-LabUser.ps1`, that produce the same result every time and validate their own output.

This is the first lab in the Infrastructure Automation and Scripting track (ADR-015) and does not introduce any new infrastructure. It automates administration of infrastructure that already exists and is fully operational.

---

## Objectives

- provision a new AD user account with a single script, including OU placement and group assignment
- support an optional Linux access path (`Linux-Admins` group membership) that is provable via SSH, not just AD group state
- offboard a user with a single script: disable the account, remove its removable security-group memberships while preserving the AD account object, and confirm Linux access is denied afterward
- validate every provisioning and offboarding action by querying the result back from AD rather than assuming success from exit code alone
- document the cross-platform validation gap between AD state changes and SSSD's cached view of that state, since this is a required troubleshooting step not a script defect

---

## Project Context

The enterprise infrastructure track built a fully operational identity plane: Active Directory on DC01, a domain-joined Windows client, and an Ubuntu Server host authenticating through SSSD and Kerberos. Every subsequent lab (Group Policy, Linux/AD integration, Wazuh enrollment) depended on that identity plane but none of them automated it. Account creation has been manual since Lab 03.

ADR-014 identified automation as the highest-priority next track specifically because the AD environment is a fully operational automation target that requires no new infrastructure. ADR-015 scoped that track to be AD-centric: PowerShell against the Active Directory and Group Policy modules, with Docker, Linux, and Wazuh appearing only as supporting validation, not as parallel automation subjects.

This lab is the first practical output of that scope. It picks the highest-value, most frequently repeated manual task, user lifecycle management, and automates it end to end, including the cross-platform proof that Lab 06 established by hand: that AD group membership determines SSH access on Ubuntu Server through SSSD and PAM.

---

## Design Decisions

### Script execution location

Scripts in this lab run from WIN11-CLIENT01 via RSAT, not on DC01. This is a track-wide convention rather than a Lab 01-specific choice, and is documented in [ADR-016: Run Automation Scripts from a Domain-Joined Client, Not the Domain Controller](../architecture/decisions/016-run-automation-scripts-from-domain-joined-client.md).

### Parameter design

**Decision:** Scripts accept individual named parameters for single-user provisioning in this lab. CSV-based bulk provisioning is deferred rather than built in now.

A bulk CSV path is a reasonable production feature but it roughly doubles the validation surface for this lab (malformed rows, partial-failure handling, per-row rollback) without adding to the core objective, which is proving that one script can take a user from "does not exist" to "provisioned and validated on Windows and Linux." Single-user parameters keep the lab focused on that path. Bulk provisioning is a natural candidate for a later lab in this track if it turns out to be worth the added complexity.

---

## Technologies Used

- PowerShell 5.1 / Active Directory module (RSAT, run from WIN11-CLIENT01)
- Active Directory Domain Services (DC01)
- SSSD and PAM (Ubuntu Server)
- Existing OU structure: `OU=User Accounts`, `OU=IT`, `OU=Workstations`, `OU=Groups`
- Existing security groups: `IT-Admins`, `Domain-Users-Standard`, `Linux-Admins`

---

## Architecture or Topology

```text
WIN11-CLIENT01 (RSAT / PowerShell AD module)
        |
        | New-LabUser.ps1 / Remove-LabUser.ps1
        v
     DC01 (Active Directory Domain Services)
        |
        | account state: OU placement, group membership
        v
  Ubuntu Server (SSSD + PAM, corp.home.arpa realm join)
        |
        | id / getent / ssh
        v
  Validation: account resolves and SSH succeeds only if
  the user is a member of Linux-Admins
```

Provisioning and offboarding both originate from WIN11-CLIENT01 against DC01. Validation of the Linux access path requires a second, independent check directly against Ubuntu Server, since AD group membership and SSSD's resolution of that membership are not guaranteed to be instantaneous or automatically in sync.

---

## Prerequisites

- DC01 running Active Directory Domain Services and AD-integrated DNS (Lab 03)
- WIN11-CLIENT01 domain-joined with RSAT installed, Active Directory module available (Lab 02, Lab 04); this is the required script execution endpoint per [ADR-016](../architecture/decisions/016-run-automation-scripts-from-domain-joined-client.md)
- Ubuntu Server joined to `corp.home.arpa` with SSSD, Kerberos, and `simple_allow_groups = Linux-Admins@corp.home.arpa` operational (Lab 06)
- `Linux-Admins`, `IT-Admins`, and `Domain-Users-Standard` security groups already exist in `OU=Groups`
- An account with sufficient AD permissions to create, modify, and disable users (`labadmin`)

---

## Implementation

### Step One - Define Script Parameters and Pre-Flight Duplicate Check

The script's parameters will be defined, establishing which values are required at runtime and which fall back to defaults: name fields, `SamAccountName`, target OU, role group, an optional Linux access switch, and the initial password. A pre-flight check will then query Active Directory for an existing account with the same `SamAccountName` so that a duplicate is caught before any object is created.

### Step Two - Implement Account Creation and Group Assignment

Account creation will be implemented using `New-ADUser` to create the account in the target OU, followed by `Add-ADGroupMember` to assign the specified role group and, when Linux access is requested, `Linux-Admins`.

### Step Three - Implement Validation Logic

Validation logic will be added to query Active Directory after creation using `Get-ADUser` and `Get-ADPrincipalGroupMembership`, confirming that the account exists, is enabled, resides in the correct OU, and holds the expected group memberships, rather than relying on the success of the preceding cmdlets.

### Step Four - Run New-LabUser.ps1 Against a Test Account

The completed script will be run against a test account from WIN11-CLIENT01. The resulting output will be recorded, including any errors or mismatches surfaced by the validation logic.

### Step Five - Confirm Linux Access via SSH

SSH access to the Ubuntu Server host will be tested for the provisioned account. An account created with Linux access is expected to authenticate successfully; an account created without it is expected to be denied at the PAM authorization step, consistent with `testuser01` behavior in Lab 06.

### Step Six - Write Remove-LabUser.ps1

The offboarding script will be written to disable the account, remove its removable group memberships while leaving the primary group intact, and validate the resulting state by querying Active Directory.

### Step Seven - Run Remove-LabUser.ps1 Against the Test Account

The offboarding script will be run against the account provisioned in Step Four, and its output recorded.

### Step Eight - Confirm SSH Access Denied After Offboarding

SSH access will be attempted as the offboarded account to confirm that access is denied. Whether the SSSD cache delay described in the Troubleshooting section was encountered will be noted.

---

## Validation

Validation will confirm:

- new account confirmed to exist in the correct OU via `Get-ADUser`
- group membership confirmed via `Get-ADPrincipalGroupMembership`
- with `-LinuxAccess`, SSH login to Ubuntu Server succeeds and creates a home directory on first login
- without `-LinuxAccess`, SSH login to Ubuntu Server is denied at the PAM authorization step, consistent with `testuser01` behavior in Lab 06
- offboarded account confirmed disabled via `Get-ADUser`, with removable security-group memberships stripped via `Get-ADPrincipalGroupMembership` (the account object itself and its primary group are expected to remain, see Troubleshooting)
- offboarded account's SSH access confirmed denied on Ubuntu Server

---

## Troubleshooting

Two issues are anticipated:

**Primary group cannot be removed via `Remove-ADPrincipalGroupMembership`.** Every AD user has a primary group (Domain Users by default, RID 513). `Remove-ADPrincipalGroupMembership` cannot remove a user from their primary group and will error if asked to. An offboarding script that naively pipes every group returned by `Get-ADPrincipalGroupMembership` into removal will fail on the primary group. The intended behavior is therefore to remove *removable* security-group memberships, not literally all groups. The implementation must confirm what `Get-ADPrincipalGroupMembership` returns for the account and filter the primary group out of the removal set. This is why the offboarding language throughout this doc says "removable security-group memberships" rather than "all groups."

**SSSD cache delay.** SSSD caching may cause a delay between an AD-side group membership change and Ubuntu Server correctly reflecting it. If this occurs during validation, document the cache behavior and the targeted `sss_cache` invalidation step required (`sss_cache -u <user>` or `-g <group>`), rather than treating it as a script defect. Per the SSSD documentation, `sss_cache` invalidates rather than deletes cached records, so SSSD re-pulls from AD on the next lookup while retaining offline fallback.

---

## Security Considerations

Not yet started. To address: least-privilege for the account running the scripts, avoiding plaintext password handling for initial credentials, and confirming `Remove-LabUser.ps1` disables rather than deletes accounts so no AD object history or SID is lost.

---

## Outcome

Not yet started.

---

## Lessons Learned

Not yet started.

---

## Sources

Research references consulted during the planning phase of this lab.

**Active Directory PowerShell module (Microsoft Learn)**

- [New-ADUser](https://learn.microsoft.com/en-us/powershell/module/activedirectory/new-aduser) - core provisioning cmdlet; `SamAccountName` is required, `Path` sets OU placement, accounts created without a password are disabled by default
- [Set-ADUser](https://learn.microsoft.com/en-us/powershell/module/activedirectory/set-aduser) - modifying existing account properties post-creation
- [Get-ADPrincipalGroupMembership](https://learn.microsoft.com/en-us/powershell/module/activedirectory/get-adprincipalgroupmembership) - used for validation (confirming group assignment) and as the input to offboarding group removal
- [Remove-ADPrincipalGroupMembership](https://learn.microsoft.com/en-us/powershell/module/activedirectory/remove-adprincipalgroupmembership) - removes removable security-group memberships during offboarding; accepts piped identity objects from `Get-ADPrincipalGroupMembership`, but cannot remove a user's primary group
- [Disable-ADAccount](https://learn.microsoft.com/en-us/powershell/module/activedirectory/disable-adaccount) - disables rather than deletes the account object during offboarding

**SSSD cache behavior (Red Hat / upstream SSSD docs)**

- [Managing the SSSD Cache - Red Hat Enterprise Linux Deployment Guide](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/6/html/deployment_guide/sssd-cache) and the [System-Level Authentication Guide troubleshooting appendix](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/7/html/system-level_authentication_guide/trouble) - confirms `sss_cache` invalidates cached records so SSSD re-pulls them from AD on next lookup, rather than clearing the cache outright
- [sss_cache(8) man page](https://linux.die.net/man/8/sss_cache) - flag reference (`-u` for a single user, `-g` for a single group) used to plan targeted cache invalidation for validation rather than a full cache flush
- [How To Clear The SSSD Cache In Linux](https://www.rootusers.com/how-to-clear-the-sssd-cache-in-linux/) - clarifies that `sss_cache` marks entries expired rather than deleting them, which preserves offline fallback if AD is briefly unreachable during validation

**Account offboarding practice (disable vs. delete)**

- [Delete or Disable an Active Directory Account? One Best Practice - Imanami](https://www.imanami.com/delete-or-disable-an-active-directory-account-one-best-practice/) - summarizes the standard tradeoff: disabling preserves the SID and account history for reversibility and auditing, deleting removes access immediately but is not easily reversible
- [Best Practices - Disabling Users in Active Directory - ITAdminTools](https://www.itadmintools.com/2013/08/best-practices-disabling-users-in.html) - supports the offboarding approach used here (disable, remove removable group memberships, retain the account object) over outright deletion

These sources informed the Design Decisions and Troubleshooting sections above.

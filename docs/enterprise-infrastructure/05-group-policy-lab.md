# 05 - Group Policy Lab

## Status

Planning and research phase.

---

## Overview

This lab designs, deploys, and validates a foundational Group Policy infrastructure for the `corp.home.arpa` domain. It builds directly on the identity foundation from Lab 03 and the domain-joined workstation from Lab 04.

The lab demonstrates three core Group Policy targeting models:

1. **OU-linked computer policy** — applied to machine accounts at boot, scoped to `OU=Workstations`
2. **OU-linked user policy** — applied to user accounts at logon, scoped to `OU=User Accounts` and `OU=IT`
3. **Security group filtered policy** — restricts GPO application to members of a specific security group, independent of OU placement

These are the mechanisms that enterprise endpoint management is built on. The specific settings configured within each GPO matter less than understanding how targeting, linking, inheritance, and filtering interact to produce a resultant policy on the client.

Labs 03 and 04 established the infrastructure that Group Policy depends on: a functioning domain controller, AD-integrated DNS, a clean OU structure, domain accounts with appropriate group memberships, and a domain-joined Windows 11 workstation with a confirmed computer account in `OU=Workstations`. Lab 05 puts that foundation to use.

The planned deployment covers:

- auditing the current Group Policy baseline before making any changes
- creating a security baseline GPO for domain workstations
- creating a user environment policy GPO scoped to standard users
- creating a separate administrator environment GPO scoped to IT accounts
- validating policy application and inheritance on WIN11-CLIENT01
- testing security group filtering as an alternative targeting mechanism
- documenting the final GPO structure as a reference for Lab 06 and beyond

The `Default Domain Policy` and `Default Domain Controllers Policy` will not be modified. All custom settings will be deployed in purpose-built GPOs linked to specific OUs.

---

## Objectives

- audit the current Group Policy state on WIN11-CLIENT01 before introducing any custom GPOs
- design a GPO structure aligned with the OU hierarchy created in Lab 03
- create and link a workstation security baseline GPO scoped to `OU=Workstations`
- create and link a standard user environment GPO scoped to `OU=User Accounts`
- create and link an IT administrator environment GPO scoped to `OU=IT`
- validate GPO application using `gpupdate /force` and `gpresult /r` on WIN11-CLIENT01
- validate that `testuser01` receives user-scoped policies and computer-scoped policies from the workstations OU
- validate that `labadmin` receives IT-scoped policy and not standard user restrictions
- validate security group filtering on the `Workstation-Security-Baseline` GPO using the `Lab-Workstations` group
- enumerate and inspect all GPOs and inheritance using Group Policy PowerShell cmdlets
- generate an RSoP HTML report from the client
- create post-GPO snapshots for both VMs

---

## Project Context

Lab 03 created the OU structure specifically to support this lab. The four OUs (`IT`, `User Accounts`, `Workstations`, `Groups`) were chosen because they map directly to the three GPO scopes planned here: computer policy for workstations, user policy for standard users, and user policy for IT administrators.

Lab 04 confirmed that Group Policy processing was functioning before any custom GPOs were written. The `gpresult /r` output from Lab 04 showed `Default Domain Policy` being applied from DC01 with no errors, and the computer account in `OU=Workstations` and the user accounts in their respective OUs were all correctly reflected in the policy output. That baseline makes Lab 05 troubleshooting significantly easier because the pre-GPO state is documented precisely.

WIN11-CLIENT01 is the primary validation target. With its computer account in `OU=Workstations` and `testuser01` in `OU=User Accounts`, the workstation will receive both computer-scoped and user-scoped policies when they are applied to the correct OUs. `labadmin` in `OU=IT` will receive a separate policy environment, demonstrating that different OU populations can be governed by distinct GPOs.

`labadmin` and `testuser01` live in entirely separate OUs. The IT-Admin-Environment GPO does not override the Standard-User-Environment GPO; it simply does not apply to `labadmin` at all because `labadmin` is not in `OU=User Accounts`. This is OU-based policy targeting, not GPO precedence or inheritance conflict resolution. That distinction is important and will be reflected in the documentation throughout.

---

## Technologies Used

- Group Policy Management Console (GPMC)
- Group Policy Object Editor
- Active Directory Users and Computers (ADUC)
- Windows Server 2022 Standard Evaluation
- Windows 11 Enterprise Evaluation
- PowerShell (`gpupdate`, `gpresult`, `Get-GPO`, `Get-GPInheritance`, `Get-GPResultantSetOfPolicy`)
- Resultant Set of Policy (RSoP)
- Security Group Policy filtering

---

## Planned Architecture and Topology

After this lab, the Group Policy structure will be:

```text
corp.home.arpa [domain]
│
├── Default Domain Policy [existing, not modified]
│
├── Domain Controllers [OU]
│   ├── Default Domain Controllers Policy [existing, not modified]
│   └── DC01.corp.home.arpa
│
├── IT [OU]
│   ├── IT-Admin-Environment GPO [new]
│   └── labadmin
│
├── User Accounts [OU]
│   ├── Standard-User-Environment GPO [new]
│   └── testuser01
│
├── Workstations [OU]
│   ├── Workstation-Security-Baseline GPO [new]
│   └── WIN11-CLIENT01 (computer account)
│
└── Groups [OU]
    ├── IT-Admins
    ├── Domain-Users-Standard
    └── Lab-Workstations
```

### Planned GPO Inheritance Flow

```text
Domain Level
    Default Domain Policy (password policy, account lockout)
            ↓
OU=Workstations
    Workstation-Security-Baseline GPO
    (applied to WIN11-CLIENT01 computer account)

OU=User Accounts
    Standard-User-Environment GPO
    (applied to testuser01 at logon)

OU=IT
    IT-Admin-Environment GPO
    (applied to labadmin at logon)
```

---

## Prerequisites

- Lab 03 completed and validated
- Lab 04 completed and validated
- DC01 post-domain-join snapshot (`DC01 - Domain Join Complete`) available and verified
- WIN11-CLIENT01 post-domain-join snapshot (`WIN11-CLIENT01 - Domain Joined`) available and verified
- DC01 at static IP `192.168.1.10` with RDP operational
- WIN11-CLIENT01 domain-joined to `corp.home.arpa` with computer account in `OU=Workstations`
- Domain accounts operational: `labadmin` (Domain Admins, IT-Admins), `testuser01` (Domain-Users-Standard)
- OU structure intact: IT, User Accounts, Workstations, Groups
- Security groups intact: IT-Admins, Domain-Users-Standard, Lab-Workstations
- Group Policy Management Console accessible from WIN11-CLIENT01 via RSAT
- Both VMs powered on and accessible before beginning

---

## Planned GPO Design

### GPO 1: Workstation-Security-Baseline

Linked to: `OU=Workstations`
Applied to: computer accounts (WIN11-CLIENT01)
Scope: computer configuration only (User Configuration section disabled within the GPO)

Planned settings:

| Setting | Location | Planned Value |
|---|---|---|
| Interactive logon: machine inactivity limit | Computer > Windows Settings > Security Settings > Local Policies > Security Options | 900 seconds (15 minutes) |
| Windows Firewall: Domain profile state | Computer > Windows Settings > Security Settings > Windows Firewall | On |
| Audit account logon events | Computer > Windows Settings > Security Settings > Local Policies > Audit Policy | Success and Failure |
| Audit logon events | Computer > Windows Settings > Security Settings > Local Policies > Audit Policy | Success and Failure |

Note: `Prevent access to registry editing tools` is a user restriction and belongs in a user-scoped GPO if used at all. It is not appropriate for a computer-scoped baseline because it would affect all users on the machine, including administrators. It is not included here.

The User Configuration section of this GPO will be disabled in GPMC (GPO Properties > Details tab > GPO Status: User configuration settings disabled). This improves processing performance and makes the scope of the GPO unambiguous.

---

### GPO 2: Standard-User-Environment

Linked to: `OU=User Accounts`
Applied to: user accounts (`testuser01`)
Scope: user configuration only (Computer Configuration section disabled within the GPO)

Planned settings:

| Setting | Location | Planned Value |
|---|---|---|
| Prevent access to Control Panel and PC Settings | User > Administrative Templates > Control Panel | Enabled |
| Remove Run menu from Start Menu | User > Administrative Templates > Start Menu and Taskbar | Enabled |
| Prevent changing desktop and display settings | User > Administrative Templates > Control Panel > Display | Enabled |
| Hide Network settings pages | User > Administrative Templates > Network | Enabled |

Note: `Disable access to command prompt` and the `Do not run specified Windows applications` blocklist (cmd.exe, regedit.exe, powershell.exe) have been removed from this GPO. PowerShell and cmd access will be needed on the `testuser01` session for validation work in Labs 06 and 07. The settings above demonstrate policy application effectively without handicapping the account for future lab use.

---

### GPO 3: IT-Admin-Environment

Linked to: `OU=IT`
Applied to: user accounts (`labadmin`)
Scope: user configuration only (Computer Configuration section disabled within the GPO)

Purpose: demonstrates that separate user environment policies can be targeted to different OU populations. Because `labadmin` resides in `OU=IT` and `testuser01` resides in `OU=User Accounts`, these users receive entirely different GPOs. This is OU-based policy targeting, not GPO override or precedence. There is no inheritance conflict between these two GPOs.

Planned settings:

| Setting | Location | Planned Value |
|---|---|---|
| Desktop Wallpaper | User > Administrative Templates > Desktop > Desktop | A distinct solid color or path (e.g. `C:\Windows\Web\Wallpaper\Windows\img0.jpg`) |
| Wallpaper Style | User > Administrative Templates > Desktop > Desktop | Fill |

Note on the previous design: an earlier version of this GPO used `Interactive logon: Message title` and `Interactive logon: Message text` from Security Options. Those settings are computer-scoped, not user-scoped. The logon banner appears before Windows knows which user is logging in, so it cannot be targeted through User Configuration. It lives under `Computer Configuration > Windows Settings > Security Settings > Local Policies > Security Options` and applies to all logons on the machine regardless of which user account is used. It has been removed from this GPO accordingly.

The wallpaper setting is genuinely user-scoped, applies at logon, and produces an immediately visible result: `labadmin` sessions will show a distinct desktop wallpaper while `testuser01` sessions will not. This cleanly demonstrates that a separate user policy is being applied to the IT OU population without restricting the account in any way that would affect future lab operations.

---

## Planned Deployment Steps

### Step One - Audit the Pre-GPO Baseline

Before creating any GPOs, the current policy state on WIN11-CLIENT01 will be documented. This produces an unambiguous record of what was in place before any custom Group Policy was applied.

From an elevated PowerShell session on WIN11-CLIENT01:

```powershell
gpresult /r
gpresult /h C:\gpresult-baseline.html
```

The baseline report should show only `Default Domain Policy` in the applied GPOs list with no errors and correct OU placement for both the computer and user accounts.

The Group Policy PowerShell module will also be used to enumerate the existing state on DC01:

```powershell
Get-GPO -All

Get-GPInheritance -Target "OU=Workstations,DC=corp,DC=home,DC=arpa"
Get-GPInheritance -Target "OU=User Accounts,DC=corp,DC=home,DC=arpa"
Get-GPInheritance -Target "OU=IT,DC=corp,DC=home,DC=arpa"
```

`Get-GPO -All` lists all GPO objects in the domain. At baseline, only `Default Domain Policy` and `Default Domain Controllers Policy` should be present. `Get-GPInheritance` shows the GPO links and inheritance state for a given OU, which provides a clean before-state to compare against after the custom GPOs are deployed.

---

### Step Two - Review the Default Domain Policy

Before creating custom GPOs, the existing Default Domain Policy will be reviewed in GPMC to document what is already configured at the domain level.

Key settings to note:

- Password policy (minimum length, complexity, history, maximum age)
- Account lockout policy (threshold, duration, observation window)
- Kerberos policy (ticket lifetime, renewal, enforcement)

These settings will not be modified. They are the domain-wide baseline that all accounts and workstations inherit and cannot be overridden by OU-linked GPOs for password and account lockout settings specifically.

---

### Step Three - Create the Workstation Security Baseline GPO

In GPMC on DC01 (accessed via RDP or RSAT from WIN11-CLIENT01):

1. Navigate to `Group Policy Objects`
2. Create a new GPO named `Workstation-Security-Baseline`
3. Edit the GPO to configure the planned computer settings
4. Open GPO Properties > Details tab > set GPO Status to `User configuration settings disabled`
5. Link the GPO to `OU=Workstations`

The link is what activates the GPO. Creating the GPO object and linking it are separate operations in GPMC.

PowerShell equivalent:

```powershell
New-GPO -Name "Workstation-Security-Baseline"
New-GPLink -Name "Workstation-Security-Baseline" `
           -Target "OU=Workstations,DC=corp,DC=home,DC=arpa"
```

---

### Step Four - Create the Standard User Environment GPO

In GPMC:

1. Create a new GPO named `Standard-User-Environment`
2. Edit the GPO to configure the planned user settings
3. Open GPO Properties > Details tab > set GPO Status to `Computer configuration settings disabled`
4. Link the GPO to `OU=User Accounts`

PowerShell equivalent:

```powershell
New-GPO -Name "Standard-User-Environment"
New-GPLink -Name "Standard-User-Environment" `
           -Target "OU=User Accounts,DC=corp,DC=home,DC=arpa"
```

---

### Step Five - Create the IT Administrator Environment GPO

In GPMC:

1. Create a new GPO named `IT-Admin-Environment`
2. Edit the GPO to configure the planned IT user settings
3. Open GPO Properties > Details tab > set GPO Status to `Computer configuration settings disabled`
4. Link the GPO to `OU=IT`

PowerShell equivalent:

```powershell
New-GPO -Name "IT-Admin-Environment"
New-GPLink -Name "IT-Admin-Environment" `
           -Target "OU=IT,DC=corp,DC=home,DC=arpa"
```

---

### Step Six - Force Policy Update and Validate on WIN11-CLIENT01

From an elevated PowerShell session on WIN11-CLIENT01:

```powershell
gpupdate /force
gpresult /r
```

The `gpresult /r` output should now show the custom GPOs in the applied list. Expected results depend on the user context being evaluated.

When logged in as CORP\testuser01:

- Computer policy: Workstation-Security-Baseline
- User policy: Standard-User-Environment

When logged in as CORP\labadmin:

- Computer policy: Workstation-Security-Baseline
- User policy: IT-Admin-Environment

The gpresult output should show the custom GPOs linked to the appropriate OUs. Default domain policies may also appear depending on scope and reporting context.

Separate `gpresult /r` runs will be performed for each user session because Group Policy reports only the currently logged-in user's policy scope.

The Group Policy PowerShell cmdlets will also be used to inspect the post-deployment state from DC01:

```powershell
Get-GPO -All

Get-GPInheritance -Target "OU=Workstations,DC=corp,DC=home,DC=arpa"
Get-GPInheritance -Target "OU=User Accounts,DC=corp,DC=home,DC=arpa"
Get-GPInheritance -Target "OU=IT,DC=corp,DC=home,DC=arpa"
```

This confirms from the domain side that the GPO links are in place and inheritance is functioning as expected.

---

### Step Seven - Validate Policy Settings Functionally

Beyond confirming GPO names in `gpresult` output, the actual settings will be validated by testing behavior on WIN11-CLIENT01:

**testuser01 session:**
- Control Panel is blocked
- Run menu is absent from Start
- Desktop settings change is prevented
- Network settings pages are hidden

**labadmin session:**
- Desktop wallpaper is set to the path configured in `IT-Admin-Environment`
- Control Panel is accessible
- Run menu is present

**Both sessions:**
- Security audit events visible in the Windows Security event log (Event ID 4624 for successful logon, Event ID 4625 for failed logon)
- Windows Firewall domain profile confirmed active via PowerShell:

```powershell
Get-NetFirewallProfile -Profile Domain | Select-Object Name, Enabled
```

---

### Step Eight - Validate Security Group Filtering

Security group filtering restricts GPO application to members of a specified security group, regardless of OU placement. This exercise demonstrates filtering as an alternative and complementary targeting mechanism to OU-based linking.

The `Workstation-Security-Baseline` GPO will be used as the test subject. By default it applies to `Authenticated Users` within `OU=Workstations`. The exercise switches filtering to the `Lab-Workstations` security group and validates that the GPO continues to apply correctly.

Sequence:

1. Add `WIN11-CLIENT01$` (the computer account) to the `Lab-Workstations` security group in ADUC. The `$` suffix denotes a computer account.
2. Verify group membership is visible in ADUC before proceeding.
3. In GPMC, open `Workstation-Security-Baseline` > Scope tab.
4. Under Security Filtering, click Add and add `Lab-Workstations`. Confirm it has Read and Apply Group Policy permissions in the Delegation tab.
5. Remove `Authenticated Users` from Security Filtering. **Do this only after `Lab-Workstations` is already added and confirmed.** Removing `Authenticated Users` first will cause the workstation to lose access to the GPO before the replacement filter is in place.
6. Run `gpupdate /force` on WIN11-CLIENT01.
7. Validate the GPO is still applied via `gpresult /r`.
8. Confirm the security filtering change is reflected in the RSoP output.

After validation, the filtering configuration can be left as-is (demonstrating security filtering) or reverted to `Authenticated Users` (demonstrating OU-only targeting). Either outcome is acceptable. Document whichever state the lab ends in.

---

### Step Nine - Generate and Review RSoP Report

A full Resultant Set of Policy report will be generated for WIN11-CLIENT01 to confirm the effective policy for both computer and user scopes.

From WIN11-CLIENT01:

```powershell
gpresult /h C:\gpresult-final.html /f
```

From DC01 using the Group Policy PowerShell module:

```powershell
Get-GPResultantSetOfPolicy -ReportType Html -Path C:\rsop-dc.html
```

The HTML reports will be reviewed to confirm:

- all three custom GPOs are listed as applied
- no GPOs are listed as denied or filtered unexpectedly
- applied settings match what was configured
- security filtering is reflected correctly for the `Workstation-Security-Baseline` GPO
- no errors or warnings are present

---

### Step Ten - Create Post-GPO Snapshots

Once validation is complete, snapshots will be created for both VMs.

Planned snapshot names:

```text
DC01 - Group Policy Deployed
WIN11-CLIENT01 - Group Policy Applied
```

Planned snapshot descriptions should include: GPO names and links, security filtering state of `Workstation-Security-Baseline`, and the intended next lab.

---

## Validation Checklist

| Check | Expected Result |
|---|---|
| Pre-GPO baseline documented | `gpresult /r` shows only Default Domain Policy; `Get-GPO -All` shows only two built-in GPOs |
| `Get-GPInheritance` run on all three target OUs before GPO creation | Baseline inheritance state documented |
| Default Domain Policy reviewed | Password, lockout, and Kerberos settings documented |
| `Workstation-Security-Baseline` GPO created | Visible in GPMC under Group Policy Objects |
| `Workstation-Security-Baseline` User Configuration disabled | GPO Status shows User configuration settings disabled |
| `Workstation-Security-Baseline` linked to `OU=Workstations` | Visible in GPMC scope tab |
| `Standard-User-Environment` GPO created | Visible in GPMC |
| `Standard-User-Environment` Computer Configuration disabled | GPO Status shows Computer configuration settings disabled |
| `Standard-User-Environment` linked to `OU=User Accounts` | Visible in GPMC |
| `IT-Admin-Environment` GPO created | Visible in GPMC |
| `IT-Admin-Environment` Computer Configuration disabled | GPO Status shows Computer configuration settings disabled |
| `IT-Admin-Environment` linked to `OU=IT` | Visible in GPMC |
| `Get-GPO -All` post-deployment | Three custom GPOs now visible alongside the two built-in GPOs |
| `Get-GPInheritance` post-deployment on all three OUs | GPO links reflected correctly |
| `gpupdate /force` completes without errors | Computer and User policy updated successfully |
| `gpresult /r` (testuser01 session) | `Workstation-Security-Baseline`, `Standard-User-Environment`, and `Default Domain Policy` present |
| `gpresult /r` (labadmin session) | `Workstation-Security-Baseline`, `IT-Admin-Environment`, and `Default Domain Policy` present |
| `testuser01` functional validation | Control Panel blocked, Run menu absent, desktop settings restricted, network pages hidden |
| `labadmin` functional validation | Desktop wallpaper set to configured path, Control Panel accessible, Run menu present |
| Security audit events in event log | Event ID 4624 (logon success) and Event ID 4625 (logon failure) visible in Security log |
| Windows Firewall domain profile active | `Get-NetFirewallProfile -Profile Domain` returns Enabled: True |
| `WIN11-CLIENT01$` added to `Lab-Workstations` | Visible in ADUC group membership |
| Security filtering switched to `Lab-Workstations` | Authenticated Users removed, Lab-Workstations has Read + Apply GP permissions |
| `Workstation-Security-Baseline` still applied after filtering switch | `gpresult /r` confirms GPO in applied list after `gpupdate /force` |
| RSoP HTML report generated | `gpresult /h` and `Get-GPResultantSetOfPolicy` both produce valid HTML reports |
| RSoP reviewed | No denied GPOs, no errors, settings match configuration, security filtering reflected |
| DC01 post-GPO snapshot created | Visible in VMware snapshot manager |
| WIN11-CLIENT01 post-GPO snapshot created | Visible in VMware snapshot manager |

---

## Potential Issues and Notes

### Default Domain Policy Should Not Be Modified

The Default Domain Policy and Default Domain Controllers Policy are the built-in baseline GPOs that ship with Active Directory. Modifying them directly makes troubleshooting more difficult and can affect all objects in the domain rather than just the intended targets. All custom settings go in purpose-built GPOs linked to specific OUs.

### GPO Scope: Computer vs User Configuration

GPOs contain both a Computer Configuration section and a User Configuration section. Computer Configuration applies when the computer account processes policy at boot. User Configuration applies when the user account processes policy at logon. The two scopes are processed independently. Disabling the unused section in each GPO keeps the scope unambiguous and improves processing performance.

### OU-Based Targeting vs GPO Precedence

`labadmin` and `testuser01` live in different OUs and receive different GPOs. This is OU-based targeting, not precedence or conflict resolution. There is no inheritance conflict in this lab because the two user-scoped GPOs are linked to entirely separate OUs with no parent-child relationship. If both GPOs were linked to the same OU or along the same inheritance path, precedence rules would apply. That scenario is not present here.

### gpresult Requires Elevated Session for Computer Policy

Running `gpresult /r` from a non-elevated session may not display the computer policy section. Run from an elevated PowerShell session to see both computer and user policy sections.

### Security Filtering: Add Before Remove

When switching security filtering from `Authenticated Users` to `Lab-Workstations`, always add the new filter group and confirm its permissions before removing `Authenticated Users`. Removing `Authenticated Users` first will cause the workstation to immediately lose access to the GPO, requiring a revert or re-add to restore it.

### Windows 11 Policy Behavior Differences

Some Group Policy settings available in the GPMC templates may behave differently on Windows 11 23H2 and later. The Start Menu and taskbar were substantially redesigned in Windows 11, and certain Administrative Templates settings that worked on Windows 10 do not apply on Windows 11. If a setting does not produce the expected result on WIN11-CLIENT01, check the GPMC comments field and Microsoft documentation for Windows 11 compatibility notes before assuming a configuration error. Use `gpresult` to confirm whether the setting was applied; if it appears in the applied list but has no visible effect, the issue is Windows 11 behavior, not GPO configuration.

### Group Policy Replication Latency

In a single-DC environment, there is no GPO replication latency. Policy changes on DC01 are immediately available to domain clients after a `gpupdate /force`. This is worth noting because in multi-DC environments, replication latency is a common source of inconsistent policy application.

---

## Research Notes

### Group Policy Processing Order and Precedence

Group Policy is applied in the following order, with later items taking precedence over earlier ones:

1. Local Group Policy (on the individual machine)
2. Site-level GPOs
3. Domain-level GPOs
4. OU-level GPOs (parent OUs before child OUs)

A GPO linked to `OU=Workstations` takes precedence over a GPO linked at the domain level for objects in that OU. Multiple GPOs linked to the same OU are processed in the order shown in GPMC, with lower link order numbers taking precedence.

### Security Filtering vs OU Structure for Policy Targeting

OU-based targeting and security group filtering are two different mechanisms for scoping GPO application. OU-based targeting links a GPO to an OU so it applies to all objects in that OU. Security group filtering restricts an OU-linked GPO so it only applies to objects that are members of the specified security group, regardless of whether the object is in the OU.

Security group filtering is particularly useful when the OU structure does not perfectly align with the desired policy scope. In this lab, the OU structure was deliberately designed to align with the policy scope, so OU-based targeting is the primary mechanism. Security group filtering via `Lab-Workstations` is explored as a supplementary exercise in Step Eight.

### Resultant Set of Policy

RSoP describes the net effect of all Group Policy settings applied to a given computer and user combination. `gpresult` and `Get-GPResultantSetOfPolicy` both report RSoP. The HTML report produced by `gpresult /h` includes every applied GPO, the source DC it was applied from, the OU path of the affected object, any security filtering or WMI filters in effect, and a setting-by-setting breakdown of what was configured and by which GPO.

RSoP is the most reliable way to confirm what a client actually received. The policy editor on the DC shows what was configured; RSoP on the client shows what was applied. These two views can diverge when filtering, inheritance blocking, or processing errors are present.

### WMI Filtering

WMI filters allow GPOs to be conditionally applied based on properties of the target machine queried at policy processing time. A GPO with a WMI filter only applies if the filter query returns true on the target. This is a more advanced targeting mechanism than security group filtering and is not used in this lab. It is documented here as a reference for Lab 06 and beyond, where operating system or hardware-based targeting may become relevant.

### Administrative Templates (ADMX)

The Group Policy settings visible in the GPMC editor under Administrative Templates are backed by ADMX files stored in the PolicyDefinitions folder on the domain controller. Windows ships with a large set of built-in ADMX templates. Additional templates can be added for third-party software. The ADMX files define what settings are available in the editor; the ADML files provide the localized display names and descriptions.

### Password Policy Scope Limitation

Password policy configured in the Default Domain Policy applies domain-wide and cannot be overridden by GPOs linked to OUs. If different password policies are needed for different user groups, Fine-Grained Password Policies (FGPPs) configured through Active Directory Administrative Center are the correct mechanism. FGPPs are applied through Password Settings Objects linked to security groups rather than through Group Policy. This is not implemented in this lab but is noted as context for why password policy lives in the Default Domain Policy rather than in OU-level GPOs.
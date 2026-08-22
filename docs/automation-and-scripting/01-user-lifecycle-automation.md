# 01 - User Lifecycle Automation

## Status

Complete. Both `New-LabUser.ps1` and `Remove-LabUser.ps1` are authored, self-validating, and have been run end to end against a live test account (`jdoe`): provisioned with Linux access, confirmed via an authenticated SSH session with a valid Kerberos ticket, offboarded (disabled, stripped of removable group memberships, primary group and account object preserved), and confirmed denied on Linux after offboarding. All eight implementation steps are done.

---

## Overview

This lab replaces the manual account provisioning and offboarding workflow used throughout the enterprise infrastructure track with a scripted, repeatable PowerShell process against the existing `corp.home.arpa` Active Directory domain.

Every user account in the enterprise infrastructure track (`labadmin`, `testuser01`) was created by hand through Active Directory Users and Computers: create the account, place it in the correct OU, add it to the correct security groups, then separately confirm the resulting access behaves on both Windows and Linux. That is slow, error-prone at scale, and undocumented as a repeatable procedure. This lab formalizes it into two scripts, `New-LabUser.ps1` and `Remove-LabUser.ps1`, that produce the same result every time and validate their own output.

This is the track's first lab (ADR-015) and introduces no new infrastructure; it automates administration of what already exists.

---

## Objectives

- provision a new AD user account with one script, including OU placement and group assignment
- support an optional Linux access path (`Linux-Admins` group membership) that is provable via SSH, not just AD group state
- offboard a user with one script: disable the account, remove its removable security-group memberships while preserving the AD account object, and confirm Linux access is denied afterward
- validate every action by querying the result back from AD rather than assuming success from an exit code
- document the gap between AD state changes and SSSD's cached view of them, a required troubleshooting step rather than a script defect

---

## Project Context

The enterprise infrastructure track built a fully operational identity plane: Active Directory on DC01, a domain-joined Windows client, and an Ubuntu Server host authenticating through SSSD and Kerberos. Every subsequent lab depended on that identity plane and none automated it; account creation has been manual since Lab 03.

ADR-014 identified automation as the highest-priority next track precisely because the AD environment is a fully operational target requiring no new infrastructure. ADR-015 scoped it AD-centric: PowerShell against the Active Directory and Group Policy modules, with Docker, Linux, and Wazuh appearing only as supporting validation.

This lab is the first practical output of that scope, taking the most frequently repeated manual task, user lifecycle management, end to end, including the cross-platform proof Lab 06 established by hand: AD group membership determines SSH access on Ubuntu Server through SSSD and PAM.

---

## Design Decisions

### Script execution location

Scripts in this lab run from WIN11-CLIENT01 via RSAT, not on DC01, a track-wide convention documented in [ADR-016: Run Automation Scripts from a Domain-Joined Client, Not the Domain Controller](../architecture/decisions/016-run-automation-scripts-from-domain-joined-client.md).

### Parameter design

**Decision:** Scripts accept individual named parameters for single-user provisioning in this lab. CSV-based bulk provisioning is deferred rather than built in now.

A bulk CSV path roughly doubles the validation surface (malformed rows, partial-failure handling, per-row rollback) without adding to the core objective: proving one script can take a user from "does not exist" to "provisioned and validated on Windows and Linux." Bulk provisioning is a natural candidate for a later lab in this track.

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

Provisioning and offboarding both originate from WIN11-CLIENT01 against DC01. Validating the Linux path requires a second, independent check directly against Ubuntu Server, since AD group membership and SSSD's resolution of it are not guaranteed to be in sync.

---

## Prerequisites

- DC01 running Active Directory Domain Services and AD-integrated DNS (Lab 03)
- WIN11-CLIENT01 domain-joined with RSAT and the Active Directory module available (Lab 02, Lab 04), the required script execution endpoint per [ADR-016](../architecture/decisions/016-run-automation-scripts-from-domain-joined-client.md)
- Ubuntu Server joined to `corp.home.arpa` with SSSD, Kerberos, and `simple_allow_groups = Linux-Admins@corp.home.arpa` operational (Lab 06)
- `Linux-Admins`, `IT-Admins`, and `Domain-Users-Standard` security groups already exist in `OU=Groups`
- An account with sufficient AD permissions to create, modify, and disable users (`labadmin`)

---

## Implementation

### Step One - Define Script Parameters and Pre-Flight Duplicate Check

`New-LabUser.ps1` was created in `C:\Scripts` on WIN11-CLIENT01, the script execution endpoint established in [ADR-016](../architecture/decisions/016-run-automation-scripts-from-domain-joined-client.md).

```powershell
New-Item -Path "C:\Scripts\New-LabUser.ps1" -ItemType File -Force
```

<p align="center">
  <img src="../../images/automation-and-scripting/01-user-lifecycle-automation/01-create-script-file.jpg" width="900">
</p>

<p align="center">
  <em>New-LabUser.ps1 created as an empty file in C:\Scripts on WIN11-CLIENT01.</em>
</p>

#### Execution Policy

The first attempt was blocked by Windows PowerShell's default execution policy, which returns a `PSSecurityException` before the script's own logic is reached. Expected on a freshly configured workstation, and an administrative prerequisite rather than a script defect.

The policy was set to `RemoteSigned` scoped to `CurrentUser`: locally authored scripts run, anything downloaded still needs a signature, and only the current user's context is touched rather than machine-wide policy.

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Get-ExecutionPolicy -List
```

<p align="center">
  <img src="../../images/automation-and-scripting/01-user-lifecycle-automation/02-set-execution-policy.jpg" width="900">
</p>

<p align="center">
  <em>Get-ExecutionPolicy -List confirming RemoteSigned applied at the CurrentUser scope, with all other scopes left Undefined.</em>
</p>

#### Parameter Design

The parameter block follows from the objectives. `FirstName`, `LastName`, and `SamAccountName` are mandatory, with `SamAccountName` a required attribute of `New-ADUser`. `TargetOU` and `RoleGroup` carry the OU placement and group assignment objective, defaulting to `OU=User Accounts` and `Domain-Users-Standard` while remaining overridable. `LinuxAccess` is a switch because the Linux path is optional. `InitialPassword` is a mandatory `[SecureString]`: `New-ADUser` produces a disabled account without one, and avoiding plaintext credential handling requires it be entered at runtime rather than passed as a string.

```powershell
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$FirstName,

    [Parameter(Mandatory = $true)]
    [string]$LastName,

    [Parameter(Mandatory = $true)]
    [string]$SamAccountName,

    [Parameter(Mandatory = $false)]
    [string]$TargetOU = "OU=User Accounts,DC=corp,DC=home,DC=arpa",

    [Parameter(Mandatory = $false)]
    [ValidateSet("IT-Admins", "Domain-Users-Standard")]
    [string]$RoleGroup = "Domain-Users-Standard",

    [Parameter(Mandatory = $false)]
    [switch]$LinuxAccess,

    [Parameter(Mandatory = $true)]
    [System.Security.SecureString]$InitialPassword
)
```

#### Pre-Flight Duplicate Check

Before creating anything, the script queries AD for an existing account with the same `SamAccountName`. `Get-ADUser -Identity` throws a terminating `ADIdentityNotFoundException` when the account does not exist, so catching that specific exception confirms the name is free, while a second generic catch handles a real query failure (DC01 unreachable, insufficient permissions) without falsely reporting the name available.

```powershell
Import-Module ActiveDirectory

Write-Host "Checking whether '$SamAccountName' already exists in Active Directory..." -ForegroundColor Cyan

try {
    $existing = Get-ADUser -Identity $SamAccountName -ErrorAction Stop
    Write-Host "ABORT: an account with SamAccountName '$SamAccountName' already exists ($($existing.DistinguishedName))." -ForegroundColor Red
    return
}
catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
    Write-Host "OK: no existing account named '$SamAccountName'. Safe to proceed." -ForegroundColor Green
}
catch {
    Write-Host "ERROR: could not query Active Directory ($($_.Exception.Message))." -ForegroundColor Red
    return
}
```

The check was validated both ways: `testuser01`, which exists from Lab 06, triggered the ABORT branch and returned the account's live distinguished name from DC01; the unused name `jdoe` passed and reported safe to proceed.

<p align="center">
  <img src="../../images/automation-and-scripting/01-user-lifecycle-automation/03-preflight-duplicate-abort.jpg" width="900">
</p>

<p align="center">
  <em>Pre-flight check against testuser01 hitting the ABORT branch and returning the existing account's distinguished name (CN=testuser01,OU=User Accounts,DC=corp,DC=home,DC=arpa) from Active Directory.</em>
</p>

<p align="center">
  <img src="../../images/automation-and-scripting/01-user-lifecycle-automation/04-preflight-duplicate-pass.jpg" width="900">
</p>

<p align="center">
  <em>Pre-flight check against the unused name jdoe passing the ADIdentityNotFoundException catch and reporting the name safe to proceed.</em>
</p>

### Step Two - Implement Account Creation and Group Assignment

With the name confirmed free, the script derives the remaining attributes and creates the object. `DisplayName` and `UserPrincipalName` are derived rather than exposed as parameters, `"FirstName LastName"` and `SamAccountName@corp.home.arpa`, keeping the parameter block minimal while still populating what an account needs to be usable.

```powershell
# Derive display name and UPN from the supplied parameters
$displayName = "$FirstName $LastName"
$userPrincipalName = "$SamAccountName@corp.home.arpa"

Write-Host "Creating account '$SamAccountName' in $TargetOU..." -ForegroundColor Cyan

New-ADUser `
    -Name $displayName `
    -SamAccountName $SamAccountName `
    -UserPrincipalName $userPrincipalName `
    -GivenName $FirstName `
    -Surname $LastName `
    -DisplayName $displayName `
    -Path $TargetOU `
    -AccountPassword $InitialPassword `
    -ChangePasswordAtLogon $true `
    -Enabled $true
```

`-Name` sets the common name shown in ADUC; `-SamAccountName` sets the separate logon name. `-AccountPassword` consumes the runtime `[SecureString]` directly, so no plaintext conversion happens anywhere. `-ChangePasswordAtLogon $true` forces the user to set their own password at first logon, so the administrator never knows the eventual credential. `-Enabled $true` makes the account usable; without both a password and an explicit enable, `New-ADUser` produces a disabled account.

Role-group assignment follows creation. `Linux-Admins` is added only when `-LinuxAccess` is supplied, and the `else` branch prints an explicit skip so the console shows which path was taken rather than silently omitting the Linux step.

```powershell
# Assign the role group
Write-Host "Adding '$SamAccountName' to role group '$RoleGroup'..." -ForegroundColor Cyan
Add-ADGroupMember -Identity $RoleGroup -Members $SamAccountName

# Grant Linux access only when requested
if ($LinuxAccess) {
    Write-Host "Adding '$SamAccountName' to 'Linux-Admins' (Linux access requested)..." -ForegroundColor Cyan
    Add-ADGroupMember -Identity "Linux-Admins" -Members $SamAccountName
}
else {
    Write-Host "Linux access not requested; skipping Linux-Admins membership." -ForegroundColor DarkGray
}
```

This logic was written but not executed here. Because these cmdlets write to AD, the first live run happens in Step Four against the account later offboarded in Step Seven, keeping creation and removal on one traceable object.

<p align="center">
  <img src="../../images/automation-and-scripting/01-user-lifecycle-automation/05-account-creation-code.jpg" width="900">
</p>

<p align="center">
  <em>New-LabUser.ps1 in the editor showing the pre-flight check followed by the account creation and group assignment logic, with the conditional Linux-Admins membership.</em>
</p>

### Step Three - Implement Validation Logic

The script then validates by querying AD back rather than trusting the preceding cmdlets. `Get-ADUser` returns the account with its `Enabled` and `DistinguishedName` properties, and `Get-ADPrincipalGroupMembership` returns its group memberships by name. The latter is deliberate: it is the same cmdlet the offboarding script uses in Step Six, so both scripts reason about group membership through one tool.

```powershell
# Validate the result by querying AD back, rather than trusting the cmdlets above
Write-Host "Validating provisioned account against Active Directory..." -ForegroundColor Cyan

$created = Get-ADUser -Identity $SamAccountName -Properties Enabled, DistinguishedName
$groups  = Get-ADPrincipalGroupMembership -Identity $SamAccountName | Select-Object -ExpandProperty Name
```

Four checks compare current state against what was requested, each printing an explicit PASS or FAIL: the account must exist and be enabled, sit in the requested OU, and belong to its role group.

```powershell
# Account exists and is enabled
if ($created -and $created.Enabled) {
    Write-Host "PASS: account exists and is enabled." -ForegroundColor Green
}
else {
    Write-Host "FAIL: account missing or not enabled." -ForegroundColor Red
}

# Account resides in the requested OU
if ($created.DistinguishedName -like "*$TargetOU") {
    Write-Host "PASS: account is in the target OU ($TargetOU)." -ForegroundColor Green
}
else {
    Write-Host "FAIL: account is not in the expected OU. Found: $($created.DistinguishedName)" -ForegroundColor Red
}

# Role group membership
if ($groups -contains $RoleGroup) {
    Write-Host "PASS: member of role group '$RoleGroup'." -ForegroundColor Green
}
else {
    Write-Host "FAIL: not a member of role group '$RoleGroup'." -ForegroundColor Red
}
```

The Linux-Admins check is deliberately two-sided: with `-LinuxAccess` the account must be a member, without it the account must not be. That catches an erroneous membership when Linux access was not requested, which a one-sided check would miss.

```powershell
# Linux-Admins membership matches what was requested
if ($LinuxAccess) {
    if ($groups -contains "Linux-Admins") {
        Write-Host "PASS: member of Linux-Admins (Linux access requested)." -ForegroundColor Green
    }
    else {
        Write-Host "FAIL: Linux access requested but not a member of Linux-Admins." -ForegroundColor Red
    }
}
else {
    if ($groups -notcontains "Linux-Admins") {
        Write-Host "PASS: not a member of Linux-Admins (Linux access not requested)." -ForegroundColor Green
    }
    else {
        Write-Host "FAIL: not requested, but unexpectedly a member of Linux-Admins." -ForegroundColor Red
    }
}
```

The OU check uses a `-like` suffix match against the distinguished name, a readable comparison suited to the lab that can be tightened to parse DN components explicitly if it proves too loose in Step Four. `New-LabUser.ps1` is now complete end to end: pre-flight check, creation, group assignment, self-validation.

<p align="center">
  <img src="../../images/automation-and-scripting/01-user-lifecycle-automation/06-validation-code.jpg" width="900">
</p>

<p align="center">
  <em>New-LabUser.ps1 validation logic querying AD back after creation and printing PASS/FAIL for account existence, enabled state, OU placement, role group, and two-sided Linux-Admins membership.</em>
</p>

### Step Four - Run New-LabUser.ps1 Against a Test Account

The completed script was run from WIN11-CLIENT01 as `labadmin` to provision the test account `jdoe` with Linux access, the account SSH-tested in Step Five and offboarded in Step Seven.

```powershell
.\New-LabUser.ps1 -FirstName Jane -LastName Doe -SamAccountName jdoe -RoleGroup Domain-Users-Standard -LinuxAccess
```

A complex password satisfying the domain password policy was entered at the `InitialPassword` prompt. The script ran end to end: pre-flight confirmed `jdoe` did not exist, the account was created in `OU=User Accounts`, added to `Domain-Users-Standard` and `Linux-Admins`, and all four validation checks returned PASS.

- **PASS**: account exists and is enabled
- **PASS**: account is in the target OU (`OU=User Accounts,DC=corp,DC=home,DC=arpa`)
- **PASS**: member of role group `Domain-Users-Standard`
- **PASS**: member of `Linux-Admins` (Linux access requested)

The `-like` suffix match resolved correctly against the real distinguished name, so no adjustment was needed. `-ChangePasswordAtLogon` means `jdoe` must set a new password at first logon, exercised in Step Five.

<p align="center">
  <img src="../../images/automation-and-scripting/01-user-lifecycle-automation/07-run-account-creation.jpg" width="900">
</p>

<p align="center">
  <em>New-LabUser.ps1 run against jdoe with -LinuxAccess, showing the pre-flight pass, account creation, role group and Linux-Admins assignment, and all four validation checks returning PASS.</em>
</p>

### Step Five - Confirm Linux Access via SSH

With `jdoe` provisioned and confirmed in `Linux-Admins`, SSH to Ubuntu Server was tested from WIN11-CLIENT01. This is the cross-platform proof at the center of the lab: the PowerShell script writes to AD, AD carries the account and group membership, SSSD resolves it on Linux, and PAM authorizes the session on `Linux-Admins` membership.

#### SSSD cache: account not yet resolvable

The first SSH attempt failed at the password prompt with `Permission denied`, but the cause was resolution rather than authorization: SSSD had no record of the freshly created account, so it could not authenticate a user it could not resolve. Querying it directly on Ubuntu Server confirmed this:

```bash
id jdoe@corp.home.arpa
# id: 'jdoe@corp.home.arpa': no such user
```

The targeted cache invalidation from the plan did not apply, because there was no cached entry to invalidate:

```bash
sudo sss_cache -u jdoe@corp.home.arpa
# No cache object matched the specified search
```

A full-cache expire also failed to make the account resolvable:

```bash
sudo sss_cache -E
id jdoe@corp.home.arpa
# id: 'jdoe@corp.home.arpa': no such user
```

The account became resolvable only after restarting the SSSD service, which clears the in-memory negative-cache entry that `sss_cache` did not reach:

```bash
sudo systemctl restart sssd
id jdoe@corp.home.arpa
# uid=1366001112(jdoe@corp.home.arpa) gid=1366000513(domain users@corp.home.arpa)
# groups=1366000513(domain users@corp.home.arpa),1366001110(linux-admins@corp.home.arpa),1366001106(domain-users-standard@corp.home.arpa)
```

The resolved identity shows `linux-admins@corp.home.arpa`, confirming the script's group assignment reached Linux intact. Troubleshooting covers why a service restart, rather than `sss_cache`, was required.

<p align="center">
  <img src="../../images/automation-and-scripting/01-user-lifecycle-automation/08-sssd-cache-resolution.jpg" width="900">
</p>

<p align="center">
  <em>SSSD failing to resolve jdoe (no such user), sss_cache finding no entry to invalidate and a full expire not helping, then systemctl restart sssd making the account resolve with linux-admins membership present.</em>
</p>

#### Authenticated SSH session

With resolution working, the SSH login proceeded. Because `-ChangePasswordAtLogon` was set at creation, PAM required a password change on first login before completing the session:

```text
WARNING: Your password has expired.
You must change your password now and log in again!
Current Password:
New password:
Retype new password:
passwd: password updated successfully
Connection to 192.168.1.226 closed.
```

The forced-password-change design working end to end: the administrator set only a temporary password and `jdoe` set its own, which the administrator never learns. The session closed after the change, requiring a reconnect.

Reconnecting with the new password produced a working, authorized session. Three checks confirm it is a genuine AD-sourced login:

```bash
whoami
# jdoe@corp.home.arpa

id
# uid=1366001112(jdoe@corp.home.arpa) gid=1366000513(domain users@corp.home.arpa)
# groups=...,1366001110(linux-admins@corp.home.arpa),1366001106(domain-users-standard@corp.home.arpa)

klist
# Default principal: jdoe@CORP.HOME.ARPA
# Valid TGT: krbtgt/CORP.HOME.ARPA@CORP.HOME.ARPA
```

`whoami` returns the fully qualified AD identity, `id` shows the correct UID and `Linux-Admins` membership, and `klist` shows a valid Kerberos TGT issued by DC01 at login. The home directory was created on first login. A single PowerShell run on Windows produced a fully functional, Kerberos-authenticated, correctly authorized Linux account.

<p align="center">
  <img src="../../images/automation-and-scripting/01-user-lifecycle-automation/09-ssh-session-success.jpg" width="900">
</p>

<p align="center">
  <em>Authenticated SSH session as jdoe@corp.home.arpa showing whoami, id with linux-admins membership, and klist with a valid Kerberos TGT for jdoe@CORP.HOME.ARPA.</em>
</p>

### Step Six - Write Remove-LabUser.ps1

`Remove-LabUser.ps1` was created in `C:\Scripts` alongside `New-LabUser.ps1`. It takes a single mandatory parameter, `SamAccountName`, since offboarding operates on an account that already exists.

```powershell
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$SamAccountName
)

Import-Module ActiveDirectory
```

The pre-flight check mirrors `New-LabUser.ps1`'s with the branches reversed: provisioning aborts if the account already exists, offboarding aborts if it does not. Both use the same `Get-ADUser -Identity` and `ADIdentityNotFoundException` pattern.

```powershell
# Abort if the account does not exist
Write-Host "Checking whether '$SamAccountName' exists in Active Directory..." -ForegroundColor Cyan

try {
    $user = Get-ADUser -Identity $SamAccountName -Properties Enabled, PrimaryGroup -ErrorAction Stop
    Write-Host "OK: found '$SamAccountName' ($($user.DistinguishedName))." -ForegroundColor Green
}
catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
    Write-Host "ABORT: no account named '$SamAccountName' exists." -ForegroundColor Red
    return
}
catch {
    Write-Host "ERROR: could not query Active Directory ($($_.Exception.Message))." -ForegroundColor Red
    return
}
```

The account is disabled before any group work. Disabling immediately blocks logon, so it happens first: if group removal fails partway through, the account is already secured rather than sitting mid-cleanup with standing access.

```powershell
# Disable the account first; this is the immediate security action
Write-Host "Disabling '$SamAccountName'..." -ForegroundColor Cyan
Disable-ADAccount -Identity $SamAccountName
```

Group removal implements the Troubleshooting section's primary-group problem: `Get-ADPrincipalGroupMembership` returns every group, and `Where-Object` filters out the one matching `$user.PrimaryGroup`, captured during the pre-flight query, before any removal is attempted. That is what "removable security-group memberships" means in practice.

```powershell
# Strip removable security-group memberships, preserving the primary group
Write-Host "Removing removable group memberships from '$SamAccountName'..." -ForegroundColor Cyan

$groups = Get-ADPrincipalGroupMembership -Identity $SamAccountName |
    Where-Object { $_.DistinguishedName -ne $user.PrimaryGroup }

foreach ($group in $groups) {
    Write-Host "Removing '$SamAccountName' from '$($group.Name)'..." -ForegroundColor Cyan
    Remove-ADPrincipalGroupMembership -Identity $SamAccountName -MemberOf $group -Confirm:$false
}
```

`-Confirm:$false` suppresses the per-removal prompt `Remove-ADPrincipalGroupMembership` normally raises, which is what lets the script run unattended. A deliberate tradeoff for a lab tool on a known test account; Security Considerations revisits what a production version would add.

The script then validates the same way `New-LabUser.ps1` does, by re-querying AD. Three checks: the account must be disabled, every group targeted for removal must be gone, and the primary group, and therefore the account object, must be unchanged.

```powershell
# Validate the result by querying AD back, rather than trusting the cmdlets above
Write-Host "Validating offboarded account against Active Directory..." -ForegroundColor Cyan

$final = Get-ADUser -Identity $SamAccountName -Properties Enabled, PrimaryGroup
$remainingGroups = Get-ADPrincipalGroupMembership -Identity $SamAccountName | Select-Object -ExpandProperty Name

# Account is disabled
if (-not $final.Enabled) {
    Write-Host "PASS: account is disabled." -ForegroundColor Green
}
else {
    Write-Host "FAIL: account is still enabled." -ForegroundColor Red
}

# Removable groups are gone
if ($groups.Count -eq 0) {
    Write-Host "PASS: no removable group memberships were present." -ForegroundColor Green
}
else {
    $stillRemoved = $groups | Where-Object { $remainingGroups -notcontains $_.Name }
    if ($stillRemoved.Count -eq $groups.Count) {
        Write-Host "PASS: all removable group memberships were removed." -ForegroundColor Green
    }
    else {
        Write-Host "FAIL: some group memberships were not removed." -ForegroundColor Red
    }
}

# Primary group and account object are preserved
if ($final.PrimaryGroup -eq $user.PrimaryGroup) {
    Write-Host "PASS: primary group preserved; account object retained." -ForegroundColor Green
}
else {
    Write-Host "FAIL: primary group changed unexpectedly." -ForegroundColor Red
}
```

The group-removal check reuses `$groups`, captured before removal, against a fresh `$remainingGroups` query, so it confirms the groups are gone rather than assuming the loop succeeded because it did not error. The primary-group check is the proof that "disable and strip, don't delete" held: if `$final.PrimaryGroup` still matches the pre-flight value, the account object survived intact. `Remove-LabUser.ps1` is now complete end to end, with its first live run in Step Seven against `jdoe`.

<p align="center">
  <img src="../../images/automation-and-scripting/01-user-lifecycle-automation/10-offboarding-code.jpg" width="900">
</p>

<p align="center">
  <em>Remove-LabUser.ps1 in the editor showing the reversed pre-flight check, account disable, primary-group-preserving removal loop, and post-offboarding self-validation.</em>
</p>

### Step Seven - Run Remove-LabUser.ps1 Against the Test Account

The offboarding script was run from WIN11-CLIENT01 as `labadmin` against `jdoe`, provisioned in Step Four and SSH-tested in Step Five.

```powershell
.\Remove-LabUser.ps1 -SamAccountName jdoe
```

The script ran end to end: the pre-flight check found `jdoe` (`CN=Jane Doe,OU=User Accounts,DC=corp,DC=home,DC=arpa`), disabled the account, removed it from `Domain-Users-Standard` and `Linux-Admins`, and all three validation checks returned PASS.

- **PASS**: account is disabled
- **PASS**: all removable group memberships were removed
- **PASS**: primary group preserved; account object retained

`Domain-Users-Standard` and `Linux-Admins` are exactly the two non-primary groups `jdoe` held. `Domain Users`, the primary group, was correctly excluded from the removal loop and confirmed unchanged, and the account object still exists in AD, disabled rather than deleted. Step Eight confirms this on the Linux side.

<p align="center">
  <img src="../../images/automation-and-scripting/01-user-lifecycle-automation/11-run-offboarding.jpg" width="900">
</p>

<p align="center">
  <em>Remove-LabUser.ps1 run against jdoe, showing the account found, disabled, both non-primary groups removed, and all three validation checks returning PASS.</em>
</p>

### Step Eight - Confirm SSH Access Denied After Offboarding

With `jdoe` disabled and stripped of its removable group memberships, SSH access was attempted from WIN11-CLIENT01 using the credentials `jdoe` set during Step Five.

```powershell
ssh jdoe@corp.home.arpa@192.168.1.226
```

The login was denied, `Permission denied, please try again`, without reaching a shell. The cause differs from Step Five's failure: `jdoe` resolves fine now, but the account is disabled in AD, so authentication is refused regardless of the password.

<p align="center">
  <img src="../../images/automation-and-scripting/01-user-lifecycle-automation/12-ssh-denied-post-offboarding.jpg" width="900">
</p>

<p align="center">
  <em>SSH login attempt as jdoe after offboarding, denied at the password prompt.</em>
</p>

Checking the Linux-side view against AD directly surfaced a partial cache lag, the mirror image of Step Five's issue. Immediately after offboarding, SSSD still resolved `jdoe` with a stale group list:

```bash
id jdoe@corp.home.arpa
# uid=1366001112(jdoe@corp.home.arpa) gid=1366000513(domain users@corp.home.arpa)
# groups=1366000513(domain users@corp.home.arpa),1366001106(domain-users-standard@corp.home.arpa)
```

`Linux-Admins` was already gone, correctly reflecting the removal that gated SSH, but `Domain-Users-Standard` remained, even though `Remove-LabUser.ps1`'s own validation had confirmed it removed in AD. Querying AD directly, bypassing SSSD, confirmed the script had not left anything behind:

```powershell
Get-ADPrincipalGroupMembership -Identity jdoe | Select-Object Name
# Domain Users
```

Only the primary group remained in AD, so the discrepancy was entirely SSSD's: its cache had picked up the `Linux-Admins` removal but not the `Domain-Users-Standard` one, showing staleness can apply unevenly across a single account's attributes rather than all-or-nothing. It did not affect the SSH denial, since PAM's `simple_allow_groups` gates only on `Linux-Admins`. Restarting SSSD resolved the lag:

```bash
sudo systemctl restart sssd
id jdoe@corp.home.arpa
# uid=1366001112(jdoe@corp.home.arpa) gid=1366000513(domain users@corp.home.arpa)
# groups=1366000513(domain users@corp.home.arpa)
```

SSSD's view now matches AD exactly: only the primary group. That closes the lifecycle loop. One script provisioned `jdoe` with working AD and Linux access, one script offboarded it while preserving the account object, and both ends of the cross-platform identity chain agree on the result.

<p align="center">
  <img src="../../images/automation-and-scripting/01-user-lifecycle-automation/13-sssd-cache-post-offboarding.jpg" width="900">
</p>

<p align="center">
  <em>SSSD showing a stale Domain-Users-Standard membership immediately after offboarding despite Linux-Admins already being removed; systemctl restart sssd resolves it so the cached group list matches AD (primary group only).</em>
</p>

---

## Validation

- **PASS**: `jdoe` confirmed to exist in the correct OU (`OU=User Accounts,DC=corp,DC=home,DC=arpa`) via `Get-ADUser` (Step Four)
- **PASS**: group membership confirmed via `Get-ADPrincipalGroupMembership` (`Domain-Users-Standard`, `Linux-Admins`) (Step Four)
- **PASS**: with `-LinuxAccess`, SSH login to Ubuntu Server succeeded and created a home directory on first login (Step Five)
- **PASS**: offboarded account confirmed disabled via `Get-ADUser`, with removable security-group memberships stripped via `Get-ADPrincipalGroupMembership`; the account object itself and its primary group were confirmed to remain (Step Seven)
- **PASS**: offboarded account's SSH access confirmed denied on Ubuntu Server (Step Eight)

One objective was not independently re-tested here: the negative case for provisioning without `-LinuxAccess`, SSH denied at the PAM authorization step for a non-member account. `testuser01` validated that in Lab 06 under the identical `simple_allow_groups` mechanism, and Step Three's two-sided check confirms the script withholds `Linux-Admins` membership when the switch is absent. A fresh run without `-LinuxAccess` would be a reasonable follow-up but was not needed to meet the objectives.

---

## Troubleshooting and Adjustments

**Primary group cannot be removed via `Remove-ADPrincipalGroupMembership`.** Every AD user has a primary group (Domain Users by default, RID 513), and the cmdlet errors if asked to remove it, so an offboarding script that naively pipes everything from `Get-ADPrincipalGroupMembership` into removal fails there. The intended behavior is to remove *removable* security-group memberships, not literally all groups. `Remove-LabUser.ps1` captures the account's `PrimaryGroup` distinguished name during the pre-flight query and filters it out with `Where-Object` before the loop runs, confirmed against `jdoe` in Step Seven: `Domain-Users-Standard` and `Linux-Admins` removed, `Domain Users` untouched.

**SSSD did not resolve a freshly created account, and `sss_cache` did not fix it (encountered in Step Five).** After `jdoe` was created in AD, Ubuntu Server could not resolve it (`id: 'jdoe@corp.home.arpa': no such user`), so SSH failed at the password prompt. The plan anticipated a stale-cache scenario resolved by targeted invalidation; the actual behavior differed:

- `sss_cache -u jdoe@corp.home.arpa` returned `No cache object matched the specified search`. `sss_cache` can only expire an entry that already exists in the cache; because the account had never been successfully looked up, there was no positive entry to invalidate.
- `sss_cache -E` (expire everything) also did not make the account resolve. A negative-lookup result (SSSD having recorded that the name did not exist) persisted in memory and continued to suppress re-queries to AD.
- `sudo systemctl restart sssd` resolved it immediately. Restarting the daemon clears the in-memory negative cache that `sss_cache` does not reach, forcing a fresh lookup against AD on the next request.

The practical lesson: `sss_cache -u <user>` or `-g <group>` is the correct targeted tool for a stale membership change on an account SSSD has already cached, but for one it has never successfully resolved, where a negative-cache entry is created, a service restart is the reliable fix. Per the SSSD documentation `sss_cache` invalidates existing cache objects so they are re-pulled on the next lookup, which is why it had nothing to act on here.

**SSSD's cache updated unevenly across a single account's group memberships after offboarding (encountered in Step Eight).** Immediately after `jdoe` was disabled and stripped of both groups in AD, SSSD's cached view had dropped `Linux-Admins` but still showed `Domain-Users-Standard`, while `Get-ADPrincipalGroupMembership` run directly against AD confirmed only the primary group remained. SSSD's cache can update per-attribute rather than atomically per-account, so a partially-stale result does not mean the AD change failed; confirm against AD directly, bypassing SSSD, before assuming a script defect. Here the stale attribute did not affect access control, since `Linux-Admins`, the group PAM actually authorizes on, was already correct, but `systemctl restart sssd` brought the whole record back in sync.

---

## Security Considerations

**Least privilege for the executing account.** Both scripts were run as `labadmin`, which holds broad AD permissions. A production deployment would use a dedicated service account scoped to only these operations, create and disable users, add and remove group membership within specific OUs, rather than running lifecycle automation under a broad administrative identity.

**Plaintext password handling.** `New-LabUser.ps1` takes the initial password as a mandatory `[SecureString]` entered at runtime, never as a plaintext parameter, and never writes it to disk, a log, or the repository. With `-ChangePasswordAtLogon $true`, the administrator never learns the account's eventual password, limiting that credential's value even if the administrator's session were compromised.

**Disable rather than delete.** `Remove-LabUser.ps1` never deletes the AD object, confirmed in Step Seven's validation (`PASS: primary group preserved; account object retained`). This preserves the account's SID and history for auditing and reversibility, consistent with the offboarding practice sources cited below, at the cost of accumulating disabled objects that a real deployment would need a retention or cleanup policy for.

**`-Confirm:$false` on group removal.** Suppressing the per-removal prompt is appropriate for a lab tool operating on a known test account. A production tool acting on arbitrary accounts at scale would want safeguards first: a `-WhatIf`-compatible dry-run mode, logging every removal to a file external to the console, or a separate explicit `-Force` switch distinct from the account-targeting parameter.

---

## Outcome

Both scripts meet every objective set out at the start. One run provisions an AD account, places it in the correct OU, assigns its role group, optionally grants Linux access via `Linux-Admins`, and validates by querying AD back rather than trusting the cmdlets' exit codes. One run offboards it: disable, strip removable group memberships while preserving the primary group and the account object, validate the same way.

The cross-platform claim, that AD group membership determines SSH access on Ubuntu Server through SSSD and PAM, was proven in both directions against a real account rather than assumed from Lab 06's earlier manual result: `jdoe` gained working, Kerberos-authenticated SSH access on being added to `Linux-Admins` and lost it on removal. Both directions surfaced SSSD cache behavior the plan had anticipated only in general terms, a negative-cache entry for a never-resolved account and per-attribute staleness for an already-cached one. Documenting what actually happened, including the cases where the anticipated `sss_cache` fix did not work and a service restart was required instead, makes the Troubleshooting section a more accurate reference than the plan alone would have produced.

---

## Lessons Learned

**Anticipated troubleshooting steps are hypotheses to verify, not facts to assert.** The plan's Troubleshooting section, written before any code existed, predicted that `sss_cache` targeted invalidation would resolve SSSD staleness. It did not, twice, for two different reasons: no cache entry to invalidate on first resolution, and a negative-cache entry that survived a full expire. Documenting what actually happened rather than what was predicted produced a more useful and more honest reference, and reinforces the rule that nothing is documented as done before it has happened and been verified.

**Self-validation catches what console output alone would hide.** `Remove-LabUser.ps1`'s validation block, added deliberately to match `New-LabUser.ps1`'s standard, is what made the Step Eight SSSD discrepancy visible in the first place. Without a script that re-queries AD and states plainly what it found, a partially-stale cache on the Linux side is easily mistaken for a partially-failed offboarding script. Querying the source of truth directly, rather than trusting either the script's own success message or one downstream system's cached view, resolved the ambiguity quickly.

**Cache staleness is not always all-or-nothing.** Both SSSD issues refined the same underlying lesson from different angles: a cache miss on a brand-new account behaves differently from one on a modified attribute of an already-known account, and within a single account's record, individual group memberships can update independently. "The cache is either fresh or stale" is not an accurate enough mental model for SSSD in practice; the safer default is to verify the authoritative source directly whenever a Linux-side result looks surprising, rather than assuming either total staleness or a script defect.

---

## Sources

Research references consulted during the planning phase of this lab.

**Active Directory PowerShell module (Microsoft Learn)**

- [New-ADUser](https://learn.microsoft.com/en-us/powershell/module/activedirectory/new-aduser) - core provisioning cmdlet; `SamAccountName` is required, `Path` sets OU placement, accounts created without a password are disabled by default
- [Set-ADUser](https://learn.microsoft.com/en-us/powershell/module/activedirectory/set-aduser) - modifying existing account properties post-creation
- [Get-ADPrincipalGroupMembership](https://learn.microsoft.com/en-us/powershell/module/activedirectory/get-adprincipalgroupmembership) - used for validation (confirming group assignment) and as the input to offboarding group removal
- [Remove-ADPrincipalGroupMembership](https://learn.microsoft.com/en-us/powershell/module/activedirectory/remove-adprincipalgroupmembership) - removes removable security-group memberships during offboarding, but cannot remove a user's primary group
- [Disable-ADAccount](https://learn.microsoft.com/en-us/powershell/module/activedirectory/disable-adaccount) - disables rather than deletes the account object during offboarding

**SSSD cache behavior (Red Hat / upstream SSSD docs)**

- [Managing the SSSD Cache - Red Hat Enterprise Linux Deployment Guide](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/6/html/deployment_guide/sssd-cache) and the [System-Level Authentication Guide troubleshooting appendix](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/7/html/system-level_authentication_guide/trouble) - confirms `sss_cache` invalidates cached records so SSSD re-pulls them from AD on next lookup, rather than clearing the cache outright
- [sss_cache(8) man page](https://linux.die.net/man/8/sss_cache) - flag reference (`-u` for a single user, `-g` for a single group); in practice it operates only on existing cache objects, so a negative-lookup entry for a never-resolved account required a service restart instead
- [How To Clear The SSSD Cache In Linux](https://www.rootusers.com/how-to-clear-the-sssd-cache-in-linux/) - clarifies that `sss_cache` marks entries expired rather than deleting them, which preserves offline fallback if AD is briefly unreachable during validation

**Account offboarding practice (disable vs. delete)**

- [Delete or Disable an Active Directory Account? One Best Practice - Imanami](https://www.imanami.com/delete-or-disable-an-active-directory-account-one-best-practice/) - summarizes the standard tradeoff: disabling preserves the SID and account history for reversibility and auditing, deleting removes access immediately but is not easily reversible
- [Best Practices - Disabling Users in Active Directory - ITAdminTools](https://www.itadmintools.com/2013/08/best-practices-disabling-users-in.html) - supports the offboarding approach used here (disable, remove removable group memberships, retain the account object) over outright deletion

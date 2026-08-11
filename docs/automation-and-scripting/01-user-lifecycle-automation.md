# 01 - User Lifecycle Automation

## Status

In progress. `New-LabUser.ps1` is complete and validated end to end: Steps One through Five are done. The provisioning script was authored (parameters and pre-flight check, account creation and group assignment, self-validation), run successfully against the test account `jdoe` with Linux access with all four validation checks passing, and confirmed on Ubuntu Server by an authenticated SSH session with a valid Kerberos ticket and correct group membership. Remaining: Step Six (`Remove-LabUser.ps1` offboarding script), and Steps Seven and Eight (offboarding run and post-offboarding SSH denial). The test account `jdoe` currently exists in Active Directory and is offboarded in Step Seven.

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

The first attempt to run the script was blocked. Windows PowerShell's default execution policy prevents any script from running, returning a `PSSecurityException` before the script's own logic is reached. This is expected on a freshly configured workstation and is a real administrative prerequisite rather than a script defect.

The execution policy was set to `RemoteSigned` scoped to `CurrentUser`. `RemoteSigned` permits locally authored scripts to run while still requiring that any script downloaded from the internet be digitally signed, which is the standard, defensible posture for an administration workstation. Scoping the change to `CurrentUser` rather than `LocalMachine` keeps it least-privilege: only the current user's context is affected, and no machine-wide policy is altered.

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

The parameter block is derived directly from the lab objectives. The identity fields (`FirstName`, `LastName`, `SamAccountName`) are mandatory because provisioning an account requires them and no default is meaningful; `SamAccountName` in particular is a required attribute of `New-ADUser`. `TargetOU` and `RoleGroup` implement the OU placement and group assignment objective, defaulting to the existing `OU=User Accounts` and `Domain-Users-Standard` structures documented in Technologies Used while remaining overridable. `LinuxAccess` is a switch rather than a mandatory parameter because the second objective defines the Linux path as optional. `InitialPassword` is a mandatory `[SecureString]`: `New-ADUser` creates a disabled account if no password is supplied, so one is required, and the Security Considerations requirement to avoid plaintext credential handling dictates that it be a SecureString entered at runtime rather than a plaintext string.

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

Before any account object is created, the script queries Active Directory for an existing account with the same `SamAccountName`. `Get-ADUser -Identity` throws a terminating `ADIdentityNotFoundException` when the account does not exist. Catching that specific exception confirms the name is free and safe to use, while a second, generic catch handles a genuine query failure (DC01 unreachable, insufficient permissions) without falsely reporting the name as available. This reflects the lab objective of validating a result rather than assuming success, applied before anything is created.

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

The check was validated against two accounts. Running it against `testuser01`, which exists from Lab 06, triggered the ABORT branch and returned the account's live distinguished name from DC01. Running it against the unused name `jdoe` passed the check and reported the name safe to proceed.

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

With the pre-flight check confirming the name is free, the script derives the remaining account attributes and creates the object. `DisplayName` and `UserPrincipalName` are derived in the script rather than exposed as parameters: the display name is `"FirstName LastName"`, and the UPN is `SamAccountName@corp.home.arpa`. Deriving them keeps the parameter block minimal while still populating the attributes an account needs to be usable.

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

`-Name` sets the account's common name (the CN shown in ADUC), while `-SamAccountName` sets the separate logon name. `-AccountPassword` consumes the `[SecureString]` supplied at runtime directly, so no plaintext conversion occurs anywhere in the script. `-ChangePasswordAtLogon $true` forces the user to set their own password on first logon, meaning the administrator who runs the script never knows the account's eventual credential. `-Enabled $true` makes the account usable at creation; without both a password and an explicit enable, `New-ADUser` produces a disabled account.

Role-group assignment follows creation. The account is always added to its role group, and `Linux-Admins` is added only when `-LinuxAccess` is supplied. The `else` branch prints an explicit skip message so the console output reflects which path was taken rather than silently omitting the Linux step.

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

The creation and assignment logic was written but not executed at this stage. Because these cmdlets write to Active Directory, the first live run is performed in Step Four against the test account that is later offboarded in Step Seven, keeping account creation and removal on a single, traceable object rather than creating throwaway accounts out of sequence.

<p align="center">
  <img src="../../images/automation-and-scripting/01-user-lifecycle-automation/05-account-creation-code.jpg" width="900">
</p>

<p align="center">
  <em>New-LabUser.ps1 in the editor showing the pre-flight check followed by the account creation and group assignment logic, with the conditional Linux-Admins membership.</em>
</p>

### Step Three - Implement Validation Logic

After creation and group assignment, the script validates the result by querying Active Directory back rather than trusting that the preceding cmdlets silently succeeded. Two queries gather the current state: `Get-ADUser` returns the account with its `Enabled` and `DistinguishedName` properties, and `Get-ADPrincipalGroupMembership` returns the account's group memberships, reduced to their names. `Get-ADPrincipalGroupMembership` is used here because it is the same cmdlet the offboarding script relies on in Step Six, so provisioning-validation and offboarding reason about group membership through one consistent tool.

```powershell
# Validate the result by querying AD back, rather than trusting the cmdlets above
Write-Host "Validating provisioned account against Active Directory..." -ForegroundColor Cyan

$created = Get-ADUser -Identity $SamAccountName -Properties Enabled, DistinguishedName
$groups  = Get-ADPrincipalGroupMembership -Identity $SamAccountName | Select-Object -ExpandProperty Name
```

Four checks then compare the current state against what was requested, each printing an explicit PASS or FAIL. The account must exist and be enabled, must reside in the requested OU, and must be a member of its role group.

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

The Linux-Admins check is deliberately two-sided: it passes only when membership matches the request in either direction. With `-LinuxAccess`, the account must be a member; without it, the account must not be. Checking both directions catches not only a missing membership when Linux access was requested, but also an erroneous membership when it was not, which a one-sided check would miss.

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

The OU check uses a `-like` suffix match against the distinguished name. This is a simple, readable comparison suited to the lab; if it proves too loose during the live run in Step Four, it can be tightened to parse the DN's OU components explicitly. With this logic in place, `New-LabUser.ps1` is complete end to end: pre-flight check, creation, group assignment, and self-validation. The first live run is performed in Step Four.

<p align="center">
  <img src="../../images/automation-and-scripting/01-user-lifecycle-automation/06-validation-code.jpg" width="900">
</p>

<p align="center">
  <em>New-LabUser.ps1 validation logic querying AD back after creation and printing PASS/FAIL for account existence, enabled state, OU placement, role group, and two-sided Linux-Admins membership.</em>
</p>

### Step Four - Run New-LabUser.ps1 Against a Test Account

The completed script was run from WIN11-CLIENT01, executing as `labadmin`, to provision the test account `jdoe` with Linux access. This is the account that is SSH-tested in Step Five and offboarded in Step Seven.

```powershell
.\New-LabUser.ps1 -FirstName Jane -LastName Doe -SamAccountName jdoe -RoleGroup Domain-Users-Standard -LinuxAccess
```

A complex password satisfying the domain password policy was entered at the `InitialPassword` prompt. The script ran end to end: the pre-flight check confirmed `jdoe` did not exist, the account was created in `OU=User Accounts`, it was added to `Domain-Users-Standard` and to `Linux-Admins`, and all four validation checks returned PASS.

- **PASS**: account exists and is enabled
- **PASS**: account is in the target OU (`OU=User Accounts,DC=corp,DC=home,DC=arpa`)
- **PASS**: member of role group `Domain-Users-Standard`
- **PASS**: member of `Linux-Admins` (Linux access requested)

The OU `-like` suffix match resolved correctly against the account's real distinguished name, so no adjustment to that check was needed. Because `-ChangePasswordAtLogon` was set, `jdoe` will be required to set a new password at first logon, which is exercised during the SSH test in Step Five.

<p align="center">
  <img src="../../images/automation-and-scripting/01-user-lifecycle-automation/07-run-account-creation.jpg" width="900">
</p>

<p align="center">
  <em>New-LabUser.ps1 run against jdoe with -LinuxAccess, showing the pre-flight pass, account creation, role group and Linux-Admins assignment, and all four validation checks returning PASS.</em>
</p>

### Step Five - Confirm Linux Access via SSH

With `jdoe` provisioned in AD and confirmed to be a member of `Linux-Admins`, SSH access to Ubuntu Server was tested from WIN11-CLIENT01. This is the cross-platform proof at the center of the lab: it confirms the identity chain end to end, from the PowerShell script writing to AD, to AD replicating the account and group membership, to SSSD resolving it on Linux, to PAM authorizing the session on the basis of `Linux-Admins` membership.

#### SSSD cache: account not yet resolvable

The first SSH attempt failed at the password prompt with `Permission denied`. The cause was not authorization but resolution: SSSD on Ubuntu Server had no record of the freshly created account yet, so it could not authenticate a user it could not resolve. Querying the account directly on Ubuntu Server confirmed this:

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

The resolved identity shows `linux-admins@corp.home.arpa` in the group list, confirming that the script's group assignment reached Linux intact. See the Troubleshooting section for why a service restart, rather than `sss_cache`, was required here.

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

This is the forced-password-change design working end to end: the administrator set only a temporary password, and `jdoe` set its own password on first login, which the administrator never knows. The session closed after the change, as expected, requiring a reconnect with the new password.

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

`whoami` returns the fully qualified AD identity, `id` shows the correct UID and `Linux-Admins` membership, and `klist` shows a valid Kerberos ticket-granting ticket issued by DC01 at login. The home directory was created on first login. This completes the provisioning half of the lifecycle: a single PowerShell run on Windows produced a fully functional, Kerberos-authenticated, correctly authorized Linux account.

<p align="center">
  <img src="../../images/automation-and-scripting/01-user-lifecycle-automation/09-ssh-session-success.jpg" width="900">
</p>

<p align="center">
  <em>Authenticated SSH session as jdoe@corp.home.arpa showing whoami, id with linux-admins membership, and klist with a valid Kerberos TGT for jdoe@CORP.HOME.ARPA.</em>
</p>

### Step Six - Write Remove-LabUser.ps1

The offboarding script will be written to disable the account, remove its removable group memberships while leaving the primary group intact, and validate the resulting state by querying Active Directory.

### Step Seven - Run Remove-LabUser.ps1 Against the Test Account

The offboarding script will be run against the account provisioned in Step Four, and its output recorded.

### Step Eight - Confirm SSH Access Denied After Offboarding

SSH access will be attempted as the offboarded account to confirm that access is denied. Whether the SSSD cache delay encountered in Step Five recurs will be noted.

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

**Primary group cannot be removed via `Remove-ADPrincipalGroupMembership`.** Every AD user has a primary group (Domain Users by default, RID 513). `Remove-ADPrincipalGroupMembership` cannot remove a user from their primary group and will error if asked to. An offboarding script that naively pipes every group returned by `Get-ADPrincipalGroupMembership` into removal will fail on the primary group. The intended behavior is therefore to remove *removable* security-group memberships, not literally all groups. The implementation must confirm what `Get-ADPrincipalGroupMembership` returns for the account and filter the primary group out of the removal set. This is why the offboarding language throughout this doc says "removable security-group memberships" rather than "all groups."

**SSSD did not resolve a freshly created account, and `sss_cache` did not fix it (encountered in Step Five).** After `jdoe` was created in AD, Ubuntu Server could not resolve it (`id: 'jdoe@corp.home.arpa': no such user`), which caused SSH to fail at the password prompt. The plan anticipated a stale-cache scenario resolved by targeted invalidation, but the actual behavior was different and worth recording:

- `sss_cache -u jdoe@corp.home.arpa` returned `No cache object matched the specified search`. `sss_cache` can only expire an entry that already exists in the cache; because the account had never been successfully looked up, there was no positive entry to invalidate.
- `sss_cache -E` (expire everything) also did not make the account resolve. A negative-lookup result (SSSD having recorded that the name did not exist) persisted in memory and continued to suppress re-queries to AD.
- `sudo systemctl restart sssd` resolved it immediately. Restarting the daemon clears the in-memory negative cache that `sss_cache` does not reach, forcing a fresh lookup against AD on the next request.

The practical lesson: for a stale membership change on an account SSSD has already cached, `sss_cache -u <user>` or `-g <group>` is the correct targeted tool. But for an account SSSD has never successfully resolved (a brand-new account queried too soon, where a negative-cache entry is created), a service restart is the reliable fix. Per the SSSD documentation, `sss_cache` invalidates cached records so they are re-pulled from AD on the next lookup, but it operates on existing cache objects, which is why it had nothing to act on here.

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
- [sss_cache(8) man page](https://linux.die.net/man/8/sss_cache) - flag reference (`-u` for a single user, `-g` for a single group) used to plan targeted cache invalidation; in practice `sss_cache` operates only on existing cache objects, so a negative-lookup entry for a never-resolved account required a service restart instead
- [How To Clear The SSSD Cache In Linux](https://www.rootusers.com/how-to-clear-the-sssd-cache-in-linux/) - clarifies that `sss_cache` marks entries expired rather than deleting them, which preserves offline fallback if AD is briefly unreachable during validation

**Account offboarding practice (disable vs. delete)**

- [Delete or Disable an Active Directory Account? One Best Practice - Imanami](https://www.imanami.com/delete-or-disable-an-active-directory-account-one-best-practice/) - summarizes the standard tradeoff: disabling preserves the SID and account history for reversibility and auditing, deleting removes access immediately but is not easily reversible
- [Best Practices - Disabling Users in Active Directory - ITAdminTools](https://www.itadmintools.com/2013/08/best-practices-disabling-users-in.html) - supports the offboarding approach used here (disable, remove removable group memberships, retain the account object) over outright deletion

These sources informed the Design Decisions and Troubleshooting sections above.

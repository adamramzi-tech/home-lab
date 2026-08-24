# 02 - Hybrid Identity with Entra Connect

## Status

Planning and research phase.

Lab 01 left a tenant with a verified primary custom domain and an administrative model that does not depend on Active Directory. Nothing on-premises has been modified by this track yet, `SYNC01` does not exist, and no directory object has synchronized. This document is the plan and the research behind it, written before implementation.

---

## Overview

This lab will connect the two directories. It is the point at which `corp.home.arpa` stops being the only place an identity in this environment exists.

Lab 01 built a destination and proved nothing crossed into it. The tenant holds three cloud-only administrative accounts and no ordinary users. On-premises, Active Directory holds every user, group, and computer the enterprise and automation tracks created, and it authenticates all three systems in the environment. The two have no relationship. This lab creates one, in a single direction: Active Directory remains authoritative, and a scoped subset of it is projected into Microsoft Entra ID by a synchronization engine running on a new member server.

Four things will exist at the end of it that do not exist now:

- `SYNC01`, a Windows Server 2022 member server joined to `corp.home.arpa`, running Microsoft Entra Connect Sync
- a routable user principal name suffix, `@brindeck.com`, added alongside `corp.home.arpa` and applied to the users selected for synchronization
- a synchronized population in the tenant, scoped by organizational unit, whose passwords are validated in the cloud against hashes replicated from DC01
- an observed record of how synchronization behaves over time: the cycle, at least one deliberately induced failure, and the diagnosis that resolved it

The last of those is the reason this lab is worth more than its configuration steps. A working synchronization is a wizard. A synchronization whose failure modes have been provoked and read is an operational understanding, and it is the thing every later lab in this track depends on.

---

## Objectives

The primary goals of this lab are to:

- build `SYNC01` as a dedicated domain-joined member server, keeping the synchronization engine off DC01 per [ADR-019](../architecture/decisions/019-establish-cloud-and-hybrid-identity-track.md)
- add `brindeck.com` as an alternative user principal name suffix in Active Directory and retarget the users selected for synchronization, before any synchronization runs
- update `New-LabUser.ps1` to emit the routable suffix for accounts created in synchronized organizational units, under the analysis and testing standard set by [ADR-017](../architecture/decisions/017-adopt-powershell-static-analysis-and-unit-testing.md)
- install Microsoft Entra Connect Sync with password hash synchronization, scoped by organizational unit rather than synchronizing the whole directory
- confirm that a user provisioned on-premises appears in the tenant with a matching routable user principal name and authenticates to a cloud service with their on-premises password
- enable seamless single sign-on and validate it from WIN11-CLIENT01
- document the synchronization cycle as observed, not as described, including the difference between the directory cycle and password hash synchronization
- induce at least one synchronization failure deliberately, document how it presented, and record the diagnosis

---

## Project Context

[ADR-019](../architecture/decisions/019-establish-cloud-and-hybrid-identity-track.md) established this track and settled its architecture. This lab implements the parts of that decision that touch the on-premises environment, and it is the first work in the entire repository to modify `corp.home.arpa` since the enterprise infrastructure track closed.

That is worth stating plainly, because Lab 01 could afford to be careless in a way this lab cannot. Lab 01 touched nothing on-premises; its worst outcome was a misconfigured tenant that could be deleted and rebuilt. This lab adds a user principal name suffix to a production domain, changes the sign-in names of real accounts, installs a service that writes back to Active Directory, and creates a computer account that holds a Kerberos key trusted by Microsoft. None of that is destructive, and none of it changes the domain name, the Kerberos realm, `sAMAccountName` values, DNS, or Group Policy scoping. But it is the first lab in this track where a mistake lands on the systems the Linux, enterprise, and automation tracks documented.

The environment it modifies is the one those tracks built. DC01 holds `corp.home.arpa` with four organizational units: `User Accounts`, `IT`, `Workstations`, and `Groups`. WIN11-CLIENT01 is domain-joined and carries the thirteen-script PowerShell library. Ubuntu Server authenticates domain users through SSSD and Kerberos. Wazuh collects authentication events from all three. Nothing in that arrangement changes here, and the validation for this lab includes confirming that it did not.

---

## Design Decisions

### SYNC01 is a dedicated member server, sized to Microsoft's documented floor

**Decision:** A new virtual machine, `SYNC01`, running Windows Server 2022 and joined to `corp.home.arpa`, will host Entra Connect Sync. It will be allocated 2 vCPU, 8 GB of memory, and 80 GB of thin-provisioned storage.

ADR-019 settled that the synchronization engine does not go on DC01, and that reasoning is not relitigated here. What this lab has to settle is what the machine actually needs. Microsoft's prerequisites are unambiguous about the operating system: Entra Connect "must be installed on a domain-joined server," the server "must have a full GUI installed," and "installing Microsoft Entra Connect on Windows Server Core isn't supported," which rules out both WIN11-CLIENT01 and a Core deployment. Windows Server 2025 and 2022 are the recommended versions; 2022 is chosen to match DC01 rather than for any capability reason.

Sizing is where the documentation is less helpful than it looks. Microsoft's hardware table has no tier below "fewer than 10,000 objects," and that tier asks for a 1.6 GHz CPU, 6 GB of memory, and 70 GB of disk. This environment has perhaps thirty objects in scope, so the floor is set by the software rather than the workload: Entra Connect installs SQL Server 2019 Express LocalDB by default, which "has a 10-GB size limit that enables you to manage approximately 100,000 objects," far beyond anything this directory will hold, so no separate SQL Server is required.

The allocation above rounds Microsoft's disk floor up to 80 GB to match the storage convention DC01 already uses, which costs nothing because the disk is thin provisioned and the real consumption is the operating system, a pagefile, and a database holding roughly thirty objects. The memory is rounded up for a different and more deliberate reason. Committed memory is not reclaimed lazily the way thin-provisioned disk is, so the extra 2 GB is a real allocation rather than a ceiling, and it is there because Step Nine deliberately breaks and restarts the synchronization service and provokes failures on this host. A server that will be reconfigured repeatedly is the wrong place to sit exactly on a vendor minimum. Against the host's 32 GB, with DC01 at 4 GB and WIN11-CLIENT01 at 8 GB, this brings committed memory to 20 GB and leaves the workstation the headroom the enterprise resource plan calls for. That plan's virtual machine inventory is updated by this lab rather than by a later one.

### Custom installation, not Express

**Decision:** Entra Connect will be installed using Custom settings rather than Express settings.

ADR-019 requires synchronization to be scoped by organizational unit, and Express does not offer that choice during installation. Express synchronizes "all eligible objects in all domains and all OUs." There is a documented way around it, unselecting the option to start synchronization on the final page and then rerunning the wizard to change the organizational units before enabling the schedule, but that path configures the thing correctly on the second attempt rather than the first, and it means the wizard's own summary screen describes a scope that was never intended.

Custom settings also surface decisions this lab wants visible rather than assumed: the sign-in method, the source anchor, the organizational unit filter, and the optional features are all shown and chosen rather than defaulted. For a lab whose purpose is to understand the synchronization relationship rather than to establish one quickly, the installer that asks more questions is the correct one.

### Synchronization scope is `User Accounts` and `Groups`, and `IT` is deliberately excluded

**Decision:** Only the `User Accounts` and `Groups` organizational units will synchronize. `IT` and `Workstations` will remain on-premises.

ADR-019 requires a scoped synchronization and gives the reason: the tenant should not become an unfiltered mirror of every object the environment has ever held, and filtering behavior should be observable rather than assumed. This is the specific scope that satisfies it.

`User Accounts` is the ordinary user population and the target the automation track's `New-LabUser.ps1` writes to by default, so it is the population that makes the single-identity premise demonstrable. `Groups` is included because Lab 03 has to compare what can be edited on a synchronized group against a cloud-only one, and it cannot do that without a synchronized group to look at.

`IT` is excluded on purpose, and the reason parallels ADR-019's decision to keep the tenant's administrators cloud-only. `IT` holds `labadmin`, the account that runs every script in the automation library and holds domain privilege. Keeping it out means the environment's privileged on-premises identity has no cloud presence at all, so a tenant compromise reaches no privileged on-premises account and a synchronized-account compromise reaches nothing privileged on-premises. It also leaves an organizational unit that visibly exists on one side of the boundary and not the other, which is the observable filtering property ADR-019 asked for rather than a claim about one.

`Workstations` is excluded because device objects belong to Lab 05, which takes up device join and enrollment deliberately, and because syncing computer objects here would add a population this lab has no validation planned for.

This scope creates two consequences worth predicting before they are observed.

The first is a group whose membership is partly out of scope. `IT-Admins` is a group in `Groups`, so the group object will synchronize, but its members live in `IT`, which will not. The expected result is a synchronized group whose on-premises membership is partly invisible in the tenant. That is a real property of organizational-unit filtering rather than a defect, and it is better predicted and then checked than discovered later.

The second is specific to this environment and easy to miss. Microsoft's documentation places the Active Directory connector account "in the forest root domain in the Users container," but the enterprise infrastructure track ran `redirusr` to redirect `CN=Users` to `OU=User Accounts`, which is inside the synchronization scope chosen above. If the installer creates its connector account in the redirected location, the account that performs synchronization would itself be synchronized into the tenant. Custom settings offers a choice here that Express does not, between creating a new connector account and specifying an existing one, so the resolution is to determine where a created account actually lands before enabling the schedule, and to place the account outside the synchronized scope deliberately if it does not go somewhere suitable on its own. Both consequences are called out in Validation as things to confirm rather than assume.

### The routable suffix is applied before the first synchronization, not after

**Decision:** `brindeck.com` will be added as an alternative user principal name suffix in Active Directory and applied to every user in the synchronized scope before Entra Connect is installed.

The order matters more than it appears to, and the reason is the failure mode ADR-019 identified: a non-routable user principal name does not produce a synchronization error. Microsoft documents the actual behavior plainly, that "any UPN that contains a nonroutable domain, such as `.local` (example: billa@contoso.local), is synchronized to an `.onmicrosoft.com` domain (example: billa@contoso.onmicrosoft.com)." Nothing fails. The objects arrive, the wizard reports success, and every synchronized user has a sign-in name that does not match their on-premises identity.

Doing the suffix work first means the first synchronization this environment ever performs is the correct one, and the tenant never holds a population that has to be corrected. It also means the lab can demonstrate the right outcome directly rather than demonstrating a repair.

### `New-LabUser.ps1` is updated in this lab, under the existing standard

**Decision:** `New-LabUser.ps1` will be modified to emit the routable suffix for accounts created in synchronized organizational units, and it will pass PSScriptAnalyzer and its Pester suite before this lab closes.

ADR-019 assigns this change to Lab 02 and explains why it cannot wait: the script constructs each account's user principal name from the domain name directly, so every account it creates would carry the non-routable suffix and land in the tenant under the `onmicrosoft.com` name. The provisioning path that the entire automation track was built around would quietly reintroduce, on every new hire, the exact condition the suffix work exists to prevent.

The change is narrow. The script currently derives the name as `"$SamAccountName@corp.home.arpa"`, hardcoded, while its `-TargetOU` parameter already defaults to `OU=User Accounts,DC=corp,DC=home,DC=arpa`. The suffix therefore has to become a function of the target organizational unit rather than a constant. Accounts created in a synchronized organizational unit receive `@brindeck.com`; accounts created outside one keep `@corp.home.arpa`. Per [ADR-016](../architecture/decisions/016-run-automation-scripts-from-domain-joined-client.md) it continues to run from WIN11-CLIENT01, and per ADR-017 the new branching logic is covered by tests rather than asserted to work.

### The installation runs as the cloud-only Global Administrator, so that Connect Health is enabled

**Decision:** Entra Connect will be configured using `admin@brindeck.com`, the cloud-only Global Administrator created in Lab 01, rather than a dedicated Hybrid Identity Administrator.

This trades least privilege for a diagnostic surface, and the trade is deliberate. Microsoft's prerequisites accept either role, and Hybrid Identity Administrator is the narrower of the two, so on privilege grounds alone it would be the better choice. But the documentation also states that "if you plan to use Microsoft Entra Connect Health for syncing, you need to use a Global Administrator account to install Microsoft Entra Connect Sync. If you use a Hybrid Identity Administrator account, the agent is installed but in a disabled state."

Connect Health is the surface this lab's central objective depends on. It is where synchronization errors are reported in the Entra admin center, and it is the only place one particular class of failure appears at all. Microsoft Entra applies Duplicate Attribute Resiliency by default, which means a conflicting user principal name is not rejected but quarantined and replaced with a placeholder, and the documented consequence is that "since the export for this object is successful, the sync client doesn't log an error and doesn't retry the create / update operation upon subsequent sync cycles." A quarantined attribute is therefore a failure that the synchronization engine on `SYNC01` considers a success. Diagnosing it from the server alone is not possible. A lab whose stated objective is to document synchronization failure behavior cannot give up the one surface where that failure is visible.

Two things bound the cost. The credentials are used during installation only; the documentation is explicit that they exist "only during installation" and that the account's purpose is "to create the Microsoft Entra Connector account that syncs changes to Microsoft Entra ID." And that Connector account, which is what actually runs day to day, receives the least privilege available: "a special Directory Synchronization Accounts role that has permissions to perform only directory synchronization tasks." The elevated identity is a one-time installer credential, not the running service account.

### Seamless single sign-on is enabled, with its recurring maintenance cost recorded rather than discovered

**Decision:** Seamless single sign-on will be enabled during installation and validated from WIN11-CLIENT01, and the Group Policy and key rollover work it requires will be treated as part of the lab rather than as follow-up.

Seamless SSO is in ADR-019's scope for this lab and it pairs with password hash synchronization, which the documentation confirms directly. What is easy to miss is that enabling the checkbox is not the whole job. Browsers "don't send Kerberos tickets to a cloud endpoint, like to the Microsoft Entra URL, unless you explicitly add the URL to the browser's intranet zone," so `https://autologon.microsoftazuread-sso.com` has to reach clients through Group Policy, in the Local intranet zone specifically. Microsoft's troubleshooting guidance is blunt about the near miss: putting that URL in Trusted Sites instead "blocks users from signing in."

This environment is well positioned for that, because the enterprise track already established Group Policy scoping and the automation track already built reporting against it. The new policy is scoped to the same organizational units the existing user policies use.

The part worth recording before it becomes a surprise is the standing cost. Seamless SSO creates an `AZUREADSSOACC` computer account whose Kerberos decryption key Microsoft recommends rolling "at least every 30 days" using `Update-AzureADSSOForest`, and nothing in the product does it automatically. That is a recurring administrative task this environment does not currently have any equivalent of, and it is a candidate for the Microsoft Graph PowerShell automation in Lab 06 rather than something to leave as a calendar reminder.

### Entra Connect is installed at or above the version Microsoft's September 2026 deadline requires

**Decision:** The installation will use the current Entra Connect Sync release, obtained from the Microsoft Entra admin center, and the version installed will be recorded in Validation.

This is ordinarily too mundane to be a design decision, and it is one here only because of timing. Microsoft has set a hard cutoff: "all synchronization services in Microsoft Entra Connect Sync will stop working on September 30, 2026 if you're not on at least version 2.5.79.0," and "if you're unable to upgrade before the deadline, all synchronization services will fail until you upgrade to the latest version." This lab is being planned in August 2026, roughly five weeks ahead of that date. A deployment built now on a stale installer would break within the month, during Lab 03 or Lab 04, for reasons that would have nothing to do with the work being done at the time.

The current release as of this writing is 2.6.84.0, published 7 July 2026. The installer is no longer distributed generally: the documentation notes that "the Microsoft Entra Connect Sync .msi installation file is exclusively available on Microsoft Entra Admin Center." Beyond the September deadline, Microsoft retires each 2.x version twelve months after a newer one ships, so version currency is a standing maintenance obligation for this environment rather than a one-time installation detail.

---

## Technologies Used

- Microsoft Entra Connect Sync, on `SYNC01`
- Windows Server 2022, as a domain-joined member server
- Active Directory Domains and Trusts, for the alternative user principal name suffix
- Active Directory Users and Computers, and the Active Directory PowerShell module on WIN11-CLIENT01
- Password hash synchronization
- Seamless single sign-on, with Group Policy for Intranet zone configuration
- Microsoft Entra Connect Health for sync
- Synchronization Service Manager on `SYNC01`
- PSScriptAnalyzer and Pester, for the `New-LabUser.ps1` change
- VMware Workstation Pro, for the `SYNC01` virtual machine

---

## Architecture or Topology

Lab 01 built the right-hand side of a boundary and nothing crossed it. This lab creates the crossing, in one direction only.

```text
On-premises (corp.home.arpa)                    Microsoft Entra (brindeck.com)
────────────────────────────                    ──────────────────────────────
DC01  (AD DS, AD-integrated DNS)                brindeck.onmicrosoft.com
  ├── OU=User Accounts   ──┐                      └── brindeck.com [primary]
  ├── OU=Groups          ──┤                            ├── synchronized users
  ├── OU=IT                │  in sync scope             ├── synchronized groups
  └── OU=Workstations      │                            └── cloud-only admins
                           │                                (never synchronized)
SYNC01 (Windows Server 2022, member server)
  └── Entra Connect Sync ──┘ ──── outbound HTTPS ────▶ tenant

WIN11-CLIENT01 ──── seamless SSO (Kerberos, AZUREADSSOACC) ────▶ tenant
UBUNTU-SERVER  ──── SSSD / Kerberos to DC01 only, unchanged
```

Connectivity is outbound only. Password hash synchronization was chosen in ADR-019 precisely because it requires no publicly reachable on-premises endpoint, so `SYNC01` reaches Microsoft and nothing new is exposed inbound.

Two different clocks govern what arrives and when, and conflating them is a common source of confusion this lab intends to document rather than inherit:

```text
Directory synchronization cycle          Password hash synchronization
───────────────────────────────          ─────────────────────────────
every 30 minutes by default              every 2 minutes, fixed
delta or full                            not user-configurable
Start-ADSyncSyncCycle -PolicyType        no manual trigger
users, groups, attributes                password hashes only
```

A password changed on-premises is expected in the cloud within minutes. A newly created user is not, unless the cycle is triggered by hand.

---

## Prerequisites

- Lab 01 complete: the tenant exists with `brindeck.com` verified and set primary
- host capacity for a third virtual machine alongside DC01 and WIN11-CLIENT01
- a Windows Server 2022 ISO, already present from the enterprise infrastructure track
- an Enterprise Admin credential in `corp.home.arpa` for the Active Directory side of the installation
- `admin@brindeck.com`, the cloud-only Global Administrator, with its multifactor authentication method available
- the current Entra Connect Sync installer, downloaded from the Microsoft Entra admin center
- DC01, WIN11-CLIENT01, Ubuntu Server, and the Wazuh stack all operational, so that "unchanged by this lab" can be demonstrated rather than assumed
- [ADR-019](../architecture/decisions/019-establish-cloud-and-hybrid-identity-track.md) accepted

---

## Implementation Plan

### Step One: Build SYNC01 and join the domain

Create the virtual machine to the allocation above, install Windows Server 2022 with the full desktop experience, apply updates, set the hostname to `SYNC01`, configure a static address consistent with the enterprise addressing scheme, and join `corp.home.arpa`. Confirm the computer account lands in `OU=Workstations` per the existing `redircmp` redirect, and take a pre-installation snapshot.

Enroll the Wazuh agent, so that the environment's newest system is monitored on the same terms as the other three rather than becoming the one host nothing watches.

### Step Two: Record the pre-synchronization baseline

Capture what both directories hold before anything connects them: the object counts and user principal names in each organizational unit on the Active Directory side, and the user and group counts in the tenant on the cloud side. This is the "before" that the whole lab is measured against, and Lab 01's experience with security defaults is the argument for capturing it rather than assuming it.

### Step Three: Add the routable user principal name suffix

In Active Directory Domains and Trusts, add `brindeck.com` as an alternative user principal name suffix. Confirm that `corp.home.arpa` remains present and that the domain name, Kerberos realm, and `sAMAccountName` values are untouched.

Retarget the users in `OU=User Accounts` to the new suffix, and verify that `IT` is left alone. Then confirm on Ubuntu Server that domain authentication through SSSD and Kerberos still works for a retargeted account, because that is the on-premises consequence most likely to be affected and least likely to be noticed.

### Step Four: Update New-LabUser.ps1 and prove it

Change the user principal name derivation so the suffix follows the target organizational unit rather than being hardcoded. Extend `New-LabUser.Tests.ps1` to cover both branches, run the analyzer, and confirm the full thirteen-script library still passes cleanly. Provision one account into `OU=User Accounts` and confirm it is created with `@brindeck.com`, and one into a non-synchronized organizational unit and confirm it keeps `@corp.home.arpa`.

Doing this before the first synchronization means the first objects to cross the boundary include one created by the automation library, which is the deliverable ADR-019 actually asks for.

### Step Five: Install Entra Connect Sync with Custom settings

Run the installer on `SYNC01`. Choose password hash synchronization as the sign-in method, enable seamless single sign-on, and select `User Accounts` and `Groups` as the synchronized organizational units.

Record what the wizard selects for the source anchor rather than assuming it. The documentation describes conditional logic here: the wizard uses `ms-DS-ConsistencyGuid` if that attribute is unused across the directory, and falls back to `objectGUID` if anything else has populated it. Whichever it picks is effectively permanent, since "the sourceAnchor attribute can only be set during initial installation" and changing it later means uninstalling and reinstalling.

Do not start synchronization at the end of the wizard. The scope is the thing most worth verifying before anything exports.

### Step Six: Verify scope, then run the first synchronization

With the scheduler still disabled, confirm the configured organizational unit filter matches the intent from Design Decisions, and confirm where the Active Directory connector account was actually created. The `redirusr` redirect this environment applied during the enterprise track means the container Microsoft's documentation names may resolve to an organizational unit that is inside the synchronization scope, and an account that synchronizes itself is worth catching before the first export rather than after. Then run a first cycle deliberately with `Start-ADSyncSyncCycle -PolicyType Initial` and watch it in the Synchronization Service Manager rather than waiting for the schedule.

Read the run's status rather than its completion. The Operations tab distinguishes `success` from `completed-*-errors` and `completed-*-warnings`, and a run that completes with errors is not a run that worked.

### Step Seven: Validate the synchronized population

Confirm that users from `User Accounts` appear in the tenant with `@brindeck.com` user principal names matching their on-premises identity, that groups from `Groups` appear, and that nothing from `IT` or `Workstations` arrived. Confirm specifically what happened to `IT-Admins`, whose members are out of scope.

Then confirm the premise the whole track rests on: sign in to a cloud service as a synchronized user, using the on-premises password, and have it work. Change that password on-premises and confirm the new one works in the cloud within minutes, which also demonstrates the two-minute password cycle as distinct from the thirty-minute directory cycle.

### Step Eight: Configure and validate seamless single sign-on

Confirm the `AZUREADSSOACC` computer account was created, and place it somewhere protected as Microsoft recommends. Create and link a Group Policy object adding `https://autologon.microsoftazuread-sso.com` to the Local intranet zone, scoped to the synchronized user population, and enable the associated status bar policy setting.

Validate from WIN11-CLIENT01 as a synchronized domain user: reaching a tenant sign-in page should complete without a password prompt. Record the behavior honestly if it does not, since the documentation describes the feature as opportunistic and silently falling back to a normal password prompt on failure, which means a negative result looks identical to the feature not being configured.

### Step Nine: Observe the cycle, then break it on purpose

Let the scheduler run unattended and record what a normal cycle looks like over several intervals: `Get-ADSyncScheduler` output, the run history, and how long a change made on-premises takes to appear.

Then induce a failure and document how it presents and how it is diagnosed. The candidate chosen during planning is a duplicate user principal name conflict, created by giving an on-premises account a user principal name that already belongs to a cloud-only object in the tenant. It is chosen because of how it fails rather than that it fails: with Duplicate Attribute Resiliency active, the conflicting attribute is quarantined and a placeholder assigned, the export succeeds, and the synchronization engine reports no error at all. It is the failure mode most likely to be missed in a real environment and the one that best justifies the Connect Health decision above.

A second candidate, held in reserve, is stopping the ADSync service or severing outbound connectivity from `SYNC01`, which fails loudly and at a different layer. If the first produces a thin result, the second gives a contrasting one.

### Step Ten: Validate the environment is otherwise unchanged, and record the finished state

Confirm that DC01, WIN11-CLIENT01, and Ubuntu Server still behave as the earlier tracks documented: domain authentication, Group Policy application, SSSD and Kerberos on Ubuntu Server, the Wazuh agents, and a run of the automation library's health report. Record the Entra Connect version installed, the source anchor chosen, the synchronized object counts on both sides, and the scheduler configuration.

---

## Validation

*Recorded during implementation, against observed results.*

---

## Troubleshooting and Adjustments

*Recorded during implementation, documenting issues actually encountered.*

---

## Security Considerations

This lab introduces the environment's first path from the local network to a cloud directory, and most of what follows is a consequence of that.

The synchronization account is the most consequential new credential in the environment. Entra Connect creates an Active Directory connector account for reading the directory, and password hash synchronization requires it to hold Replicate Directory Changes and Replicate Directory Changes All. Those rights are what allow it to request password hashes from a domain controller over the standard replication protocol. An account with directory replication rights is a high-value target by definition, and it lives on `SYNC01` rather than on the domain controller, which is precisely why ADR-019 put the synchronization engine on a host whose compromise does not begin at the identity foundation.

Password hash synchronization sends a hash of the on-premises password hash rather than the password or the original hash, and cloud authentication is then evaluated entirely in the cloud. This is why the method was chosen: it adds no inbound path and no on-premises dependency at sign-in. It also means the cloud directory now holds derived credential material for every synchronized user, which the tenant's administrative controls from Lab 01 are what protect.

Seamless single sign-on introduces a computer account, `AZUREADSSOACC`, whose Kerberos decryption key is shared with Microsoft Entra ID. Microsoft's guidance is explicit that this account "needs to be strongly protected," that "only Domain Admins should be able to manage the computer account," that Kerberos delegation on it must be disabled, and that it should be stored where accidental deletion is unlikely. Its key should be rolled at least every thirty days, and nothing does that automatically.

The synchronization scope is itself a security decision. Excluding `IT` keeps the environment's privileged on-premises identity out of the cloud directory entirely, so neither compromise reaches across. That is the on-premises mirror of ADR-019's decision to keep the tenant's administrators cloud-only, and the two together mean privilege on either side of the boundary does not imply privilege on the other.

One filtering behavior is worth treating as an operational hazard rather than a configuration detail. Objects that fall out of synchronization scope after having been synchronized are deleted in the cloud, and Microsoft warns specifically that renaming a synchronized organizational unit changes its distinguished name, drops it from scope, and "can potentially cause an unexpected mass deletion of objects in Microsoft Entra ID." The organizational unit names in this environment are stable, but the hazard is recorded here because the trigger is an ordinary administrative action with a wildly disproportionate result.

Identifier handling follows the policy the [track README](README.md) sets. On-premises identifiers already documented across the enterprise and automation tracks continue to appear; new cloud-side object identifiers are masked in screenshots on the same terms Lab 01 established.

---

## Outcome

*Recorded at completion.*

---

## Lessons Learned

*Recorded at completion.*

---

## Sources

**Deployment prerequisites and installation**

- [Microsoft Entra Connect Sync: Prerequisites](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/how-to-connect-install-prerequisites) - the domain-joined and full-GUI requirements that rule out WIN11-CLIENT01 and Server Core, the Windows Server 2025 and 2022 recommendation, the hardware table used to size `SYNC01`, the SQL Server Express 100,000-object ceiling, and the Global Administrator requirement for an enabled Connect Health agent
- [Select which installation type to use](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/how-to-connect-install-select-installation) - that Express synchronizes all objects in all organizational units, and the documented workaround that made Custom the cleaner choice rather than the only one
- [Custom installation of Microsoft Entra Connect](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/how-to-connect-install-custom) - the domain and organizational unit filtering page, and the source anchor options
- [Microsoft Entra Connect: Accounts and permissions](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/reference-connect-accounts-permissions) - the Replicate Directory Changes rights password hash synchronization requires, what the installer creates automatically, and the Directory Synchronization Accounts role the running connector account receives
- [Microsoft Entra Connect: Version release history](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/reference-connect-version-history) - the 30 September 2026 mandatory version deadline, the current 2.6.84.0 release, the twelve-month per-version retirement policy, and that the installer is now distributed only through the Entra admin center

**Design and synchronization behavior**

- [Microsoft Entra Connect: Design concepts](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/plan-connect-design-concepts) - the source anchor and `ms-DS-ConsistencyGuid`, the wizard's conditional selection logic, and that the choice cannot be changed without uninstalling
- [Microsoft Entra Connect Sync: Scheduler](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/how-to-connect-sync-feature-scheduler) - the 30-minute default cycle, delta versus full, `Start-ADSyncSyncCycle` and its `Delta` and `Initial` policy types, and the scheduler properties that can be read and changed
- [Password hash synchronization](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/how-to-connect-password-hash-synchronization) - that password hashes synchronize on a fixed two-minute interval independent of the directory cycle and that the interval cannot be modified
- [Configure filtering](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/how-to-connect-sync-configure-filtering) - that previously synchronized objects filtered out later are deleted in the cloud, the organizational unit rename mass-deletion hazard, and disabling the scheduler before changing scope

**Sign-in and failure behavior**

- [Microsoft Entra seamless single sign-on](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/how-to-connect-sso) - what the feature does, and that it works with password hash synchronization
- [Seamless SSO: Quickstart](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/how-to-connect-sso-quick-start) - the `AZUREADSSOACC` computer account and how to protect it, and the Group Policy Intranet zone configuration including the exact URL and policy path
- [Seamless SSO: Technical deep dive](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/how-to-connect-sso-how-it-works) - the Kerberos exchange the feature depends on
- [Seamless SSO: FAQ](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/how-to-connect-sso-faq) - the recommendation to roll the Kerberos decryption key at least every thirty days, and the `Update-AzureADSSOForest` procedure
- [Troubleshoot seamless SSO](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/tshoot-connect-sso) - that placing the sign-on URL in Trusted Sites rather than Local intranet blocks sign-in
- [Troubleshoot errors during synchronization](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/tshoot-connect-sync-errors) - the documented error classes, including duplicate attribute and data mismatch conditions
- [Duplicate attribute resiliency](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/how-to-connect-syncservice-duplicate-attribute-resiliency) - what quarantining an attribute means, and that the export succeeds so the sync client logs no error and does not retry, which is the behavior the induced failure in Step Nine is chosen to expose
- [Microsoft Entra Connect Health for sync](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/how-to-connect-health-sync) - the synchronization error report, its thirty-minute refresh, and the alerting the Global Administrator installation decision buys
- [Synchronization Service Manager: Operations tab](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/how-to-connect-sync-service-manager-ui-operations) - reading run status, and the distinction between `success` and a run that completed with errors

**Domain preparation**

- [Prepare a non-routable domain for directory synchronization](https://learn.microsoft.com/en-us/microsoft-365/enterprise/prepare-a-non-routable-domain-for-directory-synchronization) - that a non-routable user principal name does not fail but is silently synchronized to the `onmicrosoft.com` domain, which is the reason the suffix work precedes the first synchronization

# Cloud and Hybrid Identity Track

## Overview

This track will extend the on-premises `corp.home.arpa` domain built in the enterprise infrastructure track into Microsoft Entra ID, producing a hybrid identity architecture in which a single identity exists in two directories at once, with Active Directory remaining the authoritative source.

Every identity in the environment today exists in exactly one directory, and every authentication happens on the local network: Kerberos and NTLM for the Windows systems, Kerberos brokered through SSSD and PAM for Ubuntu Server. The cross-platform integration work in the enterprise track proved that Active Directory can be authoritative for a non-Windows system, but it did so within one directory on one network. This track introduces the condition that work could not reach: a synchronization process between two directories, and authentication that may be evaluated on either side of it.

The on-premises environment will continue to operate as documented. The domain name, Kerberos realm, `sAMAccountName` values, Group Policy scoping, and cross-platform authentication on Ubuntu Server are unchanged by this track. What it adds is a second directory, a synchronization engine between the two, and an administrative surface reachable from the public internet, which is the first infrastructure in this environment to have that property and the reason the tenant's administrative model is treated as a design decision rather than a setup step.

Track scope, design decisions, and boundaries are defined in [ADR-019](../architecture/decisions/019-establish-cloud-and-hybrid-identity-track.md).

---

## Architectural Context

- [ADR-014: Establish Long-Term Infrastructure Expansion Roadmap](../architecture/decisions/014-establish-long-term-infrastructure-expansion-roadmap.md)
- [ADR-019: Establish Cloud and Hybrid Identity Track](../architecture/decisions/019-establish-cloud-and-hybrid-identity-track.md)
- [ADR-016: Run Automation Scripts from a Domain-Joined Client](../architecture/decisions/016-run-automation-scripts-from-domain-joined-client.md)
- [ADR-017: Adopt PowerShell Static Analysis and Unit Testing](../architecture/decisions/017-adopt-powershell-static-analysis-and-unit-testing.md)

---

## Prerequisites

This track builds directly on the enterprise infrastructure and automation tracks. The following must remain operational:

- DC01 running Active Directory Domain Services and AD-integrated DNS for `corp.home.arpa`
- WIN11-CLIENT01 domain-joined, with RSAT tooling and the Track 3 PowerShell library present
- Ubuntu Server joined to the domain with SSSD and PAM-based access control operational
- Wazuh Manager, Indexer, and Dashboard running with agents enrolled on all three systems

The following are introduced by this track and must be in place before the labs that depend on them:

| Requirement | Introduced in | Notes |
|---|---|---|
| A registered public DNS domain | Lab 01 (met) | Verified in the tenant and added to `corp.home.arpa` as an alternative user principal name suffix. `home.arpa` is reserved by RFC 8375 and cannot be verified, so a routable domain is required before any user can synchronize with a matching sign-in name |
| A Microsoft Entra tenant | Lab 01 (met) | Created through a Microsoft 365 subscription signup, since a new tenant cannot be created from a free or trial account. The track's identity foundation depends only on Microsoft Entra ID Free; Lab 01 records what the tenant actually holds |
| `SYNC01` | Lab 02 (met) | A Windows Server 2022 member server joined to `corp.home.arpa`, hosting Entra Connect Sync. Entra Connect requires a server operating system, so WIN11-CLIENT01 cannot host it, and per ADR-019 it is deliberately not co-located on DC01. Built and domain-joined in Step One at `192.168.1.30`, running Entra Connect Sync v2.6.84.0 since Step Five |
| Workstation resources for a third virtual machine | Lab 02 (met) | `SYNC01` runs alongside DC01 and WIN11-CLIENT01 on the same host at 2 vCPU, 8 GB memory, and 80 GB thin-provisioned storage. If the host cannot support it, ADR-019 treats that as a condition for reassessing the decision rather than as an approved fallback |
| A licensed tier above Microsoft Entra ID Free | Lab 03 (met, and perishable) | A Microsoft 365 Business Premium thirty-day trial started inside the existing tenant, 25 seats, recurring billing disabled the same day, expiring 2026-10-05. Its `AAD_PREMIUM`, `EXCHANGE_S_STANDARD`, and `INTUNE_A` service plans were confirmed present and provisioned by name off the SKU rather than inferred from the tier, and carry Microsoft Entra ID P1 for Lab 03, Exchange Online Plan 1 for Lab 04, and Microsoft Intune Plan 1 for Lab 05. Unlike every other row in this table, this one expires: what to do when it does is a decision Labs 04 and 05 each take for themselves |

---

## Primary Tooling

- Microsoft Entra admin center and Microsoft 365 admin center
- Microsoft Entra Connect Sync, running on `SYNC01`
- Microsoft Graph PowerShell SDK and Exchange Online PowerShell, run from WIN11-CLIENT01 per [ADR-016](../architecture/decisions/016-run-automation-scripts-from-domain-joined-client.md)
- Existing RSAT tooling and the Track 3 PowerShell library on WIN11-CLIENT01
- PSScriptAnalyzer and Pester for any scripts this track produces, per [ADR-017](../architecture/decisions/017-adopt-powershell-static-analysis-and-unit-testing.md)

---

## Labs

Links appear here once a lab document exists; the Track Status table below records how far each has progressed.

| Lab | Focus Area |
|---|---|
| [01 - Tenant Foundation and Custom Domain](01-tenant-foundation-and-custom-domain.md) | Tenant creation, public domain registration and DNS verification, administrative role assignment, a cloud-only Global Administrator, an emergency access account excluded from policy, and multifactor authentication on administrative accounts |
| [02 - Hybrid Identity with Entra Connect](02-hybrid-identity-with-entra-connect.md) | `SYNC01` build and domain join, alternative user principal name suffix preparation in Active Directory, updating `New-LabUser.ps1` to emit the routable suffix for accounts in synchronized organizational units, Entra Connect Sync installation, organizational unit scoped synchronization, password hash synchronization, seamless single sign-on, and observed synchronization cycle and failure behavior |
| [03 - Entra ID User, Group, and License Administration](03-entra-id-user-group-and-license-administration.md) | Synchronized versus cloud-only objects and what can be edited on each, group types and membership models, dynamic group membership, license assignment models, and directory role assignment |
| 04 - Microsoft 365 Administration Workflows | Exchange Online mailbox provisioning, shared mailboxes, distribution and Microsoft 365 groups, and license assignment and removal across the hybrid user population |
| 05 - Access Control and Device Management | Multifactor authentication, conditional access policy, self-service password reset with writeback to Active Directory, and Windows device join and enrollment on WIN11-CLIENT01 |
| 06 - Hybrid Identity Automation with Microsoft Graph PowerShell | Microsoft Graph PowerShell scripts extending the Track 3 library across the identity boundary, developed and tested under the ADR-017 standard |

The comparison between Entra Connect Sync and Entra Cloud Sync required by ADR-019 will be documented against the deployed environment once Connect Sync is operational and the later labs have exercised it, rather than as a standalone lab written from product documentation.

---

## Licensing

Microsoft Entra ID Free covers the identity foundation of this track: directory synchronization, user and group administration, and administrative multifactor authentication through security defaults. Several capabilities the later labs need sit above that tier, including conditional access, self-service password reset writeback, Exchange Online mailboxes, and device management.

How the tenant was created is a separate question from what it is licensed for. A new tenant cannot be created from a free or trial account, so this one was created through a Microsoft 365 Business Basic trial signup, and it holds whatever that subscription carries for as long as it lasts. The free tier described above is what the track's identity foundation depends on rather than a claim about what the tenant holds; Lab 01 records the actual licensing state as the baseline every later lab builds on.

That trial no longer converts, and that is now a confirmed state rather than a carried assumption. Recurring billing on it had been disabled, so it lapses on 2026-09-22 instead, which Lab 03 reconfirmed on the subscription's own Billing page in Step Three and re-read fresh at Step Twelve. The decision the track owed on it is resolved in both halves: the Basic trial was not kept, and what replaced it is a trial rather than a purchase. That item is closed and no longer carries forward.

The replacement arrived one lab earlier than planned. Lab 03 needed Microsoft Entra ID P1 for dynamic membership groups and role-assignable groups, both of which are in its stated scope, so the licensing arrival [ADR-019](../architecture/decisions/019-establish-cloud-and-hybrid-identity-track.md) Design Decision 2 anticipated fell at Lab 03 rather than Lab 04. A Microsoft 365 Business Premium thirty-day trial was started from inside the existing tenant as a documented step of Lab 03, accepted without a second-trial refusal despite the tenant having already consumed a Basic trial, landing on the with-Teams line at 25 seats and expiring 2026-10-05. It carries Microsoft Entra ID P1 for that lab, Exchange Online Plan 1 for Lab 04, and Microsoft Intune Plan 1 for Lab 05 in a single subscription, all three confirmed present by service plan name rather than taken from the tier.

Trialling rather than buying is a deliberate position rather than a cost compromise, and it is recorded as one in Lab 03's Design Decisions. What this track needs from these capabilities is to operate them and document what operating them is like; it does not need to keep them. The repository documents this environment at a point in time with screenshot evidence captured as the work happens, exactly as every earlier track did, so a lab whose licensed features have since lapsed is no more invalidated by that than a lab whose configuration has since been rebuilt.

Two consequences followed and were handled in the lab rather than assumed away. Recurring billing was turned off on the new trial the day it started, because a trial converts to a paid subscription at the end of its period unless it is, which is a documented default and a real trap; the subscription page then read that the trial expires and the service ends rather than converting. And Lab 03's steps were ordered so the P1-dependent work landed early in the thirty days, ahead of the work that behaves identically on any tier. What to do when the window closes is still a decision Labs 04 and 05 each take for themselves.

Acquiring Microsoft Entra ID P1 at Lab 03 did not move conditional access earlier, and the guard held. ADR-019 Design Decision 6 keeps the security defaults to conditional access transition, and the obligation to reproduce the protections being removed rather than dropping them silently, with Lab 05. Lab 03 used P1's group and licensing capabilities only; security defaults remained enabled and untouched, and no conditional access policy was created, modified, or evaluated at any point in the lab.

One property of this arrangement is worth stating plainly, because Lab 04 will plan against it: Microsoft Entra ID P1 is carried entirely by the Business Premium trial rather than held independently of it. When that trial lapses on 2026-10-05, P1 lapses with it, and so does everything built on it, including dynamic membership evaluation, role-assignability, and group-based licensing. Microsoft Entra ID Free remains on the tenant's Your products page as its own non-assignable line and is what the tenant falls back to.

Licensing is added as the labs that need it arrive, and each lab records what its own work required, so the dependency is visible where it applies rather than assumed across the track.

---

## Cloud Configuration and Script Library

Scripts and exported configuration artifacts produced by this track are maintained in:

```text
infrastructure/cloud-and-hybrid-identity/
```

Tenant configuration is performed through administrative portals and is therefore documented by this repository rather than defined by it, which is the reverse of the relationship the compose files and script library have with the Linux and automation tracks. Exported configuration is committed only where it carries no credentials, tokens, or user data. Identifiers are handled by whether they are already public rather than by category. The tenant ID and the verified domain names appear in full, because anyone holding the domain can resolve the tenant ID from Microsoft's unauthenticated OpenID Connect discovery endpoint and publishing it reveals nothing the verified domain does not. Directory object IDs are masked in screenshots. A masked directory object ID shows its first eight characters with the remainder blacked out, so that two different objects remain visibly different without the full identifier being disclosed. Billing and subscription identifiers are omitted, and the emergency access account's user principal name is redacted as `[redacted]@brindeck.onmicrosoft.com` wherever it would otherwise appear, since from Lab 05 onward it is the one identity the tenant's conditional access policies deliberately do not constrain.

---

## Track Status

| Lab | Status |
|---|---|
| [01 - Tenant Foundation and Custom Domain](01-tenant-foundation-and-custom-domain.md) | Complete |
| [02 - Hybrid Identity with Entra Connect](02-hybrid-identity-with-entra-connect.md) | Complete |
| [03 - Entra ID User, Group, and License Administration](03-entra-id-user-group-and-license-administration.md) | Complete |
| 04 - Microsoft 365 Administration Workflows | Planned |
| 05 - Access Control and Device Management | Planned |
| 06 - Hybrid Identity Automation with Microsoft Graph PowerShell | Planned |

The track is established by [ADR-019](../architecture/decisions/019-establish-cloud-and-hybrid-identity-track.md). Lab 01 is complete: `brindeck.com` was registered on 2026-08-22 and verified in the tenant on 2026-08-23, and the tenant now has a verified primary custom domain, a cloud-only Global Administrator, and a tested emergency access account, all protected by multifactor authentication. No on-premises system was modified by it. Lab 02 is complete, and it is the first work in this track to change `corp.home.arpa`. `SYNC01` was built, domain-joined, and enrolled as a Wazuh agent; `brindeck.com` was applied as an alternative user principal name suffix to the users in `OU=User Accounts`, five at the time it was added; `New-LabUser.ps1` was changed to derive that suffix from the target OU, bringing the automation library's suite to 174 tests; and Entra Connect Sync v2.6.84.0 was installed on `SYNC01`, scoped to `OU=User Accounts` and `OU=Groups`, with password hash synchronization confirmed by a real sign-in as `testuser01@brindeck.com`. Seamless single sign-on was enabled and validated from WIN11-CLIENT01 by a password-free sign-in and a live Kerberos service ticket, with `AZUREADSSOACC` relocated into a new, delegation-restricted `OU=Protected Objects` and its Kerberos key rolled to AES. Observing the cycle found a defect rather than the behavior the objective anticipated: `SyncCycleEnabled` had been `False` since installation, so every change through Step Eight reached the tenant only by a manually forced cycle; corrected, then proven by three unattended Delta cycles landing on their own. A deliberate user principal name collision produced a Duplicate Attribute Resiliency quarantine, visible only in the tenant while the synchronization client reported a clean export, after a first attempt reproduced UPN soft match instead. The finished environment holds nine users and four groups on-premises across six organizational units, and ten users, five groups, and one application in the tenant, with DC01, WIN11-CLIENT01, and Ubuntu Server confirmed unchanged by the lab.

Lab 03 is complete, and it is the first lab in this track to operate the hybrid environment rather than build it. Nothing was deployed and no topology changed. The tenant moved from Microsoft Entra ID Free to Microsoft Entra ID Premium P1 on a Business Premium thirty-day trial with recurring billing off, and the trial's service plans were confirmed by name off the SKU rather than inferred from the tier. Five accounts were licensed directly, two cloud-only and three synchronized, with no behavioral difference between the object types at any point. `department` was populated on all six synchronized users on-premises, a domain that had carried no organizational attributes at all before this lab, and `IT-Department` was built as the environment's first dynamic membership group on `(user.department -eq "IT")`, with the round trip from an on-premises `Set-ADUser` to a cloud group membership nobody touched timed at between four and six minutes. `Finance` and `Company Announcements` were created as the first cloud-only security and Microsoft 365 groups and then licensed at the group level; `Groups-Administrators` was created as the tenant's first role-assignable group and holds Groups Administrator at Directory scope, and `testuser01` holds License Administrator, tested live rather than read off the role reference. Group-based licensing produced content the plan did not anticipate: unchecking a direct assignment on a user who is also group-licensed does not stick while the membership continues, but it does permanently consume the direct component. Delete and restore was exercised on both user object types and both cloud-only group types, settling Microsoft's own documentation contradiction in favor of the recoverability architecture guidance, and a group carrying an active license assignment turned out not to be deletable at all. The environment finished at 10 users and 9 groups in the tenant against a Step One baseline of 10 and 5, with the only persisting on-premises changes being `department` on six users and `title` on `mjohnson`, and with DC01, WIN11-CLIENT01, Ubuntu Server, and `SYNC01` confirmed otherwise unchanged.

Two items carry forward from Lab 01 rather than being closed by it: the tenant holds three Global Administrators pending the privileged role review in Lab 05, and the emergency access account needs a phishing-resistant sign-in method and a companion second account to meet Microsoft's guidance. Lab 01's third item is now closed. The Business Basic trial's 2026-09-22 date is no longer a conversion date: recurring billing on that trial was disabled, so it lapses rather than converting, and Lab 03 confirmed that directly on the subscription's own Billing page in Step Three and re-read the expiration fresh at Step Twelve. The replacement question the track deferred to Lab 04, whether to keep, cancel, or replace that subscription, was answered in Lab 03 by trialling rather than buying.

Lab 02 opened three more of its own. The Entra Connect installer recommended enabling the Active Directory Recycle Bin on `corp.home.arpa`; the recommendation is sound but the setting is forest-wide and irreversible once enabled, so it belongs to the Enterprise Infrastructure track rather than being applied mid-lab. Security Defaults were also found to enforce multifactor authentication tenant-wide rather than for administrators only, which surfaced when an ordinary synchronized user was required to register Microsoft Authenticator at first cloud sign-in. Lab 01's licensing note describing Security Defaults as covering administrative multifactor authentication is narrower than what the feature actually does; scoping it properly is Lab 05's work. Seamless single sign-on left a standing maintenance obligation the environment has no equivalent of: Microsoft recommends rolling `AZUREADSSOACC`'s Kerberos decryption key at least every thirty days, and nothing in the product does it automatically, which made it a candidate for the Microsoft Graph PowerShell automation in Lab 06 rather than a calendar reminder. Lab 03 took that item up and answered the question it turned on. Microsoft's Quickstart, Technical Deep Dive, and FAQ agree on "we highly recommend" rolling the key "at least every 30 days," none of them describes the key as expiring, the Quickstart says explicitly that the roll is not needed immediately after enabling the feature, and Defender for Identity's own hybrid posture assessment does not flag the account until its password is over ninety days old. Thirty days is a hygiene interval, not an operational deadline. Lab 06 would therefore be automating a good habit rather than meeting a deadline, which is the answer that item was opened to get.

Lab 02 also opened two items against the Infrastructure Automation and Scripting track rather than this one, and they remain held in [that track's README](../automation-and-scripting/README.md) rather than being moved here: `Get-LabWazuhAgentStatus.ps1`'s default agent list predates `SYNC01`, so the scheduled health report has never checked the one host the tenant's synchronization now depends on, and `Get-LabDockerServiceStatus.ps1`'s documentation names a Portainer account that is not the one that authenticates. Lab 03 confirmed the first of the two empirically rather than repeating it from Lab 02: `Invoke-LabHealthReport.ps1` returned `Overall: Healthy` from its hardcoded three-host default without ever asking about `SYNC01`, while an explicit four-host call showed all four agents active. Both are restated in the carry-forward list below so that this track's open items can be read in one place.

### Carrying forward from Lab 03

Ten items are open at this lab's close. Three are unresolved findings, two are objects or intervals deliberately left in place for a later lab, and five are defects or changes owed elsewhere.

Unresolved findings:

- **The Microsoft Graph group-to-license gap.** A group Microsoft Graph refuses to delete on the stated grounds that it carries an active modern license reports its own `assignedLicenses` as empty, and a user drawing a license through that group reports `licenseAssignmentStates.assignedByGroup` as `null`. The Microsoft 365 admin center and the deletion refusal both confirm the relationship; the Entra admin center's group Licenses blade and Graph both deny it. Staleness and permissions were ruled out. Recorded as a finding for a later lab or a support case, not as a conclusion.
- **The product page's six-versus-seven movement.** The Business Premium product page read 6 of 25 assigned on 2026-09-07 and 7 of 25 on 2026-09-08 against an identical composition, the only change being a group membership. Under the assignment-target counting basis Lab 03 established, adding or removing a member of an already-listed group should not move that count. The Business Basic page showed the same shape, reading 1 of 25 at Step Eight's close after `Finance` had already become a target and 2 of 25 at Step Twelve with nothing changing in between. No mechanism is proposed for either.
- **Three unreconciled service counts on one SKU.** The same Business Premium SKU reported 62 service plans through Microsoft Graph, 60 apps in the Microsoft 365 admin center, and 53 enabled services on the Entra admin center's Licenses blade. No two of the three were reconciled against each other, and what unit each is counting is not established.
Deliberately left in place:

- **`nolocation-demo01` and `Testgroup`, both retained for Labs 04 and 05.** `nolocation-demo01` was soft-deleted 2026-09-07 with permanent deletion 2026-10-07 and kept deliberately: it is the concrete artifact behind the finding that a soft-deleted object keeps its `assignedLicenses` property while consuming no seat, and purging it would destroy that for no benefit. `Testgroup` was soft-deleted 2026-09-06 with permanent deletion 2026-10-06, predates Lab 03 entirely, and was left alone in both directions, since there was no basis to restore an object of unknown composition and none to purge an artifact of unknown provenance. Both windows close before the end of October, so a later lab inherits a decision with a date on it rather than an open one.
- **The 2026-09-30 seamless single sign-on interval.** Thirty days from the Lab 02 `AZUREADSSOACC` key roll falls on 2026-09-30, 2026-10-01 in UTC. Lab 03 deliberately did not roll the key at eleven days elapsed, so that a later lab can watch a full interval elapse against a recommendation now established as hygiene rather than a deadline.
Defects and changes owed elsewhere:

- **`SYNC01`'s scheduler does not survive a VM suspend.** Resuming a suspended `SYNC01` leaves the Entra Connect scheduler's in-process timer stale: `Get-ADSyncScheduler` reports `SyncCycleEnabled: True` and `SchedulerSuspended: False` against a `NextSyncCycleStartTimeInUTC` in the past, with no cycle having actually run, while the `ADSync` service itself reports `Running` and acquires tokens normally. `Restart-Service ADSync` does not correct it; a full VM restart does. Any session that suspends that VM should expect this and know the fix in advance.
- **`Get-LabWazuhAgentStatus.ps1`'s default agent list predates `SYNC01`**, so the scheduled health report has never checked the host this track's synchronization depends on. Held against the Infrastructure Automation and Scripting track; confirmed again by Lab 03 Step Twelve.
- **`Get-LabDockerServiceStatus.ps1`'s documentation names a Portainer account that is not the one that authenticates.** Held against the Infrastructure Automation and Scripting track alongside the Wazuh agent list above, and untouched by Lab 03.
- **`New-LabUser.ps1` sets no organizational attributes**, so any account it creates lands outside `IT-Department` and any future rule keyed to `department`, `title`, or `manager`. A Lab 06 candidate under the [ADR-017](../architecture/decisions/017-adopt-powershell-static-analysis-and-unit-testing.md) analysis and testing standard rather than something a portal lab should reopen.
- **The emergency access account's user principal name needs renaming.** It should be changed before Lab 05 makes that account the one identity the tenant's conditional access policies deliberately do not constrain, so that the exclusion is written against a name chosen for the purpose rather than the one the account happens to carry. The account stays on the `onmicrosoft.com` domain and its user principal name continues to appear as `[redacted]@brindeck.onmicrosoft.com` in this track's documentation either way.

One question sits alongside those ten rather than among them, because the event that answers it is already scheduled. Whether Microsoft Entra ID Free permits group-based licensing at all is not something Lab 03 could observe: Microsoft's documentation states no tier prerequisite and the tenant's own assignment screens claimed none, but the tenant held P1 throughout. The Business Premium trial lapsing on 2026-10-05 is what would settle it, on the two groups this lab left licensed.

---

## Success Criteria

This track will be considered complete when:

- a tenant exists with a verified custom domain, documented administrative role assignments, and a tested emergency access account
- a user provisioned on-premises by the Track 3 scripts appears in Microsoft Entra ID with a matching routable user principal name and authenticates to a cloud service using their on-premises password
- synchronization scope, synchronization cycle behavior, and at least one deliberately induced synchronization failure are documented with observed results and the diagnosis that resolved them
- Microsoft Entra group and license administration is documented, including which attributes can and cannot be edited on a synchronized object compared with a cloud-only one
- Microsoft 365 workflows are documented end to end: mailbox provisioning, shared mailbox configuration, distribution and Microsoft 365 group management, and license assignment and removal
- access control is documented and validated from a client: multifactor authentication, at least one conditional access policy, and self-service password reset writing back to Active Directory
- WIN11-CLIENT01 is joined to the tenant and enrolled, with its device state observable from both the on-premises and cloud sides
- a Microsoft Graph PowerShell script set extends the Track 3 library across the hybrid boundary and passes the ADR-017 static analysis and unit testing standard
- the Entra Connect Sync and Entra Cloud Sync comparison is documented against the deployed environment

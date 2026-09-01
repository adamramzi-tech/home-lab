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
| 03 - Entra ID User, Group, and License Administration | Synchronized versus cloud-only objects and what can be edited on each, group types and membership models, dynamic group membership, license assignment models, and directory role assignment |
| 04 - Microsoft 365 Administration Workflows | Exchange Online mailbox provisioning, shared mailboxes, distribution and Microsoft 365 groups, and license assignment and removal across the hybrid user population |
| 05 - Access Control and Device Management | Multifactor authentication, conditional access policy, self-service password reset with writeback to Active Directory, and Windows device join and enrollment on WIN11-CLIENT01 |
| 06 - Hybrid Identity Automation with Microsoft Graph PowerShell | Microsoft Graph PowerShell scripts extending the Track 3 library across the identity boundary, developed and tested under the ADR-017 standard |

The comparison between Entra Connect Sync and Entra Cloud Sync required by ADR-019 will be documented against the deployed environment once Connect Sync is operational and the later labs have exercised it, rather than as a standalone lab written from product documentation.

---

## Licensing

Microsoft Entra ID Free covers the identity foundation of this track: directory synchronization, user and group administration, and administrative multifactor authentication through security defaults. Several capabilities the later labs need sit above that tier, including conditional access, self-service password reset writeback, Exchange Online mailboxes, and device management.

How the tenant was created is a separate question from what it is licensed for. A new tenant cannot be created from a free or trial account, so this one was created through a Microsoft 365 Business Basic trial signup, and it holds whatever that subscription carries for as long as it lasts. The free tier described above is what the track's identity foundation depends on rather than a claim about what the tenant holds; Lab 01 records the actual licensing state as the baseline every later lab builds on.

That trial converts to a paid subscription on 2026-09-22. Whether to keep, cancel, or replace it is a decision this track takes before Lab 04, which needs Exchange Online mailboxes and therefore a subscription of some kind. The Entra ID Free foundation survives either outcome.

Licensing is added as the labs that need it arrive, and each lab records what its own work required, so the dependency is visible where it applies rather than assumed across the track.

---

## Cloud Configuration and Script Library

Scripts and exported configuration artifacts produced by this track are maintained in:

```text
infrastructure/cloud-and-hybrid-identity/
```

Tenant configuration is performed through administrative portals and is therefore documented by this repository rather than defined by it, which is the reverse of the relationship the compose files and script library have with the Linux and automation tracks. Exported configuration is committed only where it carries no credentials, tokens, or user data. Identifiers are handled by whether they are already public rather than by category. The tenant ID and the verified domain names appear in full, because anyone holding the domain can resolve the tenant ID from Microsoft's unauthenticated OpenID Connect discovery endpoint and publishing it reveals nothing the verified domain does not. Directory object IDs are masked in screenshots, billing and subscription identifiers are omitted, and the emergency access account's user principal name is redacted as `[redacted]@brindeck.onmicrosoft.com` wherever it would otherwise appear, since from Lab 05 onward it is the one identity the tenant's conditional access policies deliberately do not constrain.

---

## Track Status

| Lab | Status |
|---|---|
| [01 - Tenant Foundation and Custom Domain](01-tenant-foundation-and-custom-domain.md) | Complete |
| [02 - Hybrid Identity with Entra Connect](02-hybrid-identity-with-entra-connect.md) | In progress: Steps One through Seven complete |
| 03 - Entra ID User, Group, and License Administration | Planned |
| 04 - Microsoft 365 Administration Workflows | Planned |
| 05 - Access Control and Device Management | Planned |
| 06 - Hybrid Identity Automation with Microsoft Graph PowerShell | Planned |

The track is established by [ADR-019](../architecture/decisions/019-establish-cloud-and-hybrid-identity-track.md). Lab 01 is complete: `brindeck.com` was registered on 2026-08-22 and verified in the tenant on 2026-08-23, and the tenant now has a verified primary custom domain, a cloud-only Global Administrator, and a tested emergency access account, all protected by multifactor authentication. No on-premises system was modified by it. Lab 02 is the first work in this track to change `corp.home.arpa`, and it is in progress. Steps One through Seven are complete: `SYNC01` is built, domain-joined, and enrolled as a Wazuh agent; `brindeck.com` is an alternative user principal name suffix applied to the users in `OU=User Accounts`, five at the time it was added; `New-LabUser.ps1` derives that suffix from the target OU; and Entra Connect Sync v2.6.84.0 is installed on `SYNC01`, scoped to `OU=User Accounts` and `OU=Groups`, with the first synchronization cycle complete and password hash synchronization confirmed by a real sign-in as `testuser01@brindeck.com`. Steps Eight through Ten, covering seamless single sign-on, the observed synchronization cycle and its deliberately induced failure, and the closing validation, are outstanding.

Three items carry forward from Lab 01 rather than being closed by it: the tenant holds three Global Administrators pending the privileged role review in Lab 05, the emergency access account needs a phishing-resistant sign-in method and a companion second account to meet Microsoft's guidance, and the Business Basic trial converts to a paid subscription on 2026-09-22.

Lab 02 has opened two more while still in progress. The Entra Connect installer recommended enabling the Active Directory Recycle Bin on `corp.home.arpa`; the recommendation is sound but the setting is forest-wide and irreversible once enabled, so it belongs to the Enterprise Infrastructure track rather than being applied mid-lab. And Security Defaults were found to enforce multifactor authentication tenant-wide rather than for administrators only, which surfaced when an ordinary synchronized user was required to register Microsoft Authenticator at first cloud sign-in. Lab 01's licensing note describing Security Defaults as covering administrative multifactor authentication is narrower than what the feature actually does; scoping it properly is Lab 05's work.

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

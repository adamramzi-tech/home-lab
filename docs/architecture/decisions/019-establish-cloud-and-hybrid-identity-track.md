# ADR-019: Establish Cloud and Hybrid Identity Track

## Status

Accepted

## Date

2026-08-22

---

## Related Decisions

Builds upon:

- [ADR-010: Establish Enterprise Infrastructure Track](010-establish-enterprise-infrastructure-track.md)
- [ADR-011: Adopt Hybrid Infrastructure Architecture](011-adopt-hybrid-infrastructure-architecture.md)
- [ADR-014: Establish Long-Term Infrastructure Expansion Roadmap](014-establish-long-term-infrastructure-expansion-roadmap.md)
- [ADR-015: Establish Infrastructure Automation and Scripting Track](015-establish-infrastructure-automation-and-scripting-track.md)
- [ADR-016: Run Automation Scripts from a Domain-Joined Client](016-run-automation-scripts-from-domain-joined-client.md)
- [ADR-017: Adopt PowerShell Static Analysis and Unit Testing](017-adopt-powershell-static-analysis-and-unit-testing.md)
- [ADR-018: Retire Cross-Platform Validation Lab](018-retire-cross-platform-validation-lab.md)

Related documentation:

- [Project README](../../../README.md)
- [Cloud and Hybrid Identity Track README](../../cloud-and-hybrid-identity/README.md)
- [01 - Tenant Foundation and Custom Domain](../../cloud-and-hybrid-identity/01-tenant-foundation-and-custom-domain.md) (the track's first lab)
- [Architecture Documentation](../README.md)
- [Topology Documentation](../topology.md)
- [Infrastructure Standards and Naming Conventions](../naming-and-scope-standards.md)
- [Recovery and Rollback Strategy](../recovery-and-rollback.md)

---

# Context

ADR-014 established a five-track expansion roadmap, three of which remained to implement, and identified Cloud and Hybrid Identity as Track 4, to follow the automation and scripting track. That track closed with Lab 05 per [ADR-018](018-retire-cross-platform-validation-lab.md). This ADR defines the scope, boundaries, and architectural constraints of Track 4 in detail.

The environment as it stands is a complete on-premises identity platform with a scripted administrative layer above it:

- DC01 running Active Directory Domain Services and AD-integrated DNS for `corp.home.arpa`
- WIN11-CLIENT01 domain-joined, with Group Policy applied and validated
- Ubuntu Server joined to the same domain through realmd, SSSD, Kerberos, and PAM
- Wazuh SIEM collecting authentication events from all three systems
- a thirteen-script PowerShell library on WIN11-CLIENT01 automating user lifecycle, group and OU administration, Group Policy reporting, and scheduled health reporting

Every identity in that environment exists in exactly one directory. Authentication happens entirely on the LAN: Kerberos and NTLM for Windows systems, Kerberos brokered through SSSD and PAM for Ubuntu Server. Nothing in the environment authenticates against, or is visible to, any service outside the local network. The cross-platform integration work in the enterprise track proved that Active Directory can be authoritative for a non-Windows system, but it did so within a single directory on a single network segment.

Hybrid identity introduces a condition the current environment cannot demonstrate at all: one identity existing simultaneously in two directories, with one authoritative source, a synchronization process between them, and authentication that may be evaluated on either side. Most organizations that still run Active Directory now operate this way, and a great deal of identity administration happens across that boundary rather than on one side of it. Extending `corp.home.arpa` into Microsoft Entra ID is therefore the largest single increase in architectural realism available to this environment, and it requires no changes to the on-premises foundation beyond the synchronization configuration itself.

This track also introduces something no previous track has: an identity system whose administrative control plane sits on the public internet. Every service built so far is LAN-only, reachable through Tailscale, published through NGINX Proxy Manager, or not exposed at all. The environment does already depend on two external consoles, Tailscale's and the domain registrar's, but neither holds its directory. A Microsoft Entra tenant is a publicly reachable identity system whose administrative surface is internet-facing by definition, and it cannot be placed behind the reverse proxy or the VPN. That changes what the environment's security posture has to account for, and the decisions below reflect it.

Four constraints surfaced during planning that materially shape the track.

**The on-premises domain name cannot be used in the cloud.**

`corp.home.arpa` was selected for the on-premises domain during the enterprise infrastructure track. The `home.arpa` name is reserved by RFC 8375 for residential and home networks. It is not registrable, not publicly resolvable, and cannot be verified in a Microsoft Entra tenant. Microsoft Entra accepts a user principal name suffix only for a domain that has been added to the tenant and verified through a DNS record, which is impossible for a name nobody can own.

Synchronizing the directory without addressing this does not fail. It does something worse: every synchronized user arrives in the tenant with a user principal name of `user@tenant.onmicrosoft.com`, which does not match their on-premises sign-in name. The single-identity premise the track exists to demonstrate is broken at the first step, and domain verification, DNS record management, and mail routing disappear from scope along with it.

Microsoft documents the resolution: add an alternative user principal name suffix in Active Directory that is publicly routable, verify that same domain in the tenant, and retarget user principal names before synchronization begins. This requires registering a public DNS domain. It is worth being precise about what that does and does not change, because the distinction is easy to miss: an Active Directory forest's DNS name and its users' user principal name suffixes are separate attributes. Adding an alternative suffix does not rename the domain, does not alter the Kerberos realm, does not change `sAMAccountName` values, domain membership, DNS, or Group Policy scoping, and does not affect anything documented in the Linux, enterprise, or automation tracks. It adds a second sign-in name format for users who are selected to receive it.

**The tenant's capabilities are licensed, and not all of them permanently.**

The Microsoft 365 developer sandbox, which once offered a durable feature-complete tenant to anyone who signed up, is now restricted to a narrow set of subscribers and partner programs and runs on an activity-gated lifecycle. It is not a foundation a documented environment can rest on.

The track is therefore built on a tenant licensed to what the environment actually requires. Microsoft Entra ID Free covers the identity foundation, including directory synchronization, while several capabilities the later labs need sit above that tier: conditional access, self-service password reset with on-premises writeback, Exchange Online mailboxes, and device management. Creating a tenant at all is subject to the same licensing reality, since Microsoft restricts creation of a new Workforce tenant to customers holding an eligible subscription, so the tenant is created through a Microsoft 365 signup rather than from a free Azure account.

Each lab states what its work required, so the licensing a capability depends on is visible in the lab that uses it rather than assumed from the tenant as a whole.

**Two supported synchronization engines now exist.**

Microsoft Entra Connect Sync installs a full synchronization server on Windows Server, holds its configuration on-premises, and carries the broader feature set. Microsoft Entra Cloud Sync uses a lightweight provisioning agent with cloud-managed configuration, supports multiple active agents, and is Microsoft's stated strategic direction for new deployments, while still lacking some Connect Sync capabilities.

ADR-014 named Entra Connect. That remains the right primary choice here, but the fork itself is now part of the operational landscape: most existing Active Directory environments run Connect Sync, while new deployments increasingly receive Cloud Sync. Treating the choice as settled without documenting the comparison would misrepresent the current state of hybrid identity.

**The synchronization engine requires a Windows Server host.**

Entra Connect Sync requires a domain-joined Windows Server with a full graphical installation; Microsoft's current prerequisites name Windows Server 2025 and Windows Server 2022 as the recommended versions, with older releases supported only while in extended support. A client operating system is not supported, which rules out WIN11-CLIENT01. The environment's only server is DC01, and a domain controller is not the domain-joined member server those prerequisites describe. Beyond what Microsoft recommends, installing the synchronization engine there would place a synchronization service, a local database, and outbound internet traffic on the host that every other system in the environment depends on for identity.

---

# Decision

The homelab project would formally establish the Cloud and Hybrid Identity track as Track 4 in the expansion roadmap defined by ADR-014.

## Scope

The track extends the existing on-premises Active Directory environment into Microsoft Entra ID and operates the resulting hybrid identity architecture. Scope includes:

- tenant foundation: tenant creation, custom domain registration and verification, administrative role assignment, and emergency access account design
- hybrid identity configuration: user principal name suffix preparation, Entra Connect Sync deployment, synchronization scoping, password hash synchronization, seamless single sign-on, and synchronization validation and failure behavior
- Microsoft Entra ID user, group, and license administration, including the operational differences between synchronized and cloud-only objects
- Microsoft 365 administration workflows: mailbox provisioning, shared mailboxes, distribution and Microsoft 365 groups, and license assignment and removal
- access control and device management: multifactor authentication, conditional access policy, self-service password reset with on-premises writeback, and Windows device join and enrollment
- hybrid identity automation using the Microsoft Graph PowerShell SDK, extending the Track 3 script library across the identity boundary
- a documented comparison of Entra Connect Sync and Entra Cloud Sync, evaluated after the Connect Sync deployment is operational

## Design Decisions

**1. A registered public domain provides the routable user principal name suffix.**

A public DNS domain is registered, verified in the tenant through a DNS record, added as an alternative user principal name suffix in `corp.home.arpa`, and applied to the users selected for synchronization. The domain registered for this purpose is `brindeck.com`, with `brindeck.onmicrosoft.com` as the tenant's matching initial domain; Brindeck is the fictional organization this environment represents. A tenant's initial domain can never be renamed or removed once the tenant exists, so the two names are decided together rather than separately. The Active Directory domain name, Kerberos realm, `sAMAccountName` values, domain membership, DNS configuration, and Group Policy scoping are unchanged, and the on-premises environment continues to operate exactly as the Linux, enterprise, and automation tracks documented it.

The Track 3 script library is in scope for one narrow consequence of this. `New-LabUser.ps1` constructs each new account's user principal name from the domain name directly, so every account it creates would carry the non-routable suffix and synchronize under the tenant's `onmicrosoft.com` name, which is the exact failure this decision exists to prevent. Lab 02 updates that script to emit the routable suffix for accounts created in synchronized organizational units, under the analysis and testing standard ADR-017 already applies to it.

**2. Tenant licensing follows what the labs require.**

The identity foundation sits on Microsoft Entra ID Free, which covers directory synchronization, user and group administration, and administrative multifactor authentication through security defaults. Capabilities above that tier are licensed as the labs that need them arrive, and each lab records what its work required.

**3. Entra Connect Sync is deployed on a dedicated domain-joined member server.**

A new virtual machine, `SYNC01`, running Windows Server 2022 and joined to `corp.home.arpa`, hosts the synchronization engine. DC01 remains a domain controller and nothing else. Windows Server 2022 is chosen to match DC01 rather than for any capability reason; Windows Server 2025 is equally supported and would be an acceptable substitute.

The reasoning is operational rather than doctrinal. The synchronization engine is the component this track will most often reconfigure, restart, and deliberately break in order to document how synchronization failures present and how they are diagnosed. Performing that work on the domain controller places the environment's entire identity foundation, including cross-platform authentication on Ubuntu Server and the automation library's only target, behind the outcome of every synchronization experiment. Separating the roles isolates that risk to a host whose loss means nothing more than a rebuild.

**4. Password hash synchronization is the authentication method.**

Password hash synchronization sends a hash of the on-premises password hash to Microsoft Entra ID, so cloud authentication is evaluated entirely in the cloud with no on-premises dependency at sign-in. The alternatives were considered and rejected: pass-through authentication keeps evaluation on-premises through agents, adding a dependency that fails whenever the workstation hosting the environment is off, and federation requires a server farm, certificate management, and a publicly reachable endpoint. Password hash synchronization is Microsoft's recommended default and the only one of the three that adds no internet-exposed on-premises infrastructure to a LAN-only environment.

**5. Synchronization scope is limited by organizational unit.**

Only designated organizational units synchronize to the tenant. Service accounts, test accounts, and objects created during earlier labs remain on-premises unless deliberately included. This prevents the tenant from becoming an unfiltered mirror of every object the environment has ever held, and it makes filtering behavior itself an observable, documentable property rather than an assumed one.

**6. Cloud administration uses a separate identity, with a break-glass account.**

The tenant's Global Administrator is a cloud-only account rather than a synchronized on-premises account, so a synchronization failure or an on-premises compromise cannot remove administrative access to the tenant or extend into it. A second cloud-only emergency access account is created and excluded from conditional access policies, with its credentials stored offline.

Multifactor authentication is required on all administrative accounts from the first lab onward, and the mechanism enforcing it changes as licensing does. On the free tier this is security defaults, which also block legacy authentication protocols and device code flow. Conditional access cannot coexist with security defaults, so the lab that introduces conditional access must disable security defaults and reproduce the protections being removed rather than dropping them silently. Accounts holding the Directory Synchronization Accounts role are excluded from security defaults, so enabling them does not interfere with Entra Connect.

This is the first component of the environment's own identity plane whose administrative interface is reachable from the public internet, and it is treated accordingly. The environment already accepts two external control planes in the Tailscale admin console and the domain registrar's dashboard; what is new here is that the directory itself now has one, and unlike every service published through NGINX Proxy Manager it cannot be placed behind the reverse proxy or confined to Tailscale.

**7. All cloud automation uses the Microsoft Graph PowerShell SDK.**

The MSOnline and AzureAD PowerShell modules were retired during 2025, with Microsoft Graph PowerShell as their supported replacement. Scripts produced by this track run from WIN11-CLIENT01 per ADR-016 and are subject to the PSScriptAnalyzer and Pester standard established by ADR-017, so the cloud scripts join the existing library under the same quality bar rather than beside it under a looser one.

## Boundaries

The track does not include:

- Azure infrastructure or resource administration: no virtual machines, storage, or virtual networks in Azure
- federation deployment of any kind, including AD FS
- Exchange hybrid configuration or mailbox migration, as no on-premises Exchange organization exists
- production, personal, or otherwise real data in the tenant
- renaming or restructuring the on-premises Active Directory domain
- network segmentation, deferred to Track 5

## Primary Tooling

- Microsoft Entra admin center and Microsoft 365 admin center
- Microsoft Entra Connect Sync on `SYNC01`
- Microsoft Graph PowerShell SDK and Exchange Online PowerShell, run from WIN11-CLIENT01
- existing RSAT tooling and the Track 3 PowerShell library on WIN11-CLIENT01
- PSScriptAnalyzer and Pester for any scripts produced, per ADR-017

## Deliverables

When the track is complete:

- a tenant exists with a verified custom domain, documented administrative role assignments, and a tested emergency access account
- a user provisioned on-premises by the Track 3 scripts appears in Microsoft Entra ID with a matching routable user principal name and authenticates to a cloud service using their on-premises password
- synchronization scope, synchronization cycle behavior, and at least one deliberately induced synchronization failure are documented with observed results and diagnosis
- Microsoft Entra group and license administration is documented, including which attributes can and cannot be edited on a synchronized object compared with a cloud-only one
- Microsoft 365 workflows are documented end to end: mailbox provisioning, shared mailbox configuration, distribution and Microsoft 365 group management, and license assignment and removal
- access control is documented and validated from a client: multifactor authentication, at least one conditional access policy, and self-service password reset writing back to Active Directory
- WIN11-CLIENT01 is joined to the tenant and enrolled, with its device state observable from both the on-premises and cloud sides
- a Microsoft Graph PowerShell script set extends the Track 3 library across the hybrid boundary and passes the ADR-017 standard
- the Connect Sync and Cloud Sync comparison is documented against the deployed environment rather than against product documentation alone

The track will remain:

- documented to the same standard as previous tracks
- incrementally implemented through a sequence of numbered labs
- architecture-driven, with each lab scoped to a coherent operational problem
- explicit about what licensing each lab's work required

---

# Alternatives Considered

## Use Only the Tenant's onmicrosoft.com Domain

Advantages:

- no external dependency and no registrar or DNS zone to maintain
- no DNS verification step before synchronization can begin
- fastest path to a working tenant

Reasons rejected:

- every synchronized user would sign in with a name that does not match their on-premises identity, breaking the single-identity premise the track exists to demonstrate
- domain verification, DNS record management, and mail routing would be removed from scope entirely
- the resulting environment could not demonstrate the configuration most real hybrid deployments use
- what the alternative avoids is trivial next to the capability it gives up

## Install Entra Connect on DC01

Advantages:

- no additional virtual machine and no additional host resource consumption
- a common shortcut in very small environments, where the domain controller is the only server available
- fewer systems to build, patch, and document

Reasons rejected:

- it places a synchronization service, a local database, and outbound internet traffic on the domain controller
- the synchronization engine is the component this track will deliberately break and rebuild, and doing that on DC01 puts Active Directory, cross-platform authentication on Ubuntu Server, and the automation library's only target at risk with every experiment
- Microsoft does not recommend it, and the reasons Microsoft gives apply directly to this environment
- separating the roles is what a professionally managed environment would do, and the separation requires only one minimally sized virtual machine

## Deploy Cloud Sync Instead of Connect Sync

Advantages:

- Microsoft's stated strategic direction for new deployments
- a lightweight agent with no synchronization server to build or maintain
- cloud-managed configuration and support for multiple agents

Reasons rejected:

- ADR-014 specifies Entra Connect, and Connect Sync remains what most existing Active Directory environments run, giving it broader operational applicability
- Connect Sync carries the wider feature set, so building on it first leaves fewer capabilities out of reach mid-track
- evaluating Cloud Sync after a working Connect Sync deployment produces a comparison grounded in the environment rather than in product documentation
- the comparison is more valuable as a documented evaluation than the choice would be as a silent default

## Deploy Federation with AD FS

Advantages:

- demonstrates federated authentication, still present in some environments
- keeps authentication evaluation fully on-premises

Reasons rejected:

- requires a federation server farm, certificate management, and a publicly reachable endpoint, which conflicts directly with the environment's LAN-only posture and would require inbound exposure it has deliberately avoided since ADR-004
- Microsoft recommends password hash synchronization for most organizations, making federation the less representative choice as well as the more complex one
- the failure modes it would introduce are infrastructure failure modes rather than identity ones, which is not what this track is for

## Defer the Track Until Network Infrastructure Is Complete

Advantages:

- network segmentation would exist before any internet-facing service is introduced
- perimeter policy could govern the hybrid boundary from the outset

Reasons rejected:

- inconsistent with the sequencing ADR-014 established and the dependency reasoning behind it
- hybrid identity has no dependency on network segmentation, while Track 5's identity-aware access control does depend on hybrid identity existing
- the tenant's exposure is a cloud control plane rather than a new on-premises listening service, so segmentation would not materially reduce the risk it introduces
- deferring would leave the environment's most significant architectural gap open in order to close a less consequential one first

---

# Consequences

## Positive Outcomes

- the environment moves from a single-directory on-premises architecture to a hybrid one, matching how Active Directory environments commonly operate
- identity administration gains a second authoritative surface, exercised against the same users and groups the earlier tracks created rather than against a synthetic population
- the Track 3 automation patterns extend into Microsoft Graph PowerShell rather than being superseded by it, and the resulting scripts join the existing library under the same analysis and testing standard
- the environment acquires internet-facing service administration and the security practices it demands, including administrative multifactor authentication, emergency access accounts, and separation of cloud administrative identity from on-premises identity, none of which any prior track has required
- synchronization failure behavior becomes a documentable operational subject, isolated on a host whose loss carries no consequence for the rest of the environment
- the topology gains a documented hybrid identity boundary, which is a stated input to the identity-aware access control planned for Track 5

## Tradeoffs

- this is the first track to depend on providers outside the environment's control: a domain registration that has to be maintained, and a tenant that exists on Microsoft's licensing terms rather than the environment's own
- capabilities above the free tier depend on licensing rather than on configuration, so what the environment can do is partly a function of what it is licensed for at the time
- a third virtual machine increases resource consumption on the workstation that also hosts DC01 and WIN11-CLIENT01
- tenant configuration is performed largely through web portals whose interfaces change frequently, so screenshots in this track will date faster than the command output that documents the earlier tracks
- cloud-side configuration is not version-controlled the way the compose files and script library are, so the repository documents that configuration rather than defining it, and drift between the two is possible in a way it is not on-premises

These tradeoffs are considered acceptable given that hybrid identity cannot be demonstrated at all without an external directory, and that every one of them is a property of the platform rather than of this environment's design.

---

# Future Reassessment

This track scope may be revisited if:

- the workstation cannot support a dedicated synchronization server, in which case co-location on DC01 is reconsidered with its tradeoffs documented at the time
- Microsoft retires or materially changes Entra Connect Sync, making Cloud Sync the only supported synchronization path
- Microsoft changes what the free tier includes, or what a capability the track depends on requires
- the Microsoft 365 administration scope expands enough to warrant separating it from hybrid identity as its own track
- Track 5 network segmentation introduces requirements that affect hybrid connectivity or the placement of the synchronization server
- the registered domain is retired or replaced, which would require re-verification and user principal name changes across both directories

# 01 - Tenant Foundation and Custom Domain

## Status

Planning and research phase.

One prerequisite is already met: `brindeck.com` was registered on 2026-08-22 through Cloudflare Registrar, with WHOIS redaction enabled and DNS hosted at the registrar. No tenant exists yet, and nothing in the on-premises environment has been modified.

---

## Overview

This lab will create the environment's first cloud identity plane: a Microsoft Entra tenant, a verified custom domain, and an administrative model to operate it.

Everything built so far authenticates against a single directory on the local network. This lab does not connect the two directories, and no user, group, or password will synchronize during it. It builds the destination that Lab 02 will later synchronize into, and it establishes who is allowed to administer that destination and how they will prove it.

Three things will exist at the end of it that do not exist now:

- a Microsoft Entra tenant, permanently named `brindeck.onmicrosoft.com`
- `brindeck.com` verified in that tenant, which is what makes a routable user principal name suffix possible in Lab 02
- an administrative model that does not depend on the on-premises domain: a cloud-only Global Administrator, a separate emergency access account, and multifactor authentication required for administrative sign-in

That last point is the reason this lab exists as its own step rather than as the opening section of the synchronization lab. This is the first infrastructure in the environment whose administrative interface is reachable from the public internet, and it cannot be placed behind NGINX Proxy Manager or confined to Tailscale the way every existing service is. The controls protecting it have to be in place before anything of value is put in it.

---

## Objectives

The primary goals of this lab are to:

- create a Microsoft Entra tenant whose permanent initial domain matches the registered public domain
- verify `brindeck.com` in the tenant through a DNS TXT record, establishing ownership of a namespace the on-premises domain cannot provide
- establish an administrative model that survives a synchronization failure: a cloud-only Global Administrator and a separate emergency access account, neither dependent on Active Directory
- require multifactor authentication for administrative sign-in as the first control applied to the environment's first internet-facing administrative surface
- record the tenant's licensing state, so later labs build on a known starting point
- leave the tenant in a state where Lab 02 can add the alternative user principal name suffix and begin synchronization without revisiting tenant setup

---

## Project Context

[ADR-019](../architecture/decisions/019-establish-cloud-and-hybrid-identity-track.md) established this track and defined its scope, design decisions, and boundaries. This is its first lab.

The environment it extends is complete on its own terms. Active Directory Domain Services on DC01 is authoritative for identity across the domain controller itself, a domain-joined Windows client, and an Ubuntu Server host authenticating through SSSD and Kerberos. A thirteen-script PowerShell library administers it. Wazuh collects authentication events from all three systems. What none of it has is any presence outside the local network, or any identity that exists in more than one directory.

The reason this lab comes before synchronization is that a tenant is not a neutral container. Two of its properties are permanent from the moment it is created, and both are decided here: the `onmicrosoft.com` initial domain, which can never be changed, and the identity of the account that creates it, which becomes Global Administrator automatically. Getting either wrong is not something Lab 02 can correct.

The domain registration that preceded this lab is the direct consequence of a constraint ADR-019 documented: `corp.home.arpa` cannot be used in the cloud. The `home.arpa` name is reserved by RFC 8375 for home networks. It is not registrable, not publicly resolvable, and cannot be verified in a tenant, because verification requires publishing a DNS record in a zone you demonstrably control. Without a routable domain, every synchronized user would arrive in the tenant as `someone@brindeck.onmicrosoft.com`, with a sign-in name that does not match their on-premises identity, and the single-identity premise the track exists to demonstrate would be broken at the first step.

---

## Design Decisions

### Tenant creation path

**Decision:** The tenant will be created through a Microsoft 365 subscription signup rather than from an Azure account.

Planning assumed a tenant could simply be created and named from a free account. Microsoft's tenant creation documentation restricts creation of a new Workforce tenant to customers holding an eligible subscription, which rules that path out. The Microsoft 365 signup flow creates a first tenant rather than an additional one, and it sets the initial domain during signup. That second property is what makes it the correct path here, because the initial domain is permanent and needs to match the registered domain.

What the tenant is licensed for afterward is a separate question from how it was created, and each lab records what its own work required.

### The initial domain is chosen to match the registered domain

**Decision:** The tenant's initial domain will be `brindeck.onmicrosoft.com`.

The initial `onmicrosoft.com` domain is set at tenant creation and can never be renamed or removed, because Microsoft 365 uses it behind the scenes for the subscription itself. It is not cosmetic: it appears in service URLs, in the emergency access account's user principal name, and in any account that cannot use the custom domain. A tenant whose two halves do not match, for example a custom domain of `brindeck.com` behind an initial domain derived from a personal email address, advertises itself as improvised in every screenshot for the life of the environment.

There is a partial escape hatch, and it is worth knowing before the signup screen rather than after. A tenant may hold up to five `onmicrosoft.com` domains, and a later one can be created and made the default fallback domain, so a wrong prefix can be worked around even though the original cannot be deleted. That is a repair, not a substitute for getting it right at creation, since the initial domain remains visible in the tenant permanently.

The prefix was confirmed unused before the domain was registered, by querying Microsoft's tenant discovery endpoint for `brindeck.onmicrosoft.com` and receiving a tenant-not-found response. The domain name and the prefix were treated as a single availability question rather than two, because taking one without the other produces the mismatch above.

### Administrative identities are cloud-only

**Decision:** The Global Administrator used to operate the tenant and the emergency access account will both be created directly in the tenant as cloud-only accounts, and neither will ever be synchronized from Active Directory.

This follows ADR-019 and the reasoning is worth restating in the place it takes effect. A synchronized administrator makes tenant access a dependent of the synchronization relationship and of on-premises security. If synchronization breaks, if DC01 is unavailable, or if an on-premises account is compromised, a synchronized Global Administrator carries that failure into the tenant. A cloud-only administrator does not.

The emergency access account exists for a narrower case: recovering access when the normal administrative path is blocked, whether by a misconfigured policy, a lost authentication method, or a lockout. It will be created here, kept on `brindeck.onmicrosoft.com` rather than the custom domain so that a DNS or registration problem with `brindeck.com` cannot lock the tenant, and excluded from conditional access policies in Lab 05 when those policies exist. Its credentials are stored offline and it is not used for routine work.

Exclusion is not available before Lab 05, and that has a consequence worth planning for rather than discovering. Security defaults have no exclusion mechanism beyond the Directory Synchronization Accounts role, so from the moment they are enabled in Step Seven until conditional access replaces them, the emergency access account is required to register for and perform multifactor authentication like any other user. That determines what storing its credentials offline has to mean: the stored material must include a recoverable second factor rather than a password alone, or the account meant to recover access becomes dependent on a single device that can be lost with it.

### Multifactor authentication in this lab uses security defaults

**Decision:** Administrative multifactor authentication will be enforced through security defaults in this lab, with conditional access deferred to Lab 05.

Conditional access requires a Microsoft Entra ID P1 license, which this tenant does not hold; Lab 05 licenses it when it needs it. Security defaults are a free-tier feature that requires multifactor authentication for the Global Administrator and the other privileged administrative roles, requires all users to register for it, blocks legacy authentication protocols, and blocks device code flow.

Two properties of security defaults reach beyond this lab, which is why the progression itself is recorded in [ADR-019](../architecture/decisions/019-establish-cloud-and-hybrid-identity-track.md) rather than only here. Security defaults and conditional access are mutually exclusive, so Lab 05 must disable security defaults when it introduces conditional access, and the policies it writes must reproduce the legacy authentication and device code flow blocks being turned off rather than silently dropping them. And accounts holding the Directory Synchronization Accounts role, which is what Entra Connect creates and uses in Lab 02, are excluded from security defaults and are neither prompted to register for nor required to perform multifactor authentication, so enabling them here does not break synchronization later.

### The custom domain becomes the primary domain, the emergency account does not follow it

**Decision:** `brindeck.com` will be set as the tenant's primary domain once verified, so that new accounts default to it, while the emergency access account deliberately remains on `brindeck.onmicrosoft.com`.

The primary domain determines the default suffix offered when accounts are created, which is what makes `@brindeck.com` the ordinary case rather than something set per user. The exception is deliberate: the `onmicrosoft.com` domain is guaranteed by Microsoft and cannot lapse, while a custom domain depends on a registration and a DNS zone that can both fail. Keeping the recovery account on the guaranteed name means a domain-level failure cannot take administrative access with it.

---

## Technologies Used

- Microsoft Entra ID
- Microsoft Entra admin center and Microsoft 365 admin center
- Cloudflare DNS, hosting the `brindeck.com` zone
- DNS TXT records, for domain ownership verification
- Microsoft Entra multifactor authentication through security defaults

---

## Architecture or Topology

This lab creates the right-hand side of a boundary that does not yet exist. Nothing crosses it until Lab 02.

```text
On-premises (unchanged by this lab)          Microsoft Entra (created by this lab)
─────────────────────────────────            ──────────────────────────────────────
corp.home.arpa (DC01)                        brindeck.onmicrosoft.com  [permanent]
  ├── users, groups, OUs                       └── brindeck.com  [verified, primary]
  ├── Kerberos / NTLM                                ├── Global Administrator (cloud-only)
  └── SSSD / PAM (Ubuntu Server)                     └── Emergency access account
                                                          (stays on onmicrosoft.com)

                    no synchronization exists yet
```

Domain verification is the only interaction with anything outside the tenant, and it runs through DNS rather than through the on-premises environment:

```text
Entra admin center
    ↓ issues a TXT record value
Cloudflare DNS (brindeck.com zone)
    ↓ record published
Entra verification check
    ↓ record observed
brindeck.com marked Verified in the tenant
```

---

## Prerequisites

- `brindeck.com` registered, with DNS hosted at Cloudflare and the ability to create records in the zone
- a Microsoft account for the subscription signup
- a method for the administrative account's multifactor authentication, an authenticator app on a device that is not the lab workstation
- somewhere offline to store the emergency access account credentials
- [ADR-019](../architecture/decisions/019-establish-cloud-and-hybrid-identity-track.md) accepted

No on-premises prerequisites apply. This lab does not touch DC01, WIN11-CLIENT01, or Ubuntu Server.

---

## Implementation Plan

### Step One: Create the tenant

Sign up through the Microsoft 365 flow, entering `Brindeck` as the organization name, `brindeck` as the initial domain, and United States as the country. The country cannot be changed later and determines the tenant's data residency.

Confirm the initial domain reads `brindeck.onmicrosoft.com` before completing signup. If the flow assigns something else, stop and reconsider rather than proceeding, since the initial domain can never be renamed or removed and the workaround, adding a second `onmicrosoft.com` domain as the fallback, leaves the original in place permanently.

The account created during signup becomes Global Administrator automatically. Record which account that is; Step Six creates the cloud-only administrator that replaces it for routine work.

### Step Two: Record the tenant's starting state

Capture the tenant ID, the initial domain, the subscription and its licenses, and the default administrative account before making changes. This is the baseline every later change in the track is measured against, and the point at which the tenant is a known quantity.

### Step Three: Add the custom domain and collect the verification record

In the Entra admin center, add `brindeck.com` as a custom domain. Entra will issue a TXT record value to publish in the domain's DNS zone. The record proves control of the namespace rather than ownership of the name, which is why it must be published in the zone the domain's nameservers actually serve.

### Step Four: Publish the TXT record in Cloudflare DNS

Create the TXT record in the `brindeck.com` zone exactly as issued. Cloudflare's proxy setting does not apply to TXT records, so no orange-cloud decision arises here. Confirm the record resolves publicly before returning to Entra.

### Step Five: Verify the domain and set it primary

Return to the Entra admin center and run verification. Once `brindeck.com` shows as verified, set it as the tenant's primary domain so new accounts default to it.

### Step Six: Create the administrative accounts

Create the cloud-only Global Administrator that will operate the tenant from this point forward, on `@brindeck.com`. Create the emergency access account on `@brindeck.onmicrosoft.com`, assign it Global Administrator, and store its credentials offline. Document what each account is for, since the distinction is meaningless six months later without it.

### Step Seven: Enable security defaults and register multifactor authentication

Enable security defaults, then sign in as the new administrative account and complete multifactor authentication registration. Record the behavior of the emergency access account under security defaults rather than assuming it, since its exclusion from conditional access does not arrive until Lab 05.

### Step Eight: Validate and record the finished state

Confirm the domain is verified and primary, that administrative sign-in requires multifactor authentication, that the emergency access account can sign in, and that the tenant's licensing state is recorded.

---

## Validation

*Recorded during implementation, against observed results.*

---

## Troubleshooting and Adjustments

*Recorded during implementation, documenting issues actually encountered.*

---

## Security Considerations

This lab introduces the environment's first internet-facing administrative surface, and most of its content is a response to that fact.

The tenant's administration portals are reachable by anyone who can reach Microsoft, authenticated only by credentials. There is no network boundary to hide behind, no reverse proxy to place in front of it, and no VPN that scopes who can attempt a sign-in. Every previous service in this environment had at least one of those. This one has none, which is why multifactor authentication is applied in the same lab that creates the tenant rather than in a later hardening pass.

The administrative model is built to fail independently of the on-premises environment. A cloud-only Global Administrator means a compromise of `corp.home.arpa` does not extend to the tenant, and a synchronization failure does not remove administrative access. The emergency access account extends the same reasoning one step further: it is the account that works when the normal path does not, which is why it stays on the `onmicrosoft.com` domain that cannot lapse and why its credentials live offline rather than in a password manager tied to the same identity it is meant to recover.

Security defaults also block legacy authentication protocols and device code flow, both of which are common paths around multifactor authentication. That protection is inherited rather than designed here, and Lab 05 must consciously reproduce it when conditional access replaces security defaults, since disabling security defaults removes all of it at once.

The registrant details behind `brindeck.com` are redacted in WHOIS, and no screenshot in this lab will show the registrar's account or contact panels.

---

## Outcome

*Recorded at completion.*

---

## Lessons Learned

*Recorded at completion.*

---

## Sources

**Tenant creation and licensing**

- [Quickstart: Create a new tenant in Microsoft Entra ID](https://learn.microsoft.com/en-us/entra/fundamentals/create-new-tenant) - tenant creation steps, the paid-customer prerequisite, and confirmation that the initial `onmicrosoft.com` domain cannot be changed after creation
- [Microsoft 365 Developer Program FAQ](https://learn.microsoft.com/en-us/office/developer-program/microsoft-365-developer-program-faq) - why the developer sandbox is not the basis for this track: eligibility is limited to Visual Studio Professional or Enterprise subscribers, eligible partner program tiers, and Premier or Unified Support customers, and sandboxes run a 90-day activity-gated lifecycle

**Domain and identity**

- [Prepare a non-routable domain for directory synchronization](https://learn.microsoft.com/en-us/microsoft-365/enterprise/prepare-a-non-routable-domain-for-directory-synchronization) - why `corp.home.arpa` cannot be synchronized as-is and what a routable alternative suffix resolves, the constraint that made the domain registration a prerequisite
- [Domains FAQ](https://learn.microsoft.com/en-us/microsoft-365/admin/setup/domains-faq) - that the initial `onmicrosoft.com` domain cannot be renamed or removed, that a tenant may hold up to five of them, and that a later one can be made the default fallback domain

**Administrative controls**

- [Security defaults in Microsoft Entra ID](https://learn.microsoft.com/en-us/entra/fundamentals/security-defaults) - what security defaults enforce, that Directory Synchronization Accounts are excluded from them, and that they cannot coexist with conditional access policies

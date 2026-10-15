# 05 - Access Control and Device Management

## Status

Planning and research. Not started. No trial has been started, and nothing in the tenant or on the virtual machines has changed for this lab.

The lab runs against one clock it starts itself and two it inherits. The Microsoft Intune Plan 1 and Microsoft Entra ID P2 trials are started together in Step Six, which opens a single thirty-day window that Steps Six through Ten depend on; nothing before Step Six needs either trial. testuser01's delay release hold falls due between 2026-10-24 and 2026-10-28, and the assignment records Lab 04 left on suspended SKUs are expected to go when Microsoft's grace period ends, around early November. Both are read when their dates arrive, from whatever step the lab is standing in.

---

## Overview

Lab 01 got administrative multifactor authentication by finding security defaults already on, and every lab since has run under that one switch. It requires registration and multifactor authentication tenant-wide, blocks legacy authentication and device code flow, and offers no scoping and no exclusions. This lab replaces it with conditional access, the policy engine Microsoft Entra ID P1 licenses, and gives the tenant three things a switch cannot: a deliberate scope for each protection, an excluded emergency path, and a device signal.

The device signal is the second half of the lab. WIN11-CLIENT01 has been domain-joined since the enterprise track and has never been visible to the tenant. This lab makes it a Microsoft Entra hybrid joined device, enrolls it in Microsoft Intune through Group Policy, evaluates it against a compliance policy, and uses the result in an access decision, so that one workstation's state can be read on four surfaces: the client, its Active Directory computer object, its Microsoft Entra device record, and its Intune record. Self-service password reset with writeback works in the other direction, landing a cloud-initiated password change on DC01 under DC01's own password policy.

The lab is also the track's privileged access review. Before any policy exists, it renames and strengthens the emergency access account Lab 01 created, adds the second account Microsoft's guidance calls for, and reduces Global Administrator to the accounts that need it. And because the licensing behind conditional access is a trial, the lab ends by restoring security defaults, so the tenant leaves the trial protected by the mechanism it entered with.

---

## Objectives

The primary goals of this lab are to:

- rename the existing emergency access account, give it a phishing-resistant method, and create a second one that does not depend on the same device, before any conditional access policy exists
- reduce Global Administrator to Cloud Administrator and the two emergency access accounts, moving the signup account to Billing Administrator with its billing access confirmed
- hybrid join WIN11-CLIENT01 through a narrow change to the synchronization scope, while the tenant is still on Free
- start both trials on one day, confirm `AAD_PREMIUM` and `INTUNE_A` by service plan name, and turn off recurring billing on both
- replace each security defaults protection with its own conditional access policy, run in report-only mode and read in the sign-in logs before it is turned on, with the emergency access accounts excluded, and validate each from a client
- enable self-service password reset with writeback for a pilot group, and record how a cloud-initiated reset meets DC01's password policy
- enroll WIN11-CLIENT01 in Intune through Group Policy and require a compliant device for testuser01
- commit a prediction of what the trial lapse does before the trials start, and read the outcome after
- turn conditional access off and security defaults back on before the trial ends
- dispose of every open item in the track README, and confirm that what this lab does not change is unchanged

---

## Project Context

[ADR-019](../architecture/decisions/019-establish-cloud-and-hybrid-identity-track.md) gives this lab its scope and one obligation. Design Decision 6 says conditional access cannot coexist with security defaults, so the lab that introduces it must reproduce the protections it removes rather than drop them, and that the emergency access account is excluded from conditional access. Design Decision 5 makes synchronization scope a deliberate act, which governs how a computer object enters it.

Lab 04 closed with the tenant at Microsoft Entra ID Free, no enabled license units, and twenty open items in the [track README](README.md). This plan takes a position on every one of them.

| Item | Disposition | Why |
|---|---|---|
| The Microsoft Graph group-to-license gap | Owned by Lab 05 for one reading; closure passes to Lab 06 | If Step Six assigns a license to a group, Graph is read on the group and its member while the SKU is enabled |
| The 2026-10-05 versus 2026-10-06 expiry discrepancy | Owned by Lab 05 | Two new trials give two more pairs of dates, read in Steps Six and Ten |
| Whether Microsoft Entra ID Free permits group-based licensing | Owned by Lab 05, conditionally | Testable only if the Intune SKU carries no `AAD_PREMIUM`: Step Six assigns it to a group before starting the P2 trial |
| The Viva Engage group | Owned by Lab 05 | Microsoft documents it as the Answers backing group, owned by every Global Administrator. Steps One and Three read its owners. It is left in place |
| The Connect Health alert | Owned by Lab 05 | Connect Health requires P1, and the alert arrived on the date Microsoft's notice gave for the Business Premium expiry. Steps One and Six read it on Free and with P1 restored, testing that explanation |
| testuser01's archive and delay release hold | Owned by Lab 05 | A pinned reading after 2026-10-28 |
| The licensing state | Closed by Lab 05 | Design Decisions settle it: two trials, no purchase |
| `nolocation-demo01` | Closed by Lab 05 | Step One confirms the purge |
| Ubuntu Server's resolver failover | Held against the Linux track | Step Ten applies the `systemd-resolved` restart if it recurs, as Lab 04 did |
| `New-LabUser.ps1` sets no organizational attributes | Passes to Lab 06 | A script change under ADR-017 |
| Whether the mail attribute set is cloud-editable | Passes to Lab 06 | Part of the identity boundary ADR-019 gives Lab 06 |
| Automating the `AZUREADSSOACC` key roll | Passes to Lab 06 | Step One records the key's age, now past forty days |
| The emergency access account's user principal name | Closed by Lab 05 | Step Two |
| Three Global Administrators | Closed by Lab 05 | Step Three |
| A phishing-resistant method and a second emergency access account | Closed by Lab 05 | Step Two, with any single-device limitation stated as a risk rather than closed over |
| Security defaults enforcing tenant-wide | Closed by Lab 05 | Scoping is a conditional access property. Step Seven covers administrators and users with separate policies; after Step Ten, security defaults are tenant-wide again, the only shape they have on Free |
| `Get-LabWazuhAgentStatus.ps1`'s default agent list | Held against the automation track | Step Ten works around it with an explicit agent list |
| `Get-LabDockerServiceStatus.ps1`'s Portainer account | Held against the automation track | Not touched |
| `SYNC01`'s scheduler after a suspend | Held in the track README | Applied in Prerequisites |
| The Active Directory Recycle Bin | Held against the enterprise track | Forest-wide and irreversible |

---

## Design Decisions

### Licensing is two trials started on one day, and P2 is used only for what P1 provides

**Decision:** The Microsoft Intune Plan 1 trial is started from inside the tenant as `admin@brindeck.com`, and the Microsoft Entra ID P2 trial is started the same day, so the lab has one thirty-day window. P2 is used only for its P1 features.

The Intune signup page offers the trial to this tenant and states that it includes the same features as the paid product. Standalone Intune Plan 1 may not carry Microsoft Entra ID P1, which conditional access, writeback, and automatic MDM enrollment all require. Microsoft's Intune licensing page calls the Intune free trial an Enterprise Mobility + Security subscription that includes P1 or P2, but it describes the signup that creates a new tenant, not an in-tenant trial. The P2 trial is started regardless, and Step Six reads what each SKU carries by service plan name, as Lab 03 did.

Buying was considered and rejected on cost; the thirty-day clock is accepted. Privileged Identity Management, ID Protection, and risk-based policies are P2 features and are out of scope. Recurring billing is turned off on both trials in the sitting that starts them, because a trial converts to a paid subscription at its end unless it is.

Four dates bound the window: each trial's stated Expiration and its Recurring billing date, which differed by a day on Business Premium. The lab plans against the earliest of the four.

### The work is sequenced in three phases, and the trials start only after the Free-tier work is done

**Decision:** Steps One through Five run on Microsoft Entra ID Free. Step Six starts the trials. Steps Six through Nine run inside the trial. Step Ten is the exit, finished no later than two days before the earliest of the four dates, followed by readings after the lapse.

Every day of Free-tier work done inside the window is a day the licensed work loses, so everything that does not need P1 or Intune happens first. Passkeys are available in every edition including Free, role assignment is a Free capability, and Microsoft's hybrid join prerequisites name an Entra Connect version, a synchronization scope, and two administrative roles but no license. Writeback is split: the Active Directory permissions are on-premises and go in on Free, while Microsoft's writeback tutorial requires P1 or a trial for the feature as a whole without saying whether the Entra Connect switch itself checks. Step Five attempts the switch on Free and records the result; if it is refused, it moves to Step Eight.

The two-day margin is set from Lab 04, which read Business Premium Active on its stated date and Disabled within two days of it, with no reading in between.

### Security defaults are replaced protection by protection, not dropped

**Decision:** Each protection security defaults provides becomes its own conditional access policy. Each runs in report-only mode and is read in the sign-in logs before it is turned on. A cloud-only `Emergency-Access` group holding both emergency access accounts is excluded from every policy, and the Directory Synchronization Accounts role is excluded from every policy that targets all users.

Microsoft's security defaults article lists six protections. The mapping:

| Security defaults protection | Replacement | Note |
|---|---|---|
| Require all users to register for multifactor authentication | CA02 | No separate policy; an unregistered user is expected to be sent to registration by CA02's first prompt, which Step Seven checks |
| Require administrators to do multifactor authentication | CA01, the sixteen roles security defaults names, all resources | Billing Administrator is among them, so the signup account stays covered after Step Three |
| Require users to do multifactor authentication when necessary | CA02, all users, all resources | Stricter than the original, which let Microsoft decide when to prompt |
| Block legacy authentication protocols | CA03, client apps Exchange ActiveSync and Other clients | |
| Block device code flow | CA04, authentication flows condition | |
| Protect privileged activities like access to the Azure portal | CA05, Windows Azure Service Management API | |

CA06, the compliant-device policy, is the lab's own addition and is covered under the Intune decision below.

Microsoft's all-users templates exclude the Directory Synchronization Accounts role, and its planning guidance notes that calls made by service principals are not blocked by policies scoped to users. New Entra Connect installations from version 2.5.76.0 use application-based authentication, so Lab 02's 2.6.84.0 installation probably authenticates as a service principal. Step One reads `Get-ADSyncEntraConnectorCredential` and the role's members; the exclusion is applied either way, as the templates do.

Microsoft's guidance says policies can be created while security defaults are on but not turned on. Step Seven tries to create all five in report-only mode with security defaults still enforcing, so the report-only reading costs no protection. If the portal refuses, the report-only period becomes a period with no enforcement, held to one sitting.

Two mechanisms can change this picture. Microsoft-managed policies are created in report-only mode in eligible tenants, turned on no sooner than thirty days later, and can be edited for state and exclusions but not deleted. Any that appear are recorded, given the `Emergency-Access` exclusion, and left in report-only until the exit. And an updated security defaults experience, in private preview for selected Free tenants, coexists with conditional access. If Step One finds it here, the premise of ADR-019 Design Decision 6 no longer holds, and that is recorded before Step Seven proceeds.

Mandatory multifactor authentication for the Microsoft admin portals applies regardless, including to emergency access accounts. Sign-in logs name the application that enforced a requirement, which separates it from CA05.

### The exit turns conditional access off and restores security defaults before the trial ends

**Decision:** Before the trial ends, every conditional access policy, the lab's own and any Microsoft-managed, is set to Off, and security defaults are turned back on. Both are recorded.

Without this step the tenant would leave the trial with no multifactor enforcement once P1 lapses. Microsoft's licensing article states that when the licenses conditional access requires expire, policies are not disabled or deleted, and can be viewed and deleted but no longer updated. A policy left On at the lapse could then no longer be turned Off, only deleted.

Microsoft's documentation is not consistent about what enabling security defaults requires. One Microsoft 365 article says security defaults can be enabled once all conditional access policies are disabled. Another quotes the portal text shown when one or more policies exist: that the organization is using conditional access policies, which prevents enabling security defaults. Disabled and exists are different conditions, and Microsoft-managed policies cannot be deleted. Step Ten turns everything Off and reads which text the portal shows. If Off is not enough, the lab's own policies are exported through Microsoft Graph and deleted, and if Microsoft-managed policies still block it, that is recorded as a finding the exit could not resolve.

Microsoft's security defaults article recommends revoking existing sessions when enabling security defaults, so the next sign-in is evaluated under them. Step Ten does this for the three licensed users.

### Three users are licensed, and the emergency access accounts are not

**Decision:** testuser01, Cloud Administrator, and Jane Doe receive both trial licenses. The emergency access accounts stay unlicensed.

testuser01 is the writeback and enrollment subject. Cloud Administrator is the account the administrator policy is tested against. Jane Doe is the control: licensed, signed in to the same policies, never enrolled, and outside CA06, so every result for testuser01 has a comparison that differs in one respect. The emergency access accounts need no license because no policy applies to them.

Two consequences are recorded rather than designed away. CA01 and CA02 reach accounts that hold no P1 license, including the signup account, while Microsoft's licensing pages for self-service password reset and Intune state that a license is required for any user who benefits. And testuser01 holds License Administrator from Lab 03. Microsoft applies a fixed two-gate reset policy to anyone holding that role and recommends testing reset as a user without administrator roles, so Step Three removes the assignment before Step Eight depends on it. Jane Doe holds Groups Administrator through `Groups-Administrators`, which is outside both CA01's roles and the reset pilot, so her role is left alone.

### Emergency access is rebuilt on Free, before any policy can exclude it

**Decision:** The existing emergency access account is renamed and given a device-bound passkey in Microsoft Authenticator. A second cloud-only emergency access account is created with a passkey that lives on a different device. Both join `Emergency-Access`, both are tested with a cold sign-in, and both keep their credentials offline.

The rename comes first. The new name stays on `brindeck.onmicrosoft.com` and stays redacted as `[redacted]@brindeck.onmicrosoft.com`. Microsoft documents that passkeys cannot be modified after a user principal name change and must be deleted and registered again, so a rename after registration would undo it.

Microsoft's passkeys article states that passkeys are available in all editions, including Free. Intune's passwordless planning page lists passkeys and Temporary Access Pass under P1, and Microsoft's multifactor licensing table does not mark FIDO2 as a security defaults method. This track settles conflicts against the tenant: Step Two registers on Free and proves the result with a cold sign-in under security defaults.

Passkey profiles are enabled, which cannot be undone. One allows Authenticator passkeys, device-bound, with attestation enforced; a second allows Windows Hello passkeys, which Microsoft requires to be unattested. The second account's passkey is a Microsoft Entra passkey on Windows in the Windows Hello container of the physical workstation that hosts the lab: device-bound, not synced, and usable without the device being joined, which keeps it off the phone. Bootstrapping it without the phone needs a Temporary Access Pass. If none can be issued on Free, security defaults require Authenticator registration on the phone first, and Step Two removes that method once the passkey works. If the second account cannot be made independent of the phone, that is stated as a risk.

The first account does not fully meet Microsoft's guidance either, which says emergency access accounts should not be tied to an individual's phone or share methods with normal administrative accounts. Its passkey is a different method from Cloud Administrator's Authenticator push, but on the same phone. The phone number Lab 01 added is removed once the passkey works, since it is phishable and the second account covers the loss of the phone.

No password, passkey detail, or recovery code is recorded anywhere in this repository.

### Global Administrator ends with three accounts, none of them the signup account

**Decision:** Adam Ramzi, the signup account, moves from Global Administrator to Billing Administrator. Global Administrator ends with Cloud Administrator and the two emergency access accounts.

Lab 01 kept Global Administrator on the signup account because it owns the subscription. Billing Administrator covers that ownership without directory administration: Microsoft describes it as making purchases, managing subscriptions and support tickets, and monitoring service health, with full permission over billing. Billing account roles are separate from directory roles, and the person who signed up is automatically a billing account owner. Step Three reads the billing account roles before and after, so the claim that billing access survived rests on the tenant.

Billing Administrator is assigned before Global Administrator is removed, and the removal is made by Cloud Administrator, since a Global Administrator cannot remove their own assignment. The Answers backing group's owners are every Global Administrator, so the role change is also read there.

### WIN11-CLIENT01 is hybrid joined through a narrow scope change, then enrolled through Group Policy

**Decision:** WIN11-CLIENT01 moves to a new child organizational unit, `OU=Hybrid Workstations,OU=Workstations`, which is added to Entra Connect's synchronization scope. Hybrid join is configured in Entra Connect on Free. The Intune enrollment Group Policy Object is built on Free and linked to the new OU only once the trial is active.

The settled decision was to add the OU holding WIN11-CLIENT01 to the scope, and to say so if that OU brought anything else with it. It would. The [topology document](../architecture/topology.md) places WIN11-CLIENT01, `SYNC01`, and UBUNTU-SERVER in `OU=Workstations`, and Microsoft lists Windows Server 2022 as a supported hybrid join platform, so adding that OU would register `SYNC01` as a device too. DC01 sits in Domain Controllers and is unaffected either way. A child OU holding only WIN11-CLIENT01 is the narrowest scope that works, and it keeps every link inherited from `OU=Workstations`, including `Workstation-Security-Baseline`. Adding it is the deliberate inclusion ADR-019 Design Decision 5 asks for.

Entra Connect configures hybrid join by writing a forest-wide service connection point, using Enterprise Admin credentials. `SYNC01` will therefore find it and may try to join, but its computer object stays out of scope and cannot complete registration. Microsoft's targeted deployment, a client-side registry setting in place of the forest object, would prevent the attempt, but the scope is the control this track uses, so it is not taken; `SYNC01`'s device state is read instead.

The enrollment policy is "Enable automatic MDM enrollment using default Microsoft Entra credentials", set to User Credential. Microsoft states that automatic MDM enrollment needs P1 and an Intune subscription and that the enrolling user needs an Intune license, so linking waits for Step Nine.

### Intune scope is one compliance policy and one policy that requires it

**Decision:** One Windows compliance policy, and one conditional access policy, CA06, requiring a compliant device for testuser01 only.

The compliance settings are chosen against what Step One reads on WIN11-CLIENT01, so the policy measures the device rather than failing on hardware the virtual machine does not have. BitLocker and Secure Boot are attested at boot through Device Health Attestation, and Microsoft notes devices without TPM 2.0 report Secure Boot as Not Compliant, so they are included only if Step One shows them available. The tenant-wide setting for devices with no compliance policy stays at its default, Compliant, and is recorded; Microsoft recommends Not compliant when conditional access is in use, but CA06 reaches one user.

The MDM user scope is Some, set to an `MDM-Pilot` group holding testuser01. CA06 targets testuser01 and all resources. Microsoft notes that requiring a compliant device does not block Intune enrollment, so the order of Step Nine is not circular.

CA02 is a different question. Group Policy enrollment authenticates silently with the token from testuser01's Windows sign-in, which carries no multifactor claim. Microsoft's co-management troubleshooting guidance documents enrollment failing with `AADSTS50076` when a policy requires multifactor authentication for all cloud apps, and gives the fix as excluding the Microsoft Intune app (`0000000a-0000-0000-c000-000000000000`) from that policy. That guidance is written for devices co-managed with Configuration Manager, which this environment does not have, so Step Nine attempts enrollment with CA02 unchanged first. If it fails, the documented exclusion is added to CA02, enrollment is retried, and both results are recorded.

### Self-service password reset writes back to Active Directory under DC01's own policy

**Decision:** Password writeback is enabled in Entra Connect, and `svc-entraconnect` receives the permissions Microsoft documents on `OU=User Accounts` only. Self-service password reset is scoped to an `SSPR-Pilot` group, not All. DC01's password policy is left as it is, and its interaction with a cloud-initiated reset is recorded.

Microsoft's tutorial lists Reset password, Change password, and write access to `lockoutTime` and `pwdLastSet` on descendant user objects, plus the Unexpire Password extended right on the root of each domain. The first four scope to `OU=User Accounts` as decided. Unexpire Password is a domain-root right that the decision's OU-only scope excludes, so it is not granted; Step Eight watches for any operation that fails for lack of it.

Writeback commits through the Active Directory password-setting interface, which Microsoft says enforces on-premises history, complexity, age, and password filters, and the tutorial recommends a minimum password age of zero. DC01's policy is not changed for the lab. A reset inside the minimum age is expected to be refused, and the step records the refusal or its absence.

Microsoft also documents that writeback cannot change passwords for members of protected groups, and that an administrator reset is written back from the Microsoft Entra admin center but not from the Microsoft 365 admin center. Free covers only cloud-only password change; reset with writeback needs P1 or Business Premium.

### Lab 04's lapsed trial records are left to Microsoft's grace period

**Decision:** The Business Premium and Business Basic assignment records on suspended SKUs are left alone, and the lab records whether and when they disappear.

Lab 04 found both trials went straight to Disabled with no Expired status. Its Step One had already found the lifecycle note behind that: Microsoft's subscription lifecycle article says the Expired status no longer applies, from 2026-02-09, to license-based subscriptions bought directly under a Microsoft Customer Agreement, and its Step Six read the billing account as "Products connected to Brindeck (MCA)." The new trials sit on the same billing account.

### The lapse is predicted before the trials start

**Decision:** The predictions below are committed with this document, before Step Six, and are not revised afterward. Step Ten reads the outcome after the later of the four dates.

| Subject | What Microsoft documents | Prediction |
|---|---|---|
| Both trials | The lifecycle article above; the Expired status no longer applies to direct Microsoft Customer Agreement subscriptions | Both go straight to Disabled with SKUs `Suspended`, and each trial's Expiration and Recurring billing dates differ by one day, as Business Premium's did |
| Conditional access policies, all Off after the exit | Kept, viewable, and deletable, but not updatable after the license expires | All persist; an edit is refused; deletion still works |
| A policy left On at the lapse | Nothing about enforcement | Not observable. The exit must turn every policy Off to restore security defaults, so after the lapse every prompt comes from security defaults |
| Hybrid join | No license prerequisite | Unaffected. `dsregcmd /status` still reads `AzureAdJoined : YES` and the device record persists |
| The Intune-enrolled device | Nothing found about a lapsed Intune trial; compliance status expires after a validity period of thirty days by default | The client stays enrolled and its check-ins fail; the Entra device record keeps Microsoft Intune as its MDM and its last compliance state, which does not change within the reading window |
| Self-service reset with writeback | Writeback needs P1 for users | testuser01's self-service reset is refused; an administrator reset from the Microsoft Entra admin center is still written back, held with low confidence |

The enrollment Group Policy Object is unlinked in the exit, so a retrying enrollment task does not add noise to the client's event logs.

---

## Technologies Used

- Microsoft Entra ID P2 trial, used for its P1 capabilities, and Microsoft Intune Plan 1 trial
- Microsoft Entra admin center, Microsoft Intune admin center, and Microsoft 365 admin center
- Microsoft Entra Connect Sync 2.6.84.0 on `SYNC01`, for hybrid join and password writeback
- Active Directory Users and Computers, Group Policy Management, and RSAT
- Microsoft Authenticator and Windows Hello, one for each emergency access passkey
- Microsoft Graph PowerShell SDK from WIN11-CLIENT01 per ADR-016, for reads and policy export. No script is committed, so ADR-017 is not engaged
- `dsregcmd`, `gpresult`, and Task Scheduler on WIN11-CLIENT01

---

## Architecture or Topology

Two boundaries move. A computer object crosses into the tenant for the first time, and password changes start crossing back.

```text
corp.home.arpa                                  brindeck.onmicrosoft.com
──────────────                                  ────────────────────────
OU=User Accounts ──────── users, hashes ──────▶ synchronized users
   ▲                                                │ SSPR (SSPR-Pilot)
   └── SetPassword ◀── svc-entraconnect ◀── relay ◀─┘ writeback over 443
OU=Groups ─────────────── groups ─────────────▶ synchronized groups
OU=Workstations                                     (out of scope)
   ├── SYNC01, UBUNTU-SERVER
   └── OU=Hybrid Workstations ─────────────────▶ device record, hybrid joined
          └── WIN11-CLIENT01 ── MDM enrollment ─▶ Intune, compliance ─▶ CA06
CN=Configuration ── service connection point (forest-wide)

Cloud-only: Cloud Administrator, two emergency access accounts (Emergency-Access,
excluded from CA01 to CA06), Billing Administrator (signup account)
```

All traffic stays outbound. Writeback uses a Service Bus relay over port 443, and hybrid join needs only outbound access to Microsoft's registration and sign-in endpoints, so nothing new listens on the network.

---

## Prerequisites

| Requirement | Source | State |
|---|---|---|
| Directory synchronization running on schedule | Lab 02 | To confirm in Step One after the virtual machines start |
| `svc-entraconnect` as the AD DS connector account, in `OU=Service Accounts` | Lab 02 | Met |
| Enterprise Admin credentials, for the service connection point | Enterprise track | Met |
| WIN11-CLIENT01 on a Windows edition that supports hybrid join and MDM enrollment | Enterprise track | To confirm in Step One |
| A phone running iOS 17 or Android 14 or later with Authenticator | Lab 01 | To confirm in Step Two |
| A physical workstation that supports Windows Hello | This lab | To confirm in Step Two |
| The Intune trial offered to this tenant | This lab | Confirmed on the signup page, stopped before Continue |
| testuser01 able to sign in to WIN11-CLIENT01 interactively | Enterprise track | To confirm in Step One |

**Virtual machine start order.** DC01 starts first, then `SYNC01` and WIN11-CLIENT01. On `SYNC01`, `Get-ADSyncScheduler` must show `NextSyncCycleStartTimeInUTC` in the future before any step relies on synchronization. A time in the past means the scheduler did not survive a suspend, which only a full restart of the virtual machine corrects.

---

## Implementation

Ten steps in three phases. Steps One through Five run on Free. Step Six starts the trials, and Steps Six through Nine run inside them. Step Ten is the exit, finished no later than two days before the earliest of the four dates, followed by the readings after the lapse.

Three readings are pinned to dates rather than steps: testuser01's hold, once after 2026-10-28; the assignment records on the suspended SKUs, weekly from 2026-11-01 until they go or the lab closes; and the lapse itself, after the later of the four dates.

### Step One: Record the Free-tier baseline

Read everything this plan cannot know yet, before changing anything.

- **Synchronization.** `Get-ADSyncScheduler`, the last cycle's result, `Get-ADSyncEntraConnectorCredential`'s `ConnectorIdentityType`, the members of Directory Synchronization Accounts, and the Connect Health blade with its alert.
- **WIN11-CLIENT01.** Distinguished name, Windows edition and build, `Get-Tpm`, `Confirm-SecureBootUEFI`, and `dsregcmd /status`, expected to read `AzureAdJoined : NO`. `Get-ADComputer -SearchBase "OU=Workstations,DC=corp,DC=home,DC=arpa"` lists the OU's objects. testuser01 signs in interactively once.
- **Tenant policy.** The security defaults panel, recording which experience it shows; Conditional Access > Policies, recording any Microsoft-managed policy left by the Business Premium window; the Authentication methods policy, method by method, including whether Temporary Access Pass can be enabled; Password reset properties; Device settings.
- **Roles.** Every directory role assignment, including group-based ones, read with `Get-MgRoleManagementDirectoryRoleAssignment`.
- **Emergency access account.** Its registered method types, by type only.
- **On-premises.** `Get-ADDefaultDomainPasswordPolicy`, the existing ACL on `OU=User Accounts` for `svc-entraconnect`, and `AZUREADSSOACC`'s `PasswordLastSet`.
- **Licensing and residue.** `Get-MgSubscribedSku` for both suspended SKUs, the Viva Engage group's owners and creation record, and Deleted users for `nolocation-demo01`.

Counts of users, groups, and devices are read live from the Overview. **Output:** a baseline that Step Ten compares against, and a decision recorded if security defaults show the updated experience.

### Step Two: Rebuild emergency access

Rename the existing emergency access account's user principal name, keeping it on `brindeck.onmicrosoft.com`. Opt in to passkey profiles. Create the Authenticator profile and the Windows Hello profile as Design Decisions describe, targeted at a new cloud-only `Emergency-Access` security group.

Register the first account's passkey in Authenticator, then remove its phone number method once a passkey sign-in works. Create the second account, cloud-only on `brindeck.onmicrosoft.com`, assign Global Administrator, and add it to `Emergency-Access`. Bootstrap it with a Temporary Access Pass if Step One showed one can be issued, otherwise through the Authenticator registration security defaults require. Register its passkey in the workstation's Windows Hello container, then remove any Authenticator method.

Cold sign-in with each account, signing out completely, using only its passkey, under security defaults. Record each account's methods by type. Store credentials offline. **Output:** two accounts, each signed in on its own device, or a stated limitation where that could not be achieved.

### Step Three: Review Global Administrator and the roles Step Eight depends on

As Cloud Administrator, assign Billing Administrator to Adam Ramzi, read the billing account roles, then remove his Global Administrator assignment. Remove testuser01's License Administrator assignment. Read every role assignment again, the billing account roles again, and the Answers backing group's owners.

Sign in as Adam Ramzi and open Billing > Your products and Billing accounts. **Output:** Global Administrator held by exactly three accounts, the signup account's billing access shown working, and testuser01 holding no directory role.

### Step Four: Hybrid join WIN11-CLIENT01 on Free

Create `OU=Hybrid Workstations` under `OU=Workstations` and move WIN11-CLIENT01 into it. Confirm with `gpresult /r` that its computer policies still apply. In the Entra Connect wizard, add the new OU to Domain and OU filtering, then run Configure device options, select Microsoft Entra hybrid join for Windows 10 or later, and write the service connection point for `corp.home.arpa`. Read the scheduler before and after.

Restart WIN11-CLIENT01 and let a delta cycle run. Read the computer object's `userCertificate` attribute, the Microsoft Entra device record through its Pending state to Microsoft Entra hybrid joined, and `dsregcmd /status` for `AzureAdJoined`, `DomainJoined`, `AzureAdPrt`, and the device ID, masked to eight characters. Read `dsregcmd /status` on `SYNC01`. **Output:** WIN11-CLIENT01 hybrid joined on Free, readable from the client, Active Directory, and the tenant, with `SYNC01` still absent from the tenant's device list.

### Step Five: Prepare writeback, the pilot groups, and enrollment

Grant `svc-entraconnect` Reset password, Change password, Write `lockoutTime`, and Write `pwdLastSet` on descendant user objects of `OU=User Accounts`, and read the ACL back. In the Entra Connect wizard, attempt to enable Password writeback under Optional features, and record whether it completes on Free.

Create the cloud-only `SSPR-Pilot` and `MDM-Pilot` groups, each holding testuser01. Build `Intune-MDM-Auto-Enrollment`, set to User Credential, and leave it unlinked. Record the definitions of CA01 through CA06 here, ready to create. **Output:** writeback permissions in place, the writeback switch's Free-tier behavior recorded, and an unlinked policy object.

### Step Six: Start the trials and confirm what they carry

Start the Intune Plan 1 trial as `admin@brindeck.com`. Read `Get-MgSubscribedSku` for the new SKU's service plans. If it carries no `AAD_PREMIUM`, assign it to `MDM-Pilot` while the tenant still reads Free, record whether group-based assignment is accepted, and read the group's `assignedLicenses` and testuser01's `licenseAssignmentStates` through Graph.

Start the P2 trial the same day. Confirm `AAD_PREMIUM` and `INTUNE_A` by service plan name. Turn off recurring billing on both trials and read each one's Expiration and Recurring billing dates. Assign both licenses to testuser01, Cloud Administrator, and Jane Doe. Read the Connect Health blade again and Conditional Access > Policies for Microsoft-managed policies. **Output:** the four dates, both service plans by name, and the group-based licensing result or the reason it could not be tested.

### Step Seven: Replace security defaults with conditional access

Create CA01 through CA05 in report-only mode, attempting this with security defaults still on. Generate sign-ins from WIN11-CLIENT01: Cloud Administrator to the Microsoft Entra admin center, Adam Ramzi to the Microsoft 365 admin center, Jane Doe to My Apps and the Azure portal, testuser01 with `Connect-MgGraph -UseDeviceCode`, and each emergency access account. Read each sign-in's Report-only tab.

Turn security defaults off, recording the time, and turn the five policies On. Repeat the same sign-ins and read the Conditional Access tab: multifactor prompts for CA01, CA02, and CA05, a block for CA04, and Not applied for both emergency access accounts. CA03 is validated only if a legacy client sign-in can be produced, since none of the licensed users has a mailbox now; otherwise it is recorded as configured and not exercised. **Output:** five policies On, each with a report-only result and an enforced result, and the length of any window with no enforcement.

### Step Eight: Self-service password reset with writeback

If Step Five could not enable writeback in Entra Connect, enable it now. In Password reset, set Selected to `SSPR-Pilot`, choose methods, and turn on Write back passwords to your on-premises directory. Register testuser01 for reset.

From WIN11-CLIENT01, reset testuser01's password through the reset portal. Read the result on DC01: `pwdLastSet`, `badPwdCount`, and a domain sign-in with the new password. Repeat inside the minimum password age and record whether DC01's policy refuses it. Reset Jane Doe's password from the Microsoft Entra admin center to exercise administrator reset with writeback, outside the pilot. Read the audit log's Self-service Password Management events. **Output:** a cloud-initiated reset landing on DC01, and what DC01's policy did to a second one.

### Step Nine: Enroll WIN11-CLIENT01 and require compliance

Set MDM user scope to Some, `MDM-Pilot`. Create the compliance policy and assign it to `MDM-Pilot`. Link `Intune-MDM-Auto-Enrollment` to `OU=Hybrid Workstations`, run `gpupdate /force`, and sign in as testuser01. If the enrollment task fails and the Microsoft Entra Operational log shows `AADSTS50076`, record the error, exclude the Microsoft Intune app from CA02, and retry. Read the EnterpriseMgmt scheduled task's last run result, Access work or school's MDM information, the Intune device record, and its compliance state.

Create CA06 in report-only mode. Sign in as testuser01 in Microsoft Edge on WIN11-CLIENT01 and from a browser on the physical workstation, then as Jane Doe from both. Turn CA06 On and repeat. Read device state on all four surfaces. **Output:** an enrolled, compliant device; a testuser01 sign-in allowed on it and blocked elsewhere; and Jane Doe unaffected.

### Step Ten: Exit, read the lapse, and record the finished state

**The exit,** no later than two days before the earliest of the four dates: set every policy Off, including Microsoft-managed ones, and record the security defaults panel's text. Enable security defaults, or export and delete the lab's policies if Off is not enough. Revoke sessions for the three licensed users. Unlink `Intune-MDM-Auto-Enrollment`. Confirm recurring billing is still off on both trials.

**The lapse,** after the later of the four dates: read both subscriptions and SKUs, attempt one policy edit, run `dsregcmd /status`, read the Entra and Intune device records, and try a testuser01 self-service reset and a Jane Doe administrator reset. Record each result against its prediction.

**Unchanged.** `Test-ComputerSecureChannel` and `gpresult` on WIN11-CLIENT01; `sssd` and a fresh `kinit` on Ubuntu Server; the Entra Connect version, source anchor, and scheduler on `SYNC01`. Run `Invoke-LabHealthReport.ps1`, then `Get-LabWazuhAgentStatus.ps1` with all four agents named, and `Invoke-Pester`, expected at 174 of 174.

**Finished state.** Live counts, role holders, both emergency access accounts' method types, `AZUREADSSOACC`'s age, and the pinned readings. **Output:** security defaults enabled before the lapse, each prediction confirmed or contradicted, and the state the track README records.

---

## Validation

Planned validation, to be replaced with observed results as the lab is implemented.

- **Emergency access.** Two cloud-only accounts, each proven by a cold passkey sign-in on its own device, with method types read from the tenant, and any shared-device limitation stated.
- **Global Administrator.** Role assignments read through Graph showing three holders, and the signup account opening billing pages as Billing Administrator.
- **Hybrid join.** `dsregcmd /status`, the computer object's `userCertificate`, and the Microsoft Entra device record agreeing on WIN11-CLIENT01, with `SYNC01` absent from the tenant.
- **Licensing.** Service plan names read off both SKUs, recurring billing off on both, and the four dates recorded.
- **Conditional access.** For each of CA01 through CA05, a report-only result and an enforced result in the sign-in logs from a WIN11-CLIENT01 sign-in, and Not applied for both emergency access accounts, or CA03 recorded as unexercised.
- **Writeback.** A reset from the portal reflected in DC01's `pwdLastSet`, a domain sign-in with the new password, and DC01's response to a second reset.
- **Enrollment and compliance.** The enrollment task result, including the error and the CA02 exclusion if the first attempt failed, the Intune record, a compliant state, and CA06's allow and block results against Jane Doe's.
- **Prediction.** Each row compared with what the tenant showed, neither adjusted to match the other.
- **Exit.** The time security defaults came back on, the portal text that allowed it, and every policy Off.
- **Unchanged.** Secure channel, Group Policy, `sssd`, `SYNC01`, four Wazuh agents, and 174 Pester tests.

---

## Troubleshooting and Adjustments

Recorded during implementation.

---

## Security Considerations

- **There may be a window with no multifactor enforcement.** If report-only policies cannot be created while security defaults are on, the time between turning security defaults off and turning CA01 through CA05 on has no enforcement at all. It is held to one sitting and timed. A second such window exists if the exit is late and P1 lapses with policies On, which the two-day margin exists to prevent.
- **The emergency access accounts are excluded from every policy.** That is the point of them, and it makes them the tenant's least constrained identities. Their passkeys and their offline storage are their only protection beyond mandatory multifactor authentication on the admin portals, and their user principal names stay redacted.
- **One phone may still hold too much.** The first emergency account's passkey shares a phone with Cloud Administrator's Authenticator. If the second account cannot be made independent of it, losing that phone removes the normal path and both emergency paths together.
- **`svc-entraconnect` can now reset passwords.** It already held replication rights; it now holds Reset password on every user in `OU=User Accounts`. A compromise of `SYNC01` therefore reaches account takeover on-premises as well as hash disclosure. The grant is scoped to one OU and omits Unexpire Password.
- **CA02 may carry one documented exclusion.** If Step Nine needs it, the Microsoft Intune app is excluded from the all-users multifactor policy, so CA02 no longer prompts for it. CA01 still requires multifactor authentication for administrators on all resources.
- **Billing Administrator is still privileged.** It controls purchases and subscriptions and is covered by CA01.
- **Microsoft-managed policies can switch themselves on.** They are enabled no sooner than thirty days after appearing. Each is read and given the emergency access exclusion as it appears.
- **The trial lapse removes protections that have to be put back deliberately.** Conditional access, compliance-based access, and self-service reset all lapse. Security defaults are the only protection that survives, which is why the exit restores them before the end date.

---

## Outcome

Recorded at completion.

---

## Lessons Learned

Recorded at completion.

---

## Sources

To be completed during implementation, with each link confirmed resolving at close. Research consulted for this plan:

**Security defaults and conditional access**

- [Security defaults in Microsoft Entra ID](https://learn.microsoft.com/entra/fundamentals/security-defaults) - the six protections and sixteen roles, the Directory Synchronization Accounts exclusion, session revocation, and the preview of individual protections
- [Set up multifactor authentication for Microsoft 365](https://learn.microsoft.com/microsoft-365/admin/security-and-compliance/set-up-multi-factor-authentication) - the portal text when policies exist, and creating but not enabling policies under security defaults
- [Step 3: Protect your Microsoft 365 user accounts](https://learn.microsoft.com/microsoft-365/enterprise/microsoft-365-secure-sign-in) - enabling security defaults once all policies are disabled
- [What is Conditional Access?](https://learn.microsoft.com/entra/identity/conditional-access/overview) - the P1 requirement, and policies kept but not updatable after licenses expire
- [Microsoft-managed Conditional Access policies](https://learn.microsoft.com/entra/identity/conditional-access/managed-policies) - creation, automatic enabling, and no deletion
- [Plan a Conditional Access deployment](https://learn.microsoft.com/entra/identity/conditional-access/plan-conditional-access) - exclusions, and service principals outside user-scoped policies
- [Require MFA for administrators](https://learn.microsoft.com/entra/identity/conditional-access/policy-old-require-mfa-admin) - CA01
- [Require multifactor authentication for all users](https://learn.microsoft.com/entra/identity/conditional-access/policy-all-users-mfa-strength) - CA02 and the Directory Synchronization Accounts exclusion
- [Block legacy authentication with Conditional Access](https://learn.microsoft.com/entra/identity/conditional-access/policy-block-legacy-authentication) - CA03
- [Block authentication flows with Conditional Access policy](https://learn.microsoft.com/entra/identity/conditional-access/policy-block-authentication-flows) - CA04
- [Require MFA for Azure management](https://learn.microsoft.com/entra/identity/conditional-access/policy-old-require-mfa-azure-mgmt) - CA05
- [Require device compliance with Conditional Access](https://learn.microsoft.com/entra/identity/conditional-access/policy-all-users-device-compliance) - CA06, which does not block enrollment
- [Analyze Conditional Access policy impact](https://learn.microsoft.com/entra/identity/conditional-access/concept-conditional-access-report-only) - report-only results
- [Mandatory multifactor authentication for Azure and admin portals](https://learn.microsoft.com/entra/identity/authentication/concept-mandatory-multifactor-authentication) - enforcement independent of policy, including emergency access accounts

**Emergency access and authentication methods**

- [Manage emergency access accounts in Microsoft Entra ID](https://learn.microsoft.com/entra/identity/role-based-access-control/security-emergency-access) - two accounts, passkeys, separate devices and methods, group exclusion
- [How to enable passkeys (FIDO2) in Microsoft Entra ID](https://learn.microsoft.com/entra/identity/authentication/how-to-authentication-passkeys-fido2) - availability on Free, profiles, and the user principal name change issue
- [Enable passkeys in Authenticator](https://learn.microsoft.com/entra/identity/authentication/how-to-enable-authenticator-passkey) - the Authenticator profile and device requirements
- [Enable Microsoft Entra passkey on Windows](https://learn.microsoft.com/entra/identity/authentication/how-to-authentication-entra-passkeys-on-windows) - Windows Hello passkeys without device join
- [Passwordless authentication with Microsoft Intune](https://learn.microsoft.com/intune/solutions/passwordless) - passkeys and Temporary Access Pass listed under P1
- [Features and licenses for Microsoft Entra multifactor authentication](https://learn.microsoft.com/entra/identity/authentication/concept-mfa-licensing) - the security defaults method table
- [Configure Temporary Access Pass](https://learn.microsoft.com/entra/identity/authentication/howto-authentication-temporary-access-pass) - bootstrapping the second account

**Roles and billing**

- [Microsoft Entra built-in roles: Billing Administrator](https://learn.microsoft.com/entra/identity/role-based-access-control/permissions-reference#billing-administrator) - what the role permits
- [Understand your Microsoft business billing account](https://learn.microsoft.com/microsoft-365/commerce/manage-billing-accounts) - billing account roles and types
- [Manage billing notifications](https://learn.microsoft.com/microsoft-365/commerce/billing-and-payments/manage-billing-notifications) - the signup person as billing account owner

**Hybrid join and Intune**

- [Configure Microsoft Entra hybrid join](https://learn.microsoft.com/entra/identity/devices/how-to-hybrid-join) - prerequisites and the Entra Connect procedure
- [Plan your Microsoft Entra hybrid join implementation](https://learn.microsoft.com/entra/identity/devices/hybrid-join-plan) - Windows Server 2022 support
- [Microsoft Entra hybrid join targeted deployment](https://learn.microsoft.com/entra/identity/devices/hybrid-join-control) - the alternative not taken, and the Pending state
- [Authenticate to Microsoft Entra ID by using application identity](https://learn.microsoft.com/entra/identity/hybrid/connect/authenticate-application-id) - application-based authentication from 2.5.76.0
- [Enroll a Windows device automatically using Group Policy](https://learn.microsoft.com/windows/client-management/enroll-a-windows-10-device-automatically-using-group-policy) - the policy setting and enrollment task
- [Set up automatic enrollment for Windows devices](https://learn.microsoft.com/intune/device-enrollment/windows/enable-automatic-mdm) - the P1 requirement and MDM user scope
- [Troubleshooting Windows Group Policy-based auto-enrollment](https://learn.microsoft.com/troubleshoot/mem/intune/device-enrollment/troubleshoot-windows-auto-enrollment) - the user license and `dsregcmd` values enrollment needs
- [Microsoft Intune licensing](https://learn.microsoft.com/intune/fundamentals/licensing) - per-user licensing and the trial described as EMS
- [Sign up for a Microsoft Intune free trial](https://learn.microsoft.com/intune/fundamentals/free-trial-sign-up) - thirty days, on the new-tenant path
- [Troubleshoot co-management: Auto-enroll existing Configuration Manager-managed devices into Intune](https://learn.microsoft.com/troubleshoot/mem/intune/comanage-configmgr/troubleshoot-co-management-auto-enrolling) - `AADSTS50076` under a policy requiring multifactor authentication for all cloud apps, and the Microsoft Intune app exclusion
- [Use compliance policies with Intune](https://learn.microsoft.com/intune/device-security/compliance/overview) - the no-policy default and validity period
- [Device compliance settings for Windows](https://learn.microsoft.com/intune/device-security/compliance/ref-windows-settings) - TPM-dependent settings

**Self-service password reset**

- [Licensing requirements for self-service password reset](https://learn.microsoft.com/entra/identity/authentication/concept-sspr-licensing) - Free versus P1, and licensing users who benefit
- [How does self-service password reset writeback work?](https://learn.microsoft.com/entra/identity/authentication/concept-sspr-writeback) - policy enforcement, protected groups, consoles
- [Tutorial: Enable self-service password reset writeback](https://learn.microsoft.com/entra/identity/authentication/tutorial-enable-sspr-writeback) - permissions, Unexpire Password, minimum password age
- [Password policies and account restrictions](https://learn.microsoft.com/entra/identity/authentication/concept-sspr-policy) - the administrator two-gate policy

**Licensing and lifecycle**

- [Microsoft Entra licensing](https://learn.microsoft.com/entra/fundamentals/licensing) - Connect Health requiring P1
- [Sign up for Microsoft Entra ID P1 or P2 editions](https://learn.microsoft.com/entra/fundamentals/get-started-premium) - the P2 trial
- [What happens when my Microsoft 365 for business subscription ends?](https://learn.microsoft.com/microsoft-365/commerce/subscriptions/what-if-my-subscription-expires) - lifecycle statuses and the Expired status change
- [Overview of licensing and activation in Microsoft 365 Apps](https://learn.microsoft.com/microsoft-365-apps/licensing-activation/overview-licensing-activation-microsoft-365-apps) - group-based licensing tied to P1
- [Set up Answers in Viva](https://learn.microsoft.com/viva/engage/eac-answers-overview-set-up) - the Answers backing group and its owners

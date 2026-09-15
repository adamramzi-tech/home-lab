# 04 - Microsoft 365 Administration Workflows

## Status

Planning and research. Not started.

This lab runs against two clocks that were established by Lab 03 and cannot be moved. The Microsoft 365 Business Basic (no Teams) trial lapses on 2026-09-22, and `Finance` still carries a group-level Business Basic assignment, so the lapse falls inside this lab's window whether or not the lab plans for it. The Microsoft 365 Business Premium trial expires on 2026-10-05, and it is what carries Exchange Online Plan 1. Every mailbox this lab provisions depends on an entitlement that ends on that date. The lab is sized and sequenced accordingly.

---

## Overview

Labs 01 and 02 built the environment. Lab 03 operated the directory that resulted, establishing what can be edited on a synchronized object, how groups differ by type and source of authority, and how licenses reach users under two assignment models. What none of them touched is the service layer that licensing actually buys.

This lab administers Exchange Online against the hybrid population Lab 03 licensed. It provisions mailboxes, builds the mail-enabled group types Lab 03 deliberately handed forward, delegates a shared mailbox, establishes what this subscription actually entitles a mailbox to for archiving and hold, converts a departing user's mailbox and reclaims the license, and follows real messages through the service, including one it deliberately stops, to establish where they went and why.

The distinction this lab is built on is the same one Lab 03 arrived at: configuring a thing and operating it are different, and only the second produces evidence about how it behaves. A lab that creates a distribution list and never sends mail through it has documented a configuration. A lab that sends a message to that list and reads the trace showing it expanded into its members has documented what the object does.

---

## Objectives

The primary goals of this lab are to:

- establish which accounts in the hybrid population received Exchange Online mailboxes and which did not, and record what an unlicensed account has in place of one
- create and catalogue the three mail-enabled group types the Entra admin center cannot manage, distribution lists, mail-enabled security groups, and Microsoft 365 groups, recording which console owns each and how they differ in what they accept as members
- build a shared mailbox, establish the sign-in state of its associated user account against the tenant rather than against documentation, and demonstrate all three delegation models against it, Full Access, Send As, and Send on Behalf, including what each one produces on a received message and what the wrong one looks like from the recipient's side
- convert a departing user's mailbox to a shared mailbox and reclaim the license, in the documented order, recording the constraint that makes the order matter
- follow real messages through the service with message trace, establishing delivery status for a message sent to an individual, to a distribution list, and to a recipient a deliberately built mail flow rule stops
- record a prediction about what the Business Basic lapse on 2026-09-22 will do to `Finance`'s group-level assignment, before the date, and then record what it actually did
- establish what this tenant is actually entitled to for mailbox archiving and hold by enumerating the subscription's service plans rather than by citation, settle against the tenant a contradiction between two Microsoft documents about whether those capabilities require Exchange Online Plan 2, and build or bound the work on the result
- confirm that the hybrid environment, the synchronization engine, and the automation library are unchanged by a lab conducted almost entirely in two web consoles and one PowerShell module
- record the finished mail state and the licensing state Lab 05 inherits, against an entitlement with a known expiry

---

## Project Context

[ADR-019](../architecture/decisions/019-establish-cloud-and-hybrid-identity-track.md) established this track and settled its architecture. Nothing in this lab reopens any of it. The synchronization engine, its scope, its authentication method, and the tenant's administrative model are all as Lab 02 left them and as Lab 03 confirmed them.

Lab 03 handed this lab two things explicitly. The first is a scope boundary: its Design Decisions named mail-enabled security groups and distribution lists as group types it would not create, on the grounds that their administration lives in a console it never opened, and handed them here. The second is an entitlement. The Business Premium trial Lab 03 started carries `EXCHANGE_S_STANDARD`, Exchange Online Plan 1, and Lab 03 confirmed it present by service plan name rather than inferring it from the tier. That service plan exists in this tenant for this lab.

It also handed forward ten open items to the track README, and this plan is explicit about which of them Lab 04 owns rather than addressing several of them incidentally and leaving the rest ambiguous. Three carry dates that fall inside this lab's window, which is the reason the table is here rather than in a close-out note.

| Item | Disposition | Why |
|---|---|---|
| The Microsoft Graph group-to-license gap | Owned by Lab 04 | Step Eight reconciles the same assignment-target and consumed-seat figures on a license reclamation, and Step Six reads `Finance`'s group-level assignment across a subscription lapse. Both are fresh evidence about a relationship the directory surfaces deny |
| The product page's six-versus-seven movement | Owned by Lab 04 | Step One and Step Six both read the Business Premium and Business Basic product pages, so the unexplained movement gets two more dated readings whether or not it is chased |
| Three unreconciled service counts on one SKU | Owned by Lab 04 | Step One enumerates the Business Premium SKU's service plans in full for the entitlement question, which is the same read that produced one of the three figures |
| **The 2026-09-30 seamless single sign-on interval** | Owned by Lab 04, automation passes to Lab 06 | Lab 03 deliberately left `AZUREADSSOACC`'s key unrolled at eleven days so a later lab could watch a full thirty-day interval elapse against a recommendation now established as hygiene rather than a deadline. Lab 04 is the lab running on 2026-09-30. The interval is consumed unobserved unless a step reads it, so Step One records the key's current age and Step Nine reads it again after the date. Whether the roll should be automated remains Lab 06's |
| **`Testgroup` and `nolocation-demo01` permanent deletion, 2026-10-06 and 2026-10-07** | Owned by Lab 04 | Both were retained for Labs 04 and 05, and both dates fall after this lab's own 2026-10-05 deadline. Lab 04 is therefore the last lab that can decide anything about either, which makes this a decision with a date rather than an inventory line. Step Nine takes it |
| **The 2026-10-05 versus 2026-10-06 expiry discrepancy** | Owned by Lab 04 | Lab 03 recorded the portal's own Recurring billing field reading a day later than the stated expiry and left it unresolved. This plan uses 2026-10-05 throughout as the conservative figure and says so rather than asserting it. Step Six and Step Nine both read the subscription pages and can settle it |
| `New-LabUser.ps1` sets no organizational attributes | Passes to Lab 06 | A script change under the ADR-017 analysis and testing standard, which a portal lab should not reopen |
| The emergency access account's user principal name rename | Passes to Lab 05 | It should be renamed before Lab 05 makes that account the one identity conditional access deliberately does not constrain |
| Three Global Administrators pending privileged role review | Passes to Lab 05 | Opened by Lab 01 and scheduled there |
| Whether Microsoft Entra ID Free permits group-based licensing | Passes to Lab 05 | The event that settles it is the Business Premium lapse on 2026-10-05, which falls after this lab closes |
| Whether the mail attribute set is cloud-editable on a synchronized object | Passes to Lab 06 | See below |
| `Get-LabWazuhAgentStatus.ps1`'s default agent list, and `Get-LabDockerServiceStatus.ps1`'s Portainer account | Held against the automation track | Neither belongs to this track. Step Nine works around the first rather than fixing it, as Lab 03 did |
| `SYNC01`'s scheduler does not survive a VM suspend | Held in the track README | Applied by this lab rather than owned by it. Step Nine reads `Get-ADSyncScheduler` before anything that could force a cycle |
| The Active Directory Recycle Bin recommendation | Held against the enterprise infrastructure track | Forest-wide and irreversible, so not a mid-lab action |

One question is handed on rather than answered. Whether the mail attribute set draws the cloud-editability line in the same place Lab 03 found for user objects, where user principal name and account enabled state were writable on a synchronized object and everything else was locked, is unanswered and stays unanswered here. Lab 03's Step Eleven already established the per-field finding on user objects across 175 lines, the mail-attribute version is an increment on a settled finding rather than a new one, and ADR-019 gives the identity boundary to Lab 06. It belongs there, alongside the rest of that boundary, and this lab does not build it.

It also handed forward a live question. Lab 03's Part C established that the Microsoft 365 admin center counts assignment targets while `Get-MgSubscribedSku` counts consumed seats, and that `Finance`, licensed and empty, contributes a target and no seat. `Finance` carries a Business Basic assignment that Lab 03 made in its Step Eight-E, and the Business Basic trial lapses on 2026-09-22. Lab 03 recorded what a group-level assignment does when the subscription behind it goes away as an open question and noted that the lapse would make it observable. This lab is the one that gets to observe it.

The operating premise carries forward too. Lab 03's Lessons Learned closed on a pattern this repository has now recorded four times in three technologies: a status that reports configuration rather than work will report success while nothing is happening. Exchange Online is a rich source of the same shape. A distribution list with members configured correctly and a transport rule silently dropping mail to it looks identical, from the object's own properties, to one that works. The only thing that distinguishes them is following a message through and reading what happened to it, which is why message trace is in this lab's objectives rather than left as a tool a later lab might use.

---

## Design Decisions

### The lab sends real mail and traces it, rather than confirming configuration and stopping

**Decision:** Every mail-enabled object this lab builds has at least one real message sent through it, and the result is read from message trace rather than from the object's own properties.

This is the decision the rest of the lab is shaped around, and it is an architectural position rather than a preference. Lab 03 established, four separate times, that a component reporting its own configuration is not evidence that the component is doing anything. A mailbox that exists, a distribution list with the right members, and a shared mailbox with the right delegation are all configuration states. None of them establish that mail reaches the intended recipient, which is the only property any of those objects exists to provide.

Message trace is the instrument that closes that gap, and Microsoft documents it as the tool for exactly this: determining whether a message was received, rejected, deferred, or delivered, and what happened to it before reaching that status. It has a property that makes it particularly well suited to this lab. A message sent to a distribution list appears in the trace with a delivery status of `Expanded`, showing the group being resolved into its individual members. That single result demonstrates what a distribution list is in a way that reading its membership page cannot, and it means the distribution list work and the message trace work are one step rather than two.

Because every result in this lab is read from the instrument, the instrument is established before the first message is sent rather than introduced partway through. Step One connects the module and runs one throwaway trace against a message nothing depends on, which confirms the tool works, confirms the administrative path chosen in the same step actually authorizes it, and produces this tenant's own observed latency figure before any step is waiting on one.

Its constraints are worth recording in the lab rather than discovering mid-step. Message trace data is retained for 90 days and the retention period is not configurable. Results are returned immediately for searches spanning 10 days or less; anything longer is delivered as a downloadable report prepared from archived data, which can take hours.

How long a sent message takes to appear in trace data at all is recorded as a range to observe rather than a figure to assert, because Microsoft's own sources do not agree on it. The Message Trace FAQ says five to ten minutes. The Exchange Online monitoring reference says messages less than seven days old should appear within five to thirty minutes. The mail delivery troubleshooting article says data can appear as soon as ten minutes or take up to an hour. All three are first-party. The lab plans for the widest of the three, records what this tenant actually did, and treats a message that has not appeared yet as unresolved rather than as a failure.

### The Business Basic lapse is observed, and the prediction is recorded before the date

**Decision:** The lab records what it expects the 2026-09-22 lapse to do before 2026-09-22, in the document, and commits the document before that date. It then records what actually happened. The prediction is not adjusted afterward.

Committing before the date is part of the decision rather than a process detail. A prediction sitting in an uncommitted working file is indistinguishable, read later, from one written after the outcome was known, and an unfalsifiable prediction is worth less than no prediction at all. Step One therefore closes on committing this document with the prediction in it, and that commit is a condition of the step rather than housekeeping after it.

Lab 03 recorded, twice, that a figure written down before its basis was understood becomes something the document asserts and later steps build on. The corrective habit it arrived at was to interrogate a reading before treating it as a finding. This decision applies that habit in the only direction that actually tests it, which is forward.

Research for this plan already suggests the obvious prediction is wrong, and that is precisely why it is worth writing down. Microsoft documents the subscription lifecycle as Active, then Expired, then Disabled, then Deleted. The Expired stage begins immediately at the subscription end date and lasts approximately 30 days for most subscriptions in most regions, and during it users retain normal access to the service. If that behavior holds here, 2026-09-22 will produce a status change rather than a service interruption, and `Finance`'s group-level assignment may survive the date entirely.

Two things about that remain genuinely unknown and are not to be asserted from the documentation. Whether a trial follows the same lifecycle as a paid subscription is not clearly stated for this case; one Microsoft source describes free trials moving into a grace status for 30 days, which may or may not be the same mechanism under a different name. And whether the tenant's group-based licensing machinery treats an Expired subscription as still assignable is a separate question from whether users can still sign in. The lab observes both rather than reasoning from either.

The same uncertainty reaches the track's own record. The track README currently states that when the Business Premium trial lapses on 2026-10-05, Microsoft Entra ID P1 lapses with it. If the Expired stage applies, that statement is premature by up to 30 days. This lab does not correct the README on the strength of documentation alone; it records the discrepancy, and whichever lab is running when 2026-10-05 passes gets to settle it.

**Step Six's result feeds back into this lab's own schedule, and the lab says in advance what it does with each outcome.** This decision argues the Expired stage may extend a lapsed subscription's usable life by roughly 30 days. The sizing decision below treats 2026-10-05 as a hard cliff. Both cannot be load-bearing, and Step Six settles which one is, on 2026-09-22, thirteen days before the deadline, against the same tenant and the same commerce machinery that will handle the Business Premium expiry. So:

- If the Business Basic lapse produces an Expired subscription whose entitlements remain usable, the lab records that the 2026-10-05 cliff is probably a status change rather than a service interruption, and treats the remaining schedule as having roughly 30 days of unplanned slack behind it. It does not spend that slack. It records it, finishes on the original schedule, and hands Lab 05 a materially better-informed licensing decision than a bare expiry date.
- If the lapse removes access at the date, the hard cliff is confirmed, the sizing below is correct, and anything not yet complete that needs a mailbox is triaged against 2026-10-05 immediately rather than at the deadline.
- If the outcome is neither cleanly, which is the likeliest result given that a trial's lifecycle is not clearly documented as identical to a paid subscription's, the lab records what it saw and keeps the conservative assumption. Planning against the earlier date costs nothing if the later one turns out to apply.

Treating the observation as purely retrospective would waste the only advance warning this lab gets about its own deadline.

### Delegation is demonstrated in all three forms, because the difference is only visible from the recipient's side

**Decision:** Full Access, Send As, and Send on Behalf are each configured and each exercised with a real message, and what the recipient sees is captured for all three.

These three are the most commonly confused permissions in Exchange administration, and the reason is structural: from the administrator's side they are three checkboxes on the same page, and from the mailbox owner's side they produce nearly identical access. The difference appears only on a message that has been sent, in the `From` header the recipient receives. Send As produces a message that appears to come from the shared mailbox with no indication a person sent it. Send on Behalf produces one that names both. Full Access grants neither by itself.

Configuring all three and describing the distinction would be a documentation exercise. Sending three messages and capturing what arrives is the version that establishes it, and it costs one additional step at most.

### The shared mailbox account's sign-in state is checked, because Microsoft's documentation disagrees with itself about it

**Decision:** Whether the user account behind a shared mailbox is sign-in blocked at creation is established against this tenant and recorded as observed, not cited.

Every shared mailbox has a corresponding user account with a system-generated password, and whether that account can sign in is a security property rather than a detail. Microsoft's own documentation gives three incompatible answers. The shared mailbox creation article states that by default every new shared mailbox has sign-in blocked. The Exchange Online limits reference describes the associated account as active and explains how to block it. And Microsoft 365 Lighthouse ships a feature whose purpose is finding shared mailboxes that are enabled for direct sign-in across managed tenants, which would have nothing to find if the first statement held universally.

This is the third time in this track that Microsoft's documentation has contradicted itself on a checkable point, after Lab 02 found `Get-EntraDirSyncFeature`'s accepted feature name did not match its own reference and Lab 03 found the Entra PowerShell reference and the recoverability architecture guidance disagreeing about whether a security group can be restored. Both were settled the same way, by running it against the tenant, and Lab 03's Lessons Learned records that a documentation conflict is a cue to test rather than a cue to read more carefully. This lab applies that as a method rather than rediscovering it.

### The leaver conversion is included, because it is where licensing, mailbox, and identity meet

**Decision:** One licensed user's mailbox is converted to a shared mailbox and the license is reclaimed, using a purpose-built account rather than any fixture a later lab depends on.

This is the only workflow in the lab that touches all three layers the track has built. It is also the one with a real ordering constraint that the documentation states and that is easy to get backward: the mailbox must still have its license assigned at the moment of conversion, or the conversion option does not appear at all. Remove the license first, which is the intuitive order if the goal is to reclaim a seat, and the work has to be undone before it can be done.

The conversion has a second property worth recording. A shared mailbox holds up to 50 GB without a license of its own, but a user who accesses it still needs an Exchange Online license, so the seat is reclaimed from the departed account and not from the people who inherit the mailbox. That is a licensing consequence an administrator plans capacity against, and it is the kind of thing the Microsoft 365 admin center's seat count will not explain on its own, exactly as Lab 03's Part C found for group assignments.

The subject account is created for this purpose and removed by the lab. `cloudonly-demo01` is explicitly not used: Lab 03 restored it to a license-only state with no groups and no roles because Labs 04 and 05 both inherit it, and converting its mailbox would destroy that.

### Mailbox compliance is settled against the tenant, because two Microsoft documents contradict each other about what this subscription includes

**Decision:** What this tenant is entitled to for mailbox archiving and hold is enumerated off the subscription's own service plans in Step One and settled against the tenant, not taken from a citation. Step Seven then builds what the enumeration supports, or records a boundary on the evidence if it supports nothing.

An earlier draft of this plan asserted that litigation hold, in-place archiving, and retention all require Exchange Online Plan 2 or a Plan 1 with an Exchange Online Archiving add-on, and that this tenant holds Plan 1 through Business Premium and neither add-on. That came from Microsoft's litigation hold article, which states the Plan 2 requirement plainly and adds that a Plan 1 mailbox needs a separate Exchange Online Archiving license to be placed on hold.

It is contradicted by Microsoft's Exchange Online Archiving service description, which lists the plans that require the add-on and then names, separately and explicitly, the plans that "already include archiving and don't require Exchange Online Archiving as an add-on." Microsoft 365 Business Premium is on the second list, alongside Exchange Online Plan 2 and the E-series. The same service description's feature table gives Exchange Online Archiving for Exchange Online both Litigation Hold and manual retention policies. Both documents are first-party and current, and they cannot both be right about this subscription.

This is the fourth time in this track that Microsoft's documentation has contradicted itself on a checkable point, and the first three were all settled the same way. Lab 02 found `Get-EntraDirSyncFeature`'s accepted feature name did not match its own reference. Lab 03 found the Entra PowerShell reference and the recoverability architecture guidance disagreeing about whether a security group can be restored, and the tenant settled it in four minutes at the cost of one disposable group. This lab already has a third in flight, in the shared mailbox sign-in state above, where three Microsoft sources give three answers. Lab 03's Lessons Learned states the method outright: a documentation conflict is a cue to test rather than a cue to read more carefully. Applying it here rather than picking the more authoritative-looking citation is the whole of this decision.

The consequence is a branch rather than a boundary, and the branch is decided by evidence Step One produces. Lab 03's Step Four already read 62 service plans off this SKU through Microsoft Graph and named only three of them, so the answer is sitting in a query this track has run once and never enumerated. Step One enumerates it in full.

If archiving and hold are present on the SKU, they are content this lab builds rather than a boundary it declines. The window remaining before 2026-10-05 is enough for one step, an archive mailbox and a litigation hold are exactly the kind of mailbox property an administrator meets in a real leaver workflow, and declining to build a capability the tenant holds because a single citation said it could not would be the error this track keeps catching in other people's documentation. If the enumeration shows otherwise, the boundary is restated on what the SKU actually carries rather than on a citation that turned out to be contradicted, which is a stronger statement than the one this decision replaces.

Two things stay out either way, on scope rather than on licensing. eDiscovery Premium is a substantial topic with its own case-management surface, and a shallow pass at it would be worse than an honest omission. Public folders are a legacy collaboration surface this environment has no use for, and building one to document it would be inventing a requirement.

### The lab is sized against the shorter of two clocks, and the step count is the real one

**Decision:** Nine steps, sequenced so the Exchange-dependent work completes before 2026-10-05, with the 2026-09-22 observation entering as a date-pinned interrupt rather than as a gate the later steps queue behind.

Lab 03 ran to twelve steps across roughly ten days of sittings plus several review cycles, and those review cycles consistently found real defects. Sizing this lab to the same depth would put its close-out against the entitlement deadline with no slack, and a lab whose licensed features expire mid-write is a document that cannot finish what it started.

The number stated here is the number of steps the lab has, and it is stated that way because an earlier draft did the opposite. That draft claimed eight to ten steps, listed nine, and asked each of them for materially more than one step's work: a first step that was four separable pieces, a delegation step that was two, a conversion step that was one and a half, and a hybrid-boundary step of the same shape as Lab 03's Step Eleven, which ran 175 lines on its own. A smaller label on the same work is not a smaller lab, and the deadline does not read labels.

So the work came out rather than the count coming down. The hybrid boundary on mail objects is cut and handed to Lab 06 for the reasons Project Context records, which is the single largest reduction available and removes the step this lab was least placed to do well. The compliance step the decision above restores is smaller than the step it replaced. Against that, the arithmetic is stated plainly rather than assumed, and it applies to one step rather than to five. Step One alone is bounded by 2026-09-22, because it takes the pre-lapse reading and commits the prediction. Every other step is bounded only by 2026-10-05, because Step Six enters as an interrupt rather than as a gate and nothing queues behind it. Reading the shorter deadline onto Steps Two through Five would manufacture pressure the schedule does not actually carry, on a lab whose method is not rushing readings.

The sequencing has two constraints beyond that. Everything requiring a mailbox must run before 2026-10-05, because Exchange Online Plan 1 is carried by the Business Premium trial and nothing in this tenant replaces it. And Step Six is pinned to a date rather than to a position: it is read when 2026-09-22 arrives, from whatever step the lab is standing in, and Steps Seven through Nine are not blocked behind it. Numbering it in sequence is a convenience for reading the document, not a statement about order of execution.

---

## Technologies Used

- Microsoft Exchange Online, Plan 1, provided by the Microsoft 365 Business Premium trial started in Lab 03
- Exchange admin center, at `admin.exchange.microsoft.com`, including Recipients, Mail flow rules, and Message trace
- Outlook on the web, as the mail client every message in this lab is sent from and read in, since the delegation finding in Step Four is a property of what a recipient sees rather than of what the directory holds
- Microsoft 365 admin center, for shared mailbox creation, license assignment, and subscription state
- Exchange Online PowerShell, the `ExchangeOnlineManagement` module, from WIN11-CLIENT01 per ADR-016
- Microsoft Graph PowerShell SDK, for the licensing and directory reads this lab shares with Lab 03
- Microsoft Entra ID, Premium P1, for the group objects the mail work is built on
- Microsoft Entra Connect Sync on `SYNC01`, unchanged, as the source of the synchronized population

---

## Architecture or Topology

This lab changes nothing structural. No host is built, no service is deployed, no trust or synchronization boundary moves. The environment at the end of this lab is the environment Lab 02 built and Lab 03 administered.

What changes is the object population inside the tenant, and it changes in one direction: mail-enabled objects appear where none existed. The tenant currently holds nine groups, none of which are mail-enabled in the Exchange sense except `All Company` and `Company Announcements`, which are Microsoft 365 groups and therefore carry addresses by construction. `All Company`'s is `allcompany@brindeck.onmicrosoft.com`, on the initial domain rather than the routable one, which Step One checks against what the other mail objects turn out to carry.

Whether the tenant holds any distribution lists, mail-enabled security groups, or shared mailboxes is nonetheless re-established rather than inherited, and the reason is management rather than visibility. The Entra admin center does list distribution lists and mail-enabled security groups; what it cannot do is manage them, which is the constraint Lab 03 actually recorded when it named those two types as a boundary and handed them here. A shared mailbox would likewise have appeared in Lab 03's Step One user count as an ordinary user object. So Lab 03's catalogue is probably complete. Step One re-reads the inventory from the console that owns these objects anyway, because a lab that creates mail-enabled objects should open with a baseline drawn from the surface those objects live on, which is the correction Lab 03's own Lessons Learned arrived at after its baseline missed three objects sitting in containers it never opened.

The hybrid boundary is not where this lab looks. The four groups synchronized from `OU=Groups` are mastered on-premises and read-only in the cloud, which Lab 03 established at the object level across 175 lines. Whether that constraint behaves the same way for mail properties is a real question and an open one, and Project Context records why it goes to Lab 06 with the rest of the identity boundary rather than being answered here.

---

## Prerequisites

| Requirement | Source | State |
|---|---|---|
| A tenant with a verified routable domain | Lab 01 | Met. `brindeck.com`, verified 2026-08-23 |
| Directory synchronization operating on a schedule | Lab 02 | Met. Entra Connect Sync 2.6.84.0 on `SYNC01`, `ms-DS-ConsistencyGuid` source anchor, half-hourly Delta cycle, confirmed running at Lab 03's close after a VM restart |
| A licensed population with mailboxes available | Lab 03 | Met, and perishable. Exchange Online Plan 1 is carried by the Business Premium trial expiring 2026-10-05 |
| Exchange Online Plan 1 present by service plan name | Lab 03 | Met. `EXCHANGE_S_STANDARD` confirmed off the SKU with `Get-MgSubscribedSku` rather than inferred from the tier |
| An administrative account able to run message trace | Lab 01, Lab 03 | To confirm. Message trace requires Exchange Administrator or Organization Management membership. The tenant's Global Administrator qualifies, but Lab 03 established that role-scoped administration is the correct pattern, so whether an Exchange Administrator assignment should be made for this lab is a Step One decision |
| `cloudonly-demo01` in a license-only state | Lab 03 | Met and must be preserved. No groups, no directory roles, one license. Lab 05 inherits it in the same state |
| The `ExchangeOnlineManagement` PowerShell module | This lab | Not met. Installed in Step One from WIN11-CLIENT01 per ADR-016, which ADR-019's Primary Tooling already names alongside the Microsoft Graph PowerShell SDK |
| Mail-flow DNS for `brindeck.com` | Lab 01 | To confirm, and the only prerequisite here that could stop a step on the day. Lab 01 verified the domain with a single TXT record, `MS=ms19821357`, published in Cloudflare and added through the Entra admin center's Domain names blade. That blade establishes ownership and nothing else. The Microsoft 365 domain setup that publishes the MX, SPF, and Autodiscover records was never run, and no lab in this track has published an MX record for `brindeck.com`. Step One establishes the actual state |

Two entitlement dates constrain everything below. Business Basic (no Teams) lapses 2026-09-22. Business Premium expires 2026-10-05, on the conservative reading of a one-day discrepancy Lab 03 recorded and left open, and takes Exchange Online Plan 1 and Microsoft Entra ID P1 with it unless the subscription lifecycle's Expired stage applies, which Step Six tests.

**What the mail-flow DNS row gates, stated before the lab runs rather than discovered when a message does not arrive.** `brindeck.com` carries the Primary checkmark in the tenant, so the mailboxes Lab 03's licensing provisioned most likely hold `@brindeck.com` primary SMTP addresses. Internal tenant-to-tenant mail is routed inside the service and never consults public DNS, so Steps Two, Three, and Four are unaffected either way: mailbox provisioning, the group-type catalogue, and all three delegation models can be demonstrated entirely between mailboxes in this tenant. What depends on the records existing is narrower and specific. Any message to or from a recipient outside the tenant needs MX for inbound and a correct SPF record for outbound to survive the receiving side's checks. The external-sender premise in Security Considerations below, which is about a distribution list being addressable from outside the organization, cannot be tested at all without inbound mail flow.

Step One settles it and the lab takes one of two paths in the document rather than improvising. If the records are absent, either the lab publishes them in Cloudflare as a documented step, which is legitimate content in its own right and closes a gap Lab 01 left, or it confines its mail flow work to internal recipients and says so explicitly in Step Five, scoping the deliberate failure case to a mechanism that does not need external mail. The mail flow rule Step Five builds works internally, so the failure case survives either path. What the lab does not do is write steps that assume external delivery and find out at the trace.

---

## Implementation

Nine steps. Every step except Step Six requires Exchange Online and must therefore complete before 2026-10-05, when Exchange Online Plan 1 ends with the Business Premium trial. That is Steps One through Five and Steps Seven through Nine: Step Two reads mailboxes, Step Three creates mail-enabled groups, Step Four creates and delegates a shared mailbox, Step Five traces mail through both, Step Seven works on mailbox compliance, Step Eight converts a mailbox, and Step Nine reconciles the mail state. Step Six is the only step in the lab that needs no mailbox, and it is the one pinned to a date.

Two steps are fixed by dates outside the lab rather than by their position in it, and they are fixed in opposite directions.

Step One is the urgent one and the easier to miss. It takes the before half of Step Six's observation, so it has to run before 2026-09-22 or the comparison has nothing to compare against and the observation is lost for good. It also closes on committing this document, prediction included, before that date. Step One is the only step in this lab that cannot be caught up later.

Step Six is pinned rather than sequenced. It is read when 2026-09-22 arrives, from whatever step the lab happens to be standing in, and Steps Seven through Nine are not blocked behind it. Its position in the numbering is a reading convenience. Its result also feeds back into this lab's own schedule, on the terms Design Decisions set out above.

### Step One: Record the pre-lab mail baseline and establish the administrative path

Read the tenant's mail state before touching anything, on the discipline Lab 03's Step Ten established after finding the live tenant had drifted from what the document claimed. Record which of the ten users hold mailboxes and which do not, what recipient types exist, and what the Exchange admin center's Recipients view shows against the Entra admin center's user list.

Install `ExchangeOnlineManagement` on WIN11-CLIENT01 and connect, per ADR-016 and per ADR-019's Primary Tooling, which already names Exchange Online PowerShell alongside the Microsoft Graph PowerShell SDK. Record the module version and the connection method, which is the one thing about this module a later lab will want and cannot reconstruct. No script is written or committed in this lab, so the ADR-017 analysis and testing standard is not engaged.

Take the administrative-path decision the Prerequisites table flags. Message trace requires Exchange Administrator or Organization Management, and the Global Administrator account satisfies it. Lab 03 established both that least-privilege role assignment is the correct pattern and that Privileged Identity Management is unavailable at P1. Decide whether to assign Exchange Administrator for this lab's work and record the reasoning either way.

Establish the message trace instrument before anything depends on it. Send one throwaway message between two tenant mailboxes, then trace it, in the Exchange admin center and with `Get-MessageTraceV2`. Three things come out of this that later steps would otherwise have to discover mid-result: that the tool works at all, that the administrative path just chosen actually authorizes it, and this tenant's own observed latency against the five-to-ten, five-to-thirty, and ten-minutes-to-an-hour figures three Microsoft sources give. Record the observed figure as a reading rather than a confirmation of any of the three.

Establish the mail-flow DNS state for `brindeck.com`, which the Prerequisites table flags as the one item that could stop a step on the day. Read the accepted domains list and each domain's type, Authoritative or Internal Relay; which domain Exchange is using to derive default addresses; and what `brindeck.com`'s MX actually resolves to from a public resolver rather than from either administrative console, on the pattern Lab 01 Step Four set with `Resolve-DnsName -Server 1.1.1.1`. Record the SPF TXT record's presence or absence in the same read. Then take the path the Prerequisites section sets out, publish the records or confine the mail flow work to internal recipients, and record which was chosen and why.

Enumerate the Business Premium SKU's service plans in full, all 62 that Lab 03's Step Four counted and did not list, and establish from that list what this tenant is actually entitled to for mailbox archiving and hold. This is the read that settles the contradiction between Microsoft's litigation hold article and the Exchange Online Archiving service description, and it decides what Step Seven builds. Record the service plan names as read rather than cross-referenced from a friendly name, on the discipline Lab 03's Step Four established.

Record the Business Basic subscription's state in full, before it lapses on 2026-09-22: status, expiry date, assigned count, and which objects hold it. This is the before half of Step Six's observation and it cannot be re-taken later. Read the Business Premium subscription's Recurring billing field in the same sitting, since Lab 03 recorded it a day later than the stated expiry and left the discrepancy open.

Record the two dated carry-forward items this lab owns and that nothing else in the lab would otherwise touch: `AZUREADSSOACC`'s current key age against the 2026-09-30 interval Lab 03 deliberately left unrolled, and the permanent deletion dates standing against `Testgroup` and `nolocation-demo01`.

Close the step by committing this document, with the Business Basic prediction in it, before 2026-09-22. That commit is a condition of the step rather than housekeeping after it, for the reason Design Decisions gives.

### Step Two: Establish which accounts received mailboxes, and what an unlicensed account has instead

Exchange Online provisions a mailbox when a license carrying it is assigned, which means the licensed population Lab 03 established is the mailboxed population and the unlicensed accounts are not. Confirm that rather than assume it, for both object types: a synchronized user and a cloud-only user, licensed and unlicensed.

The instructive case is the unlicensed one. Establish what the account actually has, whether it appears in the Exchange admin center at all, what happens to mail addressed to it, and what error the sender receives. Lab 03 failed to induce a license assignment error across three attempted routes; this is a reachable failure mode in the same family and worth capturing properly if it presents.

Record the mailbox properties that matter operationally: the primary SMTP address and how it was derived, the mailbox size limit the Plan 1 license grants, and whether the address matches the UPN or diverges from it.

### Step Three: Build and catalogue the mail-enabled group types Lab 03 handed forward

Create a distribution list and a mail-enabled security group, the two types Lab 03 named as a boundary and did not build. Catalogue them alongside the Microsoft 365 groups the tenant already holds, recording for each: which console can create it, which can manage its membership, what it accepts as a member, whether it can hold permissions as well as receive mail, and what it looks like from the Entra admin center that cannot manage it.

The comparison that matters is the one Lab 03 could not make. A mail-enabled security group both receives mail and grants access; a distribution list only receives mail; a Microsoft 365 group does both and brings a shared mailbox, calendar, and SharePoint site with it. Those three are routinely conflated, and the tenant now holds all three.

Record what happens when an attempt is made to manage a synchronized group's mail properties in the cloud. This is the mail-side extension of Lab 03's per-field lock finding and the answer is not assumed here.

### Step Four: Create a shared mailbox and demonstrate all three delegation models

Create a shared mailbox through the Microsoft 365 admin center. Record that it requires no license of its own below 50 GB, and that a user accessing it does require an Exchange Online license, so the seat cost sits with the people who read the mailbox rather than with the mailbox.

Establish the state of its associated user account directly rather than taking it from documentation, per Design Decisions. Read whether sign-in is blocked, and record what the tenant did rather than what any article says it should have done.

Grant Full Access, Send As, and Send on Behalf, and exercise each with a real message sent to a recipient outside the delegation. Capture what the recipient receives in each case, because the `From` header the recipient sees is the only place the three differ in any way a user would notice.

Record what Full Access alone does and does not permit, since the most common real misconfiguration is granting it and expecting sending to work.

### Step Five: Build a mail flow rule, send mail through the objects built, and trace it

This is the step the lab is shaped around, and it is the step that closes the loop on the premise Project Context opens with. That premise is that a distribution list with correct membership and a transport rule silently dropping mail to it are indistinguishable from the object's own properties. So build the rule rather than only citing it.

Create a mail flow rule in the Exchange admin center that blocks or redirects mail matching a condition this lab controls, and record what it looks like from each side: what the rule's own configuration page says, what the distribution list's membership page says, which is nothing, and what the sender receives. This is the deliberate failure case, and building it rather than borrowing one means the failure has a known cause to check the trace against.

Send at least three messages and trace each: one to an individual mailbox, one to the distribution list built in Step Three, and one the rule stops. Record for each the delivery status message trace reports and what the detail view shows about the path the message took. The distribution list case should return a status of `Expanded`, showing the group resolving into its members, which is the clearest available demonstration of what a distribution list actually is.

A second failure case is available for free if the mail-flow DNS state Step One establishes permits external mail, and is worth taking because it is a default rather than a configuration. New distribution groups require that all senders be authenticated, which rejects mail from outside the organization until Delivery management is changed. Sending to the new distribution list from an external address exercises a restriction nobody configured, and the contrast with the rule-stopped message above is the difference between a policy an administrator wrote and a policy the product shipped. If external mail is not available, record the distribution list's Delivery management setting as read and note that the behavior was not exercised.

Record the instrument's own behavior alongside the results, because it is the kind of thing that reads as a failure when it is not. Results are immediate for searches of 10 days or less and delivered as a prepared report beyond that, and trace data is retained for 90 days with no configurable retention. On latency, compare what this step observes against the figure Step One's throwaway trace produced and against the three different ranges Microsoft's own sources give, and treat a message that has not appeared as unresolved rather than lost. Run the trace both in the Exchange admin center and with `Get-MessageTraceV2`, and record where the two differ in what they return.

Remove the mail flow rule at the end of the step and confirm mail flows again, so the lab's own test apparatus does not become Lab 05's inheritance.

### Step Six: Observe the Business Basic lapse

Pinned to 2026-09-22 rather than sequenced. This step is read when the date arrives, from whatever step the lab is standing in, and Steps Seven through Nine do not wait behind it. The prediction is recorded in Step One and in Design Decisions above, before the date and in a commit made before the date, and is not revised afterward.

Read the subscription's state, `Finance`'s group-level assignment, the Microsoft 365 admin center's assigned count, and `Get-MgSubscribedSku`'s consumed units, on the day before and again after the lapse date. Record what changed and what did not.

Three specific questions this step answers rather than assumes: whether the subscription entered an Expired state rather than disappearing, whether `Finance` still carries the assignment, and whether the target-versus-seat distinction Lab 03's Part C established still reconciles the two figures the same way. If any object held a Business Basic license through `Finance` at the moment of the lapse, record what happened to that user's access.

If the outcome contradicts the prediction, record both and say plainly which one the tenant supported.

Then apply the result to this lab's own schedule rather than only to the record, on the three-way branch Design Decisions sets out. An Expired stage that retains access means the 2026-10-05 cliff is probably a status change, and the lab records roughly 30 days of unplanned slack without spending it. A clean removal of access at the date confirms the cliff, and anything outstanding that needs a mailbox is triaged against 2026-10-05 immediately. Anything in between keeps the conservative assumption. Record which branch the tenant put the lab on.

### Step Seven: Establish the tenant's mailbox compliance surface and build what it supports

Decided by evidence rather than by citation, on the enumeration Step One produced. Two Microsoft documents disagree about whether this subscription carries archiving and hold, and this step acts on what the SKU actually holds.

Read the enumeration back first and state the entitlement plainly: which archiving and hold service plans appear on the Business Premium SKU, under their service plan names, and what provisioning state each reports. Then branch, and record which branch was taken and on what evidence.

If the entitlement is present, build it. Enable an archive mailbox on a user mailbox and record what the mailbox reports before and after, what the user sees in Outlook on the web, and how the archive's quota relates to the primary mailbox's. Place a litigation hold on a mailbox, record what the hold's configuration reports, and record the Recoverable Items quota change the hold produces, which is the property that makes a hold observable rather than declarative. Record a manual retention policy applied to a folder if the entitlement covers it. Remove the hold at the end of the step and confirm removal, because a hold left in place changes what deletion means for every later lab, including Step Eight's conversion in this one.

If the entitlement is absent, record the boundary on the SKU rather than on the article. State which service plans are and are not present, name both Microsoft documents and which one the tenant supported, and note that the capability is unavailable here for a reason now established rather than cited.

eDiscovery Premium stays out either way, on scope. Public folders stay out on the same grounds.

### Step Eight: Convert a departing user's mailbox to shared and reclaim the license

Create a purpose-built account for this, license it, let its mailbox provision, and put recognizable content in it. Do not use `cloudonly-demo01`, which Lab 05 inherits in a license-only state, and do not use any synchronized account.

Convert the mailbox to shared in the documented order and record the constraint that makes the order matter: the license must still be assigned at the moment of conversion or the option does not appear. Then remove the license and confirm the mailbox and its contents survived.

Confirm the reclaimed seat appears in both the Microsoft 365 admin center's count and `Get-MgSubscribedSku`'s consumed units, and record whether the two move together this time or diverge the way Lab 03's Part C found for group assignments.

Remove the purpose-built account at the end of the step so the lab's own fixtures do not become Lab 05's inheritance, and record the removal.

### Step Nine: Validate the environment is unchanged and record the finished state

Confirm that a lab conducted in two web consoles and one PowerShell module left everything else as it found it, and record what Lab 05 starts from.

`Test-ComputerSecureChannel` from WIN11-CLIENT01, a Group Policy result confirming `IT-Admin-Environment` still applies, taken at user scope since Lab 03 established that a computer-scoped result structurally cannot show it. `sssd` active on Ubuntu Server with a freshly issued Kerberos ticket rather than a cached one. On `SYNC01`, the Entra Connect version and source anchor unchanged, and `Get-ADSyncScheduler` read before anything that could force a cycle, with the suspended-VM behavior Lab 03 recorded applied rather than rediscovered.

Run `Invoke-LabHealthReport.ps1` for the overall picture and then `Get-LabWazuhAgentStatus -AgentName DC01,WIN11-CLIENT01,UBUNTU-SERVER,SYNC01` explicitly, recording both and the reason they differ. That defect is now carried by two tracks and confirmed by two labs. `Invoke-Pester -Path C:\Scripts -Output Detailed`, expected at 174 tests and 0 failed, since this lab commits no script.

Reconcile the finished state. Record every mail object that persists and every one the lab removed, including confirmation that Step Five's mail flow rule is gone and mail flows normally again, and that Step Seven's litigation hold is released if one was placed. Record the licensing state by assignment target and consumed seat for both SKUs. Record the state of the four objects Lab 03 left outside the Entra Overview's counts: `nolocation-demo01` and `Testgroup` retained, `duptest01` and `duptest02` purged. Record whether `cloudonly-demo01` is still license-only with no groups and no roles, which is the condition Lab 05 depends on and which nothing in this lab should have touched.

Close the three dated carry-forward items this lab owns rather than passing them on with their dates already spent.

Read `AZUREADSSOACC`'s key age again, against the 2026-09-30 interval Step One recorded. Lab 03 left the key unrolled at eleven days elapsed specifically so a later lab could watch a full thirty-day interval pass against a recommendation it had established as hygiene rather than a deadline. This is that lab. Record what a fully elapsed interval produced, which is most likely nothing observable, since that is the finding either way. Whether to automate the roll remains Lab 06's.

Take the decision on `Testgroup` and `nolocation-demo01`, whose permanent deletion dates of 2026-10-06 and 2026-10-07 both fall after this lab's own deadline. That makes this the last lab that can decide anything about either. `nolocation-demo01` is the artifact behind Lab 03's finding that a soft-deleted object keeps its `assignedLicenses` while consuming no seat, so record the case for letting it reach permanent deletion on its own against the case for restoring it first to read the property one last time, and take the decision rather than letting the date take it.

Record the entitlement position plainly, and record the discrepancy rather than resolving it silently. Business Premium expires 2026-10-05 by the subscription's stated end date, while the portal's own Recurring billing field reads 2026-10-06, which Lab 03 recorded and left open. This lab plans against the earlier of the two. State both, state which one this lab used, and state whether anything observed here settled it. With the subscription goes Exchange Online Plan 1, Microsoft Entra ID P1, and Microsoft Intune Plan 1, and Lab 05 needs the last two. Whether that decision is a renewal, a purchase, or a deliberate lapse is Lab 05's to take, and this lab's job is to hand it an accurate picture of what is about to end, including whatever Step Six established about the Expired stage.

---

## Validation

Planned validation, to be replaced with observed results as the lab is implemented. Each item maps to an objective above.

- **Mailbox provisioning.** Every licensed account in the hybrid population holds an Exchange Online mailbox, confirmed for both a synchronized and a cloud-only user. What an unlicensed account holds instead is recorded, including what a sender receives when addressing it.
- **Mail-enabled group types.** A distribution list and a mail-enabled security group exist in the tenant, catalogued alongside the Microsoft 365 groups it already held, with the administering console recorded for each and the differences between the three recorded on membership, permissions, and what each brings with it.
- **Shared mailbox and delegation.** A shared mailbox exists, unlicensed, with Full Access, Send As, and Send on Behalf each granted and each exercised with a real message. What the recipient sees in the `From` header is captured for all three. The sign-in state of the mailbox's associated user account is recorded as read from the tenant, against three Microsoft sources that disagree about what it should be.
- **Mail flow.** A mail flow rule is built, exercised, traced, and removed, with what it looks like from the object's own properties recorded alongside what the trace shows. At least three messages are traced end to end, including one to a distribution list returning a delivery status of `Expanded` and one the rule stops. Message trace's own retention and timing behavior is recorded alongside the results, with observed latency stated against the three different figures Microsoft's sources give rather than confirming any one of them.
- **Mail-flow DNS.** The accepted domain state for `brindeck.com`, its type, the domain Exchange derives default addresses from, and what its MX resolves to publicly are established in Step One, from outside the administrative consoles that would be describing their own state. Whichever path the result required, publishing the records or confining mail flow to internal recipients, is recorded as a decision with its reasoning.
- **The 2026-09-22 lapse.** A prediction is recorded before the date, in a commit made before the date, and the observed outcome after it, with the two stated separately and neither adjusted to match the other. The subscription's lifecycle state, `Finance`'s assignment, and both seat-count figures are recorded on each side of the date. What the result implied for this lab's own remaining schedule is recorded as a decision rather than left as an observation.
- **Mailbox compliance.** The Business Premium SKU's service plans are enumerated in full and the tenant's actual archiving and hold entitlement is stated from that enumeration, against two Microsoft documents that disagree about it. Whichever branch the evidence supported, building the capability or recording the boundary, is carried out and the evidence for it recorded.
- **Mailbox conversion and license reclamation.** A user mailbox is converted to shared with its contents intact, the license is reclaimed, and the ordering constraint is recorded as observed rather than cited.
- **Environment unchanged.** Host and service configuration on DC01, WIN11-CLIENT01, Ubuntu Server, and `SYNC01` confirmed operating as documented. All four Wazuh agents confirmed by explicit agent list. Entra Connect version, source anchor, and scheduler unchanged. Pester suite at 174 tests, 0 failed.
- **Finished state.** Every mail object created is accounted for as persisting or removed, including the mail flow rule and any hold placed. The licensing state is recorded by assignment target and consumed seat for both SKUs, with the 2026-10-05 and 2026-10-06 readings both stated. `cloudonly-demo01` is confirmed license-only with no groups and no roles.
- **Carry-forward.** The three dated items this lab owns are closed rather than passed on with their dates spent: the fully elapsed `AZUREADSSOACC` interval is read, the `Testgroup` and `nolocation-demo01` deletion windows are decided rather than allowed to expire by default, and the expiry discrepancy is stated with the figure this lab planned against.

---

## Troubleshooting and Adjustments

Recorded during implementation.

---

## Security Considerations

- **A shared mailbox has an associated user account, and whether it can sign in is not something to take on faith.** Microsoft's documentation gives three incompatible answers about the default, which is reason enough to read it from the tenant. Whatever the default turns out to be, the account exists and holds a system-generated password, so an administrator who resets that password has created a credentialed identity that nobody is monitoring and that no person is accountable for. Microsoft's own guidance is to block sign-in and keep it blocked.
- **Send As is an impersonation grant.** A user holding it sends messages that arrive with no indication a person other than the mailbox sent them, which is exactly what makes it useful for a shared support address and exactly what makes it dangerous on a mailbox that carries authority. The distinction from Send on Behalf is a security control, not a cosmetic preference, and the lab records which one is appropriate for the mailbox it builds.
- **Distribution lists reject external senders by default, and the risk is in what an administrator does next.** Microsoft's documented default is the safe one: new distribution groups require that all senders be authenticated, which blocks mail from outside the organization until Delivery management is changed. The exposure arrives when someone changes it, usually for a good reason such as a support alias that has to receive mail from customers, because an externally addressable distribution list is a delivery mechanism into every member's mailbox at once and nothing about the list's own page says so. This lab reads the setting as shipped rather than assuming either direction, and records what changing it would open.
- **The entitlement carrying every mailbox in this lab expires inside the next month.** What happens to a mailbox when its license lapses is a real operational question with a data-retention answer attached, and Lab 05 inherits it. The lab records the expiry position accurately rather than leaving a successor to discover it.
- **Message trace exposes message metadata across the organization.** Sender, recipient, subject, and delivery path for every message are readable by anyone holding Exchange Administrator or Organization Management. That is a meaningful privilege and it is part of why the administrative path is a Step One decision rather than a default.

---

## Outcome

Recorded at completion.

---

## Lessons Learned

Recorded at completion.

---

## Sources

To be completed during implementation, with each link confirmed resolving at close rather than reconstructed. Research consulted for this plan:

- [What happens to my data and access when my Microsoft 365 for business subscription ends?](https://learn.microsoft.com/microsoft-365/commerce/subscriptions/what-if-my-subscription-expires) - the Active, Expired, Disabled, Deleted lifecycle and the access retained at each stage
- [Data retention, deletion, and destruction in Microsoft 365](https://learn.microsoft.com/compliance/assurance/assurance-data-retention-deletion-and-destruction-overview) - subscription retention periods, and the separate 30-day grace status described for free trials
- [About shared mailboxes in Microsoft 365](https://learn.microsoft.com/microsoft-365/admin/email/about-shared-mailboxes) - the 50 GB unlicensed limit and the scenarios that require a license
- [Convert a user mailbox to a shared mailbox](https://learn.microsoft.com/microsoft-365/admin/email/convert-user-mailbox-to-shared-mailbox) - the ordering constraint on the license at conversion time
- [Exchange Online limits](https://learn.microsoft.com/office365/servicedescriptions/exchange-online-service-description/exchange-online-limits) - mailbox storage limits, and the shared mailbox associated account described as active
- [Exchange Online Archiving service description](https://learn.microsoft.com/office365/servicedescriptions/exchange-online-archiving-service-description/exchange-online-archiving-service-description) - the plan list naming Microsoft 365 Business Premium among those that already include archiving without the add-on, and the feature table giving Exchange Online Archiving for Exchange Online both Litigation Hold and retention policies
- [Place a mailbox on litigation hold](https://learn.microsoft.com/microsoft-365/admin/misc/create-litigation-hold-mac) - the contradicting statement that a hold requires Exchange Online Plan 2, or Plan 1 plus a separate Exchange Online Archiving license
- [Manage distribution groups](https://learn.microsoft.com/exchange/recipients/distribution-groups) - that new distribution groups require all senders to be authenticated by default, which blocks external senders until Delivery management is changed
- [Message trace in the Exchange admin center in Exchange Online](https://learn.microsoft.com/exchange/monitoring/trace-an-email-message/message-trace-modern-eac) - delivery status values including `Expanded`, and the permissions required
- [Message Trace FAQ in Exchange Online](https://learn.microsoft.com/exchange/monitoring/trace-an-email-message/message-trace-faq) - 90-day retention, the 10-day query window, `Get-MessageTraceV2`, and a stated five to ten minute appearance latency
- [Monitoring, reporting, and message tracing in Exchange Online](https://learn.microsoft.com/exchange/monitoring/monitoring) - the same latency stated as five to thirty minutes for messages less than seven days old
- [Find and fix email delivery issues as a Microsoft 365 for business admin](https://learn.microsoft.com/troubleshoot/exchange/email-delivery/email-delivery-issues) - the same latency stated as ten minutes to one hour

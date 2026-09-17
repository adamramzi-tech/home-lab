# 04 - Microsoft 365 Administration Workflows

## Status

In progress. Steps One through Three are complete. Step One recorded the pre-lab mail baseline, the administrative path, the message trace instrument, the mail-flow DNS state, the Business Premium service plan enumeration and the reconciliation of the three service counts Lab 03 left open, and both entitlement dates' pre-lapse readings. Step Two confirmed the licensed-equals-mailboxed premise from live state on both object types, established what an unlicensed account has instead using Mary Johnson and traced the categorizer-level rejection a message to her produces rather than Directory-Based Edge Blocking, closed Step One's primary-address finding on Alex Kim and John Smith with a disproved rather than confirmed hypothesis, recorded the operationally relevant mailbox properties and settled the 100 GB mailbox quota against the Business Basic SKU's own service plans before that subscription lapses, and took Adam Ramzi's pre-lapse mailbox baseline for Step Six. Step Three built `Help-Desk`, a distribution list, and `IT-Support`, a mail-enabled security group, the two mail-enabled group types Lab 03 deliberately left as a boundary; catalogued all three mail-enabled group types by console, accepted member types, permissions granted beyond mail, and Entra admin center rendering, confirming the "can't be managed" boundary directly rather than taking it from the track README; confirmed empirically that a distribution list and a mail-enabled security group both accept a nested security group as a member while a Microsoft 365 group rejects one outright; tested a synchronized on-premises group's cloud-side mail-property write and recorded its outright rejection, distinct from the per-field allowlist Lab 03 found on user objects; traced a real message through `IT-Support` and followed it to a `Delivered` row for each member, closing the coverage gap Step Five's own plan would otherwise have left; and declared both new groups' disposition, removal at Step Nine once Step Five's own trace against `Help-Desk` completes. Steps Four through Nine remain.

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
| Three unreconciled service counts on one SKU | Closed by Lab 04 | Step One enumerated the SKU's service plans in full and diffed the names against the Microsoft 365 admin center's own Apps list rather than comparing totals. Each figure counts a different thing: 62 is every service plan on the SKU, the admin center's list is that set less `EXCHANGE_S_FOUNDATION`, which is not an assignable app, and the Entra blade's 53 is what remains after the eight plans assigned at the organization level. Step Nine re-reads the Entra blade to confirm the last of the three |
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
| An administrative account able to run message trace | Lab 01, Lab 03 | Met, and settled in Step One. Message trace requires Exchange Administrator or Organization Management membership, and the tenant's existing Global Administrator qualifies. No Exchange Administrator assignment was made. Step One records why, which turns on Privileged Identity Management being unavailable at P1 and on the privileged-role review Lab 05 owns |
| `cloudonly-demo01` in a license-only state | Lab 03 | Met and must be preserved. No groups, no directory roles, one license. Lab 05 inherits it in the same state |
| The `ExchangeOnlineManagement` PowerShell module | This lab | Met in Step One. Version 3.10.1 installed on WIN11-CLIENT01 per ADR-016, which ADR-019's Primary Tooling already names alongside the Microsoft Graph PowerShell SDK, and connected over an interactive REST-backed V3 session |
| Mail-flow DNS for `brindeck.com` | Lab 01 | Met, and settled in Step One. This was the only prerequisite here that could have stopped a step on the day. Lab 01 verified the domain with a single TXT record, `MS=ms19821357`, published in Cloudflare and added through the Entra admin center's Domain names blade. That blade establishes ownership and nothing else. The Microsoft 365 domain setup that publishes the MX, SPF, and Autodiscover records was never run, and no lab in this track has published an MX record for `brindeck.com`. Step One established the actual state: no MX record and no SPF record exist for the domain, and DC01 holds neither a zone nor a conditional forwarder for it, so nothing shadows the public answer. The lab confines its mail flow work to internal recipients on that basis |

Two entitlement dates constrain everything below. Business Basic (no Teams) lapses 2026-09-22. Business Premium expires 2026-10-05, on the conservative reading of a one-day discrepancy Lab 03 recorded and left open, and takes Exchange Online Plan 1 and Microsoft Entra ID P1 with it unless the subscription lifecycle's Expired stage applies, which Step Six tests.

**What the mail-flow DNS row gates, stated before the lab runs rather than discovered when a message does not arrive.** `brindeck.com` carries the Primary checkmark in the tenant, so the mailboxes Lab 03's licensing provisioned most likely hold `@brindeck.com` primary SMTP addresses. Internal tenant-to-tenant mail is routed inside the service and never consults public DNS, so Steps Two, Three, and Four are unaffected either way: mailbox provisioning, the group-type catalogue, and all three delegation models can be demonstrated entirely between mailboxes in this tenant. What depends on the records existing is narrower and specific. Any message to or from a recipient outside the tenant needs MX for inbound and a correct SPF record for outbound to survive the receiving side's checks. The external-sender premise in Security Considerations below, which is about a distribution list being addressable from outside the organization, cannot be tested at all without inbound mail flow.

Step One settled it, and the lab took the second of the two paths this plan set out. Neither an MX nor an SPF record exists for `brindeck.com`, so the choice was between publishing them in Cloudflare as a documented step and confining the mail flow work to internal recipients. Step One records why it chose the latter. Step Five's mail flow rule and both of its delivery-status cases work internally, so the deliberate failure case survives unchanged; what does not survive is the external-sender premise in Security Considerations, which is recorded there as documented behavior rather than tested live. What the lab did not do is write steps that assume external delivery and find out at the trace.

---

## Implementation

Nine steps. Every step except Step Six requires Exchange Online and must therefore complete before 2026-10-05, when Exchange Online Plan 1 ends with the Business Premium trial. That is Steps One through Five and Steps Seven through Nine: Step Two reads mailboxes, Step Three creates mail-enabled groups, Step Four creates and delegates a shared mailbox, Step Five traces mail through both, Step Seven works on mailbox compliance, Step Eight converts a mailbox, and Step Nine reconciles the mail state. Step Six is the only step in the lab that needs no mailbox, and it is the one pinned to a date.

Two steps are fixed by dates outside the lab rather than by their position in it, and they are fixed in opposite directions.

Step One is the urgent one and the easier to miss. It takes the before half of Step Six's observation, so it has to run before 2026-09-22 or the comparison has nothing to compare against and the observation is lost for good. It also closes on committing this document, prediction included, before that date. Step One is the only step in this lab that cannot be caught up later.

Step Six is pinned rather than sequenced. It is read when 2026-09-22 arrives, from whatever step the lab happens to be standing in, and Steps Seven through Nine are not blocked behind it. Its position in the numbering is a reading convenience. Its result also feeds back into this lab's own schedule, on the terms Design Decisions set out above.

### Step One: Recorded the pre-lab mail baseline and established the administrative path

The tenant's mail state was read before anything was touched, on the discipline Lab 03's Step Ten established after finding the live tenant had quietly diverged from what its own document claimed.

The Exchange admin center's Recipients, Mailboxes view listed seven recipients, all UserMailbox: Adam Ramzi (`Adam@brindeck.onmicrosoft.com`), Alex Kim (`akim@brindeck.onmicrosoft.com`), Cloud Administrator (`admin@brindeck.com`), the Cloud-Only Demo Account (`cloudonly-demo01@brindeck.com`), Jane Doe (`jdoe@brindeck.com`), John Smith (`jsmith@brindeck.onmicrosoft.com`), and testuser01 (`testuser01@brindeck.com`). The Entra admin center's Users blade still held all ten. The three without a mailbox, Emergency Access Account, Mary Johnson, and Test Sync, are exactly the three that never appear among Lab 03's licensed assignment targets on either SKU, so the gap tracks the licensing record rather than looking like drift.

<p align="center">
  <img src="../../images/cloud-and-hybrid-identity/04-microsoft-365-administration-workflows/01-exchange-admin-center-mailboxes-pre-lab.jpg" alt="01-exchange-admin-center-mailboxes-pre-lab" width="700">
</p>

<p align="center">
  <em>Exchange admin center, Recipients, Mailboxes: seven UserMailbox recipients, none archived.</em>
</p>

One thing in the baseline does not resolve cleanly and is recorded as a finding rather than forced into an explanation. Two of the seven mailboxes carry a primary address that does not match their user principal name: Alex Kim's and John Smith's sit on `akim@brindeck.onmicrosoft.com` and `jsmith@brindeck.onmicrosoft.com` despite both holding `@brindeck.com` UPNs. Four sit on `@brindeck.com` matching theirs, those of Jane Doe, Cloud Administrator, the Cloud-Only Demo Account, and testuser01. The seventh, Adam Ramzi, sits on the initial domain as the tenant's original signup account from Lab 01, so its address is evidence of nothing here and is set aside rather than counted either way.

`brindeck.com` reads as the tenant's default accepted domain (`Get-AcceptedDomain` returned `Default: True` for `brindeck.com` alone, matching the Microsoft 365 admin center's own "(default domain)" label), so the default-domain reading does not explain the two. Neither does synchronization source, which is the obvious next guess and is wrong here: Jane Doe and testuser01 are both synchronized from Windows Server AD, on Lab 03's own source breakdown, and both sit on `brindeck.com`. What this baseline did not read is the full `EmailAddresses` stamp on each mailbox, which is where an answer would be if a primary address was set before `brindeck.com` was verified on 2026-08-23 and never reapplied afterward. Step Two reads it. It is left open until then rather than resolved here.

Recipients, Groups showed exactly the two Microsoft 365 groups Lab 03 left, All Company and Company Announcements, with the tenant's Distribution list, Dynamic distribution list, and Mail-enabled security tabs all empty, confirming the boundary Lab 03 handed forward rather than assuming it held. Mail flow, Accepted domains listed three domains, all Authoritative and all Allow Sending: `brindeck.onmicrosoft.com`, `brindeck.com` (the default), and `brindeck.mail.onmicrosoft.com`, which no prior lab in this track added. Microsoft's own glossary names that form the tenant's hybrid routing domain, used to route mail between an on-premises Exchange organization and Exchange Online. This environment has no on-premises Exchange, so the domain is present without being in use. Whether the service provisions it for every tenant or something in this one produced it is not established here.

`ExchangeOnlineManagement` 3.10.1 was installed on WIN11-CLIENT01 (`Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber`; the plain `-Force` install failed on a PackageManagement/PowerShellGet version clobber, a Windows PowerShell 5.1 packaging issue rather than a real blocker, recorded in Troubleshooting and Adjustments) and connected with `Connect-ExchangeOnline -UserPrincipalName admin@brindeck.com`, an interactive, REST-backed V3 connection that needs no WinRM Basic Auth. `Get-ConnectionInformation` confirmed `State: Connected`, `TenantId dc2a02ec-636d-4df3-9af2-2908706aed4b`, token valid to 9/16/2026. No script is written or committed in this lab, so the ADR-017 analysis and testing standard is not engaged, per Prerequisites.

The Prerequisites table's administrative-path decision was taken in the same sitting: this lab's message trace and read-only Exchange work runs under the existing Global Administrator account rather than a dedicated Exchange Administrator assignment. Message trace requires Exchange Administrator or Organization Management, and Global Administrator satisfies it automatically. Lab 03 established least-privilege role assignment as the correct pattern in general, but Privileged Identity Management remains unavailable at P1, so any role assigned here would be a standing grant with no eligible or time-bound mechanism to remove it afterward, on a tenant that already carries three Global Administrators pending the privileged-role review Lab 01 opened and Lab 05 owns. Adding a fourth standing assignment now, to satisfy one lab's read-only diagnostic need, works against that pending review rather than for least privilege, so the existing account was used instead and the reasoning is recorded here rather than left implicit.

The message trace instrument was established before anything else depended on it, per Design Decisions. One throwaway message was sent from `testuser01@brindeck.com` to `jdoe@brindeck.com` through Outlook on the web at 2:49 PM Eastern on 9/15/2026, subject "Lab 04 Step One - message trace test." It was already present in the Exchange admin center's Message trace when that view was checked, Status `Delivered`, and `Get-MessageTraceV2` returned the identical record:

```powershell
Get-MessageTraceV2 -SenderAddress testuser01@brindeck.com -RecipientAddress jdoe@brindeck.com -StartDate (Get-Date).AddHours(-2) -EndDate (Get-Date) | Format-List
```

```text
Message Trace ID  : eae41014-8164-4376-a1fa-08df135a0c67
Message ID        : <PH0PR18MB38137387C5DD87452A5C99D2ADBA2@PH0PR18MB3813.namprd18.prod.outlook.com>
Received          : 9/15/2026 6:49:18 PM
Sender Address    : testuser01@brindeck.com
Recipient Address : jdoe@brindeck.com
From IP           : [redacted, originating client address]
To IP             :
Subject           : Lab 04 Step One - message trace test
Status            : Delivered
Size              : 36070
```

`To IP` returns empty. The message never left the service: both mailboxes are in this tenant, so Exchange Online routed it internally and there is no destination host outside the service to name. That is the same reason Step One's mail-flow DNS finding does not block Steps Two through Five.

The received timestamp, 6:49:18 PM UTC, matches the 2:49 PM Eastern send time to the minute. That measures delivery, which is not the quantity the three conflicting Microsoft figures describe. Those figures, five to ten minutes, five to thirty minutes, and ten minutes to an hour, are about how long a message takes to become queryable in trace data, and the evidence for that here is weaker than the delivery timestamp is: the record was already present when the view was first checked, and the interval between sending and checking was not timed. What this establishes is a ceiling comfortably under the lowest of the three figures rather than a measured reading to set against them, and it is recorded that way rather than as a latency figure this tenant has confirmed. Step Five traces several more messages and can time the interval properly. The administrative path chosen above authorized both reads without incident.

The originating client address that `Get-MessageTraceV2` returns in the `From IP` field is redacted above under this track's identifier policy. It is the public address of the connection the message was sent from, which is a fact about the lab's own network rather than about the tenant, and it is the one identifier a message trace prints that maps to a physical location.

Mail-flow DNS for `brindeck.com` was established next, since the Prerequisites table flags it as the one item that could stop a step on the day. `Get-AcceptedDomain` (above) confirmed `brindeck.com` as the tenant's default domain. From WIN11-CLIENT01, against a public resolver rather than either administrative console, on the Lab 01 Step Four pattern:

```powershell
Resolve-DnsName -Name brindeck.com -Type MX -Server 1.1.1.1
```

returned no MX record at all, only an SOA record in the Authority section, which is how a public resolver signals that no record of the requested type exists for the zone. The same query for TXT returned only Lab 01's original domain-verification string, `MS=ms19821357`; no SPF record accompanies it. Neither an MX nor an SPF record has been published for `brindeck.com` at any point in this track, exactly as the Prerequisites table anticipated. On DC01:

```powershell
Get-DnsServerZone -ComputerName DC01 | Where-Object ZoneName -like '*brindeck*'
Get-DnsServerForwarder -ComputerName DC01
```

returned no zone matching `brindeck` at all, and a forwarder list of `1.1.1.1`, `8.8.8.8`, and one IPv6 resolver, none of it a conditional forwarder scoped to `brindeck.com`. DC01 neither hosts nor shadows the domain, confirmed rather than assumed, and its own general forwarders are public resolvers, so there is no shadowing risk in either direction.

With MX and SPF both absent, this lab takes the Prerequisites fork by confining its mail flow work to internal recipients rather than publishing either record in Cloudflare. `brindeck.com` is a real, registered domain rather than a disposable lab fixture, and publishing an MX record would make it a live internet mail destination reachable by anyone, indefinitely, which is an exposure decision rather than a configuration step. Nothing this lab's objectives require depends on it: Step Five's mail flow rule and its `Expanded` and blocked-message delivery statuses both work entirely on internal mail by the plan's own design. Only a bonus external-sender test against the new distribution list's default authenticated-senders-only restriction, and the external-sender premise in Security Considerations, go unexercised as a result, and both are recorded as documented behavior rather than something tested live.

The Business Premium SKU's service plans were enumerated in full, all 62 that Lab 03's Step Four counted and did not list:

```powershell
Connect-MgGraph -Scopes "Organization.Read.All"
(Get-MgSubscribedSku | Where-Object SkuPartNumber -eq "SPB").ServicePlans | Sort-Object ServicePlanName | Format-Table ServicePlanName, ProvisioningStatus -AutoSize
```

(`Connect-MgGraph` was required first, since Microsoft Graph cmdlets authenticate per session.) All 62 read `Success` except `INTUNE_O365` at `PendingActivation`, matching Lab 03's count and its one exception exactly, no drift. The names are recorded here rather than counted, which is the whole point of the read:

```text
ServicePlanName                            ProvisioningStatus
---------------                            ------------------
AAD_PREMIUM                                Success
AAD_SMB                                    Success
ADALLOM_S_DISCOVERY                        Success
ATP_ENTERPRISE                             Success
Bing_Chat_Enterprise                       Success
BPOS_S_DlpAddOn                            Success
BPOS_S_TODO_1                              Success
CDS_O365_P3                                Success
CLIPCHAMP                                  Success
Deskless                                   Success
DYN365_CDS_O365_P3                         Success
DYN365BC_MS_INVOICING                      Success
EXCHANGE_S_ARCHIVE_ADDON                   Success
EXCHANGE_S_FOUNDATION                      Success
EXCHANGE_S_STANDARD                        Success
EXCHANGE_STORAGE_50GB                      Success
FLOW_O365_P1                               Success
FORMS_PLAN_E1                              Success
GRAPH_CONNECTORS_SEARCH_INDEX              Success
INSIGHTS_BY_MYANALYTICS                    Success
INTUNE_A                                   Success
INTUNE_O365                                PendingActivation
INTUNE_SMBIZ                               Success
KAIZALA_O365_P2                            Success
M365_LIGHTHOUSE_CUSTOMER_PLAN1             Success
M365_LIGHTHOUSE_PARTNER_PLAN1              Success
MCOSTANDARD                                Success
MDE_SMB                                    Success
MESH_AVATARS_ADDITIONAL_FOR_TEAMS          Success
MESH_AVATARS_FOR_TEAMS                     Success
MESH_IMMERSIVE_FOR_TEAMS                   Success
MFA_PREMIUM                                Success
MICROSOFT_LOOP                             Success
MICROSOFT_MYANALYTICS_FULL                 Success
MICROSOFT_SEARCH                           Success
MICROSOFTBOOKINGS                          Success
MYANALYTICS_P2                             Success
Nucleus                                    Success
O365_SB_Relationship_Management            Success
OFFICE_BUSINESS                            Success
OFFICE_SHARED_COMPUTER_ACTIVATION          Success
PEOPLE_SKILLS_FOUNDATION                   Success
PLACES_CORE                                Success
POWER_VIRTUAL_AGENTS_O365_P3               Success
POWERAPPS_O365_P1                          Success
PROJECT_O365_P3                            Success
PROJECTWORKMANAGEMENT                      Success
PURVIEW_DISCOVERY                          Success
RMS_S_ENTERPRISE                           Success
RMS_S_PREMIUM                              Success
SHAREPOINTSTANDARD                         Success
SHAREPOINTWAC                              Success
STREAM_O365_E1                             Success
SWAY                                       Success
TEAMS1                                     Success
UNIVERSAL_PRINT_01                         Success
VIVA_LEARNING_SEEDED                       Success
VIVAENGAGE_CORE                            Success
WHITEBOARD_PLAN1                           Success
WINBIZ                                     Success
WINDOWSUPDATEFORBUSINESS_DEPLOYMENTSERVICE Success
YAMMER_ENTERPRISE                          Success
```

Among the 62 is `EXCHANGE_S_ARCHIVE_ADDON`, alongside `EXCHANGE_S_FOUNDATION`, `EXCHANGE_S_STANDARD`, and `EXCHANGE_STORAGE_50GB`. That settles the contradiction Design Decisions raised between Microsoft's litigation hold article and its Exchange Online Archiving service description, and it settles it more directly than either document states: the archiving add-on's own service plan is bundled into the SPB SKU itself, provisioned and successful, not merely implied by a tier exemption. Step Seven has a real capability to build against on this evidence, not a boundary to declare.

**The three unreconciled service counts, settled.** Lab 03 read three different figures off this one SKU and reconciled none of them: 62 service plans through Microsoft Graph, 60 apps in the Microsoft 365 admin center, and "53 of 53 enabled services" on the Entra admin center's Licenses blade. It recorded all three and passed the question forward. Having the 62 names in hand makes the comparison a diff rather than a hypothesis, so `testuser01`'s Licenses and apps tab was expanded and every entry read against them.

The admin center reads 61 rather than Lab 03's 60, on the same account's tab that Lab 03 read. The service plan count did not move with it: 62 then, 62 now. Nothing arrived on the SKU, so whatever changed is in what the admin center surfaces rather than in what the subscription contains. Three explanations fit and none can be tested, because Lab 03 recorded its 60 as a number and not as a list. Two plans may have gone unsurfaced then where one does now. One plan may have been substituted for another, leaving the total intact. Or Lab 03's reading, taken immediately after the license was saved, may have caught the panel before it had finished populating. The movement is recorded as unexplained rather than attributed to any of the three.

Mapping the 61 friendly names onto the 62 service plan names accounts for every app, leaving exactly one service plan with no counterpart in the Apps list: `EXCHANGE_S_FOUNDATION`. That it is the one plan with no app entry is what was observed. The likely reason is that it is the underlying Exchange entitlement every Exchange-bearing SKU carries rather than a capability an administrator grants or revokes, which would leave the admin center nothing to offer, but this read does not establish that and it is offered as the probable explanation rather than the finding. The Apps list is the service plan list minus that one entry. Two pairs are close enough in name that which friendly label belongs to which plan cannot be settled by eye, the two MyAnalytics plans and the two Common Data Service plans, but both members of each pair appear on both lists, so the pairing does not affect the count.

The third figure follows from the same reading. Eight of the 61 are greyed and unchecked, each carrying the note that it is assigned at the organization level and cannot be assigned per user. Named as the admin center labels them, rather than by the service plan names behind them, they are DO NOT USE - Microsoft MyAnalytics (Full), Insights by MyAnalytics Backend, Microsoft 365 Lighthouse (Plan 1), Microsoft 365 Lighthouse (Plan 2), Microsoft Defender for Office 365 (Plan 1), Microsoft Search, Mobile Device Management for Office 365, and Nucleus. Sixty-one less those eight is 53, which is what the Entra blade counts. Each figure is therefore a different and correct answer to a different question: 62 is everything on the SKU, 61 is what the admin center presents as an app, and 53 is what can actually be toggled for one user.

One detail sits alongside that without explaining it. `INTUNE_O365`, the single plan on the SKU not reading `Success`, is also one of the eight the admin center will not let an administrator assign per user, appearing there as Mobile Device Management for Office 365. Whether `PendingActivation` and organization-level assignment are related is not established by anything read here, and the coincidence is recorded rather than resolved.

Two of Lab 03's own guesses at the gap are disproved by the same read. It suggested that `INTUNE_O365` at `PendingActivation` plausibly accounted for one of the missing two and that `AAD_PREMIUM` being a licensing feature rather than a user-facing app accounted for the other. Both appear in the list, as Mobile Device Management for Office 365 and Microsoft Entra ID P1 respectively, so neither is the explanation.

One piece is a prediction rather than a reading and is marked as such. The Entra admin center's Licenses blade was not re-read in this step, and Lab 03 read its 53 on Alex Kim's blade rather than this account's, though both hold the same SKU by direct assignment. The prediction rests on this step's own reading rather than on Lab 03's: 61 apps less the eight the admin center will not assign per user is 53, so the blade should still read 53. Lab 03's own pair implies seven organization-level entries then against eight now, which is a second figure that moved in the same unexplained direction as the first and is recorded beside it rather than used to justify anything. Step Nine reads that blade again and either confirms the model or breaks it.

The count movement carries a lesson worth more than the reconciliation. Lab 03 recorded "60 apps" as a number and not as a list, so which app arrived since cannot now be determined from anything in this repository. A figure recorded without the names behind it cannot be diffed later, which is why the 62 are written out above rather than counted.

The Business Basic (no Teams) subscription was read in full before its 2026-09-22 lapse. Subscription status Active, Expiration date 9/22/2026, 2 of 25 licenses assigned, unchanged from Lab 03's own close (Finance, empty, and Adam Ramzi as the two assignment targets, one seat actually consumed). Its Recurring billing field, however, reads "Expires on September 23, 2026," a full day later than the page's own stated Expiration date. That is the identical one-day discrepancy Lab 03 found on Business Premium (stated expiry 10/5/2026, Recurring billing reading 10/6/2026), now appearing a second time on a different subscription. Read in the same sitting, Business Premium's own figures are unchanged from Lab 03's close: 7 of 25 assigned, Expiration date 10/5/2026, Recurring billing still reading "Expires on October 6, 2026." Two independent instances of the same pattern is no longer a coincidence worth treating as one; it is recorded as a reproducible property of this portal's billing page rather than a one-off oddity Lab 03 happened to notice.

<p align="center">
  <img src="../../images/cloud-and-hybrid-identity/04-microsoft-365-administration-workflows/02-business-basic-product-page-pre-lapse.jpg" alt="02-business-basic-product-page-pre-lapse" width="450">
</p>

<p align="center">
  <em>Microsoft 365 admin center, Billing, Your products, Business Basic (no Teams), read before the 2026-09-22 lapse: 2 of 25 assigned, Expiration date 9/22/2026, Recurring billing reading "Expires on September 23, 2026."</em>
</p>

<p align="center">
  <img src="../../images/cloud-and-hybrid-identity/04-microsoft-365-administration-workflows/03-business-premium-product-page-recurring-billing.jpg" alt="03-business-premium-product-page-recurring-billing" width="450">
</p>

<p align="center">
  <em>The same Billing, Your products view for Business Premium, read in the same sitting: 7 of 25 assigned, Expiration date 10/5/2026, Recurring billing reading "Expires on October 6, 2026," both unchanged from Lab 03's close.</em>
</p>

**The prediction for the 2026-09-22 lapse.** Per Design Decisions, it is recorded here, before the date, and is not adjusted afterward.

It departs from what Design Decisions anticipated, and the reason is recorded rather than the departure being made quietly. That section argued the Expired stage would probably apply, giving roughly 30 days of retained access past the date. Reading the same Microsoft lifecycle article in full while writing this step turned up a note that section had not accounted for: as of 2026-02-09, the Expired state no longer applies to license-based subscriptions bought directly through a Microsoft Customer Agreement. This subscription's own product page reads Purchase channel: Commercial direct. If a direct commercial purchase is an MCA purchase, the Expired stage does not apply here at all, and the subscription moves from Active straight to Disabled, where users lose access immediately and only administrators retain access to data. Predicting the cushion anyway, having read the note that removes it, would not be a prediction.

So the call is that **2026-09-22 removes access rather than deferring it**. Three sub-predictions follow, each able to fail on its own:

- **The date is 9/22, not 9/23.** The Recurring billing field reading "Expires on September 23, 2026" is most likely a billing-period boundary displayed against a last-service-day of 9/22 rather than a second real date, which would also explain the identical one-day offset on Business Premium. Reading both days settles it.
- **Adam Ramzi's mailbox survives the date even though his license does not.** He holds the subscription's single consumed seat, it is the only license he holds, and it carries the Exchange Online Plan 1 behind his mailbox. Losing a license puts a mailbox into Exchange's own retention rather than deleting it, which is a separate mechanism from the subscription lifecycle, so the mailbox should remain recoverable by reassigning a license for roughly 30 days, to about 2026-10-22.
- **The article's trial clause does not apply.** Its statement that trial account information and data are permanently deleted when a trial ends describes a trial tenant, not a trial subscription running inside an established tenant that holds a verified domain and a second subscription. If that reading is wrong, it is the most consequential thing this step got wrong.

`Finance` is empty, so its group-level assignment is a question about whether the assignment record survives rather than about anyone's access.

**The lapse is allowed to happen rather than prevented, and that is a decision.** Assigning Adam Ramzi a Business Premium license before the date would preserve the mailbox, and it would also destroy the observation Step Six exists to make, at the cost of a seat. Nothing of value is at risk: the account's mailbox holds this step's own test message and nothing else, and because Microsoft Entra roles do not require a license, the account keeps Global Administrator, keeps sign-in, and keeps the admin center through the lapse whatever happens to its mailbox. The observation is worth more than the mailbox. The prediction stands as written regardless of what Step Six finds.

The two dated carry-forward items this lab owns were both read fresh rather than carried forward from Lab 03's prose. `Get-ADComputer -Identity AZUREADSSOACC -Properties PasswordLastSet,whenChanged` returned `PasswordLastSet: 8/31/2026 8:07:44 PM`, unchanged from Lab 03's own reading, fifteen days elapsed as of this reading on 2026-09-15 against the thirty-day interval Lab 03 deliberately left unrolled, exactly at that interval's midpoint and comfortably short of 2026-09-30. Entra admin center, Deleted users and Deleted groups confirmed both retained objects exactly as the track README recorded them: `nolocation-demo01` deleted 9/7/2026 4:01 PM, permanent deletion 10/7/2026 4:01 PM; `Testgroup` deleted 9/6/2026 5:08:17 PM, permanent deletion 10/6/2026 5:08:17 PM. Neither shows any drift from Lab 03's close.

### Step Two: Established which accounts received mailboxes, and what an unlicensed account has instead

Exchange Online provisions a mailbox when a license carrying it is assigned, so the licensed population Lab 03 established should be the mailboxed population and the unlicensed accounts should not. This was confirmed from live state on 2026-09-16 rather than assumed from Step One's baseline, across both object types.

```powershell
Get-MgUser -All -Property Id,DisplayName,UserPrincipalName,OnPremisesSyncEnabled | ForEach-Object {
    $lic = Get-MgUserLicenseDetail -UserId $_.Id
    [PSCustomObject]@{
        DisplayName    = $_.DisplayName
        UPN            = $_.UserPrincipalName
        Synced         = $_.OnPremisesSyncEnabled
        LicenseCount   = @($lic).Count
        SkuPartNumbers = ($lic.SkuPartNumber -join ',')
    }
} | Sort-Object DisplayName | Format-Table -AutoSize
```

```text
DisplayName                              UPN                                        Synced LicenseCount SkuPartNumbers
-----------                              ---                                        ------ ------------ --------------
Adam Ramzi                               Adam@brindeck.onmicrosoft.com                     1            Microsoft_365_Business_Basic_(no Teams)
Alex Kim                                 akim@brindeck.com                          True   1            SPB
Cloud Administrator                      admin@brindeck.com                                1            SPB
Cloud-Only Demo Account (Lab 03 fixture) cloudonly-demo01@brindeck.com                     1            SPB
Emergency Access Account                 [redacted]@brindeck.onmicrosoft.com                0
Jane Doe                                 jdoe@brindeck.com                          True   1            SPB
John Smith                               jsmith@brindeck.com                        True   1            SPB
Mary Johnson                             mjohnson@brindeck.com                      True   0
Test Sync                                tsync01@brindeck.com                       True   0
testuser01                               testuser01@brindeck.com                    True   1            SPB
```

`Get-MgUserLicenseDetail` reads the resultant license set rather than only direct assignment, which is why John Smith shows a license here even though Lab 03 recorded his as sourced through `Company Announcements` membership rather than direct assignment; the count is correct, the source is a separate question this step does not need to reopen.

```powershell
Get-EXOMailbox -ResultSize Unlimited | Select-Object DisplayName,PrimarySmtpAddress,RecipientTypeDetails,UserPrincipalName | Sort-Object DisplayName | Format-Table -AutoSize
```

```text
DisplayName                              PrimarySmtpAddress                                                                     RecipientTypeDetails UserPrincipalName
-----------                              ------------------                                                                     --------------------- -----------------
Adam Ramzi                               Adam@brindeck.onmicrosoft.com                                                          UserMailbox            Adam@brindeck.onmicrosoft.com
Alex Kim                                 akim@brindeck.onmicrosoft.com                                                          UserMailbox            akim@brindeck.com
Cloud Administrator                      admin@brindeck.com                                                                     UserMailbox            admin@brindeck.com
Cloud-Only Demo Account (Lab 03 fixture) cloudonly-demo01@brindeck.com                                                          UserMailbox            cloudonly-demo01@brindeck.com
Discovery Search Mailbox                 DiscoverySearchMailbox{D919BA05-46A6-415f-80AD-7E09334BB852}@brindeck.onmicrosoft.com  DiscoveryMailbox       DiscoverySearchMailbox{D919BA05-46A6-415f-80AD-7E09334BB852}@brindeck.onmicrosoft.com
Jane Doe                                 jdoe@brindeck.com                                                                      UserMailbox            jdoe@brindeck.com
John Smith                               jsmith@brindeck.onmicrosoft.com                                                        UserMailbox            jsmith@brindeck.com
testuser01                               testuser01@brindeck.com                                                                UserMailbox            testuser01@brindeck.com
```

Both directions confirm the premise exactly. The seven accounts with a `LicenseCount` of 1 (Adam Ramzi, Alex Kim, Cloud Administrator, the Cloud-Only Demo Account, Jane Doe, John Smith, and testuser01) are exactly the seven `UserMailbox` recipients; the three with `LicenseCount` of 0 (Emergency Access Account, Mary Johnson, and Test Sync) have no recipient object at all. The `Synced` column cross-checks Lab 03's object-type split at the same time: `True` on the six synchronized accounts, blank on the four cloud-only ones, matching Lab 03's own breakdown independent of anything this step read.

The mailbox list also surfaced an eighth recipient that Step One's Exchange admin center read never showed: `Discovery Search Mailbox`, a `DiscoveryMailbox` rather than a `UserMailbox`, present in every Exchange Online tenant by default and carrying the same fixed GUID, `{D919BA05-46A6-415f-80AD-7E09334BB852}`, in every tenant rather than one specific to this one. `Get-EXOMailbox -ResultSize Unlimited` returns it; the Exchange admin center's Mailboxes view apparently filters it out by default, since Step One's read of that view reported exactly seven with no mention of an eighth. That is an instrument difference worth recording rather than a contradiction: the two surfaces are not counting the same underlying population, and it is a small instance of the pattern the rest of this lab keeps testing for.

A live re-read of the Exchange admin center's Mailboxes view on 2026-09-16 confirmed the same seven-item population from the console side:

<p align="center">
  <img src="../../images/cloud-and-hybrid-identity/04-microsoft-365-administration-workflows/04-exchange-admin-center-mailboxes-step-two-reread.jpg" alt="04-exchange-admin-center-mailboxes-step-two-reread" width="700">
</p>

<p align="center">
  <em>Exchange admin center, Recipients, Mailboxes, re-read for Step Two: 7 items, the same seven UserMailbox recipients Step One recorded, none of them Mary Johnson, Test Sync, or the Emergency Access Account.</em>
</p>

**The unlicensed case.** Mary Johnson (`mjohnson`) was used rather than the Emergency Access Account, whose UPN is redacted throughout this track and which Lab 05 depends on, and rather than Test Sync, for no reason beyond `mjohnson` being the more legible name in output. `Get-EXORecipient` found nothing for her at all:

```powershell
Get-EXORecipient -Identity mjohnson@brindeck.com -ErrorAction SilentlyContinue
if (-not $?) { "No recipient object found for mjohnson@brindeck.com" }
```

```text
No recipient object found for mjohnson@brindeck.com
```

Microsoft Graph confirmed why: she is a live, enabled, synchronized directory object with no Exchange attributes of any kind, not even a stub.

```powershell
Get-MgUser -UserId mjohnson@brindeck.com -Property Mail,ProxyAddresses,UserPrincipalName,AccountEnabled,OnPremisesSyncEnabled | Format-List
```

```text
AccountEnabled        : True
Mail                  :
OnPremisesSyncEnabled : True
ProxyAddresses        : {}
UserPrincipalName     : mjohnson@brindeck.com
```

(The command returned the full Microsoft Graph user object, with dozens of properties outside the requested five coming back blank or as type placeholders; only the five requested fields are quoted here, since the rest carried nothing this step needed.)

A message was sent from `testuser01@brindeck.com` through Outlook on the web at 5:18 PM Eastern (9:18 PM UTC) on 2026-09-16, subject "Lab 04 Step Two - unlicensed account test," to `mjohnson@brindeck.com`. Per Step One's mail-flow DNS finding there is no inbound mail flow for `brindeck.com` from outside the tenant, so the send originated from an internal mailbox rather than an external one. A non-delivery report arrived in testuser01's inbox within minutes:

<p align="center">
  <img src="../../images/cloud-and-hybrid-identity/04-microsoft-365-administration-workflows/05-mjohnson-ndr-summary.jpg" alt="05-mjohnson-ndr-summary" width="700">
</p>

<p align="center">
  <em>Outlook on the web, testuser01's inbox: the non-delivery report for the message to mjohnson@brindeck.com, "mjohnson wasn't found at brindeck.com."</em>
</p>

<p align="center">
  <img src="../../images/cloud-and-hybrid-identity/04-microsoft-365-administration-workflows/06-mjohnson-ndr-technical-details.jpg" alt="06-mjohnson-ndr-technical-details" width="700">
</p>

<p align="center">
  <em>The same NDR's More Info for Email Admins section: status code 550 5.1.10, the RESOLVER.ADR.RecipientNotFound error text, and the two-hop Message Hops table.</em>
</p>

The NDR's technical detail, quoted verbatim:

```text
Status code: 550 5.1.10

Original Message Details
Created Date:       9/16/2026 9:18:00 PM
Sender Address:     testuser01@brindeck.com
Recipient Address:  mjohnson@brindeck.com
Subject:            Lab 04 Step Two - unlicensed account test

Error Details
Error:               550 5.1.10 RESOLVER.ADR.RecipientNotFound; Recipient mjohnson@brindeck.com not found by SMTP address lookup
Message rejected by: SA1PR18MB4661.namprd18.prod.outlook.com

Notification Details
Sent by: SA1PR18MB4661.namprd18.prod.outlook.com

Message Hops
HOP  TIME (UTC)           FROM                                     TO                                       WITH                                                                                    RELAY TIME
1    9/16/2026 9:18:00 PM  PH0PR18MB3813.namprd18.prod.outlook.com  PH0PR18MB3813.namprd18.prod.outlook.com  mapi                                                                                    *
2    9/16/2026 9:18:15 PM  PH0PR18MB3813.namprd18.prod.outlook.com  SA1PR18MB4661.namprd18.prod.outlook.com  Microsoft SMTP Server (version=TLS1_2, cipher=TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384)      15 sec
```

The attempt was traced at the instrument this lab is built around, rather than taking the NDR's word alone:

```powershell
Get-MessageTraceV2 -SenderAddress testuser01@brindeck.com -RecipientAddress mjohnson@brindeck.com -StartDate (Get-Date).AddHours(-1) -EndDate (Get-Date) | Format-List
```

```text
Message Trace ID  : e68809dc-1d5d-4e34-f981-08df1437fc83
Message ID        : <PH0PR18MB38133B0318991519E2059AA4ADB92@PH0PR18MB3813.namprd18.prod.outlook.com>
Received          : 9/16/2026 9:18:00 PM
Sender Address    : testuser01@brindeck.com
Recipient Address : mjohnson@brindeck.com
From IP           : [redacted, originating client address]
To IP             :
Subject           : Lab 04 Step Two - unlicensed account test
Status            : Failed
Size              : 18129
```

`Status: Failed` rather than `Expanded` or `Delivered`, consistent with the NDR. The `From IP` field is redacted under this track's identifier policy on the same grounds Step One recorded it: it is the public address of the lab's own connection, not a property of the tenant.

Whether this is Directory-Based Edge Blocking, which Microsoft's own accepted-domains documentation credits `Authoritative` domains with enabling, was checked against that documentation rather than assumed from the accepted-domain type alone. Microsoft states DBEB's own rejection plainly: if an address doesn't exist, the service blocks the message before filtering even occurs, and returns an NDR reading `550 5.4.1 Recipient address rejected: Access denied`. That is a different status code and a different message than what this test produced. `550 5.1.10 RESOLVER.ADR.RecipientNotFound` is documented separately by Microsoft as a categorizer-level failure, "recipient not found by SMTP address lookup," and it appears in scenarios that have nothing to do with DBEB or an accepted domain's type: a just-restored Microsoft 365 group still replicating, or a cloud-only object with no on-premises counterpart in a hybrid deployment, among others. That fits what the Graph read above already showed: `mjohnson` has an empty `ProxyAddresses` collection and a blank `Mail` attribute, so there is no recipient object anywhere for the address to resolve against, and the failure happened at Exchange Online's internal recipient resolution rather than at the service's network perimeter. This message also never left the tenant to reach that perimeter in the first place, since it was sent mailbox to mailbox inside `brindeck.com`, and DBEB specifically polices inbound SMTP arriving from outside the service. `brindeck.com` remaining `Authoritative` is not in question here; what this corrects is crediting DBEB specifically with an NDR whose own status code and message text belong to a different, more general mechanism.

**Closing the primary-address finding Step One handed forward.** The full `EmailAddresses` collection was read on all seven mailboxes together with the storage quotas each one carries:

```powershell
$mailboxes = 'Adam@brindeck.onmicrosoft.com','akim@brindeck.com','admin@brindeck.com','cloudonly-demo01@brindeck.com','jdoe@brindeck.com','jsmith@brindeck.com','testuser01@brindeck.com'

foreach ($mbx in $mailboxes) {
    Get-EXOMailbox -Identity $mbx -Properties EmailAddresses,ProhibitSendQuota,ProhibitSendReceiveQuota,IssueWarningQuota,RecipientTypeDetails |
        Select-Object DisplayName,UserPrincipalName,PrimarySmtpAddress,RecipientTypeDetails,ProhibitSendQuota,ProhibitSendReceiveQuota,IssueWarningQuota,@{N='EmailAddresses';E={$_.EmailAddresses -join '; '}} |
        Format-List
}
```

```text
DisplayName              : Adam Ramzi
UserPrincipalName        : Adam@brindeck.onmicrosoft.com
PrimarySmtpAddress       : Adam@brindeck.onmicrosoft.com
RecipientTypeDetails     : UserMailbox
ProhibitSendQuota        : 99 GB (106,300,440,576 bytes)
ProhibitSendReceiveQuota : 100 GB (107,374,182,400 bytes)
IssueWarningQuota        : 98 GB (105,226,698,752 bytes)
EmailAddresses           : SIP:adam@brindeck.onmicrosoft.com; SMTP:Adam@brindeck.onmicrosoft.com

DisplayName              : Alex Kim
UserPrincipalName        : akim@brindeck.com
PrimarySmtpAddress       : akim@brindeck.onmicrosoft.com
RecipientTypeDetails     : UserMailbox
ProhibitSendQuota        : 99 GB (106,300,440,576 bytes)
ProhibitSendReceiveQuota : 100 GB (107,374,182,400 bytes)
IssueWarningQuota        : 98 GB (105,226,698,752 bytes)
EmailAddresses           : SIP:akim@brindeck.com; SMTP:akim@brindeck.onmicrosoft.com; smtp:akim@brindeck.com

DisplayName              : Cloud Administrator
UserPrincipalName        : admin@brindeck.com
PrimarySmtpAddress       : admin@brindeck.com
RecipientTypeDetails     : UserMailbox
ProhibitSendQuota        : 99 GB (106,300,440,576 bytes)
ProhibitSendReceiveQuota : 100 GB (107,374,182,400 bytes)
IssueWarningQuota        : 98 GB (105,226,698,752 bytes)
EmailAddresses           : SIP:admin@brindeck.com; SMTP:admin@brindeck.com

DisplayName              : Cloud-Only Demo Account (Lab 03 fixture)
UserPrincipalName        : cloudonly-demo01@brindeck.com
PrimarySmtpAddress       : cloudonly-demo01@brindeck.com
RecipientTypeDetails     : UserMailbox
ProhibitSendQuota        : 99 GB (106,300,440,576 bytes)
ProhibitSendReceiveQuota : 100 GB (107,374,182,400 bytes)
IssueWarningQuota        : 98 GB (105,226,698,752 bytes)
EmailAddresses           : SIP:cloudonly-demo01@brindeck.com; SMTP:cloudonly-demo01@brindeck.com

DisplayName              : Jane Doe
UserPrincipalName        : jdoe@brindeck.com
PrimarySmtpAddress       : jdoe@brindeck.com
RecipientTypeDetails     : UserMailbox
ProhibitSendQuota        : 99 GB (106,300,440,576 bytes)
ProhibitSendReceiveQuota : 100 GB (107,374,182,400 bytes)
IssueWarningQuota        : 98 GB (105,226,698,752 bytes)
EmailAddresses           : SIP:jdoe@brindeck.com; smtp:jdoe@brindeck.onmicrosoft.com; SMTP:jdoe@brindeck.com

DisplayName              : John Smith
UserPrincipalName        : jsmith@brindeck.com
PrimarySmtpAddress       : jsmith@brindeck.onmicrosoft.com
RecipientTypeDetails     : UserMailbox
ProhibitSendQuota        : 99 GB (106,300,440,576 bytes)
ProhibitSendReceiveQuota : 100 GB (107,374,182,400 bytes)
IssueWarningQuota        : 98 GB (105,226,698,752 bytes)
EmailAddresses           : SIP:jsmith@brindeck.com; SMTP:jsmith@brindeck.onmicrosoft.com; smtp:jsmith@brindeck.com

DisplayName              : testuser01
UserPrincipalName        : testuser01@brindeck.com
PrimarySmtpAddress       : testuser01@brindeck.com
RecipientTypeDetails     : UserMailbox
ProhibitSendQuota        : 99 GB (106,300,440,576 bytes)
ProhibitSendReceiveQuota : 100 GB (107,374,182,400 bytes)
IssueWarningQuota        : 98 GB (105,226,698,752 bytes)
EmailAddresses           : SIP:testuser01@brindeck.com; smtp:testuser01@brindeck.onmicrosoft.com; SMTP:testuser01@brindeck.com; [one additional SPO: entry carrying testuser01's own directory object ID, dropped here under this track's identifier policy]
```

The stamp shows something more specific than Step One's primary-address-only read could: all four synchronized mailboxes carry both `brindeck.com` and `brindeck.onmicrosoft.com` addresses, not one or the other. Alex Kim and John Smith each hold `brindeck.onmicrosoft.com` as primary (uppercase `SMTP:`) and `brindeck.com` as secondary (lowercase `smtp:`); Jane Doe and testuser01 hold the reverse. Adam Ramzi, Cloud Administrator, and the Cloud-Only Demo Account each carry a single address matching their own domain, which is expected and outside the mismatch.

On-premises, `proxyAddresses` was read on the four synchronized accounts with mailboxes:

```powershell
Get-ADUser -Filter "SamAccountName -eq 'akim' -or SamAccountName -eq 'jdoe' -or SamAccountName -eq 'jsmith' -or SamAccountName -eq 'testuser01'" -Properties ProxyAddresses,UserPrincipalName |
    Select-Object SamAccountName,UserPrincipalName,@{N='ProxyAddresses';E={$_.ProxyAddresses -join '; '}} |
    Format-List
```

```text
SamAccountName    : akim
UserPrincipalName : akim@brindeck.com
ProxyAddresses    :

SamAccountName    : jdoe
UserPrincipalName : jdoe@brindeck.com
ProxyAddresses    :

SamAccountName    : jsmith
UserPrincipalName : jsmith@brindeck.com
ProxyAddresses    :

SamAccountName    : testuser01
UserPrincipalName : testuser01@brindeck.com
ProxyAddresses    :
```

`ProxyAddresses` is blank on all four, on-premises, with no exception. This domain has never populated Exchange mail attributes in Active Directory, consistent with there being no on-premises Exchange server anywhere in this environment. That eliminates synchronization more thoroughly than Step One's version of the finding: it is not merely that synchronization source fails to distinguish the two pairs, it is that there is nothing on-premises for the cloud stamp to have inherited or diverged from at all. Whatever produced the primary/secondary split happened entirely inside Exchange Online at the moment each mailbox was created.

That made `WhenMailboxCreated` the property that could actually test the hypothesis, that the primary was set before `brindeck.com` was verified on 2026-08-23 and never reapplied when the UPN changed:

```powershell
foreach ($mbx in $mailboxes) {
    Get-EXOMailbox -Identity $mbx -Properties WhenMailboxCreated | Select-Object DisplayName,WhenMailboxCreated
}
```

```text
DisplayName                              WhenMailboxCreated
-----------                              ------------------
Adam Ramzi                               8/19/2026 8:41:36 AM
Alex Kim                                 9/6/2026 1:54:44 PM
Cloud Administrator                      9/6/2026 1:54:41 PM
Cloud-Only Demo Account (Lab 03 fixture) 9/6/2026 1:54:41 PM
Jane Doe                                 9/6/2026 1:54:41 PM
John Smith                               9/7/2026 3:04:05 PM
testuser01                               9/6/2026 1:50:15 PM
```

The hypothesis does not survive this reading, and the result is recorded as a disproof rather than reshaped into a different confirmation. Every mailbox provisioned after the tenant's original signup was created between 9/6 and 9/7/2026, two weeks after `brindeck.com` was verified on 2026-08-23. A pre-verification stamp is not available as an explanation for any of them, including the two that ended up on the wrong primary.

No substitute timing pattern explains the split either. Cloud Administrator, the Cloud-Only Demo Account, and Jane Doe were all created in the same second, 9/6/2026 1:54:41 PM, evidently one batch operation, and all three landed on the correct `brindeck.com` primary. Alex Kim was created three seconds later, 1:54:44 PM, apparently the same operation continuing, and landed on the wrong one. John Smith, whose license Lab 03 recorded as sourced through `Company Announcements` membership rather than direct assignment, was created over a day later than the rest, 9/7/2026 3:04:05 PM, and also landed on the wrong one; that distinguishes his provisioning path from the other five, but it does not reach back to explain Alex Kim, who was directly licensed in the same near-instantaneous batch as Jane Doe. Adam Ramzi's mailbox, created 8/19/2026 before the tenant's own domain was verified, is the one case where a pre-verification creation date is real, and Step One already set his address aside as evidence of nothing, since he is the original signup account on the initial domain by construction rather than an account this finding is about.

This is recorded as an open, unresolved finding rather than forced into an explanation the timestamps do not support. What is known: the split is a cloud-side artifact of mailbox provisioning rather than anything synchronized, it does not correlate with the domain verification date, and it does not correlate with batch membership either, since one directly-licensed account created in the same batch second as two correctly-stamped ones still came out wrong.

**Mailbox properties.** The quotas above are identical across all seven mailboxes regardless of recipient type or provisioning date: `ProhibitSendQuota` 99 GB, `ProhibitSendReceiveQuota` 100 GB, `IssueWarningQuota` 98 GB, all read directly from each mailbox rather than cited from a service description.

The double-the-expected figure resolves against Step One's own service plan enumeration rather than standing as an anomaly, which is the first time in this lab that listing the 62 names instead of counting them has paid for itself. Microsoft's Exchange Online limits article gives two different answers depending on which row is read. Standalone Exchange Online Plan 1 is 50 GB, which is the figure the plan is usually quoted at and the one that makes 100 GB look wrong. The Microsoft 365 Business Basic, Business Standard, and Business Premium columns are all 100 GB, and its capacity alerts table gives those same SKUs a warning threshold of 98 GB, prohibit send at 99 GB, and prohibit send and receive at 100 GB. That triple matches what these mailboxes carry exactly, to the gigabyte, on all three values. The tenant is not diverging from the documentation; it is matching a row of it that the headline Plan 1 figure obscures.

What supplies the extra 50 GB is named in Step One's enumeration: `EXCHANGE_STORAGE_50GB`, which the Microsoft 365 admin center's Apps list renders as Exchange Online Storage (50GB Additional). Fifty gigabytes of Exchange Online Plan 1 plus that additional fifty is the hundred these mailboxes report. So the quota is a property of what the SKU bundles rather than of the Plan 1 service plan alone, and the service plan that supplies it was sitting in a list this lab captured one step earlier.

Adam Ramzi's mailbox carrying the identical figures while holding Business Basic rather than Business Premium is consistent with that reading rather than against it, since the limits article gives Business Basic the same 100 GB. That was then closed from the tenant instead of from documentation, while the subscription still existed to read. The Business Basic (no Teams) SKU's own service plans were enumerated on 2026-09-16, six days before it lapses, and the names are recorded here rather than the count for the same reason Step One recorded Business Premium's:

```text
ServicePlanName                   ProvisioningStatus
---------------                   ------------------
Bing_Chat_Enterprise              Success
BPOS_S_TODO_1                     Success
CDS_O365_P1                       Success
DYN365_CDS_O365_P1                Success
EXCHANGE_S_STANDARD               Success
EXCHANGE_STORAGE_50GB             Success
FLOW_O365_P1                      Success
FORMS_PLAN_E1                     Success
GRAPH_CONNECTORS_SEARCH_INDEX     Success
INSIGHTS_BY_MYANALYTICS           Success
INTUNE_O365                       PendingActivation
KAIZALA_O365_P2                   Success
M365_LIGHTHOUSE_CUSTOMER_PLAN1    Success
MCOSTANDARD                       Success
MDOLITE_ENTERPRISE                Success
MESH_AVATARS_ADDITIONAL_FOR_TEAMS Success
MESH_AVATARS_FOR_TEAMS            Success
MESH_IMMERSIVE_FOR_TEAMS          Success
MICROSOFT_MYANALYTICS_FULL        Success
MICROSOFT_SEARCH                  Success
MICROSOFTBOOKINGS                 Success
MYANALYTICS_P2                    Success
Nucleus                           Success
OFFICEMOBILE_SUBSCRIPTION         Success
PEOPLE_SKILLS_FOUNDATION          Success
PLACES_CORE                       Success
POWER_VIRTUAL_AGENTS_O365_P1      Success
POWERAPPS_O365_P1                 Success
PROJECT_O365_P1                   Success
PROJECTWORKMANAGEMENT             Success
RMS_S_BASIC                       Success
SHAREPOINTSTANDARD                Success
SHAREPOINTWAC                     Success
STREAM_O365_SMB                   Success
SWAY                              Success
VIVA_LEARNING_SEEDED              Success
VIVAENGAGE_CORE                   Success
WHITEBOARD_PLAN1                  Success
YAMMER_ENTERPRISE                 Success
```

Thirty-nine service plans against Business Premium's 62, and `EXCHANGE_STORAGE_50GB` is among them, provisioned and successful. The quota explanation is now confirmed from this tenant rather than inferred from a documentation table: both SKUs in this tenant carry Exchange Online Plan 1 plus the additional fifty gigabytes, which is why a Business Basic mailbox and a Business Premium mailbox report the same 100 GB.

**That same read produces counter-evidence against something Step One said, and it is recorded here rather than corrected there.** Step One offered a probable explanation for why `EXCHANGE_S_FOUNDATION` is the one Business Premium service plan with no entry in the admin center's Apps list: that it is the underlying Exchange entitlement every Exchange-bearing SKU carries rather than a capability an administrator grants or revokes. Step One marked that as probable rather than established, which was the right call, because this list does not support it. Business Basic bears Exchange, holding `EXCHANGE_S_STANDARD` and provisioning real mailboxes, and it does not carry `EXCHANGE_S_FOUNDATION` at all. Whatever that plan is, it is not something every Exchange-bearing SKU includes, at least not in this tenant. The observation Step One's reconciliation actually rests on is unaffected, since that was a count of Business Premium's own plans against its own Apps list and stands on its own evidence; what falls is only the reason offered for it, which is now open again. Step One's text is left as written rather than revised, since the hedge it carried is exactly what a later reading is supposed to be able to land on.

Two smaller things fall out of the comparison. `INTUNE_O365` reads `PendingActivation` on both SKUs, the single exception on each, which makes it a property of that service plan or of this tenant rather than a Business Premium quirk. And where the two SKUs carry the same capability they carry different tiers of it, visible in the names alone: Business Basic holds `CDS_O365_P1`, `PROJECT_O365_P1`, `POWER_VIRTUAL_AGENTS_O365_P1`, `RMS_S_BASIC`, and `STREAM_O365_SMB` where Business Premium holds the `P3`, `RMS_S_ENTERPRISE`, and `STREAM_O365_E1` variants of the same things.

Primary SMTP address is derived from whichever accepted domain, `brindeck.com` or `brindeck.onmicrosoft.com`, was in effect when Exchange Online first created each mailbox, per the finding above, rather than from the object's UPN or its synchronization source. Recipient type is `UserMailbox` on all seven; nothing in this population is a shared, resource, or equipment mailbox yet, which is Step Four's and Step Seven's work.

**Adam Ramzi's pre-lapse baseline, for Step Six.** Adam Ramzi holds the tenant's single consumed Business Basic seat, his only license, carrying the Exchange Online Plan 1 behind his mailbox. His mailbox's state was read on 2026-09-16, six days before the 2026-09-22 lapse:

```powershell
Get-EXOMailboxStatistics -Identity Adam@brindeck.onmicrosoft.com | Select-Object DisplayName,ItemCount,TotalItemSize,TotalDeletedItemSize,LastLogonTime | Format-List
```

```text
DisplayName          : Adam Ramzi
ItemCount            : 36
TotalItemSize        : 7.536 MB (7,901,637 bytes)
TotalDeletedItemSize : 0 B (0 bytes)
LastLogonTime        :
```

Thirty-six items and 7.536 MB, entirely default provisioning content rather than anything this lab or an earlier one put there deliberately; Step One's own throwaway test message went to Jane Doe, not to this mailbox. `LastLogonTime` is blank, meaning nobody has ever opened this mailbox interactively through Outlook or Outlook on the web, consistent with the account existing for its Global Administrator role rather than for anyone reading mail through it. Recipient type is `UserMailbox` and the quotas match the uniform figures recorded above, `ProhibitSendReceiveQuota` 100 GB among them. This reading is the "before" half Step Six needs to score its prediction that the mailbox survives the license loss into Exchange's own retention; it has no value on its own until Step Six's "after" reading exists to compare it against.

### Step Three: Built and catalogued the mail-enabled group types Lab 03 handed forward

The four on-premises groups Lab 02 and Lab 03 described as synchronized from `OU=Groups` were read fresh on 2026-09-16 rather than carried forward from either lab's prose, since this step needed to know their category and scope before picking one to test against. The step was performed on the evening of 2026-09-16, America/New_York time. Timestamps in the Microsoft Graph, Exchange Online PowerShell, and message trace output below are UTC, which is why the later ones read 2026-09-17:

```powershell
Get-ADGroup -Filter * -Properties GroupCategory,GroupScope,mail,proxyAddresses,Description |
    Where-Object { $_.DistinguishedName -like "*OU=Groups*" } |
    Select-Object Name,GroupCategory,GroupScope,mail,Description |
    Format-Table -AutoSize
```

```text
Name                    GroupCategory GroupScope mail Description
----                    ------------- ---------- ---- -----------
IT-Admins               Security      Global
Domain-Users-Standard   Security      Global
Lab-Workstations        Security      Global
Linux-Admins            Security      Global          Authorized administrators of Linux infrastructure systems
```

All four are Global-scope security groups carrying no `mail` attribute. The tenant's mail-enabled group population was re-read in the same sitting, before this step added anything to it:

```powershell
Get-EXORecipient -RecipientTypeDetails MailUniversalDistributionGroup,MailUniversalSecurityGroup,GroupMailbox -ResultSize Unlimited |
    Select-Object DisplayName,PrimarySmtpAddress,RecipientTypeDetails |
    Format-Table -AutoSize
```

```text
DisplayName            PrimarySmtpAddress                   RecipientTypeDetails
-----------            ------------------                   --------------------
All Company            allcompany@brindeck.onmicrosoft.com  GroupMailbox
Company Announcements  CompanyAnnouncements@brindeck.com    GroupMailbox
```

No drift from Step One or Step Two: still exactly the two Microsoft 365 groups, and none of the four on-premises groups appear as a recipient of any kind.

**What happens when an attempt is made to manage a synchronized group's mail properties in the cloud.** `IT-Admins` was used for the test, chosen over the other three for no reason beyond its name not colliding with `IT-Department`, Lab 03's cloud-only dynamic membership group. Microsoft Graph confirmed the object exists as an ordinary, unmailed, synchronized security group:

```powershell
$groupId = (Get-MgGroup -Filter "displayName eq 'IT-Admins'").Id
Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/groups/$groupId`?`$select=id,displayName,mail,mailEnabled,securityEnabled,groupTypes,onPremisesSyncEnabled,onPremisesSamAccountName" | Format-List
```

```text
groupTypes               : {}
displayName              : IT-Admins
onPremisesSyncEnabled    : True
mail                     :
mailEnabled              : False
securityEnabled          : True
id                       : 6d494357-[remainder redacted]
onPremisesSamAccountName : IT-Admins
```

(`Get-MgGroup -Property` does not reach the request the way it does on a live user read by ID, an instrument note this track already carries, so the read above went through `Invoke-MgGraphRequest` with an explicit `$select` instead.)

`Get-EXORecipient` found no recipient object for `IT-Admins` at all, consistent with the baseline above:

```powershell
Get-EXORecipient -Identity "IT-Admins" -ErrorAction SilentlyContinue
if (-not $?) { "No recipient object found for IT-Admins" }
```

```text
No recipient object found for IT-Admins
```

The first attempt reached for `Enable-DistributionGroup`, the on-premises Exchange Management Shell cmdlet for mail-enabling an existing security group:

```powershell
Enable-DistributionGroup -Identity "IT-Admins"
```

```text
Enable-DistributionGroup : The term 'Enable-DistributionGroup' is not recognized as the name of a cmdlet, function,
script file, or operable program. Check the spelling of the name, or if a path was included, verify that the path
is correct and try again.
At line:1 char:1
+ Enable-DistributionGroup -Identity "IT-Admins"
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : ObjectNotFound: (Enable-DistributionGroup:String) [], CommandNotFoundException
    + FullyQualifiedErrorId : CommandNotFoundException
```

That cmdlet belongs to on-premises Exchange Server, and Exchange Online PowerShell has no equivalent: nothing in the `ExchangeOnlineManagement` module mail-enables an existing group. Microsoft's documentation creates a mail-enabled security group as a new object, with `New-DistributionGroup -Type Security` or the Exchange admin center wizard, which is how `IT-Support` is built below. The error is therefore a small finding in its own right rather than a wrong-module slip. The write was then attempted one layer down, directly against Microsoft Graph, setting `mailNickname` on the same group object:

```powershell
$body = @{ mailNickname = "it-admins-test" } | ConvertTo-Json
Invoke-MgGraphRequest -Method PATCH -Uri "https://graph.microsoft.com/v1.0/groups/$groupId" -Body $body -ContentType "application/json"
```

```text
Invoke-MgGraphRequest : PATCH https://graph.microsoft.com/v1.0/groups/6d494357-[remainder redacted]
HTTP/1.1 400 Bad Request
Transfer-Encoding: chunked
Vary: Accept-Encoding
Strict-Transport-Security: max-age=31536000
request-id: c3387ee5-5caf-43d1-ac08-7d0d5abde980
client-request-id: 91b712df-f601-4f1a-acb0-1f7a17fea8ee
x-ms-ags-diagnostic: {"ServerInfo":{"DataCenter":"East US","Slice":"E","Ring":"5","ScaleUnit":"010","RoleInstance":"MN1PEPF0006E495"}}
x-ms-resource-unit: 1
Cache-Control: no-cache
Date: Wed, 16 Sep 2026 23:21:19 GMT
Content-Type: application/json
{"error":{"code":"Request_BadRequest","message":"Unable to update the specified properties for on-premises mastered
Directory Sync objects or objects currently undergoing migration.","innerError":{"date":"2026-09-16T23:21:20","request-id":"c3387ee5-5caf-43d1-ac08-7d0d5abde980","client-request-id":"91b712df-f601-4f1a-acb0-1f7a17fea8ee"}}}
At line:1 char:1
+ Invoke-MgGraphRequest -Method PATCH -Uri "https://graph.microsoft.com ...
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : InvalidOperation: (Method: PATCH, ...ication/json
}:HttpRequestMessage) [Invoke-MgGraphRequest], HttpResponseException
    + FullyQualifiedErrorId : InvokeGraphHttpResponseException,Microsoft.Graph.PowerShell.Authentication.Cmdlets.InvokeMgGraphRequest
```

This is the same refusal Lab 03 recorded on the user side of the boundary. Lab 03's Step Eleven attempted `Update-MgUser -JobTitle` on a synchronized user and received this message word for word, on a field that was locked while user principal name and account-enabled state remained writable. The message names the class of on-premises-mastered objects rather than the field attempted, and it did so on users too, where some fields were nonetheless open, so the group result is consistent with the same per-field lock rather than evidence of a broader one. Whether a synchronized group carries a comparable narrow exception on a field not tried here, or has none at all, is not settled by one attempt, and it is left as an open question rather than resolved by inference.

**Building the distribution list.** `Help-Desk` was created through the Exchange admin center rather than through PowerShell, since which console can create each group type is itself part of what this step catalogues: Recipients, Groups, Add a group. The wizard's own Choose a group type screen names the three mail-enabled types in the product's own words rather than this document's: Microsoft 365 ("Allows teams to collaborate by giving them a group email and a shared workspace for conversations, files, and calendars"), Distribution ("Creates an email address for a group of people"), and Mail-enabled security ("Sends messages to all members of the group and gives access to resources like OneDrive, SharePoint and admin roles"), alongside Dynamic distribution, whose membership list the same screen states is recalculated every 24 hours from a set of filters and conditions rather than resolved live.

Distribution was selected. The wizard proceeded through Basics (name `Help-Desk`, description "Distribution list for help desk and support correspondence."), Owners (`Cloud Administrator`, the same account this lab has used throughout), Members (`testuser01`, `John Smith`, and `Jane Doe`, three of the seven mailboxes Step Two catalogued, chosen to keep the group inside accounts this lab has already characterized rather than involving Adam Ramzi, reserved for Step Six's observation, or `cloudonly-demo01`, which has to stay at zero group memberships for Lab 05 to inherit it clean), and Settings, left at its defaults rather than configured, specifically to observe what the product ships rather than what an administrator would choose: email address `help-desk@brindeck.com`, "Allow people outside of my organization to send email to this Distribution group" left unchecked, and both Joining the group and Leaving the group left on Open. That unchecked default is the setting Security Considerations already expected to find. Microsoft's documented default for new distribution groups is that all senders must be authenticated, and the checkbox's own unchecked state confirms that as this tenant's shipped behavior rather than a citation.

<p align="center">
  <img src="../../images/cloud-and-hybrid-identity/04-microsoft-365-administration-workflows/07-help-desk-review-and-finish.jpg" alt="07-help-desk-review-and-finish" width="700">
</p>

<p align="center">
  <em>Exchange admin center, Add a group, Review and finish: group type, name, description, owner, members, and settings for Help-Desk, all in their final state before creation.</em>
</p>

The group was created. The portal's own confirmation stated it can take up to an hour for `Help-Desk` to appear in the Groups list view, an interface-level propagation delay on the Exchange admin center's own list rather than anything about the recipient object itself.

<p align="center">
  <img src="../../images/cloud-and-hybrid-identity/04-microsoft-365-administration-workflows/08-help-desk-distribution-list-created.jpg" alt="08-help-desk-distribution-list-created" width="700">
</p>

<p align="center">
  <em>Exchange admin center: Help-Desk is created, with the portal's own note that the Groups list view can take up to an hour to reflect it.</em>
</p>

`Get-DistributionGroup` and `Get-DistributionGroupMember`, run immediately rather than waiting out that delay, both returned the object correctly:

```powershell
Get-DistributionGroup -Identity "Help-Desk" | Select-Object DisplayName,PrimarySmtpAddress,GroupType,RecipientTypeDetails | Format-List
Get-DistributionGroupMember -Identity "Help-Desk" | Select-Object DisplayName,PrimarySmtpAddress
```

```text
DisplayName          : Help-Desk
PrimarySmtpAddress   : help-desk@brindeck.com
GroupType            : Universal
RecipientTypeDetails : MailUniversalDistributionGroup

DisplayName PrimarySmtpAddress
----------- ------------------
Jane Doe    jdoe@brindeck.com
John Smith  jsmith@brindeck.onmicrosoft.com
testuser01  testuser01@brindeck.com
```

PowerShell resolved the group correctly while the portal's own Groups list view had not yet caught up, the same instrument-lag shape Step Two already found between the Exchange admin center's Mailboxes view and `Get-EXOMailbox` over the Discovery Search Mailbox, on a different pair of surfaces this time. Each member's primary address matches Step Two's own findings exactly: Jane Doe and testuser01 on `brindeck.com`, John Smith on `brindeck.onmicrosoft.com`, the same primary-address split Step Two characterized.

**Building the mail-enabled security group.** `IT-Support` was created the same way, through Recipients, Groups, Add a group, choosing Mail-enabled security this time. That type's own Settings screen names its distinguishing capability directly, in the product's own words rather than this document's: "Has all the functionality of a distribution list and additionally can be used to control access to OneDrive and SharePoint." No comparable line appears anywhere in the distribution list's own wizard, which only ever describes itself as creating an email address for a group of people.

The Settings screen also surfaced a real difference in how the two types handle self-service membership, worth recording alongside the permissions difference. The distribution list's Settings screen carried two separate three-way controls, Joining the group and Leaving the group, each a choice of Open, Closed, or Owner approval, both defaulting to Open. The mail-enabled security group's Settings screen carries neither. In their place is a single checkbox, "Require owner approval to join the group," unchecked by default, with no equivalent control over leaving shown anywhere in the wizard. A mail-enabled security group's membership model is narrower in the wizard than a distribution list's, not just differently labeled.

`IT-Support` was given description "Mail-enabled security group for IT support ticket correspondence and shared resource access.", owner `Cloud Administrator`, and members `Alex Kim` and `testuser01`, chosen to keep this group's population distinct from `Help-Desk`'s rather than reusing the same three accounts for both. Settings were left at their shipped defaults for the same reason as before: email address `it-support@brindeck.com`, external senders unchecked, and owner approval to join unchecked.

<p align="center">
  <img src="../../images/cloud-and-hybrid-identity/04-microsoft-365-administration-workflows/09-it-support-review-and-finish.jpg" alt="09-it-support-review-and-finish" width="700">
</p>

<p align="center">
  <em>Exchange admin center, Add a group, Review and finish: group type, name, description, owner, members, and settings for IT-Support, all in their final state before creation.</em>
</p>

The same up-to-an-hour Groups list view delay appeared on creation, already documented once above and not repeated here. `Get-DistributionGroup` and `Get-DistributionGroupMember` confirmed the object immediately, the same instrument-lag shape as `Help-Desk`:

```powershell
Get-DistributionGroup -Identity "IT-Support" | Select-Object DisplayName,PrimarySmtpAddress,GroupType,RecipientTypeDetails | Format-List
Get-DistributionGroupMember -Identity "IT-Support" | Select-Object DisplayName,PrimarySmtpAddress
```

```text
DisplayName          : IT-Support
PrimarySmtpAddress   : it-support@brindeck.com
GroupType            : Universal, SecurityEnabled
RecipientTypeDetails : MailUniversalSecurityGroup

DisplayName PrimarySmtpAddress
----------- ------------------
testuser01  testuser01@brindeck.com
Alex Kim    akim@brindeck.onmicrosoft.com
```

`RecipientTypeDetails` confirms the type distinction that matters: `MailUniversalSecurityGroup` rather than `Help-Desk`'s `MailUniversalDistributionGroup`, with `GroupType` itself carrying the extra `SecurityEnabled` flag a plain distribution list does not report. Alex Kim's primary address again lands on `brindeck.onmicrosoft.com` rather than `brindeck.com`, the same primary-address split Step Two characterized, appearing here for the third time on the same account.

**Testing what each type accepts as a member.** Rather than take the product's own descriptions at face value, `IT-Admins`, the same on-premises synchronized security group used for the mail-property lock test above, was added as a member of each of the three group types in turn:

```powershell
Add-DistributionGroupMember -Identity "Help-Desk" -Member "IT-Admins"
Add-DistributionGroupMember -Identity "IT-Support" -Member "IT-Admins"
Add-UnifiedGroupLinks -Identity "Company Announcements" -LinkType Members -Links "IT-Admins"
```

The first two returned nothing, which in PowerShell is silent success rather than silent failure, and the third failed outright:

```text
Write-ErrorMessage : ||The user couldn't be found for mailbox Identity:'IT-Admins' isn't a mailbox user..
At C:\Users\labadmin.CORP\AppData\Local\Temp\tmpEXO_0owifaqh.amv\tmpEXO_0owifaqh.amv.psm1:1196 char:13
+             Write-ErrorMessage $ErrorObject
+             ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [Add-UnifiedGroupLinks], MailboxUserNotFoundException
    + FullyQualifiedErrorId : [Server=PH0PR18MB988511,RequestId=c531290d-82d3-abfa-b01e-82ef8112a48c,TimeStamp=Thu, 17 Sep 2026 00:10:15 GMT],Write-ErrorMessage
```

Silent success is not confirmed success, so both distribution list and mail-enabled security group memberships were read back before anything was concluded:

```powershell
Get-DistributionGroupMember -Identity "Help-Desk" | Select-Object DisplayName,PrimarySmtpAddress,RecipientTypeDetails
Get-DistributionGroupMember -Identity "IT-Support" | Select-Object DisplayName,PrimarySmtpAddress,RecipientTypeDetails
```

```text
DisplayName PrimarySmtpAddress               RecipientTypeDetails
----------- ------------------               --------------------
Jane Doe    jdoe@brindeck.com                UserMailbox
testuser01  testuser01@brindeck.com          UserMailbox
John Smith  jsmith@brindeck.onmicrosoft.com  UserMailbox
IT-Admins                                    ExchangeSecurityGroup

DisplayName PrimarySmtpAddress               RecipientTypeDetails
----------- ------------------               --------------------
testuser01  testuser01@brindeck.com          UserMailbox
Alex Kim    akim@brindeck.onmicrosoft.com    UserMailbox
IT-Admins                                    ExchangeSecurityGroup
```

Both confirm it: `IT-Admins` nested into each without complaint, reported as `ExchangeSecurityGroup` rather than `UserMailbox`, a type distinct from every individual member. A Microsoft 365 group refused the same object outright, and its error message frames the rejection as a missing mailbox user rather than as a member-type restriction, which is a less direct explanation than the actual constraint but points at the same thing: a Microsoft 365 group accepts users and nothing else, while a distribution list and a mail-enabled security group both accept a nested group.

**What each type looks like from the Entra admin center.** The track README states that the Entra admin center can list a distribution list or a mail-enabled security group but cannot manage either, which Lab 03 handed forward as a boundary rather than something it tested directly. This step tested it, reading the pages below while `IT-Admins` was still nested in `IT-Support`, before the test nesting was removed.

Entra admin center, Groups, All groups read 11 groups found, reconciling exactly against the tenant's own count: nine before this step per the Architecture section above, plus `Help-Desk` and `IT-Support`. Its Group type column names every object by the same vocabulary this step has been using, drawn directly from the tenant rather than summarized:

| Name | Group type | Membership type | Source |
|---|---|---|---|
| All Company | Microsoft 365 | Assigned | Cloud |
| Company Announcements | Microsoft 365 | Assigned | Cloud |
| Domain-Users-Standard | Security | Assigned | Windows Server AD |
| Finance | Security | Assigned | Cloud |
| Groups-Administrators | Security | Assigned | Cloud |
| Help-Desk | Distribution | Assigned | Cloud |
| IT-Admins | Security | Assigned | Windows Server AD |
| IT-Department | Security | Dynamic | Cloud |
| IT-Support | Mail enabled security | Assigned | Cloud |
| Lab-Workstations | Security | Assigned | Windows Server AD |
| Linux-Admins | Security | Assigned | Windows Server AD |

<p align="center">
  <img src="../../images/cloud-and-hybrid-identity/04-microsoft-365-administration-workflows/10-entra-admin-center-all-groups.jpg" alt="10-entra-admin-center-all-groups" width="700">
</p>

<p align="center">
  <em>Entra admin center, Groups, All groups: 11 groups found, Group type distinguishing Microsoft 365, Security, Distribution, and Mail enabled security.</em>
</p>

`IT-Support`'s own Properties and Members pages both carry the same banner, word for word except for one preposition: "Some groups can't be managed in the Azure portal" on Properties, "Some groups can't be managed in this portal" on Members, each linking to "Learn where to manage these groups." Every field on Properties is greyed and non-interactive: Group name, Group description, Group type ("Mail enabled security", a different rendering of the same label the Exchange admin center wizard spelled with a hyphen), Membership type ("Assigned"), Object Id, and "Microsoft Entra roles can be assigned to the group" reading No. The Members page lists the three members correctly, `IT-Admins` shown as `Type: Group` with no email against the two `Type: User` entries, but its Add members, Bulk operations, and Remove controls sit alongside the same banner.

<p align="center">
  <img src="../../images/cloud-and-hybrid-identity/04-microsoft-365-administration-workflows/11-it-support-entra-admin-center-properties.jpg" alt="11-it-support-entra-admin-center-properties" width="700">
</p>

<p align="center">
  <em>Entra admin center, IT-Support, Properties: the "can't be managed" banner, every field greyed, Object Id masked to its first eight characters.</em>
</p>

<p align="center">
  <img src="../../images/cloud-and-hybrid-identity/04-microsoft-365-administration-workflows/12-it-support-entra-admin-center-members.jpg" alt="12-it-support-entra-admin-center-members" width="700">
</p>

<p align="center">
  <em>Entra admin center, IT-Support, Members: the same banner, IT-Admins listed with Type Group against two Type User entries.</em>
</p>

`Company Announcements`, read the same way rather than assumed to behave differently because it is a Microsoft 365 group, carries no banner on either page. Group name and Group description both show a green checkmark and are editable, and Add members, Bulk operations, and Remove are all active with no accompanying notice.

<p align="center">
  <img src="../../images/cloud-and-hybrid-identity/04-microsoft-365-administration-workflows/13-company-announcements-entra-admin-center-properties.jpg" alt="13-company-announcements-entra-admin-center-properties" width="700">
</p>

<p align="center">
  <em>Entra admin center, Company Announcements, Properties: no banner, Group name and Group description both editable, Object Id masked to its first eight characters.</em>
</p>

<p align="center">
  <img src="../../images/cloud-and-hybrid-identity/04-microsoft-365-administration-workflows/14-company-announcements-entra-admin-center-members.jpg" alt="14-company-announcements-entra-admin-center-members" width="700">
</p>

<p align="center">
  <em>Entra admin center, Company Announcements, Members: no banner, Add members and Remove both active.</em>
</p>

**Removing the test nesting.** Once the Entra admin center reads above were taken, `IT-Admins` was removed from both groups, since it existed only to test acceptance and has no part in this step's finished state:

```powershell
Remove-DistributionGroupMember -Identity "Help-Desk" -Member "IT-Admins" -Confirm:$false
Remove-DistributionGroupMember -Identity "IT-Support" -Member "IT-Admins" -Confirm:$false
```

Removal returns nothing on success, the same silence the additions produced, so both memberships were read back again rather than assumed:

```powershell
Get-DistributionGroupMember -Identity "Help-Desk" | Select-Object DisplayName,PrimarySmtpAddress,RecipientTypeDetails
Get-DistributionGroupMember -Identity "IT-Support" | Select-Object DisplayName,PrimarySmtpAddress,RecipientTypeDetails
```

```text
DisplayName PrimarySmtpAddress              RecipientTypeDetails
----------- ------------------              --------------------
Jane Doe    jdoe@brindeck.com               UserMailbox
testuser01  testuser01@brindeck.com         UserMailbox
John Smith  jsmith@brindeck.onmicrosoft.com UserMailbox

DisplayName PrimarySmtpAddress            RecipientTypeDetails
----------- ------------------            --------------------
testuser01  testuser01@brindeck.com       UserMailbox
Alex Kim    akim@brindeck.onmicrosoft.com UserMailbox
```

`Help-Desk` is back to its three original members and `IT-Support` to its two, every entry a `UserMailbox`, and `IT-Admins` is absent from both.

**The catalogue.** Everything above resolves into the comparison Lab 03 could not make, because it never built two of the three types. Each cell states whether it was observed in this step or taken from the product's own wizard text or Microsoft's documentation:

| | Distribution list | Mail-enabled security group | Microsoft 365 group |
|---|---|---|---|
| Created via | Exchange admin center, Recipients, Groups, Add a group (observed) | The same wizard, different type selection (observed) | Offered as a type in the same wizard (observed); other creation paths not tested in this lab |
| Membership managed via | Exchange admin center at creation and `Add-DistributionGroupMember` (both observed) | Exchange admin center at creation and `Add-DistributionGroupMember` (both observed) | `Add-UnifiedGroupLinks` (observed); Entra admin center Add members and Remove controls active (observed, not exercised) |
| Accepts as members | Users and a nested security group (observed) | Users and a nested security group (observed) | Users; a nested security group rejected by `Add-UnifiedGroupLinks` (observed) |
| Grants permissions beyond mail | No; the wizard describes it only as creating an email address for a group (wizard text) | Yes, access to OneDrive and SharePoint (wizard text, not exercised) | Yes, through the group mailbox and shared workspace it brings with it (wizard text, not exercised) |
| Entra admin center rendering | Listed with type "Distribution" (observed); Properties and Members pages not opened in this step | Listed with type "Mail enabled security"; Properties and Members read-only behind the "can't be managed" banner (observed) | Listed with type "Microsoft 365"; Properties and Members editable, no banner (observed) |
| Message trace delivery status | `Expanded` (Microsoft's documentation); traced against `Help-Desk` in Step Five | `Expanded` for the group, then `Delivered` to each member (observed in this step) | Not traced in this lab |

The distinction this step was planned around holds up: a mail-enabled security group receives mail and, by the product's own description, grants access; a distribution list only receives mail; and a Microsoft 365 group brings its own mailbox and workspace rather than being pointed at existing resources. None of that is what decides whether the Entra admin center can manage a group. Distribution lists and mail-enabled security groups are Exchange Online objects and are managed there, which is what the banner says; a Microsoft 365 group, like the cloud security groups in the same list, is managed in Entra.

**Sending mail through IT-Support.** Per Design Decisions, every mail-enabled object this lab builds has a real message traced through it. Step Five's three planned messages cover an individual mailbox, `Help-Desk`, and a message the rule stops, not `IT-Support`, so its test was run here.

`testuser01`, one of `IT-Support`'s two original members, sent a plain message from Outlook on the web to the group's own address, `it-support@brindeck.com`, subject `Step Three mail routing test`, chosen to stay identifiable in a trace search:

```powershell
Get-MessageTraceV2 -RecipientAddress "it-support@brindeck.com" -StartDate (Get-Date).AddMinutes(-15) -EndDate (Get-Date).AddMinutes(5)
```

```text
Received               Sender Address            Recipient Address        Subject                       Status
--------               --------------            -----------------        -------                       ------
9/17/2026 12:37:35 AM  testuser01@brindeck.com   it-support@brindeck.com  Step Three mail routing test  Expanded
```

The single row reports `Expanded`, the status Design Decisions describes for a message sent to a distribution list: the group resolved into its members rather than delivered to one mailbox. `IT-Support` produces it too, so the transport pipeline expands a mail-enabled security group the same way Microsoft documents it expanding a distribution list. The distribution list side is observed in Step Five.

`Expanded` shows the group was resolved, not that the message reached anyone, so the same message was traced by recipient for both members:

```powershell
Get-MessageTraceV2 -RecipientAddress "testuser01@brindeck.com","akim@brindeck.onmicrosoft.com" -Subject "Step Three mail routing test" -SubjectFilterType "Contains" -StartDate (Get-Date "2026-09-16") -EndDate (Get-Date "2026-09-18")
```

```text
Received               Sender Address           Recipient Address              Subject                       Status
--------               --------------           -----------------              -------                       ------
9/17/2026 12:37:35 AM  testuser01@brindeck.com  akim@brindeck.onmicrosoft.com  Step Three mail routing test  Delivered
9/17/2026 12:37:35 AM  testuser01@brindeck.com  testuser01@brindeck.com        Step Three mail routing test  Delivered
```

Both members have a `Delivered` row carrying the same received time as the `Expanded` row above, so the expansion reached both mailboxes. testuser01 is both the sender and a member, and the group delivered a copy back to its own mailbox rather than skipping it.

**What becomes of Help-Desk and IT-Support.** This is the first step in this lab to create objects, so both dispositions are declared here for Step Nine to reconcile against. Both groups are removed at Step Nine. `Help-Desk` stays until Step Five's trace against it has run; `IT-Support`'s mail-flow test is recorded above, and it has no further work in this lab. Both were left unlicensed throughout, because Lab 03 established that a group carrying a license assignment cannot be deleted. Deleting either removes the group object and its membership records only; the members' mailboxes are unaffected.

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

Read the subscription's state, `Finance`'s group-level assignment, Adam Ramzi's direct assignment, the Microsoft 365 admin center's assigned count, and `Get-MgSubscribedSku`'s consumed units, on the day before the lapse and again on both 9/22 and 9/23. Reading both dates is not belt and braces: Step One found the subscription's own Recurring billing field reading 9/23 against a stated Expiration date of 9/22, so which of the two the commerce system acts on is an open question this step can answer for free. Record what changed and what did not.

Four specific questions this step answers rather than assumes: whether the subscription entered an Expired state rather than disappearing, whether `Finance` still carries the assignment, whether Adam Ramzi's mailbox survives the loss of the only license he holds, and whether the target-versus-seat distinction Lab 03's Part C established still reconciles the two figures the same way. `Finance` is empty, so no user draws Business Basic through it and the group question is about the assignment surviving rather than about anyone's access. Adam Ramzi is the whole of the access question: he holds the subscription's single consumed seat by direct assignment, that assignment is his only license of any kind, and it is what carries the Exchange Online Plan 1 behind one of the tenant's seven mailboxes. Record the mailbox's state alongside the assignment's, since they can diverge.

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

Reconcile the finished state. Record every mail object that persists and every one the lab removed, including confirmation that Step Five's mail flow rule is gone and mail flows normally again, and that Step Seven's litigation hold is released if one was placed. Record the licensing state by assignment target and consumed seat for both SKUs. Re-read the Entra admin center's Licenses blade for one directly licensed account and record its enabled-services count, which Step One's reconciliation of the three service counts predicts at 53 and which is the one figure in that reconciliation still standing as a prediction. Record the state of the four objects Lab 03 left outside the Entra Overview's counts: `nolocation-demo01` and `Testgroup` retained, `duptest01` and `duptest02` purged. Record whether `cloudonly-demo01` is still license-only with no groups and no roles, which is the condition Lab 05 depends on and which nothing in this lab should have touched.

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
- **The three service counts on one SKU.** The 62 service plans, the Microsoft 365 admin center's Apps list, and the Entra admin center's enabled-services figure are reconciled by name rather than by total, with what each one counts stated. The Entra blade is re-read at the close so that no part of the reconciliation rests on inference.
- **Carry-forward.** The three dated items this lab owns are closed rather than passed on with their dates spent: the fully elapsed `AZUREADSSOACC` interval is read, the `Testgroup` and `nolocation-demo01` deletion windows are decided rather than allowed to expire by default, and the expiry discrepancy is stated with the figure this lab planned against.

---

## Troubleshooting and Adjustments

Three commands failed on the first attempt during Step One, none of them a finding about the tenant. `Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force` failed on a PackageManagement/PowerShellGet version clobber ("This module 'PackageManagement' may override the existing commands"); adding `-AllowClobber` resolved it. `Get-MessageTraceV2` was first invoked with its own name accidentally truncated to `V2` by a copy-paste artifact and failed as an unrecognized command; retyped in full, it ran correctly. `Get-ADComputer -Identity AZUREADSSOACC -Properties PasswordLastSet -Server SYNC01` failed because SYNC01 is a domain member rather than a domain controller and does not run Active Directory Web Services; dropping `-Server` and letting the AD module resolve to `corp.home.arpa` normally, exactly as Lab 03 ran it, succeeded.

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
- [Manage mail-enabled security groups in Exchange Online](https://learn.microsoft.com/exchange/recipients-in-exchange-online/manage-mail-enabled-security-groups) - mail-enabled security groups created as new objects with `New-DistributionGroup -Type Security` or the Exchange admin center
- [Manage distribution groups](https://learn.microsoft.com/exchange/recipients/distribution-groups) - that new distribution groups require all senders to be authenticated by default, which blocks external senders until Delivery management is changed
- [Message trace in the Exchange admin center in Exchange Online](https://learn.microsoft.com/exchange/monitoring/trace-an-email-message/message-trace-modern-eac) - delivery status values including `Expanded`, and the permissions required
- [Message Trace FAQ in Exchange Online](https://learn.microsoft.com/exchange/monitoring/trace-an-email-message/message-trace-faq) - 90-day retention, the 10-day query window, `Get-MessageTraceV2`, and a stated five to ten minute appearance latency
- [Monitoring, reporting, and message tracing in Exchange Online](https://learn.microsoft.com/exchange/monitoring/monitoring) - the same latency stated as five to thirty minutes for messages less than seven days old
- [Find and fix email delivery issues as a Microsoft 365 for business admin](https://learn.microsoft.com/troubleshoot/exchange/email-delivery/email-delivery-issues) - the same latency stated as ten minutes to one hour
- [Configure OAuth authentication between Exchange and Exchange Online organizations](https://learn.microsoft.com/exchange/configure-oauth-authentication-between-exchange-and-exchange-online-organizations-exchange-2013-help) - the glossary naming `contoso.mail.onmicrosoft.com` as the hybrid routing domain, and the Microsoft Online Email Routing Address built from a user's UPN prefix and the initial domain suffix
- [Manage accepted domains in Exchange Online](https://learn.microsoft.com/exchange/mail-flow-best-practices/manage-accepted-domains/manage-accepted-domains) - the Authoritative and Internal relay domain types, and Directory-Based Edge Blocking as what Authoritative enables

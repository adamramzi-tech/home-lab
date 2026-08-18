# ADR-018: Retire Cross-Platform Validation as a Standalone Lab

## Status

Accepted

## Date

2026-08-17

---

## Related Decisions

Builds upon:

- [ADR-014: Establish Long-Term Infrastructure Expansion Roadmap](014-establish-long-term-infrastructure-expansion-roadmap.md)
- [ADR-015: Establish Infrastructure Automation and Scripting Track](015-establish-infrastructure-automation-and-scripting-track.md)
- [ADR-016: Run Automation Scripts from a Domain-Joined Client](016-run-automation-scripts-from-domain-joined-client.md)
- [ADR-017: Adopt PowerShell Static Analysis and Unit Testing](017-adopt-powershell-static-analysis-and-unit-testing.md)

Related documentation:

- [Automation and Scripting Track README](../../automation-and-scripting/README.md)
- [01 - User Lifecycle Automation](../../automation-and-scripting/01-user-lifecycle-automation.md)
- [04 - Group Policy Reporting and Audit](../../automation-and-scripting/04-group-policy-reporting-and-audit.md)

---

# Context

ADR-015 scoped the Infrastructure Automation and Scripting track and named cross-platform validation as one of its objectives: "cross-platform validation confirming that AD-side changes produce expected authentication behavior on Linux." It appeared in that ADR's scope, deliverables, and positive consequences, and the track roadmap carried it as a dedicated lab. After ADR-017 inserted the static analysis and testing work as Lab 03 and renumbered the remainder, that dedicated lab became Lab 05 (Cross-Platform Validation), with Scheduled Health Reporting as Lab 06.

The dedicated lab was never drafted. Revisiting it before writing it, it does not justify itself as a standalone lab, for three reasons.

First, it is redundant with work already done. Lab 01 (User Lifecycle Automation) already implemented and validated the full cross-platform identity chain (AD group membership, SSSD resolution, PAM authorization, SSH) in both directions against a live test account (`jdoe`): access granted upon `Linux-Admins` membership and denied upon its removal, with the SSSD cache behavior in each direction documented from real observation rather than assumption. The cross-platform proof ADR-015 called for is therefore already demonstrated in the repository as an intrinsic part of user lifecycle automation, not a gap awaiting its own lab.

Second, a standalone lab would over-elevate a supporting concern. ADR-015 was deliberate that this track is AD-centric, with Docker, Linux, and Wazuh present as supporting validation, not as parallel automation subjects. A lab whose entire subject is the Linux-side validation would invert that emphasis, making the supporting concern the headline.

Third, the fully automated form of the lab is low-value relative to its fragility. An end-to-end script that provisions a user and then validates SSH access as that user runs into two behaviors Lab 01 already documented: `-ChangePasswordAtLogon` forces an interactive password change on first login, which a non-interactive check cannot complete, and a freshly provisioned account is not immediately resolvable on Ubuntu Server until SSSD's negative cache is cleared (Lab 01 found `sss_cache` insufficient and a service restart required). The realistic automated form degrades to checking resolution and group membership from an administrative session, which is what Lab 01 already did by hand.

---

# Decision

Cross-platform validation is retired as a standalone lab in the Infrastructure Automation and Scripting track. No `05-cross-platform-validation.md` lab will be created.

The cross-platform validation objective of ADR-015 is considered satisfied by Lab 01, which demonstrated the AD-to-Linux authentication chain in both directions against a live account. Cross-platform validation remains a supporting concern of the track as ADR-015 framed it; it is not removed as a concept, only as a dedicated lab.

Scheduled Health Reporting, previously Lab 06, becomes Lab 05 and is the track's final planned lab. The track is therefore a five-lab sequence: User Lifecycle Automation, Group and OU Administration, Static Analysis and Unit Testing, Group Policy Reporting and Audit, and Scheduled Health Reporting.

The track README's success criteria are reworded so the Linux SSH access outcome is stated as demonstrated by Lab 01 rather than promised via a single combined provisioning-and-validation script.

This ADR supersedes ADR-015's treatment of cross-platform validation as a separate deliverable, and the lab-numbering portion of ADR-017's sequencing decision. Consistent with the repository's ADR practice, the bodies of ADR-015 and ADR-017 are preserved as the historical record; each carries a pointer to this ADR in its Status line, and this ADR is the current record where they conflict.

---

# Alternatives Considered

## Build the Lab as Originally Implied

Advantages:

- delivers the literal ADR-015 success criterion of a single script that provisions and validates Linux access
- adds an explicit end-to-end orchestration artifact to the track

Reasons rejected:

- redundant with Lab 01, which already proves the cross-platform chain in both directions against a live account
- inverts the AD-centric emphasis ADR-015 set, by making the Linux side the subject of a whole lab
- the fully automated form is fragile against the forced-password-change and SSSD-cache behaviors Lab 01 documented, and its realistic form reduces to the administrative-session resolution check Lab 01 already performed

## Reshape It Into a Repeatable Cross-Platform Access-Verification Report

Advantages:

- would be genuinely distinct from Lab 01, in the way Lab 04 made a one-time manual `gpresult` check repeatable
- demonstrates a script reasoning across the Windows and Linux boundary at runtime

Reasons rejected, for now:

- requires a cross-host execution model that departs from ADR-016's "no new remoting technology" boundary, which would need its own ADR
- requires a testing approach for parsing external `ssh`/`getent` output that ADR-017's mock-the-AD-cmdlet standard does not cover
- the added architecture surface is not justified while Lab 01 already demonstrates the chain; this is recorded as a future reassessment trigger rather than built now

## Fold Cross-Platform Checks Into Scheduled Health Reporting

Advantages:

- avoids a separate lab while retaining an automated Linux-side check

Reasons rejected:

- muddies the scope of Scheduled Health Reporting, which is environment health (AD service state, Wazuh agent enrollment, Docker service status), not per-user access verification

---

# Consequences

## Positive Outcomes

- the track structure is honest and non-redundant: no lab re-proves what Lab 01 already established
- the AD-centric emphasis of ADR-015 is preserved rather than diluted by a Linux-subject lab
- the track is a clean five-lab sequence with no fragile automated-login lab to build and maintain
- the cross-platform proof remains in the repository where it was actually performed, in Lab 01

## Tradeoffs

- the literal ADR-015 wording of a single script that both provisions and validates Linux access is not delivered; validation of Linux access remains the Lab 01 demonstration rather than an on-demand tool
- renumbering leaves the original numbering in the bodies of ADR-015, ADR-016, and ADR-017 referring to a sequence that no longer matches; this is mitigated by preserving those bodies as history, adding Status-line pointers to this ADR, and treating this ADR as the current record

---

# Future Reassessment

This decision may be revisited if:

- a repeatable cross-platform access-verification tool becomes worthwhile (for example, if the managed account count grows, or routine access audits across Windows and Linux become a recurring need), at which point the reshaped access-report lab deferred above could be built
- the automation track adopts a jump-host or remote-exec model, which is ADR-016's own reassessment trigger; a cross-host validation script would be built under that model with its own execution ADR
- a later track (for example, Cloud and Hybrid Identity) introduces cross-platform or hybrid access-validation requirements that make a dedicated on-premises validation tool a useful foundation

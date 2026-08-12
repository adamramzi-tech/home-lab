# ADR-017: Adopt PowerShell Static Analysis and Unit Testing for the Automation and Scripting Track

## Status

Accepted

## Date

2026-08-12

---

## Related Decisions

Builds upon:

- [ADR-015: Establish Infrastructure Automation and Scripting Track](015-establish-infrastructure-automation-and-scripting-track.md)
- [ADR-016: Run Automation Scripts from a Domain-Joined Client](016-run-automation-scripts-from-domain-joined-client.md)

Related documentation:

- [Project README](../../../README.md)
- [Automation and Scripting Track README](../../automation-and-scripting/README.md)
- [03 - Static Analysis and Unit Testing](../../automation-and-scripting/03-static-analysis-and-unit-testing.md) (the lab this decision establishes)
- [01 - User Lifecycle Automation](../../automation-and-scripting/01-user-lifecycle-automation.md)
- [02 - Group and OU Administration](../../automation-and-scripting/02-group-and-ou-administration.md)

---

# Context

The Infrastructure Automation and Scripting track now has a small but growing PowerShell script library: five scripts across Lab 01 (`New-LabUser.ps1`, `Remove-LabUser.ps1`) and Lab 02 (`Add-LabGroupMembers.ps1`, `Get-LabOUReport.ps1`, `Get-LabAccountInventory.ps1`), with more expected in Labs 04 through 06.

Quality in these scripts is currently assured entirely by manual, documented validation. Each script is run against the live `corp.home.arpa` environment during its lab, and its reported result is cross-checked against an independent, standalone Active Directory query rather than trusted on its own success message. That validation is rigorous, and it is the right way to prove a script actually works against real infrastructure. But it has two structural limits. It is performed once, during the lab, and is not repeatable without re-running the entire lab against the live domain. And it depends on a live domain being reachable, which means there is no way to check a script's internal logic in isolation.

Two categories of quality assurance that are standard in professional PowerShell work are therefore absent from the track:

- **Static analysis.** There is no linting pass that catches known-problematic constructs (unapproved verbs, aliases used in scripts, uninitialized or unused variables, inconsistent style) before a script is run.
- **Automated unit testing.** There is no repeatable, assertion-based test of a script's decision logic, the input validation, the partial-success batch handling, the primary-group exclusion, and the query-back validation that are the actual value of these scripts, independent of a live domain.

As the library grows and later labs reuse patterns from earlier scripts (Lab 02 already reused `Remove-LabUser.ps1`'s primary-group exclusion pattern; the Group Policy reporting and scheduled health reporting labs are expected to reuse the reporting-output convention), the absence of an automated safety net means a regression in a reused pattern would only surface by manually re-running a lab. The library is still small enough that adopting this tooling now is cheap, and establishing the convention before the remaining labs add more scripts means new scripts are written against the standard from the start rather than retrofitted later.

**Relationship to the track's scope.** ADR-015 scoped this track to automating the administration of the existing Active Directory environment, and explicitly not to general-purpose scripting instruction. Adopting static analysis and unit testing does not broaden that scope: it serves one of ADR-015's own stated success criteria, that `infrastructure/automation-and-scripting/` contain a coherent operational script library that can be used without additional context. A library that passes a documented analyzer standard and carries unit tests of its decision logic is more coherent and more trustworthy to reuse. This ADR treats static analysis and testing as quality assurance for the track's own administrative automation, not as a new subject area.

**Relationship to ADR-016.** ADR-016 established that the track's Active Directory scripts run from WIN11-CLIENT01 against DC01, and framed that as applying to every subsequent lab. The lab this ADR introduces is a deliberate exception to that execution model: static analysis reads the script files, and the Pester tests replace the Active Directory cmdlets with mocks, so the suite runs entirely on the workstation with no live domain contact. ADR-016 continues to govern every lab that actually executes Active Directory cmdlets; it simply does not apply to a lab whose tests never touch the directory.

---

# Decision

The track will adopt **PSScriptAnalyzer** for static analysis and **Pester** for unit testing as standing quality tooling for the PowerShell script library.

**PSScriptAnalyzer** is the standard, Microsoft-maintained static analyzer for PowerShell. It runs without a live Active Directory environment, enforces consistent style, and flags known problematic constructs before a script is executed. Every script under `infrastructure/automation-and-scripting/` is expected to pass an agreed PSScriptAnalyzer rule set, run from WIN11-CLIENT01 (consistent with ADR-016) or any workstation with the module installed.

**Pester** is the de facto testing framework for PowerShell. It supports mocking, so the Active Directory cmdlets each script calls can be replaced with test doubles and the script's decision logic asserted without touching a real domain. Pester tests will cover the behavior that manual validation currently proves only once: input and header validation, the partial-success batch model, primary-group exclusion, and the query-back validation pattern. These mocked tests complement, and do not replace, the live-environment cross-checks the track already performs.

The analyzer configuration and the Pester tests will live in the repository alongside the scripts. The tooling and an initial pass retrofitting the existing Lab 01 and Lab 02 scripts will be introduced as its own lab, documented to the same standard as the rest of the track. This ADR records the decision to adopt the tooling; the implementation is pending and will be documented when it is actually performed.

**Sequencing: this work becomes the next lab (Lab 03).** This decision also reorders the remainder of the track. The static analysis and testing work is inserted as Lab 03, the immediate next lab, ahead of the previously planned Group Policy Reporting and Audit, Cross-Platform Validation, and Scheduled Health Reporting labs, which shift to Lab 04, Lab 05, and Lab 06 respectively. Numbering in this repository reflects implementation sequence rather than importance (per the [infrastructure standards](../naming-and-scope-standards.md)), so the sequence should match the order the labs will actually be built. Establishing the analysis and testing standard before any further scripts are written means Labs 04 through 06 are authored against it from the start and gain test coverage as they are built, rather than accumulating an untested backlog to retrofit later. The existing five scripts from Labs 01 and 02 are a small, bounded retrofit target now, and every lab deferred past this point enlarges that target. Because Labs 04 through 06 are all still in the planning stage with no implementation yet, reordering them costs nothing in redone work.

---

# Alternatives Considered

## Continue with Manual Documented Validation Only

Advantages:

- no new tooling or test-authoring overhead
- consistent with how the track has operated through Labs 01 and 02

Reasons rejected:

- manual validation is performed once per lab and is not repeatable without re-running the whole lab against the live domain
- it provides no regression safety net as scripts and reused patterns accumulate
- it omits static analysis and automated testing, both of which are standard practice in professional PowerShell work and expected in a track whose entire subject is automation quality

## Static Analysis Only (PSScriptAnalyzer, no Pester)

Advantages:

- lower overhead than also authoring tests
- catches style and correctness issues cheaply

Reasons rejected:

- linting cannot assert behavior, and the value of these scripts is in their decision logic (partial-success handling, query-back validation, primary-group exclusion), which only tests can verify
- adopting half of the standard tooling would leave the more valuable half, behavioral testing, unaddressed

## Stand Up a Full CI Pipeline Now (GitHub Actions running analyzer and tests on push)

Advantages:

- automated enforcement on every push rather than on demand
- no reliance on remembering to run the tooling manually

Reasons rejected:

- the scripts target a live Active Directory environment and are run from WIN11-CLIENT01; a hosted CI runner has no domain, so only the mocked Pester tests and the analyzer could run there, not the live validation
- standing up CI is a larger step than the track currently needs, and introduces build infrastructure ahead of demonstrated need
- this is a natural future reassessment trigger once the mocked tests and analyzer configuration exist and are worth automating

---

# Consequences

## Positive Outcomes

- repeatable, automated quality checks replace one-time manual validation for the purpose of catching regressions
- new scripts in Labs 03 through 05 are written against a defined analysis and testing standard from the start rather than retrofitted afterward
- Pester's mocking allows a script's decision logic to be tested without a live domain, complementing the live-environment cross-checks the track already performs
- the track demonstrates professional PowerShell quality-assurance practice, strengthening its operational story rather than relying on manual validation alone

## Tradeoffs

- introduces static-analysis configuration and test-authoring overhead for every script in the library
- mocked tests validate logic against test doubles, not live Active Directory behavior; the existing live cross-checks remain necessary and are explicitly not replaced by this decision
- retrofitting Pester tests and an analyzer pass onto the existing five scripts is upfront work that must be completed before the standard is fully in force

These tradeoffs are considered acceptable given the compounding value of an automated safety net as the script library grows, and the low cost of adopting the tooling while the library is still small.

---

# Future Reassessment

This decision may be revisited if:

- the script library or contributor count grows enough to justify a hosted CI pipeline running PSScriptAnalyzer and mocked Pester tests automatically on push, the alternative deferred above
- the track later targets more than one Active Directory environment, at which point integration tests against a disposable test domain may become worthwhile alongside the mocked unit tests
- PowerShell 7 or cross-platform execution becomes relevant to the track, which would require revisiting the analyzer rule set and module compatibility assumptions made here

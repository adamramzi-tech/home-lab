# 03 - Static Analysis and Unit Testing

## Status

- Planning and research phase

This lab is scoped and researched but not yet implemented. The sections below describe the intended work in forward-looking terms: the tooling this lab will introduce, the standard it will establish for the script library, and the plan for retrofitting the existing Lab 01 and Lab 02 scripts. Implementation, validation, troubleshooting, and outcome content will be added as the work is actually performed, in the same lifecycle order the previous labs in this track followed. The decision to adopt this tooling and to place it here in the sequence is recorded in [ADR-017](../architecture/decisions/017-adopt-powershell-static-analysis-and-unit-testing.md).

---

## Overview

This lab hardens the automation layer the track has produced so far, rather than adding another administrative workflow to it. Labs 01 and 02 produced five PowerShell scripts, each validated once by running it against the live `corp.home.arpa` environment and cross-checking its output against an independent Active Directory query. That validation proves each script works, but it is manual, performed once per lab, and not repeatable without re-running the whole lab against a live domain.

This lab introduces the two quality tools that are standard in professional PowerShell work but so far absent from the track: PSScriptAnalyzer for static analysis and Pester for unit testing. It applies both to the existing script library and establishes them as the standard every later lab is written against. Consistent with ADR-015, it introduces no new infrastructure. It is also the first lab in the track that does not touch DC01 at runtime: static analysis reads the script files, and the Pester tests replace the Active Directory cmdlets with mocks, so the whole suite runs on the workstation without a live domain.

---

## Objectives

The primary goals of this lab are to:

- run PSScriptAnalyzer across every script in `infrastructure/automation-and-scripting/` and bring the library to a clean pass against an agreed, documented rule set
- decide, and document the reasoning for, how to handle the `PSAvoidUsingWriteHost` rule, which flags the colored PASS/FAIL status output every script in the library currently relies on
- author Pester unit tests that assert each script's decision logic (pre-flight validation, OU and group placement, the partial-success batch model, primary-group exclusion, and the query-back validation pattern) using mocked Active Directory cmdlets, so the tests run without a live domain
- capture the agreed analyzer rule set and the test suite in the repository so both are reproducible and become the standard the later labs (04 through 06) are written against
- document explicitly which behaviors are covered by these mocked tests and which remain covered only by the live-environment validation in Labs 01 and 02, so the boundary between unit-tested logic and live-validated behavior is clear rather than implied

---

## Project Context

The automation track has, to this point, grown its script library faster than its quality tooling. Five scripts exist (`New-LabUser.ps1`, `Remove-LabUser.ps1`, `Add-LabGroupMembers.ps1`, `Get-LabOUReport.ps1`, `Get-LabAccountInventory.ps1`), each documented and validated to a high standard, but that validation is entirely manual and entirely dependent on a live domain. There is no linting pass that catches a bad construct before a script runs, and no repeatable test that would catch a regression in a reused pattern. Lab 02 already reused `Remove-LabUser.ps1`'s primary-group exclusion logic; the reporting labs still to come will reuse the console-table convention. A regression in one of those shared patterns would, today, only surface by manually re-running a lab.

ADR-017 records the decision to close that gap by adopting PSScriptAnalyzer and Pester, and to do it now, as the next lab, rather than after the remaining administrative labs. The reasoning is sequencing: the library is still small enough that retrofitting five scripts is cheap, and establishing the standard before Labs 04 through 06 are written means those labs are authored against it from the start and gain test coverage as they are built, instead of accumulating an untested backlog to retrofit later. This lab is the implementation of that decision.

It also fills a gap in the track's demonstrated skill set. A track whose entire subject is automation quality that relied only on manual validation would be conspicuously missing the two tools any professional PowerShell practice uses to enforce that quality automatically.

---

## Design Decisions

*(These are planning-stage decisions. They may be revised during implementation if a live diagnostic or the analyzer's actual output contradicts the reasoning here, in which case the change and its rationale will be documented in the implementation and troubleshooting sections.)*

### Mocked unit tests, not live-integration tests, for the repeatable suite

**Decision:** The Pester tests will replace the Active Directory cmdlets each script calls (`Get-ADUser`, `Get-ADGroup`, `New-ADUser`, `Add-ADGroupMember`, `Get-ADGroupMember`, `Get-ADPrincipalGroupMembership`, `Get-ADOrganizationalUnit`, `Get-ADComputer`) with Pester mocks, so the suite asserts each script's decision logic without contacting DC01.

The value of these scripts is in their decision logic, the pre-flight checks, the partial-success batch handling, the primary-group exclusion, and the query-back validation, and that logic can be exercised deterministically with mocked cmdlets returning controlled results, including the error and empty-result cases that are awkward to produce against a live domain on demand. Mocking also makes the suite fast, repeatable, and safe to run without a domain or credentials. The tradeoff is that mocked tests validate logic against test doubles, not live Active Directory behavior; they do not replace the live cross-checks Labs 01 and 02 already performed, and this lab will state that boundary explicitly rather than implying the mocked tests prove live behavior.

### Handle PSAvoidUsingWriteHost deliberately, and document the choice

**Decision:** The lab will make an explicit, documented decision about the `PSAvoidUsingWriteHost` rule rather than silently suppressing it or silently letting it fail.

Every script in the library uses `Write-Host` with `-ForegroundColor` to print colored PASS, FAIL, and ABORT status lines. PSScriptAnalyzer flags this with `PSAvoidUsingWriteHost` (a Warning, always enabled) because `Write-Host` writes to the host rather than the pipeline; the rule's built-in exception for `Show`-verb functions does not apply, since these are `New-`, `Remove-`, `Add-`, and `Get-` scripts. There are two defensible resolutions, and the lab will choose one and record why: suppress the rule for these scripts with a documented justification (the colored status output is intentional operator-facing display, not pipeline data), or migrate the status output to `Write-Information`, which is available in PowerShell 5.1, is analyzer-clean, and remains visible to the operator while behaving better in a pipeline. The migration is the cleaner long-term path but changes output behavior slightly; the suppression is lower-effort but leaves a rule turned off. This is the central implementation decision of the lab and will be resolved in Step Two against the analyzer's actual output.

### Capture the agreed rule set in a settings file

**Decision:** The agreed PSScriptAnalyzer rule set will be captured in a `PSScriptAnalyzerSettings.psd1` committed to the repository, rather than relying on whichever default rules a given machine happens to run.

Pinning the rule set makes the standard explicit and reproducible: anyone running `Invoke-ScriptAnalyzer -Settings <file>` against the library gets the same result, and any deviation from the analyzer's defaults (for example, a decision on the `PSAvoidUsingWriteHost` rule above) is visible in one reviewed file rather than buried in per-run parameters.

### On-demand execution, no CI pipeline yet

**Decision:** The analyzer and the Pester suite will be run on demand from WIN11-CLIENT01, not wired into a continuous integration pipeline in this lab.

ADR-017 deferred standing up CI as a larger step than the track currently needs, and named it a future reassessment trigger once the mocked tests and analyzer settings exist. This lab produces exactly those artifacts. Automating their execution on push is left as the natural follow-on once they are in place, rather than introducing build infrastructure in the same lab that first creates the tests.

### Script and folder naming

**Decision:** Pester tests will follow the framework's `*.Tests.ps1` naming convention, and the analyzer settings and test files will live in the repository alongside the script library under `infrastructure/automation-and-scripting/`, with the exact layout (a shared `tests/` subfolder versus per-script colocation) settled in Step Three.

---

## Technologies Used

- PowerShell 5.1 (run from WIN11-CLIENT01, per ADR-016, though no live domain is required for this lab)
- PSScriptAnalyzer: `Invoke-ScriptAnalyzer` for static analysis, installed from the PowerShell Gallery
- Pester (v5 or later; current release v6): `Invoke-Pester` with `Describe`, `Context`, `It`, `Should`, and `Mock` for unit testing with mocked cmdlets
- `PSScriptAnalyzerSettings.psd1` to pin the agreed rule set
- The existing script library from Labs 01 and 02 (`New-LabUser.ps1`, `Remove-LabUser.ps1`, `Add-LabGroupMembers.ps1`, `Get-LabOUReport.ps1`, `Get-LabAccountInventory.ps1`)

---

## Architecture or Topology

```text
WIN11-CLIENT01 (PowerShell, PSScriptAnalyzer + Pester)
        |
        |  Invoke-ScriptAnalyzer -Settings PSScriptAnalyzerSettings.psd1
        |      --> static analysis over infrastructure/automation-and-scripting/*.ps1
        |
        |  Invoke-Pester
        |      --> *.Tests.ps1, with Active Directory cmdlets replaced by Mock
        v
  No DC01 contact at runtime: the AD cmdlets are mocked, so static
  analysis and the unit tests run entirely on the workstation.

  Live-environment behavior (real AD writes, SSSD/PAM SSH access)
  remains covered by the manual validation in Labs 01 and 02, not by
  this suite. This lab documents that boundary rather than blurring it.
```

Unlike every prior lab in the track, this lab does not query or modify DC01 when it runs. That is a deliberate property of unit testing with mocks, and it is what makes the suite safe to run repeatedly.

---

## Prerequisites

- Lab 01 (`New-LabUser.ps1`, `Remove-LabUser.ps1`) and Lab 02 (`Add-LabGroupMembers.ps1`, `Get-LabOUReport.ps1`, `Get-LabAccountInventory.ps1`) complete; the five scripts exist in `infrastructure/automation-and-scripting/`
- PSScriptAnalyzer and Pester installable on WIN11-CLIENT01 from the PowerShell Gallery (`Install-Module`), or available for offline install
- [ADR-017](../architecture/decisions/017-adopt-powershell-static-analysis-and-unit-testing.md), which establishes this tooling and this lab's place in the track sequence
- WIN11-CLIENT01 as the execution endpoint per [ADR-016](../architecture/decisions/016-run-automation-scripts-from-domain-joined-client.md); note that, uniquely for this lab, no live domain connection is required to run the suite

---

## Implementation Plan

*(Titled "Implementation Plan" during the planning and research phase. It will be renamed to "Implementation" and rewritten in past tense as each step is actually performed, matching the workflow used in Lab 01 and Lab 02.)*

### Step One - Install PSScriptAnalyzer and Baseline the Library

The plan is to install PSScriptAnalyzer (`Install-Module -Name PSScriptAnalyzer`) on WIN11-CLIENT01 and run `Invoke-ScriptAnalyzer` across all five scripts to capture the initial set of findings as a starting baseline. Based on the rule set, `PSAvoidUsingWriteHost` is expected to fire on every script, since each uses `Write-Host` for its colored status output; the baseline will confirm which other rules, if any, also fire.

```powershell
Install-Module -Name PSScriptAnalyzer -Scope CurrentUser
Invoke-ScriptAnalyzer -Path .\infrastructure\automation-and-scripting\ -Recurse
```

### Step Two - Settle the Rule Set and Resolve Findings

The plan is to resolve the `PSAvoidUsingWriteHost` decision described in the Design Decisions section (documented suppression versus migration to `Write-Information`), capture the agreed rule set in `PSScriptAnalyzerSettings.psd1`, and resolve or justify every remaining finding until the library passes cleanly against that settings file. Any suppression will carry a written justification so a turned-off rule is an explicit, reviewable choice.

### Step Three - Install Pester and Test the Lab 01 Scripts

The plan is to install Pester (`Install-Module -Name Pester`), settle the `*.Tests.ps1` layout, and write the first unit tests for `New-LabUser.ps1` and `Remove-LabUser.ps1`. These tests will mock the Active Directory cmdlets and assert the decision branches: the duplicate and existence pre-flight checks, OU placement and group assignment, the optional `Linux-Admins` handling, and the query-back self-validation, including the failure branches that are awkward to trigger against a live domain.

```powershell
Install-Module -Name Pester -Scope CurrentUser
# Describe / Context / It / Should, with Mock Get-ADUser, Mock New-ADUser, etc.
Invoke-Pester -Path .\infrastructure\automation-and-scripting\ -Output Detailed
```

### Step Four - Test the Lab 02 Scripts

The plan is to write mocked tests for the three Lab 02 scripts: `Add-LabGroupMembers.ps1` (CSV header validation, grouping by target group, and the partial-success model where an invalid member is excluded while a valid member in the same batch still succeeds), `Get-LabOUReport.ps1` (per-OU counting with `-SearchScope OneLevel` and the zero-count case), and `Get-LabAccountInventory.ps1` (primary-group exclusion and preservation of blank `LastLogonDate` values). These are the decision behaviors Lab 02 proved once by hand; the tests lock them in against regression.

### Step Five - Run the Full Suite and Document Coverage

The plan is to run `Invoke-ScriptAnalyzer` and `Invoke-Pester` across the whole library, record the results, and document explicitly which behaviors the mocked suite covers and which remain covered only by the live-environment validation in Labs 01 and 02 (real Active Directory writes, and the SSSD and PAM SSH access path proven in Lab 01). Making that boundary explicit is part of the deliverable: the suite is a regression safety net for logic, not a replacement for the live proof the earlier labs already provided.

---

## Validation

*To be completed during implementation. This section will record the actual analyzer output before and after the rule-set decision, the actual Pester run results, and confirmation that the library passes both, following the evidence-based approach used in Lab 01 and Lab 02. It will document what was observed, not what was expected.*

---

## Troubleshooting and Adjustments

*To be completed during implementation. This section will document any issues actually encountered, including the resolution of the `PSAvoidUsingWriteHost` decision and any mocking difficulties (for example, cmdlets whose behavior is hard to reproduce with a mock), the investigation performed, and the outcome.*

---

## Security Considerations

*(Planned security posture. Where these depend on observed behavior, they will be confirmed during implementation.)*

- **No live domain, no credentials.** Because the Pester tests mock the Active Directory cmdlets, the suite touches no live directory and needs no credentials or AD privileges to run. This is a deliberate departure from the other labs in the track, and it makes the suite safe to run repeatedly without any risk to the domain.
- **Static analysis is read-only.** `Invoke-ScriptAnalyzer` reads the script files and does not execute them or modify anything.
- **Suppressions are explicit and justified.** Any analyzer rule that is suppressed will carry a written justification in the settings file or the script, so a disabled rule is a reviewable decision rather than a silent omission, consistent with the track's habit of documenting reasoning rather than hiding it.

---

## Outcome

*To be completed once the lab is implemented and validated. This section will summarize what was actually established: the analyzer standard, the test coverage the library now has, and the boundary between unit-tested logic and live-validated behavior.*

---

## Lessons Learned

*To be completed once the lab is implemented. This section will capture the operational and architectural lessons actually drawn from the work, including whatever the `Write-Host` decision and the first round of mocked tests reveal about making these scripts testable.*

---

## Sources

*(Living research log. The references below were consulted during the planning and research phase. Deployment-stage sources will be appended as they come up during implementation and troubleshooting.)*

**PSScriptAnalyzer (Microsoft Learn)**

- [PSScriptAnalyzer overview](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/overview) - static code checker for PowerShell; installed with `Install-Module PSScriptAnalyzer` and run with `Invoke-ScriptAnalyzer`, the basis for this lab's static analysis step
- [AvoidUsingWriteHost rule](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/rules/avoidusingwritehost) - documents why `Write-Host` is flagged (it writes to the host, not the pipeline), the `Show`-verb exception (which does not apply to this library's scripts), and that the rule can be suppressed; the source of the central design decision in Step Two

**Pester (pester.dev)**

- [Pester quick start](https://pester.dev/docs/quick-start) - confirms the `*.Tests.ps1` convention and the `Describe`, `Context`, `It`, and `Should` keywords, and that tests run with `Invoke-Pester`; the basis for this lab's unit-testing steps
- [Pester mocking](https://pester.dev/docs/usage/mocking) - the `Mock` keyword used to replace the Active Directory cmdlets so the tests run without a live domain, the approach chosen in the Design Decisions section

**Repository reference**

- [ADR-017: Adopt PowerShell Static Analysis and Unit Testing](../architecture/decisions/017-adopt-powershell-static-analysis-and-unit-testing.md) - the decision that establishes this tooling and places this lab as Lab 03 in the track sequence
- [01 - User Lifecycle Automation](01-user-lifecycle-automation.md) and [02 - Group and OU Administration](02-group-and-ou-administration.md) - the labs whose scripts this lab retrofits with static analysis and tests

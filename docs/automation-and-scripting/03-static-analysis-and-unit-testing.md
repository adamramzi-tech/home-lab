# 03 - Static Analysis and Unit Testing

## Status

- Implementation in progress

Step One (install PSScriptAnalyzer and baseline the script library), Step Two (resolve `PSAvoidUsingWriteHost` and bring the library to a clean pass), and Step Three (install Pester and test the Lab 01 scripts) are complete. Steps Four and Five remain. Completed steps below are rewritten in past tense with actual results as they are performed; steps not yet reached remain in the forward-looking planning language established during the research phase, in the same lifecycle order the previous labs in this track followed. The decision to adopt this tooling and to place it here in the sequence is recorded in [ADR-017](../architecture/decisions/017-adopt-powershell-static-analysis-and-unit-testing.md).

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
- Pester 5.6.1, pinned via `-RequiredVersion` rather than whatever version the Gallery resolves by default: `Invoke-Pester` with `Describe`, `Context`, `It`, `Should`, and `Mock` for unit testing with mocked cmdlets
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

## Implementation

### Step One - Install PSScriptAnalyzer and Baseline the Library

PSScriptAnalyzer was installed on WIN11-CLIENT01 with `Install-Module -Name PSScriptAnalyzer -Scope CurrentUser`. The install prompted twice before completing: once for PowerShellGet to install and import the NuGet provider it needs to talk to Gallery-based repositories, and once to confirm installing from PSGallery, which is untrusted by default. Both prompts were accepted.

```powershell
Install-Module -Name PSScriptAnalyzer -Scope CurrentUser
```

Module availability was then verified:

```powershell
Get-Module -Name PSScriptAnalyzer -ListAvailable
```

This confirmed PSScriptAnalyzer 1.25.0 installed under the `CurrentUser` scope (`C:\Users\labadmin.CORP\Documents\WindowsPowerShell\Modules`), exporting `Get-ScriptAnalyzerRule`, `Invoke-ScriptAnalyzer`, and `Invoke-Formatter`.

<p align="center">
  <img src="../../images/automation-and-scripting/03-static-analysis-and-unit-testing/01-install-and-verify-psscriptanalyzer.jpg" width="900">
</p>

<p align="center">
  <em>Install-Module -Name PSScriptAnalyzer -Scope CurrentUser completing after accepting the NuGet provider and untrusted-repository prompts, followed by Get-Module -Name PSScriptAnalyzer -ListAvailable confirming version 1.25.0 installed under the CurrentUser scope.</em>
</p>

#### Baseline Scan

```powershell
Invoke-ScriptAnalyzer -Path C:\Scripts -Recurse
```

<p align="center">
  <img src="../../images/automation-and-scripting/03-static-analysis-and-unit-testing/02-baseline-scan-output.jpg" width="900">
</p>

<p align="center">
  <em>Invoke-ScriptAnalyzer -Path C:\Scripts -Recurse baseline output, showing PSAvoidUsingWriteHost findings against Add-LabGroupMembers.ps1.</em>
</p>

The baseline returned findings for a single rule, `PSAvoidUsingWriteHost` (Warning severity, always enabled), across all five scripts: 52 findings total, and no findings from any other rule.

| Script | Findings | Lines |
|---|---|---|
| `New-LabUser.ps1` | 19 | 39, 43, 47, 50, 58, 73, 78, 82, 86, 93, 96, 101, 104, 109, 112, 118, 121, 126, 129 |
| `Remove-LabUser.ps1` | 15 | 20, 24, 27, 31, 36, 40, 46, 51, 58, 61, 66, 71, 74, 80, 83 |
| `Add-LabGroupMembers.ps1` | 12 | 28, 33, 37, 46, 53, 57, 71, 74, 79, 83, 91, 94 |
| `Get-LabAccountInventory.ps1` | 3 | 30, 35, 58 |
| `Get-LabOUReport.ps1` | 3 | 25, 29, 47 |

This confirms the Design Decisions section's prediction that `PSAvoidUsingWriteHost` would fire on every script, and establishes that it is the only rule the baseline surfaces, no unapproved-verb, alias, or uninitialized-variable findings, or anything else, fired against any of the five scripts. The `PSAvoidUsingWriteHost` decision described in Design Decisions is the only finding Step Two has to resolve to bring the library to a clean pass.

### Step Two - Settle the Rule Set and Resolve Findings

The `PSAvoidUsingWriteHost` decision described in Design Decisions was resolved in favor of a documented suppression, not a migration to `Write-Information`. The colored PASS/FAIL/ABORT status lines are intentional operator-facing display, not pipeline data; the scripts' actual report data flows through the pipeline and `Export-Csv`, and the status lines are feedback only. The scripts target Windows PowerShell 5.1, where `Write-Host` writes to the information stream (stream 6) and is therefore capturable and redirectable, so the rule's core objection, that `Write-Host` output "cannot be suppressed, captured, or redirected," applies only prior to PS 5.0, per the rule's own message. Migrating to `Write-Information` was considered and rejected: it is silent by default (requires `-InformationAction Continue` or `$InformationPreference = 'Continue'`) and carries no `-ForegroundColor`, which would degrade the operator experience for no practical gain.

The agreed rule set was captured in `PSScriptAnalyzerSettings.psd1`, committed to the repository at `infrastructure/automation-and-scripting/`. It excludes only `PSAvoidUsingWriteHost`, with the reasoning above recorded as a comment directly in the file; every other default PSScriptAnalyzer rule remains active.

```powershell
@{
    ExcludeRules = @(
        'PSAvoidUsingWriteHost'
    )
}
```

A copy was placed in `C:\Scripts` on WIN11-CLIENT01 so it could be used with the live scan.

<p align="center">
  <img src="../../images/automation-and-scripting/03-static-analysis-and-unit-testing/03-settings-file-placed-in-scripts.jpg" width="900">
</p>

<p align="center">
  <em>PSScriptAnalyzerSettings.psd1, with the PSAvoidUsingWriteHost exclusion and its written justification, placed in C:\Scripts alongside the script library.</em>
</p>

The library was re-scanned against the pinned settings file:

```powershell
Invoke-ScriptAnalyzer -Path C:\Scripts -Settings C:\Scripts\PSScriptAnalyzerSettings.psd1 -Recurse
```

<p align="center">
  <img src="../../images/automation-and-scripting/03-static-analysis-and-unit-testing/04-clean-rescan-output.jpg" width="900">
</p>

<p align="center">
  <em>Invoke-ScriptAnalyzer re-run with -Settings pointed at PSScriptAnalyzerSettings.psd1, returning to the prompt with no output: a clean pass across all five scripts.</em>
</p>

The command returned no output, confirming a clean pass: with `PSAvoidUsingWriteHost` excluded, zero findings remain against any of the five scripts under the pinned rule set. This resolves the lab's central design decision and gives the library a clean, reproducible baseline to build the Pester suite against in Steps Three and Four.

### Step Three - Install Pester and Test the Lab 01 Scripts

Pester was installed pinned to a specific version, 5.6.1, rather than whatever version the Gallery resolves by default:

```powershell
Install-Module Pester -RequiredVersion 5.6.1 -Scope CurrentUser -Force -SkipPublisherCheck
Import-Module Pester -RequiredVersion 5.6.1 -Force
(Get-Module Pester).Version
```

`(Get-Module Pester).Version` confirmed `5.6.1.0` imported. Pinning mattered here specifically because this suite leans on `-ParameterFilter` scriptblocks and the `$PesterBoundParameters` variable Pester defines inside them (see below); reproducing the suite on another machine depends on that same major version being present, not on whichever version `Install-Module` would otherwise resolve.

<p align="center">
  <img src="../../images/automation-and-scripting/03-static-analysis-and-unit-testing/05-install-and-verify-pester.jpg" width="900">
</p>

<p align="center">
  <em>Install-Module Pester -RequiredVersion 5.6.1, Import-Module Pester -RequiredVersion 5.6.1 -Force, and (Get-Module Pester).Version confirming 5.6.1.0 imported.</em>
</p>

With Pester in place, the `*.Tests.ps1` layout question left open in Design Decisions was settled in favor of colocation over a shared `tests/` subfolder: `New-LabUser.Tests.ps1` and `Remove-LabUser.Tests.ps1` were placed directly in `infrastructure/automation-and-scripting/user-lifecycle-automation/`, next to the scripts they test. Pester's discovery is recursive regardless of layout, so the choice does not affect whether `Invoke-Pester` finds the tests; colocation was chosen so a script and the suite that exercises it are visible together in the same folder rather than split across two trees.

#### Proving the Harness Before Expanding

Rather than writing the full suite for both scripts at once, a single smoke test was written first, for `New-LabUser.ps1` only: `Get-ADUser` mocked to throw `Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException` (simulating no existing account), the script invoked with test parameters, and the test asserting only that the script did not throw and that `New-ADUser` was called once.

The first run of that smoke test failed, not because the script misbehaved, but because the mock itself was miswired. `New-LabUser.ps1` calls `Get-ADUser` twice: once as a pre-flight check with no `-Properties`, and once for post-creation validation with `-Properties Enabled, DistinguishedName`. The test tried to give each call different mocked behavior by branching each mock's `-ParameterFilter` on `$PSBoundParameters.ContainsKey('Properties')`, and both mocks matched the same call. Reading Pester 5.6.1's own source (`src/functions/Mock.ps1`) established why: a `-ParameterFilter` scriptblock does not receive `$PSBoundParameters` for the call being matched; Pester defines a separate `$PesterBoundParameters` variable for that purpose. Switching both `ParameterFilter`s to `$PesterBoundParameters` fixed the smoke test, which then passed with `New-ADUser` confirmed called exactly once, and that pattern was used consistently for every `ParameterFilter` and `Should -Invoke -ParameterFilter` written afterward.

#### Expanding to the Full Suite

With the harness proven, each script's entire Active Directory cmdlet surface was mocked, not just the calls central to a given test: `New-LabUser.Tests.ps1` mocks `Get-ADUser` (both call shapes), `New-ADUser`, `Add-ADGroupMember`, and `Get-ADPrincipalGroupMembership`; `Remove-LabUser.Tests.ps1` mocks `Get-ADUser`, `Disable-ADAccount`, `Get-ADPrincipalGroupMembership`, and `Remove-ADPrincipalGroupMembership`. An unmocked cmdlet anywhere on the success path could either crash the test or, worse, execute for real against a live domain.

Two further mocking issues surfaced while expanding the suite, both stemming from the same cause: Pester's mock proxy preserves the real cmdlet's parameter types, so a plain string the script passes is coerced into a typed Active Directory object at bind time, not left as a string.

- `Add-ADGroupMember`'s `-Identity` and `-Members` are typed `ADGroup` and `ADPrincipal[]` on the real cmdlet. `Should -Invoke -ParameterFilter` checks comparing `$PesterBoundParameters['Identity']` directly against a string always failed, even though the calls were happening, because the bound value was an `ADGroup` object, not a string. Wrapping the comparison in `"$($PesterBoundParameters['Identity'])"` to force `.ToString()` resolved it; a temporary diagnostic mock that logged the bound value's type and string form to a file confirmed the object's `.ToString()` reliably reproduces the identity string it was constructed from.
- `Remove-ADPrincipalGroupMembership`'s `-MemberOf` is typed `ADPrincipal`. The `Get-ADPrincipalGroupMembership` mock initially returned fabricated `PSCustomObject` values, and binding those to `-MemberOf` failed outright ("the adapter cannot set the value of property"), since a `PSCustomObject` does not go through the same identity-type conversion a plain string does. Casting the group's distinguished name to a real `ADPrincipal` instance first, then adding `DistinguishedName`/`Name` note properties for the script's own filtering and narration to read, produced an object that bound without error. A second, related issue followed: those note-property overrides did not survive parameter binding, because the value actually bound to `-MemberOf` is a freshly reconstructed object built from the identity string, not the specific instance the mock returned. `.ToString()` on the bound value did reliably reproduce the full distinguished name, so `Should -Invoke -ParameterFilter` checks against `-MemberOf` compare against `"$($PesterBoundParameters['MemberOf'])"` rather than a property on the bound object.

A smaller issue affected the pre-flight negative tests for `Remove-LabUser.ps1`: `Should -Invoke -Times 0` against `Disable-ADAccount` and `Remove-ADPrincipalGroupMembership` threw `Could not find Mock for command ... in script scope` until those two commands had at least a default `Mock` registered somewhere in scope. Pester requires a registered mock to exist for a command before `Should -Invoke` can assert anything about it, including that it was never called; both mocks were moved to the `Describe`-level `BeforeEach` shared by every test in the file.

#### Result

Both suites were run from WIN11-CLIENT01 against the synced copies in `C:\Scripts`, and the repository copies were kept in sync with each iteration.

| Test file | Tests | Result |
|---|---|---|
| `New-LabUser.Tests.ps1` | 12 | 12 passed, 0 failed |
| `Remove-LabUser.Tests.ps1` | 10 | 10 passed, 0 failed |
| **Total** | **22** | **22 passed, 0 failed** |

```powershell
Invoke-Pester -Path C:\Scripts\New-LabUser.Tests.ps1, C:\Scripts\Remove-LabUser.Tests.ps1 -Output Detailed
```

<p align="center">
  <img src="../../images/automation-and-scripting/03-static-analysis-and-unit-testing/06-full-test-suite-passing-output.jpg" width="900">
</p>

<p align="center">
  <em>Tail of the combined run against both test files: Tests Passed: 22, Failed: 0, Skipped: 0, Inconclusive: 0, NotRun: 0.</em>
</p>

Each suite asserts its script's decision logic, not which PASS/FAIL line the script prints for a given result: the pre-flight duplicate/not-found/error branches, the parameters passed to `New-ADUser`, role-group and `Linux-Admins` assignment, primary-group exclusion during removal, and that both scripts re-query Active Directory after writing rather than trusting the write cmdlets' own success. `Write-Host` was not mocked, per this lab's testing approach, so the scripts' colored narration prints during every test run; which specific PASS/FAIL line each query-back branch selects remains covered only by the live-environment validation in Lab 01, not by this suite.

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
- [Pester `Mock.ps1` source (GitHub)](https://github.com/pester/Pester/blob/main/src/functions/Mock.ps1) - confirms that a `-ParameterFilter` scriptblock receives `$PesterBoundParameters`, not `$PSBoundParameters`, for the call being matched; consulted directly in Step Three after `$PSBoundParameters`-based filters matched the wrong mocked behavior

**Repository reference**

- [ADR-017: Adopt PowerShell Static Analysis and Unit Testing](../architecture/decisions/017-adopt-powershell-static-analysis-and-unit-testing.md) - the decision that establishes this tooling and places this lab as Lab 03 in the track sequence
- [01 - User Lifecycle Automation](01-user-lifecycle-automation.md) and [02 - Group and OU Administration](02-group-and-ou-administration.md) - the labs whose scripts this lab retrofits with static analysis and tests

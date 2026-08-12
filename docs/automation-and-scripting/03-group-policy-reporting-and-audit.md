# 03 - Group Policy Reporting and Audit

## Status

- Planning and research phase

This lab is scoped and researched but not yet implemented. The sections below describe the intended work in forward-looking terms: the scripts this lab will produce, the Group Policy cmdlets they will be built on, and the plan for validating them against the environment's known Group Policy design. Implementation, validation, troubleshooting, and outcome content will be added as the work is actually performed, in the same lifecycle order the previous labs in this track followed.

---

## Overview

This lab will automate reporting and audit workflows for the Group Policy environment that the enterprise infrastructure track deployed in Lab 05 (Group Policy Lab). Where Lab 01 automated the user lifecycle and Lab 02 automated group and OU administration, this lab targets the third standing category of manual Active Directory work in the environment: answering "what Group Policy state currently exists, where is it linked, and what actually applies to a given user or computer" without walking the Group Policy Management Console by hand.

The lab will produce three read-only PowerShell scripts: a Group Policy Object inventory, a per-OU link and inheritance report, and a Resultant Set of Policy (RSoP) report for the domain-joined client. Consistent with ADR-015, the lab introduces no new infrastructure. It reports on and audits the three GPOs, their OU links, and their security filtering that already exist and were validated once by hand in the enterprise infrastructure track, and it makes that reporting repeatable instead of a one-time manual `gpresult` exercise.

---

## Objectives

The primary goals of this lab are to:

- enumerate every Group Policy Object in the domain with its status, creation and modification times, and configuration-side enablement, without opening the Group Policy Management Console
- report, per organizational unit, which GPOs are linked, whether each link is enabled and enforced, the order of precedence, and whether inheritance is blocked
- produce a Resultant Set of Policy report for WIN11-CLIENT01 that shows which GPOs actually apply to a specified user and computer, including any denied GPOs, rather than assuming the intended design is what is applied
- keep all three scripts read-only with respect to Group Policy: reporting and RSoP generation only, with no cmdlet capable of creating, linking, unlinking, or modifying a GPO anywhere in the lab
- reuse the reporting-output convention established in Lab 02 (formatted console table plus an optional `-ExportPath` CSV) wherever the data is tabular, so this lab extends an existing pattern rather than inventing a new one
- cross-check each report's output against the documented Group Policy design from enterprise infrastructure Lab 05, confirming the scripts report the real state rather than trusting their own output

---

## Project Context

The enterprise infrastructure track built the Group Policy environment this lab reports on. Lab 05 (Group Policy Lab) created three purpose-built GPOs, linked each to a target OU, and validated them once, by hand, using `gpresult /r` and Resultant Set of Policy in both a `testuser01` and a `labadmin` session:

- `Workstation-Security-Baseline`, linked to `OU=Workstations`, User Configuration disabled, security filtering switched from `Authenticated Users` to `Lab-Workstations`
- `Standard-User-Environment`, linked to `OU=User Accounts`, Computer Configuration disabled
- `IT-Admin-Environment`, linked to `OU=IT`, Computer Configuration disabled

That validation was a single manual checkpoint. Nothing in the environment currently answers the same questions repeatably: which GPOs exist and what state they are in, where each is linked and in what precedence, and what actually resolves onto WIN11-CLIENT01 for a given user. Reproducing that today means opening the Group Policy Management Console and clicking through it, or re-running `gpresult` interactively per user. Both are exactly the manual overhead ADR-015 scoped this track to eliminate.

This lab also continues a pattern the track depends on. Lab 02 established the reporting shape this track expects later labs to reuse: a formatted console table by default, with an optional CSV export for point-in-time record keeping. This lab reuses that shape for its tabular reports and extends it to Group Policy, and Lab 05 (Scheduled Health Reporting) is expected to fold GPO and RSoP state into a scheduled report built on the same reporting precedent. Getting the Group Policy reporting shape right here gives that later lab a pattern to follow rather than one to invent.

---

## Design Decisions

*(These are planning-stage decisions. They may be revised during implementation if a live diagnostic contradicts the reasoning here, in which case the change and its rationale will be documented in the implementation and troubleshooting sections, as Lab 02 did when its Step Five plan went stale.)*

### Three read-only scripts split by reporting concern

**Decision:** The lab will produce three scripts, `Get-LabGPOInventory.ps1`, `Get-LabGPOLinkReport.ps1`, and `Get-LabRSoPReport.ps1`, each answering one distinct question (what GPOs exist, where they are linked, and what actually applies), rather than a single combined Group Policy report.

Group Policy state has three genuinely different shapes. GPO inventory is a flat per-object list. Link and inheritance data is per-OU and hierarchical. Resultant Set of Policy is per-user and per-computer and is sourced from the client, not the directory. Folding all three into one script would produce output that is neither a clean table nor a clean RSoP report, and would couple a directory-side query to a client-side one. Splitting by concern keeps each script's output coherent and matches the one-script-per-workflow granularity Lab 02 used for its three scripts. The tradeoff is three files instead of one, which is consistent with the per-lab script library the track already maintains.

### Reuse Lab 02's console-table-plus-optional-CSV convention for the tabular reports

**Decision:** `Get-LabGPOInventory.ps1` and `Get-LabGPOLinkReport.ps1` will write a formatted table to the console by default and support an optional `-ExportPath` parameter that writes the same data to CSV via `Export-Csv`, exactly as Lab 02's reporting scripts do.

These two scripts report a state rather than validate a change, so the PASS/FAIL model from Lab 01 does not fit them, the same reasoning Lab 02 applied to `Get-LabOUReport.ps1` and `Get-LabAccountInventory.ps1`. Rather than reinvent an output convention, this lab reuses the one Lab 02 already established and validated, which also keeps the track's reporting scripts consistent with one another and gives Lab 05 (Scheduled Health Reporting) a single convention to build on.

### Use native Group Policy report format for RSoP rather than a hand-built table

**Decision:** `Get-LabRSoPReport.ps1` will generate its Resultant Set of Policy output using `Get-GPResultantSetOfPolicy`'s native `-ReportType Html` / `Xml` output rather than flattening RSoP into a console table.

Resultant Set of Policy data is hierarchical (per-GPO, per-setting, with applied and denied GPOs and winning-GPO precedence) and does not reduce cleanly to a flat table without losing the structure that makes it useful. The Group Policy module's own HTML and XML report format is the established representation for this data, is what an administrator would expect to hand to someone else, and is the same format the Group Policy Management Console produces. The tradeoff is that this one script departs from the console-table convention used by the other two, which is a deliberate exception justified by the shape of the data rather than an inconsistency.

### RSoP in logging mode against the live client, not planning-mode modeling

**Decision:** The RSoP report will use logging mode against WIN11-CLIENT01 and a specified user, reporting what actually applied, and will treat planning-mode "what-if" modeling as out of scope for this lab.

The goal of this lab is to confirm that the GPOs designed in enterprise Lab 05 actually resolve onto the real domain-joined client for real accounts, which is precisely what logging mode reports. `Get-GPResultantSetOfPolicy` supports only logging mode; planning-mode modeling requires the Group Policy Management Console and is a different capability aimed at hypothetical scenarios rather than the live environment. Scoping this lab to logging mode matches both the tool's capability and the lab's actual objective, and leaves planning-mode modeling as a possible later addition rather than an unstated gap.

### Script and folder naming

**Decision:** The three scripts will be named `Get-LabGPOInventory.ps1`, `Get-LabGPOLinkReport.ps1`, and `Get-LabRSoPReport.ps1`, stored under `infrastructure/automation-and-scripting/group-policy-reporting-and-audit/`, following the `Verb-LabNoun` naming pattern and per-lab subfolder convention Lab 01 and Lab 02 established.

---

## Technologies Used

- PowerShell 5.1 / Group Policy module (RSAT, to be run from WIN11-CLIENT01, per ADR-016)
- Group Policy cmdlets: `Get-GPO`, `Get-GPOReport`, `Get-GPInheritance`, `Get-GPResultantSetOfPolicy`
- `gpresult.exe` as an independent cross-check for the RSoP report during validation
- `Export-Csv` (PowerShell Utility module) for the tabular reports' optional CSV output
- Active Directory Domain Services (DC01) and AD-integrated DNS
- Existing OU structure: `OU=IT`, `OU=User Accounts`, `OU=Workstations`, `OU=Groups`, and the built-in `OU=Domain Controllers`
- Existing GPOs from enterprise Lab 05: `Workstation-Security-Baseline`, `Standard-User-Environment`, `IT-Admin-Environment`, alongside the built-in `Default Domain Policy` and `Default Domain Controllers Policy`

---

## Architecture or Topology

```text
WIN11-CLIENT01 (RSAT / PowerShell Group Policy module)
        |
        |  Get-LabGPOInventory.ps1     --> optional -ExportPath CSV
        |  Get-LabGPOLinkReport.ps1    --> optional -ExportPath CSV
        |  Get-LabRSoPReport.ps1       --> HTML / XML RSoP report
        |
        |  directory-side queries (GPOs, links, inheritance)
        v
     DC01 (Active Directory Domain Services, SYSVOL, GPOs)
        |
        | GPOs: Workstation-Security-Baseline (-> OU=Workstations, filtered to Lab-Workstations)
        |       Standard-User-Environment     (-> OU=User Accounts)
        |       IT-Admin-Environment          (-> OU=IT)
        v
  RSoP logging mode reads applied policy from the client itself:
  Get-LabRSoPReport.ps1 targets WIN11-CLIENT01 + a specified user
        |
        v
  Validation: report contents cross-checked against the documented
  Lab 05 GPO design and against gpresult, not assumed from the script
```

The inventory and link reports are directory-side: they query GPO objects and OU links from DC01 through the Group Policy module, the same LDAP/Kerberos-backed remote cmdlet behavior used elsewhere in this track. The RSoP report is client-side: logging mode reads what actually applied on WIN11-CLIENT01 for a specified user, so that script targets the client itself rather than the directory. All three originate from WIN11-CLIENT01, consistent with ADR-016.

---

## Prerequisites

- DC01 running Active Directory Domain Services and AD-integrated DNS (Lab 03, enterprise infrastructure track)
- The three GPOs from enterprise Lab 05 deployed, linked, and previously validated: `Workstation-Security-Baseline` (linked to `OU=Workstations`, filtered to `Lab-Workstations`), `Standard-User-Environment` (linked to `OU=User Accounts`), and `IT-Admin-Environment` (linked to `OU=IT`)
- WIN11-CLIENT01 domain-joined with RSAT installed and the Group Policy PowerShell module available; required script execution endpoint per [ADR-016](../architecture/decisions/016-run-automation-scripts-from-domain-joined-client.md)
- Group Policy previously processed on WIN11-CLIENT01 for `testuser01` and `labadmin` (enterprise Lab 05), so logging-mode RSoP data exists on the client to report against
- An account with sufficient permissions to read GPO, link, and RSoP data (`labadmin`)

---

## Implementation Plan

*(Titled "Implementation Plan" during the planning and research phase. It will be renamed to "Implementation" and rewritten in past tense as each step is actually performed, matching the workflow used in Lab 01 and Lab 02.)*

### Step One - Confirm the Group Policy Module and Establish the Known-Good Baseline

Before any report is written, the plan is to confirm the Group Policy PowerShell module is available on WIN11-CLIENT01 (`Import-Module GroupPolicy`) and to capture the current Group Policy state by hand as the known-good baseline that every report in this lab will later be checked against. This baseline is not invented for the lab: it is the design already documented in enterprise Lab 05 (three GPOs, their OU links, and the `Lab-Workstations` security filtering on `Workstation-Security-Baseline`). Recording it explicitly at the start gives the validation step in Step Five a fixed reference to compare each script's output against.

```powershell
Import-Module GroupPolicy
Get-GPO -All | Select-Object DisplayName, GpoStatus, CreationTime, ModificationTime
```

### Step Two - Build Get-LabGPOInventory.ps1

The plan is a read-only inventory script that enumerates every GPO in the domain with `Get-GPO -All` and reports the fields most useful for an at-a-glance audit: `DisplayName`, `Id`, `GpoStatus` (which side of the GPO is enabled), `CreationTime`, and `ModificationTime`. The script will sort by `DisplayName` for stable output, write a formatted console table by default, and support an optional `-ExportPath` for CSV, reusing Lab 02's reporting convention. It will confirm the expected count includes the three Lab 05 GPOs plus the two built-in default policies.

```powershell
$gpos = Get-GPO -All | Sort-Object DisplayName
# report DisplayName, Id, GpoStatus, CreationTime, ModificationTime
# console table by default; optional -ExportPath -> Export-Csv
```

### Step Three - Build Get-LabGPOLinkReport.ps1

The plan is a read-only per-OU link and inheritance report. For each OU in the domain, the script will call `Get-GPInheritance -Target <OU DN>` and report the linked GPOs (`GpoLinks`), the effective inherited order (`InheritedGpoLinks`), whether inheritance is blocked (`GpoInheritanceBlocked`), and per-link enabled and enforced state. This is the report that maps each GPO to where it actually applies, and it is where the `Workstation-Security-Baseline` link on `OU=Workstations`, the `Standard-User-Environment` link on `OU=User Accounts`, and the `IT-Admin-Environment` link on `OU=IT` should surface. OU enumeration will reuse the `Get-ADOrganizationalUnit -Filter *` approach proven in Lab 02's `Get-LabOUReport.ps1`.

```powershell
$ous = Get-ADOrganizationalUnit -Filter * | Sort-Object Name
foreach ($ou in $ous) {
    Get-GPInheritance -Target $ou.DistinguishedName
    # report GpoLinks, InheritedGpoLinks, GpoInheritanceBlocked, enabled/enforced state
}
```

### Step Four - Build Get-LabRSoPReport.ps1

The plan is a Resultant Set of Policy report for WIN11-CLIENT01 in logging mode, using `Get-GPResultantSetOfPolicy -ReportType Html -Path <file>` (with `-User` and `-Computer` as appropriate) to capture what actually applies to a specified user on the client. The expected result, based on enterprise Lab 05, is that `testuser01` resolves `Standard-User-Environment`, `labadmin` resolves `IT-Admin-Environment`, and the computer resolves `Workstation-Security-Baseline`, with any denied GPOs surfaced explicitly.

**Open question to verify during implementation, not assume.** It needs to be confirmed by a live diagnostic, in the same way Lab 02 verified `Add-ADGroupMember`'s array-validation behavior before designing around it, whether `Get-GPResultantSetOfPolicy` run from WIN11-CLIENT01 in logging mode requires the target user to have an active or prior interactive session on the client, and how it behaves for a user who has not recently logged on. `gpresult /r` and `gpresult /h <file>` will be used as an independent cross-check and as a fallback path if the cmdlet's session requirements make it unsuitable for a given account. The design of this script will be finalized around whatever that verification actually shows.

```powershell
Get-GPResultantSetOfPolicy -ReportType Html -Path "C:\Scripts\rsop-testuser01.html" -User "CORP\testuser01" -Computer "CORP\WIN11-CLIENT01"
# independent cross-check / fallback:
# gpresult /r    and    gpresult /h C:\Scripts\rsop-testuser01-gpresult.html
```

### Step Five - Run All Three Reports and Validate Against the Known Group Policy Design

The plan is to run all three scripts and cross-check their output against the Step One baseline and the documented enterprise Lab 05 design, rather than trusting each script's own output. This mirrors the independent-verification approach Lab 01 and Lab 02 used: the inventory's GPO list and the link report's per-OU links will be checked against a standalone `Get-GPO -All` and `Get-GPInheritance` run outside of any script, and the RSoP report will be checked against an independent `gpresult /r` for the same user and computer. Any discrepancy between reported state and the known design will be treated as a finding to investigate, not reconciled silently.

---

## Validation

*To be completed during implementation. This section will record the actual observed results of running each script and cross-checking it against the known Group Policy design and against `gpresult`, following the evidence-based validation approach used in Lab 01 and Lab 02. It will document what was verified, not what was expected.*

---

## Troubleshooting and Adjustments

*To be completed during implementation. This section will document any issues actually encountered, the investigation performed, and the resolution, including the outcome of the RSoP logging-mode session-requirement question raised in Step Four. Anticipated-but-not-encountered items will be recorded as such rather than presented as tested.*

---

## Security Considerations

*(Planned security posture. Where these depend on observed behavior, they will be confirmed during implementation.)*

- **Read-only by design.** All three scripts are planned to use only reporting cmdlets (`Get-GPO`, `Get-GPInheritance`, `Get-GPResultantSetOfPolicy`, `Get-GPOReport`) and `gpresult`. No cmdlet capable of creating, linking, unlinking, or modifying a GPO (for example `New-GPO`, `New-GPLink`, `Set-GPLink`, `Set-GPInheritance`, `Set-GPPermission`) will appear in this lab. A review of the finalized scripts during validation will confirm this, as the equivalent review did for the reporting scripts in Lab 02.
- **Exported reports as a data-handling boundary.** GPO settings reports and RSoP output can contain detailed configuration, applied policy, and security-filtering information. As in Lab 02, any exported report (`-ExportPath` CSV, or the RSoP HTML/XML) is planned to be kept out of the repository and stored only on WIN11-CLIENT01, consistent with treating environment audit output as operational data rather than repository content.
- **Least privilege for the executing account.** As in the prior labs, the scripts are planned to be run as `labadmin`. A production deployment would scope a dedicated account with read-only access to Group Policy and RSoP data rather than the broad administrative identity used in the lab.

---

## Outcome

*To be completed once the lab is implemented and validated. This section will summarize what was actually demonstrated: the reporting and audit capabilities that now exist for the Group Policy environment, and what each script was confirmed to report correctly.*

---

## Lessons Learned

*To be completed once the lab is implemented. This section will capture the operational and architectural lessons actually drawn from the work, including whatever the RSoP logging-mode verification reveals about reporting on applied policy from a domain-joined client.*

---

## Sources

*(Living research log. The references below were consulted during the planning and research phase. Deployment-stage sources will be appended as they come up during implementation and troubleshooting.)*

**Group Policy PowerShell module cmdlets (Microsoft Learn)**

- [Get-GPO](https://learn.microsoft.com/en-us/powershell/module/grouppolicy/get-gpo) - retrieves one GPO or all GPOs in the domain (`-All`, `-Name`, `-Guid`); exposes `DisplayName`, `Id`, `GpoStatus`, `CreationTime`, `ModificationTime`, and `Owner`, which underpin `Get-LabGPOInventory.ps1`
- [Get-GPInheritance](https://learn.microsoft.com/en-us/powershell/module/grouppolicy/get-gpinheritance) - returns per-OU link and inheritance data (`GpoLinks`, `InheritedGpoLinks`, `GpoInheritanceBlocked`) via `-Target <DN>`; the basis for `Get-LabGPOLinkReport.ps1`
- [Get-GPResultantSetOfPolicy](https://learn.microsoft.com/en-us/powershell/module/grouppolicy/get-gpresultantsetofpolicy) - generates a logging-mode RSoP report (`-ReportType Html`/`Xml`, `-Path`, `-User`, `-Computer`); documents that only logging mode is supported and that GPMC is required for planning-mode modeling, which is why this lab scopes RSoP to logging mode
- [Get-GPOReport](https://learn.microsoft.com/en-us/powershell/module/grouppolicy/get-gporeport) - generates an HTML or XML report of a GPO's settings, links, and security filtering (`-ReportType`, `-All`, `-Name`, `-Guid`, `-Path`); held in reserve for settings-level detail if the inventory and link reports need to be supplemented during implementation

**Command-line RSoP cross-check**

- [gpresult](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/gpresult) - `gpresult /r` and `gpresult /h` provide an independent, non-PowerShell view of applied policy, planned as the cross-check and fallback for `Get-LabRSoPReport.ps1` in Step Four and Step Five

**Environment reference (this repository)**

- [05 - Group Policy Lab](../enterprise-infrastructure/05-group-policy-lab.md) - the source of the known-good GPO design (the three GPOs, their OU links, and the `Lab-Workstations` security filtering) this lab's reports will be validated against
- [ADR-015: Establish Infrastructure Automation and Scripting Track](../architecture/decisions/015-establish-infrastructure-automation-and-scripting-track.md) and [ADR-016: Run Automation Scripts from a Domain-Joined Client](../architecture/decisions/016-run-automation-scripts-from-domain-joined-client.md) - the track scope and the execution-endpoint convention this lab operates under

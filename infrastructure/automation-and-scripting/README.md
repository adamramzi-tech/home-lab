# Infrastructure Automation and Scripting

This directory contains the PowerShell script library for the infrastructure automation and scripting track.

---

## Active Lab Artifacts

| Directory | Lab | Description |
|---|---|---|
| `user-lifecycle-automation/` | [01 - User Lifecycle Automation](../../docs/automation-and-scripting/01-user-lifecycle-automation.md) | `New-LabUser.ps1` and `Remove-LabUser.ps1`: scripted AD user provisioning and offboarding with OU placement, group assignment, self-validation, and cross-platform SSH access validation on Ubuntu Server |
| `group-and-ou-administration/` | [02 - Group and OU Administration](../../docs/automation-and-scripting/02-group-and-ou-administration.md) | `Add-LabGroupMembers.ps1`, `Get-LabOUReport.ps1`, and `Get-LabAccountInventory.ps1`: CSV-driven bulk group membership with a partial-success batch model, per-OU user/computer census reporting, and full account inventory reporting, each independently cross-checked against standalone AD queries |
| `group-policy-reporting-and-audit/` | [04 - Group Policy Reporting and Audit](../../docs/automation-and-scripting/04-group-policy-reporting-and-audit.md) | `Get-LabGPOInventory.ps1`, `Get-LabGPOLinkReport.ps1`, and `Get-LabRSoPReport.ps1`: read-only GPO inventory, per-OU link and inheritance reporting, and Resultant Set of Policy reporting, each cross-checked against native Group Policy cmdlets and `gpresult` |
| `scheduled-health-reporting/` | [05 - Scheduled Health Reporting](../../docs/automation-and-scripting/05-scheduled-health-reporting.md) | `Get-LabADServiceHealth.ps1`, `Get-LabWazuhAgentStatus.ps1`, `Get-LabDockerServiceStatus.ps1`, `Invoke-LabHealthReport.ps1`, and `Register-LabHealthReportTask.ps1`: three `Healthy`/`Unhealthy`/`Unknown` health checks over DC01's AD services, Wazuh agent enrollment, and Docker container state, a worst-wins orchestrator that writes a timestamped report on every run, and the script that registers it as an unattended Task Scheduler job |

---

## Testing and Static Analysis

`PSScriptAnalyzerSettings.psd1` at the root of this directory is the analyzer standard [ADR-017](../../docs/architecture/decisions/017-adopt-powershell-static-analysis-and-unit-testing.md) adopted and [Lab 03](../../docs/automation-and-scripting/03-static-analysis-and-unit-testing.md) established. Every script carries a matching `*.Tests.ps1` Pester file beside it rather than in a separate tree, so a lab directory holds both the script and its coverage.

The library is thirteen scripts and thirteen test files. Run together from `C:\Scripts` on WIN11-CLIENT01 at the close of Lab 05, it passed a zero-finding `Invoke-ScriptAnalyzer -Recurse` sweep and 172 of 172 Pester tests. Every external call is mocked, so the suite runs without a live domain, a reachable Wazuh or Portainer API, or credentials of any kind.

The library has been changed once since the track closed. Lab 02 of the Cloud and Hybrid Identity track changed `New-LabUser.ps1` to derive the user principal name suffix from `-TargetOU` rather than hardcoding `@corp.home.arpa`, so accounts created in a synchronized organizational unit receive the routable `@brindeck.com` suffix. `New-LabUser.Tests.ps1` gained a `Context` covering both branches and one existing test was corrected, bringing the suite to 174. The analyzer sweep stayed at zero findings. The change is recorded in [Lab 01](../../docs/automation-and-scripting/01-user-lifecycle-automation.md) as an appended revision section, and its reasoning belongs to [ADR-019](../../docs/architecture/decisions/019-establish-cloud-and-hybrid-identity-track.md).

---

## Notes

Each script is documented in its accompanying lab with purpose, usage, parameters, expected output, and validation steps. Every script in this track runs from WIN11-CLIENT01, per [ADR-016](../../docs/architecture/decisions/016-run-automation-scripts-from-domain-joined-client.md). The Labs 01, 02, and 04 scripts reach DC01 through RSAT's Active Directory and Group Policy modules; the Lab 05 health checks reach it through the Service Control Manager's remote service query instead, and reach Ubuntu Server through the Wazuh Manager and Portainer REST APIs, so no script in the library opens a remote shell anywhere.

No script in this library writes a report artifact, an exported CSV, or a credential file into the repository. Those are runtime outputs and stay on WIN11-CLIENT01, a boundary every lab in the track has held.

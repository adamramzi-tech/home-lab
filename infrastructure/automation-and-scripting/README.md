# Infrastructure Automation and Scripting

This directory contains the PowerShell script library for the infrastructure automation and scripting track.

---

## Active Lab Artifacts

| Directory | Lab | Description |
|---|---|---|
| `user-lifecycle-automation/` | [01 - User Lifecycle Automation](../../docs/automation-and-scripting/01-user-lifecycle-automation.md) | `New-LabUser.ps1` and `Remove-LabUser.ps1`: scripted AD user provisioning and offboarding with OU placement, group assignment, self-validation, and cross-platform SSH access validation on Ubuntu Server |
| `group-and-ou-administration/` | [02 - Group and OU Administration](../../docs/automation-and-scripting/02-group-and-ou-administration.md) | `Add-LabGroupMembers.ps1`, `Get-LabOUReport.ps1`, and `Get-LabAccountInventory.ps1`: CSV-driven bulk group membership with a partial-success batch model, per-OU user/computer census reporting, and full account inventory reporting, each independently cross-checked against standalone AD queries |

---

## Notes

Each script is documented in its accompanying lab with purpose, usage, parameters, expected output, and validation steps. Scripts in this track are run from WIN11-CLIENT01 via RSAT against DC01, per [ADR-016](../../docs/architecture/decisions/016-run-automation-scripts-from-domain-joined-client.md).

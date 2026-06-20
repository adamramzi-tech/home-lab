# Infrastructure Automation and Scripting Track

## Overview

This track operationalizes the Active Directory environment built in the enterprise infrastructure track by replacing manual administrative workflows with repeatable, documented PowerShell scripts.

The environment built across the Linux and enterprise infrastructure tracks is fully operational but entirely manually administered. Every user provisioning task, group membership change, GPO report, and health check currently requires direct tool interaction. This track builds the administrative automation layer that a production environment of this complexity would require.

Active Directory is the center of gravity. It governs authentication across Windows and Linux systems, controls group and OU membership, and is the authoritative identity source for the environment. Automating AD administration produces compounding operational value because every other system in the environment depends on AD for identity.

Docker, Linux, and Wazuh automation appear in this track where they reinforce the AD-centric story: cross-platform validation scripts confirm that AD provisioning produces the expected result on Linux, and health reporting includes Docker service state and Wazuh agent enrollment as supporting checks on the AD-dependent environment.

This track does not introduce new infrastructure. It deepens the operational value of infrastructure that already exists.

---

## Architectural Context

- [ADR-014: Establish Long-Term Infrastructure Expansion Roadmap](../architecture/decisions/014-establish-long-term-infrastructure-expansion-roadmap.md)
- [ADR-015: Establish Infrastructure Automation and Scripting Track](../architecture/decisions/015-establish-infrastructure-automation-and-scripting-track.md)

---

## Prerequisites

This track builds directly on the enterprise infrastructure track. The following must be operational before beginning:

- DC01 running Active Directory Domain Services and AD-integrated DNS
- WIN11-CLIENT01 domain-joined with Group Policy applied and validated
- Ubuntu Server joined to `corp.home.arpa` with SSSD and PAM-based access control operational
- Wazuh Manager, Indexer, and Dashboard running with agents enrolled on all three systems
- Docker infrastructure running on Ubuntu Server

---

## Primary Tooling

- PowerShell with the Active Directory module
- PowerShell with the Group Policy module
- Windows Task Scheduler for recurring automation
- Bash for cross-platform validation steps on Ubuntu Server where appropriate

---

## Labs

| Lab | Focus Area |
|---|---|
| [01 - User Lifecycle Automation](01-user-lifecycle-automation.md) | User provisioning and offboarding scripts covering account creation, group assignment, disablement, and cleanup |
| [02 - Group and OU Administration](02-group-and-ou-administration.md) | Bulk group membership management, OU reporting, and account inventory automation |
| [03 - Group Policy Reporting and Audit](03-group-policy-reporting-and-audit.md) | GPO inventory, RSoP reporting, and policy compliance validation scripts |
| [04 - Cross-Platform Validation](04-cross-platform-validation.md) | End-to-end automation spanning AD provisioning and Linux SSH access validation |
| [05 - Scheduled Health Reporting](05-scheduled-health-reporting.md) | Recurring environment health report covering AD service state, Wazuh agent enrollment, and Docker service status |

---

## Script Library

Completed scripts are maintained in:

```text
infrastructure/automation-and-scripting/
```

Each script is documented with purpose, usage, parameters, expected output, and validation steps.

---

## Track Status

| Lab | Status |
|---|---|
| 01 - User Lifecycle Automation | Planned |
| 02 - Group and OU Administration | Planned |
| 03 - Group Policy Reporting and Audit | Planned |
| 04 - Cross-Platform Validation | Planned |
| 05 - Scheduled Health Reporting | Planned |

---

## Success Criteria

This track is considered complete when:

- a new user can be fully provisioned in AD, assigned to the correct groups and OU, and validated for Linux SSH access by running a single script
- an existing user can be offboarded cleanly, disabled in AD, removed from relevant groups, and confirmed denied on Linux by running a single script
- GPO state and RSoP compliance can be reported on demand without manual intervention
- a scheduled job produces a regular health report covering AD service state, Wazuh agent enrollment, and Docker service status
- all scripts are documented to lab standard: purpose, usage, parameters, expected output, and validation steps
- the `infrastructure/automation-and-scripting/` directory contains a coherent operational script library that can be used without additional context

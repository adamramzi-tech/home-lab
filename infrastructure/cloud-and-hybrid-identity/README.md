# Cloud and Hybrid Identity

This directory will contain the scripts and exported configuration artifacts produced by the cloud and hybrid identity track.

Track scope and design decisions are defined in [ADR-019](../../docs/architecture/decisions/019-establish-cloud-and-hybrid-identity-track.md). Lab documentation is in [docs/cloud-and-hybrid-identity/](../../docs/cloud-and-hybrid-identity/README.md).

---

## Planned Contents

| Directory | Lab | Description |
|---|---|---|
| `hybrid-identity-automation/` | 06 - Hybrid Identity Automation with Microsoft Graph PowerShell | Microsoft Graph PowerShell scripts extending the Track 3 library across the identity boundary, each paired with a Pester test file in the same directory |

Additional directories will be added as labs produce artifacts worth retaining.

---

## Standards

Scripts in this track follow the standards the automation and scripting track established:

- every script runs from WIN11-CLIENT01, per [ADR-016](../../docs/architecture/decisions/016-run-automation-scripts-from-domain-joined-client.md)
- every script carries a matching `*.Tests.ps1` Pester file beside it and passes the analyzer standard defined by [ADR-017](../../docs/architecture/decisions/017-adopt-powershell-static-analysis-and-unit-testing.md)
- every external call is mocked in tests, so the suite runs without a tenant, a live domain, or credentials of any kind

---

## Repository Boundaries

Tenant configuration is performed through administrative portals rather than declared in files, so this directory documents that configuration rather than defining it. That is the reverse of the relationship the Docker compose files have with the Linux infrastructure track, and it means exported configuration here is a record of state rather than a source of it.

Nothing in this directory will contain:

- credentials, client secrets, certificates, or access tokens
- exported user, group, or mailbox data
- report artifacts or runtime output, which stay on WIN11-CLIENT01 as they do in the automation track

Tenant identifiers are redacted where they appear in exported configuration.

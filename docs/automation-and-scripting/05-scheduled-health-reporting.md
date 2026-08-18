# 05 - Scheduled Health Reporting

## Status

Planning and research phase.

This document describes intended work. No scripts have been written, no scheduled task has been registered, and nothing described below has been run against the live environment. It is written in future tense throughout, and any question that cannot be answered from the repository as it stands today is called out explicitly as an open question for the operator and reviewer to confirm before implementation begins.

---

## Overview

This lab will produce the Infrastructure Automation and Scripting track's final deliverable: a recurring, unattended environment health report covering Active Directory service state on DC01, Wazuh agent enrollment across all three monitored systems, and Docker service status on Ubuntu Server, run on a schedule through Windows Task Scheduler rather than invoked by an operator. Per [ADR-018](../architecture/decisions/018-retire-cross-platform-validation-lab.md), Scheduled Health Reporting is the track's fifth and final lab; per [ADR-015](../architecture/decisions/015-establish-infrastructure-automation-and-scripting-track.md), it treats Wazuh agent enrollment and Docker service status as supporting checks on an AD-centric environment, not as parallel automation subjects in their own right.

Every prior lab in this track was operator-invoked: a script is run from `C:\Scripts` on WIN11-CLIENT01, and a human reads the console output or opens the resulting CSV. This lab is the first designed to run with nobody watching. That shift is small in surface area but real in consequence: a report nobody reads while it runs has to represent an unreachable check honestly rather than as a false "all clear" or a false alarm, has to write its result somewhere an operator will find it later rather than to a console that closes when the session ends, and has to run under a stored, unattended credential rather than an interactive administrator's own session. The lab's design decisions below are organized around that shift.

The lab will also close a data-collection gap none of the first four labs had to solve. Every script through Lab 04 queried Active Directory or Group Policy on DC01, reachable from WIN11-CLIENT01 through the Active Directory and Group Policy PowerShell modules' native remote cmdlet behavior, per [ADR-016](../architecture/decisions/016-run-automation-scripts-from-domain-joined-client.md). Wazuh agent enrollment and Docker service status live on Ubuntu Server, which nothing in this track has reached before. How to collect those two signals without introducing a new remoting technology, something ADR-016 explicitly rules out as a matter of routine, is the central design problem this lab has to solve, and it is addressed in the first Design Decision below.

The lab will extend the reporting-output convention Lab 02 established and Lab 04 reused, adding the shape that convention is missing: a self-contained artifact suited to a scheduled job rather than only a console table meant to be read in real time. It will also be the first lab in the track whose Pester coverage mocks something other than an Active Directory or Group Policy cmdlet, extending the mocking pattern Lab 03 established, per [ADR-017](../architecture/decisions/017-adopt-powershell-static-analysis-and-unit-testing.md), to the new external calls this lab introduces.

---

## Objectives

The primary goals of this lab are to:

- check the running state of a defined set of Active Directory-related Windows services on DC01 (`NTDS`, `DNS`, `Netlogon`, `Kdc`, `W32Time`, and `ADWS`, Active Directory Web Services, the service every Active Directory PowerShell module cmdlet this track has depended on since Lab 01 relies on, and therefore the operational backbone of ADR-016's whole execution model) from WIN11-CLIENT01, without RDP into DC01 or opening `services.msc`
- query the Wazuh Manager's REST API for the enrollment and connectivity status of all three enrolled agents (`DC01`, `WIN11-CLIENT01`, `UBUNTU-SERVER`), reusing the same platform enterprise Lab 07 deployed rather than re-deriving agent state some other way
- query an already-deployed, purpose-built Docker management API (Portainer) for the running state of the containers that make up the monitoring, reverse-proxy, and Wazuh stacks on Ubuntu Server, without introducing SSH, WinRM, or any other new remoting technology to reach Ubuntu Server from WIN11-CLIENT01
- classify each individual check as `Healthy`, `Unhealthy`, or `Unknown` (the check itself could not be completed), and aggregate all three into a single overall environment status, so an unreachable host or API is never silently reported as either a false "all clear" or a false incident
- produce a report shaped for an unattended run: a timestamped artifact written automatically to a runtime path on WIN11-CLIENT01 every time the job fires, in addition to the console-table-plus-optional-`-ExportPath` convention Lab 02 established and Lab 04 reused for interactive, operator-invoked runs
- register the finished orchestrating script as a recurring Windows Task Scheduler job on WIN11-CLIENT01, per the track's "Primary Tooling" (Windows Task Scheduler for recurring automation), and resolve, rather than assume, what account and privilege level that job should run under
- author every script in this lab under the Lab 03 static analysis and unit testing standard from the outset, per ADR-017, including Pester coverage of the new Healthy/Unhealthy/Unknown classification and aggregation logic this lab introduces, and mocked coverage of the new non-Active-Directory external calls (`Get-Service -ComputerName`, `Invoke-RestMethod` against the Wazuh and Portainer APIs) that this lab is the first in the track to make
- keep every exported report artifact off the repository and on WIN11-CLIENT01, consistent with the data-handling boundary every prior lab in this track has held
- close the track's final stated success criterion, "a scheduled job produces a regular health report covering AD service state, Wazuh agent enrollment, and Docker service status," and with it, the Infrastructure Automation and Scripting track itself, per [ADR-018](../architecture/decisions/018-retire-cross-platform-validation-lab.md)

---

## Project Context

ADR-014 named Infrastructure Automation and Scripting as the highest-priority next track, and ADR-015 scoped it around Active Directory as the environment's identity backbone, with Docker, Linux, and Wazuh appearing only as supporting checks on the AD-dependent environment. Labs 01 and 02 automated the standing manual AD administration work (user lifecycle, group and OU administration); Lab 03 gave the resulting script library a repeatable quality-assurance standard; Lab 04 automated the last category of manual AD work the track had identified, Group Policy reporting and audit. ADR-018 then retired the originally planned standalone cross-platform validation lab as redundant with work Lab 01 already performed, and made this lab, Scheduled Health Reporting, the track's fifth and final lab.

The environment this lab reports on is fully built and already independently validated once, by hand, in the enterprise infrastructure track. Enterprise Lab 07 deployed the Wazuh stack (Manager, Indexer, Dashboard) on Ubuntu Server and enrolled DC01, WIN11-CLIENT01, and Ubuntu Server itself as agents, all three confirmed `Active` in the dashboard. Linux infrastructure Labs 04 through 07 deployed and progressively integrated the Docker services running on that same host: the monitoring stack (Prometheus, Node Exporter, Grafana), the reverse proxy (NGINX Proxy Manager), and Portainer, all attached to a shared Docker network and, since the reverse proxy lab, reachable through hostname-based routing rather than direct LAN ports. None of that validation is repeatable today without opening the Wazuh dashboard, checking Services on DC01 directly, or reaching Ubuntu Server to check Docker state, each a separate manual step. That gap, an environment whose health nobody can check with one command, is what this lab exists to close, the same category of gap Lab 04 closed for Group Policy state.

This lab also continues the reporting pattern the track has depended on since Lab 02. Lab 02's Design Decisions section named this lab (then numbered differently, see ADR-017 and ADR-018) as an expected future consumer of its console-table-plus-optional-CSV convention, and Lab 04 reused that convention for its two directory-side reports. This lab reuses it again for its individual check scripts, and extends it, for the first time in the track, into a second, unattended report shape, since a console table is only useful to someone who is looking at the console when the job runs.

Because this is the track's terminal lab, per ADR-018, no future automation-track lab depends on the design decisions made here the way, for example, every subsequent lab in this track depended on ADR-016's execution-endpoint convention. That changes how this document treats the one boundary-adjacent decision it has to make, addressed directly in Design Decision 1 below.

---

## Design Decisions

### 1. Reach Ubuntu Server's signals through its existing management APIs, not a new remoting technology

**Decision:** Wazuh agent enrollment status will be collected from the Wazuh Manager's REST API (`https://192.168.1.226:55000`), and Docker container status will be collected from Portainer's REST API (already deployed on Ubuntu Server for exactly this purpose), both queried with `Invoke-RestMethod` from WIN11-CLIENT01. Neither introduces SSH, WinRM, PowerShell Remoting, or any other new remoting technology to reach Ubuntu Server.

This is the lab's central design problem, and it deserves being reasoned through rather than assumed. AD service state is reachable from WIN11-CLIENT01 today because `Get-Service` accepts a `-ComputerName` parameter that, per its own Windows PowerShell 5.1 documentation, "does not rely on Windows PowerShell remoting," the same category of remote-but-not-remoting behavior the Active Directory module's cmdlets already use against DC01 under ADR-016. Wazuh agent enrollment and Docker service status have no equivalent built-in PowerShell surface, since both live on a Linux host this track has never queried from. Four realistic options were considered:

**Option A: Extend the Wazuh channel to cover Docker too, using Wazuh's command monitoring capability.** Wazuh agents support a command-monitoring configuration that periodically runs a local command (for example, `docker ps` or `docker compose ps`) and forwards its output to the manager. This would keep every Ubuntu-side signal behind a single existing channel. It was investigated directly, and the Wazuh documentation is explicit that this is more fragile than it first appears: command output is only made useful through a custom decoder and rule authored on the manager, and "when a decoder is not found, the log is ignored," meaning an unmatched command output does not even land in the archived logs by default, let alone anywhere the Wazuh API can return it. Building and proving a correct custom decoder and rule is real, non-trivial Wazuh-server configuration work whose success cannot be assumed at the planning stage.

**Option B: SSH-invoked `docker`/`docker compose` commands from WIN11-CLIENT01.** Using a PowerShell SSH client (the `Posh-SSH` module, or the built-in Windows OpenSSH client via `ssh.exe`) to run `docker ps` on Ubuntu Server directly and parse its output is the most direct option, and it would reuse infrastructure (SSH, Tailscale) the environment already runs for remote administration generally. It was rejected as the primary approach because it is, plainly, a new remoting technology for this track's scripts specifically: no script in Labs 01 through 04 opens a remote shell or session anywhere, and ADR-016's decision was deliberately framed as "no new remoting technology (PowerShell Remoting, WinRM sessions to DC01, and so on)." ADR-018 rejected a reshaped cross-platform-validation lab for a closely related reason, noting that a genuinely cross-host execution model "departs from ADR-016's 'no new remoting technology' boundary, which would need its own ADR." SSH-invoked commands against Ubuntu Server are the same category of departure this lab does not need to make if another option covers the same ground within the existing boundary.

**Option C: A companion script that runs locally on Ubuntu Server.** A Bash script or cron job on Ubuntu Server writing its own status output somewhere retrievable was considered and rejected quickly. It falls outside this track's PowerShell-centered scope per ADR-015, and it does not actually solve the collection problem, since the result still has to get from Ubuntu Server back to WIN11-CLIENT01 by some channel, which only pushes the same question one step further without answering it.

**Option D: Portainer's existing REST API.** Portainer is already deployed on Ubuntu Server specifically to manage Docker containers, and its API (`POST /api/auth` for a JWT, `GET /api/endpoints/{id}/docker/containers/json` for live container state) is a purpose-built, already-running source of exactly the signal this lab needs. Reaching it from WIN11-CLIENT01 requires no new Wazuh-server configuration, no custom decoder or rule, and no new remoting technology, only an authenticated HTTPS query of the same kind the Wazuh API call already makes, and the same kind the Active Directory module's cmdlets already make against DC01 under LDAP/Kerberos. It also avoids Option A's specific failure mode, silent data loss when no decoder matches, since Portainer's container-listing endpoint is definitionally the tool's core function rather than a repurposed side channel.

**The environment's own architecture is a real threat to Options A and D, and has to be weighed before either is recommended.** Both options ultimately depend on reaching the Wazuh Manager API from WIN11-CLIENT01, and Option D additionally depends on reaching Portainer's API, and this environment has a documented history of exactly this kind of backend API becoming unreachable once centralized ingress was enforced. ADR-009 moved backend services, including Portainer, to internal-only Docker networking with no direct LAN-accessible ports, reachable only through NGINX Proxy Manager's hostname-based routing; the reverse proxy lab's own validation confirmed direct access to Portainer's port `9443` blocked once that transition was complete. ADR-013 then excluded the Wazuh Dashboard from NGINX Proxy Manager entirely, after proxying it produced authorization-token failures and API errors (Error 3002, HTTP 429) on the proxied request path that were never conclusively resolved, even though direct-IP access to the dashboard and JWT generation against the Manager API itself continued to work throughout. That is a direct precedent, in this same environment, for the reverse-proxy path specifically breaking token-authenticated API calls while direct-IP access to the same services kept working. The two APIs sit in different positions, and the plan should not blur them. Portainer no longer has a direct LAN-accessible port at all: ADR-009 removed it and the reverse proxy lab confirmed direct access to `192.168.1.226:9443` fails, so the Portainer check's only available path is `portainer.local` through NGINX Proxy Manager, precisely the proxied, token-authenticated path ADR-013 showed can break. The Wazuh Manager API is the opposite case: direct-IP access to the Wazuh stack historically worked while proxying broke it, so the open question there is narrower, whether port `55000` is actually published on the Ubuntu Server host and reachable across the LAN from WIN11-CLIENT01, not whether a proxy will interfere. Whether either API is reachable from WIN11-CLIENT01 is therefore unconfirmed, for different reasons, and both must be verified in Implementation Step One before Design Decision 1's recommendation is treated as settled. A negative result here would not be a minor firewall adjustment: it would invalidate Option D (and the Wazuh Manager API leg of Option A) as planned, and would force falling back to Option B or reconsidering an Ubuntu-Server-side check along the lines of Option C. This is treated as this lab's primary open reachability question, to be confirmed or refuted directly in Implementation Step One, before the four-script design in Design Decision 2 is finalized, not assumed away at the planning stage.

**Recommendation, pending confirmation of reachability: Option D for Docker service status, alongside the Wazuh Manager API for agent status.** Both are read-only queries against management APIs the environment already runs for their own stated purposes, neither opens a session or a shell on a remote host, and neither requires new server-side configuration whose correctness is unproven. This is the plan of record, but it is contingent, not settled: given the reachability risk above, it holds only if Implementation Step One actually confirms both API endpoints are reachable from WIN11-CLIENT01 before the four-script design is locked in. If Step One finds either API unreachable, this is where the fallback lands: Option B (SSH) is recorded here as that fallback, and if it is ever adopted, it should be documented as its own ADR-019 at that time, consistent with ADR-016's own reassessment trigger ("the automation track expands to require... a jump-host/PAW-style model") and with the precedent ADR-018 set when it flagged this exact category of departure as needing its own ADR.

**Whether this decision itself needs an ADR, or belongs here as an in-lab Design Decision:** it belongs here. Two things distinguish this case from ADR-016 and from the departure ADR-018 declined to build. First, the recommended approach (querying an existing management API) is not actually a departure from ADR-016's boundary in the first place; it is the same category of remote-but-not-remoting behavior the AD module and `Get-Service -ComputerName` already use, just against a different endpoint. There is nothing here that needs elevating to ADR status because nothing here crosses the line ADR-016 drew. Second, ADR-016 was written explicitly to apply forward, to "every subsequent lab in this track"; this lab has no subsequent lab in the track to bind, per ADR-018. An ADR recorded now would have no future lab to govern. If the SSH fallback is ever actually adopted, that decision would cross the ADR-016 boundary for real, and it should get its own ADR-019 at that point, not preemptively here.

### 2. Three focused check scripts plus one orchestrating script, not one combined script

**Decision:** The lab will produce four scripts: `Get-LabADServiceHealth.ps1`, `Get-LabWazuhAgentStatus.ps1`, and `Get-LabDockerServiceStatus.ps1`, each independently runnable and each answering one question about one data source, plus `Invoke-LabHealthReport.ps1`, a thin orchestrator that calls all three, aggregates their results, and is the one script actually registered in Task Scheduler. All four will be stored under `infrastructure/automation-and-scripting/scheduled-health-reporting/`, following the `Verb-LabNoun` naming pattern and per-lab subfolder convention every prior lab in the track established.

This follows the one-script-per-workflow granularity Lab 02 and Lab 04 both used, for the same reason Lab 04 gave for its own three-way split: the three data sources have genuinely different shapes and genuinely different failure modes, a Windows service query, an authenticated REST call to a SIEM, and an authenticated REST call to a container manager, and folding all three into one script would couple three unrelated external dependencies into one hard-to-test unit. Keeping them separate also means each check remains independently useful outside the scheduled context; an operator troubleshooting only the Wazuh side of the environment can run `Get-LabWazuhAgentStatus.ps1` alone, the same way Lab 04's three scripts remain independently useful outside a full Group Policy audit.

An orchestrator is not optional overhead here, unlike a case where three independent reports could simply be listed side by side in a track README. Task Scheduler needs one action pointing at one script, and this lab's whole point is a single aggregated status, not three unrelated console tables an operator would have to reconcile by hand after the fact. `Invoke-LabHealthReport.ps1` is deliberately kept thin: it calls the three check scripts, applies the aggregation logic from Design Decision 4, and handles the report-writing behavior from Design Decision 3. It is not where the classification logic itself will live; each check script owns its own Healthy/Unhealthy/Unknown determination for its own data source, the same separation of concerns Lab 02's grouped-CSV design and Lab 04's three-way split both used to keep each script's decision logic locally testable rather than centralized somewhere harder to reason about.

How the orchestrator actually calls the three check scripts is also being settled here, as an explicit decision, since it determines whether Design Decision 6's planned aggregation testing is even possible. Every script in Labs 01 through 04 is a standalone `.ps1` file invoked by its file path (for example, `.\Get-LabOUReport.ps1`), and none of those scripts ever calls another script programmatically. Pester's `Mock` intercepts a command by name; it cannot readily intercept a call made by explicit relative file path, since that bypasses PowerShell's normal command resolution. To keep `Invoke-LabHealthReport.ps1`'s aggregation logic testable in isolation, each of the three check scripts is planned to define a function of the same name as its file (for example, `Get-LabADServiceHealth.ps1` defining `function Get-LabADServiceHealth { ... }`), dot-sourced by the orchestrator and invoked by that function name rather than executed as a separate file. This is a small but real departure from the flat, standalone-script convention every prior lab in this track used, introduced specifically because this is the first lab where one script's logic is composed from calling three others, a composition none of Labs 01 through 04 needed. The tradeoff is one additional layer of structure, a dot-sourced function per script rather than a script that only ever runs standalone, accepted for the sake of making the orchestrator's own aggregation logic mockable and testable under ADR-017.

### 3. Keep the existing reporting convention for interactive runs, add a mandatory timestamped artifact for the unattended run

**Decision:** The three individual check scripts will follow Lab 02's and Lab 04's console-table-plus-optional-`-ExportPath` convention when run standalone. `Invoke-LabHealthReport.ps1` will additionally always write a timestamped aggregate report to a runtime directory on WIN11-CLIENT01 (planned as an HTML summary, matching Lab 04's precedent of departing from a flat table when the data's shape, here three different check types rolled into one overall status, does not reduce cleanly to a single CSV row) every time it runs, whether invoked by an operator or by Task Scheduler.

Every report in this track so far has been read by the person who just ran the script. This lab's whole premise is that nobody will be watching when the report runs, so an optional `-ExportPath` the way Lab 02 and Lab 04 use it, present only if an operator remembers to ask for it, is the wrong default here: if the scheduled run does not write something durable by default, an unhealthy night produces nothing for anyone to find the next morning. The individual check scripts keep the existing optional-export convention because they remain genuinely interactive tools an operator might run by hand; the orchestrator's always-write behavior is the one deliberate departure this lab makes from the established pattern, and it is departing for a reason specific to this lab's unattended nature rather than inventing a new convention for its own sake.

### 4. Health determination: a three-state classification with worst-wins aggregation

**Decision:** Each check script will classify its result as `Healthy`, `Unhealthy`, or `Unknown`. `Unknown` is reserved specifically for "the check itself could not be completed" (DC01 unreachable, a Wazuh or Portainer authentication failure, a request timeout), distinct from `Unhealthy`, which means the check completed and found a real problem (a stopped service, a disconnected agent, a stopped container). `Invoke-LabHealthReport.ps1` aggregates the three per-check results into one overall status using a worst-wins rule: any `Unhealthy` check makes the overall status `Unhealthy`, regardless of the other two; failing that, any `Unknown` check makes the overall status `Unknown`; only if all three checks report `Healthy` is the overall status `Healthy`.

This is the actual decision logic of the lab and the natural center of its Pester coverage, the same way the partial-success batch model was the real logic Lab 02's tests targeted and the RSoP session requirement was Lab 04's. A two-state model, Healthy or Unhealthy, would force every check to collapse an unreachable host into one of the two real outcomes, and either direction is a real failure mode for an unattended job: collapsing "could not reach the Wazuh API" into `Healthy` produces a false all-clear nobody catches until something is actually wrong and the report still reads green; collapsing it into `Unhealthy` produces a false incident indistinguishable from a genuinely stopped service, which erodes trust in the report the same way a noisy alert erodes trust in monitoring generally. Keeping `Unknown` as its own state, and treating it as worse than `Healthy` but not automatically as bad as a confirmed `Unhealthy`, is the more honest representation for a report nobody is present to sanity-check in real time, and it is the property this lab's Pester suite will exercise most directly: every combination of the three checks' possible states feeding into the aggregator, not just the two happy-path cases.

### 5. Scheduling: `Register-ScheduledTask` on WIN11-CLIENT01, with the run-as account and cadence left as explicit open questions

**Decision (partial; two items below are open questions, not settled decisions):** `Invoke-LabHealthReport.ps1` will be registered as a Windows Task Scheduler job on WIN11-CLIENT01 using `Register-ScheduledTask`, built from `New-ScheduledTaskAction`, `New-ScheduledTaskTrigger`, and `New-ScheduledTaskPrincipal`, consistent with the track's "Primary Tooling" (Windows Task Scheduler for recurring automation). A daily trigger is planned as the default cadence; the exact time of day is not yet fixed and will be settled during implementation.

Two things about this step are genuinely undecided, in the same spirit as Lab 04's RSoP session-requirement question, and are recorded here rather than assumed:

**What account should the task run as?** Every script in this track so far has been run interactively as `labadmin`, an account with Domain Admins membership, by an operator who explicitly started the session. A scheduled task that runs unattended under a stored credential is a materially different exposure: the credential sits on disk (or in the Task Scheduler credential store) indefinitely rather than existing only for the length of an interactive session, and it runs whether or not anyone is paying attention. The default recommendation is to continue using `labadmin`, for consistency with every script this track has produced and because the checks this lab performs are all read-only. The alternative, worth the operator's and reviewer's explicit confirmation before implementation, is a dedicated, least-privileged scheduled-task account: read access to the target services on DC01, a read-only Wazuh API role, and a read-only Portainer API role, provisioned the same way Lab 01's `New-LabUser.ps1` already provisions accounts. Labs 02 and 04 both noted that "a production deployment would scope a dedicated account... rather than the broad administrative identity used in the lab" as an aside in Security Considerations; this lab is the first where that aside describes a standing, unattended exposure rather than a session-scoped convenience, which is why it is raised here as an open question rather than repeated as the same aside.

**Elevation and non-interactive behavior.** Lab 04 discovered, by live diagnostic rather than assumption, that `Get-GPResultantSetOfPolicy` required an elevated session. Whether `Get-Service -ComputerName` against DC01 has any equivalent requirement, and whether Task Scheduler's non-interactive execution context (no console, `Write-Host` output with nowhere to go) affects any of the three check scripts' behavior, is unverified at the planning stage and will be tested directly in Step One of Implementation before any script is finalized, the same way Lab 04 resolved its open question with a live diagnostic before writing `Get-LabRSoPReport.ps1`'s error handling.

### 6. Testing approach: extend Lab 03's mocking pattern to non-Active-Directory external calls for the first time

**Decision:** Pester coverage for this lab will mock `Get-Service` (for the AD service check), `Invoke-RestMethod` (for both the Wazuh and Portainer checks), and each check script's own output (for the orchestrator's aggregation logic), using the same `Mock` mechanism Lab 03 established for Active Directory cmdlets, applied to new command names rather than a new testing approach.

Every mocked test in this track through Lab 04 replaces an Active Directory or Group Policy cmdlet. This lab is the first whose scripts call nothing from either module, so it is worth being explicit that this is new ground only in the sense of new commands to mock, not a new testing technique: Pester's `Mock` works against any command a script calls, and `Get-LabADServiceHealth.Tests.ps1` mocking `Get-Service` or `Get-LabWazuhAgentStatus.Tests.ps1` mocking `Invoke-RestMethod` will follow the identical pattern Lab 03 documented for `Get-ADUser` or `Get-ADGroupMember`, just returning a fabricated service list or a fabricated JSON response instead of a fabricated AD object. The highest-value target for coverage is `Invoke-LabHealthReport.ps1`'s aggregation logic from Design Decision 4, since it is pure logic with no external dependency of its own: every combination of the three checks' Healthy/Unhealthy/Unknown states can be exercised deterministically by mocking the three check functions by name (per the dot-sourced function design in Design Decision 2, which is what makes them mockable at all) rather than their underlying cmdlets. Each individual check script's own tests will assert its classification mapping directly, for example that a mocked `Get-Service` result of `Stopped` maps to `Unhealthy` and a mocked `Invoke-RestMethod` that throws maps to `Unknown`, echoing the try/catch-driven failure-message testing pattern `Get-LabRSoPReport.Tests.ps1` already used in Lab 04 for a non-Active-Directory-shaped failure.

### 7. Validation approach: an independent source per signal, deliberately not the same API a script queries

**Decision:** Each reported signal will be cross-checked, during implementation, against a source outside the script that reported it: AD service state against a direct interactive query of the same services on DC01; Wazuh agent status against the Wazuh dashboard's Agents view (`https://192.168.1.226:8443`); and Docker container status against a direct `docker ps` or `docker compose ps` run interactively on Ubuntu Server, not solely against the Portainer UI.

This continues the rule the track has held since Lab 01, that no script's own success message is trusted without an independent check, but it is worth naming a subtlety specific to this lab. For the AD and Wazuh checks, an independent source is straightforward: `Get-Service` run directly against DC01, or the Wazuh dashboard, are genuinely separate observation paths from the script's own query. For Docker, the more obvious "independent" check, opening the Portainer UI, is not actually independent of `Get-LabDockerServiceStatus.ps1`'s own data source, since both the script and the Portainer UI read from the same Portainer-tracked state. The plan is therefore to validate the Docker check against a raw `docker ps`/`docker compose ps` run directly on Ubuntu Server over the existing SSH access path (used here only as a manual validation step by the operator, not by any script, so it does not conflict with Design Decision 1's boundary), which is a genuinely separate observation of the same underlying Docker Engine state rather than a second read of the same intermediary.

---

## Technologies Used

- PowerShell 5.1 (WIN11-CLIENT01, per [ADR-016](../architecture/decisions/016-run-automation-scripts-from-domain-joined-client.md))
- `Get-Service` with `-ComputerName` (`Microsoft.PowerShell.Management`), targeting DC01's `NTDS`, `DNS`, `Netlogon`, `Kdc`, `W32Time`, and `ADWS` services
- `Invoke-RestMethod` (`Microsoft.PowerShell.Utility`) against the Wazuh Manager REST API and the Portainer REST API
- Wazuh 4.14.5 (Manager, Indexer, Dashboard, Agents), deployed in enterprise Lab 07; Manager REST API on port `55000`, JWT authentication via `POST /security/user/authenticate`
- Portainer Community Edition, deployed on Ubuntu Server in linux infrastructure Lab 04 (Docker Setup) and later migrated to internal-only, reverse-proxy-routed access in linux infrastructure Lab 07 (Reverse Proxy Lab); REST API authentication via `POST /api/auth`, container listing via `GET /api/endpoints/{id}/docker/containers/json`
- Windows Task Scheduler / the `ScheduledTasks` module: `Register-ScheduledTask`, `New-ScheduledTaskAction`, `New-ScheduledTaskTrigger`, `New-ScheduledTaskPrincipal`
- PSScriptAnalyzer 1.25.0 and Pester 5.6.1, the standard established in Lab 03, applied to all four new scripts from the outset
- The Docker Compose stacks already running on Ubuntu Server: the monitoring stack (`prometheus`, `node-exporter`, `grafana`), the reverse proxy (`nginx-proxy-manager`), the standalone `portainer` container, and the Wazuh stack (`wazuh-manager`, `wazuh-indexer`, `wazuh-dashboard`); the exact expected container set will be confirmed against a live `docker ps`/`docker compose ls` baseline in Step One rather than assumed purely from documentation
- Active Directory Domain Services (DC01) and the services this lab checks, not the Active Directory PowerShell module itself, which none of this lab's scripts call

---

## Architecture or Topology

```text
WIN11-CLIENT01 (PowerShell 5.1)
        |
        |  Get-LabADServiceHealth.ps1     ---> Get-Service -ComputerName DC01
        |  Get-LabWazuhAgentStatus.ps1    ---> Invoke-RestMethod (Wazuh Manager API)
        |  Get-LabDockerServiceStatus.ps1 ---> Invoke-RestMethod (Portainer API)
        |          |            |            |
        |          v            v            v
        |     [Healthy / Unhealthy / Unknown, per check]
        |
        |  Invoke-LabHealthReport.ps1 (orchestrator)
        |      --> aggregates the three checks (worst-wins)
        |      --> console table (interactive runs)
        |      --> timestamped report file (every run, per Design Decision 3)
        |
        |  Registered as a Task Scheduler job (Register-ScheduledTask),
        |  run-as account and cadence resolved during implementation
        v
   +-------------------------------+       +---------------------------------------+
   |  DC01 (192.168.1.10)          |       |  Ubuntu Server (192.168.1.226)         |
   |  NTDS, DNS, Netlogon, Kdc,    |       |  Wazuh Manager API :55000              |
   |  W32Time, ADWS services       |       |  Portainer API                         |
   |  (queried directly, no        |       |  Docker: prometheus, node-exporter,    |
   |   PowerShell remoting)        |       |  grafana, nginx-proxy-manager,         |
   |                               |       |  portainer, wazuh-manager,             |
   |                               |       |  wazuh-indexer, wazuh-dashboard        |
   +-------------------------------+       +---------------------------------------+

  Validation: each signal cross-checked against an independent source
  outside the script that reported it (direct DC01 query, Wazuh dashboard,
  and a raw docker ps/docker compose ps on Ubuntu Server, not the Portainer
  UI), not trusted from the script's own output alone.
```

All four scripts originate from WIN11-CLIENT01, consistent with ADR-016. No script in this lab opens a session or a shell on DC01 or Ubuntu Server; every cross-host signal is collected through a query against an already-running service (Windows's own remote service query, or an authenticated REST call), not through remote command execution.

---

## Prerequisites

- Labs 01 through 04 of this track complete, including the script library under `infrastructure/automation-and-scripting/` and the PSScriptAnalyzer/Pester standard established in Lab 03
- DC01 running the target services (`NTDS`, `DNS`, `Netlogon`, `Kdc`, `W32Time`, `ADWS`) and reachable from WIN11-CLIENT01; the network path used by `Get-Service -ComputerName` (the Service Control Manager's remote RPC interface, distinct from PowerShell Remoting) has not yet been explicitly confirmed open between the two hosts and will be validated in Step One
- WIN11-CLIENT01 as the script execution endpoint per [ADR-016](../architecture/decisions/016-run-automation-scripts-from-domain-joined-client.md)
- The Wazuh stack operational with all three agents enrolled and previously confirmed `Active` (enterprise Lab 07), and API credentials available. Whether the Manager REST API (`192.168.1.226:55000`) is actually reachable from WIN11-CLIENT01 is a gating prerequisite, not an assumption: it must be confirmed, not merely believed likely, before Design Decision 1's recommendation can be treated as settled, given that ADR-013 excluded the Wazuh Dashboard from NGINX Proxy Manager specifically because proxying it broke its own token-authenticated calls to this same Manager API, an unresolved precedent in this environment
- Portainer running on Ubuntu Server, with API credentials (or an access token) available. Portainer has no direct LAN-accessible port at all: ADR-009 removed it, and the reverse proxy lab's own validation confirmed direct access to `192.168.1.226:9443` fails, so `portainer.local` through NGINX Proxy Manager is its only access path. Whether that proxied, token-authenticated path is actually reachable from WIN11-CLIENT01 is a gating prerequisite rather than an assumption, precisely the kind of path ADR-013 showed can break
- PSScriptAnalyzer 1.25.0 and Pester 5.6.1 already installed on WIN11-CLIENT01 (Lab 03), and `PSScriptAnalyzerSettings.psd1` already committed to the repository
- The `ScheduledTasks` module, built into Windows and available on WIN11-CLIENT01 without additional installation
- A resolved answer to the run-as-account open question in Design Decision 5 before the scheduled task is actually registered

---

## Implementation

### Step One - Confirm Reachability and Establish a Known-Good Baseline (planned)

Before any script is written, the plan is to confirm each data source is reachable from WIN11-CLIENT01 and to capture the current state of each as the baseline every later check will be validated against, the same posture Lab 04's Step One took toward the Group Policy environment. This means confirming `Get-Service -ComputerName DC01 -Name NTDS,DNS,Netlogon,Kdc,W32Time,ADWS` succeeds and returns the expected six services in a running state; confirming a Wazuh API authentication call (`POST /security/user/authenticate`) succeeds and that a subsequent `GET /agents` call returns all three agents as `active`; and confirming a Portainer API authentication call succeeds and that a container-listing call returns the expected container set. This step is also where the two open items from Design Decision 5, whether either PowerShell 5.1 API call needs any TLS accommodation for the self-signed certificates the Wazuh stack uses (`Invoke-RestMethod` on PowerShell 5.1 has no `-SkipCertificateCheck` parameter, unlike PowerShell 7; a certificate-validation callback workaround may be needed and will be confirmed here rather than assumed), and whether `Get-Service -ComputerName` against DC01 requires any elevation, will be investigated directly.

Confirming reachability of the Wazuh Manager API and the Portainer API is a gate on the rest of the lab, not a formality. Per Design Decision 1, the internal-only-backend posture ADR-009 established, and the proxy-related API failures ADR-013 documented for the Wazuh Dashboard, mean this environment has real precedent for exactly this kind of API becoming unreachable once centralized ingress is enforced. The four-script design in Design Decision 2 is not finalized until this step confirms both endpoints are actually reachable from WIN11-CLIENT01, directly or through the reverse proxy. If either is found unreachable, the plan does not proceed with `Get-LabWazuhAgentStatus.ps1` or `Get-LabDockerServiceStatus.ps1` as currently designed; it falls back per Design Decision 1, to Option B (SSH), documented as its own ADR-019 if adopted, or to reconsidering an Ubuntu-Server-side check.

### Step Two - Build Get-LabADServiceHealth.ps1 (planned)

Planned to accept an optional `-ComputerName` parameter (default `DC01`) and a `-ServiceName` parameter (default the six-service list above), query each service's `Status` via `Get-Service -ComputerName`, and classify the check as `Healthy` if every named service reports `Running`, `Unhealthy` if the query succeeds but any service is not `Running`, and `Unknown` if the query itself fails (host unreachable, access denied, or any other terminating error). Output planned as a `PSCustomObject` carrying the check name, target, per-service detail, and the overall classification for that check, consumed by `Invoke-LabHealthReport.ps1`. Pester coverage planned to mock `Get-Service` and assert the three classification branches directly, following Lab 03's mocking pattern per Design Decision 6.

### Step Three - Build Get-LabWazuhAgentStatus.ps1 (planned)

Planned to accept the Wazuh Manager's base URI and API credentials, authenticate via `POST /security/user/authenticate` to obtain a JWT, and query `GET /agents` for the three enrolled agents' status. Classification planned as `Healthy` if all three agents report `active`, `Unhealthy` if the query succeeds but any agent reports `disconnected` or `never_connected`, and `Unknown` if authentication or the query itself fails. Pester coverage planned to mock `Invoke-RestMethod` for both the authentication call and the agent-status call, asserting the classification mapping and that credentials are never written to the console or the report output.

### Step Four - Build Get-LabDockerServiceStatus.ps1 (planned)

Planned to accept the Portainer base URI, endpoint ID, and API credentials, authenticate via `POST /api/auth`, and query `GET /api/endpoints/{id}/docker/containers/json` for the containers confirmed present in Step One. Classification planned as `Healthy` if every expected container reports a running state, `Unhealthy` if the query succeeds but any expected container is stopped or missing, and `Unknown` if authentication or the query itself fails. Pester coverage planned to mirror Step Three's approach, mocking `Invoke-RestMethod` rather than reaching Ubuntu Server.

### Step Five - Build Invoke-LabHealthReport.ps1, the Orchestrator (planned)

Planned to dot-source the three check scripts and call their functions by name, per the invocation design in Design Decision 2, apply the worst-wins aggregation from Design Decision 4, print a console table when run interactively, and always write a timestamped report (planned as HTML) to a `-ReportDirectory` parameter, per Design Decision 3. Pester coverage planned to be the most extensive in this lab, exercising every combination of the three checks' possible states against the aggregation rule by mocking the three check functions by name rather than their underlying cmdlets, per Design Decision 6, which is only possible because of the function-based invocation Design Decision 2 settles on.

### Step Six - Register the Scheduled Task (planned)

Planned to build a `New-ScheduledTaskAction`, `New-ScheduledTaskTrigger` (daily cadence, exact time to be finalized here), and `New-ScheduledTaskPrincipal` reflecting whichever answer Design Decision 5's open question resolves to, then register the task with `Register-ScheduledTask` on WIN11-CLIENT01. Planned to observe at least one scheduled (not manually triggered) firing before considering this step complete, to confirm the non-interactive execution context behaves as expected, per the second open item in Design Decision 5.

### Step Seven - Run All Checks Live and Validate Against Independent Sources (planned)

Planned to run all four scripts against the live environment, both individually and through a full scheduled firing, and cross-check each reported signal against the independent source named in Design Decision 7. Planned to close with a full combined `Invoke-ScriptAnalyzer -Recurse` and `Invoke-Pester` sweep across the entire script library, all scripts and test files across Labs 01 through 05, the same closing move every prior lab in this track has made.

---

## Validation

Once implemented, this lab will be considered validated when:

- `Get-LabADServiceHealth.ps1`'s reported state for DC01's six target services matches a direct, independent `Get-Service` query against DC01
- `Get-LabWazuhAgentStatus.ps1`'s reported state for all three agents matches the Wazuh dashboard's Agents view at `https://192.168.1.226:8443`
- `Get-LabDockerServiceStatus.ps1`'s reported state for the expected container set matches a direct `docker ps`/`docker compose ps` run on Ubuntu Server, not solely the Portainer UI, per Design Decision 7
- `Invoke-LabHealthReport.ps1`'s aggregated overall status correctly reflects the worst-wins rule from Design Decision 4 across the live run's actual combination of per-check results
- the scheduled Task Scheduler job fires on its configured cadence without an operator present and produces a timestamped report file on WIN11-CLIENT01, not only a console table
- no script in this lab is found, on review, to call anything other than a read-only query (`Get-Service`, or a `GET`/authentication `POST` against the Wazuh and Portainer APIs); nothing in this lab modifies AD, Wazuh, or Docker state
- the full combined script library, all scripts and test files across Labs 01 through 05, passes a clean `Invoke-ScriptAnalyzer -Recurse` sweep and a clean combined `Invoke-Pester` run

Consistent with the rule this track has held since Lab 01, no script's reported result will be accepted from its own output alone; each will be checked against the independent source named in Design Decision 7.

---

## Troubleshooting and Adjustments

Nothing in this lab has been implemented yet, so this section records anticipated risks to watch during implementation, not events that have occurred.

**PowerShell 5.1's `Invoke-RestMethod` has no `-SkipCertificateCheck` parameter.** The Wazuh stack uses self-signed certificates generated by the `wazuh-certs-generator` container (enterprise Lab 07), and Portainer's API may present a similar certificate depending on how it is reached. `-SkipCertificateCheck` is a PowerShell 7+ parameter; Windows PowerShell 5.1 requires a `[System.Net.ServicePointManager]::ServerCertificateValidationCallback` workaround or an equivalent accommodation to call either API over HTTPS without a trusted certificate. This is anticipated to surface in Step One and will need to be resolved before either Wazuh- or Portainer-facing script can be finalized.

**`Get-Service -ComputerName` against DC01 has not been confirmed reachable in this environment.** This parameter relies on the Service Control Manager's remote RPC interface (port 135 plus a dynamic RPC range), not on WinRM or PowerShell Remoting, but nothing in this track has exercised that specific path between WIN11-CLIENT01 and DC01 before. Whether it works without additional firewall configuration is unverified and is planned to be confirmed directly in Step One rather than assumed.

**The expected Docker container set is drawn from documentation, not a live baseline.** The eight-container list in Technologies Used (`prometheus`, `node-exporter`, `grafana`, `nginx-proxy-manager`, `portainer`, `wazuh-manager`, `wazuh-indexer`, `wazuh-dashboard`) is reconstructed from linux infrastructure Labs 06 and 07 and enterprise Lab 07's documentation. The linux infrastructure track's earlier Docker networking lab may have left containers or compose projects still present that are not reflected in this list, or the documented set may have drifted since those labs were written. Step One's live `docker ps`/`docker compose ls` baseline, not this document, is the actual source of truth `Get-LabDockerServiceStatus.ps1` will be built against.

**A stored scheduled-task credential is a new, standing security surface for this track.** Every prior lab's most-privileged operation existed only for the length of an interactive session an operator explicitly started. A scheduled task configured to run whether a user is logged on or not requires a stored credential (via `Register-ScheduledTask -User -Password`, or an equivalent principal configuration) that persists indefinitely. This is not a defect to fix during implementation so much as a property to design around, addressed as an open question in Design Decision 5 and expanded on in Security Considerations below.

**Portainer's endpoint ID is assumed, not confirmed.** Portainer's container-listing endpoint addresses a specific Docker environment by numeric ID (commonly `1` for a single local Docker environment managed by Portainer), which has not been confirmed against this specific deployment. This will be confirmed in Step One before `Get-LabDockerServiceStatus.ps1`'s parameter defaults are finalized.

---

## Security Considerations

- **Read-only by design.** Every call this lab's scripts make is a query: `Get-Service` with no state-changing parameter, and `GET` requests (plus each API's own authentication `POST`) against the Wazuh and Portainer REST APIs. No script in this lab is planned to call anything capable of modifying Active Directory, Wazuh configuration, or Docker container state. As in Lab 04, this claim is intended to be exercised by the Pester suite, not only reviewed by eye, once the scripts exist.
- **A stored, unattended credential is this lab's most significant new exposure.** Every prior lab in this track ran under `labadmin` for the length of an operator-initiated interactive session. A Task Scheduler job configured to run unattended needs a credential that persists on WIN11-CLIENT01 indefinitely, a materially different exposure than a session-scoped one, and the open question in Design Decision 5, whether to continue using `labadmin` or provision a dedicated least-privileged scheduled-task account, is raised here with more weight than the similar "a production deployment would use a dedicated account" aside in Labs 02 and 04, because this lab's version of that aside describes a standing condition of the deployment rather than a convenience taken during a single lab session.
- **API credentials handled the same way Lab 01 handled a plaintext password.** `New-LabUser.ps1` (Lab 01) took its password parameter as a `[SecureString]` rather than plaintext. The Wazuh and Portainer API credentials this lab's scripts need will be handled with the same discipline, sourced from a secure credential store (Windows Credential Manager, or the scheduled task's own stored credential) rather than embedded as plaintext in any script or configuration file.
- **Exported reports as a data-handling boundary.** The timestamped health report and any `-ExportPath` CSV output from the individual check scripts can describe service state, agent connectivity, and container status across the whole environment. As in every prior lab, all of it will be kept out of the repository and stored only on WIN11-CLIENT01.

---

## Outcome

This section describes what the lab is expected to demonstrate once implemented; it will be rewritten in the past tense, describing what was actually built and observed, once implementation is complete, per this repository's documentation conventions.

At the planning stage, the expected outcome is four PowerShell scripts, three focused health checks and one orchestrator, giving the environment a single, on-demand or scheduled answer to "is everything currently healthy," where today that answer requires checking DC01's services, the Wazuh dashboard, and Ubuntu Server's Docker state as three separate manual steps. The lab is expected to close the track's final stated success criterion and, with it, the Infrastructure Automation and Scripting track itself, per ADR-018.

---

## Lessons Learned

Lessons cannot honestly be recorded before this lab has been implemented and run against the live environment; this section will be completed once that work is done. At the planning stage, the questions most likely to produce real lessons, the ones this document has deliberately left open rather than assumed, are the run-as-account decision in Design Decision 5 and whichever of the anticipated risks in Troubleshooting and Adjustments actually turns out to matter once Step One's live reachability checks are run.

---

## Sources

Research references consulted during this lab's planning.

**Wazuh Manager REST API (Wazuh documentation)**

- [Getting started - Wazuh server API](https://documentation.wazuh.com/current/user-manual/api/getting-started.html) - confirms the API's default port (`55000`) and JWT authentication flow (`POST /security/user/authenticate`, `Authorization: Bearer` on subsequent requests), the basis for `Get-LabWazuhAgentStatus.ps1`'s planned authentication step
- [Wazuh server API use cases](https://documentation.wazuh.com/current/user-manual/api/use-cases.html) and [Agent life cycle](https://documentation.wazuh.com/current/user-manual/agents/agent-life-cycle.html) - agent status values (`active`, `disconnected`, `never_connected`, `pending`) this script's classification logic will map to `Healthy`/`Unhealthy`

**Wazuh command monitoring (considered and not adopted as the primary Docker-status path; Design Decision 1)**

- [How it works - Command monitoring](https://documentation.wazuh.com/current/user-manual/capabilities/command-monitoring/how-it-works.html) - documents the command-monitoring pipeline and the requirement for a matching decoder before an event is analyzed
- [Command output analysis - Command monitoring](https://documentation.wazuh.com/current/user-manual/capabilities/command-monitoring/command-output-analysis.html) - the specific finding ("when a decoder is not found, the log is ignored") that informed the decision to prefer Portainer's API over a custom Wazuh decoder/rule for Docker status

**Portainer REST API (Portainer documentation)**

- [API usage examples - Portainer Documentation](https://docs.portainer.io/api/examples) - confirms the authentication endpoint (`POST /api/auth`, JWT), the container-listing endpoint (`GET /api/endpoints/{id}/docker/containers/json`), and the `X-API-Key` header pattern, the basis for `Get-LabDockerServiceStatus.ps1`'s planned design

**PowerShell remote service queries (Microsoft Learn)**

- [Get-Service (Windows PowerShell 5.1)](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/get-service?view=powershell-5.1) - confirms `-ComputerName` is present in Windows PowerShell 5.1 and explicitly "does not rely on Windows PowerShell remoting," the basis for treating this call as consistent with ADR-016's boundary in Design Decision 1

**Windows Task Scheduler (Microsoft Learn)**

- [Register-ScheduledTask](https://learn.microsoft.com/en-us/powershell/module/scheduledtasks/register-scheduledtask) - `-User`/`-Password`/`-Principal` and `-RunLevel` parameters underpinning the run-as-account open question in Design Decision 5
- [New-ScheduledTaskTrigger](https://learn.microsoft.com/en-us/powershell/module/scheduledtasks/new-scheduledtasktrigger) and [New-ScheduledTask](https://learn.microsoft.com/en-us/powershell/module/scheduledtasks/new-scheduledtask) - trigger and task construction this lab's Step Six is planned around

**Repository reference**

- [ADR-015: Establish Infrastructure Automation and Scripting Track](../architecture/decisions/015-establish-infrastructure-automation-and-scripting-track.md) - the track's AD-centric scope and the framing of Wazuh/Docker as supporting checks
- [ADR-016: Run Automation Scripts from a Domain-Joined Client](../architecture/decisions/016-run-automation-scripts-from-domain-joined-client.md) - the "no new remoting technology" boundary Design Decision 1 reasons against
- [ADR-017: Adopt PowerShell Static Analysis and Unit Testing](../architecture/decisions/017-adopt-powershell-static-analysis-and-unit-testing.md) - the testing standard this lab's scripts will be authored against from the outset
- [ADR-018: Retire Cross-Platform Validation as a Standalone Lab](../architecture/decisions/018-retire-cross-platform-validation-lab.md) - establishes this lab as the track's final lab and sets the precedent, discussed in Design Decision 1, for when a cross-host departure from ADR-016 needs its own ADR
- [02 - Group and OU Administration](02-group-and-ou-administration.md) - the source of the console-table-plus-optional-CSV reporting convention this lab reuses and extends
- [04 - Group Policy Reporting and Audit](04-group-policy-reporting-and-audit.md) - the closest structural model for this lab's planning approach, its open-question handling, and its native-report-format precedent
- [07 - Security and Monitoring Lab](../enterprise-infrastructure/07-security-monitoring-lab.md) - the source of the Wazuh deployment facts (version, agent names, manager address and ports) this lab's Wazuh check is built against
- [04 - Docker Setup](../linux-infrastructure/04-docker-setup.md), [06 - Monitoring Stack Lab](../linux-infrastructure/06-monitoring-stack-lab.md), and [07 - Reverse Proxy Lab](../linux-infrastructure/07-reverse-proxy-lab.md) - the source of the Docker container, Portainer deployment, and networking facts this lab's Docker check is built against

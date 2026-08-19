# 05 - Scheduled Health Reporting

## Status

Step One (confirm reachability and establish a known-good baseline), Step Two (build and test `Get-LabADServiceHealth.ps1`), Step Three (build and test `Get-LabWazuhAgentStatus.ps1`), Step Four (build and test `Get-LabDockerServiceStatus.ps1`), and Step Five (build and test `Invoke-LabHealthReport.ps1`, the orchestrator) are complete. Steps Six and Seven remain planning and research; no scheduled task has been registered, and the full-library sweep has not been run.

Step One confirmed, against the live environment, that Design Decision 1's Option D holds: both the Wazuh Manager API and the Portainer API are reachable from WIN11-CLIENT01 and authenticate successfully. Real values discovered during Step One (the Wazuh Manager API's `wazuh-wui` account, the confirmed Portainer endpoint ID, the plain-HTTP `portainer.local` access path, and the live Docker container baseline) now replace the assumptions Design Decision 1, Technologies Used, and Prerequisites previously carried.

Step Two built `Get-LabADServiceHealth.ps1` and its Pester suite, colocated in a new `infrastructure/automation-and-scripting/scheduled-health-reporting/` folder, and confirmed the dot-sourced-function invocation model from Design Decision 2 with a real Pester assertion, ten tests passing, PSScriptAnalyzer clean after a real finding was fixed, and a real live run against DC01 showing `Healthy`. Step Three built `Get-LabWazuhAgentStatus.ps1` alongside it, copying the same dot-sourced-function invocation model and extending Design Decision 6's mocking pattern to the lab's first `Invoke-RestMethod`-based check: fifteen tests passing, PSScriptAnalyzer clean after a real finding was fixed, and a real live run against the Wazuh Manager API showing `Healthy` across all three monitored agents. Step Four built `Get-LabDockerServiceStatus.ps1`, the lab's third and final check script: PSScriptAnalyzer was clean on the first pass against both the script and its test file, an outcome Steps Two and Three did not have, but the first live run surfaced a real defect that a fully passing, sixteen-test Pester suite had not caught, a nested-array response-deserialization bug specific to this endpoint's top-level JSON array shape. That defect was root-caused by live diagnostic, fixed, covered by a seventeenth regression test, and confirmed resolved by a second live run, which returned the `Unhealthy` result Step One's own deliberately-unremediated monitoring-stack outage predicted, `prometheus`, `grafana`, and `node-exporter` reported stopped against an otherwise-healthy environment, the check working as intended rather than a defect. Step Five built `Invoke-LabHealthReport.ps1`, the thin orchestrator that dot-sources the three check scripts at its own top level and calls their functions by name, applies the worst-wins aggregation from Design Decision 4, and produces both a console table and an always-written timestamped HTML report per Design Decision 3. Building its Pester suite surfaced two real, back-to-back Pester authoring defects, not defects in the orchestrator itself, both caught by a real operator run rather than assumed: a twenty-seven-case data-driven aggregation Context that silently produced zero tests because its source data was built inside a `BeforeAll` rather than in the Context body Pester's Discovery phase actually reads, and, once that was fixed, the same twenty-seven cases running but every named variable binding to `$null` because the source data was an array of `PSCustomObject` rather than `Hashtable` entries, which is what Pester's `-ForEach` actually projects into named test variables. Both were fixed and confirmed by a third real run, thirty-eight of thirty-eight tests passing. PSScriptAnalyzer surfaced three real findings, all resolved rather than suppressed: a `PSUseShouldProcessForStateChangingFunctions` warning resolved by renaming the HTML-building helper from a `New-` verb to `ConvertTo-` (the same relationship PowerShell's own `ConvertTo-Html` has to its data), and two `PSUseOutputTypeCorrectly` information findings resolved by adding `OutputType` attributes, one of which needed a second, corrected attempt after the first guessed type did not match the analyzer's own inferred type. A first live-run attempt surfaced one further real defect, in the orchestrator's own interactive guard rather than in Pester or Analyzer coverage: a blank report-directory prompt produced an empty string that failed PowerShell's built-in parameter validation, but that failure was non-terminating at the script level, so execution continued into a garbled, blank summary table instead of stopping cleanly. Fixed by validating all three interactively-resolved inputs explicitly and failing loudly and immediately if any is missing, confirmed by a second attempt that failed cleanly on the same blank input, and only then a genuine live run, which returned the `Unhealthy` overall result the monitoring stack's still-unremediated outage predicted: AD and Wazuh both `Healthy`, Docker `Unhealthy`, worst-wins correctly propagating the one real fault to the overall status. All five steps' own sections below are written in past tense, describing what was actually run and observed; Steps Six and Seven remain written in future tense, since neither has been attempted yet.

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

**Option D: Portainer's existing REST API.** Portainer is already deployed on Ubuntu Server specifically to manage Docker containers, and its API (`POST /api/auth` for a JWT, `GET /api/endpoints/{id}/docker/containers/json` for live container state) is a purpose-built, already-running source of exactly the signal this lab needs. Reaching it from WIN11-CLIENT01 requires no new Wazuh-server configuration, no custom decoder or rule, and no new remoting technology, only an authenticated REST query of the same kind the Wazuh API call already makes, and the same kind the Active Directory module's cmdlets already make against DC01 under LDAP/Kerberos. It also avoids Option A's specific failure mode, silent data loss when no decoder matches, since Portainer's container-listing endpoint is definitionally the tool's core function rather than a repurposed side channel.

**The environment's own architecture is a real threat to Options A and D, and has to be weighed before either is recommended.** Both options ultimately depend on reaching the Wazuh Manager API from WIN11-CLIENT01, and Option D additionally depends on reaching Portainer's API, and this environment has a documented history of exactly this kind of backend API becoming unreachable once centralized ingress was enforced. ADR-009 moved backend services, including Portainer, to internal-only Docker networking with no direct LAN-accessible ports, reachable only through NGINX Proxy Manager's hostname-based routing; the reverse proxy lab's own validation confirmed direct access to Portainer's port `9443` blocked once that transition was complete. ADR-013 then excluded the Wazuh Dashboard from NGINX Proxy Manager entirely, after proxying it produced authorization-token failures and API errors (Error 3002, HTTP 429) on the proxied request path that were never conclusively resolved, even though direct-IP access to the dashboard and JWT generation against the Manager API itself continued to work throughout. That is a direct precedent, in this same environment, for the reverse-proxy path specifically breaking token-authenticated API calls while direct-IP access to the same services kept working. The two APIs sit in different positions, and the plan should not blur them. Portainer no longer has a direct LAN-accessible port at all: ADR-009 removed it and the reverse proxy lab confirmed direct access to `192.168.1.226:9443` fails, so the Portainer check's only available path is `portainer.local` through NGINX Proxy Manager, precisely the proxied, token-authenticated path ADR-013 showed can break. The Wazuh Manager API is the opposite case: direct-IP access to the Wazuh stack historically worked while proxying broke it, so the open question there is narrower, whether port `55000` is actually published on the Ubuntu Server host and reachable across the LAN from WIN11-CLIENT01, not whether a proxy will interfere. Whether either API was reachable from WIN11-CLIENT01 was therefore unconfirmed at the planning stage, for different reasons, and both were verified directly in Implementation Step One before Design Decision 1's recommendation below was treated as settled. Step One confirmed both, though neither was a minor firewall adjustment away from failing: the Wazuh Manager API is reachable at `192.168.1.226:55000` and authenticates once queried with its own dedicated `wazuh-wui` account, distinct from the Dashboard/Indexer login, a distinction Step One had to discover by trial rather than assume; and the Portainer API is reachable, not at `192.168.1.226:9443` (confirmed blocked, matching ADR-009 and the reverse proxy lab), but through `portainer.local` over plain HTTP, which required a manual hosts-file entry on WIN11-CLIENT01 and turned out to be an HTTP-only NGINX Proxy Manager proxy host rather than the HTTPS path originally assumed. Full detail on both diagnostic paths is in Implementation Step One below.

**Recommendation, confirmed by Implementation Step One: Option D for Docker service status, alongside the Wazuh Manager API for agent status.** Both are read-only queries against management APIs the environment already runs for their own stated purposes, neither opens a session or a shell on a remote host, and neither requires new server-side configuration whose correctness is unproven. This is now the plan of record, not a contingent one: Step One confirmed both API endpoints are reachable from WIN11-CLIENT01 and authenticate successfully, so the four-script design in Design Decision 2 is cleared to proceed to Step Two in a later session. Option B (SSH) is retained here as a documented fallback that turned out not to be needed; had Step One found either API unreachable, Option B would have been adopted and documented as its own ADR-019 at that time, consistent with ADR-016's own reassessment trigger ("the automation track expands to require... a jump-host/PAW-style model") and with the precedent ADR-018 set when it flagged this exact category of departure as needing its own ADR.

**Whether this decision itself needs an ADR, or belongs here as an in-lab Design Decision:** it belongs here. Two things distinguish this case from ADR-016 and from the departure ADR-018 declined to build. First, the recommended approach (querying an existing management API) is not actually a departure from ADR-016's boundary in the first place; it is the same category of remote-but-not-remoting behavior the AD module and `Get-Service -ComputerName` already use, just against a different endpoint. There is nothing here that needs elevating to ADR status because nothing here crosses the line ADR-016 drew. Second, ADR-016 was written explicitly to apply forward, to "every subsequent lab in this track"; this lab has no subsequent lab in the track to bind, per ADR-018. An ADR recorded now would have no future lab to govern. If the SSH fallback is ever actually adopted, that decision would cross the ADR-016 boundary for real, and it should get its own ADR-019 at that point, not preemptively here.

### 2. Three focused check scripts plus one orchestrating script, not one combined script

**Decision:** The lab will produce four query scripts: `Get-LabADServiceHealth.ps1`, `Get-LabWazuhAgentStatus.ps1`, and `Get-LabDockerServiceStatus.ps1`, each independently runnable and each answering one question about one data source, plus `Invoke-LabHealthReport.ps1`, a thin orchestrator that calls all three, aggregates their results, and is the one script actually registered in Task Scheduler. All four will be stored under `infrastructure/automation-and-scripting/scheduled-health-reporting/`, following the `Verb-LabNoun` naming pattern and per-lab subfolder convention every prior lab in the track established.

A fifth script, `Register-LabHealthReportTask.ps1`, is added in Step Six to perform the Task Scheduler registration itself, per Design Decision 5. It is deliberately not part of the four-way split reasoned about below, because it is not a health check and does not run on the schedule; it is the one-time registration of the job, kept as a committed script rather than as ad-hoc commands so the task's configuration is reproducible. It is also the track's first state-changing script, and the consequences of that for this lab's read-only claims are handled where those claims are made, in Validation and Security Considerations.

This follows the one-script-per-workflow granularity Lab 02 and Lab 04 both used, for the same reason Lab 04 gave for its own three-way split: the three data sources have genuinely different shapes and genuinely different failure modes, a Windows service query, an authenticated REST call to a SIEM, and an authenticated REST call to a container manager, and folding all three into one script would couple three unrelated external dependencies into one hard-to-test unit. Keeping them separate also means each check remains independently useful outside the scheduled context; an operator troubleshooting only the Wazuh side of the environment can run `Get-LabWazuhAgentStatus.ps1` alone, the same way Lab 04's three scripts remain independently useful outside a full Group Policy audit.

An orchestrator is not optional overhead here, unlike a case where three independent reports could simply be listed side by side in a track README. Task Scheduler needs one action pointing at one script, and this lab's whole point is a single aggregated status, not three unrelated console tables an operator would have to reconcile by hand after the fact. `Invoke-LabHealthReport.ps1` is deliberately kept thin: it calls the three check scripts, applies the aggregation logic from Design Decision 4, and handles the report-writing behavior from Design Decision 3. It is not where the classification logic itself will live; each check script owns its own Healthy/Unhealthy/Unknown determination for its own data source, the same separation of concerns Lab 02's grouped-CSV design and Lab 04's three-way split both used to keep each script's decision logic locally testable rather than centralized somewhere harder to reason about.

How the orchestrator actually calls the three check scripts is also being settled here, as an explicit decision, since it determines whether Design Decision 6's planned aggregation testing is even possible. Every script in Labs 01 through 04 is a standalone `.ps1` file invoked by its file path (for example, `.\Get-LabOUReport.ps1`), and none of those scripts ever calls another script programmatically. Pester's `Mock` intercepts a command by name; it cannot readily intercept a call made by explicit relative file path, since that bypasses PowerShell's normal command resolution. To keep `Invoke-LabHealthReport.ps1`'s aggregation logic testable in isolation, each of the three check scripts is planned to define a function of the same name as its file (for example, `Get-LabADServiceHealth.ps1` defining `function Get-LabADServiceHealth { ... }`), dot-sourced by the orchestrator and invoked by that function name rather than executed as a separate file. This is a small but real departure from the flat, standalone-script convention every prior lab in this track used, introduced specifically because this is the first lab where one script's logic is composed from calling three others, a composition none of Labs 01 through 04 needed. The tradeoff is one additional layer of structure, a dot-sourced function per script rather than a script that only ever runs standalone, accepted for the sake of making the orchestrator's own aggregation logic mockable and testable under ADR-017.

### 3. Keep the existing reporting convention for interactive runs, add a mandatory timestamped artifact for the unattended run

**Decision:** The three individual check scripts will follow Lab 02's and Lab 04's console-table-plus-optional-`-ExportPath` convention when run standalone. `Invoke-LabHealthReport.ps1` will additionally always write a timestamped aggregate report to a runtime directory on WIN11-CLIENT01 (planned as an HTML summary, matching Lab 04's precedent of departing from a flat table when the data's shape, here three different check types rolled into one overall status, does not reduce cleanly to a single CSV row) every time it runs, whether invoked by an operator or by Task Scheduler.

Every report in this track so far has been read by the person who just ran the script. This lab's whole premise is that nobody will be watching when the report runs, so an optional `-ExportPath` the way Lab 02 and Lab 04 use it, present only if an operator remembers to ask for it, is the wrong default here: if the scheduled run does not write something durable by default, an unhealthy night produces nothing for anyone to find the next morning. The individual check scripts keep the existing optional-export convention because they remain genuinely interactive tools an operator might run by hand; the orchestrator's always-write behavior is the one deliberate departure this lab makes from the established pattern, and it is departing for a reason specific to this lab's unattended nature rather than inventing a new convention for its own sake.

### 4. Health determination: a three-state classification with worst-wins aggregation

**Decision:** Each check script will classify its result as `Healthy`, `Unhealthy`, or `Unknown`. `Unknown` is reserved specifically for "the check itself could not be completed" (DC01 unreachable, a Wazuh or Portainer authentication failure, a request timeout), distinct from `Unhealthy`, which means the check completed and found a real problem (a stopped service, a disconnected agent, a stopped container). `Invoke-LabHealthReport.ps1` aggregates the three per-check results into one overall status using a worst-wins rule: any `Unhealthy` check makes the overall status `Unhealthy`, regardless of the other two; failing that, any `Unknown` check makes the overall status `Unknown`; only if all three checks report `Healthy` is the overall status `Healthy`.

This is the actual decision logic of the lab and the natural center of its Pester coverage, the same way the partial-success batch model was the real logic Lab 02's tests targeted and the RSoP session requirement was Lab 04's. A two-state model, Healthy or Unhealthy, would force every check to collapse an unreachable host into one of the two real outcomes, and either direction is a real failure mode for an unattended job: collapsing "could not reach the Wazuh API" into `Healthy` produces a false all-clear nobody catches until something is actually wrong and the report still reads green; collapsing it into `Unhealthy` produces a false incident indistinguishable from a genuinely stopped service, which erodes trust in the report the same way a noisy alert erodes trust in monitoring generally. Keeping `Unknown` as its own state, and treating it as worse than `Healthy` but not automatically as bad as a confirmed `Unhealthy`, is the more honest representation for a report nobody is present to sanity-check in real time, and it is the property this lab's Pester suite will exercise most directly: every combination of the three checks' possible states feeding into the aggregator, not just the two happy-path cases.

### 5. Scheduling: `Register-ScheduledTask` on WIN11-CLIENT01, daily, running as `labadmin` at limited privilege

**Decision:** `Invoke-LabHealthReport.ps1` will be registered as a Windows Task Scheduler job on WIN11-CLIENT01 using `Register-ScheduledTask`, built from `New-ScheduledTaskAction`, `New-ScheduledTaskTrigger`, `New-ScheduledTaskPrincipal`, and `New-ScheduledTaskSettingsSet`, consistent with the track's "Primary Tooling" (Windows Task Scheduler for recurring automation). The trigger will be daily at 07:00 local time. The task will run as `labadmin` under `-LogonType Password` and `-RunLevel Limited`, with `-StartWhenAvailable` and a fifteen-minute `-ExecutionTimeLimit` in its settings set. Registration will be performed by a fifth script, `Register-LabHealthReportTask.ps1`, committed alongside the other four so the task's configuration is reproducible from the repository rather than existing only as one machine's local state.

Both items this section previously carried as open questions are now settled, one of them by a live probe run during this step's planning rather than by argument. A third question, not previously identified here at all, turned out to be the harder of the three and is recorded first, because the other two depend on it.

**There are three credentials in play, not one.** This section originally discussed "the run-as account" as though the scheduled task needed a single identity. It needs three distinct ones, and conflating them obscures which part of the problem is actually hard. The first is the Windows principal the task runs as, which must be a domain account, since `Get-Service -ComputerName DC01` authenticates to the domain controller through Kerberos and a local WIN11-CLIENT01 account cannot. The second and third are the Wazuh Manager API account and the Portainer account, which are application credentials belonging to those two platforms and have nothing to do with the Windows principal. Task Scheduler stores the first for the task; it has no mechanism to supply the other two, which is why Step Six-A below exists at all.

**What account the task runs as, and why it is not a least-privileged one.** Every script in this track so far has been run interactively as `labadmin`, an account with Domain Admins membership, by an operator who explicitly started the session. A scheduled task that runs unattended under a stored credential is a materially different exposure: the credential sits in the Task Scheduler credential store indefinitely rather than existing only for the length of an interactive session, and it runs whether or not anyone is paying attention. The intended answer was therefore a dedicated, least-privileged scheduled-task account rather than `labadmin`, and that intent was tested before it was committed to, using the existing `testuser01` account so that nothing had to be provisioned to find out. It failed: `Get-Service -ComputerName DC01 -ErrorAction Stop`, run in a session started with `runas /user:corp\testuser01`, returned `Cannot open Service Control Manager on computer 'DC01'. This operation might require other privileges.` A plain domain account cannot enumerate services remotely on a domain controller in this environment. That finding is recorded in full in Troubleshooting and Adjustments below.

The failure matters more than a missing capability normally would, because of where it lands in this lab's own classification model. An SCM-open failure is precisely the condition `Get-LabADServiceHealth.ps1` classifies `Unknown`, per Step Two's own error-handling rework. A dedicated least-privileged account would therefore not have produced a degraded-but-usable report; it would have produced an AD check reporting `Unknown` every night, which is the quietest possible failure mode for a report nobody is watching, and exactly the false signal Design Decision 4 exists to prevent.

Two changes to DC01 would have made a least-privileged account work, and both were considered and deliberately refused. Editing the Service Control Manager's security descriptor with `sc.exe sdset scmanager` to grant remote enumerate rights to a specific principal is the technically correct enterprise answer, and it is what a tiered-administration model would do; it was refused here because it is a permanent security-descriptor edit on this environment's only domain controller, made from a lab whose own scope is read-only, with no second domain controller to recover against if the SDDL is wrong. Adding the account to Server Operators was refused for a stronger reason: that group can start and stop services on domain controllers, which is a broader and more dangerous grant than the strictly read-only use this lab actually makes of `labadmin`. There is no meaningful middle option, since on a domain controller the realistic groups are Domain Admins, BUILTIN\Administrators, and Server Operators, and none of them is a smaller grant than what is already available.

The task will therefore run as `labadmin`, recorded here as a documented compromise with a named production alternative rather than as a default that was never questioned. Two things reduce it in practice. The task is registered with `-RunLevel Limited` rather than `-RunLevel Highest`, since Implementation Step One already proved the AD check succeeds non-elevated, so the standing task does not additionally carry an elevated token it has no use for. And least-privilege is still applied to the two credentials where the platform allows it, below.

**Why not a group Managed Service Account.** A gMSA is the textbook answer to a standing stored password, and Task Scheduler supports a gMSA principal. It was considered and rejected on three grounds. It requires a KDS root key and gMSA provisioning in Active Directory, which is new tier-0 directory infrastructure introduced into a track ADR-015 scoped to automating the existing environment rather than extending it. It does not solve the two API credentials, which are the actual blocker for an unattended run. And a gMSA principal does not unlock a user DPAPI master key the way a password logon does, which conflicts directly with the credential-storage approach Step Six-A adopts. It is named here as the correct answer for a production deployment, not adopted for this lab.

**The two API accounts can be least-privileged, and will be.** Nothing in the Service Control Manager finding above constrains the Wazuh or Portainer credentials, which are ordinary application accounts on their own platforms. Step Six-A will provision a read-only Wazuh Manager API user and a non-administrative Portainer user in place of the broad admin accounts Steps One, Three, and Four used for diagnostics, subject to what each platform's role model actually supports, which will be established live rather than assumed. This is the part of the least-privilege intent that survives, and it is worth stating plainly: least-privilege was applied wherever the platform allowed it, and refused only where the only routes to it were tier-0 changes to the domain controller.

**Cadence.** Daily at 07:00 local time, which follows directly from Design Decision 3's own premise: an unhealthy night has to leave something an operator finds the next morning, and 07:00 is when that reading actually happens. `-StartWhenAvailable` is set so a firing missed because WIN11-CLIENT01 was powered off runs at the next opportunity rather than being skipped silently; if that happens, the observed run time will not match the trigger time, and the implementation write-up should say so rather than presenting the two as the same thing. The fifteen-minute `-ExecutionTimeLimit` replaces Task Scheduler's three-day default, so a run that hangs rather than failing is terminated the same morning instead of occupying the task until the following week.

**Elevation and non-interactive behavior.** Lab 04 discovered, by live diagnostic rather than assumption, that `Get-GPResultantSetOfPolicy` required an elevated session. Implementation Step One tested whether `Get-Service -ComputerName` against DC01 has any equivalent requirement, and found that it does not: a non-elevated session on WIN11-CLIENT01 succeeded on the first attempt, returning all six services as `Running`. That answers elevation for the check itself, and it is why `-RunLevel Limited` is correct above. It does not answer elevation for the step: registering a task that runs as a named user with a stored password requires an elevated session to perform the registration, which is a separate requirement from anything the check needs, and Step Six-B is written accordingly.

Whether Task Scheduler's non-interactive execution context changes the orchestrator's behavior remains genuinely untested, and it is the reason Step Six-B requires observing a real scheduled firing rather than a manually triggered one. The relevant script is `Invoke-LabHealthReport.ps1` specifically, not the three check scripts, since a scheduled firing invokes only the orchestrator and reaches the checks as dot-sourced functions inside it. The surfaces actually at risk are its interactive guard's `Get-Credential` and `Read-Host` calls, addressed in Step Six-A; `$MyInvocation.InvocationName` resolving to the script path rather than `.` under `powershell.exe -File`, which the whole run depends on; `$PSScriptRoot` resolving so the three dot-sourced check scripts are found; the calling account's execution policy; `Get-LabWazuhAgentStatus.ps1`'s runtime `Add-Type` compilation, which needs a writable temporary directory; and whether the report directory can be created and written under the task's own token. None of the four scripts uses `Write-Host`, so console-narration output is not among the risks, despite being the obvious first guess for a non-interactive context.

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
- Wazuh 4.14.5 (Manager, Indexer, Dashboard, Agents), deployed in enterprise Lab 07; Manager REST API on port `55000`, JWT authentication via `POST /security/user/authenticate` under the Manager API's own dedicated `wazuh-wui` account (confirmed in Implementation Step One; distinct from the Dashboard/Indexer login)
- Portainer Community Edition, deployed on Ubuntu Server in linux infrastructure Lab 04 (Docker Setup) and later migrated to internal-only, reverse-proxy-routed access in linux infrastructure Lab 07 (Reverse Proxy Lab); reachable only through `portainer.local` over plain HTTP via NGINX Proxy Manager (confirmed in Implementation Step One; the proxy host is HTTP-only, and direct `https://192.168.1.226:9443` remains blocked as ADR-009 and the reverse proxy lab documented), requiring a hosts-file entry on WIN11-CLIENT01; REST API authentication via `POST /api/auth`, container listing via `GET /api/endpoints/3/docker/containers/json` against endpoint ID `3` (confirmed live in Step One, not the previously assumed default of `1`)
- Windows Task Scheduler / the `ScheduledTasks` module: `Register-ScheduledTask`, `New-ScheduledTaskAction`, `New-ScheduledTaskTrigger`, `New-ScheduledTaskPrincipal`, `New-ScheduledTaskSettingsSet`, and, for reading back a firing's real outcome, `Get-ScheduledTask` and `Get-ScheduledTaskInfo`
- `Export-CliXml` and `Import-CliXml` (`Microsoft.PowerShell.Utility`) for DPAPI-protected storage of the two API credentials the unattended run needs, per Design Decision 5 and Implementation Step Six-A
- PSScriptAnalyzer 1.25.0 and Pester 5.6.1, the standard established in Lab 03, applied to all four new scripts from the outset
- The Docker Compose stacks running on Ubuntu Server, confirmed against a live `docker ps -a`/`docker compose ls -a` baseline in Implementation Step One rather than assumed from documentation: the Wazuh stack (`single-node-wazuh.manager-1`, `single-node-wazuh.indexer-1`, `single-node-wazuh.dashboard-1`, compose project `single-node`, running), the reverse proxy (`nginx-proxy-manager`, compose project `reverse-proxy-lab`, running), the standalone `portainer` container (running), and the monitoring stack (`prometheus`, `grafana`, `node-exporter`, compose project `monitoring-stack`, expected running). At the time of Step One, the monitoring stack's compose project reported `exited(3)`, all three containers stopped for roughly two months, a pre-existing condition Step One discovered rather than caused; see Troubleshooting and Adjustments. The `docker-networking` compose project (`frontend`, `backend`), leftover teaching-lab containers from linux infrastructure Lab 05, is confirmed present but excluded from the expected-running baseline, since it was never meant to run continuously
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
- DC01 running the target services (`NTDS`, `DNS`, `Netlogon`, `Kdc`, `W32Time`, `ADWS`) and reachable from WIN11-CLIENT01; the network path used by `Get-Service -ComputerName` (the Service Control Manager's remote RPC interface, distinct from PowerShell Remoting) was confirmed open between the two hosts in Implementation Step One, non-elevated, on the first attempt, all six services `Running`
- WIN11-CLIENT01 as the script execution endpoint per [ADR-016](../architecture/decisions/016-run-automation-scripts-from-domain-joined-client.md)
- The Wazuh stack operational with all three agents enrolled and previously confirmed `Active` (enterprise Lab 07), and API credentials available for the Manager REST API's own dedicated `wazuh-wui` account, distinct from the Dashboard/Indexer login and found in `docker-compose.yml` on Ubuntu Server during Step One after the Dashboard/Indexer credential was tried and rejected. The Manager REST API (`192.168.1.226:55000`) was confirmed reachable from WIN11-CLIENT01 in Implementation Step One, resolving the gating question ADR-013's Wazuh Dashboard proxy precedent had raised for this same Manager API
- Portainer running on Ubuntu Server, with an admin account available for both the web UI and the REST API. Portainer has no direct LAN-accessible port: ADR-009 removed it, and Implementation Step One reconfirmed direct access to `192.168.1.226:9443` fails. `portainer.local` through NGINX Proxy Manager is the only access path, and Step One confirmed it is HTTP-only, not HTTPS; WIN11-CLIENT01 needs a `192.168.1.226 portainer.local` hosts-file entry (added during Step One) for the hostname to resolve. The numeric endpoint ID for the Docker environment Portainer manages was confirmed as `3`
- PSScriptAnalyzer 1.25.0 and Pester 5.6.1 already installed on WIN11-CLIENT01 (Lab 03), and `PSScriptAnalyzerSettings.psd1` already committed to the repository
- The `ScheduledTasks` module, built into Windows and available on WIN11-CLIENT01 without additional installation
- An elevated PowerShell session on WIN11-CLIENT01 for the registration itself, which is a separate requirement from the non-elevated `Get-Service` call the scheduled job actually makes, per Design Decision 5
- DPAPI-protected credential files for the Wazuh Manager API and Portainer accounts, created with `Export-CliXml` in an interactive session as `labadmin`, the same account the task runs as, and stored on a runtime path outside the repository alongside the report directory. A credential file exported by one account on one machine cannot be read by another, which is the property this approach depends on and also its main constraint

---

## Implementation

### Step One - Confirmed Reachability and Established a Known-Good Baseline

Before any script was written, each data source was confirmed reachable from WIN11-CLIENT01 and its current state captured as the baseline later checks will be validated against, the same posture Lab 04's Step One took toward the Group Policy environment. This step was also where two open items were investigated directly: whether either PowerShell 5.1 API call needed a TLS accommodation for the self-signed certificates the Wazuh stack uses, raised in Technologies Used and Prerequisites rather than in any Design Decision, and whether `Get-Service -ComputerName` against DC01 requires elevation, the second of Design Decision 5's own open items. It is also where Design Decision 1's central open question, whether the Wazuh Manager API and the Portainer API are actually reachable from WIN11-CLIENT01, was resolved by live diagnostic rather than assumption. All commands were run from `C:\Scripts` on WIN11-CLIENT01 as `labadmin`, per ADR-016.

**AD service reachability.** `Get-Service -ComputerName DC01 -Name NTDS,DNS,Netlogon,Kdc,W32Time,ADWS` was run first, in a non-elevated session:

```powershell
Get-Service -ComputerName DC01 -Name NTDS,DNS,Netlogon,Kdc,W32Time,ADWS
```

This succeeded on the first attempt, returning all six services as `Running`. This resolves the `Get-Service` half of Design Decision 5's elevation question: no elevation is required for this check, unlike Lab 04's `Get-GPResultantSetOfPolicy` finding.

<p align="center">
  <img src="../../images/automation-and-scripting/05-scheduled-health-reporting/01-ad-service-health-baseline.jpg" width="900">
</p>

<p align="center">
  <em>Get-Service -ComputerName DC01, non-elevated, returning all six target services as Running: ADWS, DNS, Kdc, Netlogon, NTDS, W32Time.</em>
</p>

**Wazuh Manager API.** PowerShell 5.1's `Invoke-RestMethod` has no `-SkipCertificateCheck`, so the standard 5.1 accommodation was applied first: forcing TLS 1.2 and installing a certificate-validation callback that accepts the Wazuh stack's self-signed certificate.

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if (-not ("TrustAllCertsPolicy" -as [type])) {
    Add-Type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(ServicePoint sp, X509Certificate cert, WebRequest req, int problem) {
        return true;
    }
}
"@
}
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
```

This accommodation worked on the first try: no TLS handshake error, no connection failure, confirming port `55000` is reachable across the LAN from WIN11-CLIENT01. Authentication itself failed twice, both times with `{"title":"Unauthorized","detail":"Invalid credentials"}`, using the Dashboard/Indexer `admin` login the operator had just used successfully to log into the Wazuh Dashboard front end. This was not a credential error so much as a wrong-account error: the Wazuh Manager REST API validates against its own local user store, separate from the Indexer/OpenSearch account the Dashboard authenticates against. The correct account was found in `docker-compose.yml` on Ubuntu Server (`~/infrastructure/security-monitoring-lab/wazuh-docker/single-node/docker-compose.yml`), which defines the `wazuh.manager` service's `API_USERNAME` as `wazuh-wui`. Retrying with that account succeeded:

```powershell
$cred = Get-Credential -Message "Wazuh API credentials (wazuh-wui)"
$pair = "$($cred.UserName):$($cred.GetNetworkCredential().Password)"
$base64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($pair))

$authResponse = Invoke-RestMethod -Uri "https://192.168.1.226:55000/security/user/authenticate" -Method Post -Headers @{ Authorization = "Basic $base64" }
$token = $authResponse.data.token

$headers = @{ Authorization = "Bearer $token" }
Invoke-RestMethod -Uri "https://192.168.1.226:55000/agents" -Method Get -Headers $headers | ConvertTo-Json -Depth 5
```

`GET /agents` returned four entries, not three: agent `000` (`wazuh.manager` itself, the manager's own built-in agent, `registerIP: 127.0.0.1`, `status: active`), agent `001` (`UBUNTU-SERVER`, `ip: 192.168.1.226`, `status: active`), agent `002` (`WIN11-CLIENT01`, `ip: 192.168.1.20`, `status: active`), and agent `003` (`DC01`, `ip: 192.168.1.10`, `status: active`), with `total_affected_items: 4` and `total_failed_items: 0`. All three target agents named in Objectives (`DC01`, `WIN11-CLIENT01`, `UBUNTU-SERVER`) are `active`; the manager's own agent `000` is additionally always present in this response and will need to be accounted for, not silently included, when `Get-LabWazuhAgentStatus.ps1` is built in Step Three.

<p align="center">
  <img src="../../images/automation-and-scripting/05-scheduled-health-reporting/02-wazuh-api-auth-and-agents.jpg" width="900">
</p>

<p align="center">
  <em>Wazuh Manager API authentication succeeding under the wazuh-wui account after the TLS accommodation, followed by GET /agents returning wazuh.manager and UBUNTU-SERVER as active (WIN11-CLIENT01 and DC01 confirmed active further down the same response).</em>
</p>

**Portainer API.** Direct access was tested first, to reconfirm ADR-009 and the reverse proxy lab's documented finding still holds:

```powershell
Invoke-RestMethod -Uri "https://192.168.1.226:9443/api/status" -Method Get
```

This failed with `Unable to connect to the remote server`, confirming direct `:9443` access remains blocked. `portainer.local` did not resolve on WIN11-CLIENT01 (`Resolve-DnsName` and `ping` both failed), so a hosts-file entry was added from an elevated session:

```powershell
Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Value "192.168.1.226 portainer.local"
```

<p align="center">
  <img src="../../images/automation-and-scripting/05-scheduled-health-reporting/03-portainer-direct-9443-blocked.jpg" width="900">
</p>

<p align="center">
  <em>Direct https://192.168.1.226:9443 failing with Unable to connect to the remote server, and portainer.local failing to resolve before the hosts-file entry was added.</em>
</p>

After the hosts entry, `portainer.local` resolved to `192.168.1.226`, but an HTTPS request failed with `The request was aborted: Could not create SSL/TLS secure channel`, even after the TLS 1.2/certificate-policy accommodation from the Wazuh check was reapplied fresh in the same session. Since the same accommodation had worked immediately against the Wazuh API, this pointed at something specific to the Portainer proxy path rather than a missing client-side workaround. Linux infrastructure Lab 04's own documentation of the current Portainer access URL, and the reverse proxy lab's Validated URLs list, both record `http://portainer.local`, not `https://`, which was the actual cause: the NGINX Proxy Manager proxy host for Portainer is HTTP-only, with no SSL certificate assigned to that vhost. Switching to plain HTTP succeeded:

```powershell
Invoke-RestMethod -Uri "http://portainer.local/api/status" -Method Get
```

This returned `Version: 2.39.2`, `InstanceID: cce20bb2-93cd-47bd-974c-7f23deca85d1`.

<p align="center">
  <img src="../../images/automation-and-scripting/05-scheduled-health-reporting/04-portainer-https-tls-failure.jpg" width="900">
</p>

<p align="center">
  <em>The TLS 1.2/certificate-policy accommodation reapplied and HTTPS to portainer.local still failing with Could not create SSL/TLS secure channel, ruling out a missing client-side accommodation as the cause.</em>
</p>

<p align="center">
  <img src="../../images/automation-and-scripting/05-scheduled-health-reporting/05-portainer-http-success.jpg" width="900">
</p>

<p align="center">
  <em>Plain HTTP to portainer.local/api/status succeeding: Portainer 2.39.2.</em>
</p>

Authenticating against the Portainer API surfaced two unrelated pieces of friction before it produced real data. `Get-Credential`'s Windows Security dialog opened but did not accept input in this remote session, a window-station-level issue rather than a credential problem; the workaround was switching to console-based `Read-Host` prompts for the username and password instead of `Get-Credential`. Pasting the resulting multi-line command block in one paste then corrupted the input, since the interactive `Read-Host` prompts consumed characters intended for later lines, producing a `Missing closing ')' in expression` parser error and a cascade of unrelated failures; running the same commands one line at a time, waiting for each prompt, resolved it cleanly:

```powershell
$portainerUser = Read-Host -Prompt "Portainer username"
$portainerPass = Read-Host -AsSecureString -Prompt "Portainer password"
$cred = New-Object System.Management.Automation.PSCredential($portainerUser, $portainerPass)

$body = @{ Username = $cred.UserName; Password = $cred.GetNetworkCredential().Password } | ConvertTo-Json
$authResponse = Invoke-RestMethod -Uri "http://portainer.local/api/auth" -Method Post -Body $body -ContentType "application/json"
$token = $authResponse.jwt

$headers = @{ Authorization = "Bearer $token" }
$endpoints = Invoke-RestMethod -Uri "http://portainer.local/api/endpoints" -Method Get -Headers $headers
$endpoints | ConvertTo-Json -Depth 5
```

Authentication succeeded using the same admin account used for the Portainer web UI; no separate API account exists for Portainer the way `wazuh-wui` exists for Wazuh. `GET /api/endpoints` returned one endpoint: `Id: 3`, `Name: "local"`, `Status: 1`, with a live Docker snapshot showing `DockerVersion: 29.7.2`, `ContainerCount: 10`, `RunningContainerCount: 5`, `StoppedContainerCount: 5`. The endpoint ID is `3`, not the previously assumed default of `1`, resolving the open item Troubleshooting and Adjustments had flagged. The full container list was then queried against that endpoint:

```powershell
$containers = Invoke-RestMethod -Uri "http://portainer.local/api/endpoints/3/docker/containers/json?all=true" -Method Get -Headers $headers
$containers | Select-Object @{N='Name';E={$_.Names -join ','}}, Image, State, Status | Format-Table -AutoSize
```

This returned ten containers: `single-node-wazuh.dashboard-1` (`wazuh/wazuh-dashboard:4.14.5`, running, up 7 days), `single-node-wazuh.manager-1` (`wazuh/wazuh-manager:4.14.5`, running, up 7 days), `single-node-wazuh.indexer-1` (`wazuh/wazuh-indexer:4.14.5`, running, up 7 days), `nginx-proxy-manager` (`jc21/nginx-proxy-manager:latest`, running, up 7 days), `portainer` (`portainer/portainer-ce:lts`, running, up 7 days), `prometheus` (`prom/prometheus:latest`, exited, `Exited (0) 2 months ago`), `grafana` (`grafana/grafana:latest`, exited, `Exited (0) 2 months ago`), `node-exporter` (`prom/node-exporter:latest`, exited, `Exited (2) 2 months ago`), `frontend` (`nginx:latest`, exited, `Exited (0) 2 months ago`), and `backend` (`hashicorp/http-echo`, exited, `Exited (2) 2 months ago`).

<p align="center">
  <img src="../../images/automation-and-scripting/05-scheduled-health-reporting/06-portainer-api-containers.jpg" width="900">
</p>

<p align="center">
  <em>The full ten-container list from Portainer's API against endpoint 3: the Wazuh stack, nginx-proxy-manager, and portainer running; prometheus, grafana, node-exporter, frontend, and backend exited.</em>
</p>

**Docker Engine cross-check via SSH.** Per Design Decision 7, Portainer's own view is not treated as independent of itself, so the container baseline was cross-checked against a direct `docker ps -a`/`docker compose ls -a` on Ubuntu Server, over the existing SSH access path, as a manual operator step rather than a script:

```bash
docker ps -a
docker compose ls -a
```

`docker ps -a` matched Portainer's container list exactly: the same ten containers, the same names, images, and running/exited states. `docker compose ls -a` added information Portainer's container list alone does not show: `single-node` (the Wazuh stack) reports `running(3)` and `reverse-proxy-lab` reports `running(1)`, both compose projects fully up; `monitoring-stack` reports `exited(3)` and `docker-networking` reports `exited(2)`, both compose projects fully down, not merely individual containers drifting.

<p align="center">
  <img src="../../images/automation-and-scripting/05-scheduled-health-reporting/07-docker-ssh-crosscheck.jpg" width="900">
</p>

<p align="center">
  <em>docker ps -a and docker compose ls -a on Ubuntu Server, matching Portainer's API view exactly and showing monitoring-stack and docker-networking as fully exited compose projects.</em>
</p>

**The `frontend`/`backend` containers are explained; the monitoring stack being down is not.** `frontend` and `backend` are linux infrastructure Lab 05's own demonstration containers (an NGINX frontend and a `hashicorp/http-echo` backend, deployed to exercise custom Docker bridge networking), part of the `docker-networking` compose project. Lab 05 never documents removing them; they were left in place after that lab concluded, exactly the scenario Troubleshooting and Adjustments had speculated about, and they are correctly excluded from the expected-running baseline going forward, since they were never meant to run continuously. The monitoring stack (`prometheus`, `grafana`, `node-exporter`, the `monitoring-stack` compose project) being fully down is a different and genuinely unplanned finding: linux infrastructure Lab 06 is documented as `Completed` with no later note about decommissioning, pausing, or any incident, and no ADR mentions it either. The operator did not know the monitoring stack was down before this step surfaced it. Root cause was not investigated in this session, and the stack was deliberately not restarted here; per this lab's own read-only scope and the goal of an authentic first health-report run, remediation is deferred to Step Seven, so that `Get-LabDockerServiceStatus.ps1`'s first live run against the real environment catches and reports this as `Unhealthy` rather than being validated against an environment someone quietly fixed first.

**Go/no-go verdict.** Design Decision 1's Option D holds. Both the Wazuh Manager API and the Portainer API are reachable from WIN11-CLIENT01 and authenticate successfully, so the four-script design in Design Decision 2 is cleared to proceed to Step Two in a later session. The AD service check was clean on the first attempt, no friction. The Wazuh Manager API check required real but contained troubleshooting: the TLS accommodation worked immediately, and the only obstacle was locating the correct `wazuh-wui` account, resolved in one step by checking `docker-compose.yml`. The Portainer API check took the most sustained troubleshooting of the three: a hosts-file entry was required, the assumed HTTPS path turned out to be wrong and cost a full diagnostic round to identify, and the `Get-Credential`/multi-line-paste issues were unrelated environmental friction on top of that. None of the friction encountered changed the underlying verdict, but it is real enough to note for scoping the remainder of this lab: reachability held, but the Portainer path in particular did not work on the first, second, or even third attempt.

### Step Two - Built Get-LabADServiceHealth.ps1

`Get-LabADServiceHealth.ps1` was built colocated with its Pester tests in a new `infrastructure/automation-and-scripting/scheduled-health-reporting/` folder, following the `Verb-LabNoun` naming pattern and per-lab subfolder convention every prior lab in the track established. It accepts an optional `-ComputerName` (default `DC01`) and `-ServiceName` (default the six-service list Step One confirmed: `NTDS`, `DNS`, `Netlogon`, `Kdc`, `W32Time`, `ADWS`), plus the optional `-ExportPath` the standalone reporting convention uses, and queries each named service's `Status` via `Get-Service -ComputerName`, the call Step One already confirmed works non-elevated with no new remoting.

**The dot-sourced-function invocation model.** Per Design Decision 2, the script defines a function named the same as the file, `Get-LabADServiceHealth`, so `Invoke-LabHealthReport.ps1` can dot-source it in Step Five and call it by name rather than executing it as a separate file, which is what will make the orchestrator's aggregation logic mockable. That invocation model set a hard requirement this script had to satisfy: dot-sourcing it must define the function with no side effects, no query against DC01 and no console output. The idiom chosen for that split is a guard at the bottom of the file:

```powershell
if ($MyInvocation.InvocationName -ne '.') {
    # standalone console-table / -ExportPath rendering lives here
}
```

`$MyInvocation.InvocationName` is `.` when the file is dot-sourced and the file's own path or name when it is run directly, so the guard's body, the Design Decision 3 console-table-plus-`-ExportPath` rendering, only ever executes on a direct run. This is the pattern the remaining check scripts (`Get-LabWazuhAgentStatus.ps1` in Step Three, `Get-LabDockerServiceStatus.ps1` in Step Four) are expected to copy, and the Pester suite below asserts it directly rather than assuming it.

**Classification.** `Get-Service -ComputerName $ComputerName -ErrorAction Stop` is called inside a `try`/`catch`, per Design Decision 4, enumerating every service on the target rather than passing `-Name`, and the script matches each requested service name against the returned collection itself. A requested service that is simply absent from that collection is reported `NotFound` and classifies the overall check `Unhealthy`, the "expected service absent" condition the plan called for rather than a query failure. A connectivity or permission failure against DC01 (host unreachable, an RPC/SCM error, access denied) cannot open the target's Service Control Manager and surfaces as a terminating `InvalidOperationException` under `-ErrorAction Stop`, which the `try`/`catch` catches and classifies `Unknown`, carrying the exception's message on the returned object. Every named service reporting `Running` classifies `Healthy`. This enumerate-then-match shape is not the form the script was first built with: it replaced a `-Name` / `-ErrorAction SilentlyContinue` call after a live diagnostic showed that earlier form could not tell an unreachable target apart from a reachable one missing the named services, and misclassified an unreachable DC `Unhealthy` instead of `Unknown`. That finding and its resolution are recorded in Troubleshooting and Adjustments below.

The script returns a `PSCustomObject` (`CheckName`, `ComputerName`, `Services`, one entry per named service with its own `ServiceName`/`Status`, `Status`, and `Message`) rather than printing `Write-Host` PASS/FAIL narration, so it does not rely on this library's `PSAvoidUsingWriteHost` suppression from Lab 03 at all. The standalone path, inside the dot-source guard, flattens the nested `Services` collection to one row per service, both for the `Format-Table` console output and, when `-ExportPath` is supplied, for `Export-Csv`, since a nested array does not serialize cleanly to a single CSV row.

**Pester coverage.** `Get-LabADServiceHealth.Tests.ps1` mocks `Get-Service`, the only external command the script calls, plus a representative sample of state-changing service cmdlets (`Set-Service`, `Stop-Service`, `Start-Service`, `Restart-Service`), each asserted at `-Times 0`, matching this library's established read-only assertion pattern. Ten tests were written across seven Contexts: Dot-sourcing behavior (asserting the function is defined and that `Get-Service` was called zero times immediately after dot-sourcing), Read-only behavior, the three classification branches (Healthy; Unhealthy for a stopped service and, separately, for a not-found service; Unknown for a Service Control Manager failure surfaced the way the live cmdlet surfaces it, a non-terminating error made terminating by `-ErrorAction Stop`), Parameter defaults and pass-through, and the `-ExportPath` CSV branch. Because the function returns its result directly rather than only piping to `Format-Table`, the classification tests call `Get-LabADServiceHealth` directly after dot-sourcing and assert on the returned object's `Status`, `Services`, and `Message` properties, per Design Decision 6, rather than round-tripping through a CSV export the way the read-only Lab 04 scripts had to.

```powershell
Invoke-Pester -Path C:\Scripts\Get-LabADServiceHealth.Tests.ps1 -Output Detailed
```

All ten tests passed on the first run: `Discovery found 10 tests`, `Tests Passed: 10, Failed: 0, Skipped: 0, Inconclusive: 0, NotRun: 0`.

**Analysis was not clean on the first pass.**

```powershell
Invoke-ScriptAnalyzer -Path C:\Scripts -Settings C:\Scripts\PSScriptAnalyzerSettings.psd1 -Recurse
```

This returned five findings, all `PSAvoidUsingComputerNameHardcoded` (Error severity), all against `Get-LabADServiceHealth.Tests.ps1`:

| RuleName | Severity | ScriptName | Line |
|---|---|---|---|
| `PSAvoidUsingComputerNameHardcoded` | Error | `Get-LabADServiceHealth.Tests.ps1` | 133 |
| `PSAvoidUsingComputerNameHardcoded` | Error | `Get-LabADServiceHealth.Tests.ps1` | 155 |
| `PSAvoidUsingComputerNameHardcoded` | Error | `Get-LabADServiceHealth.Tests.ps1` | 174 |
| `PSAvoidUsingComputerNameHardcoded` | Error | `Get-LabADServiceHealth.Tests.ps1` | 188 |
| `PSAvoidUsingComputerNameHardcoded` | Error | `Get-LabADServiceHealth.Tests.ps1` | 208 |

<p align="center">
  <img src="../../images/automation-and-scripting/05-scheduled-health-reporting/08-analyzer-computername-hardcoded-finding.jpg" width="900">
</p>

<p align="center">
  <em>Invoke-ScriptAnalyzer returning five PSAvoidUsingComputerNameHardcoded findings against Get-LabADServiceHealth.Tests.ps1, each reporting "The ComputerName parameter of cmdlet 'Get-LabADServiceHealth' is hardcoded. This will expose sensitive information about the system if the script is shared."</em>
</p>

Lines 133, 155, 174, and 188 were the four classification tests' calls to `Get-LabADServiceHealth -ComputerName 'DC01' ...`; line 208 was the explicit-override pass-through test's `-ComputerName 'DC02'`. The rule flags a literal string bound directly to a parameter named `ComputerName` at a call site; it does not flag a `-ComputerName` parameter's own default value in a `param` block, which is why `Get-LabADServiceHealth.ps1` itself was already clean. The fix was confined to the test file: `$script:TargetComputerName = 'DC01'` and `$script:AlternateComputerName = 'DC02'` were added to `BeforeAll`, and all five call sites, plus the two `ParameterFilter` comparisons that referenced the same literals, were switched to reference those variables instead, clearing the rule without suppressing it in `PSScriptAnalyzerSettings.psd1`.

```powershell
Invoke-Pester -Path C:\Scripts\Get-LabADServiceHealth.Tests.ps1 -Output Detailed
Invoke-ScriptAnalyzer -Path C:\Scripts -Settings C:\Scripts\PSScriptAnalyzerSettings.psd1 -Recurse
```

Re-run after the fix, Pester still passed 10 of 10, confirming the fix, a call-site value change only, did not affect any assertion, and the analyzer returned to the prompt with no further output: a clean pass.

<p align="center">
  <img src="../../images/automation-and-scripting/05-scheduled-health-reporting/09-pester-and-analyzer-clean-pass.jpg" width="900">
</p>

<p align="center">
  <em>Invoke-Pester re-run confirming all ten tests still passing after the PSAvoidUsingComputerNameHardcoded fix (the test-file-only change described above), followed by Invoke-ScriptAnalyzer returning to the prompt with no output: a clean pass. This is the build-time clean pass; a second, later clean pass follows the separate error-handling fix in Troubleshooting and Adjustments (screenshot 12).</em>
</p>

**A single live standalone run against DC01 was performed here**, per the plan, since Step One had already proven `Get-Service -ComputerName DC01` works non-elevated; the authoritative live validation and the full combined analyzer/Pester sweep across all of Labs 01 through 05 remain reserved for Step Seven, not claimed here.

```powershell
.\Get-LabADServiceHealth.ps1
```

This returned a real `Healthy` result: all six target services (`NTDS`, `DNS`, `Netlogon`, `Kdc`, `W32Time`, `ADWS`) reporting `Running` against `DC01`, `OverallStatus` `Healthy` on every row, `Message` blank.

<p align="center">
  <img src="../../images/automation-and-scripting/05-scheduled-health-reporting/10-live-ad-service-health-run.jpg" width="900">
</p>

<p align="center">
  <em>.\Get-LabADServiceHealth.ps1 run standalone against DC01: a formatted console table showing all six target services Running and OverallStatus Healthy.</em>
</p>

### Step Three - Built Get-LabWazuhAgentStatus.ps1

`Get-LabWazuhAgentStatus.ps1` was built alongside `Get-LabADServiceHealth.ps1` in the same `infrastructure/automation-and-scripting/scheduled-health-reporting/` folder. It accepts an optional `-BaseUri` (default `https://192.168.1.226:55000`, the Manager API address Step One confirmed reachable), a `-Credential` for the Manager API's dedicated `wazuh-wui` account (confirmed in Step One; distinct from the Dashboard/Indexer login), an optional `-AgentName` list (default the three agents Step One confirmed enrolled and active: `DC01`, `WIN11-CLIENT01`, `UBUNTU-SERVER`), and the optional `-ExportPath` the standalone reporting convention uses. It authenticates against `POST /security/user/authenticate` with a Basic authorization header built from the credential, takes the JWT from the response's `data.token`, and queries `GET /agents` with that token as a Bearer header, reading the agent list from `data.affected_items`, the same request shape Step One proved live.

**The dot-sourced-function invocation model, copied from Step Two.** `Get-LabWazuhAgentStatus.ps1` defines a function named the same as the file, per Design Decision 2, and reuses the same guard at the bottom of the file, `if ($MyInvocation.InvocationName -ne '.') { ... }`, so dot-sourcing it only ever defines the function and binds the top-level parameter defaults, the same no-side-effects requirement Step Two's script had to satisfy. One difference from Step Two's script follows directly from that requirement: the top-level `-Credential` parameter carries no `Mandatory` attribute and no default, even though the function's own `-Credential` is mandatory. A mandatory parameter at the top of the script would make PowerShell prompt for it interactively the moment the file is dot-sourced, which would hang a Pester run waiting on input rather than merely defining the function. The standalone path inside the guard prompts for the credential itself, with `Get-Credential`, only when the file is run directly and no `-Credential` was supplied, keeping the interactive prompt confined to the one code path that is actually meant to run interactively.

**Agent 000 filtering.** Per Step One's own finding, `GET /agents` returns a fourth entry for the Wazuh Manager's own built-in agent (`id 000`, `name wazuh.manager`) alongside the three monitored targets. The script excludes that entry, by `id`, before matching the requested `-AgentName` list against the response, so it is never counted as a monitored agent and never affects the returned `Status`, whatever its own reported status happens to be.

**Classification.** Per Design Decision 4: `Healthy` if every named agent is present in the response and reports `active`; `Unhealthy` if the query completes but any named agent reports a non-active status (`disconnected`, `never_connected`, `pending`, or any other value besides `active`) or is missing from the response entirely, the Wazuh-agent analog of Step Two's `NotFound` condition; `Unknown` only if authentication or the agent query itself could not be completed. Unlike `Get-Service`, which Step Two discovered does not throw a terminating error for an unreachable target when called with `-Name`, forcing `Get-LabADServiceHealth.ps1` into the enumerate-then-match rework documented in that step's Troubleshooting, `Invoke-RestMethod` throws a terminating error on its own for both a connection failure and an HTTP error status, the same 401 Step One's own troubleshooting produced against the wrong Wazuh account. A failed authentication or an unreachable Manager API therefore reaches this script's `try`/`catch` and classifies `Unknown` without any equivalent workaround: the same `Unknown` requirement Step Two had to engineer around `Get-Service`'s actual behavior is satisfied here by `Invoke-RestMethod`'s own throwing behavior, confirmed by the mocked Pester coverage below rather than assumed.

**The certificate-validation bypass, scoped rather than left on for the session.** PowerShell 5.1's `Invoke-RestMethod` has no `-SkipCertificateCheck` parameter, so reaching the Wazuh stack's self-signed certificate over HTTPS requires the same TLS 1.2 / `TrustAllCertsPolicy` accommodation Step One used interactively. That accommodation is process-wide in PowerShell 5.1: `[System.Net.ServicePointManager]::CertificatePolicy` has no narrower, request-scoped equivalent. Step One's own Security Considerations left open how the finished script should handle this. The decision made here is to capture the process's existing `CertificatePolicy` and `SecurityProtocol` before applying the accommodation, apply it only for the authentication and agent-query calls the function makes, and restore both original values in a `finally` block once those two calls are done, so certificate validation is disabled only for the duration of this function's own REST calls rather than for the rest of the calling session. Restoring cleanly was not impractical here: both `ServicePointManager` properties are ordinary settable static properties, and saving and reassigning them costs two extra lines.

**Credential and token hygiene.** `-Credential` is accepted as a `[PSCredential]`, the same discipline `New-LabUser.ps1` (Lab 01) established for a plaintext password. The Basic authorization header built from it, and the JWT bearer token `GET /agents` is authenticated with, exist only inside the function's local scope; the returned `PSCustomObject` carries only agent names and statuses, the overall `Status`, and a `Message` drawn from the exception's own text on failure, and neither the credential nor the token is written to the console, placed on the returned object, or included in the standalone report. The Pester suite asserts this directly.

Like `Get-LabADServiceHealth.ps1`, this script returns a `PSCustomObject` rather than printing PASS/FAIL narration with `Write-Host`. The standalone path, inside the dot-source guard, flattens the nested `Agents` collection to one row per agent, both for the `Format-Table` console output and, when `-ExportPath` is supplied, for `Export-Csv`.

**Pester coverage.** `Get-LabWazuhAgentStatus.Tests.ps1` mocks `Invoke-RestMethod`, the only external command the script calls, distinguishing the authentication call from the agent-status call by `-Uri` in each `ParameterFilter`, per this lab's Design Decision 6 extended for the first time in this lab to a non-`Get-Service` external command. The test credential was built without `ConvertTo-SecureString -AsPlainText`, per Lab 03's own `PSAvoidUsingConvertToSecureStringWithPlainText` finding: a `PSCredential` constructed directly from an empty `[System.Security.SecureString]::new()`, since no test depends on the password's actual contents. Fifteen tests were written across eight Contexts: Dot-sourcing behavior, Read-only behavior (asserting `Invoke-RestMethod` is called exactly twice, once `Post` against the authenticate endpoint and once `Get` against the agents endpoint, and never any other method or URI), the three classification branches (Healthy, including a dedicated assertion that agent `000` is excluded from the result; Unhealthy for a non-active target agent and, separately, for a target agent missing from the response; Unknown for an authentication failure and, separately, for an agents-query failure), Parameter defaults and pass-through, Credential and token hygiene (asserting the fabricated JWT never appears on the returned object or in standalone console output), and the `-ExportPath` CSV branch.

```powershell
Invoke-Pester -Path C:\Scripts\Get-LabWazuhAgentStatus.Tests.ps1 -Output Detailed
```

All fifteen tests passed on the first run: `Discovery found 15 tests in 170ms`, `Tests Passed: 15, Failed: 0, Skipped: 0, Inconclusive: 0, NotRun: 0`.

<p align="center">
  <img src="../../images/automation-and-scripting/05-scheduled-health-reporting/13-wazuh-first-pester-pass.jpg" width="900">
</p>

<p align="center">
  <em>Invoke-Pester against Get-LabWazuhAgentStatus.Tests.ps1: 15 tests discovered across eight Contexts, all fifteen passed on the first run.</em>
</p>

**Analysis was not clean on the first pass.**

```powershell
Invoke-ScriptAnalyzer -Path C:\Scripts\Get-LabWazuhAgentStatus.ps1 -Settings C:\Scripts\PSScriptAnalyzerSettings.psd1
Invoke-ScriptAnalyzer -Path C:\Scripts\Get-LabWazuhAgentStatus.Tests.ps1 -Settings C:\Scripts\PSScriptAnalyzerSettings.psd1
```

Analyzed as two separate invocations, following the comma-path workaround Lab 04 established. This returned one finding, against the test file:

| RuleName | Severity | ScriptName | Line | Message |
|---|---|---|---|---|
| `PSUseSingularNouns` | Warning | `Get-LabWazuhAgentStatus.Tests.ps1` | 86 | The cmdlet 'script:New-DefaultMockAgents' uses a plural noun. A singular noun should be used instead. |

<p align="center">
  <img src="../../images/automation-and-scripting/05-scheduled-health-reporting/14-analyzer-singularnouns-finding.jpg" width="900">
</p>

<p align="center">
  <em>Invoke-ScriptAnalyzer returning one PSUseSingularNouns finding against Get-LabWazuhAgentStatus.Tests.ps1 line 86, flagging the test-only helper function New-DefaultMockAgents.</em>
</p>

`New-DefaultMockAgents` was a private test-only helper building the fabricated four-agent `GET /agents` response (the manager's own agent plus the three active targets) reused across the default mocks. The fix was confined to the test file: the function was renamed to `New-DefaultMockAgentSet`, and its one call site was updated to match; no assertion changed.

```powershell
Invoke-Pester -Path C:\Scripts\Get-LabWazuhAgentStatus.Tests.ps1 -Output Detailed
Invoke-ScriptAnalyzer -Path C:\Scripts\Get-LabWazuhAgentStatus.ps1 -Settings C:\Scripts\PSScriptAnalyzerSettings.psd1
Invoke-ScriptAnalyzer -Path C:\Scripts\Get-LabWazuhAgentStatus.Tests.ps1 -Settings C:\Scripts\PSScriptAnalyzerSettings.psd1
```

Re-run after the fix, Pester still passed 15 of 15 (`Tests completed in 926ms`, `Tests Passed: 15, Failed: 0, Skipped: 0, Inconclusive: 0, NotRun: 0`), confirming the rename did not affect any assertion, and both `Invoke-ScriptAnalyzer` invocations returned to the prompt with no output: a clean pass.

<p align="center">
  <img src="../../images/automation-and-scripting/05-scheduled-health-reporting/15-pester-and-analyzer-clean-pass.jpg" width="900">
</p>

<p align="center">
  <em>Invoke-Pester re-run confirming all fifteen tests still passing after the New-DefaultMockAgentSet rename, followed by both Invoke-ScriptAnalyzer invocations returning to the prompt with no output: a clean pass.</em>
</p>

**A single live standalone run against the Wazuh Manager API was performed here**, per the plan, since Step One had already proven the API reachable and authenticating under the `wazuh-wui` account; the authoritative live validation and the full combined analyzer/Pester sweep across all of Labs 01 through 05 remain reserved for Step Seven, not claimed here.

```powershell
$cred = Get-Credential -Message "Wazuh Manager API credentials (wazuh-wui)"
.\Get-LabWazuhAgentStatus.ps1 -Credential $cred
```

This returned a real `Healthy` result: all three target agents (`DC01`, `WIN11-CLIENT01`, `UBUNTU-SERVER`) reporting `active` against `https://192.168.1.226:55000`, `OverallStatus` `Healthy` on every row, matching Step One's all-active baseline exactly.

<p align="center">
  <img src="../../images/automation-and-scripting/05-scheduled-health-reporting/16-live-wazuh-agent-status-run.jpg" width="900">
</p>

<p align="center">
  <em>.\Get-LabWazuhAgentStatus.ps1 run standalone against the Wazuh Manager API: a formatted console table showing all three target agents active and OverallStatus Healthy.</em>
</p>

### Step Four - Built Get-LabDockerServiceStatus.ps1

`Get-LabDockerServiceStatus.ps1` was built alongside the two earlier check scripts in the same `infrastructure/automation-and-scripting/scheduled-health-reporting/` folder. It accepts an optional `-BaseUri` (default `http://portainer.local`, the plain-HTTP path Step One confirmed working), an optional `-EndpointId` (default `3`, the numeric Docker environment ID Step One confirmed live, not the previously assumed default of `1`), a `-Credential` for the Portainer admin account, an optional `-ExpectedContainer` list (default the curated eight-container set below), and the optional `-ExportPath` the standalone reporting convention uses. It authenticates against `POST /api/auth` with a JSON body built from the credential and reads the JWT from the response's top-level `jwt` field, a different shape from the Wazuh Manager API's `data.token`, then queries `GET /api/endpoints/3/docker/containers/json?all=true` with that token as a Bearer header, the `?all=true` flag being the reason a stopped expected container shows up as stopped rather than simply missing from the response.

**No TLS accommodation, unlike Step Three.** Step One confirmed the only working Portainer path is plain HTTP through NGINX Proxy Manager, not HTTPS, so this script applies none of `Get-LabWazuhAgentStatus.ps1`'s TLS 1.2 / `TrustAllCertsPolicy` accommodation; there is no HTTPS leg on this path to accommodate. One consequence, expanded on in Security Considerations, is that the Portainer credential crosses the LAN in cleartext on every call this script makes.

**The dot-sourced-function invocation model, copied from Steps Two and Three.** `Get-LabDockerServiceStatus.ps1` defines a function named the same as the file, per Design Decision 2, and reuses the same `if ($MyInvocation.InvocationName -ne '.') { ... }` guard, so dot-sourcing it only ever defines the function and binds the top-level parameter defaults. As in Step Three, the top-level `-Credential` parameter carries no `Mandatory` attribute and no default, even though the function's own `-Credential` is mandatory, so that dot-sourcing this file cannot hang a test run on an interactive prompt; the standalone path inside the guard prompts for the credential itself, with `Get-Credential`, only when the file is run directly and no `-Credential` was supplied.

**Container-name normalization.** Docker's container-listing endpoint returns each container's `Names` as an array of strings with a leading slash, for example `["/portainer"]`, confirmed in Step One's own container listing. The script takes the first entry and strips the leading slash before matching a container against `-ExpectedContainer`; matching the raw, slash-prefixed value against a plain container name would silently fail every comparison.

**The curated expected-running set, and the deliberate exclusion of the teaching containers.** The default `-ExpectedContainer` list is the eight containers Step One confirmed as the environment's intended baseline: the Wazuh stack (`single-node-wazuh.manager-1`, `single-node-wazuh.indexer-1`, `single-node-wazuh.dashboard-1`), the reverse proxy (`nginx-proxy-manager`), `portainer` itself, and the monitoring stack (`prometheus`, `grafana`, `node-exporter`). The `docker-networking` project's `frontend` and `backend` containers, leftover teaching-lab containers from linux infrastructure Lab 05, are deliberately not in this list, the same way `Get-LabWazuhAgentStatus.ps1` excludes the Wazuh Manager's own agent `000`: whatever their state, they are simply never matched against and never affect the result, rather than being detected and then special-cased.

**Classification.** Per Design Decision 4: `Healthy` if every expected container is present and reports a running state; `Unhealthy` if the query completes but any expected container is present with a non-running state, its real state reported, for example `exited`, or missing from the response entirely, reported `NotFound`, the Docker analog of `Get-LabADServiceHealth.ps1`'s `NotFound` condition; `Unknown` only if authentication or the container query itself could not be completed. As with `Get-LabWazuhAgentStatus.ps1`, `Invoke-RestMethod` throws a terminating error on its own for both a connection failure and an HTTP error status, so a failed authentication or an unreachable Portainer API reaches this script's `try`/`catch` and classifies `Unknown` without the enumerate-then-match workaround `Get-Service` required in Step Two.

**Credential and token hygiene.** `-Credential` is accepted as a `[PSCredential]`, the same discipline every REST-backed check script in this lab uses. The JSON body `POST /api/auth` is authenticated with, and the JWT bearer token the containers query is authenticated with, exist only inside the function's local scope; the returned `PSCustomObject` carries only container names and states, the overall `Status`, and a `Message` drawn from the exception's own text on failure, and neither the credential nor the token is written to the console, placed on the returned object, or included in the standalone report. The Pester suite asserts this directly.

**Pester coverage.** `Get-LabDockerServiceStatus.Tests.ps1` mocks `Invoke-RestMethod`, distinguishing the auth call from the containers call by `-Uri` in each `ParameterFilter`, the same pattern Step Three established. The test credential was built from an empty `[System.Security.SecureString]::new()`, per Lab 03's `PSAvoidUsingConvertToSecureStringWithPlainText` finding. Seventeen tests are written across ten Contexts: Dot-sourcing behavior, Read-only behavior, the three classification branches (Healthy; Unhealthy for a stopped container and, separately, for a missing container, plus a dedicated exclusion test confirming `frontend` and `backend` never affect the result even when present and exited; Unknown for an authentication failure and, separately, for a containers-query failure), a Real-environment baseline Context reproducing Step One's exact ten-container live finding and asserting the result is driven only by the three monitoring containers, Parameter defaults and pass-through, Credential and token hygiene, the `-ExportPath` CSV branch, and a Response deserialization Context, added after Step Four's own live run surfaced a defect these other sixteen tests had not caught, covered in full in Troubleshooting and Adjustments below.

```powershell
Invoke-Pester -Path C:\Scripts\Get-LabDockerServiceStatus.Tests.ps1 -Output Detailed
```

Sixteen tests, the suite as it stood before the defect below was found and the seventeenth test written, passed on the first run: `Discovery found 16 tests in 224ms`, `Tests Passed: 16, Failed: 0, Skipped: 0, Inconclusive: 0, NotRun: 0`.

**Analysis was clean on the first pass, unlike Steps Two and Three.**

```powershell
Invoke-ScriptAnalyzer -Path C:\Scripts\Get-LabDockerServiceStatus.ps1 -Settings C:\Scripts\PSScriptAnalyzerSettings.psd1
Invoke-ScriptAnalyzer -Path C:\Scripts\Get-LabDockerServiceStatus.Tests.ps1 -Settings C:\Scripts\PSScriptAnalyzerSettings.psd1
```

Both invocations returned to the prompt with no output. Unlike `Get-LabADServiceHealth.Tests.ps1`'s `PSAvoidUsingComputerNameHardcoded` finding in Step Two or `Get-LabWazuhAgentStatus.Tests.ps1`'s `PSUseSingularNouns` finding in Step Three, neither script nor test file triggered a finding here.

<p align="center">
  <img src="../../images/automation-and-scripting/05-scheduled-health-reporting/17-docker-first-pester-and-analyzer-clean-pass.jpg" width="900">
</p>

<p align="center">
  <em>Invoke-Pester against Get-LabDockerServiceStatus.Tests.ps1: 16 tests discovered across nine Contexts, all sixteen passed on the first run, followed by both Invoke-ScriptAnalyzer invocations returning to the prompt with no output, a clean pass with no finding to fix.</em>
</p>

**A clean Pester run and a clean analyzer pass were not enough: the first live run surfaced a real defect.** Per the plan, a live run against Portainer was performed once Pester and Analyzer were both clean, since Step One had already proven the API reachable and authenticating under the admin account used there.

```powershell
$cred = Get-Credential -Message "Portainer admin API credentials"
.\Get-LabDockerServiceStatus.ps1 -Credential $cred
```

This did not return the expected result. Seven of the eight expected containers came back `NotFound`, and `single-node-wazuh.dashboard-1` came back with `ContainerState` showing `{running, running, running, exited...}`, a collection value where a single state string was expected. `OverallStatus` was `Unhealthy` on every row, but not for the reason Step One's plan anticipated. This was a real defect in the script, not the monitoring-stack outage the plan expected this check to catch, and it is root-caused in full, with the diagnostic sequence that found it, in Troubleshooting and Adjustments below.

<p align="center">
  <img src="../../images/automation-and-scripting/05-scheduled-health-reporting/18-first-live-run-array-nesting-defect.jpg" width="900">
</p>

<p align="center">
  <em>The first live run: seven of eight expected containers reported NotFound, and single-node-wazuh.dashboard-1 reported a collection value, {running, running, running, exited...}, in place of a single state. A real defect, resolved below, not the expected outage.</em>
</p>

**After the fix described in Troubleshooting and Adjustments, Pester and Analyzer were re-run.**

```powershell
Invoke-Pester -Path C:\Scripts\Get-LabDockerServiceStatus.Tests.ps1 -Output Detailed
Invoke-ScriptAnalyzer -Path C:\Scripts\Get-LabDockerServiceStatus.ps1 -Settings C:\Scripts\PSScriptAnalyzerSettings.psd1
Invoke-ScriptAnalyzer -Path C:\Scripts\Get-LabDockerServiceStatus.Tests.ps1 -Settings C:\Scripts\PSScriptAnalyzerSettings.psd1
```

Seventeen tests passed, the sixteen original tests plus the new regression test covering the fixed defect: `Discovery found 17 tests in 118ms`, `Tests Passed: 17, Failed: 0, Skipped: 0, Inconclusive: 0, NotRun: 0`. Both `Invoke-ScriptAnalyzer` invocations again returned to the prompt with no output.

<p align="center">
  <img src="../../images/automation-and-scripting/05-scheduled-health-reporting/22-post-fix-pester-and-analyzer-clean-pass.jpg" width="900">
</p>

<p align="center">
  <em>Invoke-Pester re-run after the array-deserialization fix: 17 tests discovered across ten Contexts, all seventeen passed, including the new Response deserialization Context, followed by both Invoke-ScriptAnalyzer invocations returning to the prompt with no output: a clean pass.</em>
</p>

**The live run was repeated, and this time returned the result Step One's plan anticipated.**

```powershell
.\Get-LabDockerServiceStatus.ps1 -Credential $cred
```

This returned a real `Unhealthy` result, driven by exactly the condition Step One deliberately left in place: `single-node-wazuh.manager-1`, `single-node-wazuh.indexer-1`, `single-node-wazuh.dashboard-1`, `nginx-proxy-manager`, and `portainer` all reported `running`; `prometheus`, `grafana`, and `node-exporter` all reported `exited`. This matches Step One's own live container baseline exactly, and it is this check working correctly on its first genuine live run, catching the monitoring-stack outage Step One found and deliberately did not remediate, not a defect. Remediation remains deferred to Step Seven, per the plan.

<p align="center">
  <img src="../../images/automation-and-scripting/05-scheduled-health-reporting/23-post-fix-docker-service-status-live-run.jpg" width="900">
</p>

<p align="center">
  <em>.\Get-LabDockerServiceStatus.ps1 run standalone against Portainer, after the fix: the Wazuh stack, nginx-proxy-manager, and portainer reporting running; prometheus, grafana, and node-exporter reporting exited; OverallStatus Unhealthy on every row. The monitoring-stack outage Step One found, correctly caught.</em>
</p>

### Step Five - Built Invoke-LabHealthReport.ps1, the Orchestrator

`Invoke-LabHealthReport.ps1` was built alongside the three check scripts in the same `infrastructure/automation-and-scripting/scheduled-health-reporting/` folder. It is the script Step Six will register in Task Scheduler, so it is the environment's single entry point: an operator or a scheduled firing runs this one script, not the three check scripts individually. It accepts `-WazuhCredential` and `-PortainerCredential` (both `[PSCredential]`) and `-ReportDirectory`; per Design Decision 2, it does not re-declare any of the three checks' own classification parameters (target computer, service list, agent list, base URIs, endpoint ID, expected-container list), relying entirely on each check's own defaults, the same defaults Steps Two through Four already built and validated.

**The dot-source placement is a correctness requirement, not a style choice.** Per Design Decision 6, the three check scripts are dot-sourced once, at this file's own top level, resolved relative to `$PSScriptRoot`, rather than inside the `Invoke-LabHealthReport` function body:

```powershell
. (Join-Path -Path $PSScriptRoot -ChildPath 'Get-LabADServiceHealth.ps1')
. (Join-Path -Path $PSScriptRoot -ChildPath 'Get-LabWazuhAgentStatus.ps1')
. (Join-Path -Path $PSScriptRoot -ChildPath 'Get-LabDockerServiceStatus.ps1')
```

Placed at the top level, the three check functions are defined exactly once, whenever this file is loaded, by dot-sourcing or by a direct run. A Pester suite can then dot-source this file, which dot-sources the three checks and defines the real functions, `Mock` those three functions by name, and invoke `Invoke-LabHealthReport`, and the mocks take effect because PowerShell resolves a bare function call by name at call time. Had the dot-source calls instead lived inside the `Invoke-LabHealthReport` function body, every call to that function would re-dot-source the three check scripts and redefine the real functions over the top of any active `Mock`, making the aggregation untestable.

**Parameter-name collision is handled by naming, not by scoping.** Because the three check scripts are dot-sourced into this file's own scope, each one's own top-level `param` block variables (`$ComputerName`, `$ServiceName`, `$BaseUri`, `$Credential`, `$AgentName`, `$EndpointId`, `$ExpectedContainer`, `$ExportPath`) land in this file's scope as a side effect, the last-dot-sourced script's default winning for any name more than one check script happens to share. None of that is used by this script; `-WazuhCredential`, `-PortainerCredential`, and `-ReportDirectory` were named specifically so that none of them collides with any name the three dot-sourced check scripts already bind, rather than scoping the dot-source calls to prevent the collision.

As in every check script in this lab, the top-level `-WazuhCredential` and `-PortainerCredential` parameters carry no `Mandatory` attribute and no default, and neither does `-ReportDirectory`: a `Mandatory` parameter at the top of this file would make PowerShell prompt for it the moment the file is dot-sourced, which would hang a Pester run waiting on input. The standalone path inside the guard at the bottom of the file prompts for whichever of the three is missing, `Get-Credential` for the two credentials and `Read-Host` for the report directory, only when the file is run directly.

**Aggregation (Design Decision 4, worst-wins).** `Invoke-LabHealthReport` calls `Get-LabADServiceHealth`, `Get-LabWazuhAgentStatus`, and `Get-LabDockerServiceStatus` by name and aggregates their three `Status` values: any `Unhealthy` check makes the overall status `Unhealthy`, regardless of the other two; failing that, any `Unknown` check makes it `Unknown`; only if all three report `Healthy` is the overall status `Healthy`. This is pure logic with no external dependency of its own, and it is this lab's highest-value Pester target, per Design Decision 6.

**Report output (Design Decision 3).** A console table (`CheckName` and `Status` for the three checks, plus the aggregated `Overall` row) is printed on an interactive run, built by a separate `Get-LabHealthReportSummaryTable` function rather than inline in the guard, so it can be called directly against an already-mocked result in tests (see Pester coverage, below). A timestamped, self-contained HTML summary is always written to `-ReportDirectory`, on every run, whether invoked by an operator or, once Step Six registers it, by Task Scheduler, built by a helper function named `ConvertTo-LabHealthReportHtml` (named that from an analyzer finding covered under Analysis, below, not from its own first draft). An HTML summary was chosen over a flat CSV row, matching Lab 04's own precedent, per Design Decision 3's text, of departing from a flat table when the data's shape does not reduce cleanly to a single CSV row; unlike the three check scripts, whose optional `-ExportPath` still writes a flat CSV per Lab 02's and Lab 04's convention, this orchestrator's report has no flat-row equivalent to fall back to, since it is rolling three different check types into one overall status. Every value the HTML report renders is passed through `[System.Net.WebUtility]::HtmlEncode`, including a check's own `Message` text, before being embedded. The report file is an exported artifact, not a repository file: it is written only to the runtime `-ReportDirectory` the operator supplies, and it stays off WIN11-CLIENT01's own `C:\Scripts` working copy of the repository entirely.

**Credential and token hygiene.** `-WazuhCredential` and `-PortainerCredential` are passed straight through to the two REST-backed checks without ever being read from, echoed, or stored by this script. The three check functions already exclude their own credentials and JWTs from their returned objects, per Steps Three and Four's own hygiene; this script's console table and HTML report both render only `CheckName` and `Status` values drawn from those already-clean returned objects, so neither surface can carry a credential or a token forward. The Pester suite asserts this directly rather than assuming it.

**A testability boundary worth stating plainly.** Because the three check scripts are dot-sourced unconditionally at this file's own top level, running the file directly with the call operator (`& .\Invoke-LabHealthReport.ps1`) re-executes those three dot-source statements in that run's own local scope, which redefines the three check functions as their real, network-calling selves in that local scope, shadowing any `Mock` a caller further up the scope chain had set. The three check scripts do not have this issue, since none of them dot-sources anything else; this script does, and it is a direct consequence of Design Decision 6's own dot-source-for-mockability requirement. The console-table rendering is factored into its own function for exactly this reason, so the Pester suite can call it directly against a `$result` it already has from an already-mocked `Invoke-LabHealthReport` call, rather than by invoking the file with `&` the way the three check scripts' own test suites do for their console-output-hygiene assertions.

**Pester coverage.** `Invoke-LabHealthReport.Tests.ps1` mocks the three check functions by name rather than their underlying commands, the only way this script's aggregation logic can be exercised in isolation, per Design Decision 6. `BeforeEach` dot-sources the orchestrator fresh for every test, which defines `Invoke-LabHealthReport` and, as a side effect of the orchestrator's own top-level dot-sourcing, the three real check functions, so `Mock` calls placed after that dot-source replace the real functions rather than something undefined. The test credentials were built from an empty `[System.Security.SecureString]::new()`, per Lab 03's own finding, and every direct invocation supplies both credentials and `-ReportDirectory` explicitly, so no `Get-Credential` or `Read-Host` prompt can hang the suite; `TestDrive:\` is used for `-ReportDirectory` throughout.

Thirty-eight tests were written across five Contexts: Dot-sourcing behavior (asserting `Invoke-LabHealthReport` is defined, the three check functions are defined as a side effect, and none of them is invoked); Read-only / call-count behavior (each check function called exactly once per run, and each credential passed through to the correct check); Aggregation, twenty-seven tests, one per combination of the three checks' `Healthy`/`Unhealthy`/`Unknown` states, built data-driven with `It -ForEach` over a table computed in the Context body (see Troubleshooting and Adjustments for why the data has to be built there, and as `Hashtable` entries, not inside a `BeforeAll` and not as `PSCustomObject` entries); Report file behavior (a timestamped HTML file written on every run, the report directory created if missing, the overall status and all three check names present in the file, and a distinct file on each of two successive runs); and Credential and token hygiene (neither credential nor a token on the returned object, in the report file, or in the rendered console summary table).

```powershell
Invoke-Pester -Path C:\Scripts\Invoke-LabHealthReport.Tests.ps1 -Output Detailed
```

All thirty-eight tests passed: `Discovery found 38 tests in 68ms`, `Tests Passed: 38, Failed: 0, Skipped: 0, Inconclusive: 0, NotRun: 0`. Getting there took two real, back-to-back Pester authoring defects, both caught by real runs rather than review, covered in full in Troubleshooting and Adjustments below.

<p align="center">
  <img src="../../images/automation-and-scripting/05-scheduled-health-reporting/24-pester-first-run-aggregation-missing.jpg" width="900">
</p>

<p align="center">
  <em>The first real Invoke-Pester run: only eleven tests discovered, the twenty-seven-case Aggregation Context silently absent from both the test tree and the output, no error or warning printed anywhere.</em>
</p>

<p align="center">
  <img src="../../images/automation-and-scripting/05-scheduled-health-reporting/25-pester-aggregation-psobject-binding-failure.jpg" width="900">
</p>

<p align="center">
  <em>After fixing the Discovery-timing defect, all thirty-eight tests were discovered, but all twenty-seven Aggregation cases failed: every title rendered with blank AD=/Wazuh=/Docker= placeholders, and every assertion failed with "Expected $null, but got 'Healthy'".</em>
</p>

<p align="center">
  <img src="../../images/automation-and-scripting/05-scheduled-health-reporting/26-pester-aggregation-hashtable-fix-clean-pass.jpg" width="900">
</p>

<p align="center">
  <em>After switching the Aggregation Context's combinations from PSCustomObject to Hashtable entries, all thirty-eight tests passed, with every Aggregation title now showing its real AD/Wazuh/Docker/Overall values.</em>
</p>

**Analysis was not clean on the first pass.**

```powershell
Invoke-ScriptAnalyzer -Path C:\Scripts\Invoke-LabHealthReport.ps1 -Settings C:\Scripts\PSScriptAnalyzerSettings.psd1
Invoke-ScriptAnalyzer -Path C:\Scripts\Invoke-LabHealthReport.Tests.ps1 -Settings C:\Scripts\PSScriptAnalyzerSettings.psd1
```

This returned three findings, all against the script, the test file clean on the first pass:

| RuleName | Severity | ScriptName | Line | Message |
|---|---|---|---|---|
| `PSUseShouldProcessForStateChangingFunctions` | Warning | `Invoke-LabHealthReport.ps1` | 150 | Function 'New-LabHealthReportHtml' has verb that could change system state. Therefore, the function has to support 'ShouldProcess'. |
| `PSUseOutputTypeCorrectly` | Information | `Invoke-LabHealthReport.ps1` | 222 | The cmdlet 'New-LabHealthReportHtml' returns an object of type 'System.String' but this type is not declared in the OutputType attribute. |
| `PSUseOutputTypeCorrectly` | Information | `Invoke-LabHealthReport.ps1` | 279 | The cmdlet 'Get-LabHealthReportSummaryTable' returns an object of type 'System.Array' but this type is not declared in the OutputType attribute. |

<p align="center">
  <img src="../../images/automation-and-scripting/05-scheduled-health-reporting/27-analyzer-shouldprocess-and-outputtype-findings.jpg" width="900">
</p>

<p align="center">
  <em>Invoke-ScriptAnalyzer returning three findings against Invoke-LabHealthReport.ps1 (PSUseShouldProcessForStateChangingFunctions on the HTML-building helper, and two PSUseOutputTypeCorrectly findings), and Invoke-LabHealthReport.Tests.ps1 returning to the prompt with no output, clean on the first pass.</em>
</p>

`PSUseShouldProcessForStateChangingFunctions` fired because the HTML-building helper was originally named `New-LabHealthReportHtml`, and `New-` is one of the verbs PSScriptAnalyzer treats as state-changing, even though the function only builds and returns a string with no side effect of its own; the actual file write happens in `Invoke-LabHealthReport`, via `Out-File`. The fix was a rename, not a suppression: `New-LabHealthReportHtml` became `ConvertTo-LabHealthReportHtml`, the same relationship PowerShell's own `ConvertTo-Html` cmdlet has to the data it renders, and a verb the rule does not flag. The two `PSUseOutputTypeCorrectly` findings were fixed by adding `OutputType` attributes: `[OutputType([string])]` on `ConvertTo-LabHealthReportHtml`, unambiguous since the function always returns a single string, and `[OutputType([PSCustomObject])]` on `Get-LabHealthReportSummaryTable`, describing the collection's element type rather than the array itself.

```powershell
Invoke-Pester -Path C:\Scripts\Invoke-LabHealthReport.Tests.ps1 -Output Detailed
Invoke-ScriptAnalyzer -Path C:\Scripts\Invoke-LabHealthReport.ps1 -Settings C:\Scripts\PSScriptAnalyzerSettings.psd1
Invoke-ScriptAnalyzer -Path C:\Scripts\Invoke-LabHealthReport.Tests.ps1 -Settings C:\Scripts\PSScriptAnalyzerSettings.psd1
```

Pester still passed 38 of 38, confirming the rename did not affect any assertion, but the analyzer returned one remaining finding: `Get-LabHealthReportSummaryTable`'s declared `[OutputType([PSCustomObject])]` did not match what the analyzer had actually inferred from the function body, `System.Array`, since the function's last statement is an array-literal expression (`@(...)`) rather than a single object.

<p align="center">
  <img src="../../images/automation-and-scripting/05-scheduled-health-reporting/28-analyzer-outputtype-array-mismatch-remaining.jpg" width="900">
</p>

<p align="center">
  <em>After the rename and the first OutputType attempt: Pester still 38 of 38, but Invoke-ScriptAnalyzer returning one remaining PSUseOutputTypeCorrectly finding, "returns an object of type 'System.Array'", against Get-LabHealthReportSummaryTable's declared [PSCustomObject].</em>
</p>

The declared attribute was corrected to `[OutputType([System.Array])]`, matching the analyzer's own inferred type literally rather than the collection's element type.

```powershell
Invoke-Pester -Path C:\Scripts\Invoke-LabHealthReport.Tests.ps1 -Output Detailed
Invoke-ScriptAnalyzer -Path C:\Scripts\Invoke-LabHealthReport.ps1 -Settings C:\Scripts\PSScriptAnalyzerSettings.psd1
Invoke-ScriptAnalyzer -Path C:\Scripts\Invoke-LabHealthReport.Tests.ps1 -Settings C:\Scripts\PSScriptAnalyzerSettings.psd1
```

Pester passed 38 of 38 again, and both `Invoke-ScriptAnalyzer` invocations returned to the prompt with no output: a clean pass.

<p align="center">
  <img src="../../images/automation-and-scripting/05-scheduled-health-reporting/29-pester-and-analyzer-clean-pass.jpg" width="900">
</p>

<p align="center">
  <em>Invoke-Pester re-run confirming all thirty-eight tests still passing after the OutputType correction, followed by both Invoke-ScriptAnalyzer invocations returning to the prompt with no output: a clean pass.</em>
</p>

**A first live-run attempt surfaced one further real defect, in the orchestrator's own interactive guard rather than in anything Pester or Analyzer covers.** Per the plan, once Pester and Analyzer were both clean, a live run was attempted against the real environment.

```powershell
.\Invoke-LabHealthReport.ps1
```

Both `Get-Credential` prompts were answered, but the report-directory `Read-Host` prompt was left blank. `Read-Host` returned an empty string, which was then passed through to `Invoke-LabHealthReport`'s own `Mandatory [string]$ReportDirectory` parameter; PowerShell's built-in parameter validation rejected the empty string with `ParameterArgumentValidationErrorEmptyStringNotAllowed`. That rejection is a terminating error for the failed statement, but not for the top-level script under the default `$ErrorActionPreference = 'Continue'`, so execution continued into the next lines with `$result` left `$null`: a blank summary table (headers only, `CheckName`/`Status` columns empty except a literal `Overall` row with no status) and an empty `Report written to:` line, rather than a clean stop. No live check function had actually run, since the parameter-binding failure happened before `Invoke-LabHealthReport`'s own body ever started, so nothing had reached DC01, Wazuh, or Portainer at this point.

The fix was to validate all three interactively-resolved inputs explicitly, immediately after resolving each one, and `throw` a clear, specific error right there if any is missing, rather than trusting PowerShell's own parameter binding to catch it later:

```powershell
if ([string]::IsNullOrWhiteSpace($ReportDirectory)) {
    throw 'A report directory is required to run this report; the prompt was left empty.'
}
```

The same explicit check was added for both credentials, since `Get-Credential` returns `$null` on a cancelled prompt rather than throwing, and an explicit `$null` passed to a `Mandatory` parameter of a reference type like `[PSCredential]` is accepted silently by PowerShell, unlike the empty-string case, which would otherwise let a cancelled prompt fail much later and far less clearly, deep inside a REST call. A second attempt against the same blank report-directory input confirmed the fix: the script now failed immediately with the intended message, `A report directory is required to run this report; the prompt was left empty.`, rather than continuing into a broken run.

```powershell
Invoke-Pester -Path C:\Scripts\Invoke-LabHealthReport.Tests.ps1 -Output Detailed
Invoke-ScriptAnalyzer -Path C:\Scripts\Invoke-LabHealthReport.ps1 -Settings C:\Scripts\PSScriptAnalyzerSettings.psd1
Invoke-ScriptAnalyzer -Path C:\Scripts\Invoke-LabHealthReport.Tests.ps1 -Settings C:\Scripts\PSScriptAnalyzerSettings.psd1
```

Re-run after the guard fix, Pester still passed 38 of 38 and both `Invoke-ScriptAnalyzer` invocations again returned to the prompt with no output, confirming the fix, confined to the guard's own input validation, had not touched anything either suite covers.

<p align="center">
  <img src="../../images/automation-and-scripting/05-scheduled-health-reporting/30-pester-and-analyzer-clean-pass-after-guard-fix.jpg" width="900">
</p>

<p align="center">
  <em>Invoke-Pester re-run after the interactive-guard input-validation fix: still 38 of 38, followed by both Invoke-ScriptAnalyzer invocations returning to the prompt with no output, confirming the fix did not affect either suite.</em>
</p>

**The live run was then repeated for real, against the live environment, and returned the result the plan anticipated.**

```powershell
.\Invoke-LabHealthReport.ps1
```

Both credential prompts were answered and a real report directory (`C:\Reports`) was supplied. This returned a real `Unhealthy` overall result: `ADServiceHealth` `Healthy` and `WazuhAgentStatus` `Healthy`, matching Steps Two and Three's own live-run baselines exactly, and `DockerServiceStatus` `Unhealthy`, matching Step Four's own live-run baseline exactly, driven by the same still-unremediated monitoring-stack outage Step One found and deliberately left in place. The report was written to `C:\Reports\LabHealthReport-20260819-124807.html`.

<p align="center">
  <img src="../../images/automation-and-scripting/05-scheduled-health-reporting/31-live-run-unhealthy-overall-status.jpg" width="900">
</p>

<p align="center">
  <em>.\Invoke-LabHealthReport.ps1 run standalone: the console summary table showing ADServiceHealth and WazuhAgentStatus Healthy, DockerServiceStatus Unhealthy, Overall Unhealthy, and the report path written to C:\Reports\LabHealthReport-20260819-124807.html.</em>
</p>

<p align="center">
  <img src="../../images/automation-and-scripting/05-scheduled-health-reporting/32-live-run-html-report.jpg" width="900">
</p>

<p align="center">
  <em>The generated HTML report opened in a browser: overall status Unhealthy in red; ADServiceHealth Healthy with all six services Running; WazuhAgentStatus Healthy with all three agents active; DockerServiceStatus Unhealthy, the Wazuh stack, nginx-proxy-manager, and portainer running, prometheus, grafana, and node-exporter exited, matching Step One's and Step Four's own baselines exactly.</em>
</p>

This is worst-wins, from Design Decision 4, working exactly as intended: one real fault, in one of the three checks, correctly propagated to the overall status rather than averaged away or masked by the other two checks' `Healthy` results. It is not a failure of the orchestrator, Pester coverage, or the live run; it is the same intended outcome Step One's plan anticipated back when the monitoring-stack outage was first found and deliberately left unremediated, now demonstrated end to end through the finished orchestrator for the first time. Remediation and a `Healthy` before/after comparison remain deferred to Step Seven, per the plan.

### Step Six - Make the Orchestrator Schedulable, Then Register the Scheduled Task (planned)

Planned in two phases, because the orchestrator as built in Step Five cannot be scheduled as it stands. Its only executable path is the `$MyInvocation.InvocationName -ne '.'` guard, and that guard resolves both credentials with `Get-Credential` and the report directory with `Read-Host`. Task Scheduler cannot answer a prompt, and a `[PSCredential]` cannot be passed on a `powershell.exe -File` command line, so registering the script exactly as it stands today would produce either an immediate throw or a process blocked on a prompt against a window station that does not exist. Which of the two it would do is untested, and neither is a firing worth observing. This is not a defect in Step Five's work, which was built for the interactive runs it was validated against; it is the remaining gap between an operator-invoked script and an unattended one, and closing it is what Step Six-A is for.

**Step Six-A, planned: give the orchestrator a non-interactive input path.** Planned to add an optional `-CredentialDirectory` parameter to `Invoke-LabHealthReport.ps1` and a small `Get-LabStoredCredential` function in the same file, which wraps `Import-CliXml` and validates explicitly, throwing a clear error if the file is absent or does not deserialize to a `[PSCredential]`, rather than letting a malformed file fail later inside a REST call. The guard calls it for whichever credential was not supplied as a parameter, keeping `Invoke-LabHealthReport`'s own signature and all thirty-eight of its existing tests untouched; the new function is dot-sourceable and therefore testable directly, independent of the guard the orchestrator's suite deliberately does not invoke. Planned to write the two credential files with `Export-CliXml` in an interactive session as `labadmin`, which is both the account that runs the task and the account whose DPAPI key protects the files, per Design Decision 5.

Planned, in the same phase, to provision the least-privileged Wazuh and Portainer API accounts Design Decision 5 commits to, replacing the broad admin accounts Steps One, Three, and Four used, and to confirm live that each still returns the data its check script needs rather than assuming the platform's role model allows it. Planned to author the new function and its tests under the Lab 03 standard from the outset, per ADR-017, with `[OutputType([PSCredential])]` declared, given this track's repeated history with `PSUseOutputTypeCorrectly` in Step Five.

**Step Six-B, planned: register the task and observe a real firing.** Planned to build `Register-LabHealthReportTask.ps1`, taking a `[PSCredential]` for the run-as account rather than separate username and password parameters, both because that is the discipline every credential in this lab already follows and because a `Password` parameter would trip `PSAvoidUsingUserNameAndPasswordParams` and `PSAvoidUsingPlainTextForPassword`; the plaintext password `Register-ScheduledTask` requires is unwrapped at the call site only. `Register-` is on PSScriptAnalyzer's state-changing-verb list, so this script will implement `SupportsShouldProcess` properly rather than renaming its way around the rule as Step Five's `ConvertTo-LabHealthReportHtml` did, which makes it the first script in the track to do so. Its Pester suite mocks the `ScheduledTasks` cmdlets, per the Lab 03 standard, so the registration logic is verified without registering anything.

The action is planned as `powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File C:\Scripts\Invoke-LabHealthReport.ps1` with the credential directory and report directory supplied as arguments. `-NonInteractive` is deliberate: if any prompt survives Step Six-A, it should fail the run immediately and visibly rather than hanging the task until the execution time limit expires. Registration itself requires an elevated session, per Design Decision 5.

Planned to observe at least one scheduled, not manually triggered, firing before considering this step complete. A manual run from the Task Scheduler UI proves the action string works; it does not prove the non-interactive context does, which is the whole question. Planned to observe the firing with the operator logged off rather than merely locked, since "run whether the user is logged on or not" is the configuration actually being tested.

**Evidence planned for this step,** so that it counts as validated rather than assumed: `Get-ScheduledTask` and `Get-ScheduledTaskInfo` output showing `LastRunTime` at the trigger time, `LastTaskResult` of `0`, and a plausible `NextRunTime`; a directory listing of the report path showing a file whose timestamp matches that firing and is distinct from any manual run; the report's own contents matching what a manual run of the same scripts returns; and Task Scheduler's operational history for the task. That last item has a prerequisite worth noting before the firing rather than after: Task Scheduler's "All Tasks History" is disabled by default on Windows, so it has to be enabled ahead of the run or the history will not exist to capture.

### Step Seven - Run All Checks Live and Validate Against Independent Sources (planned)

Each of the four scripts has already had one live run, in Steps Two through Five, and those runs established that the checks work; what they did not do is validate the reported signals against anything outside the scripts themselves. That is this step's first job: cross-check each reported signal against the independent source named in Design Decision 7, from an observation taken at the same time as the run being validated rather than against Step One's baseline, which is by now weeks old. The `Unhealthy` results Steps Four and Five already produced are the starting condition here, not a prediction; both were captured live and are documented in past tense in those steps. Once a validated `Unhealthy` run is captured, ideally the scheduled firing Step Six-B observes rather than a manual run, this step will move on to root-causing the monitoring stack outage Step One surfaced, remediating it (restarting `prometheus`, `grafana`, and `node-exporter`, and adding a restart policy to the `monitoring-stack` compose project so it cannot silently sit down for months the way it did between linux infrastructure Lab 06 and this lab's Step One), and re-running the report to confirm both the Docker check and the overall status flip to `Healthy`. The resulting before-and-after, `Unhealthy` on the validated run and `Healthy` after remediation, both ideally captured from scheduled firings rather than manual ones, is planned as the concrete demonstration that the three-state classification and worst-wins aggregation from Design Decision 4 actually discriminate between a real fault and a clean environment, rather than a report that always reads green regardless of what it is checking. Planned to close with a full combined `Invoke-ScriptAnalyzer -Recurse` and `Invoke-Pester` sweep across the entire script library, all scripts and test files across Labs 01 through 05, the same closing move every prior lab in this track has made.

---

## Validation

Once implemented, this lab will be considered validated when:

- `Get-LabADServiceHealth.ps1`'s reported state for DC01's six target services matches a direct, independent `Get-Service` query against DC01
- `Get-LabWazuhAgentStatus.ps1`'s reported state for all three agents matches the Wazuh dashboard's Agents view at `https://192.168.1.226:8443`
- `Get-LabDockerServiceStatus.ps1`'s reported state for the expected container set matches a direct `docker ps`/`docker compose ps` run on Ubuntu Server, not solely the Portainer UI, per Design Decision 7
- `Invoke-LabHealthReport.ps1`'s aggregated overall status correctly reflects the worst-wins rule from Design Decision 4 across the live run's actual combination of per-check results
- the scheduled Task Scheduler job fires on its configured cadence without an operator present and produces a timestamped report file on WIN11-CLIENT01, not only a console table
- none of this lab's four query scripts (`Get-LabADServiceHealth.ps1`, `Get-LabWazuhAgentStatus.ps1`, `Get-LabDockerServiceStatus.ps1`, `Invoke-LabHealthReport.ps1`) is found, on review, to call anything other than a read-only query (`Get-Service`, or a `GET`/authentication `POST` against the Wazuh and Portainer APIs); nothing in this lab modifies AD, Wazuh, or Docker state. `Register-LabHealthReportTask.ps1` is the deliberate exception and is state-changing by definition, but only against WIN11-CLIENT01's own Task Scheduler, and only when run once by an operator; it is never invoked by the scheduled job it registers
- the full combined script library, all scripts and test files across Labs 01 through 05, passes a clean `Invoke-ScriptAnalyzer -Recurse` sweep and a clean combined `Invoke-Pester` run

Consistent with the rule this track has held since Lab 01, no script's reported result will be accepted from its own output alone; each will be checked against the independent source named in Design Decision 7.

---

## Troubleshooting and Adjustments

Steps One through Five are implemented and run against the live environment; the entries below that they resolved are recorded in past tense as encountered-and-resolved. Steps Six and Seven have not been implemented yet, so risks specific to those steps remain in anticipated framing, with one exception: the remote Service Control Manager finding below was settled by a live probe during Step Six's planning, before any of that step was implemented, and is recorded in past tense accordingly because it actually happened.

**PowerShell 5.1's `Invoke-RestMethod` has no `-SkipCertificateCheck` parameter (encountered and resolved, Step One).** The Wazuh stack uses self-signed certificates generated by the `wazuh-certs-generator` container (enterprise Lab 07). The anticipated `[System.Net.ServicePointManager]`-based accommodation (forcing TLS 1.2 and installing a certificate-validation callback) worked on the first attempt against the Wazuh Manager API, with no TLS handshake error. The same accommodation was reapplied against `portainer.local` and did not resolve an HTTPS failure there, but that turned out to be a different problem entirely (see below), not a defect in the accommodation itself.

**`Get-Service -ComputerName` against DC01 is reachable, and requires no elevation (encountered and resolved, Step One).** `Get-Service -ComputerName DC01 -Name NTDS,DNS,Netlogon,Kdc,W32Time,ADWS` succeeded on the first attempt from a non-elevated session, returning all six services as `Running`. The Service Control Manager's remote RPC interface is open between WIN11-CLIENT01 and DC01 with no additional firewall configuration needed, and the `Get-Service` half of Design Decision 5's elevation question is answered: elevation is not required.

**The Wazuh Manager API validates against its own dedicated account, distinct from the Dashboard/Indexer login (encountered and resolved, Step One).** Authentication against `POST /security/user/authenticate` was attempted first with the Dashboard/Indexer `admin` credentials, which the operator had just used successfully to log into the Wazuh Dashboard, and failed twice with `{"title":"Unauthorized","detail":"Invalid credentials"}`. This was not a wrong-password problem but a wrong-account problem: the Manager REST API has its own local user store, separate from the Indexer/OpenSearch account the Dashboard authenticates against. The correct account, `wazuh-wui`, was found in `docker-compose.yml` on Ubuntu Server (`~/infrastructure/security-monitoring-lab/wazuh-docker/single-node/docker-compose.yml`, under the `wazuh.manager` service's `API_USERNAME` environment variable). Authentication succeeded immediately once retried with that account.

**Portainer's proxy host is HTTP-only, not HTTPS (encountered and resolved, Step One).** `https://portainer.local/api/status` failed with `Could not create SSL/TLS secure channel`, even with the TLS 1.2/certificate-policy accommodation freshly reapplied in the same session, ruling out a missing client-side workaround as the cause. Linux infrastructure Lab 04's documentation of the current Portainer access URL, and the reverse proxy lab's own Validated URLs list, both record `http://portainer.local`, not `https://`; the NGINX Proxy Manager proxy host for Portainer has no SSL certificate assigned to it. Plain HTTP to the same hostname succeeded immediately. This is a real design correction, not a workaround: `Get-LabDockerServiceStatus.ps1` will be built against `http://portainer.local`, not an HTTPS URI.

**`Get-Credential`'s dialog failed to accept input in this remote session, and pasting a multi-line block with interactive prompts corrupted input (encountered and resolved, Step One).** The `Get-Credential` Windows Security dialog opened but did not respond to input, a window-station-level issue specific to this remote session rather than a credential problem. Switching to console-based `Read-Host` prompts for username and password resolved it. Pasting the resulting multi-line command block in a single paste then corrupted the input, since the interactive `Read-Host` prompts consumed characters intended for later lines, producing a `Missing closing ')' in expression` parser error and a cascade of unrelated downstream failures (an empty response body, an invalid JWT). Running the same commands one line at a time, waiting for each prompt to resolve before pasting the next, avoided the issue entirely and produced clean output.

**The expected Docker container set is now a live baseline, not documentation, and it includes a real, unexplained outage (encountered, Step One; not resolved, and not remediated in this session).** Portainer's `GET /api/endpoints/3/docker/containers/json?all=true` and an independent `docker ps -a`/`docker compose ls -a` on Ubuntu Server (Design Decision 7) matched exactly: ten containers, the same names, images, and states from both sources. Two containers not previously documented in this lab, `frontend` and `backend`, are explained: they are linux infrastructure Lab 05's own `docker-networking` teaching-lab containers, left running after that lab concluded, and are correctly excluded from the expected-running baseline. The monitoring stack (`prometheus`, `grafana`, `node-exporter`, the `monitoring-stack` compose project) reporting fully `exited(3)` is not explained anywhere in the repository; linux infrastructure Lab 06 is documented `Completed` with no later note of decommissioning, and no ADR mentions it. This was unknown to the operator before this step, root cause has not been investigated, and the stack was deliberately not restarted in this session. Remediation is intentionally deferred to Step Seven, so `Get-LabDockerServiceStatus.ps1`'s first live run catches and reports this as a genuine `Unhealthy` condition rather than validating against an environment quietly fixed ahead of time.

**PSScriptAnalyzer flags a literal value passed to a `-ComputerName` parameter at a call site, not the same parameter's own default value (encountered and resolved, Step Two).** `Get-LabADServiceHealth.Tests.ps1`'s first analyzer pass returned five `PSAvoidUsingComputerNameHardcoded` findings (Error severity), one for each test that called `Get-LabADServiceHealth -ComputerName 'DC01' ...` or `-ComputerName 'DC02'` with a literal string. `Get-LabADServiceHealth.ps1` itself was already clean, because the rule specifically targets a string constant bound to a `ComputerName`-named parameter at a call site, not the same parameter's default value inside a `param` block. The fix was confined to the test file: the two fixture values were hoisted into `$script:TargetComputerName` and `$script:AlternateComputerName` in `BeforeAll`, and every call site and `ParameterFilter` comparison that had referenced the literals directly was switched to reference the variables instead. This cleared the rule without suppressing it in `PSScriptAnalyzerSettings.psd1`, and the Pester suite was re-run afterward and confirmed unaffected, still 10 of 10.

**`Get-Service -ComputerName` with `-Name` and `-ErrorAction SilentlyContinue` misclassified an unreachable target `Unhealthy` instead of `Unknown` (encountered and resolved, Step Two).** As first built, `Get-LabADServiceHealth.ps1` called `Get-Service -ComputerName $ComputerName -Name $ServiceName -ErrorAction SilentlyContinue` inside its `try`/`catch`, and both the script's comments and this Step Two write-up asserted that a connectivity or permission failure against the target "throws a terminating exception regardless of `-ErrorAction` preference," so the `catch` would classify it `Unknown`. A review questioned that claim, and it was checked directly against the live environment rather than argued in the abstract. Running the actual script against a target that does not resolve, `.\Get-LabADServiceHealth.ps1 -ComputerName BOGUS01`, returned all six services `NotFound` and an `OverallStatus` of `Unhealthy`, not `Unknown`, with a blank `Message`. A follow-up probe with `-ErrorVariable` showed why: `Get-Service -ComputerName BOGUS01 -Name NTDS,DNS,Netlogon -ErrorAction SilentlyContinue` reached no `catch` at all (`returned service count = 0`) and instead populated the error variable with one non-terminating `Microsoft.PowerShell.Commands.ServiceCommandException` per requested name, each reading "Cannot find any service with service name 'X'." With `-Name` specified, an unreachable host is reported through the same per-name "cannot find" error an absent-but-reachable service produces, and `-ErrorAction SilentlyContinue` suppresses all of it before the `catch` can see anything, so the check falls through every requested name as `NotFound` and lands on `Unhealthy`. The original assumption was wrong on both counts: the failure was non-terminating, and `-Name` made a connectivity failure indistinguishable from a genuinely absent service. This defeated Design Decision 4's primary `Unknown` case, and the original Unknown Pester test had passed only because its mock used a bare `throw` (always terminating), which did not represent how the real cmdlet behaves.

<p align="center">
  <img src="../../images/automation-and-scripting/05-scheduled-health-reporting/11-bogus-host-misclassified-unhealthy.jpg" width="900">
</p>

<p align="center">
  <em>The live diagnostic: .\Get-LabADServiceHealth.ps1 -ComputerName BOGUS01 returning all six services NotFound and OverallStatus Unhealthy, the misclassification described above and resolved by the enumerate-then-match rework that follows.</em>
</p>

The resolution was to enumerate every service on the target with `Get-Service -ComputerName $ComputerName -ErrorAction Stop`, without `-Name`, and match the requested names against the returned collection in the script. Two further live probes confirmed this shape discriminates the two conditions the earlier form conflated. `Get-Service -ComputerName BOGUS01 -ErrorAction Stop` (no `-Name`) raised a terminating `System.InvalidOperationException`, "Cannot open Service Control Manager on computer 'BOGUS01'. This operation might require other privileges.", which the `try`/`catch` catches and classifies `Unknown`. The same call against the reachable `DC01` returned the host's full service list (209 services), with all six target services present and `Running` and a deliberately bogus name simply absent from the set, so an absent named service still classifies `NotFound`/`Unhealthy` and a healthy DC still classifies `Healthy`. An SCM-open failure from an access-denied or genuinely-offline target reaches `Unknown` by this same terminating-`InvalidOperationException` path; the case verified live here was the non-resolving target.

The change was confined to the error-handling path and the tests and comments that depend on it. The `try` call was switched to the no-`-Name`, `-ErrorAction Stop` form; the script's classification comment was corrected and the "throws terminating regardless of `-ErrorAction`" claim removed. The Unknown Pester test's mock was rewritten to emit the Service-Control-Manager failure as a non-terminating error with `Write-Error` rather than a bare `throw`, so it now depends on the script's `-ErrorAction Stop` to terminate and can no longer pass if the script reverts to suppressing errors. The two pass-through tests, which had asserted `-Name` was passed to `Get-Service`, were reworked to assert that `-ComputerName` and `-ErrorAction Stop` are bound and `-Name` is not, with the explicit-override test additionally confirming the script applies the requested `-ServiceName` by filtering the enumerated set rather than passing it to the cmdlet. The dot-source-no-side-effects guard, the not-found-service handling, the object-return-plus-flattened-CSV design, and the read-only assertions were left untouched. The reworked suite was re-run and returned `Tests Passed: 10, Failed: 0, Skipped: 0, Inconclusive: 0, NotRun: 0`, and `Invoke-ScriptAnalyzer -Path C:\Scripts -Settings C:\Scripts\PSScriptAnalyzerSettings.psd1 -Recurse` returned to the prompt with no output: a clean pass.

<p align="center">
  <img src="../../images/automation-and-scripting/05-scheduled-health-reporting/12-pester-and-analyzer-clean-pass-after-fix.jpg" width="900">
</p>

<p align="center">
  <em>Invoke-Pester re-run after the error-handling fix (the enumerate-then-match rework, distinct from the earlier PSAvoidUsingComputerNameHardcoded fix in screenshot 09) confirming all ten tests still passing, including the rewritten Unknown and pass-through tests, followed by Invoke-ScriptAnalyzer returning to the prompt with no output: a second, separate clean pass.</em>
</p>

**A stored scheduled-task credential is a new, standing security surface for this track (anticipated, later step; scope now settled in Design Decision 5).** Every prior lab's most-privileged operation existed only for the length of an interactive session an operator explicitly started. A scheduled task configured to run whether a user is logged on or not requires a stored credential (via `Register-ScheduledTask -User -Password`, or an equivalent principal configuration) that persists indefinitely. This is not a defect to fix during implementation so much as a property to design around. Design Decision 5 now settles what that property will be in this lab, and the entry immediately below records the live finding that drove it there.

**A plain domain account cannot open the Service Control Manager on DC01, which rules out a least-privileged scheduled-task account (encountered and resolved, Step Six planning).** Design Decision 5 originally carried the run-as account as an open question, with a dedicated least-privileged account as the preferred answer over `labadmin`. Rather than provisioning an account to find out whether that was viable, the existing `testuser01` account was used as a probe, so nothing was created and nothing in the environment changed. A session was started with `runas /user:corp\testuser01 powershell.exe`, and the enumerate-then-match call `Get-LabADServiceHealth.ps1` actually makes was run in it:

```powershell
(Get-Service -ComputerName DC01 -ErrorAction Stop | Measure-Object).Count
```

This failed with a terminating `System.InvalidOperationException`: `Cannot open Service Control Manager on computer 'DC01'. This operation might require other privileges.` This is the same exception, on the same code path, that Step Two's own `BOGUS01` diagnostic produced against an unreachable target, and it is the condition `Get-LabADServiceHealth.ps1` classifies `Unknown`. A least-privileged run-as account would therefore have produced an AD check reporting `Unknown` on every scheduled firing, indefinitely, which is a worse outcome than the exposure it was meant to reduce: an unattended report that silently cannot see one third of what it claims to check.

The resolution was to run the task as `labadmin` and to record the reasoning rather than the conclusion alone. Two routes would have made a least-privileged account work, and both were considered and refused: `sc.exe sdset scmanager` on DC01, refused as a permanent security-descriptor edit on the environment's only domain controller made from a read-only lab, and Server Operators membership, refused as a broader grant than the read-only use actually being made. Least-privilege was preserved where the platform allows it, in the Wazuh and Portainer API accounts, and the task is registered with `-RunLevel Limited` rather than `-RunLevel Highest` on the strength of Step One's non-elevated finding. Full reasoning, including why a gMSA was also rejected, is in Design Decision 5.

**Portainer's endpoint ID is now confirmed (encountered and resolved, Step One).** `GET /api/endpoints` returned a single endpoint, `Id: 3`, `Name: "local"`, not the previously assumed default of `1`. `Get-LabDockerServiceStatus.ps1`'s parameter defaults use `3`.

**PSScriptAnalyzer flags a plural noun on a test-only helper function (encountered and resolved, Step Three).** `Get-LabWazuhAgentStatus.Tests.ps1`'s first analyzer pass returned one `PSUseSingularNouns` finding (Warning severity) against `New-DefaultMockAgents`, a private helper building the fabricated four-agent `GET /agents` response reused across the file's default mocks. `Get-LabWazuhAgentStatus.ps1` itself was already clean; the finding was confined to the test file's own helper naming. The fix was a rename, `New-DefaultMockAgents` to `New-DefaultMockAgentSet`, and its one call site updated to match, with no assertion changed. The suite was re-run afterward and confirmed unaffected, still 15 of 15, and both `Invoke-ScriptAnalyzer` invocations returned to the prompt with no output.

**A live-only defect survived a clean Pester suite and a clean analyzer pass: wrapping a live `Invoke-RestMethod` call directly in `@()` nested this endpoint's top-level JSON array instead of flattening it (encountered and resolved, Step Four).** `Get-LabDockerServiceStatus.ps1`'s containers query originally read `$allContainers = @(Invoke-RestMethod -Uri $containersUri ...)`. Pester was 16 of 16 and both analyzer invocations returned no output, so the first live run was expected to simply confirm Step One's known baseline. It did not: seven of the eight expected containers came back `NotFound`, and `single-node-wazuh.dashboard-1` came back with its `State` showing `{running, running, running, exited...}`, a collection where a single string was expected.

The diagnostic followed the same live-evidence-over-assumption approach Step Two's `BOGUS01` probe used. First, the raw API response was checked directly against a freshly authenticated session: `$containers.Count` was `10`, matching Step One's baseline exactly; `(​$containers | Select-Object -First 1).Names` was a `System.Object[]` holding one slash-prefixed string; `.State` was a plain `System.String`. The raw response was exactly the shape the script's normalization code assumed.

<p align="center">
  <img src="../../images/automation-and-scripting/05-scheduled-health-reporting/19-diagnostic-raw-container-response-shape.jpg" width="900">
</p>

<p align="center">
  <em>Diagnostic: the raw Portainer container response confirmed as 10 items, Names as a one-element System.Object[], State as a System.String, exactly the shape the script's normalization code assumed.</em>
</p>

Second, the script's own normalization and matching code was retyped at the prompt, line for line, against that already-fetched `$containers` variable. It worked perfectly: ten clean rows with slash-stripped names, and a `portainer` lookup returning a single clean `PSCustomObject` with `State = running`. This ruled out the classification logic itself.

<p align="center">
  <img src="../../images/automation-and-scripting/05-scheduled-health-reporting/20-diagnostic-manual-classification-replication.jpg" width="900">
</p>

<p align="center">
  <em>Diagnostic: the script's normalization and matching code, retyped at the prompt against the same live $containers data, produced ten clean rows and a correct single-object portainer match, ruling out the classification logic itself.</em>
</p>

Third, the live script was run again, and then dot-sourced with the function called directly (`. .\Get-LabDockerServiceStatus.ps1; Get-LabDockerServiceStatus -Credential $cred`), bypassing the standalone rendering guard entirely. Both reproduced the identical defect, which ruled out the rendering code and confirmed the bug was inside the function's own live call path, the one difference between the failing runs and the successful manual replication.

<p align="center">
  <img src="../../images/automation-and-scripting/05-scheduled-health-reporting/21-live-run-and-function-call-reproduce-defect.jpg" width="900">
</p>

<p align="center">
  <em>Diagnostic: a direct script re-run and a dot-source-plus-direct-function-call both reproduced the identical defect, isolating it to the function's own live Invoke-RestMethod call rather than the standalone rendering guard.</em>
</p>

The root cause is a PowerShell 5.1 pipeline behavior specific to this endpoint's response shape. The containers endpoint returns a top-level JSON array, unlike the Wazuh agents endpoint, which nests its array under a `data` property. For a top-level array response, `Invoke-RestMethod` can write the entire array to the pipeline as a single object rather than one object per container. A bare assignment, `$containers = Invoke-RestMethod ...`, binds directly to that one emitted object, which happens to be the array itself, so `.Count` reads correctly. But `@()` wrapped around the live command call only collects what the pipeline actually emitted, one object, the whole array, so `@(Invoke-RestMethod ...)` nested that array as a single element instead of flattening it: one entry containing ten containers, rather than ten entries. The normalization loop then ran exactly once, with `$container` bound to the entire array; member enumeration made `$container.Names` and `$container.State` return the property values across all ten containers rather than one, which is why `single-node-wazuh.dashboard-1`, the array's first element, was the only name that "matched," and why its `State` showed as a collection instead of a string. `@()` wrapped around an already-materialized variable does not have this problem, since PowerShell's array-subexpression operator correctly enumerates an expression that already evaluates to an array; only wrapping a live command call, whose cmdlet may itself emit only one pipeline object, is affected.

The fix was confined to the containers-query line: the response is now assigned to `$containersResponse` first, and `$allContainers = @($containersResponse)` wraps that variable rather than the live call. A regression test was added to `Get-LabDockerServiceStatus.Tests.ps1`, in a new Response deserialization Context, that forces Pester's mock to emit the entire container array as a single pipeline object using the unary comma operator (`, (New-DefaultMockContainerSet)`), reproducing the exact shape that had let the defect pass all sixteen original tests; Pester's own `-MockWith` return unrolls an array onto the pipeline element by element, unlike the real cmdlet's behavior for this endpoint, which is why none of the original tests caught it. The reworked suite was re-run and returned `Tests Passed: 17, Failed: 0, Skipped: 0, Inconclusive: 0, NotRun: 0`, both `Invoke-ScriptAnalyzer` invocations again returned to the prompt with no output, and the live run was repeated and returned the `Unhealthy` result Step One's baseline predicted, screenshots for all three in Step Four's Implementation section above.

**Pester's `It -ForEach` needs its source data at Discovery time, not Run time (encountered and resolved, Step Five).** The twenty-seven-case Aggregation Context was first written with its combinations built inside a `BeforeAll`. `Describe`/`Context` bodies run during Pester's Discovery phase, but `BeforeAll` only runs later, during the Run phase, so `-ForEach` evaluated against an empty collection at Discovery time and silently generated zero tests for that Context, no error, no warning, the Context header absent from `-Output Detailed` entirely. A real run confirmed it: eleven tests discovered, not the expected thirty-eight, with no indication anything was missing beyond the shortfall in the total. The fix was to build the combinations as plain script code directly in the Context body, not inside `BeforeAll`, per Step Five's Implementation above.

**Pester's `It -ForEach` only projects named variables from Hashtable items, not PSCustomObject (encountered and resolved, Step Five).** After the Discovery-timing fix above, all twenty-seven Aggregation cases ran, but every one failed: `Should -Be` compared against `$null`, and every test title rendered with blank `AD=`/`Wazuh=`/`Docker=` placeholders. Pester only projects an item's members into named variables, and into `<Name>` title placeholders, when the item is an `IDictionary`; a `[PSCustomObject]` item passes through as an unnamed `$_` with nothing bound. Confirmed by a real run showing all twenty-seven cases executing with blank titles and `$null` comparisons. Fixed by changing every combination from `[PSCustomObject]@{...}` to `@{...}`, a plain Hashtable, confirmed by a third real run, thirty-eight of thirty-eight passing with correct titles.

**A blank interactive prompt produced a non-terminating parameter-binding failure that let the script continue into a broken state instead of stopping (encountered and resolved, Step Five).** The orchestrator's guard originally resolved a missing `-ReportDirectory` with `Read-Host` and passed the result straight through with no further check. A live-run attempt left that prompt blank; `Read-Host` returned an empty string, which failed `Invoke-LabHealthReport`'s own `Mandatory [string]$ReportDirectory` parameter binding with `ParameterArgumentValidationErrorEmptyStringNotAllowed`. That failure terminated the one statement but not the top-level script under the default `$ErrorActionPreference`, so execution continued into a blank summary table and an empty report-path line rather than stopping. No live check had actually run, since the parameter-binding failure happened before `Invoke-LabHealthReport`'s own body started. Fixed by validating all three interactively-resolved inputs (`-WazuhCredential`, `-PortainerCredential`, `-ReportDirectory`) explicitly, immediately after resolving each one, and throwing a clear, specific error if any is missing, confirmed by a second attempt against the same blank input failing immediately and cleanly instead of continuing.

---

## Security Considerations

- **Read-only by design.** Every call this lab's scripts make is a query: `Get-Service` with no state-changing parameter, and `GET` requests (plus each API's own authentication `POST`) against the Wazuh and Portainer REST APIs. No script in this lab calls anything capable of modifying Active Directory, Wazuh configuration, or Docker container state, and none is planned to. As in Lab 04, this claim is exercised by the Pester suite, not only reviewed by eye: `Get-LabADServiceHealth.Tests.ps1` asserts `-Times 0` against a representative sample of state-changing service cmdlets, and both `Get-LabWazuhAgentStatus.Tests.ps1` and `Get-LabDockerServiceStatus.Tests.ps1` extend the same claim to their own scripts' calls, each asserting `Invoke-RestMethod` is called exactly twice, once to authenticate and once to query, and never with any other method or URI. `Invoke-LabHealthReport.Tests.ps1` extends the same claim one level up: it asserts each of the three check functions is called exactly once per run, rather than asserting against a state-changing command directly, since the orchestrator itself calls nothing external, only the three already-verified-read-only check functions.
- **A stored, unattended credential is this lab's most significant new exposure, and it is now a confirmed configuration rather than an open question.** Every prior lab in this track ran under `labadmin` for the length of an operator-initiated interactive session. A Task Scheduler job configured to run unattended needs a credential that persists on WIN11-CLIENT01 indefinitely, a materially different exposure than a session-scoped one. Design Decision 5 attempted to reduce that exposure with a dedicated least-privileged account and found, by live probe, that a plain domain account cannot open the Service Control Manager on DC01, and that the only routes to making one work are tier-0 changes to the environment's single domain controller. The task therefore runs as `labadmin`, a Domain Admins member, and this lab states that as a documented compromise rather than an unexamined default. Three things bound it: the task carries `-RunLevel Limited` rather than `-RunLevel Highest`, since Step One proved the check needs no elevation; the two API credentials are least-privileged read-only accounts on their own platforms, which is where least-privilege was actually achievable; and the correct production answer, delegated remote service-query rights on the domain controller under a tiered-administration model, is named in Design Decision 5 rather than quietly omitted. Labs 02 and 04 both carried "a production deployment would use a dedicated account" as an aside; this lab is the first where that aside describes a standing condition of the deployment, and the first where attempting it produced a real finding instead of an intention.
- **The two API credentials are stored on disk under DPAPI, protected by account and machine rather than by a passphrase.** Step Six-A writes the Wazuh and Portainer credentials to a runtime path with `Export-CliXml`, which encrypts them under the exporting account's DPAPI key on the exporting machine. That is the same class of protection Task Scheduler applies to the task's own stored password, and it is why the files must be created in an interactive session as `labadmin`, the account the task runs as. It is worth being precise about what this does and does not protect against: anything running as `labadmin` on WIN11-CLIENT01 can decrypt these files, so the protection is against the files being copied off the machine or read by another account, not against a compromise of the account itself. The files are kept out of the repository, alongside the exported reports, per the same data-handling boundary.
- **API credentials handled the same way Lab 01 handled a plaintext password.** `New-LabUser.ps1` (Lab 01) took its password parameter as a `[SecureString]` rather than plaintext. The Wazuh and Portainer API credentials this lab's scripts need are handled with the same discipline: accepted as `[PSCredential]` by every script that takes one, and, for the unattended run, sourced from the DPAPI-protected files described above rather than embedded as plaintext in any script, argument, or configuration file. `Register-LabHealthReportTask.ps1` follows the same rule for the run-as credential it must hand to `Register-ScheduledTask`, taking a `[PSCredential]` and unwrapping the plaintext password only at that call site, which is also what keeps it clear of `PSAvoidUsingUserNameAndPasswordParams` and `PSAvoidUsingPlainTextForPassword`.
- **Exported reports as a data-handling boundary.** The timestamped health report and any `-ExportPath` CSV output from the individual check scripts can describe service state, agent connectivity, and container status across the whole environment. As in every prior lab, all of it will be kept out of the repository and stored only on WIN11-CLIENT01.
- **The Portainer API path is HTTP-only, so its credential crosses the LAN in cleartext on every call.** Implementation Step One confirmed the only working Portainer path is `http://portainer.local` through NGINX Proxy Manager, not HTTPS; the proxy host has no SSL certificate assigned. `Get-LabDockerServiceStatus.ps1`, built in Step Four, therefore sends Portainer's admin credential (or, for a scheduled run, a stored one) over plain HTTP internally on every invocation, confirmed directly by Step Four's own live runs using the same admin account Step One used. This strengthens, rather than merely restates, the case in Design Decision 5 for a dedicated, least-privileged, read-only Portainer account over the broad admin account used during both steps' diagnostics; a compromised or misconfigured segment of the LAN could otherwise observe the credential in transit.
- **The Wazuh API's certificate-validation bypass is a documented diagnostic accommodation, not a silent workaround.** Implementation Step One's `TrustAllCertsPolicy` accommodation, used to call the Wazuh Manager API's self-signed certificate over HTTPS from PowerShell 5.1, disabled certificate validation for the process's lifetime during that diagnostic session, not just for the Wazuh call. Step Three resolved the open question this left for the finished script: `Get-LabWazuhAgentStatus.ps1` captures the process's existing `CertificatePolicy` and `SecurityProtocol` before applying the accommodation and restores both in a `finally` block once its own authentication and agent-query calls are done, so certificate validation is disabled only for the duration of this script's own REST calls, not for the rest of the calling session.

---

## Outcome

This section describes what the lab is expected to demonstrate once implemented; it will be rewritten in the past tense, describing what was actually built and observed, once implementation is complete, per this repository's documentation conventions.

At the planning stage, the expected outcome is four PowerShell scripts, three focused health checks and one orchestrator, giving the environment a single, on-demand or scheduled answer to "is everything currently healthy," where today that answer requires checking DC01's services, the Wazuh dashboard, and Ubuntu Server's Docker state as three separate manual steps. The lab is expected to close the track's final stated success criterion and, with it, the Infrastructure Automation and Scripting track itself, per ADR-018.

---

## Lessons Learned

Lessons cannot honestly be recorded for the lab as a whole before the scheduled task is registered and observed firing on its own cadence (Step Six) and the monitoring-stack outage is remediated and re-validated alongside the full combined script-library sweep (Step Seven); this section will be completed once that work is done. All four scripts' own findings, through Step Five, are recorded where they belong, in each step's Implementation and in Troubleshooting and Adjustments above, rather than anticipated or duplicated here. At the planning stage for the two remaining steps, the questions most likely to produce further lessons are the run-as-account decision in Design Decision 5 and the second open item it left, whether Task Scheduler's non-interactive execution context affects any of the four scripts' actual behavior, and whether the before/after comparison Step Seven plans, `Unhealthy` before remediation and `Healthy` after, actually demonstrates worst-wins discriminating a real fault from a clean environment the way Design Decision 4 intends.

---

## Sources

Research references consulted during this lab's planning.

**Wazuh Manager REST API (Wazuh documentation)**

- [Getting started - Wazuh server API](https://documentation.wazuh.com/current/user-manual/api/getting-started.html) - confirms the API's default port (`55000`) and JWT authentication flow (`POST /security/user/authenticate`, `Authorization: Bearer` on subsequent requests), the basis for `Get-LabWazuhAgentStatus.ps1`'s authentication step
- [Wazuh server API use cases](https://documentation.wazuh.com/current/user-manual/api/use-cases.html) and [Agent life cycle](https://documentation.wazuh.com/current/user-manual/agents/agent-life-cycle.html) - agent status values (`active`, `disconnected`, `never_connected`, `pending`) this script's classification logic maps to `Healthy`/`Unhealthy`

**Wazuh command monitoring (considered and not adopted as the primary Docker-status path; Design Decision 1)**

- [How it works - Command monitoring](https://documentation.wazuh.com/current/user-manual/capabilities/command-monitoring/how-it-works.html) - documents the command-monitoring pipeline and the requirement for a matching decoder before an event is analyzed
- [Command output analysis - Command monitoring](https://documentation.wazuh.com/current/user-manual/capabilities/command-monitoring/command-output-analysis.html) - the specific finding ("when a decoder is not found, the log is ignored") that informed the decision to prefer Portainer's API over a custom Wazuh decoder/rule for Docker status

**Portainer REST API (Portainer documentation)**

- [API usage examples - Portainer Documentation](https://docs.portainer.io/api/examples) - confirms the authentication endpoint (`POST /api/auth`, JWT), the container-listing endpoint (`GET /api/endpoints/{id}/docker/containers/json`), and the `X-API-Key` header pattern, the basis for `Get-LabDockerServiceStatus.ps1`'s design

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

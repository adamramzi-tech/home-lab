# ADR-016: Run Automation Scripts from a Domain-Joined Client, Not the Domain Controller

## Status

Accepted

---

## Related Decisions

Builds upon:

- [ADR-003: Adopt Remote-First Administration](003-adopt-remote-first-administration.md)
- [ADR-010: Establish Enterprise Infrastructure Track](010-establish-enterprise-infrastructure-track.md)
- [ADR-015: Establish Infrastructure Automation and Scripting Track](015-establish-infrastructure-automation-and-scripting-track.md)

Related documentation:

- [Project README](../../../README.md)
- [Automation and Scripting Track README](../../automation-and-scripting/README.md)
- [02 - Windows Server Lab](../../enterprise-infrastructure/02-windows-server-lab.md)
- [04 - Domain Client Lab](../../enterprise-infrastructure/04-domain-client-lab.md)
- [01 - User Lifecycle Automation](../../automation-and-scripting/01-user-lifecycle-automation.md)

---

# Context

ADR-015 established the Infrastructure Automation and Scripting track and scoped it to PowerShell automation of the existing Active Directory environment. That ADR defined what the track automates but not where the automation runs from.

DC01 is the domain controller for `corp.home.arpa`, promoted in Lab 03. It has the Active Directory module natively available and is capable of running any AD administration script directly. WIN11-CLIENT01 is a domain-joined Windows 11 workstation that received RSAT (including the Active Directory PowerShell module) during Lab 02, and has functioned as the primary management endpoint for AD administration, Group Policy work, and RDP-based access to DC01 since that lab.

This decision became necessary at the start of Lab 01 (User Lifecycle Automation), the first lab to actually execute AD-modifying scripts rather than manually creating objects through ADUC. Every previous piece of AD administration in this environment (`labadmin`, `testuser01`, OU structure, GPOs) was performed from WIN11-CLIENT01 via RSAT, with RDP to DC01 reserved for domain-controller-level administration such as promotion itself, DNS configuration, and post-change validation. Automation scripting was the first point where it needed to be decided explicitly, rather than by convention, whether that pattern would continue.

This decision applies to the automation track as a whole, not to Lab 01 specifically. Every subsequent lab in the track (group and OU administration, GPO reporting, cross-platform validation, scheduled health reporting) will run scripts against DC01's Active Directory, and the execution location needed to be settled once rather than re-justified in each lab document.

---

# Decision

All PowerShell automation scripts in the Infrastructure Automation and Scripting track are run from WIN11-CLIENT01 using the Active Directory PowerShell module provided by RSAT. Scripts are never run locally on DC01 as a matter of routine administration.

Scripts authenticate and operate against DC01 remotely through the Active Directory module's normal LDAP/Kerberos-backed cmdlet behavior, the same mechanism already used for manual AD administration from WIN11-CLIENT01 since Lab 02. No new remoting technology (PowerShell Remoting, WinRM sessions to DC01, and so on) is introduced by this decision; the AD module cmdlets contact DC01 directly.

This establishes a durable convention for the automation track: DC01 is treated strictly as the domain controller, not as an administrative workstation. WIN11-CLIENT01 is the administration and automation execution endpoint for the AD-centric scripts this track produces, consistent with the role it has held for manual AD work since Lab 02 and with the remote-first administration model established in ADR-003 for the environment generally.

Any script or lab in this track that documents a prerequisite of "AD module available" is understood to mean available on WIN11-CLIENT01 via RSAT unless a lab explicitly states otherwise.

---

# Alternatives Considered

## Run Scripts Locally on DC01

Advantages:

- no dependency on RSAT or a second system being available
- avoids any theoretical latency or connectivity issue between client and DC
- the AD module is present on DC01 by default with no additional install step

Reasons rejected:

- inconsistent with how AD administration has been performed in this environment since Lab 02, which would make the automation track the only inconsistent piece of the environment's operational model
- treats the domain controller as a general-purpose administrative workstation, which is not realistic practice; production environments restrict interactive logon and routine script execution on DCs specifically because they are high-value, high-blast-radius systems
- does not reflect how MSP or enterprise help desk work is actually structured, where administrators operate against a DC remotely and rarely if ever log into it directly for routine account work
- would require reintroducing RDP-based interactive session usage on DC01 for day-to-day script execution, which ADR-003's remote-first model and the existing operational pattern have avoided since early in the project

## Introduce PowerShell Remoting (WinRM) from WIN11-CLIENT01 to DC01

Advantages:

- scripts would execute in a session physically running on DC01, closer to how some enterprise environments constrain AD administration through jump hosts or PAW (Privileged Access Workstation) models
- could support more advanced remote session logging or constrained endpoints in the future

Reasons rejected:

- introduces a new remoting layer (WinRM sessions, endpoint configuration, session authentication) that this track does not currently need; the AD module's native remote cmdlet behavior against DC01 already provides the required functionality without it
- adds operational and documentation surface area disproportionate to the current scope of Lab 01
- worth reconsidering later if the automation track expands toward a jump-host or constrained-endpoint model, but premature for the current single-administrator lab environment

## Leave Execution Location Undecided, Determine It Per Lab

Advantages:

- maximum flexibility per lab
- avoids committing to a convention before more of the track exists

Reasons rejected:

- produces exactly the inconsistency this ADR exists to prevent: without a stated convention, later labs would either silently repeat the WIN11-CLIENT01 pattern without documenting why, or drift toward running scripts on DC01 out of convenience during troubleshooting
- inconsistent with the ADR-driven, documentation-first approach used throughout the rest of the project, where architectural conventions that affect more than one lab are recorded once rather than re-decided informally

---

# Consequences

## Positive Outcomes

- establishes a single, consistent execution model for every lab in the automation track, rather than requiring each lab document to re-justify where its scripts run
- keeps DC01 scoped strictly to its role as domain controller, consistent with real-world practice around minimizing interactive use of domain controllers
- reinforces the remote-first administration pattern established in ADR-003, extending it from manual AD administration into scripted automation
- gives the automation track a defensible, professionally realistic operational story: an administrator working from a standard workstation against AD, not logging into the DC itself

## Tradeoffs

- every automation lab in this track now carries an implicit dependency on WIN11-CLIENT01 and its RSAT installation being available and current; if RSAT is not installed or the AD module version drifts from what DC01 supports, this needs to be documented as a prerequisite failure rather than assumed away
- scripts are one network hop removed from the domain controller during execution, which is not a practical issue in this environment but is worth naming as a difference from local execution
- if the environment later introduces a jump host or PAW model, this ADR's decision would need to be revisited rather than simply extended

These tradeoffs are considered acceptable given that the alternative, running scripts on DC01, would be a bigger and more realistic operational risk than the ones accepted here.

---

# Future Reassessment

This decision may be revisited if:

- the automation track expands to require PowerShell Remoting or a jump-host/PAW-style model, at which point the "no new remoting technology" boundary set in the Decision section would need to change
- WIN11-CLIENT01 is decommissioned or replaced, requiring the administrative endpoint role to move to a different system
- the environment introduces a second domain controller or additional administrative workstations, which could change the reasoning around where AD-centric automation is expected to run
- production-style constraints (constrained endpoints, JEA, tiered administration) become a relevant learning objective for the automation track

This decision remains foundational to the Infrastructure Automation and Scripting track's operational model and applies to all labs within that track unless a specific lab documents and justifies a departure from it.

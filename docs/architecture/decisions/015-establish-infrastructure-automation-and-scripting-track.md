# ADR-015: Establish Infrastructure Automation and Scripting Track

## Status

Accepted

## Date

2026-06-19

---

## Related Decisions

Builds upon:

- [ADR-014: Establish Long-Term Infrastructure Expansion Roadmap](014-establish-long-term-infrastructure-expansion-roadmap.md)
- [ADR-010: Establish Enterprise Infrastructure Track](010-establish-enterprise-infrastructure-track.md)
- [ADR-003: Adopt Remote-First Administration](003-adopt-remote-first-administration.md)

Related documentation:

- [Project README](../../../README.md)
- [Architecture Documentation](../README.md)
- [Topology Documentation](../topology.md)
- [Infrastructure Standards and Naming Conventions](../naming-and-scope-standards.md)
- [Recovery and Rollback Strategy](../recovery-and-rollback.md)

---

# Context

ADR-014 established a three-track expansion roadmap and identified Infrastructure Automation and Scripting as the first track to implement. This ADR defines the scope, boundaries, and operational rationale for that track in detail.

With the completion of the enterprise infrastructure track, the environment contains a fully operational Active Directory domain including:

- domain controller (DC01) running Active Directory Domain Services and AD-integrated DNS
- domain-joined Windows client (WIN11-CLIENT01) with Group Policy applied and validated
- Ubuntu Server joined to `corp.home.arpa` with SSSD, Kerberos, and PAM-based access control
- three purpose-built GPOs with OU-based targeting and security group filtering
- Wazuh SIEM with agents enrolled on all three systems
- Docker-based infrastructure running containerized services on Ubuntu Server

Every component of this environment is currently administered manually. User provisioning requires opening Active Directory Users and Computers, creating accounts, assigning group memberships, and validating access individually on each system. GPO state requires running `gpresult` interactively. Environment health requires checking each system and service independently.

This represents a significant operational gap. The infrastructure exists and is validated, but the administrative layer above it has not matured to match. In a production environment, the systems that have been built would be accompanied by scripted, repeatable, documented administrative workflows. Without those workflows, the environment requires institutional knowledge and manual effort to operate consistently.

The automation and scripting track exists to close that gap.

**Why PowerShell and Active Directory are the primary focus**

Active Directory is the identity and access control backbone of the environment. It governs authentication across Windows and Linux systems, controls group membership and OU placement, and is the authoritative source for user and group lifecycle management. Automating AD administration produces operational value across every other system in the environment because every other system depends on AD for identity.

PowerShell is the correct tool for this work. It is the native automation language for Windows Server and Active Directory administration, provides direct access to the Active Directory module and Group Policy module, and is the industry-standard scripting platform for Windows infrastructure roles. Choosing PowerShell for AD automation is not a preference; it is the appropriate professional tool for the domain.

The track is therefore centered on PowerShell automation of Active Directory workflows. This is not a general-purpose scripting track. The objective is to automate the administration of infrastructure that already exists, with Active Directory as the primary automation target.

**Why Docker, Linux, and Wazuh automation are supporting concerns**

Docker, Linux, and Wazuh are components of the environment but they are not the identity layer. Automating them in isolation would produce scripts with narrower operational impact than automating AD workflows that propagate across the entire environment.

These components appear in the track where they reinforce the AD-centric story. Cross-platform validation scripts confirm that AD provisioning produces the expected authentication behavior on Linux. Environment health reporting includes Docker service state and Wazuh agent enrollment as supporting checks that confirm the AD-dependent environment is operating correctly end to end.

Treating Docker, Linux, and Wazuh as equal automation subjects would dilute the track's focus and reduce the coherence of its operational narrative. They are present as supporting concerns, not parallel objectives.

**Why this track precedes Cloud and Hybrid Identity**

The Cloud and Hybrid Identity track will extend the existing on-premises AD environment into Azure via Microsoft Entra Connect. That work introduces a significantly more complex identity architecture: hybrid sync, cloud-side user and group management, and Microsoft 365 administration workflows.

Establishing repeatable, scripted AD administration workflows before introducing hybrid identity is architecturally sound for two reasons. First, the automation patterns developed in this track apply directly to the hybrid environment: user lifecycle scripts, group management workflows, and GPO reporting tools remain relevant and useful after Entra Connect is introduced. Second, operating the on-premises environment through scripted workflows rather than manual tooling reduces the risk of configuration drift as the environment becomes more complex during the cloud identity transition.

Automation is foundational infrastructure for the tracks that follow it.

---

# Decision

The homelab project would formally establish the Infrastructure Automation and Scripting track as Track 3 in the expansion roadmap defined by ADR-014.

**Scope**

The track is focused on automating the administration of the Active Directory environment and its dependent systems using PowerShell. Scope includes:

- user account lifecycle automation: provisioning, modification, disablement, and cleanup
- group membership and OU administration automation
- GPO inventory, RSoP reporting, and policy compliance validation
- cross-platform validation confirming that AD-side changes produce expected authentication behavior on Linux
- scheduled health reporting covering AD service state, Wazuh agent enrollment, and Docker service status as supporting checks

**Boundaries**

The track does not include:

- general-purpose programming or scripting instruction
- automation of infrastructure outside the existing environment
- introduction of new infrastructure components
- cloud or hybrid identity automation (deferred to Track 4)
- network administration scripting (deferred to Track 5)

**Primary tooling**

- PowerShell with the Active Directory module
- PowerShell with the Group Policy module
- Task Scheduler for recurring automation
- Bash for cross-platform validation steps on Ubuntu Server where appropriate

**Deliverables**

When the track is complete:

- a new user can be fully provisioned in AD, assigned to the correct groups and OU, and validated for Linux SSH access by running a single script
- an existing user can be offboarded cleanly, disabled in AD, removed from relevant groups, and confirmed denied on Linux by running a single script
- GPO state and RSoP compliance can be reported on demand without manual intervention
- a scheduled job produces a regular health report covering AD service state, Wazuh agent enrollment, and Docker service status
- all scripts are documented to lab standard: purpose, usage, parameters, expected output, and validation steps
- the `infrastructure/automation-and-scripting/` directory contains a coherent operational script library that can be used without additional context

The track will remain:

- operationally focused on existing infrastructure
- documented to the same standard as previous tracks
- incrementally implemented through a sequence of numbered labs
- architecture-driven with each lab scoped to a coherent operational problem

---

# Alternatives Considered

## Include Docker, Linux, and Wazuh Automation as Equal Track Objectives

Advantages:

- broader automation coverage across the environment
- more varied scripting experience

Reasons rejected:

- reduces the operational coherence of the track
- Active Directory automation has compounding value because AD underpins every other system in the environment
- treating all components as equal subjects produces a collection of disconnected scripts rather than a unified administrative automation layer
- the track is more valuable as a focused, AD-centric capability than as a general scripting survey

## Introduce a General-Purpose Scripting Track Instead

Advantages:

- broader language and tooling coverage
- less dependency on existing infrastructure

Reasons rejected:

- inconsistent with the track model established throughout the repository, which ties each track to specific infrastructure and operational objectives
- scripting for its own sake does not produce operational artifacts that improve the environment
- the value of this track comes from automating real administrative workflows against real infrastructure, not from scripting exercises in isolation

## Defer Automation Until After Cloud and Hybrid Identity

Advantages:

- hybrid identity workflows could be automated alongside on-premises workflows
- single combined automation effort

Reasons rejected:

- on-premises AD automation is a prerequisite foundation for hybrid identity automation, not a parallel effort
- introducing Entra Connect before establishing repeatable on-premises administrative workflows increases the risk of configuration drift during the more complex hybrid transition
- automation tooling developed in this track remains relevant and directly applicable in the hybrid identity environment

---

# Consequences

## Positive Outcomes

- repeatable, documented administrative workflows replace manual operations for core AD tasks
- the environment gains an operational script library that persists and remains useful across subsequent tracks
- cross-platform validation scripts demonstrate end-to-end automation spanning Windows and Linux
- scheduled health reporting produces persistent operational visibility into the environment
- automation patterns established here apply directly to the hybrid identity workflows in Track 4

## Tradeoffs

- the track produces scripts and documentation rather than new deployed infrastructure, which requires a different kind of implementation discipline than previous tracks
- PowerShell scripting against a lab AD environment has inherent scope limitations compared to a production multi-domain environment
- Docker, Linux, and Wazuh receive narrower automation coverage than if they were primary track objectives

These tradeoffs are considered acceptable given the operational value of a focused, AD-centric automation capability and the compounding benefit it provides to subsequent tracks.

---

# Future Reassessment

This track scope may be revisited if:

- the environment expands to include additional AD domains or sites
- infrastructure-as-code tooling such as Ansible becomes a relevant automation layer
- the Cloud and Hybrid Identity track introduces automation requirements that warrant revisiting on-premises scripting scope
- the script library grows to a scale that warrants a dedicated version control or distribution strategy

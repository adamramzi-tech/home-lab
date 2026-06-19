# ADR-014: Establish Long-Term Infrastructure Expansion Roadmap

## Status

Accepted

## Date

2026-06-19

---

## Related Decisions

Builds upon:

- [ADR-010: Establish Enterprise Infrastructure Track](010-establish-enterprise-infrastructure-track.md)
- [ADR-011: Adopt Hybrid Infrastructure Architecture](011-adopt-hybrid-infrastructure-architecture.md)
- [ADR-012: Refactor Repository for Scalable Infrastructure Documentation](012-refactor-repository-for-scalable-infrastructure-documentation.md)

Related documentation:

- [Project README](../../../README.md)
- [Architecture Documentation](../README.md)
- [Topology Documentation](../topology.md)
- [Infrastructure Standards and Naming Conventions](../naming-and-scope-standards.md)
- [Recovery and Rollback Strategy](../recovery-and-rollback.md)

---

# Context

With the completion of the enterprise infrastructure track, both existing infrastructure tracks reached a point of operational completeness and full documentation coverage.

The environment now spans:

- Ubuntu Server administration and Docker-based infrastructure
- centralized monitoring and observability
- reverse proxy architecture and ingress management
- Active Directory Domain Services and DNS
- Windows Server administration
- Group Policy management
- cross-platform Linux and AD identity integration
- centralized security monitoring with Wazuh SIEM

At this stage, the project reached a natural decision point requiring deliberate evaluation of future direction rather than incremental continuation of existing tracks.

Several potential expansion directions were considered:

- infrastructure automation and scripting
- cloud and hybrid identity integration
- network infrastructure and segmentation
- deeper security operations and incident response workflows

Each direction was evaluated against the following criteria:

- operational value added to the existing environment
- logical dependency relationships between tracks
- architectural progression and coherence
- implementation risk and potential disruption to existing infrastructure
- depth and maturity of skills developed relative to the current environment's foundations

**Infrastructure automation and scripting** was identified as the highest-priority immediate next track.

The existing Active Directory environment provides a fully operational automation target requiring no new infrastructure. The environment already manages users, groups, organizational units, Group Policy, and cross-platform identity integration. These systems are natural candidates for scripted administration workflows. Introducing automation at this stage deepens the operational value of infrastructure that already exists rather than expanding the environment's footprint prematurely. PowerShell scripting against Active Directory also represents a foundational skill layer that benefits every subsequent track: automation competency compounds across infrastructure domains.

The implementation risk is minimal. This track introduces no new hardware requirements, no topology changes, and no risk of disruption to existing services.

**Cloud and hybrid identity integration** was identified as the second priority.

This track has a direct dependency on the enterprise infrastructure track: a functional on-premises Active Directory domain is a prerequisite for meaningful hybrid identity work. It also benefits from the automation foundation established in the preceding automation and scripting track, as cloud identity management introduces additional scripting and administration surface area that builds naturally on prior automation work.

Architecturally, extending the existing AD environment into Azure via Entra ID represents the most operationally coherent next step after the automation track. The environment transitions from a self-contained on-premises identity platform into a hybrid identity architecture, which more closely reflects how identity infrastructure operates in modern enterprise environments. This is a meaningful increase in architectural maturity without requiring changes to the existing on-premises foundation.

Implementation risk is moderate. This track introduces a dependency on external cloud infrastructure but does not require changes to the existing on-premises environment beyond the Entra Connect configuration.

**Network infrastructure** was confirmed as the third track in the sequence.

Network segmentation and perimeter firewall deployment represent the most architecturally disruptive change available to the environment. Introducing VLAN segmentation requires reconfiguring network topology assumptions that every existing track was built on. Deferring this track until the automation and cloud identity work is complete allows the environment to stabilize at a higher level of operational maturity before absorbing that disruption. It also ensures that when network segmentation is introduced, the automation tooling exists to manage the more complex environment that results.

Additionally, a segmented network environment is more valuable once hybrid identity is operational, as access control policy across VLANs can reflect identity-aware boundaries rather than purely host-based rules.

This sequencing reflects a deliberate prioritization of operational depth and architectural coherence over breadth of coverage.

---

# Decision

The homelab project would formally commit to the following infrastructure expansion roadmap, to be implemented sequentially:

```text
Track 1: Linux Infrastructure (completed)
Track 2: Enterprise Infrastructure (completed)
Track 3: Infrastructure Automation and Scripting
Track 4: Cloud and Hybrid Identity
Track 5: Network Infrastructure
```

**Track 3: Infrastructure Automation and Scripting**

Focused on PowerShell scripting and automation against the existing Active Directory environment. Planned scope includes user and group provisioning automation, GPO reporting, scheduled maintenance tasks, and log parsing workflows. No new infrastructure required. Builds directly on the enterprise infrastructure track.

**Track 4: Cloud and Hybrid Identity**

Focused on extending the existing on-premises Active Directory environment into Azure through Entra ID and Microsoft Entra Connect. Planned scope includes hybrid identity configuration, Entra ID user and group management, and Microsoft 365 administration workflows. Builds directly on the enterprise infrastructure track and the automation foundation established in Track 3.

**Track 5: Network Infrastructure**

Focused on perimeter firewall deployment, VLAN design and segmentation, inter-VLAN routing and access control policy, firewall rule documentation, network-layer intrusion detection integrated with the existing Wazuh SIEM deployment, and self-hosted VPN infrastructure. Deferred to allow the automation and cloud identity tracks to mature the environment before absorbing the topological disruption that segmentation introduces.

Each track will receive its own ADR at the time of establishment, defining scope, alternatives considered, and architectural consequences in detail. This ADR documents the strategic decision to adopt this sequence and the reasoning behind it.

The roadmap prioritizes:

- operational depth over premature architectural expansion
- logical dependency ordering between tracks
- implementation stability at each stage
- long-term architectural coherence across the full environment

---

# Alternatives Considered

## Begin with Network Infrastructure Immediately

Advantages:

- addresses the flat LAN topology gap
- improves infrastructure realism at the network layer
- provides perimeter security enforcement earlier

Reasons rejected:

- VLAN segmentation and firewall deployment represent the most disruptive change available to the existing environment
- introducing this disruption before automation and cloud identity work is complete would increase operational risk without a commensurate increase in architectural value at this stage
- the environment gains more from deepening existing infrastructure through automation before expanding its physical topology
- network segmentation is more architecturally valuable once hybrid identity is operational and identity-aware access control policy can be applied across VLAN boundaries

## Pursue All Three Tracks Simultaneously

Advantages:

- faster overall coverage
- broader concurrent skill development

Reasons rejected:

- increases documentation complexity and organizational overhead
- reduces focus and depth within each track
- the established pattern of sequential track implementation has produced higher quality documentation and more thorough lab coverage
- concurrent builds across networking, cloud, and automation domains increase the risk of infrastructure instability and unresolved dependency conflicts

## Treat Future Expansion as Unplanned

Advantages:

- maximum flexibility
- no commitment to a specific sequence

Reasons rejected:

- inconsistent with the architecture-first and documentation-first principles established throughout the project
- reduces the ability to make deliberate tradeoffs between competing directions
- the ADR framework exists specifically to document decisions of this type at the time they are made

---

# Consequences

## Positive Outcomes

- clear long-term direction established for the project
- each track builds cleanly on prior work through deliberate dependency ordering
- automation skills developed in Track 3 compound across Track 4 and Track 5
- hybrid identity architecture achieved in Track 4 informs access control policy in Track 5
- network infrastructure introduced at a stage where the environment is mature enough to absorb the disruption
- the project continues to reflect deliberate architectural decision-making rather than opportunistic expansion

## Tradeoffs

- network infrastructure segmentation is deferred, meaning the flat LAN topology persists through Tracks 3 and 4
- committing to a sequence reduces flexibility to pivot significantly if priorities shift
- each track requires its own planning, ADR, and documentation investment before implementation begins

These tradeoffs are considered acceptable given the dependency relationships between tracks and the operational value of completing automation and hybrid identity work before introducing topological disruption.

---

# Future Reassessment

This roadmap may be revisited if:

- infrastructure priorities shift in a way that makes network segmentation more urgent
- hardware or resource constraints affect the feasibility of a planned track
- a specific architectural requirement emerges that changes the dependency ordering between tracks
- the scope of an individual track expands significantly during planning

Individual track scope will be defined in dedicated ADRs at the time each track is established.

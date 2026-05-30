# ADR-001: Repurpose Existing Consumer Hardware for Linux Infrastructure

## Status

Accepted

---

## Related Decisions 

Builds upon: 

- none

Related documentation:

- [Project README](../../../README.md) 
- [01 - Hardware Build](../../linux-infrastructure/01-hardware-build.md) 
- [02 - Ubuntu Server Installation](../../linux-infrastructure/02-ubuntu-server-install.md) 
- [03 - Remote Access and SSH](../../linux-infrastructure/03-remote-access-and-ssh.md) 
- [Topology Documentation](../topology.md) 
- [Recovery and Rollback Strategy](../recovery-and-rollback.md)

---

# Context

The homelab project required a dedicated infrastructure platform capable of supporting:

- Linux server administration
- Docker workloads
- networking labs
- monitoring infrastructure
- remote administration workflows
- future hybrid infrastructure integration

At the beginning of the project, the environment did not yet include dedicated enterprise or server-grade hardware.

However, several components from a previous desktop gaming system were already available after the primary workstation environment was upgraded. Most of the hardware had become effectively inactive and was no longer being used operationally.

The available hardware included:

- Intel Core i5-9600KF
- MSI Z390 motherboard
- 16GB DDR4 memory
- NVIDIA GTX 1060
- consumer ATX chassis and power supply
- 1TB HDD Storage

The original system previously utilized an aging AIO liquid cooler. During the rebuild process, the cooling solution was replaced with a modern air cooler better suited for long-running continuous operation.

The project objective prioritized:

- practical infrastructure experience
- operational familiarity
- experimentation
- incremental learning
- infrastructure deployment experience
- hands-on troubleshooting

rather than:

- enterprise-grade redundancy
- high availability
- power efficiency optimization
- production-scale infrastructure design

The environment was intended primarily as a learning-focused infrastructure platform rather than a production environment.

---

# Decision

The environment would initially be deployed using repurposed consumer hardware instead of purchasing dedicated enterprise server hardware or relying entirely on virtualization hosted on the primary workstation.

The rebuilt system would operate as:

- a dedicated Ubuntu Server host
- a Docker infrastructure platform
- a long-running homelab environment
- an experimentation and learning platform

The infrastructure host would remain physically separated from the primary Windows 11 workstation while sharing the same LAN environment.

This approach allowed infrastructure services and experimentation workloads to operate independently from the primary workstation while also distributing workloads across multiple physical systems rather than concentrating all infrastructure responsibilities onto a single machine.

The decision prioritized:

- immediate infrastructure availability
- reduced startup cost
- practical deployment experience
- operational independence
- flexibility for future infrastructure evolution

The existing hardware was considered sufficient for the project's current learning objectives, making additional infrastructure purchases unnecessary during the initial deployment phase.

---

# Alternatives Considered

## Purchase Dedicated Enterprise Server Hardware

Advantages:

- enterprise-grade reliability
- ECC memory support
- higher long-term scalability
- improved redundancy options
- lower operational risk

Reasons rejected initially:

- significantly higher upfront cost
- unnecessary complexity for early-stage learning objectives
- would delay practical deployment and experimentation
- existing desktop hardware was already available and sufficient

---

## Purchase Dedicated Mini PC Hardware

Advantages:

- lower power consumption
- smaller physical footprint
- quieter operation
- modern low-power hardware platforms

Reasons rejected initially:

- additional hardware investment was unnecessary
- repurposed hardware already provided adequate performance capacity
- existing hardware allowed infrastructure work to begin immediately
- infrastructure concepts could be learned effectively without purchasing new hardware

---

## Use Only Virtual Machines on the Primary Workstation

Advantages:

- reduced hardware footprint
- simplified infrastructure management
- lower power consumption
- no secondary physical system required

Reasons rejected initially:

- desire for operational separation between personal workstation and lab infrastructure
- ability to practice dedicated server administration workflows
- opportunity to gain experience with physical infrastructure deployment
- reduced risk of experimentation impacting the primary workstation environment
- ability to distribute infrastructure workloads across multiple physical systems

At the time of the initial Linux infrastructure deployment, maintaining a dedicated infrastructure host was considered more valuable for learning operational workflows than consolidating all services into a single virtualization environment.

---

# Consequences

## Positive Outcomes

- reduced initial infrastructure cost
- immediate infrastructure availability
- productive reuse of otherwise inactive hardware
- practical hardware deployment experience
- operational familiarity with BIOS and firmware workflows
- exposure to physical infrastructure troubleshooting
- dedicated Linux administration environment
- ability to experiment without production risk
- workload distribution across multiple physical systems
- operational separation between workstation and infrastructure services

The decision accelerated the start of the project and allowed infrastructure work to begin immediately without requiring additional major hardware investment.

The dedicated infrastructure host also enabled:

- remote administration workflows
- headless Linux server management
- Docker-based infrastructure deployment
- networking experimentation
- monitoring and ingress architecture development

The project reinforced the operational principle that practical experience and infrastructure familiarity are more important than perfect hardware during early infrastructure learning stages.

---

## Tradeoffs

The environment accepts several limitations:

- higher power consumption compared to low-power server platforms
- no infrastructure redundancy or failover capability
- consumer-grade reliability characteristics
- constrained virtualization and concurrent workload capacity
- limited storage scalability
- single-host dependency for Linux infrastructure services

These limitations were considered acceptable within the learning-focused scope of the environment.

The environment was intentionally designed around:

- accessibility
- incremental learning
- operational experimentation
- recoverability
- infrastructure familiarity

rather than enterprise-scale availability requirements.

---

# Future Reassessment

This decision may be revisited in the future if:

- virtualization workloads expand significantly
- infrastructure resource requirements increase
- power efficiency becomes operationally important
- additional enterprise services are introduced
- higher availability becomes a design priority
- dedicated virtualization infrastructure becomes necessary

Future infrastructure evolution may eventually introduce:

- dedicated virtualization hardware
- enterprise networking equipment
- lower-power infrastructure platforms
- expanded storage architecture
- additional infrastructure segmentation
- higher availability design
- centralized enterprise services
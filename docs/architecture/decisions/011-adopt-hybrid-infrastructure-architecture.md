# ADR-011: Adopt Hybrid Infrastructure Architecture

## Status

Accepted

---

## Related Decisions

Builds upon:

- [ADR-010: Establish Enterprise Infrastructure Track](010-establish-enterprise-infrastructure-track.md)

Related documentation:

- [Project README](../../../README.md) 
- [Architecture Documentation](../README.md) 
- [Topology Documentation](../topology.md) 
- [Enterprise Infrastructure Resource Plan](../enterprise-resource-plan.md) 
- [Recovery and Rollback Strategy](../recovery-and-rollback.md)

---

# Context

After establishing the enterprise infrastructure track, the project began planning for:

- Active Directory deployment
- Windows Server administration
- domain-joined Windows clients
- centralized identity infrastructure
- virtualization workflows
- hybrid Linux and Windows integration

During planning and research phases, it became increasingly clear that the enterprise infrastructure environment would introduce:

- multiple virtual machines
- persistent enterprise services
- additional networking complexity
- increased resource consumption
- more demanding virtualization workloads

At the same time, the existing Ubuntu Server infrastructure host was already responsible for:

- Docker infrastructure services
- monitoring and observability tooling
- reverse proxy architecture
- container networking
- remote administration workflows
- future Linux infrastructure expansion

The environment therefore required architectural decisions regarding:

- workload placement
- virtualization strategy
- resource allocation
- operational boundaries
- future infrastructure scalability

The primary Windows 11 workstation provided significantly stronger hardware resources than the Ubuntu infrastructure host, including:

- greater CPU performance
- more available memory capacity
- stronger virtualization suitability
- higher overall system performance

The project also increasingly prioritized:

- preserving Linux infrastructure stability
- maintaining operational separation
- reducing infrastructure contention
- supporting future infrastructure expansion
- enabling hybrid Linux and Windows experimentation

At this stage, the project was evolving from:

- a Linux infrastructure learning environment

into:

- a broader hybrid infrastructure platform spanning Linux infrastructure services and Windows enterprise administration concepts

The architecture therefore required clearer separation between:

- Linux infrastructure workloads
- enterprise virtualization workloads
- management systems
- operational domains

---

# Decision

The environment would adopt a hybrid infrastructure architecture consisting of:

- a dedicated Ubuntu Server infrastructure host
- a separate Windows 11 workstation acting as the enterprise virtualization platform

The Ubuntu Server host would remain focused primarily on:

- Linux infrastructure services
- Docker-based workloads
- monitoring infrastructure
- ingress architecture
- networking experimentation
- observability tooling
- future Linux infrastructure expansion

Enterprise infrastructure workloads would instead operate as virtual machines hosted on the Windows 11 workstation.

Planned virtualization workloads included:

- Active Directory domain controllers
- Windows Server infrastructure
- Windows enterprise client systems
- future enterprise administration labs

This architecture intentionally distributed infrastructure responsibilities across separate physical systems rather than consolidating all workloads onto a single host.

The hybrid model prioritized:

- workload separation
- resource allocation efficiency
- infrastructure scalability
- operational stability
- reduced service contention
- cross-platform operational familiarity
- long-term infrastructure flexibility

The decision also leveraged:

- the workstation's stronger hardware capabilities
- existing workstation virtualization capacity
- centralized management convenience
- future hybrid infrastructure experimentation opportunities

The environment would therefore evolve as:

- Linux infrastructure services hosted on Ubuntu Server
- enterprise virtualization workloads hosted on the Windows workstation
- both systems integrated through shared networking and future cross-platform services

This established the foundational topology for the long-term hybrid infrastructure roadmap.

---

# Alternatives Considered

## Host Enterprise Virtualization Directly on the Ubuntu Server

Advantages:

- centralized infrastructure platform
- single physical infrastructure host
- simplified physical topology
- reduced power consumption
- consolidated infrastructure management

Reasons rejected:

- reduced available resources for future Linux infrastructure workloads
- increased workload contention
- reduced operational separation
- greater risk of enterprise experimentation impacting Linux infrastructure services
- weaker long-term scalability
- limited virtualization capacity compared to the workstation

The Ubuntu infrastructure host was considered better suited for maintaining dedicated Linux infrastructure responsibilities rather than absorbing all virtualization workloads.

---

## Convert the Ubuntu Host Into a Dedicated Hypervisor Platform

Examples conceptually included:

- Proxmox
- VMware ESXi
- Hyper-V alternatives

Advantages:

- centralized virtualization architecture
- more enterprise-oriented hypervisor workflows
- stronger VM lifecycle tooling
- consolidated virtualization management

Reasons rejected initially:

- would significantly alter the existing Linux infrastructure environment
- existing Docker infrastructure was already operational and stable
- unnecessary complexity for the current project stage
- reduced focus on Linux administration workflows
- additional migration overhead

The project prioritized preserving the existing Linux infrastructure foundation while expanding gradually into enterprise virtualization concepts.

---

## Operate Linux and Enterprise Infrastructure on a Single Workstation Only

Advantages:

- reduced hardware footprint
- simplified physical infrastructure
- centralized system management
- easier hardware maintenance

Reasons rejected:

- reduced infrastructure separation
- weaker operational realism
- greater dependency on a single physical system
- increased operational risk during experimentation
- reduced ability to maintain continuously running Linux infrastructure independently

The project prioritized maintaining a dedicated Linux infrastructure platform while expanding enterprise capabilities separately.

---

# Consequences

## Positive Outcomes

- clear separation between Linux infrastructure and enterprise virtualization workloads
- improved workload distribution across physical systems
- preserved Linux infrastructure performance capacity
- improved virtualization scalability
- reduced resource contention
- stronger operational boundaries
- improved infrastructure flexibility
- practical exposure to hybrid infrastructure concepts
- improved long-term scalability
- stronger separation between infrastructure domains

The architecture established the foundation for:

- Active Directory deployment
- enterprise virtualization workflows
- hybrid Linux and Windows integration
- future centralized authentication
- cross-platform observability
- future enterprise networking concepts

The environment also gained:

- improved operational flexibility
- more realistic infrastructure topology separation
- stronger scalability for future experimentation
- dedicated resource allocation for virtualization workloads

This hybrid architecture more closely resembled real-world environments in which:

- Linux infrastructure services
- enterprise identity services
- virtualization platforms
- and management systems

often operate across multiple systems with distinct operational responsibilities.

---

## Tradeoffs

The environment accepts several tradeoffs:

- increased physical infrastructure complexity
- dependency on multiple systems
- additional operational coordination requirements
- increased power consumption
- broader troubleshooting scope
- more complicated topology relationships
- additional virtualization management overhead

The architecture also became more dependent on:

- inter-system networking
- cross-platform management workflows
- workload boundary management
- virtualization resource planning

Maintaining separate infrastructure systems also increases:

- documentation requirements
- operational coordination
- infrastructure planning complexity

These tradeoffs were considered acceptable because the operational flexibility and scalability benefits significantly outweighed the added complexity.

---

# Future Reassessment

This decision may later be revisited if:

- dedicated hypervisor hardware is introduced
- enterprise virtualization requirements expand significantly
- clustered virtualization becomes operationally relevant
- infrastructure scale increases substantially
- Kubernetes or container orchestration platforms are introduced
- centralized storage infrastructure becomes necessary
- dedicated enterprise networking hardware is introduced

Potential future evolution may include:

- Proxmox infrastructure
- dedicated virtualization nodes
- centralized storage platforms
- VLAN segmentation
- clustered virtualization
- hybrid cloud integration
- infrastructure automation tooling
- advanced identity integration

The hybrid infrastructure architecture currently remains foundational to the long-term direction of the homelab environment and establishes the operational boundary between Linux infrastructure services and enterprise virtualization workloads.

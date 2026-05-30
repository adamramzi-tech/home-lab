# ADR-006: Use Custom Docker Bridge Networking

## Status

Accepted

---

## Related Decisions

Builds upon:

- [ADR-005: Standardize on Containerized Service Deployment](005-standardize-on-containerized-service-deployment.md)

Related documentation:

- [Project README](../../../README.md) 
- [04 - Docker Setup](../../linux-infrastructure/04-docker-setup.md) 
- [05 - Docker Networking Lab](../../linux-infrastructure/05-docker-networking-lab.md) 
- [07 - Reverse Proxy Lab](../../linux-infrastructure/07-reverse-proxy-lab.md) 
- [Topology Documentation](../topology.md)

---

# Context

As the homelab environment evolved beyond single-container deployments, infrastructure services increasingly required:

- container-to-container communication
- service isolation
- predictable internal networking
- scalable multi-service deployment workflows
- simplified service discovery
- reduced unnecessary service exposure

The environment had already standardized on:

- Docker-based infrastructure deployment
- Docker Compose orchestration
- remote-first administration workflows
- containerized infrastructure services

Early Docker deployments initially relied on:

- published host ports
- default Docker networking behavior
- direct host-to-container access patterns

However, as infrastructure complexity increased, this model introduced several operational limitations:

- excessive direct service exposure
- fragmented networking behavior
- limited service segmentation
- reduced architectural clarity
- dependency on static host port mappings
- more complicated multi-service communication workflows

The environment required a networking model that supported:

- isolated service communication
- internal-only backend services
- reverse proxy architectures
- scalable multi-container deployments
- predictable service discovery
- layered infrastructure design

The Docker networking lab specifically explored:

- custom bridge networks
- internal DNS-based service discovery
- reverse proxy communication patterns
- isolated backend service design
- multi-container infrastructure workflows

This phase marked the transition from isolated container experimentation toward more structured infrastructure architecture design.

---

# Decision

The environment would standardize on custom Docker bridge networks for infrastructure service communication rather than relying primarily on Docker's default bridge network.

Infrastructure services would communicate internally through:

- user-defined Docker bridge networks
- Docker DNS service discovery
- container name-based communication
- segmented internal networking layers

Docker Compose would manage:

- network creation
- network attachment
- service membership
- internal networking relationships

Custom bridge networks would be used to:

- isolate related infrastructure services
- simplify internal service communication
- support reverse proxy architectures
- reduce unnecessary direct LAN exposure
- establish clearer infrastructure boundaries

The networking model intentionally prioritized:

- internal container communication
- service segmentation
- layered infrastructure architecture
- scalable multi-service deployment
- internal-only backend services where appropriate

Infrastructure services would increasingly communicate internally using:

- container names
- Docker DNS resolution
- shared bridge networks

rather than:

- static IP assignments
- localhost-only assumptions
- direct host networking dependencies

This established a more structured and scalable internal networking architecture for future infrastructure expansion.

---

# Alternatives Considered

## Use Docker Default Bridge Networking

Advantages:

- simplest Docker networking model
- minimal configuration requirements
- automatic networking behavior
- reduced deployment complexity

Reasons rejected:

- limited service segmentation
- weaker infrastructure organization
- reduced control over networking boundaries
- less predictable multi-service communication
- reduced architectural clarity
- poorer scalability for expanding infrastructure

The default bridge network was considered acceptable for temporary or isolated containers but insufficient for long-term infrastructure architecture.

---

## Expose Services Directly Through Host Networking

Advantages:

- simplified external access
- fewer networking abstraction layers
- easier early-stage troubleshooting
- direct host-to-container communication

Reasons rejected:

- excessive direct service exposure
- reduced service isolation
- increased attack surface
- fragmented ingress architecture
- reduced flexibility for reverse proxy integration
- increased dependency on host port management

As the environment evolved, directly exposing all services individually was considered increasingly difficult to manage cleanly.

---

## Use Macvlan or Advanced Docker Networking Immediately

Advantages:

- direct LAN participation for containers
- more advanced networking flexibility
- greater network segmentation capabilities
- more enterprise-like networking behavior

Reasons rejected initially:

- unnecessary networking complexity
- increased troubleshooting overhead
- reduced deployment simplicity
- excessive complexity for the current infrastructure scale
- bridge networking already satisfied operational requirements

The environment prioritized operational clarity and foundational networking familiarity before introducing more advanced container networking models.

---

# Consequences

## Positive Outcomes

- improved service isolation
- cleaner internal infrastructure architecture
- simplified container-to-container communication
- Docker DNS-based service discovery
- reduced dependency on static IP addressing
- more scalable multi-service deployments
- improved reverse proxy integration
- clearer networking boundaries
- improved operational consistency
- reduced unnecessary backend exposure

The decision established the networking foundation for:

- centralized ingress architecture
- reverse proxy service routing
- internal-only backend services
- monitoring stack segmentation
- multi-stack Docker networking
- future infrastructure hardening workflows

Custom bridge networking also enabled:

- service communication through container names
- internal DNS resolution
- simplified Compose-based orchestration
- cleaner infrastructure topology design

## This significantly improved the maintainability and scalability of the containerized infrastructure environment.

## Tradeoffs

The environment accepts several tradeoffs:

- increased networking abstraction complexity
- additional Docker networking troubleshooting requirements
- dependency on Compose-managed networking configuration
- increased operational learning curve
- more complex cross-stack networking considerations
- additional debugging complexity during connectivity issues

The environment also became more dependent on:

- Docker DNS resolution
- network attachment consistency
- correct Compose networking definitions

These tradeoffs were considered acceptable because the operational and architectural benefits significantly outweighed the added complexity as the environment expanded.

---

# Future Reassessment

This decision may later be revisited if:

- infrastructure scale increases significantly
- Kubernetes networking becomes operationally relevant
- VLAN-backed container segmentation becomes necessary
- service mesh architectures become a learning objective
- advanced east-west traffic controls are introduced
- container security requirements expand
- multi-host container orchestration is implemented

Potential future networking evolution may include:

- macvlan networking
- overlay networking
- Kubernetes CNI architectures
- VLAN-aware container segmentation
- service mesh technologies
- dedicated ingress controllers

For the current environment, custom Docker bridge networking provides an effective balance between:

- simplicity
- service isolation
- internal communication
- operational clarity
- scalability
- maintainability
- practical infrastructure learning

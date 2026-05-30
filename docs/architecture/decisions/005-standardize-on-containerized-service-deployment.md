# ADR-005: Standardize on Containerized Service Deployment

## Status

Accepted

---

## Related Decisions

Builds upon:

- [ADR-002: Standardize on Ubuntu Server LTS](002-standardize-on-ubuntu-server-lts.md) 
- [ADR-003: Adopt Remote-First Administration](003-adopt-remote-first-administration.md)

Related documentation:

- [Project README](../../../README.md) 
- [04 - Docker Setup](../../linux-infrastructure/04-docker-setup.md) 
- [05 - Docker Networking Lab](../../linux-infrastructure/05-docker-networking-lab.md) 
- [Recovery and Rollback Strategy](../recovery-and-rollback.md) 
- [Topology Documentation](../topology.md)

---

# Context

After the Ubuntu Server infrastructure platform and remote administration workflows were established, the environment required a standardized method for deploying and managing infrastructure services.

Planned infrastructure services included:

- monitoring platforms
- reverse proxy services
- container management tooling
- networking labs
- future observability tooling
- future hybrid infrastructure integrations

The environment required a deployment strategy that prioritized:

- reproducibility
- operational consistency
- simplified service management
- recoverability
- infrastructure modularity
- isolated application environments
- lightweight experimentation

The project also prioritized:

- practical infrastructure learning
- operational familiarity
- incremental infrastructure expansion
- reduced deployment complexity
- maintainable service architecture

Traditional host-based deployments were considered less desirable because they would:

- increase dependency conflicts
- complicate service isolation
- reduce deployment consistency
- make rollback and redeployment workflows more difficult
- increase operating system configuration complexity over time

At this stage of the project, the environment was still relatively small but expected to expand incrementally as additional infrastructure services were introduced.

The infrastructure platform also relied heavily on:

- remote administration workflows
- SSH-based management
- browser-based tooling
- reproducible deployment workflows
- Git-based documentation and configuration management

A deployment model was needed that could scale operationally without significantly increasing administrative overhead.

---

# Decision

The environment would standardize on containerized service deployment using Docker and Docker Compose as the primary infrastructure deployment model.

Infrastructure services would operate primarily as isolated containers rather than being installed directly onto the Ubuntu Server host operating system.

Docker Compose would become the standardized orchestration and deployment mechanism for:

- multi-container applications
- infrastructure services
- networking configuration
- persistent storage configuration
- service lifecycle management

Containerized deployment would be used for:

- monitoring infrastructure
- reverse proxy services
- container management tooling
- networking experimentation
- future observability services
- future hybrid infrastructure integrations where appropriate

The Ubuntu Server host would function primarily as:

- the infrastructure runtime platform
- the container host operating system
- the management layer for containerized infrastructure workloads

The deployment model prioritized:

- declarative infrastructure configuration
- isolated application environments
- simplified redeployment workflows
- operational consistency
- service portability
- infrastructure reproducibility

Docker Compose configuration files would also become part of the broader infrastructure documentation and recovery strategy.

---

# Alternatives Considered

## Traditional Host-Based Service Deployment

Advantages:

- direct operating system integration
- fewer abstraction layers
- reduced dependency on container tooling
- simpler resource visibility

Reasons rejected:

- increased risk of dependency conflicts
- more difficult rollback and recovery workflows
- reduced deployment consistency
- greater operating system configuration drift over time
- more complicated service isolation
- reduced portability and reproducibility

As the environment expanded, manually managed host services were expected to become increasingly difficult to maintain consistently.

---

## Full Virtual Machine-Based Service Segmentation

Advantages:

- strong workload isolation
- dedicated operating system environments
- realistic enterprise virtualization experience
- independent system-level administration

Reasons rejected initially:

- unnecessary resource overhead for lightweight services
- increased memory and storage consumption
- higher operational complexity
- slower deployment workflows
- excessive infrastructure overhead for early-stage services

The environment prioritized lightweight and rapidly deployable infrastructure services during the Linux infrastructure phase.

---

## Kubernetes or Advanced Container Orchestration Platforms

Advantages:

- enterprise-grade orchestration
- advanced scaling capabilities
- declarative infrastructure management
- high availability and scheduling features

Reasons rejected initially:

- unnecessary operational complexity
- steeper learning curve
- significantly larger infrastructure overhead
- excessive abstraction for current project scope
- premature orchestration complexity

The project objective prioritized foundational containerization familiarity before introducing more advanced orchestration systems.

Docker Compose was considered the most practical balance between:

- operational simplicity
- infrastructure reproducibility
- scalability
- maintainability
- learning accessibility

---

# Consequences

## Positive Outcomes

- standardized infrastructure deployment methodology
- isolated application environments
- simplified service deployment and redeployment
- reduced dependency conflict risk
- reproducible infrastructure workflows
- improved infrastructure modularity
- simplified rollback and recovery workflows
- easier infrastructure experimentation
- operational familiarity with modern containerized infrastructure concepts
- cleaner separation between host operating system and infrastructure services

The decision established the operational foundation for:

- monitoring infrastructure
- reverse proxy architecture
- container networking
- centralized ingress
- service segmentation
- future observability tooling

Containerization also integrated naturally with:

- SSH-based administration
- Git-based documentation workflows
- Docker networking
- reverse proxy architecture
- persistent storage strategies
- infrastructure recovery planning

Docker Compose deployments became infrastructure artifacts that could be:

- version controlled
- validated
- reproduced
- redeployed
- incrementally expanded

## This significantly improved operational consistency throughout the environment.

## Tradeoffs

The environment accepts several tradeoffs:

- additional abstraction between services and the host operating system
- dependency on Docker runtime infrastructure
- increased networking complexity through container networking layers
- additional troubleshooting complexity involving containers and orchestration tooling
- persistent storage management complexity for stateful services
- operational dependency on Docker Compose configuration integrity

Containerized infrastructure also introduces:

- image lifecycle management requirements
- container networking concepts
- orchestration troubleshooting workflows
- runtime isolation considerations

These tradeoffs were considered acceptable because the operational flexibility and infrastructure consistency benefits significantly outweighed the added complexity for the project's scope and learning objectives.

---

# Future Reassessment

This decision may later be revisited if:

- infrastructure scale increases significantly
- high availability requirements emerge
- orchestration complexity expands
- Kubernetes adoption becomes operationally beneficial
- virtualization infrastructure evolves substantially
- infrastructure automation requirements increase
- enterprise orchestration tooling becomes a learning objective

Potential future evolution may include:

- Kubernetes
- Docker Swarm
- infrastructure-as-code integration
- automated CI/CD deployment workflows
- container security tooling
- orchestration monitoring platforms

For the current environment, Docker Compose provides an effective balance between:

- operational simplicity
- reproducibility
- modularity
- scalability
- infrastructure isolation
- practical infrastructure learning

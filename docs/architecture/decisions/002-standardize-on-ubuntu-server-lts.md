# ADR-002: Standardize on Ubuntu Server LTS

## Status

Accepted

---

## Related Decisions 

Builds upon: 

- [ADR-001: Repurpose Existing Consumer Hardware for Linux Infrastructure](001-repurpose-existing-consumer-hardware-for-linux-infrastructure.md) 

Related documentation: 

- [Project README](../../../README.md) 
- [01 - Hardware Build](../../linux-infrastructure/01-hardware-build.md) 
- [02 - Ubuntu Server Installation](../../linux-infrastructure/02-ubuntu-server-install.md) 
- [03 - Remote Access and SSH](../../linux-infrastructure/03-remote-access-and-ssh.md) 
- [Topology Documentation](../topology.md)

---

# Context

The homelab environment required a stable operating system platform capable of supporting:

- headless server administration
- Docker-based infrastructure services
- remote SSH administration
- infrastructure monitoring
- reverse proxy services
- networking experimentation
- long-running infrastructure workloads

The environment was intended to operate primarily as a dedicated Linux infrastructure platform administered remotely from a separate Windows 11 workstation.

At the beginning of the Linux infrastructure phase, the project objective prioritized:

- operational familiarity with Linux systems
- practical server administration experience
- infrastructure reproducibility
- remote management workflows
- compatibility with modern containerized infrastructure tooling

The operating system also needed to support:

- long-term maintainability
- strong documentation availability
- broad community adoption
- compatibility with enterprise infrastructure concepts
- future hybrid Linux and Windows integration

Because the infrastructure host would eventually transition into a headless operational environment, a lightweight server-oriented operating system was considered more appropriate than a desktop-focused Linux distribution.

---

# Decision

The Linux infrastructure platform would standardize on Ubuntu Server LTS.

Ubuntu Server was selected as the foundational operating system for the Linux infrastructure environment and would serve as the primary platform for:

- Docker workloads
- monitoring infrastructure
- reverse proxy services
- remote administration
- infrastructure experimentation
- future cross-platform integration

The deployment would utilize:

- Ubuntu Server rather than Ubuntu Desktop
- a long-term support (LTS) release
- primarily command-line driven administration workflows
- remote SSH-based management

The operating system would function as a dedicated headless infrastructure platform with administration performed remotely from the Windows 11 workstation using:

- SSH
- Windows Terminal
- VS Code Remote workflows
- browser-based infrastructure management tools

---

# Alternatives Considered

## Ubuntu Desktop

Advantages:

- graphical administration environment
- easier onboarding for new Linux users
- built-in desktop tooling

Reasons rejected:

- unnecessary graphical overhead for a headless infrastructure host
- increased resource consumption
- reduced alignment with real-world server administration workflows
- less emphasis on command-line operational experience

The environment was intended to function primarily as a remotely administered infrastructure platform rather than a local desktop workstation.

---

## Other Linux Server Distributions

Alternatives considered implicitly included:

- Debian
- Fedora Server
- Arch Linux
- Red Hat Enterprise Linux derivatives

Advantages:

- different package management ecosystems
- alternative release models
- varying levels of customization and stability

Reasons Ubuntu Server LTS was selected:

- strong documentation availability
- broad community support
- widespread enterprise and homelab adoption
- operational familiarity
- strong Docker compatibility
- predictable long-term support lifecycle
- large ecosystem of tutorials and troubleshooting resources

Ubuntu Server LTS was considered the most practical platform for developing foundational Linux infrastructure administration skills while minimizing unnecessary deployment complexity.

---

## Run Linux Infrastructure Inside Virtual Machines Only

Advantages:

- simplified hardware footprint
- easier rollback workflows
- reduced power consumption

Reasons rejected initially:

- desire to gain experience managing a dedicated Linux server
- opportunity to practice physical infrastructure deployment
- ability to operate a continuously running infrastructure platform
- stronger separation between personal workstation usage and infrastructure services
- improved operational realism for remote administration workflows

The project objective prioritized hands-on operational familiarity with dedicated Linux infrastructure rather than consolidating all workloads into a single workstation environment.

---

# Consequences

## Positive Outcomes

- stable long-term Linux infrastructure platform
- exposure to headless Linux administration workflows
- operational familiarity with SSH-based management
- compatibility with Docker and containerized infrastructure tooling
- strong documentation and troubleshooting ecosystem
- reduced operating system overhead compared to desktop-oriented deployments
- realistic server administration experience
- strong foundation for future hybrid infrastructure integration

Ubuntu Server LTS became the operational foundation for:

- Docker Compose infrastructure
- reverse proxy architecture
- monitoring and observability tooling
- remote administration workflows
- internal infrastructure networking
- future enterprise integration planning

The decision also reinforced command-line operational familiarity and infrastructure troubleshooting skills through continuous remote administration workflows.

---

## Tradeoffs

The environment accepts several limitations:

- reduced convenience compared to graphical desktop environments
- greater reliance on command-line administration
- steeper learning curve for Linux system management
- increased dependency on remote administration workflows
- additional troubleshooting complexity during early deployment stages

These tradeoffs were considered acceptable because the project prioritized:

- practical infrastructure administration
- operational familiarity
- remote management workflows
- Linux systems knowledge
- infrastructure-oriented learning objectives

---

# Future Reassessment

This decision may be revisited in the future if:

- infrastructure requirements expand significantly
- dedicated virtualization infrastructure is introduced
- orchestration platforms such as Kubernetes are adopted
- enterprise Linux distributions become operationally relevant
- additional Linux infrastructure roles require alternative operating system strategies

Ubuntu Server LTS currently remains the standardized Linux infrastructure platform for the environment and serves as the operational foundation for the broader hybrid infrastructure roadmap.

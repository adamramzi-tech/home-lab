# ADR-003: Adopt Remote-First Administration

## Status

Accepted

---

## Related Decisions

Builds upon:

- [ADR-002: Standardize on Ubuntu Server LTS](002-standardize-on-ubuntu-server-lts.md)

Related documentation:

- [Project README](../../../README.md) 
- [01 - Hardware Build](../../linux-infrastructure/01-hardware-build.md) 
- [02 - Ubuntu Server Installation](../../linux-infrastructure/02-ubuntu-server-install.md) 
- [03 - Remote Access and SSH](../../linux-infrastructure/03-remote-access-and-ssh.md) 
- [Topology Documentation](../topology.md)

---

# Context

The homelab environment was designed to operate as a dedicated Linux infrastructure platform separate from the primary Windows 11 workstation.

During the initial hardware deployment and Ubuntu Server installation phases, the server temporarily required:

- direct monitor access
- dedicated keyboard and mouse peripherals
- local console interaction
- temporary deployment staging space

This temporary setup quickly became operationally inconvenient within the existing desk environment.

The primary workstation already utilized:

- a large ultrawide monitor
- wireless peripherals
- centralized desk management
- an established documentation and development workflow

Maintaining separate peripherals, additional monitors, or repeated input switching for routine server administration introduced unnecessary physical complexity and reduced workflow efficiency.

The temporary deployment configuration used during the hardware build and Ubuntu installation phases reinforced that long-term local console administration would be impractical for the environment.

At the same time, the project objective prioritized:

- practical Linux systems administration
- operational realism
- headless infrastructure management
- remote troubleshooting workflows
- infrastructure accessibility
- centralized management workflows

The environment also needed to support:

- remote administration from the primary workstation
- future remote access while away from home
- simplified documentation workflows
- browser-based infrastructure management
- future hybrid infrastructure administration

The Linux infrastructure platform was intended to function more like a dedicated infrastructure node than a traditional desktop system.

---

# Decision

The infrastructure environment would adopt a remote-first administration model centered around SSH-based workflows rather than ongoing local console interaction.

The Ubuntu Server host would operate primarily as a headless infrastructure system administered remotely from the Windows 11 workstation using:

- OpenSSH
- Windows Terminal
- PowerShell
- VS Code Remote workflows
- browser-based infrastructure management interfaces

After initial deployment and networking configuration were completed, the server would no longer require:

- a permanent monitor
- dedicated local peripherals
- direct physical console interaction during normal operations

The physical server was relocated beneath the primary workstation after remote administration workflows became operational.

The remote administration model also incorporated:

- Tailscale mesh VPN connectivity
- Wake-on-LAN support
- reserved local IP addressing
- remote power management workflows
- secure off-site infrastructure access

This established a centralized management plane in which:

- the Windows workstation functioned as the primary administration endpoint
- the Ubuntu Server host functioned as the dedicated infrastructure platform
- operational workflows remained accessible locally and remotely

The decision prioritized:

- operational convenience
- reduced physical clutter
- realistic infrastructure administration workflows
- centralized management
- infrastructure accessibility
- long-term maintainability

---

# Alternatives Considered

## Continue Using Local Console Administration

Advantages:

- direct physical access to the system
- simplified troubleshooting during early deployment
- no dependency on network connectivity
- easier onboarding for basic Linux interaction

Reasons rejected:

- impractical physical workspace requirements
- increased desk and cable clutter
- inefficient monitor and peripheral switching
- reduced workflow efficiency
- poor scalability as infrastructure complexity increased
- inconsistent with long-term headless server operation goals

The temporary deployment setup used during initial installation demonstrated that maintaining permanent local console workflows would be operationally cumbersome.

---

## Deploy a Dedicated KVM or Secondary Administration Setup

Advantages:

- dedicated infrastructure administration environment
- reduced dependency on SSH workflows
- easier physical access to BIOS and recovery environments

Reasons rejected:

- unnecessary additional hardware complexity
- increased desk space requirements
- additional cable management overhead
- unnecessary cost for current infrastructure scope
- remote SSH workflows already provided sufficient operational capability

The environment did not require enterprise-style rack management infrastructure at its current scale.

---

## Use GUI-Based Remote Desktop Administration Exclusively

Advantages:

- more familiar management experience
- easier visual interaction for some workflows
- reduced command-line dependency

Reasons rejected:

- reduced emphasis on Linux command-line familiarity
- additional graphical overhead
- weaker alignment with real-world Linux server administration practices
- SSH provided simpler and more lightweight operational workflows
- browser-based interfaces already covered graphical management requirements where appropriate

The environment intentionally prioritized Linux administration familiarity and terminal-based operational workflows.

---

# Consequences

## Positive Outcomes

- successful transition to headless Linux infrastructure administration
- centralized infrastructure management from the Windows workstation
- reduced physical desk clutter and peripheral complexity
- improved operational workflow efficiency
- practical SSH administration experience
- operational familiarity with remote Linux management
- simplified documentation and screenshot workflows
- remote infrastructure accessibility through Tailscale
- remote power management capability through Wake-on-LAN
- improved infrastructure scalability and maintainability

The decision established the operational management model used throughout the remainder of the environment, including:

- Docker administration
- reverse proxy management
- monitoring stack deployment
- infrastructure troubleshooting
- configuration management
- Git-based documentation workflows

The remote-first model also aligned naturally with:

- browser-based infrastructure tooling
- VS Code Remote development workflows
- future virtualization management
- future hybrid Linux and Windows administration

This approach more closely mirrored real-world infrastructure administration practices in which servers are typically managed remotely rather than through persistent physical console interaction.

---

## Tradeoffs

The environment accepts several limitations:

- dependency on network connectivity for normal administration
- additional troubleshooting complexity during networking failures
- increased reliance on SSH and remote access tooling
- reduced convenience for BIOS-level or low-level recovery interaction
- dependency on remote authentication and connectivity workflows

Certain maintenance and recovery scenarios still require:

- temporary physical monitor access
- direct BIOS interaction
- local troubleshooting during networking failures

These limitations were considered acceptable because the operational advantages of remote-first administration significantly outweighed the inconvenience of maintaining permanent local console infrastructure.

---

# Future Reassessment

This decision may be revisited in the future if:

- dedicated rack infrastructure is introduced
- enterprise-grade out-of-band management becomes relevant
- hypervisor infrastructure expands significantly
- centralized KVM infrastructure becomes operationally beneficial
- advanced remote recovery tooling becomes necessary

The remote-first administration model currently remains foundational to the operational design of the homelab environment and continues to support both Linux infrastructure administration and future hybrid infrastructure expansion.
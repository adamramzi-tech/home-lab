# ADR-004: Use Tailscale for Secure Remote Access

## Status

Accepted

---

## Related Decisions

Builds upon:

- [ADR-003: Adopt Remote-First Administration](003-adopt-remote-first-administration.md)

Related documentation:

- [Project README](../../../README.md) 
- [03 - Remote Access and SSH](../../linux-infrastructure/03-remote-access-and-ssh.md) 
- [Recovery and Rollback Strategy](../recovery-and-rollback.md) 
- [Topology Documentation](../topology.md)

---

# Context

The homelab environment required a method for securely accessing infrastructure systems remotely without exposing management services directly to the public internet.

At the time of implementation, Tailscale was already being used between the primary Windows 11 workstation and an iPhone for remote file transfer workflows. Existing familiarity with the platform reduced deployment complexity and made it a practical candidate for extending remote infrastructure access capabilities.

The infrastructure environment already relied heavily on:

- SSH-based administration
- remote-first operational workflows
- centralized management from the Windows workstation
- browser-based infrastructure administration
- headless Linux server operation

As the environment evolved, the need for flexible remote access increased.

Operational goals included:

- secure remote SSH access
- remote infrastructure management while away from home
- avoiding direct public exposure of SSH services
- simplified remote connectivity
- minimal networking complexity
- encrypted device-to-device communication
- cross-device accessibility

The environment also operated within several practical constraints:

- consumer networking hardware
- dynamic residential networking
- limited desire to manage manual port forwarding
- preference for low operational overhead
- learning-focused infrastructure priorities

The solution needed to remain:

- easy to deploy
- operationally reliable
- lightweight
- compatible across multiple devices
- maintainable within a small-scale homelab environment

Tailscale was ultimately integrated into:

- the Ubuntu Server host
- the Windows administrative workstation
- mobile devices used for remote access workflows

This created a private mesh network for infrastructure management.

---

# Decision

The environment would adopt Tailscale as the primary secure remote access platform for infrastructure administration.

Tailscale would provide:

- encrypted remote connectivity
- mesh VPN functionality
- private infrastructure access
- remote SSH administration capability
- secure cross-device communication

The platform would be integrated into the operational management plane alongside:

- OpenSSH
- Windows Terminal
- PowerShell
- VS Code Remote workflows
- Wake-on-LAN functionality

Remote administration workflows would occur through:

- Tailscale-connected SSH sessions
- browser-based infrastructure management
- remote access from mobile and portable devices

The environment intentionally avoided:

- public SSH exposure
- manual router port forwarding
- direct internet-facing management services

This established a remote administration architecture in which infrastructure systems remained privately accessible through authenticated mesh VPN connectivity rather than publicly reachable network services.

---

# Alternatives Considered

## Traditional Port Forwarding and Public SSH Exposure

Advantages:

- direct remote SSH connectivity
- no third-party coordination layer
- standard Linux remote administration workflow
- minimal additional software requirements

Reasons rejected:

- increased exposure of SSH services to the public internet
- additional security risk
- reliance on residential router configuration
- operational complexity involving dynamic IP management
- unnecessary exposure for a learning-focused environment
- reduced convenience compared to mesh VPN connectivity

The environment intentionally prioritized minimizing direct public attack surface exposure.

---

## Self-Hosted VPN Infrastructure

Advantages:

- complete infrastructure ownership
- deeper VPN administration experience
- greater configuration flexibility
- reduced external dependency

Reasons rejected:

- significantly higher operational complexity
- additional infrastructure maintenance burden
- increased troubleshooting requirements
- unnecessary overhead for the current scale of the environment
- slower deployment and onboarding process

At the current project stage, the objective was practical infrastructure accessibility rather than deep VPN engineering specialization.

---

## LAN-Only Administration

Advantages:

- simplest networking model
- no external connectivity dependencies
- reduced software footprint

Reasons rejected:

- no remote administration capability outside the home network
- limited operational flexibility
- inability to access infrastructure while away from home
- reduced usefulness of remote-first administration workflows

The environment was intentionally designed to support flexible remote operations.

---

# Consequences

## Positive Outcomes

- secure remote infrastructure access without public SSH exposure
- encrypted mesh VPN connectivity between infrastructure devices
- simplified remote administration workflows
- remote SSH access from multiple devices
- mobile infrastructure accessibility
- reduced networking complexity
- elimination of manual port forwarding requirements
- improved operational flexibility
- easier cross-device management workflows
- practical exposure to modern mesh VPN infrastructure concepts

Tailscale also integrated naturally into:

- the remote-first administration model
- Wake-on-LAN workflows
- centralized infrastructure management
- future hybrid infrastructure operations

The platform enabled infrastructure accessibility from:

- the primary Windows workstation
- mobile devices
- future portable administration systems

This significantly improved operational convenience while maintaining a relatively small security footprint.

---

## Tradeoffs

The environment accepts several tradeoffs:

- dependency on a third-party coordination platform
- reduced direct exposure to traditional VPN configuration workflows
- reliance on external identity-based authentication infrastructure
- reduced experience with self-hosted VPN management
- dependency on client software across connected systems

The environment also remains partially dependent on:

- internet connectivity
- Tailscale service availability
- authenticated device enrollment

These limitations were considered acceptable because the operational simplicity and security improvements significantly outweighed the added dependency concerns at the current scale of the project.

---

# Future Reassessment

This decision may later be revisited if:

- the environment expands significantly
- self-hosted VPN infrastructure becomes a learning objective
- advanced segmentation requirements emerge
- dedicated firewall infrastructure is introduced
- site-to-site networking becomes necessary
- centralized enterprise authentication requirements evolve
- more advanced network security experimentation becomes a priority

Potential future alternatives may include:

- WireGuard self-hosting
- pfSense or OPNsense VPN infrastructure
- enterprise firewall VPN solutions
- segmented management VLANs
- dedicated remote access gateways

For the current environment, Tailscale provides an effective balance between:

- security
- simplicity
- accessibility
- operational convenience
- low administrative overhead
- practical infrastructure usability

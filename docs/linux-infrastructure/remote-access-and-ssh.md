# Remote Access and SSH

## Objective

Establish secure remote administration capabilities for the Ubuntu Server environment using OpenSSH, Windows Terminal, Tailscale, and Wake-on-LAN functionality.

---

## OpenSSH Installation

### OpenSSH Server Deployment

During Ubuntu Server installation, the OpenSSH server package was enabled to allow secure remote administration immediately after deployment.

<p align="center">
  <img src="../images/linux-infrastructure/remote-access-and-ssh/01-openssh-installation.jpeg" width="700">
</p>

<p align="center">
  <em>OpenSSH server installation enabled during Ubuntu Server deployment.</em>
</p>

This configuration allowed the server to accept inbound SSH connections after the operating system installation completed.

Additional Ubuntu installation details are documented in the [Ubuntu Server Installation](./ubuntu-server-install.md) section.

---

## Initial System Validation

### First Boot Verification

After installation completed, the system successfully booted into Ubuntu Server and initialized core services.

<p align="center">
  <img src="../images/linux-infrastructure/remote-access-and-ssh/02-first-boot.jpeg" width="450">
</p>

<p align="center">
  <em>Initial Ubuntu Server boot confirmation following operating system deployment.</em>
</p>

Validation performed:
- verified successful operating system deployment
- confirmed network interface initialization
- verified OpenSSH availability
- confirmed system resource visibility
- validated hostname configuration

---

## Remote SSH Administration

### First SSH Connection

The first remote SSH session was established from a Windows 11 workstation using Windows Terminal and OpenSSH client utilities.

<p align="center">
  <img src="../images/linux-infrastructure/remote-access-and-ssh/03-first-ssh-session.jpeg" width="700">
</p>

<p align="center">
  <em>First successful SSH connection established from the Windows 11 administrative workstation.</em>
</p>

The initial connection process included:
- host authenticity verification
- ED25519 fingerprint validation
- known_hosts registration
- password authentication testing
- remote shell validation

This transition marked the movement from direct physical console management to remote Linux server administration workflows.

---

## SSH Key Generation

### Generating ED25519 SSH Keys

SSH key infrastructure was prepared on the Windows workstation using the built-in OpenSSH utilities within PowerShell.

<p align="center">
  <img src="../images/linux-infrastructure/remote-access-and-ssh/04-ssh-keygen.jpeg" width="650">
</p>

<p align="center">
  <em>Generating ED25519 SSH authentication keys from the Windows administrative workstation.</em>
</p>

Key generation objectives:
- prepare for passwordless authentication
- improve remote administration security
- support future infrastructure automation
- establish persistent trusted administrative access

---

## Tailscale Remote Connectivity

### Tailscale Mesh VPN Integration

Tailscale was deployed to provide secure remote access to the homelab environment without exposing SSH services directly to the public internet.

<p align="center">
  <img src="../images/linux-infrastructure/remote-access-and-ssh/05-tailscale-connection.jpeg" width="700">
</p>

<p align="center">
  <em>Tailscale status output showing active mesh VPN connectivity between infrastructure devices.</em>
</p>

Connected devices included:
- Ubuntu Server host
- Windows administrative workstation
- iPhone mobile client

This provided:
- encrypted remote connectivity
- simplified remote administration
- private mesh networking
- secure access without traditional port forwarding exposure

---

## Static Addressing

### Reserved Local IP Configuration

A reserved local IPv4 address was configured through the router management interface to ensure stable infrastructure addressing.

<p align="center">
  <img src="../images/linux-infrastructure/remote-access-and-ssh/06-reserved-ip.jpeg" width="450">
</p>

<p align="center">
  <em>Reserved local IPv4 assignment configured for consistent infrastructure connectivity.</em>
</p>

Benefits of reserved addressing:
- stable SSH connection targets
- predictable infrastructure management
- simplified service configuration
- consistent DNS and routing behavior

---

## Wake-on-LAN Configuration

### BIOS Wake-on-LAN Enablement

Wake-on-LAN related firmware settings were enabled through the motherboard BIOS configuration interface.

<p align="center">
  <img src="../images/linux-infrastructure/remote-access-and-ssh/07-wake-on-lan.jpeg" width="500">
</p>

<p align="center">
  <em>BIOS-level Wake-on-LAN and power recovery configuration adjustments.</em>
</p>

Configured features included:
- PCI-E wake support
- onboard LAN wake capability
- automatic power recovery behavior
- fan control optimization

This enabled remote power management functionality for the server environment.

---

## Mobile Wake-on-LAN Testing

Wake-on-LAN functionality was validated using a mobile client application on the local network.

<p align="center">
  <img src="../images/linux-infrastructure/remote-access-and-ssh/08-mobile-wol.jpeg" width="350">
</p>

<p align="center">
  <em>Successful Wake-on-LAN packet transmission from mobile client to Ubuntu Server host.</em>
</p>

Validation confirmed:
- successful magic packet delivery
- correct MAC addressing configuration
- operational remote power-on capability
- functional local subnet broadcast behavior

---

# Outcome

At completion:
- OpenSSH remote administration was operational
- Windows Terminal administration workflow was established
- SSH authentication infrastructure was initialized
- Tailscale remote connectivity was functional
- Reserved local addressing was configured
- Wake-on-LAN remote power management was operational

---

# Lessons Learned

Key takeaways included:
- OpenSSH deployment workflows
- SSH trust and fingerprint verification
- remote Linux administration fundamentals
- ED25519 key generation
- mesh VPN networking concepts
- persistent infrastructure addressing
- Wake-on-LAN configuration and testing
- transitioning from local to remote server operations
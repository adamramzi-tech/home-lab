# Remote Access and SSH

## Overview

This document covers the remote access, SSH, networking, and Wake-on-LAN configuration used to manage the home lab server.

The server is primarily administered remotely from a Windows 11 workstation using PowerShell as the primary terminal environment.

Remote management capabilities were progressively expanded throughout deployment and infrastructure setup, including:

- OpenSSH Server deployment
- Remote administration through PowerShell
- Reserved local IP addressing
- Secure remote access through Tailscale
- BIOS-level Wake-on-LAN configuration
- Mobile Wake-on-LAN management

The overall goal was to create a flexible and remotely manageable server environment without relying on direct physical access.

## Goals

- Enable secure remote server administration
- Minimize dependence on physical access
- Learn Linux server management from a Windows environment
- Maintain reliable network connectivity
- Establish persistent remote access workflows
- Implement remote power management
- Improve long-term infrastructure flexibility

## Administration Workstation

The primary client machine used for remote administration is a Windows 11 desktop workstation.

PowerShell was used as the primary terminal environment for:
- SSH connectivity
- Linux server administration
- Remote management testing
- Reboot and connectivity validation

This workflow provided:
- Native SSH support within Windows
- Cross-platform administration between Windows and Linux
- Convenient remote terminal access
- Familiar tooling while learning Linux server administration

Initial SSH testing and infrastructure management tasks were performed entirely from the Windows workstation.

## Initial Bare-Metal Deployment

Ubuntu Server was deployed directly onto the server hardware using a bootable installation USB.

The server initially operated using direct local access before transitioning to fully remote administration.

![Initial Bare-Metal Deployment](images/networking/initial-local-setup.jpeg)

## OpenSSH Server Installation

OpenSSH Server was installed during the Ubuntu Server installation process.

This enabled SSH connectivity immediately after deployment without requiring additional package installation later.

![Ubuntu Server Installation Process](images/ubuntu-install/ubuntu-install-process.jpeg)

## Featured Server Snaps

During installation, Ubuntu Server presented several optional server snaps and infrastructure-related packages.

No additional snaps were selected during initial deployment in order to keep the base operating system lightweight and minimal.

![Ubuntu Server Featured Snaps](images/ubuntu-install/installer-featured-snaps.jpeg)

## SSH Host Key Generation

SSH host keys were automatically generated during installation.

This prepared the server for encrypted remote communication immediately after deployment.

![SSH Key Generation](images/ubuntu-install/ssh-key-generation.jpeg)

## Initial Network Configuration

After installation completed, the server received a local IP address through DHCP from the router.

This local IP address was then used for initial SSH connectivity testing from the Windows workstation.

## Initial SSH Connection Attempt

The first SSH connection attempt was initiated through Windows PowerShell.

While learning SSH command syntax and remote administration workflow, several initial command formatting errors were encountered before successfully establishing a connection.

This process helped reinforce:
- SSH command structure
- User and host formatting
- Basic networking concepts
- Remote troubleshooting workflow
- Client-to-server connectivity validation

![Initial SSH Attempt](images/ssh/first-powershell-connection.jpeg)

## Successful Remote Login

After correcting the SSH syntax, remote login to the Ubuntu Server system was successful.

This confirmed:
- OpenSSH Server functionality
- Local network connectivity
- Proper user authentication
- Functional remote administration capability

SSH sessions were established using:

```bash
ssh username@server-ip
```

Example:

```bash
ssh adam@192.168.x.x
```

![Successful SSH Login](images/ssh/successful-ssh-login.jpeg)

## Remote Shutdown and Reconnection Testing

A remote shutdown test was performed to validate remote management behavior and reconnection workflow.

The server was remotely powered down using:

```bash
sudo shutdown now
```

As expected, the SSH session disconnected immediately after shutdown.

![Remote Shutdown Test](images/ssh/remote-shutdown.jpeg)

After rebooting the server, SSH connectivity was successfully restored.

This validated:
- Stable networking
- Persistent SSH functionality
- Reliable remote administration capability
- Proper system recovery behavior

![SSH Reconnection Test](images/ssh/ssh-reconnect-after-reboot.jpeg)

## Reserved IP Address Configuration

To improve long-term reliability, the server was assigned a reserved IP address through the router's DHCP reservation settings.

This ensured the server consistently received the same local IP address after:
- Reboots
- Network reconnects
- Power cycles

Using a reserved IP simplified:
- SSH administration
- Wake-on-LAN configuration
- Service access
- Remote troubleshooting
- Infrastructure documentation

The reserved local IP became the primary address used for server administration tasks.

## SSH Encryption and Security

SSH provides encrypted communication between the Windows workstation and the Ubuntu Server environment using secure cryptographic protocols.

Current remote access configuration includes:
- Encrypted SSH sessions
- Non-root user authentication
- Local network administration
- Remote access through Tailscale

The SSH server configuration file is located at:

```bash
/etc/ssh/sshd_config
```

## Tailscale Remote Access

Tailscale was later integrated to provide secure remote connectivity outside the local network.

This enabled remote SSH administration without exposing ports directly to the public internet.

Tailscale simplified secure connectivity while improving overall security posture by reducing public attack surface exposure.

Benefits included:
- Secure off-site access
- Simplified VPN functionality
- Device-to-device encrypted connectivity
- Improved remote administration flexibility

## Wake-on-LAN Configuration

Wake-on-LAN (WoL) was later configured to allow the server to be powered on remotely over the network.

This required returning to the motherboard BIOS configuration and enabling several hardware and power management settings.

Configured BIOS settings included:
- Resume By PCI-E Device
- Resume By Onboard Intel LAN
- Restore After AC Power Loss
- Smart Fan Control adjustments

Additional fan curve tuning and power behavior changes were also configured while inside BIOS.

![BIOS Wake-on-LAN Configuration](images/networking/wake-on-lan-bios.jpeg)

## Mobile Wake-on-LAN Management

After BIOS configuration was completed, Wake-on-LAN functionality was tested using a mobile application.

The server was added using:
- Hostname
- MAC address
- Reserved local IP address
- Broadcast subnet information

![Wake-on-LAN Mobile Application](images/networking/wol-mobile-app.jpeg)

![Wake-on-LAN Device Setup](images/networking/wol-device-setup.png)

Successful Wake-on-LAN testing confirmed:
- Proper BIOS configuration
- Functional network adapter wake support
- Correct MAC address targeting
- Reliable remote startup capability

![Wake-on-LAN Successful Test](images/networking/wol-success.png)

## Why Wake-on-LAN Was Useful

Wake-on-LAN improved overall flexibility by allowing the server to remain powered off when not actively needed while still maintaining remote accessibility.

This enabled:
- Remote startup without physical access
- Reduced unnecessary power consumption
- More flexible server management
- Easier recovery after shutdowns
- Improved convenience for remote administration

## Future Security Improvements

Planned future improvements include:
- SSH key-only authentication
- Disabling password authentication
- Fail2ban intrusion prevention
- UFW firewall configuration
- VLAN segmentation
- Additional monitoring and logging
- Reverse proxy integration

## Lessons Learned

- SSH dramatically improves server administration workflow
- Cross-platform administration between Windows and Linux is highly practical
- PowerShell provides an effective SSH management environment on Windows
- Reserved IP addressing greatly simplifies infrastructure management
- Wake-on-LAN requires both BIOS and network-level configuration
- Remote administration quickly becomes essential in a homelab environment
- Tailscale significantly simplified secure remote connectivity
- Reboot and reconnection testing helped validate system stability
- Encrypted remote administration is foundational for modern infrastructure management
- Small infrastructure improvements compound into a much more manageable environment over time

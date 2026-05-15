# Ubuntu Server Installation

## Objective

Deploy Ubuntu Server 26.04 LTS onto repurposed hardware to establish the foundation for the homelab infrastructure environment.

---

# Preparing Installation Media

## Downloading Ubuntu Server

- Downloaded Ubuntu Server 26.04 LTS ISO
- Verified correct server image selection

![Ubuntu Download](../screenshots/ubuntu-server-install/01-ubuntu-download.jpeg)

---

## Creating Bootable USB Media

Rufus was used on a Windows 11 workstation to create a bootable Ubuntu Server installation drive.

Configuration used:
- Partition scheme: GPT
- Target system: UEFI (non-CSM)
- File system: FAT32

![Rufus Configuration](../screenshots/ubuntu-server-install/02-rufus-usb.jpeg)

---

# BIOS Preparation

## BIOS Update

The motherboard BIOS was updated before OS deployment to improve hardware compatibility and long-term stability.

![BIOS Update](../screenshots/ubuntu-server-install/03-bios-update.jpeg)

---

# Ubuntu Server Installation

## Installer Boot

The system successfully booted into the Ubuntu Server installer environment.

![Installer Language Selection](../screenshots/ubuntu-server-install/04-language-selection.jpeg)

---

## Installation Type

The standard Ubuntu Server installation option was selected.

![Installation Type](../screenshots/ubuntu-server-install/05-installation-type.jpeg)

---

## System Profile Configuration

The initial hostname, username, and authentication credentials were configured during installation.

![Profile Configuration](../screenshots/ubuntu-server-install/06-profile-configuration.jpeg)

---

## Package Installation

Ubuntu Server packages and OpenSSH components were installed.

![Package Installation](../screenshots/ubuntu-server-install/07-installation-process.jpeg)

---

# First Boot and Initialization

## Cloud-Init and SSH Key Generation

After installation completed, the server initialized cloud-init services and generated SSH host keys.

![Cloud Init](../screenshots/ubuntu-server-install/08-cloud-init.jpeg)

---

# Remote Administration

## First SSH Connection

The first successful SSH session was established from the Windows 11 client workstation using Windows Terminal.

![SSH Session](../screenshots/ubuntu-server-install/09-first-ssh.jpeg)

---

# Outcome

At completion:
- Ubuntu Server was successfully deployed
- OpenSSH was operational
- Remote administration was functional
- The server was ready for Docker and infrastructure services

---

# Lessons Learned

Key takeaways included:
- boot media preparation
- UEFI/GPT installation workflows
- BIOS firmware management
- Linux server deployment
- remote administration fundamentals
- SSH-based operational workflows

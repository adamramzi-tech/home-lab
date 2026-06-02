# 01 - Virtualization Lab

## Status

Completed

---

## Overview

This lab establishes the virtualization foundation for the enterprise infrastructure track by deploying VMware Workstation Pro on the primary Windows 11 workstation and provisioning the initial enterprise virtual machine inventory.

Two virtual machines are deployed: DC01, a Windows Server 2022 system that will later serve as the Active Directory domain controller, and WIN11-CLIENT01, a Windows 11 Enterprise client that will serve as the domain-joined enterprise workstation. Both systems are provisioned with VMware Tools and clean baseline snapshots before any enterprise roles are introduced.

This lab represents the transition from the Linux infrastructure phase into a broader hybrid environment. The virtualization platform established here becomes the operational foundation for all subsequent enterprise infrastructure labs, including Active Directory, Group Policy, domain client management, and centralized security monitoring.

---

## Objectives

- validate hardware virtualization support on the Windows 11 workstation
- install and configure VMware Workstation Pro
- create an organized enterprise virtualization directory structure
- review and validate VMware virtual networking
- download and organize enterprise operating system installation media
- deploy DC01 as the initial Windows Server 2022 virtual machine
- deploy WIN11-CLIENT01 as the Windows 11 Enterprise client virtual machine
- install VMware Tools on both virtual machines
- create clean baseline snapshots for both VMs before enterprise role deployment

---

## Project Context

Previous phases of the homelab focused primarily on Linux infrastructure, containerized services, observability, and ingress architecture running on a dedicated Ubuntu Server host. The enterprise infrastructure phase introduced new requirements that Linux infrastructure alone could not address: Windows Server workloads, domain-based identity, enterprise client systems, and Group Policy management.

Rather than deploying enterprise workloads directly onto the operational Linux host, the environment adopts a hybrid architecture in which virtualization workloads are hosted on the primary Windows 11 workstation using VMware Workstation. This separation preserves Linux infrastructure stability while allowing enterprise infrastructure to evolve independently.

---

## Technologies Used

- VMware Workstation Pro 26H1
- Windows Server 2022 Standard Evaluation (Desktop Experience)
- Windows 11 Enterprise Evaluation
- AMD-V Hardware Virtualization
- VMware Virtual Networking (NAT)
- Thin-Provisioned Virtual Disks
- Snapshot-Based Rollback Workflows

---

## Architecture and Topology

```text
Windows 11 Workstation
│
└── VMware Workstation Pro
    │
    ├── DC01
    │   └── Windows Server 2022 Standard Evaluation
    │       ├── Planned: Active Directory Domain Services
    │       └── Planned: AD-Integrated DNS
    │
    └── WIN11-CLIENT01
        └── Windows 11 Enterprise Evaluation
            └── Planned: Domain-joined enterprise workstation

                    ↕ LAN

Ubuntu Server 26.04 LTS
│
├── Docker Infrastructure
├── Monitoring Stack
├── Reverse Proxy Layer
└── Remote Administration Services
```

Both VMs initially use VMware NAT networking to simplify early deployment and reduce exposure during provisioning. Bridged networking is introduced in Lab 02 when LAN-level reachability becomes a requirement for Active Directory.

---

## Prerequisites

- Windows 11 workstation available as the virtualization host
- Hardware virtualization enabled in BIOS/UEFI
- VMware Workstation Pro installed
- Sufficient CPU, memory, and NVMe storage available for VM workloads
- Windows Server 2022 ISO available
- Windows 11 Enterprise ISO available
- Administrative access to the host workstation

---

## Deployment Steps

### Step One - Validate Hardware Virtualization Support

Before deploying VMware Workstation, hardware-assisted virtualization support was validated through Windows Task Manager (Performance → CPU → Virtualization: Enabled).

The virtualization host for this environment is:

| Component | Detail |
|---|---|
| CPU | AMD Ryzen 5 7600X3D |
| Memory | 32 GB DDR5 |
| Storage | NVMe SSD |

If virtualization is disabled, it can be enabled by rebooting into BIOS/UEFI and enabling AMD-V or SVM Mode.

Hardware virtualization validation:

<img src="../../images/enterprise-infrastructure/01-virtualization-lab/01-validating-virtualization-support.jpg" alt="01-validating-virtualization-support" width="700">

The Task Manager CPU panel confirmed virtualization was enabled in firmware and the workstation had sufficient available resources for the planned VM inventory.

PowerShell can also be used to validate Hyper-V prerequisites:

```powershell
systeminfo
```

Expected output:

```text
Hyper-V Requirements:
    VM Monitor Mode Extensions: Yes
    Virtualization Enabled In Firmware: Yes
```

---

### Step Two - Install VMware Workstation Pro

VMware Workstation Pro 26H1 was downloaded from the Broadcom support portal and installed with administrative privileges.

VMware download page:

<img src="../../images/enterprise-infrastructure/01-virtualization-lab/02-vmware-download-page.jpg" alt="02-vmware-download-page" width="700">

During installation, VMware detected that Windows Hypervisor Platform was enabled on the host. The installer noted that Hyper-V components may affect virtualization behavior and that nested virtualization may be limited. Default compatibility settings were retained — the environment remained fully operational without requiring Hyper-V removal.

Compatibility notice:

<img src="../../images/enterprise-infrastructure/01-virtualization-lab/03-vmware-compatible-setup.jpg" alt="03-vmware-compatible-setup" width="700">

Installation progress:

<img src="../../images/enterprise-infrastructure/01-virtualization-lab/04-vmware-installation-progress.jpg" alt="04-vmware-installation-progress" width="700">

Successful installation was confirmed by launching VMware Workstation and verifying the hypervisor initialized without errors:

<img src="../../images/enterprise-infrastructure/01-virtualization-lab/05-vmware-first-launch.jpg" alt="05-vmware-first-launch" width="700">

---

### Step Three - Create Enterprise Virtual Machine Directory Structure

A dedicated directory structure was created on the secondary NVMe storage volume (`D:`) to organize enterprise virtualization assets before any VMs were deployed. Storing VM workloads on a separate volume from the host OS reduces storage contention and simplifies management.

```text
D:\
└── VMware\
    ├── ISOs\
    ├── Virtual Machines\
    │   ├── DC01\
    │   └── WIN11-CLIENT01\
    └── Snapshots\
```

| Directory | Purpose |
|---|---|
| `ISOs` | Operating system installation media |
| `Virtual Machines` | VMware VM configuration and virtual disks |
| `DC01` | Planned Active Directory domain controller VM |
| `WIN11-CLIENT01` | Planned domain-joined Windows client VM |
| `Snapshots` | Snapshot exports and rollback organization |

Directory structure validation:

<img src="../../images/enterprise-infrastructure/01-virtualization-lab/06-vmware-directory-structure.jpg" alt="06-vmware-directory-structure" width="700">

---

### Step Four - Configure VMware Virtual Networking

The VMware Virtual Network Editor was reviewed to validate the default virtual networking configuration before VM deployment.

| Network | Purpose |
|---|---|
| `VMnet0` | Bridged networking |
| `VMnet1` | Host-only networking |
| `VMnet8` | NAT networking |

NAT networking (`VMnet8`) was selected for the initial deployment phase. Under NAT, VMs receive VMware-managed private addresses, outbound internet access is translated through the Windows host, and VMs remain logically separated from the production LAN. This reduces risk during early provisioning and avoids prematurely exposing Active Directory services or enterprise DNS onto the broader network before the environment is validated.

Virtual Network Editor validation:

<img src="../../images/enterprise-infrastructure/01-virtualization-lab/07-vmware-virtual-network-editor.jpg" alt="07-vmware-virtual-network-editor" width="700">

---

### Step Five - Download Enterprise Installation Media

Windows Server 2022 and Windows 11 Enterprise evaluation ISOs were downloaded from the Microsoft Evaluation Center and organized in the VMware ISO repository.

| Operating System | Intended Purpose |
|---|---|
| Windows Server 2022 | Active Directory Domain Controller and enterprise infrastructure services |
| Windows 11 Enterprise 24H2 | Domain-joined enterprise workstation and Group Policy testing |

Windows Server 2022 download:

<img src="../../images/enterprise-infrastructure/01-virtualization-lab/08-windows-server-2022-download.jpg" alt="08-windows-server-2022-download" width="700">

Windows 11 Enterprise download:

<img src="../../images/enterprise-infrastructure/01-virtualization-lab/09-windows-11-enterprise-download.jpg" alt="09-windows-11-enterprise-download" width="700">

ISOs were renamed using standardized naming conventions and stored under `D:\VMware\ISOs\`:

```text
Windows_Server_2022_Eval_x64.iso
Windows_11_Enterprise_24H2_x64.iso
```

ISO repository:

<img src="../../images/enterprise-infrastructure/01-virtualization-lab/10-enterprise-iso-repository.jpg" alt="10-enterprise-iso-repository" width="700">

---

### Step Six - Deploy DC01 (Windows Server 2022)

DC01 was created as the initial enterprise server VM and will later serve as the Active Directory domain controller and DNS server.

**VM configuration:**

| Setting | Value |
|---|---|
| VM Name | `DC01` |
| Guest OS | Windows Server 2022 Standard Evaluation (Desktop Experience) |
| CPU | 2 vCPUs |
| Memory | 4096 MB |
| Disk | 80 GB (single file) |
| Network | NAT |
| VM Storage Path | `D:\VMware\Virtual Machines\DC01\` |
| Installation Media | `D:\VMware\ISOs\Windows_Server_2022_Eval_x64.iso` |

VMware new VM wizard:

<img src="../../images/enterprise-infrastructure/01-virtualization-lab/11-vmware-new-vm-wizard.jpg" alt="11-vmware-new-vm-wizard" width="700">

VM naming and storage location:

<img src="../../images/enterprise-infrastructure/01-virtualization-lab/12-dc01-vm-naming-and-location.jpg" alt="12-dc01-vm-naming-and-location" width="700">

Virtual disk allocation:

<img src="../../images/enterprise-infrastructure/01-virtualization-lab/13-dc01-virtual-disk-allocation.jpg" alt="13-dc01-virtual-disk-allocation" width="700">

Memory allocation:

<img src="../../images/enterprise-infrastructure/01-virtualization-lab/14-dc01-memory-allocation.jpg" alt="14-dc01-memory-allocation" width="700">

Windows Server ISO mounted:

<img src="../../images/enterprise-infrastructure/01-virtualization-lab/15-dc01-windows-server-iso-mounted.jpg" alt="15-dc01-windows-server-iso-mounted" width="700">

Because Easy Install was intentionally avoided to preserve full deployment visibility, the installer required manually selecting the virtual CD-ROM from the UEFI boot manager on first boot:

<img src="../../images/enterprise-infrastructure/01-virtualization-lab/16-dc01-uefi-boot-manager.jpg" alt="16-dc01-uefi-boot-manager" width="700">

**Windows Server installation:**

Windows Server 2022 Standard Evaluation (Desktop Experience) was selected to provide the full GUI installation appropriate for the enterprise learning phase:

<img src="../../images/enterprise-infrastructure/01-virtualization-lab/17-windows-server-2022-edition-selection.jpg" alt="17-windows-server-2022-edition-selection" width="700">

Default installer partitioning was used against the 80 GB virtual disk:

<img src="../../images/enterprise-infrastructure/01-virtualization-lab/18-dc01-install-target-disk.jpg" alt="18-dc01-install-target-disk" width="700">

Installation progress:

<img src="../../images/enterprise-infrastructure/01-virtualization-lab/19-windows-server-installation-progress.jpg" alt="19-windows-server-installation-progress" width="700">

**Initial server configuration:**

After installation, the built-in Administrator password was configured:

<img src="../../images/enterprise-infrastructure/01-virtualization-lab/20-dc01-administrator-password-configuration.jpg" alt="20-dc01-administrator-password-configuration" width="700">

Initial administrator login:

<img src="../../images/enterprise-infrastructure/01-virtualization-lab/21-dc01-initial-administrator-login.jpg" alt="21-dc01-initial-administrator-login" width="700">

Server Manager launched on first boot, confirming a successful installation:

<img src="../../images/enterprise-infrastructure/01-virtualization-lab/22-dc01-server-manager-first-boot.jpg" alt="22-dc01-server-manager-first-boot" width="700">

**VMware Tools installation:**

VMware Tools was installed to improve virtual hardware drivers, display handling, shutdown integration, and host/guest time synchronization.

VMware Tools install menu:

<img src="../../images/enterprise-infrastructure/01-virtualization-lab/23-vmware-tools-install-menu.jpg" alt="23-vmware-tools-install-menu" width="700">

Mounted VMware Tools ISO:

<img src="../../images/enterprise-infrastructure/01-virtualization-lab/24-vmware-tools-mounted-iso.jpg" alt="24-vmware-tools-mounted-iso" width="700">

Setup wizard:

<img src="../../images/enterprise-infrastructure/01-virtualization-lab/25-vmware-tools-setup-wizard.jpg" alt="25-vmware-tools-setup-wizard" width="700">

Installation progress:

<img src="../../images/enterprise-infrastructure/01-virtualization-lab/26-vmware-tools-installation-progress.jpg" alt="26-vmware-tools-installation-progress" width="700">

Installation complete:

<img src="../../images/enterprise-infrastructure/01-virtualization-lab/27-vmware-tools-installation-complete.jpg" alt="27-vmware-tools-installation-complete" width="700">

Restart required:

<img src="../../images/enterprise-infrastructure/01-virtualization-lab/28-vmware-tools-restart-required.jpg" alt="28-vmware-tools-restart-required" width="700">

**Baseline snapshot:**

After rebooting, a clean baseline snapshot was created before any Active Directory roles were introduced:

Snapshot name: `DC01 - Clean Windows Server Base Install`

Snapshot description: `Initial Windows Server 2022 installation completed with VMware Tools installed prior to Active Directory deployment.`

<img src="../../images/enterprise-infrastructure/01-virtualization-lab/29-dc01-clean-base-install-snapshot.jpg" alt="29-dc01-clean-base-install-snapshot" width="700">

---

### Step Seven - Deploy WIN11-CLIENT01 (Windows 11 Enterprise)

WIN11-CLIENT01 was created as the enterprise client workstation and will later serve as the domain-joined endpoint for Active Directory testing and RSAT-based server administration.

**VM configuration:**

| Setting | Value |
|---|---|
| VM Name | `WIN11-CLIENT01` |
| Guest OS | Windows 11 Enterprise Evaluation |
| CPU | 4 vCPUs |
| Memory | 8192 MB |
| Disk | 120 GB (single file) |
| Network | NAT |
| VM Storage Path | `D:\VMware\Virtual Machines\WIN11-CLIENT01\` |
| Installation Media | `D:\VMware\ISOs\Windows_11_Enterprise_24H2_x64.iso` |

ISO selection:

<img src="../../images/enterprise-infrastructure/01-virtualization-lab/30-win11-client-vm-iso-selection.jpg" alt="30-win11-client-vm-iso-selection" width="700">

VM naming and storage location:

<img src="../../images/enterprise-infrastructure/01-virtualization-lab/31-win11-client-vm-name-and-location.jpg" alt="31-win11-client-vm-name-and-location" width="700">

Windows 11 requires TPM functionality. VMware prompted for VM encryption before enabling the virtual TPM device:

<img src="../../images/enterprise-infrastructure/01-virtualization-lab/32-win11-client-vm-tpm-encryption.jpg" alt="32-win11-client-vm-tpm-encryption" width="700">

Disk allocation:

<img src="../../images/enterprise-infrastructure/01-virtualization-lab/33-win11-client-vm-disk-allocation.jpg" alt="33-win11-client-vm-disk-allocation" width="700">

Hardware allocation (8 GB memory, 4 vCPUs):

<img src="../../images/enterprise-infrastructure/01-virtualization-lab/34-win11-client-vm-hardware-allocation.jpg" alt="34-win11-client-vm-hardware-allocation" width="700">

**Windows 11 Enterprise installation:**

Installation start:

<img src="../../images/enterprise-infrastructure/01-virtualization-lab/35-win11-installation-start.jpg" alt="35-win11-installation-start" width="700">

Target disk selection:

<img src="../../images/enterprise-infrastructure/01-virtualization-lab/36-win11-install-target-disk.jpg" alt="36-win11-install-target-disk" width="700">

Installation confirmation:

<img src="../../images/enterprise-infrastructure/01-virtualization-lab/37-win11-ready-to-install.jpg" alt="37-win11-ready-to-install" width="700">

During onboarding, the system was configured with a local administrative account using the "Domain join instead" workflow to avoid Microsoft account dependencies and preserve lab portability:

<img src="../../images/enterprise-infrastructure/01-virtualization-lab/38-win11-domain-join-instead.jpg" alt="38-win11-domain-join-instead" width="700">

The local administrative account used was `labadmin`.

Initial desktop confirming successful installation:

<img src="../../images/enterprise-infrastructure/01-virtualization-lab/39-win11-initial-desktop.jpg" alt="39-win11-initial-desktop" width="700">

Windows briefly attempted to apply updates during onboarding. The update workflow was cancelled to preserve deployment momentum and establish a clean baseline snapshot before introducing additional system changes.

**VMware Tools installation:**

Mounted VMware Tools ISO:

<img src="../../images/enterprise-infrastructure/01-virtualization-lab/40-win11-vmware-tools-mounted.jpg" alt="40-win11-vmware-tools-mounted" width="700">

Setup wizard:

<img src="../../images/enterprise-infrastructure/01-virtualization-lab/41-win11-vmware-tools-setup.jpg" alt="41-win11-vmware-tools-setup" width="700">

Installation progress:

<img src="../../images/enterprise-infrastructure/01-virtualization-lab/42-win11-vmware-tools-installation-progress.jpg" alt="42-win11-vmware-tools-installation-progress" width="700">

Restart required:

<img src="../../images/enterprise-infrastructure/01-virtualization-lab/43-win11-vmware-tools-restart-required.jpg" alt="43-win11-vmware-tools-restart-required" width="700">

**Hostname standardization and baseline snapshot:**

After rebooting, the hostname was standardized to `WIN11-CLIENT01`:

<img src="../../images/enterprise-infrastructure/01-virtualization-lab/44-win11-vmware-tools-rename.jpg" alt="44-win11-vmware-tools-rename" width="700">

A clean baseline snapshot was then created:

Snapshot name: `WIN11-CLIENT01 - Clean Windows 11 Baseline`

Snapshot description: `Initial Windows 11 Enterprise client deployment completed with VMware Tools installed prior to domain integration.`

<img src="../../images/enterprise-infrastructure/01-virtualization-lab/45-win11-client-baseline-snapshot.jpg" alt="45-win11-client-baseline-snapshot" width="700">

---

## Validation

Validation at completion confirmed:

- VMware Workstation Pro initialized successfully on the Windows 11 host
- hardware virtualization support was confirmed and operational
- enterprise virtualization directory structure created on `D:\VMware\`
- VMware NAT networking initialized correctly
- Windows Server 2022 and Windows 11 Enterprise ISOs downloaded and organized
- DC01 deployed successfully with Windows Server 2022, VMware Tools installed, and baseline snapshot created
- WIN11-CLIENT01 deployed successfully with Windows 11 Enterprise, VMware Tools installed, hostname set to `WIN11-CLIENT01`, and baseline snapshot created
- outbound internet connectivity confirmed on both VMs via NAT networking

| System | Role |
|---|---|
| `DC01` | Planned Active Directory Domain Controller |
| `WIN11-CLIENT01` | Planned domain-joined enterprise workstation |

---

## Troubleshooting and Adjustments

### Windows Hypervisor Platform Compatibility

During VMware Workstation installation, the installer detected that Windows Hypervisor Platform was enabled on the host and noted that Hyper-V components may affect virtualization behavior and limit nested virtualization. The environment remained fully operational without requiring Hyper-V removal, so default compatibility settings were retained.

### Manual ISO-Based Installation Workflow

VMware Easy Install was intentionally avoided for both VMs. Manual installation workflows were selected to preserve full deployment visibility and reinforce enterprise installation procedures. This required manually selecting the virtual CD-ROM from the UEFI boot manager on DC01's first boot, but more closely reflects real enterprise provisioning workflows.

### Windows 11 TPM Requirements

Creating the WIN11-CLIENT01 VM required enabling VM encryption before VMware would provision the virtual TPM device required by Windows 11. This introduced VM encryption configuration and VMware credential storage considerations. The VMware TPM workflow was retained as it aligns with modern enterprise Windows deployment standards.

### Windows Update Behavior During WIN11-CLIENT01 Onboarding

Windows attempted to apply updates automatically during the Windows 11 onboarding process. The update was cancelled to preserve deployment momentum and establish a clean baseline snapshot before introducing additional system changes.

---

## Security Considerations

### Separation Between Linux and Enterprise Infrastructure

The enterprise virtualization environment is hosted on the Windows 11 workstation and intentionally separated from the operational Ubuntu Server host. This reduces infrastructure coupling and eliminates operational risk to existing Linux services during enterprise infrastructure experimentation.

### NAT Networking During Early Deployment

NAT networking isolates VMs from direct LAN participation during the early deployment phase, avoiding premature exposure of Active Directory services, enterprise DNS, or Windows management protocols onto the broader local network before the environment is validated.

### Local Administrative Accounts

Both systems use local administrative accounts during deployment. This preserves isolated deployment control and rollback simplicity. Centralized identity workflows are introduced through Active Directory in Lab 03.

### Snapshot Recovery and Change Control

Baseline snapshots were created before introducing any enterprise configuration changes. This is especially important during Active Directory deployment, DNS reconfiguration, and Group Policy testing where misconfigurations may be difficult to reverse without a clean rollback point.

---

## Outcome

At completion, the enterprise virtualization foundation is fully established:

- VMware Workstation Pro deployed on the Windows 11 workstation
- organized enterprise virtualization storage on `D:\VMware\`
- DC01 provisioned with Windows Server 2022, VMware Tools, and a clean baseline snapshot
- WIN11-CLIENT01 provisioned with Windows 11 Enterprise, VMware Tools, and a clean baseline snapshot
- both VMs connected via NAT networking with outbound internet access

The environment is prepared for:

- Active Directory Domain Services deployment
- AD-integrated DNS configuration
- domain joining workflows for WIN11-CLIENT01
- Group Policy management
- hybrid Linux and Windows integration

---

## Lessons Learned

### Virtualization Is Infrastructure, Not Just a Tool

VMware Workstation became the enterprise infrastructure platform, system lifecycle management layer, and rollback mechanism for the entire enterprise track. Treating it as foundational infrastructure rather than a convenience feature shaped better operational decisions throughout the lab.

### Deliberate Organization Before Scaling

Creating the directory structure before deploying any VMs significantly improved VM organization, ISO management, and snapshot workflows. Organizational decisions made before scaling infrastructure are much harder to retrofit afterward.

### Snapshot Discipline Enables Confident Experimentation

Clean baseline snapshots before major configuration changes allow aggressive experimentation without risking irreversible configuration drift. This discipline becomes especially valuable during Active Directory deployment and DNS reconfiguration in later labs.

### Start Simple with Networking

Beginning with NAT networking simplified deployment considerably. Introducing bridged networking in Lab 02 only when LAN reachability became a genuine requirement reinforced the value of incremental complexity over premature optimization.

### Manual Provisioning Builds Operational Understanding

Avoiding automated VM provisioning workflows provided direct visibility into VM hardware allocation, ISO mounting, UEFI boot behavior, TPM requirements, and guest OS deployment. The slower manual workflow produced significantly better infrastructure understanding than automation would have.

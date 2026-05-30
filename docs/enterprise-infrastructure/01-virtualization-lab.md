# 01 - Virtualization Lab

## Status

Completed

---

## Overview


This lab establishes the virtualization foundation for the enterprise infrastructure track by deploying VMware Workstation Pro on the primary Windows 11 workstation and provisioning the initial enterprise virtual machine inventory.

The deployment covers VMware installation and configuration, virtual networking setup, enterprise operating system provisioning, VMware Tools integration, and snapshot-based rollback workflows. Two virtual machines are deployed during this lab: DC01, a Windows Server 2022 system that will later serve as the Active Directory domain controller, and WIN11-CLIENT01, a Windows 11 Enterprise client that will serve as the domain-joined enterprise workstation.

This lab represents the transition from the Linux infrastructure phase into a broader hybrid environment. The virtualization platform established here becomes the operational foundation for all subsequent enterprise infrastructure labs, including Active Directory, Group Policy, domain client management, Linux and Active Directory integration, and centralized security monitoring.

## Objective

The goal of this lab is to establish the virtualization foundation for the enterprise infrastructure track using VMware Workstation on the primary Windows 11 workstation.

This environment will provide isolated virtual infrastructure for future Windows Server, Active Directory, Group Policy, and cross-platform integration labs.

The objective is not only to deploy virtual machines, but also to understand:
- virtual networking
- resource allocation
- VM lifecycle management
- snapshots and rollback workflows
- infrastructure segmentation
- enterprise lab design considerations

---

## Project Context

The enterprise infrastructure phase introduces virtualization as the foundational technology layer required to support Windows Server administration, Active Directory, Group Policy, and future hybrid infrastructure integration.

Previous phases of the homelab environment focused primarily on Linux infrastructure, containerized services, observability, remote administration, and ingress architecture running on a dedicated Ubuntu Server host.

While the Linux infrastructure environment remains the operational foundation of the homelab, enterprise infrastructure requirements introduced several new architectural needs:

- isolated operating system environments
- rapid rollback and recovery workflows
- support for Windows Server workloads
- domain-based identity infrastructure
- enterprise client systems
- controlled networking experimentation
- snapshot-based testing workflows

Rather than deploying enterprise workloads directly onto the operational Linux infrastructure host, the environment adopts a hybrid architecture in which virtualization workloads are hosted separately on the primary Windows 11 workstation using VMware Workstation.

This separation strategy reduces operational risk to the existing Linux infrastructure environment while allowing enterprise infrastructure experimentation to evolve independently.

This lab establishes the virtualization platform that future enterprise labs depend on, including:

- Windows Server deployment
- Active Directory Domain Services
- domain-joined Windows clients
- Group Policy management
- centralized authentication
- enterprise DNS architecture
- hybrid Linux and Windows integration

The virtualization layer therefore becomes the operational foundation of the enterprise infrastructure track and represents the transition from a Linux-focused homelab toward a broader hybrid infrastructure environment.

---

## Technologies Used

- VMware Workstation Pro
- Windows 11
- Windows Server 2022 ISO
- Windows 11 Enterprise ISO
- AMD-V Hardware Virtualization
- VMware Virtual Networking
- NAT Networking
- Bridged Networking
- Thin-Provisioned Virtual Disks
- Snapshot-Based Rollback Workflows

---

## Architecture or Topology

The enterprise virtualization environment is hosted on the primary Windows 11 workstation while remaining logically separated from the operational Ubuntu Server infrastructure host.

The Windows workstation functions as:

- the virtualization host
- the primary enterprise administration endpoint
- the management platform for future Active Directory infrastructure

The Ubuntu Server host continues functioning as:

- the Linux infrastructure platform
- the container services host
- the monitoring and reverse proxy platform

Initial virtualization architecture:

```text
Windows 11 Workstation
│
└── VMware Workstation
    │
    ├── DC01 (planned)
    │   └── Windows Server 2022
    │       ├── Active Directory Domain Services
    │       └── AD-Integrated DNS
    │
    └── WIN11-CLIENT01 (planned)
        └── Windows 11 Enterprise Client

                ↓

        VMware Virtual Networking

                ↓

        Existing LAN Infrastructure

                ↓

Ubuntu Server 26.04 LTS
│
├── Docker Infrastructure
├── Monitoring Stack
├── Reverse Proxy Layer
└── Remote Administration Services
```

Initial networking utilizes VMware NAT networking in order to:

- simplify deployment
- preserve recoverability
- reduce networking complexity
- provide outbound internet access
- maintain connectivity with the Linux infrastructure environment

More advanced networking models such as bridged networking, segmented virtual networks, and enterprise DNS integration will be introduced incrementally in future enterprise infrastructure phases.

---

## Prerequisites

- Windows 11 workstation available as the virtualization host
- Hardware virtualization enabled in BIOS/UEFI
- VMware Workstation installed
- Sufficient CPU, memory, and NVMe storage available for VM workloads
- Windows Server 2022 ISO available
- Windows 11 Enterprise ISO available
- Administrative access to the host workstation 

---

## Deployment Steps

### Step One - Validate Hardware Virtualization Support

Before deploying VMware Workstation, hardware-assisted virtualization support was validated on the Windows 11 workstation.

This step confirms the system can support:
- 64-bit guest operating systems
- hardware-accelerated virtualization
- Windows Server workloads
- enterprise VM networking
- snapshot and rollback workflows
- future Active Directory infrastructure

The virtualization host for this environment is the primary Windows 11 workstation using:
- AMD Ryzen 5 7600X3D
- 32GB DDR5 memory
- NVMe SSD storage

Verifying virtualization support before hypervisor deployment reduces the likelihood of:
- unsupported guest operating systems
- VM boot failures
- degraded virtualization performance
- deployment troubleshooting later in the lab lifecycle

---

#### Actions Performed

Virtualization support was validated through Windows Task Manager.

Validation workflow:

1. Open Task Manager
2. Navigate to:
   - `Performance`
   - `CPU`
3. Confirm:
   - `Virtualization: Enabled`

If virtualization support is disabled:
- reboot into BIOS/UEFI
- enable AMD-V or SVM Mode
- save configuration changes
- reboot into Windows

---

#### Commands or Validation

Example PowerShell validation:

```powershell
systeminfo
````

Expected output:

```text
Hyper-V Requirements:
    VM Monitor Mode Extensions: Yes
    Virtualization Enabled In Firmware: Yes
```

---

#### Validation

Example validation from Task Manager:

![01-validating-virtualization-support](../../images/enterprise-infrastructure/01-virtualization-lab/01-validating-virtualization-support.jpg)

The workstation reports:

- AMD Ryzen 5 7600X3D
- 32GB DDR5 memory
- virtualization enabled in firmware
- NVMe-backed storage devices available for VM workloads

Current system utilization also confirms the workstation has sufficient available resources for the initial enterprise VM inventory planned for this environment.

---

#### Operational Notes

This validation establishes the foundational hardware readiness required for the enterprise virtualization environment.

The workstation will function as:

- the VMware Workstation host
- the enterprise infrastructure management endpoint
- the primary administration platform for future Windows Server and Active Directory labs

---

### Step Two - Install VMware Workstation Pro

After validating hardware virtualization support, VMware Workstation Pro 26H1 was deployed on the Windows 11 workstation to establish the enterprise virtualization platform.

VMware Workstation was selected because it provides:

- hosted hypervisor functionality
- Windows Server compatibility
- snapshot and rollback workflows
- virtual networking support
- isolated VM environments
- lightweight enterprise lab scalability

The platform will function as:

- the primary enterprise virtualization environment
- the VM lifecycle management platform
- the foundation for future Active Directory infrastructure

---

#### Actions Performed

VMware Workstation Pro 26H1 for Windows was downloaded directly from the Broadcom support portal.

Download validation:

![02-vmware-download-page](../../images/enterprise-infrastructure/01-virtualization-lab/02-vmware-download-page.jpg)

The latest available Windows release was selected in order to:

- maintain platform compatibility
- avoid legacy hypervisor limitations
- align the environment with current VMware releases
- improve long-term maintainability of the enterprise lab

After download completion, the installer was launched with administrative privileges.

---

#### Configuration and Installation

During installation, VMware detected that the Windows Hypervisor Platform was available on the host system.

Compatibility validation:

![03-vmware-compatible-setup](../../images/enterprise-infrastructure/01-virtualization-lab/03-vmware-compatible-setup.jpg)

The installer noted:

- VMware may utilize the Windows Hypervisor Platform
- Hyper-V-related features may affect virtualization behavior
- nested virtualization may not be available while Hyper-V components remain enabled

Default installation settings were retained during deployment to:

- simplify initial deployment
- preserve vendor-supported defaults
- reduce unnecessary configuration complexity

Installation then proceeded normally.

Installation progress:

![04-vmware-installation-progress](../../images/enterprise-infrastructure/01-virtualization-lab/04-vmware-installation-progress.jpg)

---

#### Validation

Successful installation was validated by launching VMware Workstation and confirming the hypervisor initialized successfully without compatibility or virtualization errors.

Initial VMware Workstation launch:

![05-vmware-first-launch](../../images/enterprise-infrastructure/01-virtualization-lab/05-vmware-first-launch.jpg)

Validation confirmed:

- VMware Workstation installed successfully
- virtualization support remained operational
- VMware networking components initialized correctly
- the workstation was ready for VM deployment

---

#### Operational Notes

VMware Workstation establishes the virtualization foundation required for all future enterprise infrastructure labs.

This platform will later host:

- Windows Server 2022
- Active Directory Domain Services
- domain-joined Windows clients
- Group Policy testing environments
- hybrid Linux and Windows infrastructure experimentation

The virtualization environment remains intentionally separated from the operational Ubuntu Server infrastructure host in order to:

- preserve Linux infrastructure stability
- reduce workload contention
- simplify rollback workflows
- maintain operational separation between infrastructure domains

---

### Step Three - Create Enterprise Virtual Machine Directory Structure

After VMware Workstation was successfully installed, a dedicated directory structure was created on the workstation to organize enterprise virtualization assets.

Separating virtualization resources into a structured directory layout improves:

- VM organization
- snapshot management
- ISO management
- recoverability
- long-term maintainability
- operational consistency

This structure also establishes predictable storage locations for:

- virtual machines
- installation media
- snapshots
- future enterprise infrastructure resources

---

#### Actions Performed

A dedicated virtualization directory structure was created on the secondary NVMe storage volume (`D:`).

The environment intentionally avoids storing enterprise VM workloads on the primary operating system drive in order to:

- reduce storage contention
- preserve host OS responsiveness
- simplify VM management
- improve storage organization
- support future infrastructure expansion

Initial virtualization directory structure:

```text
D:\
└── VMware\
    ├── ISOs\
    ├── Virtual Machines\
    │   ├── DC01\
    │   └── WIN11-CLIENT01\
    └── Snapshots\
```

Directory purposes:

| Directory          | Purpose                                       |
| ------------------ | --------------------------------------------- |
| `ISOs`             | Operating system installation media           |
| `Virtual Machines` | VMware VM configuration and virtual disks     |
| `DC01`             | Planned Active Directory domain controller VM |
| `WIN11-CLIENT01`   | Planned domain-joined Windows client VM       |
| `Snapshots`        | Snapshot exports and rollback organization    |

---

#### Commands or Configuration

Example PowerShell workflow:

```powershell
New-Item -ItemType Directory -Path "D:\VMware"

New-Item -ItemType Directory -Path "D:\VMware\ISOs"

New-Item -ItemType Directory -Path "D:\VMware\Virtual Machines"

New-Item -ItemType Directory -Path "D:\VMware\Virtual Machines\DC01"

New-Item -ItemType Directory -Path "D:\VMware\Virtual Machines\WIN11-CLIENT01"

New-Item -ItemType Directory -Path "D:\VMware\Snapshots"
```

Equivalent GUI-based folder creation through File Explorer was also acceptable.

---

#### Validation

Directory structure validation:

![06-vmware-directory-structure](../../images/enterprise-infrastructure/01-virtualization-lab/06-vmware-directory-structure.jpg)

Validation confirmed:

- virtualization storage directories were created successfully
- VM storage paths were organized before deployment
- ISO storage was separated from VM workloads
- snapshot storage locations were prepared in advance
- enterprise VM inventory structure was established

---

#### Operational Notes

Creating the virtualization storage structure before deploying virtual machines establishes cleaner operational boundaries and simplifies long-term infrastructure management.

This organization strategy supports:

- predictable VM storage locations
- cleaner snapshot management
- easier backup workflows
- simplified VM migration
- scalable enterprise infrastructure growth

The directory structure also aligns with the broader documentation-first and infrastructure organization standards used throughout the homelab environment.

---

### Step Four - Configure VMware Virtual Networking

After VMware Workstation was installed and the virtualization directory structure was prepared, VMware virtual networking was reviewed to establish baseline connectivity for the enterprise lab environment.

Virtual networking provides the communication layer between:

- virtual machines
- the Windows 11 host system
- the local LAN
- external internet connectivity

This networking layer becomes foundational for:

- Windows Server deployment
- Active Directory communication
- DNS functionality
- domain client connectivity
- future hybrid infrastructure integration

---

#### Networking Strategy

The initial enterprise virtualization environment utilizes VMware NAT networking.

NAT networking was selected during the early deployment phase because it:

- simplifies VM deployment
- provides outbound internet connectivity
- reduces initial networking complexity
- preserves recoverability
- minimizes risk to the existing LAN environment
- allows controlled experimentation before introducing bridged networking

Under NAT networking:

- virtual machines receive private VMware-managed IP addresses
- outbound internet access is translated through the Windows host
- the Windows workstation acts as the intermediary between VMs and the physical network

This approach allows enterprise systems to:

- download updates
- access external resources
- communicate internally
- remain logically separated from the production LAN during initial deployment

More advanced networking models such as:

- bridged networking
- segmented virtual networks
- VLAN-backed virtualization
- isolated lab segments

may be introduced later as the enterprise environment matures.

---

#### Actions Performed

The VMware Virtual Network Editor was reviewed to validate the default VMware networking configuration.

Initial networking validation focused on:

- VMware NAT functionality
- VMnet adapter availability
- virtual DHCP functionality
- baseline outbound connectivity preparation

Default VMware virtual networking components include:

| Network  | Purpose              |
| -------- | -------------------- |
| `VMnet0` | Bridged networking   |
| `VMnet1` | Host-only networking |
| `VMnet8` | NAT networking       |

The initial deployment will primarily utilize:

- `VMnet8`
- VMware NAT networking

for early-stage enterprise infrastructure deployment.

---

#### Validation

VMware Virtual Network Editor validation:

![07-vmware-virtual-network-editor](../../images/enterprise-infrastructure/01-virtualization-lab/07-vmware-virtual-network-editor.jpg)

Validation confirmed:

- VMware virtual networking components initialized successfully
- NAT networking was available
- VMware virtual adapters were created on the host workstation
- DHCP services were operational
- the environment was prepared for VM connectivity testing

The virtualization environment now supports:

- internal VM communication
- outbound internet access
- future enterprise VM deployment workflows

---

#### Operational Notes

The networking model selected during this phase intentionally prioritizes:

- simplicity
- recoverability
- controlled experimentation
- low operational risk

This approach allows enterprise infrastructure components to be introduced incrementally without immediately affecting:

- workstation DNS behavior
- production LAN services
- existing Linux infrastructure operations

Future enterprise labs may later transition selected systems toward bridged networking in order to support:

- direct LAN participation
- centralized DNS workflows
- Active Directory service discovery
- cross-platform monitoring integration
- hybrid Linux and Windows infrastructure communication

---

### Step Five - Download Enterprise Installation Media

After validating the VMware virtualization environment and confirming virtual networking functionality, enterprise operating system installation media was downloaded and organized for future virtual machine deployment.

This step prepared the environment for:

- Windows Server deployment
- Active Directory implementation
- Windows enterprise client provisioning
- future hybrid infrastructure integration

The enterprise infrastructure plan already defined:

- `DC01` as the future Active Directory Domain Controller
- `WIN11-CLIENT01` as the future domain-joined workstation

---

#### Why This Step Was Necessary

The virtualization environment required locally available ISO images before virtual machines could be created.

Downloading installation media in advance:

- simplifies VM provisioning
- avoids deployment interruptions
- centralizes infrastructure assets
- improves deployment consistency
- supports future VM rebuild and recovery workflows

This also aligns with the project's documentation-first and infrastructure reproducibility philosophy.

---

#### Installation Media Acquired

The following operating systems were downloaded:

| Operating System           | Intended Purpose                                                          |
| -------------------------- | ------------------------------------------------------------------------- |
| Windows Server 2022        | Active Directory Domain Controller and enterprise infrastructure services |
| Windows 11 Enterprise 24H2 | Domain-joined enterprise workstation and Group Policy testing             |

These systems will later support:

- Active Directory Domain Services
- AD-integrated DNS
- centralized authentication
- Group Policy administration
- Windows administration workflows
- hybrid Linux and Windows integration

---

#### Downloading Windows Server 2022

Windows Server 2022 evaluation media was downloaded directly from the Microsoft Evaluation Center.

The ISO download workflow included:

- selecting the Windows Server 2022 evaluation
- choosing the 64-bit ISO option
- downloading the evaluation installation media locally to the workstation

Windows Server 2022 download selection:

![08-windows-server-2022-download](../../images/enterprise-infrastructure/01-virtualization-lab/08-windows-server-2022-download.jpg)

The Windows Server ISO will later be used for:

- Active Directory deployment
- DNS services
- centralized authentication infrastructure
- enterprise server administration workflows

---

#### Downloading Windows 11 Enterprise

Windows 11 Enterprise evaluation media was also downloaded directly from Microsoft.

The ISO download workflow included:

- selecting Windows 11 Enterprise
- choosing the 64-bit Enterprise ISO
- downloading the installation media locally to the workstation

Windows 11 Enterprise download selection:

![09-windows-11-enterprise-download](../../images/enterprise-infrastructure/01-virtualization-lab/09-windows-11-enterprise-download.jpg)

The Windows 11 Enterprise VM will later function as:

- a domain-joined enterprise client
- a Group Policy testing workstation
- a Windows administration endpoint
- an enterprise authentication test system

---

#### Organizing the ISO Repository

All installation media was centralized within the dedicated VMware ISO repository:

```text
D:\VMware\ISOs\
```

The downloaded ISO images were renamed using standardized infrastructure naming conventions for improved readability and long-term maintainability.

Final ISO repository structure:

![10-enterprise-iso-repository](../../images/enterprise-infrastructure/01-virtualization-lab/10-enterprise-iso-repository.jpg)

Example installation media naming:

```text
Windows_Server_2022_Eval_x64.iso
Windows_11_Enterprise_24H2_x64.iso
```

Separating installation media from:

- VM disks
- snapshot data
- VMware configuration files

improves:

- organization
- deployment consistency
- recoverability
- lifecycle management
- infrastructure scalability

---

#### Validation

Validation confirmed:

- Windows Server 2022 installation media downloaded successfully
- Windows 11 Enterprise installation media downloaded successfully
- ISO files were organized correctly within the VMware repository
- standardized naming conventions were applied
- the virtualization environment was prepared for VM provisioning workflows

At completion, the environment was ready for:

- `DC01` virtual machine creation
- Windows Server deployment
- Windows enterprise client deployment
- future Active Directory implementation

---

#### Operational Notes

Acquiring and organizing installation media before VM deployment reduces deployment interruptions and improves virtualization workflow consistency.

Standardized ISO naming and centralized media management also support:

- reproducibility
- operational clarity
- predictable deployment paths
- future infrastructure expansion
- long-term maintainability of the enterprise virtualization environment

---

### Step Six - Create the DC01 Virtual Machine and Install Windows Server 2022

After preparing the VMware virtualization environment, the first enterprise virtual machine was created and provisioned for Windows Server installation.

The new virtual machine, `DC01`, will later function as:

- the Active Directory Domain Controller
- the centralized DNS server
- the primary enterprise identity system
- the foundational Windows infrastructure host for the lab

This step marks the transition from virtualization platform preparation to actual enterprise system deployment.

---

#### Why This Step Was Necessary

The enterprise infrastructure track depends on a dedicated Windows Server system to support:

- Active Directory Domain Services
- DNS
- centralized authentication
- Group Policy
- future domain-joined client testing

Without `DC01`, the later enterprise labs would have no domain controller or identity foundation to build on.

Creating the VM in a structured way also reinforced the project’s infrastructure standards:

- predictable naming
- dedicated storage paths
- deliberate resource allocation
- clean installation workflows
- reproducible deployment practices

---

#### VM Provisioning Strategy

The VM was created conservatively so it would perform well on the host workstation without consuming unnecessary resources.

Planned configuration:

| Setting            | Value                                                        |
| ------------------ | ------------------------------------------------------------ |
| VM Name            | `DC01`                                                       |
| Guest OS           | Windows Server 2022 Standard Evaluation (Desktop Experience) |
| CPU                | 2 vCPUs                                                      |
| Memory             | 4096 MB                                                      |
| Disk               | 80 GB                                                        |
| Disk Layout        | Single file                                                  |
| Network            | NAT                                                          |
| VM Storage Path    | `D:\VMware\Virtual Machines\DC01\`                           |
| Installation Media | `D:\VMware\ISOs\Windows_Server_2022_Eval_x64.iso`            |

This configuration was selected to provide enough resources for Active Directory and DNS while keeping the VM lightweight and manageable.

---

#### Actions Performed

A new virtual machine was created using VMware Workstation Pro.

Initial creation workflow:

![11-vmware-new-vm-wizard](../../images/enterprise-infrastructure/01-virtualization-lab/11-vmware-new-vm-wizard.jpg)

The VM was named and assigned to the dedicated enterprise VM directory:

![12-dc01-vm-naming-and-location](../../images/enterprise-infrastructure/01-virtualization-lab/12-dc01-vm-naming-and-location.jpg)

The virtual disk was sized at 80 GB and configured as a single file:

![13-dc01-virtual-disk-allocation](../../images/enterprise-infrastructure/01-virtualization-lab/13-dc01-virtual-disk-allocation.jpg)

Memory was adjusted to 4 GB to better support Windows Server and future AD-related workloads:

![14-dc01-memory-allocation](../../images/enterprise-infrastructure/01-virtualization-lab/14-dc01-memory-allocation.jpg)

The Windows Server ISO was then attached manually to the virtual CD/DVD device:

![15-dc01-windows-server-iso-mounted](../../images/enterprise-infrastructure/01-virtualization-lab/15-dc01-windows-server-iso-mounted.jpg)

Because the VM was installed manually rather than through Easy Install, the boot process required selecting the virtual CD-ROM from the UEFI boot manager:

![16-dc01-uefi-boot-manager](../../images/enterprise-infrastructure/01-virtualization-lab/16-dc01-uefi-boot-manager.jpg)

---

#### Windows Server Installation

The Windows Server installer launched successfully and the edition selection screen was presented.

The selected edition was:

- Windows Server 2022 Standard Evaluation (Desktop Experience)

This choice provided the full GUI installation, which is appropriate for the early enterprise learning phase.

Edition selection:

![17-windows-server-2022-edition-selection](../../images/enterprise-infrastructure/01-virtualization-lab/17-windows-server-2022-edition-selection.jpg)

The installer then presented the target disk selection screen, showing the full 80 GB virtual disk as unallocated space.

The default installer partitioning approach was used rather than manually creating partitions.

Target disk selection:

![18-dc01-install-target-disk](../../images/enterprise-infrastructure/01-virtualization-lab/18-dc01-install-target-disk.jpg)

Windows Server installation then began copying files and preparing the VM for first boot.

Installation progress:

![19-windows-server-installation-progress](../../images/enterprise-infrastructure/01-virtualization-lab/19-windows-server-installation-progress.jpg)

---

#### Initial Server Configuration

After installation completed, Windows Server prompted for the built-in Administrator password.

This step initialized the local privileged account used for first login and early server configuration.

Administrator password configuration:

![20-dc01-administrator-password-configuration](../../images/enterprise-infrastructure/01-virtualization-lab/20-dc01-administrator-password-configuration.jpg)

Once the password was set, the VM transitioned into the first login state.

Initial administrator login:

![21-dc01-initial-administrator-login](../../images/enterprise-infrastructure/01-virtualization-lab/21-dc01-initial-administrator-login.jpg)

After logging in, Server Manager opened successfully and confirmed that the Windows Server installation completed correctly.

First boot into Server Manager:

![22-dc01-server-manager-first-boot](../../images/enterprise-infrastructure/01-virtualization-lab/22-dc01-server-manager-first-boot.jpg)

---

### VMware Tools Installation and Baseline Snapshot

After confirming that Windows Server 2022 booted successfully, VMware Tools was installed to improve virtualization integration, performance, and overall VM manageability.

Installing VMware Tools provides:

- optimized virtual hardware drivers
- improved display and mouse handling
- better VM shutdown/restart integration
- improved guest responsiveness
- host and guest time synchronization

This was completed before Active Directory deployment to ensure the server began from a clean and fully integrated baseline state.

---

#### VMware Tools Installation

VMware Tools installation was initiated from the VMware Workstation toolbar.

VMware Tools install menu:

![23-vmware-tools-install-menu](../../images/enterprise-infrastructure/01-virtualization-lab/23-vmware-tools-install-menu.jpg)

The VMware Tools ISO was automatically mounted inside the guest operating system.

Mounted VMware Tools installation media:

![24-vmware-tools-mounted-iso](../../images/enterprise-infrastructure/01-virtualization-lab/24-vmware-tools-mounted-iso.jpg)

The VMware Tools setup wizard launched successfully.

VMware Tools setup wizard:

![25-vmware-tools-setup-wizard](../../images/enterprise-infrastructure/01-virtualization-lab/25-vmware-tools-setup-wizard.jpg)

The default Typical installation option was used.

Installation progress:

![26-vmware-tools-installation-progress](../../images/enterprise-infrastructure/01-virtualization-lab/26-vmware-tools-installation-progress.jpg)

After installation completed successfully, the setup wizard confirmed completion.

Installation completed successfully:

![27-vmware-tools-installation-complete](../../images/enterprise-infrastructure/01-virtualization-lab/27-vmware-tools-installation-complete.jpg)

The VM then prompted for a reboot so the VMware Tools drivers and services could initialize correctly.

Restart prompt:

![28-vmware-tools-restart-required](../../images/enterprise-infrastructure/01-virtualization-lab/28-vmware-tools-restart-required.jpg)

---

#### Baseline Snapshot Creation

After rebooting successfully, a clean baseline snapshot was created before any Active Directory roles or enterprise services were installed.

Snapshot name:

`DC01 - Clean Windows Server Base Install`

Snapshot description:

`Initial Windows Server 2022 installation completed with VMware Tools installed prior to Active Directory deployment.`

Baseline snapshot creation:

![29-dc01-clean-base-install-snapshot](../../images/enterprise-infrastructure/01-virtualization-lab/29-dc01-clean-base-install-snapshot.jpg)

This snapshot established a stable rollback point that can be used if future enterprise configuration changes require recovery or troubleshooting.

---

#### Validation

Validation confirmed:

- the VM was created successfully
- the VM was stored in the correct enterprise directory
- the virtual disk was provisioned correctly
- memory was allocated appropriately
- the Windows Server ISO mounted correctly
- the UEFI boot process selected the installer media
- Windows Server installed successfully
- the Administrator account was initialized
- Server Manager launched on first boot
- VMware Tools installed successfully
- VMware guest integration services initialized correctly
- the VM rebooted successfully after installation
- the Windows Server environment remained stable
- a clean recovery snapshot was created before Active Directory deployment

At completion, `DC01` was fully prepared for enterprise role configuration and Active Directory installation.

---

#### Operational Notes

This step established the first real enterprise infrastructure system in the lab.

It also validated several important operational patterns:

- manual VM provisioning
- deliberate resource allocation
- organized storage paths
- explicit installation media management
- enterprise-oriented installation choices
- clean first-boot validation

The environment now has a functioning Windows Server platform that can be used for:

- Active Directory
- DNS
- future domain-joined clients
- Group Policy testing
- broader enterprise infrastructure labs

---

### Step Seven - Create the WIN11-CLIENT01 Enterprise Client VM

After successfully deploying the initial Windows Server environment, a dedicated enterprise client workstation was created to support future Active Directory and Group Policy testing.

The new virtual machine, `WIN11-CLIENT01`, will later function as:

- a domain-joined enterprise workstation
- a Group Policy target system
- a centralized authentication test client
- a Windows administration endpoint
- a client-side validation system for Active Directory infrastructure

This step expands the enterprise environment beyond server infrastructure and introduces the first simulated enterprise endpoint into the lab.

---

#### Why This Step Was Necessary

Active Directory environments require both server-side and client-side systems in order to properly simulate enterprise infrastructure workflows.

Without a dedicated Windows client system, later enterprise labs would be unable to validate:

- domain joining
- Group Policy application
- centralized authentication
- enterprise DNS functionality
- user and workstation management
- client/server communication workflows

Creating a dedicated enterprise workstation also introduces a more realistic infrastructure model in which:

- servers provide centralized services
- clients consume enterprise resources
- administrative workflows occur across multiple systems

This establishes the foundational structure required for future hybrid infrastructure labs.

---

#### VM Provisioning Strategy

The Windows 11 enterprise client VM was provisioned with additional resources compared to the Windows Server VM in order to better simulate a modern enterprise workstation environment.

Planned configuration:

| Setting            | Value                                               |
| ------------------ | --------------------------------------------------- |
| VM Name            | `WIN11-CLIENT01`                                    |
| Guest OS           | Windows 11 Enterprise Evaluation                    |
| CPU                | 4 vCPUs                                             |
| Memory             | 8192 MB                                             |
| Disk               | 120 GB                                              |
| Disk Layout        | Single file                                         |
| Network            | NAT                                                 |
| VM Storage Path    | `D:\VMware\Virtual Machines\WIN11-CLIENT01\`        |
| Installation Media | `D:\VMware\ISOs\Windows_11_Enterprise_24H2_x64.iso` |

This configuration was selected to support:

- Windows 11 resource requirements
- future enterprise tooling
- browser-based administration
- RSAT tooling
- Group Policy testing
- long-term workstation usability

---

#### Actions Performed

A new VMware virtual machine was created for the enterprise client deployment.

The Windows 11 Enterprise ISO was selected during the VM creation process:

![30-win11-client-vm-iso-selection](../../images/enterprise-infrastructure/01-virtualization-lab/30-win11-client-vm-iso-selection.jpg)

The VM was then named and assigned to the dedicated enterprise VM storage path:

![31-win11-client-vm-name-and-location](../../images/enterprise-infrastructure/01-virtualization-lab/31-win11-client-vm-name-and-location.jpg)

Because Windows 11 requires TPM functionality, VMware prompted for VM encryption in order to enable the virtual Trusted Platform Module device.

VM encryption and TPM configuration:

![32-win11-client-vm-tpm-encryption](../../images/enterprise-infrastructure/01-virtualization-lab/32-win11-client-vm-tpm-encryption.jpg)

The VM disk was configured as a 120 GB single-file virtual disk:

![33-win11-client-vm-disk-allocation](../../images/enterprise-infrastructure/01-virtualization-lab/33-win11-client-vm-disk-allocation.jpg)

Hardware resources were then adjusted to allocate:

- 8 GB memory
- 4 vCPUs

Hardware allocation:

![34-win11-client-vm-hardware-allocation](../../images/enterprise-infrastructure/01-virtualization-lab/34-win11-client-vm-hardware-allocation.jpg)

---

#### Windows 11 Enterprise Installation

The Windows 11 installer launched successfully and installation initialization began.

Initial installation workflow:

![35-win11-installation-start](../../images/enterprise-infrastructure/01-virtualization-lab/35-win11-installation-start.jpg)

The installer then presented the virtual disk as unallocated space.

The default Windows partitioning workflow was retained.

Target disk selection:

![36-win11-install-target-disk](../../images/enterprise-infrastructure/01-virtualization-lab/36-win11-install-target-disk.jpg)

The installation summary screen confirmed deployment of:

- Windows 11 Enterprise Evaluation
- a clean installation workflow

Installation confirmation:

![37-win11-ready-to-install](../../images/enterprise-infrastructure/01-virtualization-lab/37-win11-ready-to-install.jpg)

During the Windows onboarding process, the system was intentionally configured using a local administrative account rather than integrating with a Microsoft cloud account.

The local account deployment path was selected through the "Domain join instead" workflow.

Enterprise onboarding workflow:

![38-win11-domain-join-instead](../../images/enterprise-infrastructure/01-virtualization-lab/38-win11-domain-join-instead.jpg)

This approach preserves:

- local administrative control
- lab portability
- isolated enterprise testing
- independence from external Microsoft account dependencies

The local administrative account used for the initial deployment was:

```text
labadmin
```

---

#### Initial Client Validation

After installation completed successfully, the Windows 11 Enterprise desktop loaded correctly and confirmed baseline workstation functionality.

Initial desktop validation:

![39-win11-initial-desktop](../../images/enterprise-infrastructure/01-virtualization-lab/39-win11-initial-desktop.jpg)

Validation confirmed:

- successful Windows 11 installation
- graphical desktop initialization
- local administrator login functionality
- internet connectivity through VMware NAT networking
- operational enterprise client deployment

---

#### VMware Tools Installation

After validating the base operating system deployment, VMware Tools was installed to improve virtualization integration and workstation responsiveness.

The VMware Tools installation media was mounted successfully inside the guest operating system:

![40-win11-vmware-tools-mounted](../../images/enterprise-infrastructure/01-virtualization-lab/40-win11-vmware-tools-mounted.jpg)

The VMware Tools setup wizard then launched normally.

VMware Tools setup wizard:

![41-win11-vmware-tools-setup](../../images/enterprise-infrastructure/01-virtualization-lab/41-win11-vmware-tools-setup.jpg)

The default Typical installation workflow was retained.

Installation progress:

![42-win11-vmware-tools-installation-progress](../../images/enterprise-infrastructure/01-virtualization-lab/42-win11-vmware-tools-installation-progress.jpg)

After installation completed, VMware Tools requested a system restart.

Restart requirement confirmation:

![43-win11-vmware-tools-restart-required](../../images/enterprise-infrastructure/01-virtualization-lab/43-win11-vmware-tools-restart-required.jpg)

---

#### Hostname Standardization and Baseline Snapshot

After rebooting successfully, the workstation hostname was standardized to align with the enterprise naming convention established earlier in the infrastructure plan.

The workstation hostname was configured as:

```text
WIN11-CLIENT01
```

Post-installation workstation validation:

![44-win11-vmware-tools-rename](../../images/enterprise-infrastructure/01-virtualization-lab/44-win11-vmware-tools-rename.jpg)

At this stage:

- VMware Tools integration was operational
- networking functionality remained stable
- the enterprise workstation naming standard was applied
- the client environment was prepared for future domain integration

Before joining the workstation to Active Directory, a clean rollback snapshot was created.

Snapshot name:

```text
WIN11-CLIENT01 - Clean Windows 11 Baseline
```

Snapshot description:

```text
Initial Windows 11 Enterprise client deployment completed with VMware Tools installed prior to domain integration.
```

Baseline snapshot creation:

![45-win11-client-baseline-snapshot](../../images/enterprise-infrastructure/01-virtualization-lab/45-win11-client-baseline-snapshot.jpg)

This establishes a stable recovery point prior to:

- Active Directory integration
- Group Policy deployment
- enterprise authentication configuration
- domain-based management workflows

---

#### Validation

Validation confirmed:

- the enterprise client VM was created successfully
- TPM support initialized correctly
- Windows 11 Enterprise installed successfully
- the virtual disk was provisioned correctly
- memory and CPU resources were allocated successfully
- VMware NAT networking functioned correctly
- the local administrative account initialized successfully
- VMware Tools installed successfully
- guest integration services initialized properly
- workstation naming standards were applied correctly
- the VM rebooted successfully after VMware Tools installation
- a clean enterprise workstation rollback snapshot was created

At completion, `WIN11-CLIENT01` was fully prepared for future Active Directory integration and enterprise workstation management workflows.

---

#### Operational Notes

This step introduced the first enterprise client system into the virtualization environment and completed the minimum infrastructure foundation required for future Active Directory labs.

The enterprise virtualization environment now contains:

- a Windows Server infrastructure platform (`DC01`)
- a Windows enterprise workstation (`WIN11-CLIENT01`)
- VMware snapshot rollback workflows
- isolated enterprise virtualization infrastructure
- baseline networking between server and client systems

This environment is now prepared for the next major enterprise infrastructure phase:

- Active Directory Domain Services deployment
- enterprise DNS configuration
- domain joining workflows
- Group Policy management
- centralized authentication infrastructure

---

## Validation

Validation confirmed:

- VMware Workstation initialized successfully on the Windows 11 host workstation
- virtualization support remained enabled and operational
- enterprise virtualization storage paths were organized successfully
- VMware NAT networking initialized correctly
- Windows Server 2022 installation media was downloaded and organized
- Windows 11 Enterprise installation media was downloaded and organized
- `DC01` deployed successfully as the initial enterprise server VM
- `WIN11-CLIENT01` deployed successfully as the enterprise client workstation VM
- VMware Tools installed correctly on both virtual machines
- baseline rollback snapshots were created for both systems
- enterprise naming conventions were applied successfully
- outbound networking functioned correctly for all deployed systems
- the virtualization environment was fully prepared for Active Directory deployment

At completion, the enterprise infrastructure environment contained:

| System           | Role                                         |
| ---------------- | -------------------------------------------- |
| `DC01`           | Planned Active Directory Domain Controller   |
| `WIN11-CLIENT01` | Planned domain-joined enterprise workstation |

The environment was now operationally prepared for:

- Active Directory Domain Services
- enterprise DNS
- domain joining workflows
- Group Policy deployment
- centralized authentication
- hybrid Linux and Windows integration

---

## Troubleshooting and Adjustments

Several deployment adjustments and operational refinements were encountered throughout the virtualization deployment process.

---

### Windows Hypervisor Platform Compatibility

During VMware Workstation installation, the installer detected that Windows Hypervisor Platform functionality was enabled on the host workstation.

VMware displayed compatibility messaging indicating:

- Hyper-V-related components may affect virtualization behavior
- nested virtualization capabilities could be limited
- VMware may utilize the Windows Hypervisor Platform backend

The environment remained operational without requiring Hyper-V removal, so default compatibility settings were retained during deployment.

This avoided introducing unnecessary host-level changes during the initial enterprise infrastructure rollout.

---

### Manual ISO-Based Installation Workflow

VMware Easy Install was intentionally avoided for both enterprise virtual machines.

Manual installation workflows were selected instead in order to:

- preserve installation visibility
- maintain full deployment control
- reinforce enterprise installation procedures
- avoid automated guest customization
- improve infrastructure reproducibility

Because of this decision, the Windows Server VM required manually selecting the virtual CD-ROM device from the VMware UEFI boot manager during first boot.

While this introduced a minor additional deployment step, it more closely reflects real enterprise provisioning workflows.

---

### Windows 11 TPM Requirements

During creation of the Windows 11 Enterprise VM, VMware required VM encryption before enabling the virtual TPM device required by Windows 11.

This introduced:

- VM encryption configuration
- VMware credential storage considerations
- virtual TPM initialization requirements

The environment retained VMware’s TPM workflow because it aligns with modern enterprise Windows deployment standards.

---

### Windows Update Installation Behavior

During the Windows 11 onboarding process, Windows attempted to download and apply feature and security updates automatically before the operating system fully stabilized.

The update workflow was intentionally cancelled in order to:

- preserve deployment momentum
- avoid unnecessary onboarding delays
- complete VMware Tools installation first
- establish a clean baseline snapshot before introducing additional system changes

Although Windows briefly attempted to apply updates during onboarding, the environment ultimately proceeded using the existing installation state without completing the update cycle.

This approach preserved a cleaner baseline image for future rollback and troubleshooting workflows.

---

### Baseline Snapshot Strategy

Baseline snapshots were intentionally created before introducing:

- Active Directory
- Group Policy
- domain integration
- authentication changes
- enterprise configuration modifications

This decision improves:

- recoverability
- troubleshooting safety
- rollback workflows
- lab experimentation flexibility

The snapshot strategy also establishes an operational discipline commonly used in enterprise virtualization environments.

---

## Security Considerations

Several architectural and operational security decisions were introduced during the virtualization deployment phase.

---

### Separation Between Linux and Enterprise Infrastructure

The enterprise virtualization environment was intentionally separated from the operational Ubuntu Server infrastructure host.

This separation reduces:

- infrastructure coupling
- operational risk
- service disruption exposure
- resource contention
- cross-environment instability

The Ubuntu Server environment continues functioning independently as:

- the Linux infrastructure platform
- the container services host
- the reverse proxy platform
- the monitoring environment

Meanwhile, VMware Workstation functions as the isolated enterprise experimentation platform.

---

### NAT Networking During Early Deployment

The environment initially utilizes VMware NAT networking instead of bridged networking.

This decision reduces exposure during the early infrastructure phase by:

- preventing direct LAN participation
- simplifying DNS behavior
- reducing accidental service conflicts
- isolating experimental enterprise services
- preserving recoverability

This approach also avoids prematurely exposing:

- Active Directory services
- enterprise DNS
- Windows management protocols

onto the broader local network before the environment is fully validated.

---

### Local Administrative Accounts

Both systems initially utilize local administrative accounts during deployment.

This preserves:

- isolated deployment control
- rollback simplicity
- infrastructure portability
- independence from external identity providers

Centralized identity workflows will later be introduced through Active Directory.

---

### Snapshot Recovery and Change Control

Baseline snapshots were created before introducing major infrastructure changes.

This improves:

- operational safety
- recovery workflows
- rollback capability
- change isolation
- troubleshooting efficiency

Snapshot-based recovery becomes especially important during:

- Active Directory deployment
- DNS reconfiguration
- Group Policy testing
- authentication troubleshooting

---

## Outcome

This lab successfully established the enterprise virtualization foundation required for the broader enterprise infrastructure track.

The completed environment now includes:

- VMware Workstation Pro deployed on the Windows 11 workstation
- organized enterprise virtualization storage paths
- VMware virtual networking
- centralized ISO management
- a Windows Server 2022 VM (`DC01`)
- a Windows 11 Enterprise VM (`WIN11-CLIENT01`)
- VMware Tools integration across both systems
- baseline rollback snapshots for recovery and experimentation

The environment now supports future enterprise infrastructure capabilities including:

- Active Directory Domain Services
- AD-integrated DNS
- centralized authentication
- domain-joined Windows clients
- Group Policy administration
- hybrid Linux and Windows integration
- enterprise security monitoring workflows

This lab also marked a major architectural transition in the homelab project by introducing:

- enterprise virtualization
- Windows infrastructure
- centralized identity planning
- multi-system infrastructure orchestration

---

## Lessons Learned

This lab reinforced several important infrastructure and operational concepts.

---

### Virtualization Is an Infrastructure Layer, Not Just a Tool

The deployment process reinforced that virtualization is foundational infrastructure rather than simply a convenience feature.

VMware Workstation became:

- the enterprise infrastructure platform
- the system lifecycle management layer
- the rollback and recovery mechanism
- the isolation boundary for experimentation

This shifted the homelab environment toward a more realistic enterprise operational model.

---

### Deliberate Infrastructure Organization Matters

Creating structured storage paths before deployment significantly improved:

- VM organization
- ISO management
- snapshot workflows
- infrastructure readability
- operational consistency

The environment became easier to manage because organizational decisions were made before scaling infrastructure inventory.

---

### Snapshot Discipline Improves Operational Confidence

Creating clean baseline snapshots before major configuration changes introduced a safer experimentation workflow.

This improves confidence during future labs involving:

- Active Directory
- Group Policy
- DNS modifications
- authentication troubleshooting
- Linux and Windows integration

The environment can now be modified aggressively without risking irreversible configuration drift.

---

### Enterprise Networking Requires Incremental Complexity

Beginning with VMware NAT networking simplified deployment significantly while still preserving:

- internet connectivity
- VM communication
- infrastructure flexibility

This reinforced the value of introducing networking complexity incrementally rather than prematurely implementing bridged or segmented enterprise networking.

---

### Manual Provisioning Reinforces Infrastructure Understanding

Avoiding fully automated VM provisioning workflows increased operational understanding of:

- VM hardware allocation
- ISO mounting
- UEFI boot workflows
- TPM requirements
- virtualization dependencies
- guest operating system deployment

The slower manual workflow provided significantly better visibility into the enterprise deployment lifecycle.

---

### Hybrid Infrastructure Architecture Creates Better Separation

Separating the Linux infrastructure environment from the enterprise virtualization environment created cleaner operational boundaries.

This architecture now allows:

- Linux infrastructure experimentation
- enterprise Windows infrastructure deployment
- virtualization testing
- Active Directory experimentation

without destabilizing the operational Ubuntu Server environment.

The project now reflects a more mature hybrid infrastructure design rather than a single-purpose homelab deployment.

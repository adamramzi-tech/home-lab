# Recovery and Rollback Strategy

## Purpose

This document defines recovery expectations and rollback strategy rather than a fully automated backup implementation.

The environment is now a multi-system hybrid one: a Linux host running containerized services, three Windows virtual machines carrying a single Active Directory domain, and a Microsoft Entra tenant synchronized from that domain. Each layer recovers differently, and a rollback in one can have consequences in another.

The objective is to:

- reduce operational risk
- preserve infrastructure stability
- simplify rollback workflows
- improve deployment confidence
- document recovery expectations before failures occur

This matters most where layers depend on each other:

- every Windows system and Ubuntu Server authenticate against DC01
- the tenant's synchronized users and groups are a projection of `corp.home.arpa`
- the scheduled health report on WIN11-CLIENT01 reaches DC01, the Wazuh Manager, and Portainer

---

## Current State

At this stage of the project:

- recovery workflows are primarily manual
- infrastructure is partially reproducible through Docker Compose
- GitHub serves as the primary configuration and documentation backup layer
- automated backup workflows have not yet been implemented
- no Active Directory backup beyond virtual machine snapshots is documented, and the Active Directory Recycle Bin is not enabled
- tenant configuration is performed through administrative portals, so the repository documents it rather than defining it

Recovery strategy currently focuses on:
- configuration preservation
- infrastructure reproducibility
- rollback planning
- VM snapshot strategy
- operational recoverability during experimentation

---

# Linux Infrastructure Recovery

## Docker Compose Recovery

Docker Compose deployments should remain:

- declarative
- reproducible
- configuration-driven

Persistent application data should remain separated from containers through:

- Docker volumes
- bind mounts
- exported configuration files

Recovery workflow generally includes:

1. restore compose files
2. restore persistent volumes or backups
3. redeploy containers
4. validate networking and ingress
5. validate monitoring and service health

---

## Reverse Proxy Recovery

The reverse proxy layer represents centralized ingress for infrastructure services.

Backup priorities include:

- NGINX Proxy Manager data
- SSL certificates
- proxy host configurations
- Docker networking configuration

Loss of the ingress layer may impact:

- centralized service access
- hostname routing
- internal administration workflows

---

# Documentation and Configuration Recovery

Infrastructure documentation and configuration files should remain version controlled through GitHub.

Critical infrastructure artifacts include:

- Docker Compose files
- topology documentation
- architecture decision records
- deployment workflows
- infrastructure standards
- reverse proxy configurations
- monitoring stack configuration

Version-controlled documentation improves:

- infrastructure reproducibility
- rollback visibility
- operational traceability
- deployment consistency

The Git repository itself should be treated as part of the infrastructure recovery strategy rather than separate from it.

---

# Enterprise Infrastructure Recovery

## Snapshot Strategy

Virtual machine snapshots should be created:

- before major configuration changes
- before domain controller promotion
- before Group Policy testing
- before network redesigns
- before authentication integration changes

Snapshots should not replace proper backups, but they provide rapid rollback capability during experimentation.

Snapshots recorded in the [enterprise resource plan](enterprise-resource-plan.md) include `DC01 - Linux AD Integration Complete`, `WIN11-CLIENT01 - Linux AD Integration Validated`, and `SYNC01 - Domain Joined, Pre-Entra-Connect`.

---

## Active Directory Considerations

DC01 is the only domain controller, so it holds the only copy of `corp.home.arpa`. There is no replication partner to recover from, and DNS for the domain fails with it. Every Windows system and Ubuntu Server depend on it for authentication.

Special care should be taken before:

- schema changes
- DNS modifications
- domain restructuring
- Group Policy changes
- deleting directory objects

The Active Directory Recycle Bin is not enabled. The Entra Connect installer recommended it during Lab 02 of the Cloud and Hybrid Identity track, and it is held against the enterprise infrastructure track because it is forest-wide and irreversible once enabled. Until it is, a deleted object cannot be restored with its attributes and group memberships intact from within the directory. Lab 03 of that track showed what that costs in a hybrid environment: a synchronized account deleted and recreated on-premises arrived in the tenant as an unrelated new object under a new source anchor.

Reverting DC01 to a snapshot is not confined to DC01:

- member computers, including WIN11-CLIENT01, SYNC01, and Ubuntu Server, change their computer account passwords periodically, so a snapshot older than a member's last change leaves that member unable to establish a secure channel until it is repaired or rejoined
- every change Entra Connect Sync has already exported to the tenant is reverted on-premises, and the next synchronization cycle pushes the older state, including the deletion of any synchronized object created after the snapshot; a full import and full synchronization should follow such a restore rather than the regular delta cycle, since the connector's delta position is ahead of the restored directory
- `AZUREADSSOACC`'s Kerberos key reverts to the value it held when the snapshot was taken, which no longer matches the key Microsoft Entra ID holds once it has been rolled since, and seamless single sign-on fails until the key is rolled again

---

# Hybrid Identity Recovery

## Entra Connect Sync on SYNC01

Entra Connect Sync's configuration exists on `SYNC01` and in the documentation of Lab 02 of the Cloud and Hybrid Identity track: a Custom installation, organizational unit filtering to `OU=User Accounts` and `OU=Groups`, password hash synchronization, and `ms-DS-ConsistencyGuid` as the source anchor, authenticating to the directory as `svc-entraconnect`.

The source anchor is what makes a rebuild recoverable. `ms-DS-ConsistencyGuid` is written to each synchronized on-premises object, so a reinstalled server configured with the same anchor matches existing cloud objects rather than creating duplicates.

The scheduler does not survive a suspend of the `SYNC01` virtual machine: its next-cycle time goes stale while the service reports running, and only a full restart of the virtual machine corrects it. The track README records the details.

## Microsoft Entra Tenant

The tenant has no on-premises dependency for administration. The Global Administrator and the emergency access account are cloud-only, and the emergency access account is kept on `brindeck.onmicrosoft.com` so that a DNS or registration problem with `brindeck.com` cannot lock the tenant.

Recovery windows observed in the track:

- a deleted user, Microsoft 365 group, or cloud-only security group remains in a soft-deleted state for 30 days and can be restored within it
- distribution lists and mail-enabled security groups are hard-deleted and cannot be restored
- a deleted mailbox is soft-deleted rather than removed immediately
- a group carrying an active license assignment cannot be deleted until the assignment is removed

Licensing is perishable rather than recoverable: Microsoft Entra ID P1 and Exchange Online Plan 1 are carried by a trial subscription with a fixed end date.

---

# Security Monitoring Recovery

The Wazuh stack runs on Ubuntu Server from the upstream `wazuh-docker` repository at `v4.14.5`, in `~/infrastructure/security-monitoring-lab`, with the certificate set generated for it by the `wazuh-certs-generator` container. None of it is stored in this repository. Rebuilding it means recloning at the same version, regenerating certificates, and reapplying the dashboard port remapping, after which the four agents must reconnect to the Manager.

---

# Automation Library Recovery

The PowerShell script library and its Pester tests are version controlled in `infrastructure/automation-and-scripting/` and can be restored from the repository.

The scheduled health report's API credentials cannot. They are DPAPI-protected `Export-CliXml` files in `C:\Secrets` on WIN11-CLIENT01, readable only by the account that exported them on the machine where they were exported. A rebuilt WIN11-CLIENT01, or a different run-as account, needs both files exported again before the scheduled task is re-registered with `Register-LabHealthReportTask.ps1`.

---

# Operational Philosophy

The environment is intentionally designed to support:

- experimentation
- troubleshooting
- iterative deployment
- architectural evolution

Rollback planning exists to encourage safe experimentation while reducing the likelihood of prolonged infrastructure outages.

The goal is not to eliminate mistakes.

The goal is to ensure the environment remains:

- recoverable
- understandable
- reproducible
- operationally manageable

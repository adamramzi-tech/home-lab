# Enterprise Infrastructure

This directory contains infrastructure configuration files and supporting deployment artifacts for the enterprise infrastructure track.

---

## Active Deployments

Enterprise infrastructure workloads are hosted as virtual machines on the Windows 11 workstation using VMware Workstation Pro. Configuration files and deployment artifacts for those environments are managed directly on the virtualization host rather than stored here. The two parts of the track that run on the Ubuntu Server host, the Linux AD integration and the Wazuh stack, keep their configuration on that host.

---

## Completed Labs Without Stored Configuration

All seven labs are complete, and none of them stores configuration in this directory. Labs 01 through 05 configure the virtual machines on the Windows 11 workstation, so their configuration is managed directly on the virtualization host. Lab 06's SSSD and Kerberos configuration lives on Ubuntu Server itself. Lab 07's Wazuh stack also runs on Ubuntu Server, from the upstream `wazuh-docker` repository, cloned at `v4.14.5` into `~/infrastructure/security-monitoring-lab` on that host together with its generated certificates, so it is maintained there rather than copied here.

| Lab | Configuration managed outside this repository |
|---|---|
| [04 - Domain Client Lab](../../docs/enterprise-infrastructure/04-domain-client-lab.md) | Domain join configurations and client management artifacts |
| [05 - Group Policy Lab](../../docs/enterprise-infrastructure/05-group-policy-lab.md) | Group Policy Object definitions and policy documentation |
| [06 - Linux and AD Integration Lab](../../docs/enterprise-infrastructure/06-linux-ad-integration-lab.md) | SSSD and Kerberos configuration for Linux AD authentication |
| [07 - Security and Monitoring Lab](../../docs/enterprise-infrastructure/07-security-monitoring-lab.md) | The Wazuh single-node Docker Compose deployment, its generated certificate set, and the dashboard port remapping |

---

## Notes

Only configuration files and artifacts that provide educational or documentation value are stored in this repository. Virtual machine state, generated certificates, private keys, vendor source repositories, and other environment-specific deployment files are maintained separately from the portfolio repository.

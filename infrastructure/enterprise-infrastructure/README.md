# Enterprise Infrastructure

This directory contains infrastructure configuration files and supporting deployment artifacts for the enterprise infrastructure track.

---

## Active Deployments

Enterprise infrastructure workloads are hosted as virtual machines on the Windows 11 workstation using VMware Workstation Pro. Configuration files and deployment artifacts for those environments are managed directly on the virtualization host rather than stored here.

---

## Completed Labs Without Stored Configuration

Labs 04, 05, and 06 are complete. Because enterprise infrastructure workloads run as virtual machines on the Windows 11 workstation, configuration artifacts for those labs are managed directly on the virtualization host rather than stored here.

| Lab                                                                                                      | Description                                                 |
| -------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------- |
| [04 - Domain Client Lab](../../docs/enterprise-infrastructure/04-domain-client-lab.md)                   | Domain join configurations and client management artifacts  |
| [05 - Group Policy Lab](../../docs/enterprise-infrastructure/05-group-policy-lab.md)                     | Group Policy Object definitions and policy documentation    |
| [06 - Linux and AD Integration Lab](../../docs/enterprise-infrastructure/06-linux-ad-integration-lab.md) | SSSD and Kerberos configuration for Linux AD authentication |

---

## Active Lab Artifacts

The following lab currently stores deployment artifacts that support the accompanying documentation.

| Directory                  | Lab                                                                                                    | Description                                                                                                 |
| -------------------------- | ------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------- |
| `security-monitoring-lab/` | [07 - Security and Monitoring Lab](../../docs/enterprise-infrastructure/07-security-monitoring-lab.md) | Supporting deployment artifacts and configuration files related to the Wazuh security monitoring deployment |
|                            |                                                                                                        |                                                                                                             |

---

## Notes

Only configuration files and artifacts that provide educational or documentation value are stored in this repository. Virtual machine state, generated certificates, private keys, vendor source repositories, and other environment-specific deployment files are maintained separately from the portfolio repository.

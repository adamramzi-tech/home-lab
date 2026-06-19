# ADR-013: Exclude Wazuh Dashboard from NGINX Proxy Manager

## Status

Accepted

## Date

2026-06-19

---

## Related Decisions

Builds upon:

- [ADR-008: Centralize Ingress with NGINX Proxy Manager](008-centralize-ingress-with-nginx-proxy-manager.md)
- [ADR-009: Remove Direct LAN Exposure from Backend Services](009-remove-direct-lan-exposure-from-backend-services.md)

Related documentation:

- [07 - Security and Monitoring Lab](../../enterprise-infrastructure/07-security-monitoring-lab.md)
- [Topology Documentation](../topology.md)

---

# Context

The original design for Lab 07 called for exposing the Wazuh Dashboard through the existing NGINX Proxy Manager infrastructure used elsewhere in the environment.

Services successfully published through NPM prior to Lab 07 included:

- Grafana (`grafana.local`)
- Prometheus (`prometheus.local`)
- Portainer (`portainer.local`)
- NPM admin UI (`npm.local`)

The Wazuh deployment consisted of three containers running as a Docker Compose stack on the Ubuntu Server host:

- Wazuh Manager
- Wazuh Indexer
- Wazuh Dashboard

The planned access path was:

```text
Browser → wazuh.local → NPM → reverse-proxy-lab_proxy network → wazuh.dashboard:5601
```

with the dashboard accessible at `https://wazuh.local`.

This would have followed the same pattern used for Grafana, Prometheus, and Portainer, and was consistent with the architectural decision established in ADR-008 to centralize all web interface access through NPM.

---

# Problem

Direct access to the Wazuh Dashboard functioned correctly throughout deployment and validation:

```text
https://192.168.1.226:8443
```

The following components were verified as fully operational before NPM was introduced:

- Wazuh Manager container
- Wazuh Indexer (OpenSearch) container
- Wazuh Dashboard container
- Internal container networking between all three services
- Dashboard login using the `admin` account
- Dashboard-to-API connection (no errors in Server Management > API configuration)
- Agent enrollment for DC01, WIN11-CLIENT01, and Ubuntu Server
- Security event collection from all three agents

After attaching the dashboard container to the `reverse-proxy-lab_proxy` network and creating the NPM proxy host for `wazuh.local`, the dashboard began generating API authentication failures in the proxied request path.

Observed symptoms included:

- Error 3002 (dashboard unable to communicate with the Wazuh API)
- HTTP 429 responses (rate limiting on the API)
- Authorization token failures on proxied requests
- Excessive authentication requests against the Wazuh API visible in manager logs

Testing confirmed that the underlying components remained healthy:

- The Wazuh API was reachable from the dashboard container directly
- API credentials were valid
- JWT tokens could be generated successfully against the API
- Dashboard and manager containers could communicate over the internal stack network
- Direct IP access continued to function without errors throughout troubleshooting

The failure was specific to the proxied request path. Despite multiple troubleshooting attempts including custom NPM Advanced configuration (timeout headers, WebSocket headers, `proxy_ssl_verify off`, `proxy_buffering off`), the root cause of the interaction between the Wazuh Dashboard and the reverse proxy layer was not conclusively identified.

---

# Decision

The Wazuh Dashboard will be accessed directly through the host IP address and published dashboard port:

```text
https://192.168.1.226:8443
```

NGINX Proxy Manager is not part of the supported deployment path for Lab 07. The Wazuh Dashboard will remain outside the reverse proxy architecture until the proxy-related authentication behavior can be fully investigated in a separate effort.

This decision reflects that Wazuh's vendor-supported access method is direct HTTPS to the dashboard container's published port. Reverse proxy integration is an optional architectural addition, not a requirement for a functional deployment.

---

# Consequences

## Positive Outcomes

- Lab 07 objectives are completed without dependency on reverse proxy functionality
- Wazuh operates using a vendor-supported deployment model with no custom proxy layer
- Security monitoring functionality is fully operational
- The deployment is simpler to maintain and troubleshoot
- Future Wazuh upgrades are less likely to be affected by custom proxy configuration

## Tradeoffs

- The Wazuh Dashboard is accessed by IP and port rather than a friendly hostname
- The deployment is inconsistent with other web interfaces in the lab environment, which are published through NPM
- Reverse proxy integration remains unresolved and is not documented as a validated path

---

# Alternatives Considered

## Continue Troubleshooting NGINX Proxy Manager Integration

Rejected.

Multiple troubleshooting sessions failed to identify a conclusive root cause. The Wazuh Dashboard's internal API token negotiation sequence involves behaviors that interact poorly with certain reverse proxy configurations, and resolving this was unlikely to improve the educational value of the lab relative to the time cost involved.

## Install Wazuh Directly on the Ubuntu Server Host

Rejected.

The lab environment standardizes on Docker-based deployments where practical. A direct host installation would introduce architectural inconsistency without resolving the underlying reverse proxy issue, and would complicate future upgrades and stack management.

## Use an Alternative Reverse Proxy for Wazuh Only

Rejected.

Introducing a second reverse proxy solely to front the Wazuh Dashboard would increase architectural complexity without contributing to the learning objectives of the lab or resolving the root cause.

---

# Future Considerations

A future investigation may revisit reverse proxy integration for the Wazuh Dashboard using:

- a fresh Wazuh deployment with direct-access baseline validation completed first
- controlled proxy testing with API request tracing and manager log analysis
- investigation of Wazuh Dashboard's internal token negotiation behavior under proxied conditions
- evaluation of whether the issue is specific to NPM or present with other reverse proxy implementations

This investigation is outside the scope of Lab 07 and will be addressed as a separate effort if pursued.

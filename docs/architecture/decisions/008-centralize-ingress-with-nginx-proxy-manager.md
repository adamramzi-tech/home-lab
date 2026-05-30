# ADR-008: Centralize Ingress with NGINX Proxy Manager

## Status

Accepted

---

## Related Decisions

Builds upon:

- [ADR-005: Standardize on Containerized Service Deployment](005-standardize-on-containerized-service-deployment.md)
- [ADR-006: Use Custom Docker Bridge Networking](006-use-custom-docker-bridge-networking.md)

Related documentation:

- [Project README](../../../README.md) 
- [05 - Docker Networking Lab](../../linux-infrastructure/05-docker-networking-lab.md) 
- [06 - Monitoring Stack Lab](../../linux-infrastructure/06-monitoring-stack-lab.md) 
- [07 - Reverse Proxy Lab](../../linux-infrastructure/07-reverse-proxy-lab.md) 
- [Topology Documentation](../topology.md) 
- [Recovery and Rollback Strategy](../recovery-and-rollback.md)

---

# Context

As the homelab environment evolved, infrastructure services were initially exposed individually through direct LAN port mappings and standalone access URLs.

At the time, services such as:

- Grafana
- Prometheus
- Portainer

were accessed independently through:

- direct IP and port combinations
- separate service endpoints
- individually exposed container ports

While operationally functional, this model introduced several architectural limitations:

- fragmented infrastructure access
- inconsistent service exposure
- excessive direct LAN visibility
- growing port management complexity
- reduced service isolation
- limited ingress standardization

The environment had already standardized on:

- Docker-based infrastructure deployment
- custom Docker bridge networking
- remote-first administration
- browser-based management workflows
- containerized infrastructure services

As infrastructure services expanded, the environment required a more structured ingress architecture capable of:

- centralizing service access
- reducing unnecessary direct exposure
- simplifying infrastructure routing
- supporting hostname-based access
- improving operational organization
- reinforcing service segmentation boundaries

The reverse proxy project specifically explored:

- centralized ingress management
- reverse proxy routing
- Docker DNS service discovery
- hostname-based service access
- internal-only backend service architecture
- shared Docker networking
- layered infrastructure design

The project represented a transition from isolated container access patterns toward a more production-oriented infrastructure access model.

---

# Decision

The environment would centralize infrastructure ingress through a dedicated reverse proxy layer using NGINX Proxy Manager.

NGINX Proxy Manager (NPM) would function as:

- the centralized ingress platform
- the primary HTTP and HTTPS routing layer
- the hostname-based access gateway
- the externally reachable frontend for proxied infrastructure services

Infrastructure services would increasingly transition toward:

- internal-only Docker networking
- reverse proxy-mediated access
- hostname-based routing
- shared ingress networking

Backend infrastructure services would communicate internally through:

- shared Docker bridge networks
- Docker DNS service discovery
- reverse proxy forwarding workflows

NGINX Proxy Manager was selected because it provided:

- simplified reverse proxy administration
- browser-based management
- Docker compatibility
- hostname-based routing support
- lightweight operational overhead
- integration with existing infrastructure workflows

The ingress architecture prioritized:

- centralized access management
- layered infrastructure design
- reduced direct service exposure
- simplified operational routing
- infrastructure segmentation
- operational scalability
- maintainability

Infrastructure services would increasingly be accessed through hostnames such as:

- `grafana.local`
- `prometheus.local`
- `portainer.local`
- `npm.local`

rather than direct IP and port combinations.

The reverse proxy layer would also become foundational to future:

- HTTPS implementation
- ingress policy management
- internal service segmentation
- infrastructure expansion workflows

---

# Alternatives Considered

## Continue Using Direct Service Exposure

Advantages:

- simpler initial deployments
- fewer networking layers
- direct service accessibility
- easier early-stage troubleshooting

Reasons rejected:

- fragmented infrastructure access
- increasing port management complexity
- excessive direct service exposure
- weaker service segmentation
- inconsistent ingress architecture
- reduced scalability as infrastructure expanded

As the environment grew, individually exposed services became increasingly difficult to organize and manage cleanly.

---

## Use Raw NGINX Configuration Directly

Advantages:

- greater configuration flexibility
- deeper reverse proxy administration experience
- more granular NGINX control
- reduced dependency on management tooling

Reasons rejected initially:

- increased configuration complexity
- steeper operational learning curve
- slower deployment workflows
- reduced management simplicity
- greater troubleshooting overhead

The project prioritized learning ingress architecture and service segmentation concepts before introducing lower-level NGINX administration complexity.

NGINX Proxy Manager provided a more accessible operational layer while still preserving realistic reverse proxy workflows.

---

## Use Alternative Reverse Proxy Platforms

Alternatives considered conceptually included:

- Traefik
- Caddy
- HAProxy

Advantages:

- modern ingress tooling
- dynamic service discovery capabilities
- automated certificate management features
- alternative configuration models

Reasons rejected initially:

- NGINX Proxy Manager aligned better with current operational simplicity goals
- reduced onboarding complexity
- easier browser-based validation workflows
- simpler visualization of ingress relationships
- sufficient feature set for current infrastructure scope

The environment prioritized operational clarity and architectural understanding over advanced ingress automation features at this stage.

---

# Consequences

## Positive Outcomes

- centralized infrastructure ingress management
- reduced direct backend service exposure
- hostname-based infrastructure access
- improved service organization
- layered infrastructure architecture
- simplified operational routing workflows
- improved service segmentation
- cleaner infrastructure topology
- improved scalability for future infrastructure services
- operational familiarity with reverse proxy architecture concepts

The reverse proxy architecture established the ingress foundation for:

- internal-only backend services
- centralized service routing
- Docker DNS-based service discovery
- cross-stack Docker networking
- future HTTPS integration
- future infrastructure hardening workflows

The deployment also reinforced:

- layered architecture principles
- infrastructure segmentation concepts
- Docker networking familiarity
- ingress management workflows
- operational infrastructure design reasoning

The environment transitioned from:

- individually exposed infrastructure services

to:

- centralized ingress with internally segmented backend services

## This significantly improved infrastructure organization, maintainability, and architectural clarity.

## Tradeoffs

The environment accepts several tradeoffs:

- increased networking complexity
- dependency on the reverse proxy layer for service access
- additional Docker networking dependencies
- increased troubleshooting complexity involving ingress routing
- additional operational overhead
- dependency on centralized ingress availability
- additional configuration management requirements

The environment also became more dependent on:

- Docker DNS resolution
- reverse proxy configuration correctness
- shared network integrity
- hostname resolution workflows

Ingress centralization also introduces a partial single point of failure for proxied infrastructure services.

These tradeoffs were considered acceptable because the architectural and operational benefits significantly outweighed the added complexity for the current environment scale.

---

# Future Reassessment

This decision may later be revisited if:

- infrastructure scale increases significantly
- Kubernetes ingress controllers become relevant
- automated certificate management requirements expand
- advanced routing policies become necessary
- centralized authentication is introduced
- zero-trust access controls become operationally relevant
- external DNS integration expands

Potential future ingress evolution may include:

- Traefik
- Caddy
- Kubernetes ingress controllers
- automated TLS certificate management
- centralized authentication gateways
- SSO integration
- access policy enforcement
- advanced reverse proxy automation

For the current environment, NGINX Proxy Manager provides an effective balance between:

- ingress centralization
- operational simplicity
- infrastructure segmentation
- maintainability
- scalability
- accessibility
- practical infrastructure learning
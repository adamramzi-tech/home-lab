# ADR-009: Remove Direct LAN Exposure from Backend Services

## Status

Accepted

---

## Related Decisions

Builds upon:

- [ADR-006: Use Custom Docker Bridge Networking](006-use-custom-docker-bridge-networking.md)
- [ADR-008: Centralize Ingress with NGINX Proxy Manager](008-centralize-ingress-with-nginx-proxy-manager.md)

Related documentation:

- [Project README](../../../README.md) 
- [06 - Monitoring Stack Lab](../../linux-infrastructure/06-monitoring-stack-lab.md) 
- [07 - Reverse Proxy Lab](../../linux-infrastructure/07-reverse-proxy-lab.md) 
- [Topology Documentation](../topology.md) 
- [Recovery and Rollback Strategy](../recovery-and-rollback.md)

---

# Context

After the centralized ingress architecture using NGINX Proxy Manager was deployed, infrastructure services continued to operate with a partially transitional exposure model.

While services such as:

- Grafana
- Prometheus
- Portainer

were accessible through the reverse proxy layer, some services still retained direct LAN-accessible ports exposed through Docker port mappings.

This created an architectural inconsistency in which:

- centralized ingress existed
- but direct backend access paths still remained available

At this stage, the environment had already standardized on:

- Docker-based infrastructure deployment
- custom Docker bridge networking
- centralized reverse proxy ingress
- hostname-based service access
- Docker DNS service discovery

The infrastructure architecture increasingly prioritized:

- service segmentation
- layered infrastructure boundaries
- reduced attack surface
- centralized access management
- operational consistency
- internal-only backend service design

Maintaining direct LAN exposure for backend services introduced several architectural and operational concerns:

- inconsistent ingress enforcement
- unnecessary attack surface exposure
- fragmented service access paths
- reduced effectiveness of centralized routing
- weaker infrastructure segmentation boundaries

The reverse proxy architecture was intended to become:

- the primary ingress layer
- the centralized routing platform
- the externally reachable access boundary for infrastructure services

The environment therefore required a transition from:

- partially exposed backend services

to:

- internal-only backend infrastructure reachable exclusively through the reverse proxy layer

This refinement represented a significant hardening and segmentation milestone within the infrastructure architecture.

---

# Decision

Backend infrastructure services would transition to internal-only Docker networking and would no longer expose direct LAN-accessible ports unless operationally required.

Infrastructure services such as:

- Grafana
- Prometheus
- Portainer

would instead be accessed exclusively through:

- NGINX Proxy Manager
- hostname-based reverse proxy routing
- shared internal Docker bridge networks

Direct Docker port publishing for backend services would be removed where possible.

Backend services would communicate internally through:

- Docker bridge networking
- Docker DNS service discovery
- shared ingress networks

The reverse proxy layer would become:

- the centralized ingress enforcement point
- the primary externally reachable service boundary
- the standardized infrastructure access model

The architecture intentionally prioritized:

- internal-only backend services
- reduced direct exposure
- layered ingress design
- service segmentation
- operational consistency
- centralized routing workflows

The environment would increasingly follow a layered infrastructure model in which:

- backend services remain isolated internally
- ingress traffic flows through the reverse proxy layer
- service exposure is minimized intentionally

This established clearer infrastructure boundaries and reinforced the centralized ingress architecture introduced previously.

---

# Alternatives Considered

## Continue Allowing Direct LAN Access Alongside Reverse Proxy Access

Advantages:

- simpler troubleshooting workflows
- direct service accessibility
- easier early-stage administration
- reduced dependency on reverse proxy availability

Reasons rejected:

- inconsistent ingress architecture
- excessive service exposure
- fragmented access workflows
- weaker service segmentation
- increased attack surface
- reduced operational clarity

As infrastructure complexity increased, maintaining multiple access paths for backend services was considered increasingly undesirable.

---

## Expose All Services Individually Without Centralized Ingress

Advantages:

- simpler networking model
- fewer reverse proxy dependencies
- direct host-to-service communication
- reduced ingress configuration complexity

Reasons rejected:

- poor scalability
- fragmented infrastructure access
- inconsistent routing model
- excessive port exposure
- reduced maintainability
- weaker architectural organization

The environment had already transitioned toward centralized ingress as the preferred operational model.

---

## Implement Advanced Network Segmentation Immediately

Examples conceptually included:

- VLAN segmentation
- firewall-enforced container isolation
- zero-trust service architectures

Advantages:

- stronger network isolation
- deeper segmentation capabilities
- more advanced security controls
- enterprise-oriented exposure management

Reasons rejected initially:

- unnecessary operational complexity
- significantly larger networking overhead
- excessive complexity for current infrastructure scale
- existing Docker bridge segmentation already satisfied operational requirements

The environment prioritized incremental infrastructure hardening and layered architectural progression rather than immediate enterprise-grade segmentation complexity.

---

# Consequences

## Positive Outcomes

- reduced direct backend service exposure
- improved service isolation
- stronger centralized ingress enforcement
- cleaner infrastructure boundaries
- improved operational consistency
- reduced attack surface
- simplified infrastructure access patterns
- improved layered architecture design
- improved reverse proxy integration
- stronger separation between frontend ingress and backend services

The environment transitioned from:

- partially exposed infrastructure services

to:

- centralized ingress with internally segmented backend services

This refinement significantly improved:

- infrastructure organization
- ingress clarity
- service segmentation
- maintainability
- scalability
- architectural consistency

The architecture now more closely resembled:

- layered infrastructure environments
- production-style ingress models
- segmented backend service architectures

The decision also reinforced:

- Docker networking concepts
- internal-only service design
- ingress enforcement principles
- service exposure minimization
- centralized routing workflows

Direct service validation confirmed that backend services were no longer reachable through direct LAN ports after ingress centralization was fully enforced.

---

## Tradeoffs

The environment accepts several tradeoffs:

- increased dependency on the reverse proxy layer
- additional troubleshooting complexity
- reduced convenience for direct backend access
- increased Docker networking dependency
- centralized ingress becoming a partial single point of failure
- additional routing configuration requirements

The environment also became more dependent on:

- reverse proxy availability
- Docker DNS resolution
- shared network integrity
- hostname resolution workflows
- ingress configuration correctness

Troubleshooting backend services may now require:

- reverse proxy validation
- Docker network inspection
- internal connectivity testing

These tradeoffs were considered acceptable because the operational consistency and architectural benefits significantly outweighed the additional complexity.

---

# Future Reassessment

This decision may later be revisited if:

- advanced firewall segmentation is introduced
- Kubernetes ingress architectures become relevant
- zero-trust networking becomes a learning objective
- external access requirements expand
- centralized authentication layers are introduced
- service mesh architectures become operationally relevant
- advanced access control policies become necessary

Potential future evolution may include:

- VLAN-backed segmentation
- centralized authentication gateways
- identity-aware proxying
- service mesh architectures
- zero-trust access controls
- dedicated firewall policy enforcement
- HTTPS-only internal service exposure

For the current environment, centralized ingress with internal-only backend services provides an effective balance between:

- security
- operational simplicity
- maintainability
- segmentation
- scalability
- infrastructure clarity
- practical infrastructure learning

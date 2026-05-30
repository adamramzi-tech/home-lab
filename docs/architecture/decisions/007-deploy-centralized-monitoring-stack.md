# ADR-007: Deploy Centralized Monitoring Stack

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
- [Recovery and Rollback Strategy](../recovery-and-rollback.md) 
- [Topology Documentation](../topology.md)

---

# Context

As the homelab environment expanded beyond basic container deployments, operational visibility into infrastructure health and service behavior became increasingly important.

The environment already included:

- a dedicated Ubuntu Server infrastructure host
- Docker-based infrastructure deployment
- custom Docker bridge networking
- remote-first administration workflows
- multiple containerized infrastructure services

As infrastructure complexity increased, the environment required improved visibility into:

- host system performance
- containerized service health
- infrastructure resource utilization
- operational stability
- long-running workload behavior

The project also prioritized:

- practical infrastructure administration experience
- operational familiarity
- troubleshooting workflows
- infrastructure observability concepts
- realistic operational tooling exposure

At this stage of the environment, most infrastructure management remained reactive and manually validated through:

- SSH sessions
- command-line inspection
- Docker CLI output
- browser-based service testing

While functional, this approach lacked:

- centralized telemetry
- historical metrics visibility
- persistent infrastructure monitoring
- consolidated operational dashboards
- scalable observability workflows

The environment required a monitoring architecture capable of:

- collecting infrastructure metrics
- visualizing operational data
- centralizing observability workflows
- supporting future infrastructure expansion
- integrating naturally into the existing Docker-based deployment model

The monitoring stack also needed to remain:

- lightweight
- modular
- reproducible
- remotely accessible
- compatible with future hybrid infrastructure expansion

The monitoring lab introduced:

- Prometheus
- Grafana
- Node Exporter
- persistent metrics storage
- infrastructure telemetry collection
- centralized dashboard visualization

This marked the beginning of infrastructure observability within the environment.

---

# Decision

The environment would adopt a centralized monitoring architecture using:

- Prometheus
- Grafana
- Node Exporter

deployed through Docker Compose.

The monitoring stack would operate as the primary infrastructure observability platform for:

- Linux host metrics
- containerized infrastructure monitoring
- resource utilization visibility
- operational dashboarding
- future cross-platform telemetry collection

The deployment model would utilize:

- containerized monitoring services
- persistent storage volumes
- Docker bridge networking
- centralized browser-based dashboards
- internal service communication through Docker networking

Prometheus would function as:

- the metrics collection platform
- the time-series metrics database
- the infrastructure telemetry ingestion layer

Node Exporter would function as:

- the Linux host metrics collector
- the operating system telemetry agent

Grafana would function as:

- the centralized dashboard and visualization platform
- the operational observability interface
- the primary infrastructure monitoring frontend

The monitoring architecture prioritized:

- centralized observability
- persistent telemetry visibility
- lightweight deployment
- operational familiarity
- future infrastructure scalability
- integration with future hybrid infrastructure systems

The stack would remain integrated into the broader Docker infrastructure architecture alongside:

- reverse proxy services
- internal Docker networking
- centralized ingress workflows
- future cross-platform integrations

---

# Alternatives Considered

## Continue Using Manual CLI-Based Monitoring

Advantages:

- minimal infrastructure overhead
- no additional services required
- simpler deployment model
- direct operating system visibility

Reasons rejected:

- no centralized telemetry visibility
- no historical metrics retention
- limited operational scalability
- fragmented troubleshooting workflows
- lack of dashboard-based infrastructure visibility
- poor long-term observability

As infrastructure complexity increased, manual validation workflows alone became increasingly insufficient.

---

## Use Lightweight Single-Purpose Monitoring Utilities Only

Advantages:

- reduced deployment complexity
- smaller resource footprint
- simpler operational model
- easier early-stage troubleshooting

Reasons rejected:

- fragmented observability workflows
- no centralized visualization layer
- limited scalability
- reduced operational realism
- lack of integrated metrics pipelines
- weaker exposure to modern observability architecture concepts

The environment prioritized learning modern infrastructure observability workflows rather than isolated utility-based monitoring alone.

---

## Use Enterprise Monitoring Platforms Immediately

Examples considered conceptually included:

- Zabbix
- ELK stack components
- enterprise SIEM platforms
- advanced observability suites

Advantages:

- enterprise-grade monitoring features
- advanced alerting and analytics
- centralized logging capabilities
- large-scale infrastructure visibility

Reasons rejected initially:

- significantly higher operational complexity
- larger infrastructure overhead
- steeper learning curve
- unnecessary complexity for the current environment scale
- observability fundamentals had not yet been established

The project prioritized foundational metrics and observability familiarity before introducing larger-scale monitoring ecosystems.

---

# Consequences

## Positive Outcomes

- centralized infrastructure observability
- persistent infrastructure telemetry collection
- browser-based operational dashboards
- improved visibility into system resource utilization
- improved troubleshooting workflows
- operational familiarity with monitoring architectures
- foundational exposure to Prometheus-based observability ecosystems
- scalable metrics collection workflows
- improved operational awareness of infrastructure behavior
- cleaner separation between infrastructure services and observability tooling

The monitoring stack established the observability foundation for:

- Docker infrastructure monitoring
- reverse proxy integration
- future hybrid infrastructure telemetry
- Windows metrics integration planning
- future security monitoring expansion
- centralized infrastructure visibility

The deployment also reinforced:

- containerized infrastructure workflows
- Docker networking concepts
- persistent storage strategies
- internal service communication
- infrastructure dashboard design

The monitoring environment later integrated naturally into the centralized ingress architecture through reverse proxy networking and hostname-based access workflows.

---

## Tradeoffs

The environment accepts several tradeoffs:

- additional infrastructure resource consumption
- increased deployment complexity
- persistent storage management requirements
- additional Docker networking complexity
- increased operational overhead
- dependency on monitoring stack availability for centralized observability
- additional troubleshooting surface area

The environment also became more dependent on:

- metrics pipeline integrity
- Prometheus configuration correctness
- exporter availability
- persistent metrics storage reliability

The monitoring stack itself now also requires:

- maintenance
- updates
- configuration management
- observability validation

These tradeoffs were considered acceptable because the operational visibility and infrastructure observability benefits significantly outweighed the added complexity.

---

# Future Reassessment

This decision may later be revisited if:

- infrastructure scale increases significantly
- centralized logging becomes operationally necessary
- SIEM tooling is introduced
- alerting and notification systems expand
- distributed infrastructure monitoring becomes necessary
- Kubernetes observability tooling becomes relevant
- enterprise telemetry pipelines are introduced

Potential future observability evolution may include:

- Alertmanager
- Loki
- Promtail
- Wazuh
- Windows Exporter integration
- centralized logging pipelines
- SIEM integration
- distributed metrics aggregation
- hybrid infrastructure dashboards

For the current environment, the Prometheus and Grafana monitoring stack provides an effective balance between:

- observability
- operational simplicity
- scalability
- maintainability
- infrastructure visibility
- practical infrastructure learning

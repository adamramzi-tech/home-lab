# Docker Networking Lab

## Overview

This lab introduced foundational Docker networking concepts using Docker Compose, custom bridge networks, internal service communication, and reverse proxy architecture.

The environment consisted of:
- an NGINX frontend container
- an internal backend service container
- a custom Docker bridge network
- internal DNS-based service discovery

The objective was to understand how containers communicate securely within isolated Docker networks while selectively exposing only public-facing services to the local network.

---

## Objectives

The primary goals of this lab were to:
- understand Docker bridge networking
- create isolated container networks using Docker Compose
- validate container-to-container communication
- demonstrate Docker internal DNS resolution
- implement a reverse proxy architecture using NGINX
- maintain backend service isolation from the LAN
- gain familiarity with Docker troubleshooting workflows

---

## Technologies Used

- Docker Engine
- Docker Compose
- NGINX
- hashicorp/http-echo
- Alpine Linux
- Ubuntu Server 26.04 LTS

---

## Core Technologies

### Docker Bridge Networking

Docker bridge networks provide isolated virtual networks that allow containers to communicate securely with one another.

In this project, the custom bridge network:
- enabled internal container communication
- isolated application traffic from unrelated containers
- provided automatic internal DNS resolution
- allowed services to communicate by container name rather than IP address

Docker Compose automatically provisioned the bridge network during deployment.

---

### NGINX

NGINX is a high-performance web server and reverse proxy commonly used for frontend traffic management and load balancing.

In this project, NGINX:
- served as the frontend application layer
- accepted inbound HTTP traffic on port 8080
- proxied requests to the backend container
- demonstrated reverse proxy functionality inside a containerized environment

The NGINX container communicated with the backend container entirely through the internal Docker network.

---

### HashiCorp HTTP Echo

HashiCorp HTTP Echo is a lightweight HTTP testing container used for validating networking and application routing behavior.

In this project, the backend container:
- responded to HTTP requests with static text
- acted as the application backend service
- validated successful reverse proxy forwarding
- demonstrated container-to-container communication

The container listened internally on port 5678 and was accessible to the frontend container through Docker networking.

---

### Docker Compose

Docker Compose is a container orchestration tool used to define and manage multi-container Docker applications using declarative YAML configuration files.

In this project, Docker Compose:
- deployed the frontend and backend containers
- provisioned the custom bridge network
- managed service configuration
- simplified multi-container orchestration
- enabled repeatable infrastructure deployment

---

## Network Architecture

The Docker networking lab implemented a multi-container application architecture using Docker Compose bridge networking.

The environment consisted of:
- an NGINX frontend container
- a backend application container
- a shared Docker bridge network for internal communication

The deployment demonstrated:
- container-to-container communication
- Docker bridge networking
- internal DNS-based service discovery
- reverse proxy forwarding
- service isolation through custom networks

Application flow:

```text
Client Browser
      ↓
NGINX Frontend Container
      ↓
Docker Bridge Network
      ↓
Backend Application Container
```

In this deployment:
- NGINX acted as the frontend reverse proxy
- the backend container served application responses
- Docker Compose created and managed the internal bridge network
- containers communicated internally using Docker DNS service discovery


## Project Directory Creation

A dedicated infrastructure directory structure was created to organize Docker networking labs and future containerized services.

Commands used:

```bash
mkdir -p ~/infrastructure/docker-networking
cd ~/infrastructure/docker-networking
```

<p align="center">
  <img src="../images/linux-infrastructure/docker-networking/01-making-project-directories.jpeg" width="700">
</p>

<p align="center">
  <em>Creating the infrastructure project directory for the Docker networking lab.</em>
</p>

---

## Creating the Docker Compose Configuration

A Docker Compose stack was created containing:
- a frontend NGINX container
- a backend HTTP echo service
- a custom user-defined bridge network

Initial compose configuration:

```yaml
services:
  frontend:
    image: nginx:latest
    container_name: frontend
    ports:
      - "8080:80"
    networks:
      - lab-network

  backend:
    image: hashicorp/http-echo
    container_name: backend
    command: ["-text=Backend container responding"]
    networks:
      - lab-network

networks:
  lab-network:
    driver: bridge
```

<p align="center">
  <img src="../images/linux-infrastructure/docker-networking/02-creating-docker-compose-file.jpeg" width="700">
</p>

<p align="center">
  <em>Initial Docker Compose configuration defining frontend and backend services attached to a custom bridge network.</em>
</p>

---

## Deploying the Docker Compose Stack

The stack was deployed using Docker Compose.

Command used:

```bash
docker compose up -d
```

<p align="center">
  <img src="../images/linux-infrastructure/docker-networking/03-running-docker-compose-stack.jpeg" width="700">
</p>

<p align="center">
  <em>Deployment of the Docker Compose stack including the custom bridge network and application containers.</em>
</p>

After deployment:
- Docker automatically created the custom bridge network
- both containers were attached to the same isolated subnet
- only the frontend container exposed a host-accessible port

---

## Inspecting Running Containers and Docker Networks

Running containers and available Docker networks were inspected to validate deployment status and network creation.

Commands used:

```bash
docker ps
docker network ls
```

<p align="center">
  <img src="../images/linux-infrastructure/docker-networking/04-inspecting-running-containers-and-networks.jpeg" width="800">
</p>

<p align="center">
  <em>Validation of active containers and Docker network types including the custom bridge network.</em>
</p>

This demonstrated several important Docker networking concepts:
- published host ports
- isolated bridge networks
- internal-only services
- automatic project-based network naming

---

## Inspecting the Custom Docker Network

The custom Docker bridge network was inspected to analyze:
- subnet assignment
- gateway configuration
- attached containers
- internal IP addressing

Command used:

```bash
docker network inspect docker-networking_lab-network
```

<p align="center">
  <img src="../images/linux-infrastructure/docker-networking/05-inspecting-custom-docker-network.jpeg" width="700">
</p>

<p align="center">
  <em>Detailed inspection of the custom Docker bridge network including internal IP allocation and attached containers.</em>
</p>

Key observations:
- Docker automatically assigned the `172.18.0.0/16` subnet
- containers received internal IP addresses
- the frontend and backend containers were attached to the same isolated bridge network
- Docker automatically configured internal routing and DNS resolution

---

## Testing Container Shell Access

An interactive shell session was opened inside the frontend container to begin testing internal connectivity.

Command used:

```bash
docker exec -it frontend sh
```

<p align="center">
  <img src="../images/linux-infrastructure/docker-networking/06-testing-container-shell-access.jpeg" width="700">
</p>

<p align="center">
  <em>Accessing the frontend container shell for internal network testing and troubleshooting.</em>
</p>

This demonstrated the distinction between:
- the host operating system shell
- containerized runtime environments
- internal Docker networking boundaries

---

## Attempting Internal Service Requests

An attempt was made to test connectivity between containers from within the frontend container.

Commands attempted:

```bash
wget -qO- http://backend:5678
ping backend
```

<p align="center">
  <img src="../images/linux-infrastructure/docker-networking/07-attempting-internal-service-request.jpeg" width="700">
</p>

<p align="center">
  <em>Attempting internal service communication from the frontend container using Docker DNS resolution.</em>
</p>

This highlighted an important operational concept:
- minimal container images often exclude troubleshooting utilities such as `ping`, `wget`, and `curl`

---

## Backend Port Conflict Validation

An attempt to manually start an additional backend process generated a port binding conflict.

Command used:

```bash
docker exec backend /http-echo -text="test"
```

<p align="center">
  <img src="../images/linux-infrastructure/docker-networking/08-backend-port-already-in-use-error.jpeg" width="700">
</p>

<p align="center">
  <em>Port binding conflict encountered while attempting to manually start an additional backend process.</em>
</p>

The error confirmed:
- the backend service was already active
- port `5678` was currently bound by the running backend container process

---

## Launching a Temporary Debug Container

A temporary Alpine Linux container was launched on the same Docker bridge network to perform internal connectivity testing.

Command used:

```bash
docker run --rm -it --network docker-networking_lab-network alpine sh
```

<p align="center">
  <img src="../images/linux-infrastructure/docker-networking/09-launching-temporary-alpine-debug-container.jpeg" width="700">
</p>

<p align="center">
  <em>Launching a temporary Alpine Linux troubleshooting container attached to the custom bridge network.</em>
</p>

This demonstrated a common real-world troubleshooting workflow used in containerized environments.

---

## Testing Container-to-Container Connectivity

The temporary Alpine container was used to validate internal Docker DNS resolution and service communication.

Commands used:

```bash
apk add curl
curl http://backend:5678
```

<p align="center">
  <img src="../images/linux-infrastructure/docker-networking/10-testing-container-to-container-connectivity.jpeg" width="700">
</p>

<p align="center">
  <em>Successful internal communication between containers using Docker DNS service discovery.</em>
</p>

This validated:
- internal bridge network communication
- automatic Docker DNS resolution
- service discovery using container names
- backend isolation from external networks

---

## Creating the NGINX Reverse Proxy Configuration

An NGINX reverse proxy configuration was created to forward incoming requests from the frontend container to the internal backend service.

Commands used:

```bash
mkdir nginx
nano nginx/default.conf
```

NGINX configuration:

```nginx
server {
    listen 80;

    location / {
        proxy_pass http://backend:5678;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

<p align="center">
  <img src="../images/linux-infrastructure/docker-networking/11-creating-nginx-reverse-proxy-config.jpeg" width="700">
</p>

<p align="center">
  <em>Creating the NGINX reverse proxy configuration to route traffic to the internal backend service.</em>
</p>

---

## Updating Docker Compose for Reverse Proxy Integration

The Docker Compose configuration was updated to mount the custom NGINX configuration into the frontend container.

Updated frontend configuration:

```yaml
frontend:
  image: nginx:latest
  container_name: frontend
  ports:
    - "8080:80"
  volumes:
    - ./nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
  networks:
    - lab-network
```

<p align="center">
  <img src="../images/linux-infrastructure/docker-networking/12-updating-docker-compose-for-reverse-proxy.jpeg" width="700">
</p>

<p align="center">
  <em>Updated Docker Compose configuration integrating the custom NGINX reverse proxy configuration.</em>
</p>

---

## Deploying the Reverse Proxy Stack

The updated stack was redeployed to apply the reverse proxy configuration.

Commands used:

```bash
docker compose down
docker compose up -d
docker compose config
```

<p align="center">
  <img src="../images/linux-infrastructure/docker-networking/13-successful-reverse-proxy-deployment.jpeg" width="700">
</p>

<p align="center">
  <em>Successful deployment and validation of the updated reverse proxy container stack.</em>
</p>

The `docker compose config` output also validated:
- YAML formatting
- bind mount configuration
- generated network naming
- normalized Compose configuration structure

---

## Final Reverse Proxy Validation

The final deployment was tested through a web browser using the host server IP address.

Tested URL:

```text
http://192.168.1.226:8080
```

<p align="center">
  <img src="../images/linux-infrastructure/docker-networking/14-final-browser-test-through-nginx.jpeg" width="650">
</p>

<p align="center">
  <em>Final browser validation confirming successful reverse proxy routing to the internal backend container.</em>
</p>

This confirmed the complete request flow:

```text
Client Browser
      ↓
Host Port 8080
      ↓
NGINX Reverse Proxy Container
      ↓
Docker Internal DNS
      ↓
backend:5678
      ↓
Backend Service Container
```

---

# Architecture Summary

The final architecture demonstrated:
- public-facing reverse proxy design
- isolated backend service architecture
- Docker internal DNS resolution
- container-to-container networking
- secure internal service communication

Only the frontend container was externally accessible.

The backend service remained isolated within the internal Docker bridge network and was not directly exposed to the local network.

---

# Security Considerations

The backend service was intentionally isolated from the local network and exposed only through the NGINX reverse proxy container.

This design reduced direct attack surface exposure while maintaining internal service communication through the Docker bridge network.

---

# Outcome

At completion:
- Docker Compose networking was successfully deployed
- custom bridge networking was operational
- container-to-container communication was validated
- Docker DNS service discovery was demonstrated
- reverse proxy routing was functional
- backend service isolation was maintained
- internal traffic flow concepts were successfully validated

The Docker networking and reverse proxy concepts demonstrated in this lab later became foundational to the centralized ingress architecture implemented in the [Reverse Proxy Lab](reverse-proxy-lab.md).

---

# Lessons Learned

Key takeaways included:
- Docker bridge networking concepts
- container isolation and segmentation
- Docker Compose project networking behavior
- reverse proxy architecture fundamentals
- internal DNS-based service discovery
- port publishing and host/container port separation
- troubleshooting minimal container environments
- temporary debugging container workflows
- YAML validation and Compose troubleshooting
- internal-only service security design
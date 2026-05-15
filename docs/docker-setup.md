# Docker Setup

## Overview

After establishing stable remote administration through SSH and Tailscale, the next major step in the home lab deployment was containerization using Docker.

Docker was installed to provide:
- Isolated application environments
- Simplified service deployment
- Easier infrastructure management
- Reproducible configurations
- Reduced dependency conflicts
- Scalable self-hosted service deployment

Portainer was later deployed as a web-based Docker management interface to simplify container administration and visualization.

The entire Docker installation and configuration process was performed remotely through SSH using PowerShell on the Windows 11 workstation.

## Goals

- Learn containerization fundamentals
- Deploy Docker Engine manually
- Understand Linux package repositories
- Validate Docker functionality
- Deploy a web-based container management platform
- Establish a scalable self-hosting foundation
- Prepare infrastructure for future services and stacks

## Updating the System

Before installing Docker, the Ubuntu Server system was fully updated using APT.

Commands used:

```bash
sudo apt update && sudo apt upgrade -y
```

This ensured:
- Current package indexes
- Updated system packages
- Improved compatibility
- Latest security patches

![System Update Process](images/docker/system-update.jpeg)

## Installing Fastfetch

An attempt was initially made to install Neofetch for system information display, but the package was unavailable in the repository configuration being used.

```bash
sudo apt install neofetch -y
```

Because of this, Fastfetch was installed instead.

```bash
sudo apt install fastfetch -y
```

Fastfetch provided:
- System hardware summaries
- Operating system information
- Resource visibility
- Cleaner terminal presentation

This also introduced package troubleshooting and repository awareness during the Linux learning process.

![Fastfetch Installation](images/docker/fastfetch-install.jpeg)

## Preparing Docker Repository Dependencies

Before adding Docker's official repository, several required packages were installed.

Commands used:

```bash
sudo apt install ca-certificates curl gnupg -y
```

These packages enabled:
- Secure HTTPS repository communication
- GPG key management
- Package verification
- Secure repository authentication

## Adding Docker's Official GPG Key

Docker's official repository signing key was then downloaded and configured.

Commands used:

```bash
sudo install -m 0755 -d /etc/apt/keyrings
```

```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
```

```bash
sudo chmod a+r /etc/apt/keyrings/docker.gpg
```

This allowed Ubuntu to securely verify Docker packages from Docker's official repository.

## Adding Docker Repository

Docker's repository was then added to the system's APT sources list.

Command used:

```bash
echo \
"deb [arch=$(dpkg --print-architecture) \
signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

After adding the repository, package indexes were refreshed:

```bash
sudo apt update
```

This configured the server to pull Docker packages directly from Docker's official repositories rather than Ubuntu's default repositories.

![Docker Repository Setup](images/docker/docker-repository-setup.jpeg)

## Installing Docker Engine

Docker Engine and related components were then installed.

Command used:

```bash
sudo apt install docker-ce docker-ce-cli containerd.io \
docker-buildx-plugin docker-compose-plugin -y
```

Installed components included:
- Docker Engine
- Docker CLI
- Containerd runtime
- Docker Buildx
- Docker Compose Plugin

This established the complete Docker runtime environment on the Ubuntu Server system.

![Docker Engine Installation](images/docker/docker-installation.jpeg)

## Verifying Docker Installation

After installation completed, Docker functionality was verified.

Docker version check:

```bash
docker --version
```

Test container execution:

```bash
sudo docker run hello-world
```

The successful "Hello from Docker!" output confirmed:
- Docker daemon functionality
- Internet connectivity
- Image pulling capability
- Container execution capability
- Functional Docker runtime installation

![Docker Hello World Verification](images/docker/docker-hello-world.jpeg)

## Why Docker Was Important

Docker fundamentally changed how services could be deployed within the home lab.

Instead of:
- Manually configuring applications directly on the host operating system
- Managing conflicting dependencies
- Risking host system instability

Services could now run inside isolated containers with:
- Independent environments
- Simplified deployment
- Easier troubleshooting
- Better portability
- Cleaner infrastructure management

Docker effectively became the foundation for future self-hosted services.

## Deploying Portainer

After Docker was functioning properly, Portainer Community Edition was deployed.

Portainer provided:
- Web-based Docker management
- Container visualization
- Volume management
- Network management
- Stack deployment
- Easier administration for future services

## Creating Portainer Volume

A persistent Docker volume was created to store Portainer data.

Command used:

```bash
sudo docker volume create portainer_data
```

This ensured Portainer configuration data would persist across:
- Container restarts
- Reboots
- Image updates

## Running the Portainer Container

The Portainer container was deployed using the following command:

```bash
sudo docker run -d \
-p 8000:8000 \
-p 9443:9443 \
--name portainer \
--restart=unless-stopped \
-v /var/run/docker.sock:/var/run/docker.sock \
-v portainer_data:/data \
portainer/portainer-ce:lts
```

Key configuration details:
- Port 9443 used for secure HTTPS web access
- Docker socket mounted for Docker management access
- Persistent volume mounted for configuration storage
- Automatic restart policy enabled

![Portainer Deployment](images/docker/portainer-deployment.jpeg)

## Accessing Portainer

After deployment, Portainer became accessible through the browser using:

```text
https://server-ip:9443
```

Example:

```text
https://192.168.x.x:9443
```

Initial setup included:
- Administrator account creation
- Local Docker environment selection
- Environment initialization

Once configured, Portainer successfully connected to the local Docker environment.

## Portainer Dashboard

The Portainer dashboard provided centralized visibility into:
- Containers
- Images
- Volumes
- Resource usage
- Docker environments

This became the primary graphical management interface for the server's container infrastructure.

The dashboard displayed:
- Active Docker containers
- Docker Engine version
- System resource availability
- Storage usage
- Networking information

![Portainer Dashboard](images/docker/portainer-dashboard.png)

## Docker Architecture Concepts Learned

During this process, several important Docker concepts were introduced:

### Images

Read-only templates used to create containers.

Examples:
- `hello-world`
- `ubuntu`
- `portainer/portainer-ce`

### Containers

Running instances of Docker images.

Containers provide:
- Isolation
- Portability
- Process encapsulation

### Volumes

Persistent storage locations outside container lifecycle management.

Volumes prevent data loss during:
- Container recreation
- Updates
- Restarts

### Container Networking

Docker automatically creates internal networking for communication between containers and external services.

### Docker Daemon

The background service responsible for:
- Pulling images
- Running containers
- Managing networking
- Managing storage

## Security Considerations

Current Docker deployment uses:
- Official Docker repositories
- HTTPS-secured Portainer access
- Persistent container storage
- Controlled local network access

Future improvements may include:
- Reverse proxy integration
- SSL certificate management
- Container segmentation
- Non-root Docker administration
- Firewall hardening
- Access control improvements

## Lessons Learned

- Docker installation is heavily repository and dependency driven
- Linux package management becomes much more important when deploying infrastructure software
- Containerization dramatically simplifies service deployment
- Docker images make application deployment highly reproducible
- Portainer significantly improves visibility and management usability
- Persistent volumes are essential for stateful applications
- The Docker ecosystem introduces many new infrastructure concepts quickly
- Containerization forms the foundation for modern self-hosting environments
- Remote SSH administration integrates naturally with Docker workflows
- Small successful deployments compound confidence for larger infrastructure projects

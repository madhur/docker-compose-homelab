# Homelab Docker Compose Services

This repository contains Docker Compose configurations for various self-hosted services in my homelab environment. All services are configured to work together with Traefik as a reverse proxy and are accessible through custom domains with SSL certificates.

## Architecture Overview

![Homelab Architecture](https://raw.githubusercontent.com/madhur/docker-compose-homelab/master/homelab-architecture.drawio.png)

- **Reverse Proxy**: Traefik with Let's Encrypt SSL certificates
- **Network**: External `proxy-network` for service communication
- **Authentication**: Authelia — forward-auth via Traefik for internet-facing services
- **Database**: PostgreSQL 18 running on host machine (local.madhur.co.in:5432, also reachable via `host.docker.internal:host-gateway` from containers)
- **Monitoring**: Gatus, host Grafana, cAdvisor, Change Detection, Dockpeek for observability
- **Notifications**: Ntfy for push notifications
- **Storage**: Host PostgreSQL and Redis, plus per-service persistent volumes

## Services

### Core Infrastructure
- **[Traefik](traefik/)** - Reverse proxy with automatic SSL certificates | [GitHub](https://github.com/traefik/traefik)
- **[Authelia](authelia/)** - Forward-auth identity provider | [GitHub](https://github.com/authelia/authelia)
- **[Gatus](gatus/)** - Declarative service health monitoring | [GitHub](https://github.com/TwiN/gatus)

### Knowledge Management & Documentation
- **[Bookstack](bookstack/)** - Simple, self-hosted wiki platform | [GitHub](https://github.com/BookStackApp/BookStack)
- **[Outline](outline/)** - Team knowledge base | [GitHub](https://github.com/outline/outline)
- **[Linkwarden](linkwarden/)** - Self-hosted bookmark manager with archive capabilities | [GitHub](https://github.com/linkwarden/linkwarden)
- **[Planka](planka/)** - Kanban board for collaborative task management | [GitHub](https://github.com/plankanban/planka)
- **[RedNotebook](rednotebook/)** - Daily journal | [GitHub](https://github.com/jendrikseipp/rednotebook)
- **[TriliumNext](trilium/)** - Hierarchical note-taking app | [GitHub](https://github.com/TriliumNext/Notes)
- **[Joplin Server](joplin/)** - Sync server for Joplin notes clients | [GitHub](https://github.com/laurent22/joplin)

### Media & Content Management
- **[Immich](immich/)** - Self-hosted photo and video backup solution | [GitHub](https://github.com/immich-app/immich)
- **[Jellyfin](jellyfin/)** - Media server for movies, TV shows, and music | [GitHub](https://github.com/jellyfin/jellyfin)
- **[Navidrome](navidrome/)** - Self-hosted music streaming server | [GitHub](https://github.com/navidrome/navidrome)
- **[Nextcloud](nextcloud/)** - Self-hosted cloud storage and collaboration | [GitHub](https://github.com/nextcloud/server)
- **[Paperless-ngx](paperless/)** - Document management system | [GitHub](https://github.com/paperless-ngx/paperless-ngx)
- **[qui](qbittorrent/)** - Fast qBittorrent web UI, replaces qBittorrent's own UI at the same domain | [GitHub](https://github.com/autobrr/qui)

### Finance
- **[Firefly III](firefly/)** - Personal finance manager | [GitHub](https://github.com/firefly-iii/firefly-iii)
- **[InvoiceShelf](invoiceshelf/)** - Invoice management | [GitHub](https://github.com/InvoiceShelf/InvoiceShelf)
- **[Wealthfolio](wealthfolio/)** - Privacy-first investment portfolio tracker | [GitHub](https://github.com/wealthfolio/wealthfolio)
- **[Ghostfolio](ghostfolio/)** - Wealth and portfolio tracker | [GitHub](https://github.com/ghostfolio/ghostfolio)

### Security & Authentication
- **[Authelia](authelia/)** - Forward-auth identity provider | [GitHub](https://github.com/authelia/authelia)
- **[Vaultwarden](vaultwarden/)** - Self-hosted Bitwarden password manager | [GitHub](https://github.com/dani-garcia/vaultwarden)

### Development & DevOps
- **[Code Server](code-server/)** - VS Code in the browser | [GitHub](https://github.com/coder/code-server)
- **[n8n](n8n/)** - Workflow automation platform | [GitHub](https://github.com/n8n-io/n8n)
- **[Prefect](prefect/)** - Workflow orchestration platform | [GitHub](https://github.com/PrefectHQ/prefect)
- **[Temporal](temporal/)** - Workflow orchestration platform | [GitHub](https://github.com/temporalio/temporal)
- **[Bento](bento/)** - Stream processor for data pipelines | [GitHub](https://github.com/warpstreamlabs/bento)
- **[Termix](termix/)** - Web-based SSH terminal | [GitHub](https://github.com/LukeGus/Termix)
- **[Request Baskets](request-baskets/)** - HTTP request inspector | [GitHub](https://github.com/darklynx/request-baskets)
- **[Dockhand](dockhand/)** - Docker management UI
- **[AKHQ](akhq/)** - Kafka UI | [GitHub](https://github.com/tchiotludo/akhq)

### Monitoring & Analytics
- **[cAdvisor](cadvisor/)** - Container resource monitoring | [GitHub](https://github.com/google/cadvisor)
- **[Change Detection](changedetection/)** - Website change monitoring | [GitHub](https://github.com/dgtlmoon/changedetection.io)
- **[Dockpeek](dockpeek/)** - Docker container monitoring and management | [GitHub](https://github.com/louislam/dockpeek)
- **[Gatus](gatus/)** - Declarative service health monitoring | [GitHub](https://github.com/TwiN/gatus)
- **[Mailpit](mailpit/)** - Local SMTP sink + web UI for homelab alert emails (auto-pruning) | [GitHub](https://github.com/axllent/mailpit)

### Location & Tracking
- **[Dawarich](dawarich/)** - Self-hosted location history | [GitHub](https://github.com/Freika/dawarich)

### Utilities & Tools
- **[ConvertX](convertx/)** - File format converter | [GitHub](https://github.com/C4illin/ConvertX)
- **[Glance](glance/)** - Self-hosted dashboard | [GitHub](https://github.com/glanceapp/glance)
- **[Homepage](homepage/)** - Application dashboard | [GitHub](https://github.com/gethomepage/homepage)
- **[Homebox](homebox/)** - Home inventory management | [GitHub](https://github.com/sysadminsmedia/homebox)
- **[IT Tools](it-tools/)** - Collection of handy developer tools | [GitHub](https://github.com/CorentinTh/it-tools)
- **[Networking Toolbox](networkingtoolbox/)** - Network diagnostic and testing tools
- **[Ntfy](ntfy/)** - Push notifications service | [GitHub](https://github.com/binwiederhier/ntfy)
- **[OliveTin](olivetin/)** - Web UI for running shell commands | [GitHub](https://github.com/OliveTin/OliveTin)
- **[OpenGist](opengist/)** - Self-hosted pastebin powered by Git | [GitHub](https://github.com/thomiceli/opengist)
- **[Dozzle](dozzle/)** - Docker container log viewer | [GitHub](https://github.com/amir20/dozzle)
- **[SFTPGo](sftpgo/)** - Self-hosted SFTP/file transfer server | [GitHub](https://github.com/drakkan/sftpgo)
- **[Idle Status](idle-status/)** - Internal-only status widget feeding Glance/Homepage dashboards (no public domain)

### Health & Fitness
- **[SparkyFitness](sparkyfitness/)** - Fitness and nutrition tracker | [GitHub](https://github.com/CodeWithCJ/SparkyFitness)

### Home Automation
- **[Home Assistant](homeassistant/)** - Home automation platform (dockerized, host network, LAN-only) | [GitHub](https://github.com/home-assistant/core)

## Quick Start

### Prerequisites
- Docker and Docker Compose installed
- External `proxy-network` created
- Domain names configured with DNS pointing to your server

### Setup
1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd docker
   ```

2. Create the external network:
   ```bash
   docker network create proxy-network
   ```

3. Navigate to any service directory and start it:
   ```bash
   cd traefik
   docker-compose up -d
   ```

## Configuration

### Environment Variables
Most services use `.env` files for configuration. Key variables include:
- Domain names (e.g., `immich.desktop.madhur.co.in`)
- Database credentials
- Upload locations
- Timezone settings (`Asia/Kolkata`)

### Network Configuration
- **proxy-network**: External network for service communication

### Security Features
- Authelia forward-auth middleware (`authelia@file`) for internet-facing services
- Dual-router pattern: LAN/VPN bypasses auth, internet requires Authelia
- VPN whitelist middleware for sensitive services (e.g., Vaultwarden)
- SSL certificates via Let's Encrypt
- Container security options (no-new-privileges)
- Network isolation

## Monitoring

- **Gatus**: Declarative health checks for all services, alerts via Ntfy
- **cAdvisor**: Container resource usage metrics
- **Grafana**: Host-based dashboards, visualizes container/system metrics
- **Change Detection**: Monitors websites for changes
- **Ntfy**: Push notifications for system events

## Access URLs

### Core Infrastructure
- **Authelia**: `https://auth.desktop.madhur.co.in`
- **Gatus**: `https://gatus.desktop.madhur.co.in`
- **Traefik Dashboard**: `https://traefik.desktop.madhur.co.in:9091`

### Knowledge Management
- **Bookstack**: `https://bookstack.desktop.madhur.co.in`
- **Outline**: `https://outline.desktop.madhur.co.in`
- **Linkwarden**: `https://linkwarden.desktop.madhur.co.in`
- **Planka**: `https://planka.desktop.madhur.co.in`
- **RedNotebook**: `https://rb.desktop.madhur.co.in`
- **TriliumNext**: `https://trilium.desktop.madhur.co.in`
- **Joplin Server**: `https://joplin.desktop.madhur.co.in`

### Media & Content
- **Immich**: `https://immich.desktop.madhur.co.in`
- **Jellyfin**: `https://jf.desktop.madhur.co.in`
- **Navidrome**: `https://navidrome.desktop.madhur.co.in`
- **Nextcloud**: `https://nc.desktop.madhur.co.in`
- **Paperless**: `https://paperless.desktop.madhur.co.in`
- **qui (qBittorrent)**: `https://torrent.desktop.madhur.co.in`

### Finance
- **Firefly III**: `https://firefly.desktop.madhur.co.in`
- **InvoiceShelf**: `https://invoiceshelf.desktop.madhur.co.in`
- **Wealthfolio**: `https://wealthfolio.desktop.madhur.co.in`
- **Ghostfolio**: `https://ghostfolio.desktop.madhur.co.in`

### Security & Development
- **Remote Browser**: `https://browser.desktop.madhur.co.in`
- **Code Server**: `https://code.desktop.madhur.co.in`
- **n8n**: `https://n8n.desktop.madhur.co.in`
- **Prefect**: `https://prefect.desktop.madhur.co.in`
- **Temporal UI**: `https://temporal-ui.desktop.madhur.co.in`
- **Bento**: `https://bento.desktop.madhur.co.in`
- **Termix**: `https://termix.desktop.madhur.co.in`
- **Request Baskets**: `https://req.desktop.madhur.co.in`
- **AKHQ**: `https://akhq.desktop.madhur.co.in`
- **Vaultwarden**: `https://vault.madhur.co.in`

### Utilities
- **ConvertX**: `https://convertx.desktop.madhur.co.in`
- **Dozzle**: `https://dozzle.desktop.madhur.co.in`
- **Glance**: `https://glance.desktop.madhur.co.in`
- **Homepage**: `https://home.desktop.madhur.co.in`
- **Homebox**: `https://homebox.desktop.madhur.co.in`
- **IT Tools**: `https://tools.desktop.madhur.co.in`
- **Ntfy**: `https://ntfy.madhur.co.in`
- **OliveTin**: `https://olivetin.desktop.madhur.co.in`
- **OpenGist**: `https://og.desktop.madhur.co.in`
- **Mailpit**: `https://mail.desktop.madhur.co.in`
- **SFTPGo**: `https://sftpgo.desktop.madhur.co.in`

### Location & Tracking
- **Dawarich**: `https://dawarich.desktop.madhur.co.in`

### Health & Fitness
- **SparkyFitness**: `https://sparkyfitness.desktop.madhur.co.in`

### Home Automation
- **Home Assistant**: `http://homeassistant.local.madhur.co.in` (LAN only, host network)

### Local Services (Host Machine)
- **Grafana**: `http://grafana.local.madhur.co.in` (LAN) / `https://grafana.desktop.madhur.co.in` (WAN, HTTPS + Authelia)
- **Prometheus**: `http://proxmox.local.madhur.co.in`
- **ActivityWatch**: `http://activitywatch.local.madhur.co.in`
- **WatchYourLAN**: `http://watchyourlan.local.madhur.co.in`
- **Ollama**: `http://ollama.local.madhur.co.in`

## Maintenance

- **Updates**: Manual container updates via `docker compose pull && docker compose up -d`
- **Backups**: Regular backups of persistent volumes recommended
- **Monitoring**: Check logs via Dozzle (`https://dozzle.desktop.madhur.co.in`) or `docker logs <container-name>`
- **SSL**: Certificates automatically renewed by Traefik

## Notes

- Authelia forward-auth applied to internet-facing services; LAN/VPN access bypasses auth
- VPN whitelist middleware applied to sensitive services (e.g., Vaultwarden)
- External network `proxy-network` must be created before starting services
- Some services require additional configuration files (`.env`, etc.)
- PostgreSQL 18 runs on the host machine and is shared by multiple services; reachable as `local.madhur.co.in:5432` (DNS) or `host.docker.internal:5432` (from containers via `host-gateway`)
- All services use domain pattern: `*.desktop.madhur.co.in` or `*.madhur.co.in`
- Traefik automatically provisions and renews Let's Encrypt SSL certificates
- Decommissioned services (Authentik, Booklore, Docmost, Karakeep, Journiv, Komodo, Radicale, EzBookkeeping, ExpenseOwl, Myfin, Sterling PDF, Gitea, WireGuard Easy, Memos, etc.) live under `archive/`

## Contributing

This is a personal homelab setup. Feel free to use these configurations as reference for your own homelab.

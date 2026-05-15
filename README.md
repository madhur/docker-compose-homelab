# Homelab Docker Compose Services

This repository contains Docker Compose configurations for various self-hosted services in my homelab environment. All services are configured to work together with Traefik as a reverse proxy and are accessible through custom domains with SSL certificates.

## Architecture Overview

![Homelab Architecture](https://raw.githubusercontent.com/madhur/docker-compose-homelab/master/homelab-architecture.drawio.png)

- **Reverse Proxy**: Traefik with Let's Encrypt SSL certificates
- **Network**: External `proxy-network` for service communication
- **VPN**: WireGuard VPN (10.42.42.0/24) for secure remote access
- **Authentication**: Authelia — forward-auth via Traefik for internet-facing services
- **Database**: PostgreSQL 18 running on host machine (local.madhur.co.in:5432, also reachable via `host.docker.internal:host-gateway` from containers)
- **Monitoring**: Gatus, Grafana, cAdvisor, Change Detection, Dockpeek for observability
- **Notifications**: Ntfy for push notifications
- **Storage**: Multiple database systems (MongoDB, Redis, Elasticsearch, DynamoDB) and persistent volumes

## Services

### Core Infrastructure
- **[Traefik](traefik/)** - Reverse proxy with automatic SSL certificates | [GitHub](https://github.com/traefik/traefik)
- **[Authelia](authelia/)** - Forward-auth identity provider | [GitHub](https://github.com/authelia/authelia)
- **[WireGuard Easy](wg-easy/)** - VPN server for remote access | [GitHub](https://github.com/wg-easy/wg-easy)
- **[Gatus](gatus/)** - Declarative service health monitoring | [GitHub](https://github.com/TwiN/gatus)

### Knowledge Management & Documentation
- **[Bookstack](bookstack/)** - Simple, self-hosted wiki platform | [GitHub](https://github.com/BookStackApp/BookStack)
- **[Docmost](docmost/)** - Collaborative documentation | [GitHub](https://github.com/docmost/docmost)
- **[Outline](outline/)** - Team knowledge base | [GitHub](https://github.com/outline/outline)
- **[Karakeep](karakeep/)** - Self-hosted bookmark and knowledge manager | [GitHub](https://github.com/karakeep-app/karakeep)
- **[Linkwarden](linkwarden/)** - Self-hosted bookmark manager with archive capabilities | [GitHub](https://github.com/linkwarden/linkwarden)
- **[Journiv](journiv/)** - Private journal | [GitHub](https://github.com/journiv/journiv)
- **[Planka](planka/)** - Kanban board for collaborative task management | [GitHub](https://github.com/plankanban/planka)
- **[RedNotebook](rednotebook/)** - Daily journal | [GitHub](https://github.com/jendrikseipp/rednotebook)

### Media & Content Management
- **[Immich](immich/)** - Self-hosted photo and video backup solution | [GitHub](https://github.com/immich-app/immich)
- **[Jellyfin](jellyfin/)** - Media server for movies, TV shows, and music | [GitHub](https://github.com/jellyfin/jellyfin)
- **[Nextcloud](nextcloud/)** - Self-hosted cloud storage and collaboration | [GitHub](https://github.com/nextcloud/server)
- **[Paperless-ngx](paperless/)** - Document management system | [GitHub](https://github.com/paperless-ngx/paperless-ngx)
- **[qBittorrent](qbittorrent/)** - BitTorrent client | [GitHub](https://github.com/qbittorrent/qBittorrent)

### Finance
- **[Firefly III](firefly/)** - Personal finance manager | [GitHub](https://github.com/firefly-iii/firefly-iii)
- **[InvoiceShelf](invoiceshelf/)** - Invoice management | [GitHub](https://github.com/InvoiceShelf/InvoiceShelf)

### Security & Authentication
- **[Authelia](authelia/)** - Forward-auth identity provider | [GitHub](https://github.com/authelia/authelia)
- **[Vaultwarden](vaultwarden/)** - Self-hosted Bitwarden password manager | [GitHub](https://github.com/dani-garcia/vaultwarden)

### Development & DevOps
- **[Code Server](code-server/)** - VS Code in the browser | [GitHub](https://github.com/coder/code-server)
- **[n8n](n8n/)** - Workflow automation platform | [GitHub](https://github.com/n8n-io/n8n)
- **[Komodo](komodo/)** - Build and deployment automation platform | [GitHub](https://github.com/mbecker20/komodo)
- **[Prefect](prefect/)** - Workflow orchestration platform | [GitHub](https://github.com/PrefectHQ/prefect)
- **[Temporal](temporal/)** - Workflow orchestration platform | [GitHub](https://github.com/temporalio/temporal)
- **[Bento](bento/)** - Stream processor for data pipelines | [GitHub](https://github.com/warpstreamlabs/bento)
- **[Termix](termix/)** - Web-based SSH terminal | [GitHub](https://github.com/LukeGus/Termix)
- **[Request Baskets](request-baskets/)** - HTTP request inspector | [GitHub](https://github.com/darklynx/request-baskets)
- **[Dockhand](dockhand/)** - Docker management UI
- **[AKHQ](akhq/)** - Kafka UI | [GitHub](https://github.com/tchiotludo/akhq)

### Databases & Storage
- **[DynamoDB](dynamodb/)** - NoSQL database (local instance) | [AWS Docs](https://aws.amazon.com/dynamodb/)
- **[Elasticsearch](elasticsearch/)** - Search and analytics engine | [GitHub](https://github.com/elastic/elasticsearch)
- **[MongoDB](mongodb/)** - NoSQL document database | [GitHub](https://github.com/mongodb/mongo)
- **[PostgreSQL](postgres/)** - Relational database
- **[Redis Cluster](redis-cluster/)** - In-memory data store cluster | [GitHub](https://github.com/redis/redis)
- **[Redis MQ Kafka](redis-mq-kafka/)** - Message queue with Kafka | [GitHub](https://github.com/apache/kafka)

### Monitoring & Analytics
- **[cAdvisor](cadvisor/)** - Container resource monitoring | [GitHub](https://github.com/google/cadvisor)
- **[Change Detection](changedetection/)** - Website change monitoring | [GitHub](https://github.com/dgtlmoon/changedetection.io)
- **[Dockpeek](dockpeek/)** - Docker container monitoring and management | [GitHub](https://github.com/louislam/dockpeek)
- **[Gatus](gatus/)** - Declarative service health monitoring | [GitHub](https://github.com/TwiN/gatus)
- **[Graphite + StatsD + Grafana](graphite-statsd-grafana/)** - Metrics collection and visualization | [GitHub](https://github.com/grafana/grafana)

### Location & Tracking
- **[Dawarich](dawarich/)** - Self-hosted location history | [GitHub](https://github.com/Freika/dawarich)

### Utilities & Tools
- **[ConvertX](convertx/)** - File format converter | [GitHub](https://github.com/C4illin/ConvertX)
- **[Glance](glance/)** - Self-hosted dashboard | [GitHub](https://github.com/glanceapp/glance)
- **[Homepage](homepage/)** - Application dashboard | [GitHub](https://github.com/gethomepage/homepage)
- **[Homebox](archive/homebox/)** - Home inventory management | [GitHub](https://github.com/sysadminsmedia/homebox)
- **[IT Tools](it-tools/)** - Collection of handy developer tools | [GitHub](https://github.com/CorentinTh/it-tools)
- **[JSON Crack](jsoncrack/)** - JSON data visualization tool | [GitHub](https://github.com/AykutSarac/jsoncrack.com)
- **[Networking Toolbox](networkingtoolbox/)** - Network diagnostic and testing tools
- **[Ntfy](ntfy/)** - Push notifications service | [GitHub](https://github.com/binwiederhier/ntfy)
- **[OliveTin](olivetin/)** - Web UI for running shell commands | [GitHub](https://github.com/OliveTin/OliveTin)
- **[OpenGist](opengist/)** - Self-hosted pastebin powered by Git | [GitHub](https://github.com/thomiceli/opengist)
- **[Radicale](radicale/)** - CalDAV/CardDAV server | [GitHub](https://github.com/Kozea/Radicale)
- **[Dozzle](dozzle/)** - Docker container log viewer | [GitHub](https://github.com/amir20/dozzle)

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
- **wg**: WireGuard VPN network (10.42.42.0/24)
- **elastic**: Elasticsearch cluster network

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
- **Grafana**: Visualizes metrics from Graphite/StatsD
- **Change Detection**: Monitors websites for changes
- **Ntfy**: Push notifications for system events

## Access URLs

### Core Infrastructure
- **Authelia**: `https://auth.desktop.madhur.co.in`
- **Gatus**: `https://gatus.desktop.madhur.co.in`
- **Traefik Dashboard**: `https://traefik.desktop.madhur.co.in:9091`
- **WireGuard**: `https://wg.desktop.madhur.co.in`

### Knowledge Management
- **Bookstack**: `https://bookstack.desktop.madhur.co.in`
- **Docmost**: `https://docmost.desktop.madhur.co.in`
- **Outline**: `https://outline.desktop.madhur.co.in`
- **Karakeep**: `https://kk.desktop.madhur.co.in`
- **Linkwarden**: `https://linkwarden.desktop.madhur.co.in`
- **Journiv**: `https://journiv.desktop.madhur.co.in`
- **Planka**: `https://planka.desktop.madhur.co.in`
- **RedNotebook**: `https://rb.desktop.madhur.co.in`

### Media & Content
- **Immich**: `https://immich.desktop.madhur.co.in`
- **Jellyfin**: `https://jf.desktop.madhur.co.in`
- **Nextcloud**: `https://nc.desktop.madhur.co.in`
- **Paperless**: `https://paperless.desktop.madhur.co.in`
- **qBittorrent**: `https://torrent.desktop.madhur.co.in`

### Finance
- **Firefly III**: `https://firefly.desktop.madhur.co.in`
- **InvoiceShelf**: `https://invoiceshelf.desktop.madhur.co.in`

### Security & Development
- **Code Server**: `https://code.desktop.madhur.co.in`
- **n8n**: `https://n8n.desktop.madhur.co.in`
- **Prefect**: `https://prefect.desktop.madhur.co.in`
- **Temporal UI**: `https://temporal-ui.desktop.madhur.co.in`
- **Bento**: `https://bento.desktop.madhur.co.in`
- **Komodo**: `https://komodo.desktop.madhur.co.in`
- **Termix**: `https://termix.desktop.madhur.co.in`
- **Request Baskets**: `https://req.desktop.madhur.co.in`
- **Vaultwarden**: `https://vault.madhur.co.in`

### Utilities
- **ConvertX**: `https://convertx.desktop.madhur.co.in`
- **Dozzle**: `https://dozzle.desktop.madhur.co.in`
- **Glance**: `https://glance.desktop.madhur.co.in`
- **Homepage**: `https://home.desktop.madhur.co.in`
- **Homebox**: `https://homebox.desktop.madhur.co.in`
- **IT Tools**: `https://tools.desktop.madhur.co.in`
- **JSON Crack**: `https://jc.desktop.madhur.co.in`
- **Ntfy**: `https://ntfy.madhur.co.in`
- **OliveTin**: `https://olivetin.desktop.madhur.co.in`
- **OpenGist**: `https://og.desktop.madhur.co.in`
- **Radicale**: `https://radiscale.desktop.madhur.co.in`

### Location & Tracking
- **Dawarich**: `https://dawarich.desktop.madhur.co.in`

### Local Services (Host Machine)
- **Grafana**: `http://grafana.local.madhur.co.in`
- **Prometheus**: `http://proxmox.local.madhur.co.in`
- **ActivityWatch**: `http://activitywatch.local.madhur.co.in`
- **WatchYourLAN**: `http://watchyourlan.local.madhur.co.in`
- **Ollama**: `http://ollama.local.madhur.co.in`
- **HomeAssistant**: `http://homeassistant.local.madhur.co.in`

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
- Decommissioned services (Authentik, Booklore, Actual Budget, EzBookkeeping, ExpenseOwl, Myfin, Sterling PDF, Gitea, etc.) live under `archive/`

## Contributing

This is a personal homelab setup. Feel free to use these configurations as reference for your own homelab.

# Homelab Docker Compose Services

This repository contains Docker Compose configurations for various self-hosted services in my homelab environment. All services are configured to work together with Traefik as a reverse proxy and are accessible through custom domains with SSL certificates.

## Architecture Overview

![Homelab Architecture](https://raw.githubusercontent.com/madhur/docker-compose-homelab/master/homelab-architecture.drawio.png)

- **Reverse Proxy**: Traefik with Let's Encrypt SSL certificates
- **Network**: External `proxy-network` for service communication
- **VPN**: WireGuard VPN (10.42.42.0/24) for secure remote access
- **Authentication**: Authentik SSO — forward-auth via Traefik for internet-facing services
- **Database**: PostgreSQL running on host machine (local.madhur.co.in:5432)
- **Monitoring**: cAdvisor, Gatus, Grafana, Change Detection for observability
- **Notifications**: Ntfy for push notifications
- **Storage**: Multiple database systems (MongoDB, Redis, Elasticsearch, DynamoDB) and persistent volumes

## Services

### Core Infrastructure
- **[Traefik](traefik/)** - Reverse proxy with automatic SSL certificates | [GitHub](https://github.com/traefik/traefik)
- **[Authentik](authentik/)** - Identity provider & SSO | [GitHub](https://github.com/goauthentik/authentik)
- **[WireGuard Easy](wg-easy/)** - VPN server for remote access | [GitHub](https://github.com/wg-easy/wg-easy)
- **[Gatus](gatus/)** - Declarative service health monitoring | [GitHub](https://github.com/TwiN/gatus)

### Knowledge Management & Documentation
- **[Bookstack](bookstack/)** - Simple, self-hosted wiki platform | [GitHub](https://github.com/BookStackApp/BookStack)
- **[Booklore](booklore/)** - Book library manager | [GitHub](https://github.com/adityachandelgit/booklore)
- **[Docmost](docmost/)** - Collaborative documentation | [GitHub](https://github.com/docmost/docmost)
- **[Karakeep](karakeep/)** - Self-hosted bookmark and knowledge manager | [GitHub](https://github.com/karakeep-app/karakeep)
- **[Linkwarden](linkwarden/)** - Self-hosted bookmark manager with archive capabilities | [GitHub](https://github.com/linkwarden/linkwarden)

### Media & Content Management
- **[Immich](immich/)** - Self-hosted photo and video backup solution | [GitHub](https://github.com/immich-app/immich)
- **[Jellyfin](jellyfin/)** - Media server for movies, TV shows, and music | [GitHub](https://github.com/jellyfin/jellyfin)
- **[Paperless-ngx](paperless/)** - Document management system | [GitHub](https://github.com/paperless-ngx/paperless-ngx)
- **[qBittorrent](qbittorrent/)** - BitTorrent client | [GitHub](https://github.com/qbittorrent/qBittorrent)

### Finance
- **[Firefly III](firefly/)** - Personal finance manager | [GitHub](https://github.com/firefly-iii/firefly-iii)
- **[Actual Budget](actual/)** - Local-first personal budget app | [GitHub](https://github.com/actualbudget/actual)
- **[EzBookkeeping](ezbookkeeping/)** - Personal bookkeeping | [GitHub](https://github.com/mayswind/ezbookkeeping)
- **[ExpenseOwl](expenseowl/)** - Expense tracking | [GitHub](https://github.com/tanq16/expenseowl)
- **[Myfin](myfin/)** - Personal finance tracker | [GitHub](https://github.com/afaneca/myfin)
- **[InvoiceShelf](invoiceshelf/)** - Invoice management | [GitHub](https://github.com/InvoiceShelf/InvoiceShelf)

### Security & Authentication
- **[Vaultwarden](vaultwarden/)** - Self-hosted Bitwarden password manager | [GitHub](https://github.com/dani-garcia/vaultwarden)

### Development & DevOps
- **[Code Server](code-server/)** - VS Code in the browser | [GitHub](https://github.com/coder/code-server)
- **[Gitea](gitea/)** - Self-hosted Git service | [GitHub](https://github.com/go-gitea/gitea)
- **[Komodo](komodo/)** - Build and deployment automation platform | [GitHub](https://github.com/mbecker20/komodo)
- **[Prefect](prefect/)** - Workflow orchestration platform | [GitHub](https://github.com/PrefectHQ/prefect)
- **[Temporal](temporal/)** - Workflow orchestration platform | [GitHub](https://github.com/temporalio/temporal)

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
- **[Homebox](homebox/)** - Home inventory management | [GitHub](https://github.com/sysadminsmedia/homebox)
- **[Homepage](homepage/)** - Application dashboard | [GitHub](https://github.com/gethomepage/homepage)
- **[IT Tools](it-tools/)** - Collection of handy developer tools | [GitHub](https://github.com/CorentinTh/it-tools)
- **[JSON Crack](jsoncrack/)** - JSON data visualization tool | [GitHub](https://github.com/AykutSarac/jsoncrack.com)
- **[Networking Toolbox](networkingtoolbox/)** - Network diagnostic and testing tools
- **[Ntfy](ntfy/)** - Push notifications service | [GitHub](https://github.com/binwiederhier/ntfy)
- **[OliveTin](olivetin/)** - Web UI for running shell commands | [GitHub](https://github.com/OliveTin/OliveTin)
- **[OpenGist](opengist/)** - Self-hosted pastebin powered by Git | [GitHub](https://github.com/thomiceli/opengist)
- **[Radicale](radicale/)** - CalDAV/CardDAV server | [GitHub](https://github.com/Kozea/Radicale)
- **[Sterling PDF](sterlingpdf/)** - PDF processing and manipulation service | [GitHub](https://github.com/Stirling-Tools/Stirling-PDF)

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
- Authentik SSO with forward-auth middleware for internet-facing services
- Dual-router pattern: LAN/VPN bypasses auth, internet requires Authentik
- VPN whitelist middleware for sensitive services
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
- **Authentik**: `https://authentik.desktop.madhur.co.in`
- **Gatus**: `https://gatus.desktop.madhur.co.in`
- **Traefik Dashboard**: `https://traefik.desktop.madhur.co.in:9091`
- **WireGuard**: `https://wg.desktop.madhur.co.in`

### Knowledge Management
- **Bookstack**: `https://bookstack.desktop.madhur.co.in`
- **Booklore**: `https://booklore.desktop.madhur.co.in`
- **Docmost**: `https://docmost.desktop.madhur.co.in`
- **Karakeep**: `https://kk.desktop.madhur.co.in`
- **Linkwarden**: `https://linkwarden.desktop.madhur.co.in`

### Media & Content
- **Immich**: `https://immich.desktop.madhur.co.in`
- **Jellyfin**: `https://jf.desktop.madhur.co.in`
- **Paperless**: `https://paperless.desktop.madhur.co.in`
- **qBittorrent**: `https://torrent.desktop.madhur.co.in`

### Finance
- **Firefly III**: `https://firefly.desktop.madhur.co.in`
- **Actual Budget**: `https://actual.desktop.madhur.co.in`
- **EzBookkeeping**: `https://ezbookkeeping.desktop.madhur.co.in`
- **ExpenseOwl**: `https://expenseowl.desktop.madhur.co.in`
- **Myfin**: `https://myfin.desktop.madhur.co.in`
- **InvoiceShelf**: `https://invoiceshelf.desktop.madhur.co.in`

### Security & Development
- **Code Server**: `https://code.desktop.madhur.co.in`
- **Prefect**: `https://prefect.desktop.madhur.co.in`
- **Temporal UI**: `https://temporal-ui.desktop.madhur.co.in`
- **Vaultwarden**: `https://vault.madhur.co.in`

### Utilities
- **ConvertX**: `https://convertx.desktop.madhur.co.in`
- **Glance**: `https://glance.desktop.madhur.co.in`
- **Homebox**: `https://homebox.desktop.madhur.co.in`
- **Homepage**: `https://home.desktop.madhur.co.in`
- **IT Tools**: `https://tools.desktop.madhur.co.in`
- **JSON Crack**: `https://jc.desktop.madhur.co.in`
- **Ntfy**: `https://ntfy.madhur.co.in`
- **OliveTin**: `https://olivetin.desktop.madhur.co.in`
- **OpenGist**: `https://og.desktop.madhur.co.in`
- **Radicale**: `https://radiscale.desktop.madhur.co.in`
- **Sterling PDF**: `https://pdf.desktop.madhur.co.in`

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
- **Monitoring**: Check logs via Dozzle (`http://localhost:9999`) or `docker logs <container-name>`
- **SSL**: Certificates automatically renewed by Traefik

## Notes

- Authentik forward-auth applied to internet-facing services; LAN/VPN access bypasses auth
- VPN whitelist middleware applied to sensitive services (e.g., Vaultwarden)
- External network `proxy-network` must be created before starting services
- Some services require additional configuration files (`.env`, etc.)
- PostgreSQL runs on the host machine and is shared by multiple services connecting to `local.madhur.co.in:5432`
- All services use domain pattern: `*.desktop.madhur.co.in` or `*.madhur.co.in`
- Traefik automatically provisions and renews Let's Encrypt SSL certificates

## Contributing

This is a personal homelab setup. Feel free to use these configurations as reference for your own homelab.

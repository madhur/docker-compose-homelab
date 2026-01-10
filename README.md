# Homelab Docker Compose Services

This repository contains Docker Compose configurations for various self-hosted services in my homelab environment. All services are configured to work together with Traefik as a reverse proxy and are accessible through custom domains with SSL certificates.

## 🏗️ Architecture Overview

- **Reverse Proxy**: Traefik with Let's Encrypt SSL certificates
- **Network**: External `proxy-network` for service communication
- **VPN**: WireGuard VPN (10.42.42.0/24) for secure remote access
- **Database**: PostgreSQL running on host machine (local.madhur.co.in:5432)
- **Monitoring**: cAdvisor, Grafana, Jaeger, Change Detection for observability
- **Notifications**: Ntfy for push notifications
- **Storage**: Multiple database systems (MongoDB, Redis, Scylla, Elasticsearch, DynamoDB) and persistent volumes

## 📋 Services

### Core Infrastructure
- **[Traefik](traefik/)** - Reverse proxy with automatic SSL certificates | [GitHub](https://github.com/traefik/traefik)
- **[Portainer](portainer/)** - Docker container management UI | [GitHub](https://github.com/portainer/portainer)
- **[WireGuard Easy](wg-easy/)** - VPN server for remote access | [GitHub](https://github.com/wg-easy/wg-easy)

### Knowledge Management & Documentation
- **[Affine](affine/)** - Privacy-focused knowledge base and collaboration platform | [GitHub](https://github.com/toeverything/affine)
- **[Bookstack](bookstack/)** - Simple, self-hosted wiki platform | [GitHub](https://github.com/BookStackApp/BookStack)
- **[Docmost](docmost/)** - Collaborative documentation platform | [GitHub](https://github.com/docmost/docmost)
- **[Linkwarden](linkwarden/)** - Self-hosted bookmark manager with archive capabilities | [GitHub](https://github.com/linkwarden/linkwarden)
- **[Outline](outline/)** - Team knowledge base and wiki | [GitHub](https://github.com/outline/outline)
- **[SiYuan](siyuan/)** - Privacy-first personal knowledge management system | [GitHub](https://github.com/siyuan-note/siyuan)

### Media & Content Management
- **[Immich](immich/)** - Self-hosted photo and video backup solution | [GitHub](https://github.com/immich-app/immich)
- **[Jellyfin](jellyfin/)** - Media server for movies, TV shows, and music | [GitHub](https://github.com/jellyfin/jellyfin)
- **[Paperless-ngx](paperless/)** - Document management system | [GitHub](https://github.com/paperless-ngx/paperless-ngx)
- **[Plex](plex/)** - Media streaming server | [GitHub](https://github.com/plexinc/pms-docker)
- **[qBittorrent](qbittorrent/)** - BitTorrent client | [GitHub](https://github.com/qbittorrent/qBittorrent)

### Security & Authentication
- **[Vaultwarden](vaultwarden/)** - Self-hosted Bitwarden password manager | [GitHub](https://github.com/dani-garcia/vaultwarden)

### Development & DevOps
- **[Code Server](code-server/)** - VS Code in the browser | [GitHub](https://github.com/coder/code-server)
- **[Gitea](gitea/)** - Self-hosted Git service | [GitHub](https://github.com/go-gitea/gitea)
- **[Jenkins](jenkins/)** - CI/CD automation server | [GitHub](https://github.com/jenkinsci/jenkins)
- **[Komodo](komodo/)** - Build and deployment automation platform | [GitHub](https://github.com/mbecker20/komodo)
- **[Nexus](nexus/)** - Artifact repository manager | [GitHub](https://github.com/sonatype/nexus-public)
- **[Temporal](temporal/)** - Workflow orchestration platform | [GitHub](https://github.com/temporalio/temporal)

### Databases & Storage
- **[DynamoDB](dynamodb/)** - NoSQL database (local instance) | [AWS Docs](https://aws.amazon.com/dynamodb/)
- **[Elasticsearch](elasticsearch/)** - Search and analytics engine | [GitHub](https://github.com/elastic/elasticsearch)
- **[MongoDB](mongodb/)** - NoSQL document database | [GitHub](https://github.com/mongodb/mongo)
- **[PostgreSQL](postgres/)** - Relational database (host machine)
- **[Redis Cluster](redis-cluster/)** - In-memory data store cluster | [GitHub](https://github.com/redis/redis)
- **[Redis MQ Kafka](redis-mq-kafka/)** - Message queue with Kafka | [GitHub](https://github.com/apache/kafka)
- **[Scylla](scylla/)** - High-performance NoSQL database | [GitHub](https://github.com/scylladb/scylla)

### Monitoring & Analytics
- **[cAdvisor](cadvisor/)** - Container resource monitoring | [GitHub](https://github.com/google/cadvisor)
- **[Change Detection](changedetection/)** - Website change monitoring | [GitHub](https://github.com/dgtlmoon/changedetection.io)
- **[Dockpeek](dockpeek/)** - Docker container monitoring and management | [GitHub](https://github.com/louislam/dockpeek)
- **[Graphite + StatsD + Grafana](graphite-statsd-grafana/)** - Metrics collection and visualization | [GitHub](https://github.com/grafana/grafana)
- **[Jaeger](jaeger/)** - Distributed tracing system | [GitHub](https://github.com/jaegertracing/jaeger)

### Location & Tracking
- **[MyTracks](mytracks/)** - GPS tracking and route management | [GitHub](https://github.com/frooodle/mytracks)
- **[OwnTracks](owntracks/)** - Location tracking and sharing | [GitHub](https://github.com/owntracks)

### Utilities & Tools
- **[IT Tools](it-tools/)** - Collection of handy developer tools | [GitHub](https://github.com/CorentinTh/it-tools)
- **[JSON Crack](jsoncrack/)** - JSON data visualization tool | [GitHub](https://github.com/AykutSarac/jsoncrack.com)
- **[Networking Toolbox](networkingtoolbox/)** - Network diagnostic and testing tools
- **[Ntfy](ntfy/)** - Push notifications service | [GitHub](https://github.com/binwiederhier/ntfy)
- **[OliveTin](olivetin/)** - Web UI for running shell commands | [GitHub](https://github.com/OliveTin/OliveTin)
- **[OpenGist](opengist/)** - Self-hosted pastebin powered by Git | [GitHub](https://github.com/thomiceli/opengist)
- **[Sterling PDF](sterlingpdf/)** - PDF processing and manipulation service | [GitHub](https://github.com/Stirling-Tools/Stirling-PDF)

## 🚀 Quick Start

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

## 🔧 Configuration

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
- VPN whitelist middleware for sensitive services
- SSL certificates via Let's Encrypt
- Container security options (no-new-privileges)
- Network isolation

## 📊 Monitoring

- **cAdvisor**: Provides container resource usage metrics
- **Grafana**: Visualizes metrics from Graphite/StatsD
- **Jaeger**: Distributed tracing for microservices
- **Change Detection**: Monitors websites for changes
- **Ntfy**: Push notifications for system events

## 🔒 Security

- All services behind Traefik reverse proxy
- SSL/TLS encryption for all web services
- VPN access required for sensitive services
- Automatic SSL certificate renewal via Let's Encrypt

## 📁 Directory Structure

```
docker/
├── Core Infrastructure
│   ├── traefik/                      # Reverse proxy
│   ├── portainer/                    # Container management
│   └── wg-easy/                      # VPN server
│
├── Knowledge Management
│   ├── affine/                       # Knowledge base
│   ├── bookstack/                    # Wiki platform
│   ├── docmost/                      # Collaborative docs
│   ├── linkwarden/                   # Bookmark manager
│   ├── outline/                      # Team wiki
│   └── siyuan/                       # PKM system
│
├── Media & Content
│   ├── immich/                       # Photo backup
│   ├── jellyfin/                     # Media server
│   ├── paperless/                    # Document management
│   ├── plex/                         # Media streaming
│   └── qbittorrent/                  # Torrent client
│
├── Development & DevOps
│   ├── code-server/                  # VS Code in browser
│   ├── gitea/                        # Git service
│   ├── jenkins/                      # CI/CD
│   ├── komodo/                       # Build automation
│   ├── nexus/                        # Artifact repository
│   └── temporal/                     # Workflow orchestration
│
├── Databases
│   ├── dynamodb/                     # NoSQL database
│   ├── elasticsearch/                # Search engine
│   ├── mongodb/                      # Document database
│   ├── postgres/                     # PostgreSQL
│   ├── redis-cluster/                # Redis cluster
│   ├── redis-mq-kafka/               # Message queue
│   └── scylla/                       # NoSQL database
│
├── Monitoring & Analytics
│   ├── cadvisor/                     # Container monitoring
│   ├── changedetection/              # Website monitoring
│   ├── dockpeek/                     # Docker monitoring
│   ├── graphite-statsd-grafana/      # Metrics & visualization
│   └── jaeger/                       # Distributed tracing
│
└── Utilities & Tools
    ├── it-tools/                     # Developer tools
    ├── jsoncrack/                    # JSON visualization
    ├── mytracks/                     # GPS tracking
    ├── networkingtoolbox/            # Network tools
    ├── ntfy/                         # Notifications
    ├── olivetin/                     # Shell command UI
    ├── opengist/                     # Pastebin
    ├── owntracks/                    # Location tracking
    └── sterlingpdf/                  # PDF tools
```

## 🌐 Access URLs

Services are accessible via the following domains:

### Core Services
- **Traefik Dashboard**: `https://traefik.desktop.madhur.co.in:9091`
- **Portainer**: `https://portainer.desktop.madhur.co.in`
- **WireGuard**: `https://wg.desktop.madhur.co.in`

### Knowledge Management
- **Affine**: `https://affine.desktop.madhur.co.in`
- **Bookstack**: `https://bookstack.desktop.madhur.co.in`
- **Docmost**: `https://docmost.desktop.madhur.co.in`
- **Linkwarden**: `https://linkwarden.desktop.madhur.co.in`
- **Outline**: `https://outline.desktop.madhur.co.in`
- **SiYuan**: `https://siyuan.desktop.madhur.co.in`

### Media & Content
- **Immich**: `https://immich.desktop.madhur.co.in`
- **Jellyfin**: `https://jellyfin.desktop.madhur.co.in`
- **Paperless**: `https://paperless.desktop.madhur.co.in`
- **Plex**: `https://plex.desktop.madhur.co.in`

### Security & Development
- **Code Server**: `https://code.desktop.madhur.co.in`
- **Gitea**: `https://gitea.desktop.madhur.co.in`
- **Vaultwarden**: `https://vault.madhur.co.in`

### Utilities
- **IT Tools**: `https://ittools.desktop.madhur.co.in`
- **JSON Crack**: `https://jsoncrack.desktop.madhur.co.in`
- **Ntfy**: `https://ntfy.madhur.co.in`
- **OliveTin**: `https://olivetin.desktop.madhur.co.in`
- **OpenGist**: `https://opengist.desktop.madhur.co.in`
- **Sterling PDF**: `https://pdf.desktop.madhur.co.in`

### Local Services (Host Machine)
These services run directly on the host machine and are accessible via Traefik routes:
- **Grafana**: `http://grafana.local.madhur.co.in`
- **Prometheus**: `http://proxmox.local.madhur.co.in`
- **ActivityWatch**: `http://activitywatch.local.madhur.co.in`
- **WatchYourLAN**: `http://watchyourlan.local.madhur.co.in`
- **Ollama**: `http://ollama.local.madhur.co.in`
- **Alertmanager**: `http://alertmanager.local.madhur.co.in`
- **Jaeger UI**: `http://jaeger.local.madhur.co.in`

## 🔄 Maintenance

- **Updates**: Manual container updates via `docker compose pull && docker compose up -d`
- **Backups**: Regular backups of persistent volumes recommended
- **Monitoring**: Check logs via Portainer or `docker logs <container-name>`
- **SSL**: Certificates automatically renewed by Traefik

## 📝 Notes

- VPN whitelist middleware applied to sensitive services (e.g., Vaultwarden)
- External network `proxy-network` must be created before starting services
- Some services require additional configuration files (`.env`, etc.)
- PostgreSQL runs on the host machine and is shared by multiple services:
  - Affine, Linkwarden, Gitea, and others connect to `local.madhur.co.in:5432`
  - Each service uses its own database within the shared PostgreSQL instance
- All services use domain pattern: `*.desktop.madhur.co.in` or `*.madhur.co.in`
- Traefik automatically provisions and renews Let's Encrypt SSL certificates

## 🤝 Contributing

This is a personal homelab setup. Feel free to use these configurations as reference for your own homelab.

## 📄 License

This repository contains Docker Compose configurations for self-hosted services. Please refer to individual service licenses for specific terms.


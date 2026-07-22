# Harbor Proxy Cache Browser

Web Interface for [Harbor](https://goharbor.io/) Proxy Cache projects, written in Ruby on Rails.

Forked from [klausmeyer/docker-registry-browser](https://github.com/klausmeyer/docker-registry-browser), adapted for Harbor's native API (`/api/v2.0/`) with global Basic Auth.

## Features

- Browse Harbor Proxy Cache projects with quota & storage usage
- Navigate repositories and tags under each project
- View artifact details: manifest, layers, environment variables, history
- Two pull command modes with toggle switch:
  - Prefix mode: `docker pull registry.example.com/docker/library/nginx:latest`
  - Mirror mode: `docker pull docker.registry.example.com/library/nginx:latest`
- Repository description tab with Markdown rendering
- Artifact type badges (IMAGE, CHART, WASM, SBOM, CNAI, etc.)
- Dark/Light theme toggle with system preference detection
- SVG icons (Lucide style), responsive layout
- Pagination, breadcrumb navigation, sticky footer

## Screenshots

### Project List (Homepage)

Dual-column grid with quota progress bar, repo count, storage usage, and creation date per project.

### Repository List

Tag list with artifact type badges, filter input, and description tab.

### Tag Detail

Pull command with dual-mode toggle, multi-arch manifest tabs, layers/env/history sections.

## Quick Start

### Docker

```shell
docker run --name harbor-browser -p 8080:8080 \
  -e SECRET_KEY_BASE=$(openssl rand -hex 64) \
  -e HARBOR_URL=https://your-harbor.example.com \
  -e HARBOR_USERNAME=robot\$viewer \
  -e HARBOR_PASSWORD=your-robot-token \
  -e PUBLIC_REGISTRY_URL=https://registry.example.com \
  registry.example.com/docker-registry-browser:2.0.0
```

### Docker Compose

```yaml
version: "3"

services:
  frontend:
    build: .
    environment:
      - "SECRET_KEY_BASE=changeme"
      - "HARBOR_URL=https://registry.example.com"
      - "HARBOR_USERNAME=robot$view-registry"
      - "HARBOR_PASSWORD=your-robot-token"
      - "PUBLIC_REGISTRY_URL=https://registry.example.com"
      - "DOMAIN_MIRROR_MAP=ghcr.io:ghcr,quay.io:quay,registry.k8s.io:k8s"
      - "NO_SSL_VERIFICATION=true"
    ports:
      - "8080:8080"
```

### Kubernetes (Helm)

```shell
helm install harbor-browser ./helm \
  --set environment.HARBOR_URL=https://registry.example.com \
  --set environment.PUBLIC_REGISTRY_URL=https://registry.example.com
```

Harbor credentials should be stored in a Kubernetes Secret and referenced via `envFromSecrets`:

```yaml
envFromSecrets:
  - harbor-credentials
```

## Configuration

See [docs/README.md](docs/README.md) for the full configuration reference.

### Key Environment Variables

| Variable | Description | Default |
|---|---|---|
| `HARBOR_URL` | Harbor API base URL | `http://localhost:8080` |
| `HARBOR_USERNAME` | Harbor robot account username (required) | - |
| `HARBOR_PASSWORD` | Harbor robot account password (required) | - |
| `PUBLIC_REGISTRY_URL` | Public URL for `docker pull` commands | - |
| `DOMAIN_MIRROR_MAP` | Project name to subdomain mapping for mirror mode | - |
| `PAGE_SIZE` | Items per page | `20` |
| `NO_SSL_VERIFICATION` | Skip SSL certificate verification | `false` |
| `SECRET_KEY_BASE` | Rails secret key (required in production) | `changeme` |

## Tech Stack

- Ruby 3.4.1 / Rails 8.1.3
- Faraday (HTTP client for Harbor API)
- Commonmarker (Markdown rendering)
- Importmap + jQuery (frontend assets)
- Puma (application server)
- Alpine-based Docker image

## License

Available as open source under the terms of the [MIT License](LICENSE).

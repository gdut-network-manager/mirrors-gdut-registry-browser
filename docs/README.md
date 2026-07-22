# Documentation

## Design

This application is a read-only web interface for browsing Harbor Proxy Cache projects. It connects to Harbor's native API (`/api/v2.0/`) using global Basic Auth with a robot account, and requires no database or local state.

### Architecture

```
Browser ──HTTP──> Rails App ──Faraday──> Harbor API (/api/v2.0/)
                                            │
                                            ├── GET /projects?with_detail=true
                                            ├── GET /projects/{name}/summary
                                            ├── GET /quotas
                                            ├── GET /projects/{name}/repositories
                                            ├── GET /projects/{name}/repositories/{repo}
                                            ├── GET /projects/{name}/repositories/{repo}/artifacts
                                            └── GET /v2/{repo}/manifests/{tag} (OCI API)
```

The app uses two Harbor API base paths:
- `/api/v2.0/` — project listing, repository browsing, artifact details
- `/v2/` — OCI manifest fetching (layers, environment variables, history)

### Authentication

Global Basic Auth is used on all Harbor API requests. No challenge-response or token flow — the `HARBOR_USERNAME` and `HARBOR_PASSWORD` environment variables are sent as HTTP Basic Auth headers on every request. This eliminates browser login popups.

A Harbor robot account with read-only access is recommended.

### Page Hierarchy

| Route | Page | Description |
|---|---|---|
| `GET /` | Project list | Proxy cache projects with quota, repo count, storage usage |
| `GET /project/:project_name` | Repository list | Repositories under the project |
| `GET /project/:project_name/repo/*repo` | Tag list | Tags/artifacts in the repository, with description tab |
| `GET /project/:project_name/repo/*repo/tag/:tag` | Tag detail | Pull commands, manifest, layers, env, history |

### Pull Command Modes

Two modes are available with a toggle switch on the tag detail page:

**Prefix mode** — Prepends the Harbor project name to the image path:

```
docker pull registry.example.com/docker/library/nginx:latest
```

**Mirror mode** — Replaces the domain with a per-project subdomain:

```
docker pull docker.registry.example.com/library/nginx:latest
```

Mirror mode requires `DOMAIN_MIRROR_MAP` to be configured. Unmapped projects fall back to using the project name as the subdomain.

## Installation

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

Store Harbor credentials in a Kubernetes Secret:

```shell
kubectl create secret generic harbor-credentials \
  --from-literal=HARBOR_USERNAME='robot$viewer' \
  --from-literal=HARBOR_PASSWORD='your-robot-token'
```

Reference it in `values.yaml`:

```yaml
envFromSecrets:
  - harbor-credentials
```

### Manual Installation

1. Install Ruby 3.4.1 (see `.ruby-version`)
2. Install dependencies: `bundle install`
3. Set environment variables (see below)
4. Start the server: `bundle exec rails server`

## Configuration

All configuration is via environment variables.

### Harbor Connection

#### `HARBOR_URL`

The base URL of your Harbor instance. The app appends `/api/v2.0/` and `/v2/` paths to this URL.

Default: `http://localhost:8080`

#### `HARBOR_USERNAME`

Harbor robot account username. Required for API authentication.

Example: `robot$viewer`

Default: not set

#### `HARBOR_PASSWORD`

Harbor robot account password/token. Required for API authentication.

Default: not set

### Public Registry

#### `PUBLIC_REGISTRY_URL`

The public-facing URL of your registry, used to generate `docker pull` commands. Should contain only the domain (and port if non-standard).

Example: `https://registry.example.com`

Default: not set (pull commands section will be hidden)

#### `DOMAIN_MIRROR_MAP`

Comma-separated mapping of Harbor project names to subdomains, used by the "mirror mode" pull command.

Format: `project_name:subdomain,project_name:subdomain`

Example: `ghcr.io:ghcr,quay.io:quay,registry.k8s.io:k8s,mcr.microsoft.com:mcr,gcr.io:gcr,docker.elastic.co:elastic,nvcr.io:nvcr,registry.gitlab.com:gitlab`

With `PUBLIC_REGISTRY_URL=https://registry.example.com`, a tag in project `ghcr.io` generates:

```
docker pull ghcr.registry.example.com/repository:tag
```

Projects not in the map use the project name itself as the subdomain.

Default: not set (mirror mode toggle will not appear)

### Pagination

#### `PAGE_SIZE`

Number of items per page in project and repository lists.

Default: `20`

### SSL / TLS

#### `NO_SSL_VERIFICATION`

When set to `true`, `1`, or `yes`, the app skips SSL certificate verification when connecting to the Harbor API. Useful for self-signed certificates.

Default: `false`

#### `CA_FILE`

Path to a custom CA certificate file for verifying Harbor API TLS connections.

Default: not set

### HTTP Server

#### `ADDRESS`

IP address to bind the HTTP server.

Default: `0.0.0.0`

#### `PORT`

Port for the HTTP server.

Default: `8080`

#### `SECRET_KEY_BASE`

Rails secret key used for encryption. Required in production. Generate with:

```
openssl rand -hex 64
```

Default: `changeme`

### HTTPS / TLS

SSL mode is enabled when both `SSL_CERT_PATH` and `SSL_KEY_PATH` are set. Consider using a reverse proxy (nginx, traefik) instead.

#### `SSL_ADDRESS`

IP address for the HTTPS server.

Default: `0.0.0.0`

#### `SSL_PORT`

Port for the HTTPS server.

Default: `8443`

#### `SSL_CERT_PATH`

Path to the SSL certificate file.

Default: not set

#### `SSL_KEY_PATH`

Path to the SSL key file.

Default: not set

### Subfolder Deployment

To run the app in a subdirectory, set both:

```
SCRIPT_NAME=/browser
RAILS_RELATIVE_URL_ROOT=/browser
```

Configure your reverse proxy to strip the prefix:

```nginx
location /browser/ {
    proxy_pass http://127.0.0.1:8080/;
}
```

### Logging

#### `REGISTRY_LOG_LEVEL`

Log level for Harbor API request/response logging.

Default: `info`

#### `REGISTRY_LOG_HEADERS`

When enabled, logs HTTP request headers to the Harbor API. Do not enable in production — Authorization headers contain sensitive data.

Default: `false`

## Harbor Robot Account Setup

1. In Harbor UI, go to **Robot Accounts** under the target project or system settings
2. Create a robot account with read-only permissions
3. Use the generated username (e.g. `robot$viewer`) and secret token

The robot account needs access to:
- List projects
- View project details and summaries
- List repositories
- View repository details
- List artifacts
- Pull manifests (OCI API)

## Troubleshooting

### Browser shows login popup

This happens if `HARBOR_USERNAME` or `HARBOR_PASSWORD` is not set. The app uses global Basic Auth — both must be configured.

### 502 Bad Gateway on project pages

The Harbor API may be slow or unreachable. Check:
- `HARBOR_URL` is correct and reachable from the app container
- `NO_SSL_VERIFICATION=true` if using self-signed certificates
- Robot account credentials are valid

### Pull commands not showing

`PUBLIC_REGISTRY_URL` must be set. Without it, the pull command section is hidden.

### Mirror mode not available

`DOMAIN_MIRROR_MAP` must be configured. The toggle switch only appears when this variable is set.

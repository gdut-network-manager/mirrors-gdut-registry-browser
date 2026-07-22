# 文档

## 设计理念

本应用是一个只读的 Web 界面,用于浏览 Harbor Proxy Cache 项目。它通过全局 Basic Auth(机器人账户)连接 Harbor 原生 API (`/api/v2.0/`),无需数据库或本地状态。

### 架构

```
浏览器 ──HTTP──> Rails 应用 ──Faraday──> Harbor API (/api/v2.0/)
                                            │
                                            ├── GET /projects?with_detail=true
                                            ├── GET /projects/{name}/summary
                                            ├── GET /quotas
                                            ├── GET /projects/{name}/repositories
                                            ├── GET /projects/{name}/repositories/{repo}
                                            ├── GET /projects/{name}/repositories/{repo}/artifacts
                                            └── GET /v2/{repo}/manifests/{tag} (OCI API)
```

应用使用两个 Harbor API 基础路径:
- `/api/v2.0/` — 项目列表、仓库浏览、制品详情
- `/v2/` — OCI Manifest 获取(层信息、环境变量、构建历史)

### 认证机制

所有 Harbor API 请求均使用全局 Basic Auth。没有 challenge-response 或 token 流程 — `HARBOR_USERNAME` 和 `HARBOR_PASSWORD` 环境变量作为 HTTP Basic Auth 头发送到每个请求上。这消除了浏览器登录弹窗。

建议使用具有只读权限的 Harbor 机器人账户。

### 页面层级

| 路由 | 页面 | 说明 |
|---|---|---|
| `GET /` | 项目列表 | Proxy Cache 项目,展示配额、仓库数量、空间使用量 |
| `GET /project/:project_name` | 仓库列表 | 项目下的仓库 |
| `GET /project/:project_name/repo/*repo` | 标签列表 | 仓库中的标签/制品,带描述信息 Tab |
| `GET /project/:project_name/repo/*repo/tag/:tag` | 标签详情 | 拉取命令、Manifest、层信息、环境变量、构建历史 |

### 拉取命令模式

标签详情页提供两种模式,通过滑块开关切换:

**前缀模式** — 在镜像路径前添加 Harbor 项目名:

```
docker pull registry.example.com/docker/library/nginx:latest
```

**镜像模式** — 用项目对应的子域名替换域名:

```
docker pull docker.registry.example.com/library/nginx:latest
```

镜像模式需要配置 `DOMAIN_MIRROR_MAP`。未映射的项目使用项目名作为子域名。

## 安装

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

Helm Chart 以 OCI 形式推送到 Harbor,直接从 OCI registry 安装。OCI 不支持 `latest` 标签,需要指定具体版本号(即 `helm/Chart.yaml` 中的 `version` 字段):

```shell
helm registry login registry.example.com --username robot\$deployer --password your-token

helm install harbor-browser \
  oci://registry.example.com/docker-registry-browser/docker-registry-browser-helm \
  --version 0.3.0 \
  --set environment.HARBOR_URL=https://registry.example.com \
  --set environment.PUBLIC_REGISTRY_URL=https://registry.example.com
```

可用版本号可在 Harbor UI 的镜像仓库页面查看,或通过以下命令列出:

```shell
helm registry login registry.example.com --username robot\$deployer --password your-token
helm show all oci://registry.example.com/docker-registry-browser/docker-registry-browser-helm --version 0.3.0
```

将 Harbor 凭证存储在 Kubernetes Secret 中:

```shell
kubectl create secret generic harbor-credentials \
  --from-literal=HARBOR_USERNAME='robot$viewer' \
  --from-literal=HARBOR_PASSWORD='your-robot-token'
```

在 `values.yaml` 中引用:

```yaml
envFromSecrets:
  - harbor-credentials
```

### 手动安装

1. 安装 Ruby 3.4.1(参见 `.ruby-version`)
2. 安装依赖: `bundle install`
3. 设置环境变量(见下文)
4. 启动服务器: `bundle exec rails server`

## 配置

所有配置均通过环境变量设置。

### Harbor 连接

#### `HARBOR_URL`

Harbor 实例的基础 URL。应用会在此 URL 后拼接 `/api/v2.0/` 和 `/v2/` 路径。

默认值: `http://localhost:8080`

#### `HARBOR_USERNAME`

Harbor 机器人账户用户名。API 认证必填。

示例: `robot$viewer`

默认值: 未设置

#### `HARBOR_PASSWORD`

Harbor 机器人账户密码/令牌。API 认证必填。

默认值: 未设置

### 公开 Registry

#### `PUBLIC_REGISTRY_URL`

Registry 的公开 URL,用于生成 `docker pull` 命令。只应包含域名(如有非标准端口则包含端口)。

示例: `https://registry.example.com`

默认值: 未设置(拉取命令区域将隐藏)

#### `DOMAIN_MIRROR_MAP`

逗号分隔的 Harbor 项目名到子域名的映射,供"镜像模式"拉取命令使用。

格式: `项目名:子域名,项目名:子域名`

示例: `ghcr.io:ghcr,quay.io:quay,registry.k8s.io:k8s,mcr.microsoft.com:mcr,gcr.io:gcr,docker.elastic.co:elastic,nvcr.io:nvcr,registry.gitlab.com:gitlab`

当 `PUBLIC_REGISTRY_URL=https://registry.example.com` 时,`ghcr.io` 项目中的标签会生成:

```
docker pull ghcr.registry.example.com/repository:tag
```

未在映射中的项目使用项目名本身作为子域名。

默认值: 未设置(镜像模式开关不显示)

### 分页

#### `PAGE_SIZE`

项目列表和仓库列表每页的条目数。

默认值: `20`

### SSL / TLS

#### `NO_SSL_VERIFICATION`

设置为 `true`、`1` 或 `yes` 时,应用跳过 Harbor API 的 SSL 证书验证。适用于自签名证书。

默认值: `false`

#### `CA_FILE`

自定义 CA 证书文件路径,用于验证 Harbor API 的 TLS 连接。

默认值: 未设置

### HTTP 服务器

#### `ADDRESS`

HTTP 服务器绑定的 IP 地址。

默认值: `0.0.0.0`

#### `PORT`

HTTP 服务器端口。

默认值: `8080`

#### `SECRET_KEY_BASE`

Rails 加密密钥。如果未设置或为 `changeme`,容器启动时会自动生成一个随机值。生产环境建议显式设置固定值以保证 session 一致性。生成方式:

```
openssl rand -hex 64
```

默认值: `changeme`(自动生成)

### HTTPS / TLS

当 `SSL_CERT_PATH` 和 `SSL_KEY_PATH` 均设置时启用 SSL 模式。建议使用反向代理(nginx、traefik)代替。

#### `SSL_ADDRESS`

HTTPS 服务器绑定的 IP 地址。

默认值: `0.0.0.0`

#### `SSL_PORT`

HTTPS 服务器端口。

默认值: `8443`

#### `SSL_CERT_PATH`

SSL 证书文件路径。

默认值: 未设置

#### `SSL_KEY_PATH`

SSL 密钥文件路径。

默认值: 未设置

### 子目录部署

要在子目录中运行应用(例如通过 `https://mirrors.example.com/docker/` 访问),需要设置 `SCRIPT_NAME` 和 `RAILS_RELATIVE_URL_ROOT` 环境变量。

#### Docker / Docker Compose

```yaml
environment:
  - "SCRIPT_NAME=/docker"
  - "RAILS_RELATIVE_URL_ROOT=/docker"
```

同时在反向代理中去除前缀:

```nginx
location /docker/ {
    proxy_pass http://127.0.0.1:8080/;
}
```

#### Kubernetes (Helm)

在 `values.yaml` 中设置 `relativeUrlRoot`,Ingress 会自动配置 `rewrite-target` 注解:

```yaml
relativeUrlRoot: "/docker"

ingress:
  enabled: true
  hosts:
    - host: mirrors.example.com
      paths:
        - path: /
          pathType: Prefix
```

### 日志

#### `REGISTRY_LOG_LEVEL`

Harbor API 请求/响应日志的日志级别。

默认值: `info`

#### `REGISTRY_LOG_HEADERS`

启用后,记录发往 Harbor API 的 HTTP 请求头。请勿在生产环境启用 — Authorization 头包含敏感数据。

默认值: `false`

## Harbor 机器人账户配置

1. 在 Harbor 界面中,进入目标项目或系统设置下的 **Robot Accounts**
2. 创建一个具有只读权限的机器人账户
3. 使用生成的用户名(如 `robot$viewer`)和密钥令牌

机器人账户需要以下权限:
- 列出项目
- 查看项目详情和摘要
- 列出仓库
- 查看仓库详情
- 列出制品
- 拉取 Manifest(OCI API)

## 故障排除

### 浏览器弹出登录框

如果 `HARBOR_USERNAME` 或 `HARBOR_PASSWORD` 未设置会出现此问题。应用使用全局 Basic Auth — 两者都必须配置。

### 项目页面返回 502 Bad Gateway

Harbor API 可能响应缓慢或不可达。检查:
- `HARBOR_URL` 正确且应用容器可访问
- 如使用自签名证书,设置 `NO_SSL_VERIFICATION=true`
- 机器人账户凭证有效

### 拉取命令不显示

必须设置 `PUBLIC_REGISTRY_URL`。未设置时拉取命令区域隐藏。

### 镜像模式不可用

必须配置 `DOMAIN_MIRROR_MAP`。此变量未设置时滑块开关不显示。

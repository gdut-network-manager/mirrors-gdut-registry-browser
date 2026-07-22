# Harbor Proxy Cache Browser Helm Chart

用于部署 Harbor Proxy Cache Browser 的 Helm Chart。Chart 以 OCI 形式推送到 Harbor。

## 使用方法

Helm Chart 以 OCI 形式推送到 Harbor。OCI 不支持 `latest` 标签,需要指定版本号(对应 `helm/Chart.yaml` 中的 `version` 字段):

```shell
helm registry login registry.example.com --username robot\$deployer --password your-token

helm install harbor-browser \
  oci://registry.example.com/docker-registry-browser/docker-registry-browser-helm \
  --version 0.3.0 \
  --set environment.HARBOR_URL=https://registry.example.com \
  --set environment.PUBLIC_REGISTRY_URL=https://registry.example.com
```

可用版本号可在 Harbor UI 的镜像仓库页面查看。

## 版本管理

CI/CD 仅在版本号变更时触发构建。应用版本号的单一事实来源是 `config/initializers/version.rb`,Docker 镜像和 Helm Chart 各自从以下位置提取版本号:

| 产物 | 版本号来源 | 说明 |
|---|---|---|
| Docker 镜像 | `config/initializers/version.rb` | 应用版本号(如 `2.0.0`) |
| Helm Chart | `helm/Chart.yaml` 的 `version` | Chart 版本号(如 `0.3.0`),独立于应用版本号 |

更新版本号时,务必同时修改以下三处:

1. `config/initializers/version.rb` — 应用版本号(Docker 镜像 tag)
2. `helm/Chart.yaml` 的 `appVersion` — 必须与 `version.rb` 一致
3. `helm/Chart.yaml` 的 `version` — Chart 自身版本号

## 配置

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

environment:
  HARBOR_URL: "https://registry.example.com"
  PUBLIC_REGISTRY_URL: "https://registry.example.com"
  DOMAIN_MIRROR_MAP: "ghcr.io:ghcr,quay.io:quay,registry.k8s.io:k8s"
  PAGE_SIZE: "20"
```

## 子路径部署

通过 `https://mirrors.example.com/docker/` 访问时,设置 `relativeUrlRoot`:

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

Ingress 会自动配置 `rewrite-target` 注解,应用会接收 `SCRIPT_NAME` 和 `RAILS_RELATIVE_URL_ROOT` 环境变量。

完整配置选项请参考 [values.yaml](values.yaml)。

# Harbor Proxy Cache Browser Helm Chart

用于部署 Harbor Proxy Cache Browser 的 Helm Chart。Chart 以 OCI 形式推送到 Harbor。

## 使用方法

```shell
helm registry login registry.example.com --username robot\$deployer --password your-token

helm install harbor-browser \
  oci://registry.example.com/docker-registry-browser/docker-registry-browser-helm \
  --version latest \
  --set environment.HARBOR_URL=https://registry.example.com \
  --set environment.PUBLIC_REGISTRY_URL=https://registry.example.com
```

指定版本号(时间戳格式):

```shell
helm install harbor-browser \
  oci://registry.example.com/docker-registry-browser/docker-registry-browser-helm \
  --version 20260723120000
```

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

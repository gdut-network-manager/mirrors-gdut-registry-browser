# Harbor Proxy Cache Browser Helm Chart

用于部署 Harbor Proxy Cache Browser 的 Helm Chart。

## 使用方法

```shell
helm install harbor-browser ./helm \
  --set environment.HARBOR_URL=https://registry.example.com \
  --set environment.PUBLIC_REGISTRY_URL=https://registry.example.com
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

完整配置选项请参考 [values.yaml](values.yaml)。

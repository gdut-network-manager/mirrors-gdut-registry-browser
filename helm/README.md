# Harbor Proxy Cache Browser Helm Chart

A Helm chart for deploying the Harbor Proxy Cache Browser.

## Usage

```shell
helm install harbor-browser ./helm \
  --set environment.HARBOR_URL=https://registry.example.com \
  --set environment.PUBLIC_REGISTRY_URL=https://registry.example.com
```

## Configuration

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

environment:
  HARBOR_URL: "https://registry.example.com"
  PUBLIC_REGISTRY_URL: "https://registry.example.com"
  DOMAIN_MIRROR_MAP: "ghcr.io:ghcr,quay.io:quay,registry.k8s.io:k8s"
  PAGE_SIZE: "20"
```

See [values.yaml](values.yaml) for all available options.

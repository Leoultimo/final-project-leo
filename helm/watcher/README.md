# QuakeWatch Helm Chart

A modern, production-ready Helm chart for deploying the QuakeWatch seismic event monitoring application on Kubernetes.

## Features

✅ **Modular Configuration** - All hardcoded values moved to `values.yaml`  
✅ **Helm Best Practices** - Following Kubernetes and Helm community standards  
✅ **Dynamic Labeling** - Automatic Helm labels for resource tracking  
✅ **Conditional Resources** - Enable/disable ingress, HPA, health checks  
✅ **Resource Management** - Configurable CPU/memory requests and limits  
✅ **Health Checks** - Built-in liveness and readiness probes  
✅ **Auto-scaling** - Horizontal Pod Autoscaler with configurable thresholds  
✅ **Health Monitoring** - Scheduled CronJob for periodic health checks  

## Quick Start

### Install the Chart

```bash
helm install quakewatch ./watcher
```

### Install with Custom Values

```bash
helm install quakewatch ./watcher -f custom-values.yaml
```

### Upgrade an Existing Release

```bash
helm upgrade quakewatch ./watcher
```

### Dry-run to Preview Manifests

```bash
helm template quakewatch ./watcher
```

## Chart Structure

```
watcher/
├── Chart.yaml              # Chart metadata
├── values.yaml             # Default configuration
├── templates/
│   ├── _helpers.tpl        # Template helper functions
│   ├── deployment.yaml     # Main application deployment
│   ├── service.yaml        # Kubernetes service
│   ├── hpa.yaml            # Horizontal Pod Autoscaler
│   ├── job.yaml            # CronJob for health checks
│   ├── serviceaccount.yaml # Service account
│   └── ingress.yaml        # Ingress configuration
└── .helmignore            # Files to ignore when packaging
```

## Configuration

### Core Application Settings

```yaml
app: quakewatch                    # Application name
environment: production             # Environment scope
replicaCount: 1                     # Number of replicas
```

### Container Image

```yaml
image:
  repository: leoultimo/watcher     # Docker image repository
  pullPolicy: IfNotPresent          # Image pull policy
  tag: latest                       # Image tag
```

### Resource Limits

```yaml
resources:
  requests:
    cpu: 250m
    memory: 400Mi
  limits:
    cpu: 500m
    memory: 800Mi
```

### Service Configuration

```yaml
service:
  type: ClusterIP                   # Service type
  port: 80                          # Service port
  targetPort: 5000                  # Container port
  sessionAffinity: None
```

### Health Probes

```yaml
livenessProbe:
  enabled: true
  httpGet:
    path: /health
    port: 5000
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  enabled: true
  httpGet:
    path: /ping
    port: 5000
  initialDelaySeconds: 10
  periodSeconds: 5
```

### Auto-scaling

```yaml
autoscaling:
  enabled: true
  minReplicas: 1
  maxReplicas: 5
  targetCPUUtilizationPercentage: 70
```

### Health Check CronJob

```yaml
healthCheck:
  enabled: true
  schedule: "*/5 * * * *"           # Every 5 minutes
  image: curlimages/curl:latest
  serviceName: quakewatch-service
```

## Examples

### Custom Deployment with Different Image

```bash
helm install quakewatch ./watcher \
  --set image.repository=my-registry/quakewatch \
  --set image.tag=v2.0.0
```

### Scale Up Replicas

```bash
helm upgrade quakewatch ./watcher --set replicaCount=3
```

### Enable Ingress

```yaml
ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: quakewatch.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: quakewatch-tls
      hosts:
        - quakewatch.example.com
```

### Adjust Auto-scaling

```bash
helm upgrade quakewatch ./watcher \
  --set autoscaling.enabled=true \
  --set autoscaling.minReplicas=2 \
  --set autoscaling.maxReplicas=10 \
  --set autoscaling.targetCPUUtilizationPercentage=80
```

### Disable Health Check CronJob

```bash
helm upgrade quakewatch ./watcher --set healthCheck.enabled=false
```

## Values Reference

See [values.yaml](values.yaml) for the complete list of configurable parameters with descriptions.

## Troubleshooting

### View Generated Manifests

```bash
helm template quakewatch ./watcher
```

### Check Deployed Resources

```bash
kubectl get all -l app.kubernetes.io/instance=quakewatch
```

### View Pod Logs

```bash
kubectl logs -l app=quakewatch -f
```

### Describe Deployment

```bash
kubectl describe deployment quakewatch
```

## Versioning

- **Chart Version**: 1.0.0
- **Application Version**: 1.0.0
- **Helm API Version**: v2

## License

See LICENSE file in the root repository.

## Support

For issues and questions, please visit: https://github.com/leo/quakewatch

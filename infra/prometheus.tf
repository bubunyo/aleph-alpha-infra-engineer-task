# Configured with StatefulSet for persistent storage

# Deploy Prometheus using Helm
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "77.9.1"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [
    yamlencode({
      grafana = {
        enabled = false # You will deploy Grafana separately and integrate with Loki
      }
      prometheus = {
        prometheusSpec = {
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                accessModes = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "10Gi"
                  }
                }
              }
            }
          }
        }
      }
      alertmanager = {
        enabled = false
      }
    })
  ]

  # Ensure namespaces exist and values file is generated
  depends_on = [
    kubernetes_namespace.monitoring,
  ]

  # Timeout for large chart deployment
  timeout = 600

  # Wait for deployment to be ready
  wait          = true
  wait_for_jobs = true
}
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

# Prometheus Ingress for external access on prometheus.localhost
resource "kubernetes_ingress_v1" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
    }
  }

  spec {
    ingress_class_name = "nginx"
    
    rule {
      host = "prometheus.localhost"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "prometheus-kube-prometheus-prometheus"
              port {
                number = 9090
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    helm_release.prometheus
  ]
}
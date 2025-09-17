# Loki deployment for log aggregation

resource "helm_release" "loki" {
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  version    = "5.47.2"
  namespace  = kubernetes_namespace.logging.metadata[0].name

  values = [
    yamlencode({
      # Minimal single binary configuration (works with v5.x)
      deploymentMode = "SingleBinary"
      
      # Single binary with persistence
      singleBinary = {
        replicas = 1
        persistence = {
          enabled = true
          size    = "5Gi"
        }
      }
      
      # Basic Loki configuration
      loki = {
        auth_enabled = false
        storage = {
          type = "filesystem"
        }
        commonConfig = {
          replication_factor = 1
        }
        schemaConfig = {
          configs = [
            {
              from = "2024-01-01"
              store = "tsdb"
              object_store = "filesystem"
              schema = "v13"
              index = {
                prefix = "index_"
                period = "24h"
              }
            }
          ]
        }
      }
    })
  ]

  depends_on = [
    kubernetes_namespace.logging
  ]

  timeout = 300
  wait    = true
}
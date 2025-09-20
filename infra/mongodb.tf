# MongoDB deployment using custom Helm chart as StatefulSet

locals {
  mongodb_cluster_port = 27017
  mongodb_ns           = kubernetes_namespace.database.metadata[0].name
}

resource "helm_release" "mongodb" {
  name      = "mongodb"
  chart     = "./charts/mongodb"
  namespace = local.mongodb_ns

  values = [
    yamlencode({
      # Authentication using existing Kubernetes Secret
      auth = {
        enabled        = true
        existingSecret = kubernetes_secret.mongodb_auth["database"].metadata[0].name
      }

      # Persistence for data
      persistence = {
        enabled = true
        size    = "5Gi"
      }

      # Service configuration
      service = {
        type = "ClusterIP"
        port = local.mongodb_cluster_port
      }

      # Resource limits (minimal)
      resources = {
        requests = {
          memory = "256Mi"
          cpu    = "100m"
        }
        limits = {
          memory = "512Mi"
          cpu    = "200m"
        }
      }
    })
  ]

  depends_on = [
    kubernetes_namespace.database,
    kubernetes_secret.mongodb_auth
  ]

  timeout = 300
  wait    = true
}
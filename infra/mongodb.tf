# MongoDB deployment using custom Helm chart as StatefulSet

resource "helm_release" "mongodb" {
  name      = "mongodb"
  chart     = "./charts/mongodb"
  namespace = kubernetes_namespace.database.metadata[0].name

  values = [
    yamlencode({
      # Authentication using existing Kubernetes Secret
      auth = {
        enabled        = true
        existingSecret = kubernetes_secret.mongodb_auth.metadata[0].name
      }

      # Persistence for data
      persistence = {
        enabled = true
        size    = "5Gi"
      }

      # Service configuration
      service = {
        type = "ClusterIP"
        port = 27017
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
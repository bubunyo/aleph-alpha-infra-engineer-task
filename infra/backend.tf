# Guestbook Backend deployment using custom Helm chart

resource "helm_release" "guestbook_backend" {
  name      = "guestbook-backend"
  chart     = "./charts/guestbook-backend"
  namespace = kubernetes_namespace.application.metadata[0].name

  values = [
    yamlencode({
      # Image configuration
      image = {
        repository = "localhost:5000/python-guestbook-backend"
        tag        = "7fdc2fe"
      }

      # Service configuration
      service = {
        type = "ClusterIP"
        port = 8080
      }

      # Environment variables
      env = {
        port            = "8080"
        guestbookDbAddr = "mongodb.${kubernetes_namespace.database.metadata[0].name}.svc.cluster.local:27017"
      }

      # MongoDB connection using existing secret
      mongodb = {
        existingSecret = kubernetes_secret.mongodb_auth["app"].metadata[0].name
      }

      # Init container to wait for MongoDB
      initContainer = {
        enabled = true
        image = {
          repository = "mongo"
          tag        = "4.4"
        }
      }

      # Resource limits (minimal)
      resources = {
        requests = {
          memory = "128Mi"
          cpu    = "50m"
        }
        limits = {
          memory = "256Mi"
          cpu    = "100m"
        }
      }

      # Health checks (disable for now - will need to implement endpoints)
      livenessProbe = {
        enabled = false
      }
      readinessProbe = {
        enabled = false
      }
    })
  ]

  depends_on = [
    kubernetes_namespace.application,
    kubernetes_secret.mongodb_auth,
    helm_release.mongodb
  ]

  timeout = 300
  wait    = true
}
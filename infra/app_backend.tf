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
        tag        = "latest"
        pullPolicy = "Always"
      }

      # Service configuration
      service = {
        type = "ClusterIP"
        port = 8080
      }

      # Environment variables
      env = {
        port = "8080"
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

      # Health checks
      livenessProbe = {
        enabled = true
        httpGet = {
          path = "/health"
          port = 8080
        }
        initialDelaySeconds = 30
        periodSeconds = 10
      }
      
      readinessProbe = {
        enabled = true
        httpGet = {
          path = "/ready"
          port = 8080
        }
        initialDelaySeconds = 5
        periodSeconds = 5
      }

      # Metrics configuration
      metrics = {
        enabled = true
        serviceMonitor = {
          enabled = true
          labels = {
            release = "prometheus"
          }
          endpoint = {
            port = "http"
            path = "/metrics"
            interval = "30s"
            scrapeTimeout = "10s"
          }
        }
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/path" = "/metrics"
          "prometheus.io/port" = "8080"
        }
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
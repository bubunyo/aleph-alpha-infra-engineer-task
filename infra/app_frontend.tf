# Guestbook Frontend deployment using custom Helm chart

resource "helm_release" "guestbook_frontend" {
  name      = "guestbook-frontend"
  chart     = "./charts/guestbook-frontend"
  namespace = kubernetes_namespace.application.metadata[0].name

  values = [
    yamlencode({
      # Image configuration
      image = {
        repository = "localhost:5000/python-guestbook-frontend"
        tag        = "latest"
        pullPolicy = "Always"
      }

      # Service configuration
      service = {
        type = "ClusterIP"
        port = 80
      }

      # Environment variables
      env = {
        port             = "8080"
        guestbookApiAddr = "guestbook-backend.${kubernetes_namespace.application.metadata[0].name}.svc.cluster.local:8080"
      }

      # Ingress configuration
      ingress = {
        enabled = true
        hosts = [
          {
            host = "localhost"
            paths = [
              {
                path     = "/"
                pathType = "Prefix"
              }
            ]
          }
        ]
      }

      # Resource limits (minimal)
      resources = {
        requests = {
          memory = "64Mi"
          cpu    = "25m"
        }
        limits = {
          memory = "128Mi"
          cpu    = "50m"
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
    helm_release.guestbook_backend
  ]

  timeout = 300
  wait    = true
}
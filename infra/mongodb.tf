# MongoDB deployment as StatefulSet for guestbook backend

resource "helm_release" "mongodb" {
  name       = "mongodb"
  repository = "bitnami"
  chart      = "mongodb"
  version    = "16.5.44"
  namespace  = kubernetes_namespace.database.metadata[0].name

  values = [
    yamlencode({
      # Minimal StatefulSet configuration
      architecture = "standalone"

      # Authentication using Kubernetes Secret
      auth = {
        enabled        = true
        existingSecret = kubernetes_secret.mongodb_auth.metadata[0].name
        usernames = [var.mongodb_username]
        passwords = [var.mongodb_password]
        databases = [var.mongodb_database]
      }

      # Persistence for data
      persistence = {
        enabled = true
        size    = "5Gi"
      }

      # Service configuration
      service = {
        type = "ClusterIP"
        ports = {
          mongodb = 27017
        }
      }

      metrics = {
        enabled = true
        prometheusRule = {
          enabled = true
          rules = [
            #             {
            #               name = "rule1"
            #               rules = [
            #                 {
            #                   alert = "HighRequestLatency"
            #                   expr  = "job:request_latency_seconds:mean5m{job=\"myjob\"} > 0.5"
            #                   for   = "10m"
            #                   labels = {
            #                     severity = "page"
            #                   }
            #                   annotations = {
            #                     summary = "High request latency"
            #                   }
            #                 }
            #               ]
            #             }
          ]
        }
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
# Grafana deployment with Prometheus integration

resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = "9.4.5"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [
    yamlencode({
      # Persistence for dashboards and configuration
      persistence = {
        type    = "sts"
        enabled = true
        size    = "5Gi"
      }

      initChownData = {
        enabled = false
      }

      # Admin credentials using Kubernetes Secret
      admin = {
        existingSecret = kubernetes_secret.grafana_auth.metadata[0].name
        userKey        = "admin-user"
        passwordKey    = "admin-password"
      }

      # Service configuration
      service = {
        type = "ClusterIP"
        port = 80
      }

      # Data sources configuration
      datasources = {
        "datasources.yaml" = {
          apiVersion = 1
          datasources = [
            {
              name      = "Prometheus"
              type      = "prometheus"
              url       = "http://prometheus-kube-prometheus-prometheus.${kubernetes_namespace.monitoring.metadata[0].name}.svc.cluster.local:9090"
              access    = "proxy"
              isDefault = true
            },
            {
              name   = "Loki"
              type   = "loki"
              url    = "http://loki.${kubernetes_namespace.logging.metadata[0].name}.svc.cluster.local:3100"
              access = "proxy"
            }
          ]
        }
      }

      alerting = {
        "rules.yml" = {
          apiVersion = 1
          groups = [

          ]

        }

        "contactpoints.yaml" = {
          apiVersion = 1
          contactPoints = [
            {
              orgId = 1
              name  = "cp_1"
              receivers = [
                {
                  uid  = "pd_uid"
                  type = "pagerduty"
                  settings = {
                    integrationKey = var.pagerduty_integration_key
                    severity       = "critical"
                    class          = "general escalations"
                    component      = "Grafana"
                    group          = "kube-ecosystem-stack"
                    summary        = "{{ `{{ include \"default.message\" . }}` }}"
                  }
                }
              ]
            }
          ]
        }
        # Notification Policies
        "policies.yml" = {
          apiVersion = 1
          policies = [
            {
              orgId           = 1
              receiver        = "pagerduty"
              group_by        = ["grafana_folder", "alertname"]
              group_wait      = "10s"
              group_interval  = "10s"
              repeat_interval = "12h"
              routes = [
                {
                  receiver = "pagerduty"
                  object_matchers = [
                    ["severity", "=", "critical"]
                  ]
                  continue = false
                },
                {
                  receiver = "pagerduty"
                  object_matchers = [
                    ["severity", "=", "warning"]
                  ]
                  group_wait      = "30s"
                  repeat_interval = "24h"
                  continue        = false
                }
              ]
            }
          ]
        }
      }


      # Unified Alerting Configuration
      "grafana.ini" = {
        unified_alerting = {
          enabled = true
        }
      }

      # Resource limits
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
    kubernetes_namespace.monitoring,
    kubernetes_namespace.logging,
    helm_release.prometheus,
    helm_release.loki,
    kubernetes_secret.grafana_auth
  ]

  timeout = 300
  wait    = true
}
# Grafana Ingress for external access on grafana.localhost
resource "kubernetes_ingress_v1" "grafana" {
  metadata {
    name      = "grafana"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
    }
  }

  spec {
    ingress_class_name = "nginx"

    rule {
      host = "grafana.localhost"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "grafana"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    helm_release.grafana
  ]
}

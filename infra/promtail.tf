# Promtail deployment for log collection

resource "helm_release" "promtail" {
  name       = "promtail"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "promtail"
  version    = "6.16.6"
  namespace  = kubernetes_namespace.logging.metadata[0].name

  values = [
    yamlencode({
      # Configuration to send logs to Loki
      config = {
        clients = [
          {
            url = "http://loki.${kubernetes_namespace.logging.metadata[0].name}.svc.cluster.local:3100/loki/api/v1/push"
          }
        ]
      }

      # DaemonSet deployment to collect logs from all nodes
      daemonset = {
        enabled = true
      }
    })
  ]

  depends_on = [
    kubernetes_namespace.logging,
    helm_release.loki
  ]

  timeout = 300
  wait    = true
}
# Kubernetes Secrets for secure credential management

# MongoDB authentication secrets
resource "kubernetes_secret" "mongodb_auth" {
  metadata {
    name      = "mongodb-auth"
    namespace = kubernetes_namespace.database.metadata[0].name
    labels = {
      app        = "mongodb"
      managed-by = "terraform"
    }
  }

  data = {
    mongodb-root-password = base64encode(var.mongodb_root_password)
    mongodb-users = base64encode(var.mongodb_username)
    mongodb-passwords = base64encode(var.mongodb_password)
  }

  type = "Opaque"
}

# Grafana admin secrets
resource "kubernetes_secret" "grafana_auth" {
  metadata {
    name      = "grafana-auth"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels = {
      app        = "grafana"
      managed-by = "terraform"
    }
  }

  data = {
    admin-user = base64encode(var.grafana_admin_username)
    admin-password = base64encode(var.grafana_admin_password)
  }

  type = "Opaque"
}
# Kubernetes Secrets for secure credential management

# MongoDB authentication secrets
resource "kubernetes_secret" "mongodb_auth" {
  for_each = {
    database : kubernetes_namespace.database.metadata[0].name
    app : kubernetes_namespace.application.metadata[0].name
  }


  metadata {
    name      = "mongodb-auth-v2"
    namespace = each.value
    labels = {
      app        = each.key
      managed-by = "terraform"
    }
  }

  data = {
    mongodb-root-username = base64encode(var.mongodb_root_username)
    mongodb-root-password = base64encode(var.mongodb_root_password)
    mongodb-username = base64encode(var.mongodb_username)
    mongodb-password = base64encode(var.mongodb_password)
    mongodb-database = base64encode(var.mongodb_database)
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
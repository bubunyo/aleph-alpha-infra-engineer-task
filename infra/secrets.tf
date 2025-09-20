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
    mongodb-root-username = base64encode(var.mongodb_root_username)
    mongodb-root-password = base64encode(var.mongodb_root_password)
    mongodb-username = base64encode(var.mongodb_username)
    mongodb-password = base64encode(var.mongodb_password)
    mongodb-database = base64encode(var.mongodb_database)
  }

  type = "Opaque"
}

# MongoDB authentication secrets for application namespace (backend access)
resource "kubernetes_secret" "mongodb_auth_app" {
  metadata {
    name      = "mongodb-auth"
    namespace = kubernetes_namespace.application.metadata[0].name
    labels = {
      app        = "guestbook-backend"
      managed-by = "terraform"
    }
  }

  data = {
    mongodb-root-username = base64encode(var.mongodb_root_username)
    mongodb-root-password = base64encode(var.mongodb_root_password)
    mongodb-username      = base64encode(var.mongodb_username)
    mongodb-password      = base64encode(var.mongodb_password)
    mongodb-database      = base64encode(var.mongodb_database)
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
# Kubernetes Secrets for secure credential management

# MongoDB authentication secrets
resource "kubernetes_secret" "mongodb_auth" {
  for_each = {
    database : kubernetes_namespace.database.metadata[0].name
    app : kubernetes_namespace.application.metadata[0].name
  }


  metadata {
    name      = "mongodb-auth"
    namespace = each.value
    labels = {
      app        = each.key
      managed-by = "terraform"
    }
  }

  data = {
    mongodb-root-username = var.mongodb_root_username
    mongodb-root-password = var.mongodb_root_password
    mongodb-username      = var.mongodb_username
    mongodb-password      = var.mongodb_password
    mongodb-database      = var.mongodb_database
    mongodb-connection = "${var.mongodb_username}:${var.mongodb_password}@mongodb.${local.mongodb_ns}.svc.cluster.local:${local.mongodb_cluster_port}"
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
    admin-user     = var.grafana_admin_username
    admin-password = var.grafana_admin_password
  }

  type = "Opaque"
}
# Kubernetes Namespaces for the guestbook application and observability stack

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      name       = "monitoring"
      purpose    = "observability"
      managed-by = "terraform"
    }
  }
}

resource "kubernetes_namespace" "logging" {
  metadata {
    name = "logging"
    labels = {
      name       = "logging"
      purpose    = "observability"
      managed-by = "terraform"
    }
  }
}

resource "kubernetes_namespace" "application" {
  metadata {
    name = "application"
    labels = {
      name       = "application"
      purpose    = "workload"
      managed-by = "terraform"
    }
  }
}

resource "kubernetes_namespace" "database" {
  metadata {
    name = "database"
    labels = {
      name       = "database"
      purpose    = "data"
      managed-by = "terraform"
    }
  }
}
resource "kubernetes_namespace" "cluster_management" {
  metadata {
    name = "cluster-management"
    labels = {
      name       = "kube-dashboard"
      purpose    = "cluster-management"
      managed-by = "terraform"
    }
  }
}

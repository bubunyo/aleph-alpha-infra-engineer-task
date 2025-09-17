terraform {
  required_version = ">= 1.0"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.6.2"
    }
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.0.19"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.5.0"
    }
  }
}

data "local_file" "docker_sock" {
  filename = ".docker_sock"
}

provider "docker" {
  host = trimspace(data.local_file.docker_sock.content)
}
provider "kind" {}

resource "docker_container" "registry" {
  name  = var.registry_name
  image = "registry:2"

  ports {
    internal = 5000
    external = var.registry_port
    ip       = "127.0.0.1"
  }

  restart = "always"
}

resource "kind_cluster" "default" {
  name           = "aa-cluster"
  wait_for_ready = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    containerd_config_patches = [
      <<-EOP
      [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:${var.registry_port}"]
        endpoint = ["http://${var.registry_name}:5000"]
      EOP
    ]

    node {
      role = "control-plane"

      kubeadm_config_patches = [
        <<-EOK
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
        EOK
      ]

      extra_port_mappings {
        container_port = 80
        host_port      = 80
        protocol       = "TCP"
      }

      extra_port_mappings {
        container_port = 443
        host_port      = 443
        protocol       = "TCP"
      }
    }
  }
  depends_on = [docker_container.registry]
}

# Configure providers to use Kind cluster
provider "kubernetes" {
  host                   = kind_cluster.default.endpoint
  client_certificate     = kind_cluster.default.client_certificate
  client_key             = kind_cluster.default.client_key
  cluster_ca_certificate = kind_cluster.default.cluster_ca_certificate
}

resource "null_resource" "connect_registry" {
  depends_on = [kind_cluster.default]

  provisioner "local-exec" {
    command = "docker network connect kind ${var.registry_name} || true"
  }
}

resource "kubernetes_config_map" "local_registry_hosting" {
  depends_on = [kind_cluster.default]

  metadata {
    name      = "local-registry-hosting"
    namespace = "kube-public"
  }
  data = {
    "localRegistryHosting.v1" = <<-EOT
    host: "localhost:${var.registry_port}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
    EOT
  }
}
data "http" "ingress_nginx" {
  url = "https://raw.githubusercontent.com/kubernetes/ingress-nginx/refs/heads/main/deploy/static/provider/kind/deploy.yaml"
}

resource "local_file" "ingress_nginx_yaml" {
  content  = data.http.ingress_nginx.response_body
  filename = "${path.module}/assets/ingress-nginx-deploy.yaml"
}

resource "null_resource" "apply_ingress_nginx" {
  provisioner "local-exec" {
    command = "kubectl apply -f ${local_file.ingress_nginx_yaml.filename}"
  }

  depends_on = [kind_cluster.default, local_file.ingress_nginx_yaml]
}

provider "helm" {
  kubernetes {
    host                   = kind_cluster.default.endpoint
    client_certificate     = kind_cluster.default.client_certificate
    client_key             = kind_cluster.default.client_key
    cluster_ca_certificate = kind_cluster.default.cluster_ca_certificate
  }
}




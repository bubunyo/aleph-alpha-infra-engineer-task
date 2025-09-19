variable "registry_port" {
  description = "Port of the local registry mirror"
  type        = number
  default     = 5000
}

variable "registry_name" {
  description = "Name of the local registry container"
  type        = string
  default     = "registry"
}

# Database secrets
variable "mongodb_root_password" {
  description = "MongoDB application username"
  type        = string
  default     = "root5678"
}

variable "mongodb_username" {
  description = "MongoDB application username"
  type        = string
  default     = "guestbook"
}

variable "mongodb_password" {
  description = "MongoDB application password"
  type        = string
  sensitive   = true
  default     = "guestbook123"
}

variable "mongodb_database" {
  description = "MongoDB database name"
  type        = string
  default     = "guestbook"
}

# Grafana secrets
variable "grafana_admin_username" {
  description = "Grafana admin username"
  type        = string
  sensitive   = true
  default     = "admin"
}
variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
  default     = "admin123"
}
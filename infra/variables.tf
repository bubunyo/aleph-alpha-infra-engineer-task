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
variable "mongodb_root_username" {
  description = "MongoDB application root username"
  type        = string
}
variable "mongodb_root_password" {
  description = "MongoDB application root password"
  type        = string
}

variable "mongodb_username" {
  description = "MongoDB application username"
  type        = string
}

variable "mongodb_password" {
  description = "MongoDB application password"
  type        = string
  sensitive   = true
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

# PagerDuty alerting configuration
variable "pagerduty_integration_key" {
  description = "PagerDuty integration key for alerts"
  type        = string
  sensitive   = true
}
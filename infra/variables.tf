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

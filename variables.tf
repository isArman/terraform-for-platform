variable "location" {
  description = "Hetzner Cloud location for all three K3s nodes"
  type        = string
  default     = "fsn1"
}

variable "server_type" {
  description = "Low-cost x86 instance type for all three K3s nodes"
  type        = string
  default     = "cx22"
}

variable "image" {
  description = "OS image used on every node"
  type        = string
  default     = "ubuntu-24.04"
}

variable "worker_count" {
  description = "Two workers plus one server creates a three-node cluster"
  type        = number
  default     = 2

  validation {
    condition     = var.worker_count >= 1
    error_message = "worker_count must be at least 1."
  }
}

variable "operator_cidr" {
  description = "Only this CIDR can reach SSH and the Kubernetes API"
  type        = string
  default     = "172.86.66.91/32"
}

variable "ssh_public_key_path" {
  description = "Public key installed on every node"
  type        = string
  default     = "/root/.ssh/k3s-lab.pub"
}

variable "project_name" {
  description = "Prefix used for Hetzner resource names and labels"
  type        = string
  default     = "k3s-lab"
}

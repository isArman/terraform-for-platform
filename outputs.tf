output "server_public_ip" {
  description = "Public entry point for SSH, Kubernetes API, and ingress"
  value       = hcloud_server.server.ipv4_address
}

output "server_private_ip" {
  value = local.server_private_ip
}

output "worker_private_ips" {
  value = [
    for i in range(var.worker_count) :
    cidrhost(local.subnet_cidr, local.worker_ip_offset + i)
  ]
}

output "ssh_command" {
  value = "ssh -i ~/.ssh/k3s-lab root@${hcloud_server.server.ipv4_address}"
}

output "kubeconfig_command" {
  value = "./get-kubeconfig.sh"
}

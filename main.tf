locals {
  network_cidr      = "10.20.0.0/16"
  subnet_cidr       = "10.20.0.0/24"
  server_private_ip = "10.20.0.2"
  worker_ip_offset  = 10
  network_zone = {
    fsn1 = "eu-central"
    nbg1 = "eu-central"
    hel1 = "eu-central"
    ash  = "us-east"
    hil  = "us-west"
    sin  = "ap-southeast"
  }[var.location]
}

resource "random_password" "k3s_token" {
  length  = 40
  special = false
}

resource "hcloud_ssh_key" "operator" {
  name       = "${var.project_name}-operator"
  public_key = file(var.ssh_public_key_path)
}

resource "hcloud_network" "lab" {
  name     = "${var.project_name}-net"
  ip_range = local.network_cidr
  labels = {
    project = var.project_name
  }
}

resource "hcloud_network_subnet" "lab" {
  network_id   = hcloud_network.lab.id
  type         = "cloud"
  network_zone = local.network_zone
  ip_range     = local.subnet_cidr
}

resource "hcloud_firewall" "server" {
  name = "${var.project_name}-server"
  labels = {
    project = var.project_name
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = [var.operator_cidr]
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "6443"
    source_ips = [var.operator_cidr]
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = [var.operator_cidr]
  }
}

resource "hcloud_server" "server" {
  name        = "${var.project_name}-server"
  server_type = var.server_type
  image       = var.image
  location    = var.location
  ssh_keys     = [hcloud_ssh_key.operator.id]
  firewall_ids = [hcloud_firewall.server.id]
  user_data = templatefile("${path.module}/server-user-data.tftpl", {
    token        = random_password.k3s_token.result
    node_name    = "k3s-server"
    private_ip   = local.server_private_ip
    network_cidr = local.network_cidr
  })

  labels = {
    project = var.project_name
    role    = "server"
  }

  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }

  network {
    network_id = hcloud_network.lab.id
    ip         = local.server_private_ip
  }

  depends_on = [hcloud_network_subnet.lab]
}

resource "hcloud_network_route" "default_via_server" {
  network_id  = hcloud_network.lab.id
  destination = "0.0.0.0/0"
  gateway     = local.server_private_ip
}

resource "hcloud_server" "worker" {
  count = var.worker_count

  name        = "${var.project_name}-worker-${count.index + 1}"
  server_type = var.server_type
  image       = var.image
  location    = var.location
  ssh_keys    = [hcloud_ssh_key.operator.id]
  user_data = templatefile("${path.module}/agent-user-data.tftpl", {
    token      = random_password.k3s_token.result
    node_name  = "k3s-worker-${count.index + 1}"
    private_ip = cidrhost(local.subnet_cidr, local.worker_ip_offset + count.index)
    gateway    = cidrhost(local.subnet_cidr, 1)
    server_url = "https://${local.server_private_ip}:6443"
  })

  labels = {
    project = var.project_name
    role    = "worker"
  }

  public_net {
    ipv4_enabled = false
    ipv6_enabled = false
  }

  network {
    network_id = hcloud_network.lab.id
    ip         = cidrhost(local.subnet_cidr, local.worker_ip_offset + count.index)
  }

  depends_on = [
    hcloud_network_subnet.lab,
    hcloud_network_route.default_via_server,
    hcloud_server.server,
  ]
}

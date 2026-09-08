# Three-node K3s lab on Hetzner Cloud

Disposable Kubernetes cluster for platform-engineering practice:

- 1 K3s server/control-plane with a public IPv4
- 2 private K3s workers (no public IP)
- `cx23` in `fsn1` (Falkenstein)
- A Hetzner network route `0.0.0.0/0` via the server, plus NAT, so private workers can pull images
- The server NATs workers so they can pull images without extra IPv4 addresses
- SSH and Kubernetes API restricted to `operator_cidr`
- HTTP/HTTPS open for ingress experiments

This is a learning cluster, not production. The control-plane is not highly
available, and `terraform destroy` removes cluster data.

Terraform talks to the Hetzner Cloud API with `HCLOUD_TOKEN`. Create a Read & Write
token in the Cloud Console under **Security → API Tokens**, then put it in `.env`.

## Up

On the operator host (`172.86.66.91`):

```bash
cd ~/Desktop/terraform-for-platform
# edit .env and set HCLOUD_TOKEN=...
./up.sh
export KUBECONFIG="$HOME/.kube/k3s-hetzner.yaml"
kubectl get nodes -o wide
```

Review the Terraform plan and type `yes`.

Optional ingress-nginx:

```bash
./bootstrap-cluster.sh
```

## Down

```bash
cd ~/Desktop/terraform-for-platform
./down.sh
```

Review the destroy plan and type `yes`. The next `./up.sh` creates a clean cluster.

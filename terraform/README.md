# QuakeWatch – Terraform + k3s on AWS

## Prerequisites
| Tool | Minimum version |
|------|----------------|
| Terraform | 1.3+ |
| AWS CLI | v2 (configured with valid credentials) |
| SSH key pair | `~/.ssh/id_rsa.pub` (or change `public_key_path`) |

---

## Quick start

```bash
# 1 – Enter the project directory
cd terraform/

# 2 – Initialise providers and modules
terraform init

# 3 – Preview the plan
terraform plan

# 4 – Apply
terraform apply
```

Terraform will auto-detect your public IP via `checkip.amazonaws.com` and scope the security-group rules to that address only.

---

## Key outputs after apply

| Output | Description |
|--------|-------------|
| `instance_public_ip` | Elastic IP of the k3s node |
| `ssh_command` | Ready-made SSH command |
| `kubeconfig_command` | Fetch & adapt kubeconfig locally |
| `my_detected_ip` | The IP that was allow-listed |

---

## Connecting after boot (~3–5 min)

```bash
# SSH in
ssh ec2-user@<instance_public_ip>

# Check bootstrap log
sudo tail -f /var/log/userdata.log

# Check k3s nodes
kubectl get nodes -o wide

# Check QuakeWatch pods
kubectl get pods -n quakewatch
```

### Fetch kubeconfig locally
```bash
$(terraform output -raw kubeconfig_command)
export KUBECONFIG=~/.kube/quakewatch-k3s.yaml
kubectl get nodes
```

---

## Customising variables

Override any variable in `terraform.tfvars`:

```hcl
aws_region      = "eu-west-1"
instance_type   = "t3.large"
public_key_path = "~/.ssh/my-aws-key.pub"
```

---

## Teardown

```bash
terraform destroy
```

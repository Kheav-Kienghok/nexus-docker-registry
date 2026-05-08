# Nexus Docker Registry

Automated deployment of **Sonatype Nexus 3** on AWS EC2 using Terraform and Ansible.

Nexus is configured with three Docker repositories:

| Repo | Port | Purpose |
|---|---|---|
| docker-hosted | 5000 | Store private images |
| docker-proxy | 5001 | Cache Docker Hub images |
| docker-group | 5002 | Single endpoint for push + pull |

---

## Prerequisites

- Terraform >= 1.5
- Ansible >= 2.14
- AWS CLI configured (`aws configure`)
- An EC2 key pair created in your AWS account

---

## Setup

**1. Fill in your variables**

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
key_name             = "your-key-pair-name"
ssh_private_key_path = "~/.ssh/your-key.pem"
```

**2. Deploy everything**

```bash
make all
```

This runs Terraform to create the EC2 instance, then Ansible to install Docker and start Nexus. At the end, the playbook prints your server IP and initial admin password.

---

## Makefile Commands

| Command | Description |
|---|---|
| `make all` | Full deploy: provision + configure |
| `make provision` | Terraform only — create EC2 instance |
| `make configure` | Ansible only — install Docker + start Nexus |
| `make plan` | Preview Terraform changes |
| `make output` | Show server IP and URLs |
| `make destroy` | Tear down all AWS resources |

---

## After Deployment

**1. Create repositories in Nexus UI** at `http://<server-ip>:8081`

Log in with `admin` and the printed password, then create three repositories:

- `docker (hosted)` → name: `docker-hosted`, HTTP port: `5000`
- `docker (proxy)` → name: `docker-proxy`, remote: `https://registry-1.docker.io`, HTTP port: `5001`
- `docker (group)` → name: `docker-group`, HTTP port: `5002`, members: hosted + proxy

**2. Configure your local Docker client**

Add the server IP to insecure registries in `/etc/docker/daemon.json`:

```json
{ "insecure-registries": ["<server-ip>:5002"] }
```

```bash
sudo systemctl restart docker
```

**3. Pull and push**

```bash
# Pull from Docker Hub via Nexus cache
docker pull <server-ip>:5002/library/nginx:latest

# Push a private image
docker tag myapp:1.0 <server-ip>:5002/myapp:1.0
docker push <server-ip>:5002/myapp:1.0
```

---

## Teardown

```bash
make destroy
```

---

## Common Errors

| Error | Fix |
|---|---|
| `http: server gave HTTP response to HTTPS client` | Add server IP to `insecure-registries` and restart Docker |
| `connection reset by peer` on port 5002 | HTTP connector not set in Nexus repo — enable HTTP port in repository settings |
| `library/nginx not found` | Use the `/library/` prefix: `docker pull <ip>:5002/library/nginx:latest` |

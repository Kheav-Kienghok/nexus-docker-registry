# Nexus Docker Registry (Hosted + Proxy Cache + Group)

This guide sets up **Sonatype Nexus Repository Manager 3** as a Docker registry with:

- **docker-hosted** → private registry (your own images)
- **docker-proxy** → Docker Hub caching proxy (faster pulls, avoids rate limits)
- **docker-group** → single endpoint combining both (best practice)

---

## Folder Structure

nexus-docker-registry/
│
├── README.md
├── docker-compose.yml
└── config/
    └── daemon.json.example

---

## Requirements

- Docker
- Docker Compose

---

# 1. Start Nexus

Run:

docker compose up -d

Verify Nexus is running:

docker ps

Nexus UI will be available at:

http://localhost:8081

---

# 2. Get the Admin Password

Default username is:

admin

To get the default password:

docker exec nexus cat /nexus-data/admin.password

Login to Nexus at:

http://localhost:8081

After login, Nexus forces you to change the password.

---

# 3. Create Docker Hosted Repo (Private Registry)

Go to:

Settings (⚙️) → Repositories → Create repository → docker (hosted)

Set:

- Name: docker-hosted
- HTTP Port: 5000
- Enable HTTP: YES
- Deployment policy: Allow redeploy (optional but recommended for testing)

Click Create repository.

This repo stores your internal/private Docker images.

---

# 4. Create Docker Proxy Repo (Docker Hub Cache)

Go to:

Settings (⚙️) → Repositories → Create repository → docker (proxy)

Set:

- Name: docker-proxy
- Remote storage URL: https://registry-1.docker.io
- Docker Index: Use Docker Hub
- HTTP Port: 5001
- Enable HTTP: YES

Click Create repository.

This repo caches Docker Hub images like nginx, redis, node, etc.

---

# 5. Create Docker Group Repo (Best Practice)

Go to:

Settings (⚙️) → Repositories → Create repository → docker (group)

Set:

- Name: docker-group
- HTTP Port: 5002
- Enable HTTP: YES

Under Group members, add repositories in this order:

1. docker-hosted
2. docker-proxy

Click Create repository.

This creates ONE endpoint for both pushing + pulling:

localhost:5002

---

# 6. Configure Docker to Allow Nexus (Insecure Registry)

Docker blocks HTTP registries by default.
Since this setup uses HTTP, you must allow it.

---

## Linux Setup

Edit Docker config:

sudo nano /etc/docker/daemon.json

Add:

{
  "insecure-registries": ["localhost:5002"]
}

Restart Docker:

sudo systemctl restart docker

---

## Mac / Windows (Docker Desktop)

Go to:

Docker Desktop → Settings → Docker Engine

Add:

{
  "insecure-registries": ["localhost:5002"]
}

Restart Docker Desktop.

---

# 7. Test Docker Hub Proxy Caching

Pull nginx through Nexus group registry:

docker pull localhost:5002/nginx:latest

If that fails, try the "official image" path:

docker pull localhost:5002/library/nginx:latest

Pull again (should be much faster because it is cached):

docker pull localhost:5002/nginx:latest

Verify caching in Nexus UI:

Browse → docker-proxy → nginx

---

# 8. Push Your Own Image (Private Hosted Repo)

Create a test Dockerfile:

FROM alpine:latest
CMD ["echo", "hello from nexus"]

Build:

docker build -t myapp:1.0 .

Tag for Nexus group registry:

docker tag myapp:1.0 localhost:5002/myapp:1.0

Push:

docker push localhost:5002/myapp:1.0

Verify in Nexus UI:

Browse → docker-hosted → myapp

---

# 9. Pull Your Private Image

Remove local copy:

docker rmi localhost:5002/myapp:1.0

Pull again:

docker pull localhost:5002/myapp:1.0

If it works, Nexus is correctly storing and serving your private images.

---

# 10. Why Docker Group Repo is the Best Setup

With a Docker Group repo:

- Pulls like nginx go through docker-proxy (cached from Docker Hub)
- Pushes like myapp go into docker-hosted (stored internally)
- Developers only configure ONE registry endpoint (localhost:5002)

This is the standard setup used in real teams.

---

# Common Errors / Fixes

## Error: http: server gave HTTP response to HTTPS client

Docker is trying HTTPS by default.

Fix:
- Ensure Docker daemon config includes: { "insecure-registries": ["localhost:5002"] }
- Restart Docker.

---

## Error: nginx not found

Some official images require /library/ prefix:

docker pull localhost:5002/library/nginx:latest

---

# Useful Ports

- Nexus UI: http://localhost:8081
- Docker Hosted Repo: localhost:5000
- Docker Proxy Repo: localhost:5001
- Docker Group Repo: localhost:5002

---

# Summary

Your final Docker registry endpoint is:

localhost:5002

Use it like:

Pull public images (cached):

docker pull localhost:5002/nginx:latest

Push private images:

docker tag myapp:1.0 localhost:5002/myapp:1.0
docker push localhost:5002/myapp:1.0

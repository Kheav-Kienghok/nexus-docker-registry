terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ──────────────────────────────────────────
# Latest Ubuntu 22.04 LTS AMI
# ──────────────────────────────────────────
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# ──────────────────────────────────────────
# SSH Key Pair (auto-generated)
# ──────────────────────────────────────────
resource "tls_private_key" "nexus" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "nexus" {
  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.nexus.public_key_openssh

  tags = {
    Name    = "${var.project_name}-key"
    Project = var.project_name
  }
}

resource "local_sensitive_file" "private_key" {
  filename        = "${path.module}/../secrets/${var.project_name}.pem"
  content         = tls_private_key.nexus.private_key_pem
  file_permission = "0600"
}

# ──────────────────────────────────────────
# Security Group
# ──────────────────────────────────────────
resource "aws_security_group" "nexus" {
  name        = "${var.project_name}-sg"
  description = "Allow SSH, Nexus UI, and Docker registry ports"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  ingress {
    description = "Nexus UI"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  ingress {
    description = "Docker Hosted Registry"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  ingress {
    description = "Docker Proxy Registry"
    from_port   = 5001
    to_port     = 5001
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  ingress {
    description = "Docker Group Registry"
    from_port   = 5002
    to_port     = 5002
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-sg"
    Project = var.project_name
  }
}

# ──────────────────────────────────────────
# EC2 Instance
# ──────────────────────────────────────────
resource "aws_instance" "nexus" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.nexus.key_name
  vpc_security_group_ids = [aws_security_group.nexus.id]

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
  }

  tags = {
    Name    = var.project_name
    Project = var.project_name
  }
}

# ──────────────────────────────────────────
# Wait for Cloud-Init to complete
# ──────────────────────────────────────────
resource "null_resource" "wait_cloud_init" {
  depends_on = [aws_instance.nexus, local_sensitive_file.private_key]

  connection {
    type        = "ssh"
    host        = aws_instance.nexus.public_ip
    user        = "ubuntu"
    private_key = tls_private_key.nexus.private_key_pem
    timeout     = "10m"

    # Skip host key verification on first login
    agent = false
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for cloud-init to complete...'",
      "cloud-init status --wait",
      "echo 'Cloud-init complete.'",
    ]
  }
}

# ──────────────────────────────────────────
# Dynamic Ansible Inventory
# ──────────────────────────────────────────
resource "local_file" "ansible_inventory" {
  depends_on = [null_resource.wait_cloud_init]
  filename   = "${path.module}/../ansible/inventory/hosts.ini"
  content    = <<-EOT
    [nexus]
    ${aws_instance.nexus.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=${local_sensitive_file.private_key.filename} ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
  EOT
}

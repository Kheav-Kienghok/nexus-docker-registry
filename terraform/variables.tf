variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Name tag applied to all resources"
  type        = string
  default     = "nexus-docker-registry"
}

variable "ami_id" {
  description = "Ubuntu 22.04 LTS AMI ID (region-specific)"
  type        = string
  # ap-southeast-1 Ubuntu 22.04 LTS
  default = "ami-0df7a207adb9748c7"
}

variable "instance_type" {
  description = "EC2 instance type — Nexus needs at least 4 GB RAM"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "Name of the existing AWS EC2 key pair"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Local path to the private key file (.pem) for Ansible SSH"
  type        = string
}

variable "allowed_cidr" {
  description = "CIDR allowed to reach Nexus ports (use your IP for security)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "root_volume_size" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 30
}

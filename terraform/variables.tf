variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name tag applied to all resources"
  type        = string
  default     = "nexus-docker-registry"
}

variable "instance_type" {
  description = "EC2 instance type — Nexus needs at least 4 GB RAM"
  type        = string
  default     = "t3.medium"
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

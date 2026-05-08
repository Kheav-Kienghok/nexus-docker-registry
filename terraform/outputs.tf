output "instance_public_ip" {
  description = "Public IP of the Nexus server"
  value       = aws_instance.nexus.public_ip
}

output "nexus_ui_url" {
  description = "URL to access Nexus UI"
  value       = "http://${aws_instance.nexus.public_ip}:8081"
}

output "docker_group_registry" {
  description = "Docker group registry endpoint"
  value       = "${aws_instance.nexus.public_ip}:5002"
}

output "docker_hosted_registry" {
  description = "Docker hosted registry endpoint"
  value       = "${aws_instance.nexus.public_ip}:5000"
}

output "docker_proxy_registry" {
  description = "Docker proxy registry endpoint"
  value       = "${aws_instance.nexus.public_ip}:5001"
}

output "ssh_command" {
  description = "SSH command to connect to the server"
  value       = "ssh -i ${var.ssh_private_key_path} ubuntu@${aws_instance.nexus.public_ip}"
}

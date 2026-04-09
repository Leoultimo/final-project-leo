output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnets
}

output "security_group_id" {
  description = "ID of the k3s security group"
  value       = aws_security_group.k3s.id
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.k3s.id
}

output "instance_public_ip" {
  description = "Elastic IP address assigned to the k3s node"
  value       = aws_eip.k3s.public_ip
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh ec2-user@${aws_eip.k3s.public_ip}"
}

output "kubeconfig_command" {
  description = "Command to fetch the kubeconfig from the node"
  value       = "ssh ec2-user@${aws_eip.k3s.public_ip} 'sudo cat /etc/rancher/k3s/k3s.yaml' | sed 's/127.0.0.1/${aws_eip.k3s.public_ip}/g' > ~/.kube/quakewatch-k3s.yaml"
}

output "my_detected_ip" {
  description = "Public IP that was auto-detected and added to the security group"
  value       = local.my_ip_cidr
}

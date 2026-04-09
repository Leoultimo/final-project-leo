variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix applied to every resource name"
  type        = string
  default     = "quakewatch"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "instance_type" {
  description = "EC2 instance type for the k3s node"
  type        = string
  default     = "t3.medium"   # 2 vCPU / 4 GiB – good baseline for a single-node k3s
}

variable "public_key_path" {
  description = "Path to your SSH public key file. Leave empty to skip key-pair creation."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "helm_chart_repo" {
  description = "Git repository containing the QuakeWatch Helm chart"
  type        = string
  default     = "https://github.com/Leoultimo/final-project-leo.git"
}

variable "common_tags" {
  description = "Tags applied to every resource"
  type        = map(string)
  default = {
    Project     = "QuakeWatch"
    ManagedBy   = "Terraform"
    Environment = "dev"
  }
}

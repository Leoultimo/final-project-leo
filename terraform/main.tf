terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ──────────────────────────────────────────────
# Fetch caller's public IP automatically
# ──────────────────────────────────────────────
data "http" "my_public_ip" {
  url = "https://checkip.amazonaws.com/"
}

locals {
  my_ip_cidr = "${chomp(data.http.my_public_ip.response_body)}/32"
}

# ──────────────────────────────────────────────
# VPC  (community module)
# ──────────────────────────────────────────────
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  public_subnets  = var.public_subnet_cidrs
  private_subnets = var.private_subnet_cidrs

  enable_nat_gateway   = false   # keep costs low for a single-node cluster
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = var.common_tags
}

# ──────────────────────────────────────────────
# Security Group
# ──────────────────────────────────────────────
resource "aws_security_group" "k3s" {
  name        = "${var.project_name}-k3s-sg"
  description = "Security group for k3s single-node cluster"
  vpc_id      = module.vpc.vpc_id

  # HTTP – your public IP only
  ingress {
    description = "HTTP from my IP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [local.my_ip_cidr]
  }

  # HTTPS – your public IP only
  ingress {
    description = "HTTPS from my IP"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [local.my_ip_cidr]
  }

  # SSH – your public IP only
  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.my_ip_cidr]
  }

  # k3s API server – your public IP only
  ingress {
    description = "k3s API server from my IP"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [local.my_ip_cidr]
  }

  # NodePort range – your public IP only (optional, useful for testing)
  ingress {
    description = "NodePort services from my IP"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = [local.my_ip_cidr]
  }

  # Allow all outbound traffic
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "${var.project_name}-k3s-sg" })
}

# ──────────────────────────────────────────────
# Latest Amazon Linux 2023 AMI
# ──────────────────────────────────────────────
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ──────────────────────────────────────────────
# EC2 Key Pair  (optional – skip if you pass "" )
# ──────────────────────────────────────────────
resource "aws_key_pair" "k3s" {
  count      = var.public_key_path != "" ? 1 : 0
  key_name   = "${var.project_name}-key"
  public_key = file(var.public_key_path)
  tags       = var.common_tags
}

# ──────────────────────────────────────────────
# EC2 Instance
# ──────────────────────────────────────────────
resource "aws_instance" "k3s" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.k3s.id]
  associate_public_ip_address = true
  key_name                    = var.public_key_path != "" ? aws_key_pair.k3s[0].key_name : null

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  user_data = templatefile("${path.module}/userdata.sh", {
    helm_chart_repo = var.helm_chart_repo
  })

  user_data_replace_on_change = true

  tags = merge(var.common_tags, { Name = "${var.project_name}-k3s-node" })
}

# ──────────────────────────────────────────────
# Elastic IP  (stable public address)
# ──────────────────────────────────────────────
resource "aws_eip" "k3s" {
  instance = aws_instance.k3s.id
  domain   = "vpc"
  tags     = merge(var.common_tags, { Name = "${var.project_name}-eip" })
}

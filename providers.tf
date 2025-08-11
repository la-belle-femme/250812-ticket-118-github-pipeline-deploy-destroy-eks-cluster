terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Backend configuration will be added dynamically by GitHub Actions
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = merge(var.tags, {
      Environment   = "development"
      Project       = "EKS-GitHub-Actions"
      ManagedBy     = "Terraform"
      Repository    = var.github_repo
    })
  }
}

# Data sources for existing VPC resources
data "aws_vpc" "existing" {
  id = var.vpc_id
}

data "aws_subnets" "existing" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  
  filter {
    name   = "subnet-id"
    values = var.subnet_ids
  }
}

data "aws_subnet" "existing" {
  for_each = toset(var.subnet_ids)
  id       = each.value
}

# Force a new random suffix to ensure we get updated permissions
resource "random_id" "bucket_suffix" {
  byte_length = 4
  
  keepers = {
    # Changed this to force recreation with new permissions
    timestamp = "2025-08-12-v3"
  }
}

# Use existing GitHub OIDC Provider (data source only - no creation)
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# IAM Role for GitHub Actions (short unique name to avoid conflicts)
resource "aws_iam_role" "github_actions" {
  name = "eks-gh-actions-${random_id.bucket_suffix.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
          }
        }
      }
    ]
  })

  tags = {
    Name      = "eks-gh-actions-${random_id.bucket_suffix.hex}"
    Project   = "eks-cluster"
    ManagedBy = "terraform"
  }
}

# UPDATED IAM Policy for GitHub Actions - Terraform State Management with CREATE permissions
resource "aws_iam_policy" "github_actions_terraform" {
  name        = "eks-tf-state-${random_id.bucket_suffix.hex}"
  description = "Policy for GitHub Actions to manage Terraform state with CREATE permissions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # S3 bucket creation and management
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:GetBucketLocation",
          "s3:GetBucketVersioning",
          "s3:PutBucketVersioning",
          "s3:GetBucketEncryption",
          "s3:PutBucketEncryption",
          "s3:GetBucketPublicAccessBlock",
          "s3:PutBucketPublicAccessBlock",
          "s3:GetBucketTagging",
          "s3:PutBucketTagging",
          "s3:GetBucketAcl",
          "s3:PutBucketAcl",
          "s3:GetBucketCORS",
          "s3:PutBucketCORS",
          "s3:GetBucketWebsite",
          "s3:PutBucketWebsite",
          "s3:GetBucketLogging",
          "s3:PutBucketLogging",
          # S3 object operations
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::eks-tfstate-*",
          "arn:aws:s3:::eks-tfstate-*/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          # DynamoDB table creation and management
          "dynamodb:CreateTable",
          "dynamodb:DeleteTable",
          "dynamodb:DescribeTable",
          "dynamodb:UpdateTable",
          "dynamodb:TagResource",
          "dynamodb:UntagResource",
          "dynamodb:ListTagsOfResource",
          "dynamodb:DescribeTimeToLive",
          "dynamodb:UpdateTimeToLive",
          # DynamoDB operations for state locking
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:UpdateItem"
        ]
        Resource = [
          "arn:aws:dynamodb:*:*:table/eks-tfstate-locks-*"
        ]
      }
    ]
  })

  tags = {
    Name      = "eks-tf-state-${random_id.bucket_suffix.hex}"
    ManagedBy = "terraform"
  }
}

# IAM Policy for GitHub Actions - EKS Management
resource "aws_iam_policy" "github_actions_eks" {
  name        = "eks-mgmt-${random_id.bucket_suffix.hex}"
  description = "Comprehensive policy for GitHub Actions to manage EKS resources"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:*",
          "ec2:*",
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:ListRoles",
          "iam:UpdateRole",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:GetPolicy",
          "iam:ListPolicies",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:PassRole",
          "iam:CreateOpenIDConnectProvider",
          "iam:GetOpenIDConnectProvider",
          "iam:ListOpenIDConnectProviders",
          "iam:TagOpenIDConnectProvider",
          "logs:*",
          "cloudwatch:*",
          "autoscaling:*",
          "elasticloadbalancing:*",
          "ecr:*",
          "sts:GetCallerIdentity",
          "kms:CreateGrant",
          "kms:DescribeKey",
          "kms:List*",
          "kms:Get*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "iam:PassedToService" = [
              "eks.amazonaws.com",
              "ec2.amazonaws.com"
            ]
          }
        }
      }
    ]
  })

  tags = {
    Name      = "eks-mgmt-${random_id.bucket_suffix.hex}"
    ManagedBy = "terraform"
  }
}

# Attach Terraform state policy to GitHub Actions role
resource "aws_iam_role_policy_attachment" "github_actions_terraform" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_terraform.arn
}

# Attach EKS management policy to GitHub Actions role
resource "aws_iam_role_policy_attachment" "github_actions_eks" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_eks.arn
}

# Output the GitHub Actions role ARN
output "github_actions_role_arn" {
  description = "ARN of the IAM role for GitHub Actions"
  value       = aws_iam_role.github_actions.arn
}

# Output the OIDC provider ARN  
output "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = data.aws_iam_openid_connect_provider.github.arn
}
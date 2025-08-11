# GitHub OIDC Provider for AWS (creates if doesn't exist)
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  tags = {
    Name        = "github-oidc-provider"
    Environment = "shared"
    ManagedBy   = "terraform"
  }

  lifecycle {
    ignore_changes = [
      thumbprint_list,
      client_id_list
    ]
  }
}

# IAM Role for GitHub Actions (short unique name)
resource "aws_iam_role" "github_actions" {
  name = "eks-gh-actions-${random_id.bucket_suffix.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
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
    Project   = var.cluster_name
    ManagedBy = "terraform"
  }
}

# IAM Policy for GitHub Actions - Terraform State Management
resource "aws_iam_policy" "github_actions_terraform" {
  name        = "eks-tf-state-${random_id.bucket_suffix.hex}"
  description = "Policy for GitHub Actions to manage Terraform state"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketVersioning",
          "s3:GetBucketLocation"
        ]
        Resource = [
          aws_s3_bucket.terraform_state.arn,
          "${aws_s3_bucket.terraform_state.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:DescribeTable"
        ]
        Resource = aws_dynamodb_table.terraform_locks.arn
      }
    ]
  })

  tags = {
    Name      = "eks-tf-state-${random_id.bucket_suffix.hex}"
    Project   = var.cluster_name
    ManagedBy = "terraform"
  }
}

# IAM Policy for GitHub Actions - EKS Management (comprehensive)
resource "aws_iam_policy" "github_actions_eks" {
  name        = "eks-mgmt-${random_id.bucket_suffix.hex}"
  description = "Comprehensive policy for GitHub Actions to manage EKS resources"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # EKS permissions
          "eks:*",
          
          # EC2 permissions for EKS
          "ec2:*",
          
          # IAM permissions for EKS roles
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
          
          # CloudWatch Logs
          "logs:*",
          
          # CloudWatch
          "cloudwatch:*",
          
          # Auto Scaling
          "autoscaling:*",
          
          # Elastic Load Balancing
          "elasticloadbalancing:*",
          
          # ECR
          "ecr:*",
          
          # STS
          "sts:GetCallerIdentity",
          
          # KMS
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
    Project   = var.cluster_name
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
  value       = aws_iam_openid_connect_provider.github.arn
}
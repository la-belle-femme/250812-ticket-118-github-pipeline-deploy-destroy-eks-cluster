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
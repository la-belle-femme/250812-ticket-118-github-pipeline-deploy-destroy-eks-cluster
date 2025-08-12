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
          # DynamoDB operations for state locking
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:UpdateItem"
        ]
        Resource = [
          "arn:aws:dynamodb:*:855978188999:table/eks-tfstate-locks-*"
        ]
      }
    ]
  })

  tags = {
    Name      = "eks-tf-state-${random_id.bucket_suffix.hex}"
    ManagedBy = "terraform"
  }
}
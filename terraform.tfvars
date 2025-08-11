aws_region                = "us-east-1"
vpc_id                    = "vpc-0b29462da246e0151"
subnet_ids                = ["subnet-08a96a34702e19938", "subnet-0c171df46bf5e3e2f", "subnet-0325b03933424daa3"]
cluster_name              = "250812-ticket-118-github-action-eks-cluster"
cluster_version           = "1.30"
instance_types            = ["t3.medium"]
desired_size              = 2
min_size                  = 2
max_size                  = 3
key_pair_name             = "terraform-offert-letter-key"
enabled_cluster_log_types = ["api", "audit"]
github_repo               = "250812-ticket-118-github-pipeline-deploy-destroy-eks-cluster"
github_org                = "la-belle-femme"

tags = {
  Environment = "development"
  Owner       = "DevOps-Team"
  Purpose     = "EKS-Testing"
}
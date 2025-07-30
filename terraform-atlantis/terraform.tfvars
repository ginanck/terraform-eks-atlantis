# AWS Configuration
aws_region = "eu-central-1"
project_name = "atlantis-eks"
environment = "dev"

# EKS Cluster Configuration
cluster_name = "atlantis-eks-eks-cluster"  # This should match the output from infrastructure deployment

# GitHub Configuration for Atlantis
github_user = "your-github-username"
github_token = "ghp_xxxxxxxxxxxxxxxxxxxx"  # GitHub Personal Access Token
github_webhook_secret = "your-random-webhook-secret"
github_repo_allowlist = "github.com/your-github-username/*"

# Atlantis Configuration
atlantis_version = "4.18.0"
atlantis_replica_count = 1
atlantis_storage_size = "10Gi"
atlantis_storage_class = "gp2"

# Optional: Custom domain for Atlantis
# atlantis_hostname = "atlantis.yourdomain.com"

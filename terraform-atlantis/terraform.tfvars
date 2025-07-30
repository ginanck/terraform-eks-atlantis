# Project Configuration
project_name = "atlantis"
environment = "dev"

# GitHub Configuration for Atlantis
github_user = "gkorkmaz"
github_repo_allowlist = "github.com/ginanck/terraform-eks-atlantis"

# GitHub credentials are injected via environment variables:
# - TF_VAR_github_token (Personal Access Token)
# - TF_VAR_github_webhook_secret

# Atlantis Configuration
atlantis_version = "5.18.0"
atlantis_replica_count = 1
atlantis_storage_size = "10Gi"
atlantis_storage_class = "gp2"

# Optional: Custom domain for Atlantis
# atlantis_hostname = "atlantis.yourdomain.com"

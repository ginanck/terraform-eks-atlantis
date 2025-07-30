variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "atlantis"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "github_user" {
  description = "GitHub username for Atlantis"
  type        = string
}

variable "github_token" {
  description = "GitHub token for Atlantis"
  type        = string
  sensitive   = true
}

variable "github_webhook_secret" {
  description = "GitHub webhook secret for Atlantis"
  type        = string
  sensitive   = true
}

variable "github_repo_allowlist" {
  description = "GitHub repository allowlist for Atlantis (e.g., github.com/username/*)"
  type        = string
}

variable "atlantis_hostname" {
  description = "Hostname for Atlantis (if using custom domain)"
  type        = string
  default     = ""
}

variable "atlantis_version" {
  description = "Atlantis Helm chart version"
  type        = string
  default     = "4.18.0"
}

variable "atlantis_replica_count" {
  description = "Number of Atlantis replicas"
  type        = number
  default     = 1
}

variable "atlantis_storage_size" {
  description = "Storage size for Atlantis data volume"
  type        = string
  default     = "10Gi"
}

variable "atlantis_storage_class" {
  description = "Storage class for Atlantis data volume"
  type        = string
  default     = "gp2"
}

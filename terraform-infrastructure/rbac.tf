# Configure the Kubernetes provider
# Note: This depends on the EKS cluster being created first
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

# Create a read-only ClusterRole
resource "kubernetes_cluster_role" "read_only" {
  metadata {
    name = "read-only"
  }

  rule {
    api_groups = [""]
    resources  = ["*"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["*"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["batch"]
    resources  = ["*"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["extensions"]
    resources  = ["*"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["*"]
    verbs      = ["get", "list", "watch"]
  }

  depends_on = [module.eks]
}

# Create ClusterRoleBinding for read-only access
resource "kubernetes_cluster_role_binding" "read_only" {
  metadata {
    name = "read-only"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.read_only.metadata[0].name
  }

  subject {
    kind     = "Group"
    name     = "system:readers"
    api_group = "rbac.authorization.k8s.io"
  }

  depends_on = [kubernetes_cluster_role.read_only]
}

# Namespace for Atlantis
resource "kubernetes_namespace" "atlantis" {
  metadata {
    name = "atlantis"
    labels = {
      name = "atlantis"
      "app.kubernetes.io/name" = "atlantis"
      "app.kubernetes.io/instance" = "atlantis"
    }
  }
}

# Service Account for Atlantis
resource "kubernetes_service_account" "atlantis" {
  metadata {
    name      = "atlantis"
    namespace = kubernetes_namespace.atlantis.metadata[0].name
    labels = {
      "app.kubernetes.io/name" = "atlantis"
      "app.kubernetes.io/instance" = "atlantis"
    }
  }
}

# Secrets will be managed by Helm chart

# RBAC for read-only access
resource "kubernetes_cluster_role" "read_only" {
  metadata {
    name = "atlantis-read-only-role"
    labels = {
      "app.kubernetes.io/name" = "atlantis"
      "app.kubernetes.io/instance" = "atlantis"
    }
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
    api_groups = ["extensions"]
    resources  = ["*"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["*"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "read_only" {
  metadata {
    name = "atlantis-read-only-binding"
    labels = {
      "app.kubernetes.io/name" = "atlantis"
      "app.kubernetes.io/instance" = "atlantis"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.read_only.metadata[0].name
  }

  subject {
    kind      = "Group"
    name      = "system:readers"
    api_group = "rbac.authorization.k8s.io"
  }
}



# Atlantis Helm Release
resource "helm_release" "atlantis" {
  name       = "atlantis"
  repository = "atlantis"
  chart      = "atlantis"
  version    = var.atlantis_version
  namespace  = kubernetes_namespace.atlantis.metadata[0].name

  # Use the values.yaml file
  values = [
    templatefile("${path.module}/values.yaml", {
      replica_count = var.atlantis_replica_count
      storage_size = var.atlantis_storage_size
      storage_class = var.atlantis_storage_class
      github_user = var.github_user
      github_token = var.github_token
      github_webhook_secret = var.github_webhook_secret
      github_repo_allowlist = var.github_repo_allowlist
    })
  ]

  # Override specific values that need dynamic configuration
  set {
    name  = "atlantisUrl"
    value = var.atlantis_hostname != "" ? "https://${var.atlantis_hostname}" : ""
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.atlantis.metadata[0].name
  }



  depends_on = [
    kubernetes_namespace.atlantis,
    kubernetes_service_account.atlantis
  ]
}

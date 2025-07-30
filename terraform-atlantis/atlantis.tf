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

# Secret for GitHub token
resource "kubernetes_secret" "atlantis_github" {
  metadata {
    name      = "atlantis-github"
    namespace = kubernetes_namespace.atlantis.metadata[0].name
    labels = {
      "app.kubernetes.io/name" = "atlantis"
      "app.kubernetes.io/instance" = "atlantis"
    }
  }

  data = {
    token = var.github_token
  }

  type = "Opaque"
}

# Secret for GitHub webhook
resource "kubernetes_secret" "atlantis_webhook" {
  metadata {
    name      = "atlantis-webhook"
    namespace = kubernetes_namespace.atlantis.metadata[0].name
    labels = {
      "app.kubernetes.io/name" = "atlantis"
      "app.kubernetes.io/instance" = "atlantis"
    }
  }

  data = {
    secret = var.github_webhook_secret
  }

  type = "Opaque"
}

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
  repository = "https://runatlantis.github.io/helm-charts"
  chart      = "atlantis"
  version    = var.atlantis_version
  namespace  = kubernetes_namespace.atlantis.metadata[0].name

  # Use the values.yaml file with Terraform variable substitution
  values = [
    templatefile("${path.module}/values.yaml", {
      atlantis_url = var.atlantis_hostname != "" ? "https://${var.atlantis_hostname}" : ""
      org_allowlist = var.github_repo_allowlist
      github_user = var.github_user
      github_token = var.github_token
      github_secret = var.github_webhook_secret
      replica_count = var.atlantis_replica_count
      storage_size = var.atlantis_storage_size
      storage_class = var.atlantis_storage_class
      service_account_name = kubernetes_service_account.atlantis.metadata[0].name
    })
  ]

  # Override specific values that need dynamic configuration
  set {
    name  = "atlantisUrl"
    value = var.atlantis_hostname != "" ? "https://${var.atlantis_hostname}" : ""
  }

  set {
    name  = "orgAllowlist"
    value = var.github_repo_allowlist
  }

  set {
    name  = "github.user"
    value = var.github_user
  }

  set_sensitive {
    name  = "github.token"
    value = var.github_token
  }

  set_sensitive {
    name  = "github.secret"
    value = var.github_webhook_secret
  }

  set {
    name  = "replicaCount"
    value = var.atlantis_replica_count
  }

  set {
    name  = "dataStorage"
    value = var.atlantis_storage_size
  }

  set {
    name  = "storageClassName"
    value = var.atlantis_storage_class
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.atlantis.metadata[0].name
  }

  set {
    name  = "environment.ATLANTIS_ATLANTIS_URL"
    value = var.atlantis_hostname != "" ? "https://${var.atlantis_hostname}" : ""
  }

  set {
    name  = "environment.ATLANTIS_GH_USER"
    value = var.github_user
  }

  set_sensitive {
    name  = "environment.ATLANTIS_GH_TOKEN"
    value = var.github_token
  }

  set_sensitive {
    name  = "environment.ATLANTIS_GH_WEBHOOK_SECRET"
    value = var.github_webhook_secret
  }

  set {
    name  = "environment.ATLANTIS_REPO_ALLOWLIST"
    value = var.github_repo_allowlist
  }

  depends_on = [
    kubernetes_namespace.atlantis,
    kubernetes_service_account.atlantis,
    kubernetes_secret.atlantis_github,
    kubernetes_secret.atlantis_webhook
  ]
}

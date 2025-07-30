output "atlantis_namespace" {
  description = "Namespace where Atlantis is deployed"
  value       = kubernetes_namespace.atlantis.metadata[0].name
}

output "atlantis_service_name" {
  description = "Name of the Atlantis service"
  value       = "atlantis"
}

output "atlantis_service_external_ip" {
  description = "External IP of the Atlantis LoadBalancer service"
  value       = "Run 'kubectl get svc atlantis -n atlantis' to get the external IP"
}

output "atlantis_helm_release_name" {
  description = "Name of the Atlantis Helm release"
  value       = helm_release.atlantis.name
}

output "atlantis_helm_release_version" {
  description = "Version of the Atlantis Helm release"
  value       = helm_release.atlantis.version
}

output "github_webhook_url" {
  description = "GitHub webhook URL for Atlantis"
  value       = "http://<EXTERNAL-IP>/events (replace <EXTERNAL-IP> with actual LoadBalancer IP)"
}

output "atlantis_url_instructions" {
  description = "Instructions to get Atlantis URL and configure GitHub webhook"
  sensitive   = true
  value = <<-EOT
    To get the Atlantis URL:
    1. Run: kubectl get svc atlantis -n atlantis
    2. Copy the EXTERNAL-IP value (may take a few minutes to provision)
    3. Access Atlantis at: http://<EXTERNAL-IP>
    
    To configure GitHub webhook:
    1. Go to your GitHub repository: https://github.com/${var.github_user}/<repo-name>/settings/hooks
    2. Click "Add webhook"
    3. Payload URL: http://<EXTERNAL-IP>/events
    4. Content type: application/json
    5. Secret: ${var.github_webhook_secret}
    6. Select "Let me select individual events" and check:
       - Pull requests
       - Issue comments
       - Pull request reviews
       - Pull request review comments
    7. Click "Add webhook"
    
    To test Atlantis:
    1. Make changes to terraform files
    2. Create a pull request
    3. Atlantis will automatically comment with a plan
    4. Comment 'atlantis apply' to apply the changes
  EOT
}

output "kubectl_commands" {
  description = "Useful kubectl commands for managing Atlantis"
  value = <<-EOT
    # Check Atlantis deployment status
    kubectl get pods -n atlantis
    
    # View Atlantis logs
    kubectl logs -f deployment/atlantis -n atlantis
    
    # Get service information
    kubectl get svc atlantis -n atlantis
    
    # Port forward for local access (optional)
    kubectl port-forward svc/atlantis 4141:80 -n atlantis
    # Then access at http://localhost:4141
    
    # Scale Atlantis (if needed)
    kubectl scale deployment atlantis --replicas=2 -n atlantis
  EOT
}

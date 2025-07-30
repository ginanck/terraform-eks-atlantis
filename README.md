# Terraform EKS with Atlantis

This project deploys an Amazon EKS cluster and Atlantis application using separate Terraform configurations for better modularity and separation of concerns.

## 🏗️ Architecture

- **VPC**: Custom VPC with 2 public and 2 private subnets across multiple AZs
- **EKS Cluster**: Kubernetes 1.28 cluster in private subnets (eu-central-1)
- **Worker Nodes**: Managed node group with autoscaling (min: 1, max: 2)
- **IAM Roles**: Two RBAC roles - `eks-admin` (full access) and `eks-read-only` (read-only access)
- **Atlantis**: Deployed via Helm chart for GitOps workflow automation

## 📁 Project Structure
```
terraform-eks-atlantis/
├── terraform-infrastructure/    # EKS cluster and infrastructure
│   ├── main.tf
│   ├── variables.tf
│   ├── vpc.tf
│   ├── iam.tf
│   ├── eks.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
├── terraform-atlantis/         # Atlantis application deployment
│   ├── main.tf
│   ├── variables.tf
│   ├── atlantis.tf
│   ├── outputs.tf
│   ├── values.yaml
│   └── terraform.tfvars.example
├── Makefile                   # Deployment automation
├── atlantis.yaml              # Atlantis configuration
└── README.md
```

## 📋 Prerequisites

1. **AWS CLI** configured with appropriate permissions
2. **Terraform** >= 1.0
3. **kubectl** for Kubernetes management
4. **Helm** 3.x for Atlantis deployment
5. **GitHub repository** and personal access token

## 🔐 Required AWS Permissions

Your AWS user/role needs the following permissions:
- VPC, Subnet, Route Table, Internet Gateway, NAT Gateway management
- EKS cluster and node group management
- IAM role and policy management
- EC2 security group management
- LoadBalancer management

## 🚀 Deployment Steps

### Quick Start with Makefile

1. **Check Prerequisites:**
   ```bash
   make check-prereqs
   ```

2. **Deploy Everything (Automated):**
   ```bash
   make all
   ```

### Step-by-Step Deployment

#### Step 1: Setup and Deploy EKS Infrastructure

1. **Setup Configuration:**
   ```bash
   make setup-config PROJECT=terraform-infrastructure
   ```

2. **Edit `terraform-infrastructure/terraform.tfvars`:**
   ```hcl
   aws_region = "eu-central-1"
   project_name = "atlantis-eks"
   environment = "dev"
   
   # VPC Configuration
   vpc_cidr = "10.0.0.0/16"
   private_subnets_cidr = ["10.0.1.0/24", "10.0.2.0/24"]
   public_subnets_cidr = ["10.0.101.0/24", "10.0.102.0/24"]
   
   # EKS Configuration
   kubernetes_version = "1.28"
   worker_instance_types = ["t3.medium"]
   worker_min_size = 1
   worker_max_size = 2
   worker_desired_size = 1
   ```

3. **Deploy EKS Infrastructure:**
   ```bash
   make apply PROJECT=terraform-infrastructure
   ```
   This automatically configures kubectl for you.

#### Step 2: Setup and Deploy Atlantis

1. **Setup Configuration:**
   ```bash
   make setup-config PROJECT=terraform-atlantis
   ```

2. **Edit `terraform-atlantis/terraform.tfvars`:**
   ```hcl
   aws_region = "eu-central-1"
   cluster_name = "atlantis-eks-eks-cluster"
   
   # GitHub Configuration
   github_user = "your-github-username"
   github_token = "ghp_xxxxxxxxxxxxxxxxxxxx"  # GitHub Personal Access Token
   github_webhook_secret = "your-random-webhook-secret"
   github_repo_allowlist = "github.com/your-github-username/*"
   ```

3. **Deploy Atlantis:**
   ```bash
   make apply PROJECT=terraform-atlantis
   ```

### Available Make Targets

View all available commands:
```bash
make help
```

**Core Terraform Operations:**
- `make init PROJECT=<project>` - Initialize Terraform
- `make plan PROJECT=<project>` - Plan deployment  
- `make apply PROJECT=<project>` - Apply configuration
- `make destroy PROJECT=<project>` - Destroy resources
- `make fmt PROJECT=<project>` - Format code
- `make clean PROJECT=<project>` - Clean cache

**Convenience Targets:**
- `make infrastructure` - Deploy EKS (shorthand)
- `make atlantis` - Deploy Atlantis (shorthand)  
- `make all` - Deploy everything
- `make status` - Show deployment status

### Configure GitHub Integration

1. **Get GitHub webhook configuration:**
   ```bash
   make webhook-info
   ```

2. **Get LoadBalancer IP:**
   ```bash
   kubectl get svc atlantis -n atlantis
   # Wait for EXTERNAL-IP to be assigned
   ```

3. **Configure GitHub Webhook:**
   - Go to your repository: `https://github.com/YOUR-USERNAME/REPO-NAME/settings/hooks`
   - Click "Add webhook"
   - **Payload URL**: `http://<EXTERNAL-IP>/events`
   - **Content type**: `application/json`
   - **Secret**: Use your `github_webhook_secret`
   - **Events**: Select individual events:
     - ✅ Pull requests
     - ✅ Issue comments
     - ✅ Pull request reviews
     - ✅ Pull request review comments

### Test Atlantis

1. **Create Test PR:**
   ```bash
   git checkout -b test-atlantis
   echo '# Test comment for Atlantis' >> terraform-infrastructure/main.tf
   git add .
   git commit -m "Test Atlantis workflow"
   git push origin test-atlantis
   ```

2. **Create Pull Request** on GitHub and observe Atlantis automation:
   - Atlantis will automatically run `terraform plan` on the changed directories
   - Comment `atlantis apply` in the PR to apply changes
   - Comment `atlantis plan` to re-run planning if needed

3. **Monitor Atlantis:**
   ```bash
   make status           # Check overall status
   make logs-atlantis    # View Atlantis logs
   ```

## 🔧 IAM Roles and RBAC

### EKS Admin Role
- **Role Name**: `eks-admin`
- **Access**: Full cluster admin access
- **Usage**: 
  ```bash
  aws sts assume-role \
    --role-arn arn:aws:iam::ACCOUNT-ID:role/eks-admin \
    --role-session-name admin-session
  ```

### EKS Read-Only Role
- **Role Name**: `eks-read-only`
- **Access**: Read-only access to cluster resources
- **Usage**: 
  ```bash
  aws sts assume-role \
    --role-arn arn:aws:iam::ACCOUNT-ID:role/eks-read-only \
    --role-session-name readonly-session
  ```

## 📊 Monitoring and Management

### Atlantis Management
```bash
# Check Atlantis status
kubectl get pods -n atlantis

# View Atlantis logs
kubectl logs -f deployment/atlantis -n atlantis

# Get service information
kubectl get svc atlantis -n atlantis

# Port forward for local access
kubectl port-forward svc/atlantis 4141:80 -n atlantis
# Access at http://localhost:4141
```

### EKS Cluster Management
```bash
# View nodes
kubectl get nodes

# Check system pods
kubectl get pods -n kube-system

# View cluster info
kubectl cluster-info
```

## 🧹 Cleanup

**Remove components in order** (Atlantis first to avoid hanging LoadBalancer):

1. **Remove Atlantis:**
   ```bash
   make destroy PROJECT=terraform-atlantis
   ```

2. **Remove EKS Infrastructure:**
   ```bash
   make destroy PROJECT=terraform-infrastructure
   ```

**Clean Terraform cache** (optional):
```bash
make clean PROJECT=terraform-atlantis
make clean PROJECT=terraform-infrastructure
```

## 🔒 Security Considerations

1. **GitHub Token**: 
   - Use fine-grained personal access tokens
   - Limit repository access scope
   - Rotate tokens regularly

2. **Webhook Secret**: 
   - Use a strong, random secret
   - Store securely in terraform.tfvars

3. **EKS Security**:
   - Cluster in private subnets
   - Security groups properly configured
   - IAM roles with least privilege

4. **Network Security**:
   - LoadBalancer for controlled access
   - Consider using ALB with WAF for production

## 🐛 Troubleshooting

### EKS Issues
```bash
# Check cluster status
aws eks describe-cluster --name atlantis-eks-eks-cluster --region eu-central-1

# Update kubeconfig
aws eks update-kubeconfig --region eu-central-1 --name atlantis-eks-eks-cluster

# Check nodes
kubectl get nodes -o wide
```

### Atlantis Issues
```bash
# Check pod status
kubectl describe pod -l app.kubernetes.io/name=atlantis -n atlantis

# View logs
kubectl logs -l app.kubernetes.io/name=atlantis -n atlantis

# Check service
kubectl describe svc atlantis -n atlantis
```

### GitHub Integration Issues
- Verify webhook URL is accessible from internet
- Check webhook secret matches exactly
- Ensure GitHub token has required permissions
- Test webhook delivery in GitHub settings

## 💰 Cost Optimization

- **Region**: eu-central-1 for European users
- **Instance Types**: t3.medium for cost efficiency
- **Auto Scaling**: Min 1, Max 2 nodes
- **Storage**: GP2 for balance of cost and performance
- **LoadBalancer**: Classic ELB for lower cost

## 🚀 Production Enhancements

1. **Security**:
   - Enable EKS audit logging
   - Use private API server endpoint
   - Implement Pod Security Standards

2. **High Availability**:
   - Deploy across 3 AZs
   - Multiple Atlantis replicas
   - RDS for Atlantis state (if needed)

3. **Monitoring**:
   - CloudWatch Container Insights
   - Prometheus and Grafana
   - Alert management

4. **CI/CD**:
   - Automated testing pipelines
   - GitOps with ArgoCD
   - Progressive deployment strategies

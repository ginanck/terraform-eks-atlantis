# EKS RBAC Testing Guide

This guide explains how to test the IAM-based authentication for the EKS cluster.

## Authentication Methods

The cluster is configured with **dual authentication mode**:

1. **IAM Access Entries** (Modern approach) - `API_AND_CONFIG_MAP`
2. **aws-auth ConfigMap** (Legacy approach) - for backward compatibility

## IAM Roles

### eks-admin Role
- **Policy**: `AmazonEKSClusterAdminPolicy`
- **Access**: Full cluster administrative access
- **ARN**: Available in terraform output `eks_admin_role_arn`

### eks-read-only Role  
- **Policy**: `AmazonEKSViewPolicy`
- **Access**: Read-only access to cluster resources
- **ARN**: Available in terraform output `eks_read_only_role_arn`

## Testing Access

### 1. Get Role ARNs
```bash
cd terraform-infrastructure
ADMIN_ROLE_ARN=$(terraform output -raw eks_admin_role_arn)
READONLY_ROLE_ARN=$(terraform output -raw eks_read_only_role_arn)
```

### 2. Test Admin Access
```bash
# Assume the admin role
aws sts assume-role \
  --role-arn $ADMIN_ROLE_ARN \
  --role-session-name eks-admin-test

# Export the credentials (replace with actual values from above command)
export AWS_ACCESS_KEY_ID=<AccessKeyId>
export AWS_SECRET_ACCESS_KEY=<SecretAccessKey>
export AWS_SESSION_TOKEN=<SessionToken>

# Configure kubectl for the assumed role
aws eks update-kubeconfig --region eu-central-1 --name atlantis-eks

# Test admin access (should work)
kubectl get nodes
kubectl get pods --all-namespaces
kubectl create namespace test-admin
kubectl delete namespace test-admin
```

### 3. Test Read-Only Access
```bash
# Assume the read-only role
aws sts assume-role \
  --role-arn $READONLY_ROLE_ARN \
  --role-session-name eks-readonly-test

# Export the credentials (replace with actual values from above command)
export AWS_ACCESS_KEY_ID=<AccessKeyId>
export AWS_SECRET_ACCESS_KEY=<SecretAccessKey>
export AWS_SESSION_TOKEN=<SessionToken>

# Configure kubectl for the assumed role
aws eks update-kubeconfig --region eu-central-1 --name atlantis-eks

# Test read-only access
kubectl get nodes                    # Should work
kubectl get pods --all-namespaces    # Should work
kubectl create namespace test-ro     # Should fail (Forbidden)
```

### 4. Reset to Original Credentials
```bash
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY  
unset AWS_SESSION_TOKEN

# Reconfigure kubectl with your original credentials
aws eks update-kubeconfig --region eu-central-1 --name atlantis-eks
```

## Verification Commands

```bash
# Check access entries
kubectl get cm aws-auth -n kube-system -o yaml

# List access entries (requires AWS CLI v2.15.0+)
aws eks list-access-entries --cluster-name atlantis-eks --region eu-central-1

# Describe access entry
aws eks describe-access-entry \
  --cluster-name atlantis-eks \
  --principal-arn $ADMIN_ROLE_ARN \
  --region eu-central-1
```

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────────┐
│   IAM Users     │───▶│   IAM Roles      │───▶│   EKS Cluster       │
│                 │    │                  │    │                     │
│ - Developer     │    │ - eks-admin      │    │ ┌─────────────────┐ │
│ - DevOps        │    │ - eks-read-only  │    │ │ Access Entries  │ │
│ - Operations    │    │                  │    │ │ + ConfigMap     │ │
└─────────────────┘    └──────────────────┘    │ └─────────────────┘ │
                                               │                     │
                                               │ Kubernetes RBAC     │
                                               │ - system:masters    │
                                               │ - system:readers    │
                                               └─────────────────────┘
```

This setup ensures both modern IAM access entries and legacy ConfigMap compatibility.

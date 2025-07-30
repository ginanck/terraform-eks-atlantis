# Security group for EKS cluster
resource "aws_security_group" "eks_cluster_sg" {
  name_prefix = "${var.project_name}-eks-cluster-sg"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${var.project_name}-eks-cluster-sg"
  })
}

resource "aws_security_group_rule" "eks_cluster_ingress_node_https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster_sg.id
  source_security_group_id = aws_security_group.eks_node_sg.id
  to_port                  = 443
  type                     = "ingress"
}

# Security group for EKS nodes
resource "aws_security_group" "eks_node_sg" {
  name_prefix = "${var.project_name}-eks-node-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    self      = true
  }

  ingress {
    from_port   = 1025
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${var.project_name}-eks-node-sg"
  })
}

# EKS Cluster
# Note: Using EKS module v19.x which has deprecation warnings for inline_policy
# These are harmless and will be resolved in future module updates
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.21"

  cluster_name    = local.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id                         = aws_vpc.main.id
  subnet_ids                     = aws_subnet.private[*].id
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  # EKS Managed Node Groups
  eks_managed_node_groups = {
    main = {
      name = "main"

      instance_types = var.worker_instance_types

      min_size     = var.worker_min_size
      max_size     = var.worker_max_size
      desired_size = var.worker_desired_size

      ami_type                   = "AL2_x86_64"
      capacity_type              = "ON_DEMAND"
      disk_size                  = 50
      force_update_version       = false
      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }

      labels = {
        Environment = var.environment
        Project     = var.project_name
      }

      taints = {}

      update_config = {
        max_unavailable_percentage = 33
      }

      tags = local.tags
    }
  }

  # aws-auth configmap
  manage_aws_auth_configmap = true

  aws_auth_roles = [
    {
      rolearn  = aws_iam_role.eks_admin_role.arn
      username = "eks-admin"
      groups   = ["system:masters"]
    },
    {
      rolearn  = aws_iam_role.eks_read_only_role.arn
      username = "eks-read-only"
      groups   = ["system:readers"]
    },
  ]

  tags = local.tags
}

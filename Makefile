# Terraform EKS with Atlantis - Simplified Makefile
# Usage: make <target> PROJECT=<project-directory>

.PHONY: help init fmt plan apply destroy clean setup-config check-prereqs setup-kubeconfig status infrastructure atlantis all

# Variables
AWS_REGION := eu-central-1
PROJECT_NAME := atlantis
CLUSTER_NAME := $(PROJECT_NAME)-eks

# Utility targets that don't require PROJECT parameter
UTILITY_TARGETS := help check-prereqs setup-kubeconfig status infrastructure atlantis all

# Check if PROJECT is required for this target
ifeq (,$(filter $(MAKECMDGOALS),$(UTILITY_TARGETS)))
  ifndef PROJECT
    $(error ❌ PROJECT parameter is required. Usage: make $(MAKECMDGOALS) PROJECT=<project-directory>)
  endif
  
  # Validate project directory exists
  ifeq (,$(wildcard $(PROJECT)/.))
    $(error ❌ Project directory '$(PROJECT)' does not exist)
  endif
endif

# Default target
help: ## Show this help message
	@echo "Terraform EKS with Atlantis - Simplified Makefile"
	@echo ""
	@echo "Usage: make <target> PROJECT=<project-directory>"
	@echo ""
	@echo "Core Terraform Operations:"
	@echo "  init      - Initialize Terraform"
	@echo "  fmt       - Format Terraform files"
	@echo "  plan      - Plan deployment"
	@echo "  apply     - Apply configuration"
	@echo "  destroy   - Destroy resources"
	@echo "  clean     - Clean cache"
	@echo ""
	@echo "Utility Commands:"
	@echo "  check-prereqs    - Check required tools"
	@echo "  setup-config     - Setup configuration files"
	@echo "  setup-kubeconfig - Configure kubectl"
	@echo "  status           - Show deployment status"
	@echo ""
	@echo "Shortcuts:"
	@echo "  infrastructure   - Deploy EKS"
	@echo "  atlantis         - Deploy Atlantis"
	@echo "  all              - Deploy everything"
	@echo ""
	@echo "Examples:"
	@echo "  make init PROJECT=terraform-infrastructure"
	@echo "  make apply PROJECT=terraform-atlantis"

# Core Terraform operations
init: ## Initialize Terraform
	@echo "🔧 Initializing $(PROJECT)..."
	@cd $(PROJECT) && terraform init -input=false > /dev/null
	@echo "✅ Terraform initialized"

fmt: ## Format Terraform files
	@echo "🎨 Formatting $(PROJECT)..."
	@cd $(PROJECT) && terraform fmt > /dev/null
	@echo "✅ Files formatted"

plan: init ## Plan deployment
	@echo "📋 Planning $(PROJECT)..."
	@cd $(PROJECT) && TF_CLI_ARGS_plan="-compact-warnings" terraform plan -input=false

apply: init ## Apply configuration
	@echo "🚀 Applying $(PROJECT)..."
	@cd $(PROJECT) && terraform apply -input=false -auto-approve > /dev/null
	@echo "✅ $(PROJECT) deployed"
	@if [ "$(PROJECT)" = "terraform-infrastructure" ]; then \
		echo "⚙️  Configuring kubectl..."; \
		aws eks update-kubeconfig --region $(AWS_REGION) --name $(CLUSTER_NAME) > /dev/null 2>&1; \
		echo "✅ kubectl configured"; \
	fi
	@if [ "$(PROJECT)" = "terraform-atlantis" ]; then \
		echo "⏳ Checking Atlantis service..."; \
		sleep 5; \
		kubectl get svc atlantis -n atlantis 2>/dev/null || echo "⚠️  Service not ready yet"; \
	fi

destroy: ## Destroy resources
	@echo "🗑️  Destroying $(PROJECT)..."
	@cd $(PROJECT) && terraform destroy -input=false -auto-approve > /dev/null
	@echo "✅ $(PROJECT) destroyed"

clean: ## Clean cache
	@echo "🧹 Cleaning $(PROJECT)..."
	@cd $(PROJECT) && rm -rf .terraform/ terraform.tfstate.backup .terraform.lock.hcl
	@echo "✅ Cache cleaned"

setup-config: ## Setup configuration files
	@if [ ! -f $(PROJECT)/terraform.tfvars ]; then \
		cd $(PROJECT) && cp terraform.tfvars.example terraform.tfvars; \
		echo "✅ Created $(PROJECT)/terraform.tfvars"; \
		echo "📝 Edit $(PROJECT)/terraform.tfvars with your settings"; \
	else \
		echo "ℹ️  $(PROJECT)/terraform.tfvars exists"; \
	fi

# Utility targets
check-prereqs: ## Check required tools
	@echo "🔍 Checking tools..."
	@command -v terraform >/dev/null 2>&1 || { echo "❌ terraform missing"; exit 1; }
	@command -v aws >/dev/null 2>&1 || { echo "❌ aws missing"; exit 1; }
	@command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl missing"; exit 1; }
	@command -v helm >/dev/null 2>&1 || { echo "❌ helm missing"; exit 1; }
	@aws sts get-caller-identity >/dev/null 2>&1 || { echo "❌ AWS credentials not configured"; exit 1; }
	@echo "✅ All tools ready"

setup-kubeconfig: ## Configure kubectl
	@echo "⚙️  Configuring kubectl..."
	@aws eks update-kubeconfig --region $(AWS_REGION) --name $(CLUSTER_NAME) > /dev/null 2>&1
	@echo "✅ kubectl configured"

status: ## Show deployment status
	@echo "📊 Status:"
	@kubectl get nodes 2>/dev/null | head -1 || echo "❌ EKS not accessible"
	@kubectl get pods -n atlantis 2>/dev/null | head -1 || echo "❌ Atlantis not found"
	@kubectl get svc atlantis -n atlantis 2>/dev/null | grep -v NAME || echo "❌ Service not found"

# Shortcuts
infrastructure: check-prereqs ## Deploy EKS
	@$(MAKE) -s setup-config PROJECT=terraform-infrastructure
	@$(MAKE) -s apply PROJECT=terraform-infrastructure

atlantis: ## Deploy Atlantis
	@$(MAKE) -s setup-config PROJECT=terraform-atlantis
	@$(MAKE) -s apply PROJECT=terraform-atlantis

all: infrastructure atlantis ## Deploy everything
	@echo "🎉 Deployment complete!"
	@echo "📋 Next: Configure GitHub webhook and test"

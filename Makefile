.PHONY: help init plan apply destroy validate audit clean

help:
	@echo "Kubernetes Security Hardening - Make Commands"
	@echo "=============================================="
	@echo "init      - Initialize Terraform"
	@echo "plan      - Plan infrastructure changes"
	@echo "apply     - Deploy infrastructure"
	@echo "destroy   - Destroy all resources"
	@echo "validate  - Validate Terraform and K8s configs"
	@echo "audit     - Run security compliance audit"
	@echo "clean     - Clean temporary files"

init:
	cd terraform && terraform init

plan:
	cd terraform && terraform plan

apply:
	bash scripts/deploy.sh

destroy:
	bash scripts/destroy.sh

validate:
	cd terraform && terraform validate
	kubectl apply --dry-run=client -f policies/
	kubectl apply --dry-run=client -f rbac/

audit:
	@echo "Running CIS Benchmark audit..."
	kubectl apply -f compliance/kube-bench-job.yaml
	@echo "Waiting for job to complete..."
	kubectl wait --for=condition=complete --timeout=300s job/kube-bench -n security-tools
	kubectl logs -n security-tools job/kube-bench

clean:
	cd terraform && rm -rf .terraform/ *.tfstate* tfplan
	find . -name "*.log" -delete

# GitHub Safety Checklist

**IMPORTANT**: Complete this checklist before pushing to GitHub to ensure no sensitive information is exposed.

## ✅ Pre-Commit Checklist

### 1. Verify .gitignore is Working
```bash
# Check what will be committed
git status

# Verify sensitive files are ignored
git check-ignore -v terraform/*.tfvars
git check-ignore -v .aws/credentials
git check-ignore -v kubeconfig

# Expected: All should show as ignored
```

### 2. Search for Sensitive Patterns
```bash
# Search for AWS keys (should return nothing)
grep -r "AKIA" k8s-security-hardening/ 2>/dev/null

# Search for passwords (should return nothing)
grep -ri "password.*=" k8s-security-hardening/ --include="*.tf" --include="*.yaml" 2>/dev/null

# Search for secrets (should return nothing in actual values)
grep -ri "secret.*=" k8s-security-hardening/ --include="*.tf" --include="*.yaml" 2>/dev/null

# Search for private IPs (should return only examples)
grep -r "10\.[0-9]\+\.[0-9]\+\.[0-9]\+" k8s-security-hardening/ --include="*.tf" 2>/dev/null

# Search for email addresses (should return only examples)
grep -r "@" k8s-security-hardening/ --include="*.tf" --include="*.yaml" 2>/dev/null
```

### 3. Check for Hardcoded Credentials
```bash
# Check Terraform files
grep -r "access_key\|secret_key\|password\|token" terraform/ --include="*.tf"

# Expected: Only variable declarations, no actual values
```

### 4. Verify Example Files Only
```bash
# Ensure only example files exist
ls -la terraform/*.tfvars

# Expected: Only terraform.tfvars.example should exist
# If terraform.tfvars exists, it should be gitignored
```

### 5. Check for Personal Information
```bash
# Search for your name
grep -r "YOUR_NAME_HERE" k8s-security-hardening/

# Search for your email
grep -r "your-email@" k8s-security-hardening/

# Search for your organization
grep -r "YOUR_COMPANY" k8s-security-hardening/
```

## 🔒 Files That Should NEVER Be Committed

### Terraform Files
- ❌ `*.tfstate` - Contains all infrastructure details
- ❌ `*.tfstate.backup` - Backup of state
- ❌ `*.tfvars` (except .example) - Contains actual values
- ❌ `.terraform/` - Downloaded providers
- ❌ `tfplan` - Execution plan with values

### Kubernetes Files
- ❌ `kubeconfig` - Cluster access credentials
- ❌ `*.kubeconfig` - Alternative kubeconfig files
- ❌ `.kube/config` - Default kubectl config

### AWS Files
- ❌ `.aws/credentials` - AWS access keys
- ❌ `*.pem` - Private keys
- ❌ `*.key` - Any key files

### Secrets
- ❌ `.env` - Environment variables
- ❌ `secrets/` - Any secrets directory
- ❌ `*.secret` - Secret files

## ✅ Files That Are SAFE to Commit

### Terraform Files
- ✅ `*.tf` - Terraform configuration (no hardcoded values)
- ✅ `*.tfvars.example` - Example configuration
- ✅ `modules/` - Reusable modules

### Kubernetes Files
- ✅ `*.yaml` - Kubernetes manifests (no secrets)
- ✅ `policies/` - Policy definitions
- ✅ `rbac/` - RBAC configurations

### Documentation
- ✅ `*.md` - All markdown documentation
- ✅ `docs/` - Documentation directory

### Scripts
- ✅ `*.sh` - Shell scripts (no credentials)

## 🔍 Manual Review Checklist

Before committing, manually review these files:

### terraform/terraform.tfvars.example
- [ ] Contains only placeholder values
- [ ] No real AWS account IDs
- [ ] No real IP addresses
- [ ] No real domain names
- [ ] All values are clearly examples

### terraform/main.tf
- [ ] No hardcoded credentials
- [ ] Uses variables for all sensitive data
- [ ] Backend configuration commented out or uses placeholders

### terraform/modules/*/main.tf
- [ ] No hardcoded AWS account IDs
- [ ] No hardcoded IP addresses
- [ ] Uses variables for configuration

### policies/*.yaml
- [ ] No real domain names
- [ ] No real email addresses
- [ ] No real registry URLs (or use examples)

### scripts/*.sh
- [ ] No hardcoded credentials
- [ ] No hardcoded AWS account IDs
- [ ] Uses environment variables or prompts

### README.md and docs/
- [ ] No real AWS account IDs
- [ ] No real cluster names (or clearly marked as examples)
- [ ] No real IP addresses
- [ ] No personal information

## 🛡️ Additional Security Measures

### 1. Use GitHub Secrets (for CI/CD)
If you add GitHub Actions later:
```yaml
# .github/workflows/example.yml
env:
  AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
  AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

### 2. Enable GitHub Security Features
- [ ] Enable Dependabot alerts
- [ ] Enable Secret scanning
- [ ] Enable Code scanning (CodeQL)
- [ ] Review security advisories

### 3. Add Security Policy
Create `.github/SECURITY.md`:
```markdown
# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability, please email: security@example.com

Do NOT create a public GitHub issue.
```

### 4. Add Contributing Guidelines
Create `CONTRIBUTING.md`:
```markdown
# Contributing Guidelines

## Security

- Never commit credentials or secrets
- Use terraform.tfvars.example as template
- Review .gitignore before committing
- Run security checks before PR
```

## 🚀 Safe Git Commands

### Initial Setup
```bash
cd k8s-security-hardening

# Initialize git (if not already done)
git init

# Verify .gitignore is in place
cat .gitignore

# Add all files
git add .

# Check what will be committed
git status

# Verify no sensitive files
git status | grep -E "tfvars|kubeconfig|credentials|\.pem|\.key"
# Expected: Should only show terraform.tfvars.example

# Commit
git commit -m "Initial commit: Kubernetes Security Hardening - 100% CIS/OWASP/NIST compliance"

# Add remote (replace with your repo URL)
git remote add origin https://github.com/YOUR_USERNAME/k8s-security-hardening.git

# Push to GitHub
git push -u origin main
```

### Before Each Commit
```bash
# Always check status first
git status

# Review changes
git diff

# Check for sensitive patterns
git diff | grep -i "password\|secret\|key\|token"

# If clean, commit
git add .
git commit -m "Your commit message"
git push
```

## 🔴 If You Accidentally Commit Secrets

### Immediate Actions
```bash
# 1. Remove from latest commit (if not pushed)
git reset HEAD~1
git add .gitignore
git commit -m "Add .gitignore"

# 2. If already pushed, remove from history
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch path/to/sensitive/file" \
  --prune-empty --tag-name-filter cat -- --all

# 3. Force push (WARNING: Rewrites history)
git push origin --force --all

# 4. IMMEDIATELY rotate all exposed credentials
# - AWS keys
# - Kubernetes tokens
# - Any other secrets
```

### Rotate Credentials
```bash
# AWS
aws iam delete-access-key --access-key-id EXPOSED_KEY_ID

# Kubernetes
kubectl delete secret exposed-secret

# Terraform
terraform taint aws_iam_access_key.exposed
terraform apply
```

## ✅ Final Verification

Before pushing to GitHub, run this complete check:

```bash
#!/bin/bash
echo "🔍 Running pre-commit security checks..."

# Check 1: Verify .gitignore exists
if [ ! -f .gitignore ]; then
    echo "❌ .gitignore not found!"
    exit 1
fi
echo "✅ .gitignore exists"

# Check 2: Search for AWS keys
if grep -r "AKIA" . 2>/dev/null | grep -v ".git"; then
    echo "❌ Found potential AWS keys!"
    exit 1
fi
echo "✅ No AWS keys found"

# Check 3: Check for .tfvars files (except examples)
if find . -name "*.tfvars" -not -name "*.example.tfvars" | grep -v ".git"; then
    echo "❌ Found .tfvars files (should be gitignored)!"
    exit 1
fi
echo "✅ No .tfvars files to commit"

# Check 4: Check for kubeconfig
if find . -name "kubeconfig" -o -name "*.kubeconfig" | grep -v ".git"; then
    echo "❌ Found kubeconfig files!"
    exit 1
fi
echo "✅ No kubeconfig files found"

# Check 5: Check for .pem or .key files
if find . -name "*.pem" -o -name "*.key" | grep -v ".git"; then
    echo "❌ Found key files!"
    exit 1
fi
echo "✅ No key files found"

# Check 6: Verify terraform.tfvars.example exists
if [ ! -f terraform/terraform.tfvars.example ]; then
    echo "❌ terraform.tfvars.example not found!"
    exit 1
fi
echo "✅ terraform.tfvars.example exists"

echo ""
echo "✅ All security checks passed!"
echo "Safe to commit to GitHub"
```

Save this as `scripts/pre-commit-check.sh` and run before each commit:
```bash
bash scripts/pre-commit-check.sh && git push
```

## 📋 Summary

**Safe to commit:**
- ✅ All .tf files (configuration only)
- ✅ All .yaml files (no secrets)
- ✅ All .md files (documentation)
- ✅ All .sh files (scripts without credentials)
- ✅ .gitignore
- ✅ terraform.tfvars.example

**Never commit:**
- ❌ *.tfstate (state files)
- ❌ *.tfvars (actual values)
- ❌ kubeconfig (cluster access)
- ❌ .aws/credentials (AWS keys)
- ❌ *.pem, *.key (private keys)
- ❌ .env (environment variables)

**Your project is safe to share on GitHub as long as:**
1. .gitignore is properly configured ✅
2. No actual credentials are in code ✅
3. Only example files with placeholders ✅
4. All sensitive files are gitignored ✅

You're ready to push to GitHub! 🚀

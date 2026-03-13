#!/bin/bash
# ============================================================================
# PRE-COMMIT SECURITY CHECK
# ============================================================================
# Run this before every commit to ensure no sensitive data is exposed
# Usage: bash scripts/pre-commit-check.sh
# ============================================================================

set -e

echo "🔍 Running pre-commit security checks..."
echo "========================================"

FAILED=0

# Check 1: Verify .gitignore exists
echo ""
echo "Check 1: Verifying .gitignore exists..."
if [ ! -f .gitignore ]; then
    echo "❌ FAIL: .gitignore not found!"
    FAILED=1
else
    echo "✅ PASS: .gitignore exists"
fi

# Check 2: Search for AWS keys
echo ""
echo "Check 2: Searching for AWS access keys..."
if grep -r "AKIA[0-9A-Z]\{16\}" . 2>/dev/null | grep -v ".git" | grep -v "pre-commit-check.sh"; then
    echo "❌ FAIL: Found potential AWS access keys!"
    FAILED=1
else
    echo "✅ PASS: No AWS keys found"
fi

# Check 3: Search for AWS secret keys
echo ""
echo "Check 3: Searching for AWS secret keys..."
if grep -r "aws_secret_access_key.*=.*['\"][^'\"]\{40\}['\"]" . 2>/dev/null | grep -v ".git"; then
    echo "❌ FAIL: Found potential AWS secret keys!"
    FAILED=1
else
    echo "✅ PASS: No AWS secret keys found"
fi

# Check 4: Check for .tfvars files (except examples)
echo ""
echo "Check 4: Checking for .tfvars files..."
if find . -name "*.tfvars" -not -name "*.example.tfvars" -not -name "*.tfvars.example" 2>/dev/null | grep -v ".git" | grep .; then
    echo "❌ FAIL: Found .tfvars files (should be gitignored)!"
    echo "These files may contain sensitive data"
    FAILED=1
else
    echo "✅ PASS: No .tfvars files to commit"
fi

# Check 5: Check for Terraform state files
echo ""
echo "Check 5: Checking for Terraform state files..."
if find . -name "*.tfstate*" 2>/dev/null | grep -v ".git" | grep .; then
    echo "❌ FAIL: Found Terraform state files!"
    echo "State files contain sensitive infrastructure data"
    FAILED=1
else
    echo "✅ PASS: No state files found"
fi

# Check 6: Check for kubeconfig
echo ""
echo "Check 6: Checking for kubeconfig files..."
if find . \( -name "kubeconfig" -o -name "*.kubeconfig" -o -name "config" \) -not -path "./.git/*" 2>/dev/null | grep .; then
    echo "❌ FAIL: Found kubeconfig files!"
    echo "Kubeconfig contains cluster access credentials"
    FAILED=1
else
    echo "✅ PASS: No kubeconfig files found"
fi

# Check 7: Check for private keys
echo ""
echo "Check 7: Checking for private key files..."
if find . \( -name "*.pem" -o -name "*.key" -o -name "id_rsa*" \) -not -path "./.git/*" 2>/dev/null | grep .; then
    echo "❌ FAIL: Found private key files!"
    FAILED=1
else
    echo "✅ PASS: No private key files found"
fi

# Check 8: Check for .env files
echo ""
echo "Check 8: Checking for .env files..."
if find . -name ".env" -not -name ".env.example" -not -path "./.git/*" 2>/dev/null | grep .; then
    echo "❌ FAIL: Found .env files!"
    echo ".env files often contain secrets"
    FAILED=1
else
    echo "✅ PASS: No .env files found"
fi

# Check 9: Check for AWS credentials file
echo ""
echo "Check 9: Checking for AWS credentials..."
if find . -path "*/.aws/credentials" -not -path "./.git/*" 2>/dev/null | grep .; then
    echo "❌ FAIL: Found AWS credentials file!"
    FAILED=1
else
    echo "✅ PASS: No AWS credentials file found"
fi

# Check 10: Verify terraform.tfvars.example exists
echo ""
echo "Check 10: Verifying example files exist..."
if [ ! -f terraform/terraform.tfvars.example ]; then
    echo "❌ FAIL: terraform.tfvars.example not found!"
    FAILED=1
else
    echo "✅ PASS: terraform.tfvars.example exists"
fi

# Check 11: Search for hardcoded passwords
echo ""
echo "Check 11: Searching for hardcoded passwords..."
if grep -r "password\s*=\s*['\"][^'\"]\+" . --include="*.tf" --include="*.yaml" 2>/dev/null | grep -v "changeme" | grep -v "example" | grep -v ".git"; then
    echo "❌ FAIL: Found potential hardcoded passwords!"
    FAILED=1
else
    echo "✅ PASS: No hardcoded passwords found"
fi

# Check 12: Search for private IP addresses (should only be examples)
echo ""
echo "Check 12: Checking for private IP addresses..."
PRIVATE_IPS=$(grep -r "10\.[0-9]\+\.[0-9]\+\.[0-9]\+" . --include="*.tf" 2>/dev/null | grep -v ".git" | grep -v "10.0.0.0/16" | grep -v "example" | grep -v "comment" || true)
if [ ! -z "$PRIVATE_IPS" ]; then
    echo "⚠️  WARNING: Found private IP addresses (verify these are examples):"
    echo "$PRIVATE_IPS"
fi

# Check 13: Search for email addresses (should only be examples)
echo ""
echo "Check 13: Checking for email addresses..."
EMAILS=$(grep -r "[a-zA-Z0-9._%+-]\+@[a-zA-Z0-9.-]\+\.[a-zA-Z]\{2,\}" . --include="*.tf" --include="*.yaml" --include="*.md" 2>/dev/null | grep -v ".git" | grep -v "example.com" | grep -v "your-email" | grep -v "security@" || true)
if [ ! -z "$EMAILS" ]; then
    echo "⚠️  WARNING: Found email addresses (verify these are examples):"
    echo "$EMAILS"
fi

# Check 14: Verify .gitignore is comprehensive
echo ""
echo "Check 14: Verifying .gitignore coverage..."
REQUIRED_PATTERNS=("*.tfstate" "*.tfvars" "kubeconfig" "*.pem" "*.key" ".env")
for pattern in "${REQUIRED_PATTERNS[@]}"; do
    if ! grep -q "$pattern" .gitignore; then
        echo "❌ FAIL: .gitignore missing pattern: $pattern"
        FAILED=1
    fi
done
if [ $FAILED -eq 0 ]; then
    echo "✅ PASS: .gitignore is comprehensive"
fi

# Final result
echo ""
echo "========================================"
if [ $FAILED -eq 1 ]; then
    echo "❌ SECURITY CHECKS FAILED!"
    echo ""
    echo "DO NOT COMMIT until issues are resolved."
    echo "Review the failures above and fix them."
    echo ""
    exit 1
else
    echo "✅ ALL SECURITY CHECKS PASSED!"
    echo ""
    echo "Safe to commit to GitHub."
    echo ""
    echo "Next steps:"
    echo "  git add ."
    echo "  git commit -m 'Your commit message'"
    echo "  git push"
    echo ""
fi

exit 0

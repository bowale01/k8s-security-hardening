# Contributing Guidelines

Thank you for your interest in contributing to the Kubernetes Security Hardening project!

## Security First

**NEVER commit sensitive information:**
- AWS credentials or access keys
- Kubernetes kubeconfig files
- Private keys or certificates
- Terraform state files
- Actual .tfvars files (only .example files)
- Personal information

## Before You Commit

1. **Run the security check:**
   ```bash
   bash scripts/pre-commit-check.sh
   ```

2. **Review your changes:**
   ```bash
   git diff
   ```

3. **Verify .gitignore is working:**
   ```bash
   git status
   ```

## Code Standards

### Terraform
- Use variables for all configurable values
- Add comments explaining security controls
- Map to CIS/OWASP/NIST requirements
- Include examples in terraform.tfvars.example

### Kubernetes Policies
- Add annotations explaining the policy
- Reference CIS/OWASP/NIST controls
- Include real-world impact examples
- Test policies before committing

### Documentation
- Keep it clear and concise
- Include examples
- Update INDEX.md if adding new files
- No personal information

### Scripts
- Add header comments
- Use environment variables for sensitive data
- Include error handling
- Make them executable: `chmod +x script.sh`

## Pull Request Process

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run security checks
5. Update documentation
6. Submit pull request

## Questions?

Open an issue for:
- Bug reports
- Feature requests
- Documentation improvements
- Security concerns

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

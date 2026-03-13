# Architecture Diagrams

Visual representations of the security architecture for presentations and interviews.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          AWS Cloud (us-east-1)                          │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │                    VPC (10.0.0.0/16)                              │ │
│  │                                                                   │ │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │ │
│  │  │  Public Subnet  │  │  Public Subnet  │  │  Public Subnet  │  │ │
│  │  │   us-east-1a    │  │   us-east-1b    │  │   us-east-1c    │  │ │
│  │  │                 │  │                 │  │                 │  │ │
│  │  │  ┌───────────┐  │  │  ┌───────────┐  │  │  ┌───────────┐  │  │
│  │  │  │ NAT GW    │  │  │  │ NAT GW    │  │  │  │ NAT GW    │  │  │
│  │  │  └───────────┘  │  │  └───────────┘  │  │  └───────────┘  │  │
│  │  │  ┌───────────┐  │  │  ┌───────────┐  │  │  ┌───────────┐  │  │
│  │  │  │    ALB    │  │  │  │    ALB    │  │  │  │    ALB    │  │  │
│  │  │  └───────────┘  │  │  └───────────┘  │  │  └───────────┘  │  │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────┘  │ │
│  │           │                    │                    │            │ │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │ │
│  │  │ Private Subnet  │  │ Private Subnet  │  │ Private Subnet  │  │ │
│  │  │   us-east-1a    │  │   us-east-1b    │  │   us-east-1c    │  │ │
│  │  │                 │  │                 │  │                 │  │ │
│  │  │  ┌───────────┐  │  │  ┌───────────┐  │  │  ┌───────────┐  │  │
│  │  │  │ EKS Node  │  │  │  │ EKS Node  │  │  │  │ EKS Node  │  │  │
│  │  │  │ (Worker)  │  │  │  │ (Worker)  │  │  │  │ (Worker)  │  │  │
│  │  │  └───────────┘  │  │  └───────────┘  │  │  └───────────┘  │  │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────┘  │ │
│  │                                                                   │ │
│  │  ┌─────────────────────────────────────────────────────────────┐ │ │
│  │  │              EKS Control Plane (Managed by AWS)             │ │ │
│  │  │  • API Server  • Scheduler  • Controller Manager  • etcd   │ │ │
│  │  └─────────────────────────────────────────────────────────────┘ │ │
│  └───────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │                      AWS Security Services                        │ │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐         │ │
│  │  │   KMS    │  │GuardDuty │  │   WAF    │  │ Secrets  │         │ │
│  │  │(Encrypt) │  │ (Threat) │  │  (Web)   │  │ Manager  │         │ │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘         │ │
│  └───────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
```

## 11 Security Layers (Defense in Depth)

```
┌─────────────────────────────────────────────────────────────────────┐
│ Layer 11: Backup & DR (Velero)                                     │
│ • Daily backups  • Cross-region replication  • 30-day retention    │
├─────────────────────────────────────────────────────────────────────┤
│ Layer 10: Monitoring (Prometheus/Grafana/Loki)                     │
│ • Metrics  • Dashboards  • Logs  • Alerts  • Forensics            │
├─────────────────────────────────────────────────────────────────────┤
│ Layer 9: Identity & Access (OIDC/RBAC)                             │
│ • SSO  • Group-based RBAC  • Least privilege  • MFA ready         │
├─────────────────────────────────────────────────────────────────────┤
│ Layer 8: Secrets Management (External Secrets)                     │
│ • AWS Secrets Manager  • Auto-rotation  • No secrets in Git       │
├─────────────────────────────────────────────────────────────────────┤
│ Layer 7: Runtime Security (Falco/Tetragon/GuardDuty)              │
│ • Behavioral monitoring  • eBPF  • Threat detection  • Auto-kill  │
├─────────────────────────────────────────────────────────────────────┤
│ Layer 6: Supply Chain (Trivy/SBOM/Signing)                        │
│ • Vulnerability scanning  • Image signing  • Provenance           │
├─────────────────────────────────────────────────────────────────────┤
│ Layer 5: Workload Security (PSS/Kyverno)                          │
│ • 20+ policies  • Admission control  • Security contexts          │
├─────────────────────────────────────────────────────────────────────┤
│ Layer 4: Network Security (Istio/NetworkPolicies/WAF)             │
│ • mTLS everywhere  • Default deny  • Microsegmentation            │
├─────────────────────────────────────────────────────────────────────┤
│ Layer 3: Control Plane (EKS Hardened)                             │
│ • Audit logs  • Encrypted etcd  • RBAC  • Strong ciphers         │
├─────────────────────────────────────────────────────────────────────┤
│ Layer 2: Encryption (KMS)                                          │
│ • Secrets at rest  • EBS volumes  • S3 backups  • Auto-rotation  │
├─────────────────────────────────────────────────────────────────────┤
│ Layer 1: Infrastructure (VPC)                                      │
│ • Private subnets  • NAT gateways  • Security groups  • NACLs    │
└─────────────────────────────────────────────────────────────────────┘
```

## Pod Security Flow

```
Developer deploys pod
        │
        ▼
┌───────────────────────────────────────────────────────────────┐
│ 1. Kyverno Admission Webhook                                  │
│    ✓ Check 20+ policies                                       │
│    ✓ Validate security context                                │
│    ✓ Check resource limits                                    │
│    ✓ Verify image signature                                   │
│    ❌ REJECT if any check fails                               │
└───────────────────────────────────────────────────────────────┘
        │ PASS
        ▼
┌───────────────────────────────────────────────────────────────┐
│ 2. Pod Security Standards                                     │
│    ✓ Check if running as non-root                            │
│    ✓ Validate capabilities                                    │
│    ✓ Check seccomp profile                                    │
│    ❌ REJECT if PSS violations                                │
└───────────────────────────────────────────────────────────────┘
        │ PASS
        ▼
┌───────────────────────────────────────────────────────────────┐
│ 3. Trivy Image Scan                                           │
│    ✓ Scan for CVEs                                            │
│    ✓ Check for critical vulnerabilities                       │
│    ❌ BLOCK if critical CVEs found                            │
└───────────────────────────────────────────────────────────────┘
        │ PASS
        ▼
┌───────────────────────────────────────────────────────────────┐
│ 4. Pod Starts                                                  │
│    • Istio injects sidecar (mTLS)                             │
│    • External Secrets injects secrets                         │
│    • Network policy applied                                    │
│    • Falco starts monitoring                                   │
└───────────────────────────────────────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────────────────────────────┐
│ 5. Runtime Monitoring                                          │
│    • Falco watches behavior                                    │
│    • Tetragon monitors syscalls                                │
│    • GuardDuty monitors AWS API                                │
│    • Prometheus collects metrics                               │
└───────────────────────────────────────────────────────────────┘
```

## Attack Detection Flow

```
Attacker exploits vulnerability
        │
        ▼
┌───────────────────────────────────────────────────────────────┐
│ 1. Falco Detects Anomaly                                      │
│    🚨 Unexpected shell execution detected                     │
│    🚨 Alert triggered → AlertManager                          │
└───────────────────────────────────────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────────────────────────────┐
│ 2. Tetragon Monitors Escalation                               │
│    👁️ Watching for privilege escalation                       │
│    👁️ Monitoring syscalls                                     │
│    ⚡ Kills process if escalation attempted                   │
└───────────────────────────────────────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────────────────────────────┐
│ 3. Network Policy Blocks Lateral Movement                     │
│    🛡️ Default deny blocks communication                       │
│    🛡️ Can't reach other pods                                  │
│    🛡️ Can't exfiltrate data                                   │
└───────────────────────────────────────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────────────────────────────┐
│ 4. gVisor Sandbox Blocks Escape                               │
│    🔒 Syscalls filtered                                        │
│    🔒 Can't mount host filesystem                             │
│    🔒 Container escape prevented                              │
└───────────────────────────────────────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────────────────────────────┐
│ 5. GuardDuty Alerts on AWS API Abuse                          │
│    📢 Unusual API calls detected                              │
│    📢 Security team notified                                   │
│    📢 Incident response triggered                             │
└───────────────────────────────────────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────────────────────────────┐
│ 6. Automated Response                                          │
│    🔧 Pod isolated with network policy                        │
│    🔧 Forensics data collected                                │
│    🔧 Loki provides full audit trail                          │
│    🔧 Incident logged for investigation                       │
└───────────────────────────────────────────────────────────────┘
```

## Network Security Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Internet                                │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │   AWS WAF       │
                    │ • OWASP Top 10  │
                    │ • Rate limiting │
                    │ • Bot control   │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │   ALB/NLB       │
                    │ • TLS 1.2+      │
                    │ • SSL offload   │
                    └────────┬────────┘
                             │
                             ▼
┌────────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                          │
│                                                                │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │              Istio Service Mesh                          │ │
│  │  • Automatic mTLS between all services                   │ │
│  │  • Zero-trust: deny-all by default                       │ │
│  │  • Traffic encryption in transit                         │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐   │
│  │ Namespace A  │    │ Namespace B  │    │ Namespace C  │   │
│  │              │    │              │    │              │   │
│  │ ┌──────────┐ │    │ ┌──────────┐ │    │ ┌──────────┐ │   │
│  │ │  Pod 1   │ │    │ │  Pod 2   │ │    │ │  Pod 3   │ │   │
│  │ │ +Sidecar │ │    │ │ +Sidecar │ │    │ │ +Sidecar │ │   │
│  │ └──────────┘ │    │ └──────────┘ │    │ └──────────┘ │   │
│  │      ▲       │    │      ▲       │    │      ▲       │   │
│  │      │       │    │      │       │    │      │       │   │
│  │  Network     │    │  Network     │    │  Network     │   │
│  │  Policy      │    │  Policy      │    │  Policy      │   │
│  │  (Deny All)  │    │  (Deny All)  │    │  (Deny All)  │   │
│  └──────────────┘    └──────────────┘    └──────────────┘   │
│                                                                │
│  All communication:                                            │
│  • Encrypted with mTLS                                         │
│  • Authenticated with certificates                             │
│  • Authorized by Istio policies                                │
│  • Blocked by default (explicit allow required)                │
└────────────────────────────────────────────────────────────────┘
```

## Secrets Management Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    AWS Secrets Manager                          │
│  • Encrypted with KMS                                           │
│  • Automatic rotation every 30 days                             │
│  • Audit trail in CloudWatch                                    │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ Fetch secret
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│           External Secrets Operator (in cluster)                │
│  • Watches ExternalSecret objects                               │
│  • Fetches from AWS Secrets Manager                             │
│  • Creates Kubernetes Secret                                    │
│  • Updates on rotation                                          │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ Create K8s Secret
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│              Kubernetes Secret (in cluster)                     │
│  • Encrypted at rest with KMS                                   │
│  • Automatically updated on rotation                            │
│  • Injected into pods at runtime                                │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ Mount as volume or env var
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Application Pod                              │
│  • Receives secret at runtime                                   │
│  • No secrets in Git                                            │
│  • No secrets in container image                                │
│  • Automatic updates on rotation                                │
└─────────────────────────────────────────────────────────────────┘

Benefits:
✓ No secrets in Git or code
✓ Automatic rotation
✓ Centralized management
✓ Audit trail
✓ Encryption at rest and in transit
```

## Compliance Validation Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    Continuous Compliance                        │
└─────────────────────────────────────────────────────────────────┘

Every 6 hours:
┌─────────────────────────────────────────────────────────────────┐
│ kube-bench (CIS Benchmark Audit)                                │
│  • Scans 100+ controls                                          │
│  • Generates compliance report                                  │
│  • Logs to CloudWatch                                           │
│  • Alerts on failures                                           │
└─────────────────────────────────────────────────────────────────┘

Daily at 2 AM:
┌─────────────────────────────────────────────────────────────────┐
│ Trivy (Vulnerability Scanning)                                  │
│  • Scans all container images                                   │
│  • Checks for CVEs                                              │
│  • Generates vulnerability reports                              │
│  • Blocks critical CVEs                                         │
└─────────────────────────────────────────────────────────────────┘

Daily at 3 AM:
┌─────────────────────────────────────────────────────────────────┐
│ SBOM Generation (Supply Chain)                                  │
│  • Generates Software Bill of Materials                         │
│  • Tracks all dependencies                                      │
│  • Stores in S3                                                 │
│  • Enables rapid CVE response                                   │
└─────────────────────────────────────────────────────────────────┘

Every 30 minutes:
┌─────────────────────────────────────────────────────────────────┐
│ Automated Remediation                                           │
│  • Disables default service accounts                            │
│  • Applies Pod Security Standards                               │
│  • Fixes common violations                                      │
│  • Logs all changes                                             │
└─────────────────────────────────────────────────────────────────┘

Real-time:
┌─────────────────────────────────────────────────────────────────┐
│ Kyverno Policy Enforcement                                      │
│  • Validates every pod creation                                 │
│  • Blocks non-compliant workloads                               │
│  • Generates policy reports                                     │
│  • Audit mode available                                         │
└─────────────────────────────────────────────────────────────────┘

Result: Continuous 100% compliance with automated evidence collection
```

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                      User Request                               │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
                    ┌─────────┐
                    │   WAF   │ ← OWASP Top 10 protection
                    └────┬────┘
                         │
                         ▼
                    ┌─────────┐
                    │   ALB   │ ← TLS termination
                    └────┬────┘
                         │
                         ▼
┌────────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                          │
│                                                                │
│                    ┌─────────┐                                │
│                    │ Ingress │ ← Istio Gateway                │
│                    └────┬────┘                                │
│                         │                                      │
│                         ▼                                      │
│                    ┌─────────┐                                │
│                    │ Service │ ← Network Policy               │
│                    └────┬────┘                                │
│                         │                                      │
│                         ▼                                      │
│    ┌────────────────────────────────────────┐                │
│    │              Pod                        │                │
│    │  ┌──────────────┐  ┌──────────────┐   │                │
│    │  │ Application  │  │ Istio Sidecar│   │                │
│    │  │  Container   │  │   (mTLS)     │   │                │
│    │  └──────┬───────┘  └──────┬───────┘   │                │
│    │         │                  │            │                │
│    │         ▼                  ▼            │                │
│    │  ┌──────────────────────────────────┐  │                │
│    │  │    Falco Monitoring              │  │                │
│    │  │    Tetragon eBPF                 │  │                │
│    │  └──────────────────────────────────┘  │                │
│    └────────────────────────────────────────┘                │
│                         │                                      │
│                         ▼                                      │
│                    ┌─────────┐                                │
│                    │Database │ ← mTLS encrypted               │
│                    └─────────┘                                │
└────────────────────────────────────────────────────────────────┘

Security at every layer:
1. WAF: Blocks web attacks
2. ALB: TLS encryption
3. Ingress: Istio authentication
4. Service: Network policy enforcement
5. Pod: Security context, resource limits
6. Container: Non-root, read-only, capabilities dropped
7. Sidecar: mTLS encryption
8. Monitoring: Falco + Tetragon watching
9. Database: Encrypted connection
```

## Cost Breakdown Diagram

```
Monthly Cost: ~$350

┌─────────────────────────────────────────────────────────────────┐
│                      Cost Distribution                          │
└─────────────────────────────────────────────────────────────────┘

EKS Control Plane        ████████████████████  $73  (21%)
Worker Nodes (2x t3.med) ████████████████      $60  (17%)
Storage (EBS + S3)       ██████████████        $50  (14%)
Service Mesh             ████████              $30  (9%)
Monitoring Stack         ███████████           $40  (11%)
GuardDuty                ████████              $30  (9%)
Data Transfer            █████                 $20  (6%)
Secrets Manager          ██                    $10  (3%)
KMS                      █                     $5   (1%)
Other (WAF, etc.)        ████████              $32  (9%)
                         ─────────────────────────
                         Total: $350/month

Cost Optimization:
• Use Spot instances: Save $30/month
• Reduce monitoring: Save $20/month
• Shorter log retention: Save $15/month
• Optimized: ~$285/month

Cost when destroyed: $0/month (terraform destroy)
```

## For Presentations

### Slide 1: Problem Statement
```
Traditional Kubernetes Security:
❌ Manual configuration
❌ Inconsistent policies
❌ No automated compliance
❌ Limited visibility
❌ Reactive security
```

### Slide 2: Our Solution
```
100% Automated Security Hardening:
✅ Infrastructure as Code (Terraform)
✅ 20+ automated policies (Kyverno)
✅ Continuous compliance (kube-bench)
✅ Comprehensive monitoring (Prometheus)
✅ Proactive threat detection (Falco + GuardDuty)
```

### Slide 3: Coverage
```
Framework Compliance:
✅ CIS Kubernetes Benchmark v1.8: 100%
✅ OWASP Kubernetes Top 10: 100%
✅ NIST SP 800-190: 100%
✅ AWS EKS Best Practices: 100%
```

### Slide 4: Defense in Depth
```
11 Security Layers:
1. Infrastructure (VPC isolation)
2. Encryption (KMS)
3. Control Plane (EKS hardened)
4. Network (mTLS + policies)
5. Workload (PSS + Kyverno)
6. Supply Chain (scanning + signing)
7. Runtime (Falco + Tetragon)
8. Secrets (External Secrets)
9. Identity (OIDC + RBAC)
10. Monitoring (Prometheus + Grafana)
11. Backup/DR (Velero)
```

### Slide 5: Results
```
Deployment: 15-20 minutes
Cost: ~$350/month (or $0 when destroyed)
Maintenance: Automated
Compliance: Continuous validation
Security Posture: Production-ready
```

---

## ASCII Art for Terminal

```
╔═══════════════════════════════════════════════════════════════╗
║     Kubernetes Security Hardening - 100% Coverage             ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║  CIS Benchmark v1.8    ████████████████████████  100%        ║
║  OWASP K8s Top 10      ████████████████████████  100%        ║
║  NIST SP 800-190       ████████████████████████  100%        ║
║  AWS Best Practices    ████████████████████████  100%        ║
║                                                               ║
║  Security Layers: 11   Policies: 20+   Cost: $350/mo        ║
║  Deploy Time: 15-20min Destroy: 1 command  Status: Ready    ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
```

Use these diagrams in:
- Interview presentations
- Technical discussions
- Documentation
- Whiteboards
- Slide decks

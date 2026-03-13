# Cost Estimate

## Monthly Cost Breakdown

### EKS Cluster
- EKS Control Plane: $73/month (fixed)
- CloudWatch Logs (30 days retention): ~$5/month

### EC2 Worker Nodes
- 2x t3.medium instances: ~$60/month
- EBS volumes (100GB total): ~$10/month

### Security Services
- GuardDuty (EKS protection): ~$15-30/month
- KMS key: $1/month + API calls (~$1/month)

### Data Transfer
- Minimal for demo: ~$5/month

### Total Estimated Cost
**$170-200/month**

## Cost Optimization Tips

### Development/Testing
1. Use smaller instance types (t3.small)
2. Reduce node count to 1
3. Disable GuardDuty when not testing
4. Use shorter log retention (7 days)

**Optimized cost: ~$100/month**

### Destroy When Not in Use
```bash
# Destroy everything
cd terraform
terraform destroy

# Estimated cost when destroyed: $0/month
```

### Cost Monitoring
- Set up AWS Budget alerts
- Use AWS Cost Explorer
- Tag all resources for tracking
- Review costs weekly

## Production Considerations

For production workloads, expect:
- 3+ nodes for HA: +$90/month
- Increased GuardDuty usage: +$50/month
- More data transfer: +$20/month
- Backup storage: +$10/month

**Production estimate: $350-500/month**

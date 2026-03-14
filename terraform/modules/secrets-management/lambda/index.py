# ============================================================================
# SECRETS ROTATION LAMBDA
# ============================================================================
# Rotates AWS Secrets Manager secrets every 30 days.
# Triggered by EventBridge on a schedule.
#
# Why this matters:
# - OWASP K08: Secrets Management Failures
# - Limits the window of exposure if a secret is compromised
# - Automated rotation removes human error from the process
# ============================================================================

import boto3
import os
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def handler(event, context):
    """
    Rotates all secrets tagged for the cluster.
    In a real implementation this would call the rotation logic
    specific to each secret type (DB password, API key, etc.)
    """
    cluster_name = os.environ.get("CLUSTER_NAME", "unknown")
    client = boto3.client("secretsmanager")

    logger.info(f"Starting secrets rotation for cluster: {cluster_name}")

    try:
        # List secrets belonging to this cluster
        paginator = client.get_paginator("list_secrets")
        for page in paginator.paginate(
            Filters=[{"Key": "name", "Values": [f"{cluster_name}/"]}]
        ):
            for secret in page.get("SecretList", []):
                secret_id = secret["ARN"]
                logger.info(f"Rotating secret: {secret['Name']}")
                # Trigger rotation (rotation lambda must be configured per secret)
                client.rotate_secret(SecretId=secret_id)

        logger.info("Secrets rotation completed successfully")
        return {"statusCode": 200, "body": "Rotation triggered"}

    except Exception as e:
        logger.error(f"Rotation failed: {str(e)}")
        raise

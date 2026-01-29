#!/bin/bash

set -euo pipefail

POLICY_ARN="${POLICY_ARN:-}"

if [ -z "$POLICY_ARN" ]; then
  echo "Error: POLICY_ARN environment variable is required"
  echo "Usage: POLICY_ARN=arn:aws:iam::123456789012:policy/WorkshopParticipantPolicy ./cleanup-workshop.sh"
  exit 1
fi

echo "Terminating all EC2 instances..."
INSTANCE_IDS=$(aws ec2 describe-instances \
  --query 'Reservations[].Instances[].InstanceId' \
  --filters "Name=instance-state-name,Values=running,stopped,pending" \
  --output text)

if [ -n "$INSTANCE_IDS" ]; then
  aws ec2 terminate-instances --instance-ids $INSTANCE_IDS
  echo "Waiting for instances to terminate..."
  aws ec2 wait instance-terminated --instance-ids $INSTANCE_IDS
fi

echo "Deleting workshop S3 buckets..."
for bucket in $(aws s3 ls | grep 'workshop-' | awk '{print $3}'); do
  echo "Deleting $bucket..."
  aws s3 rb "s3://$bucket" --force
done

echo "Deleting workshop IAM users..."
for i in $(seq -w 1 50); do
  USERNAME="workshop-user-${i}"
  echo "Deleting $USERNAME..."

  aws iam detach-user-policy \
    --user-name "$USERNAME" \
    --policy-arn "$POLICY_ARN" 2>/dev/null || true

  for key in $(aws iam list-access-keys --user-name "$USERNAME" --query 'AccessKeyMetadata[].AccessKeyId' --output text 2>/dev/null); do
    aws iam delete-access-key --user-name "$USERNAME" --access-key-id "$key"
  done

  aws iam delete-login-profile --user-name "$USERNAME" 2>/dev/null || true
  aws iam delete-user --user-name "$USERNAME" 2>/dev/null || true
done

echo "Cleanup complete!"

#!/usr/bin/env bash

set -euo pipefail

AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-}"
USER_COUNT="${USER_COUNT:-50}"
MAX_PARALLEL="${MAX_PARALLEL:-10}"

if [ -z "$AWS_ACCOUNT_ID" ]; then
  AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null) || {
    echo "Error: Could not determine AWS account ID. Set AWS_ACCOUNT_ID or configure AWS CLI."
    exit 1
  }
fi

POLICY_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:policy/WorkshopParticipantPolicy"

echo "Account: $AWS_ACCOUNT_ID"

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

echo "Deleting workshop IAM users (max $MAX_PARALLEL in parallel)..."

delete_user() {
  local username="$1"
  local policy_arn="$2"

  echo "Deleting $username..."

  aws iam detach-user-policy \
    --user-name "$username" \
    --policy-arn "$policy_arn" 2>/dev/null || true

  for key in $(aws iam list-access-keys --user-name "$username" --query 'AccessKeyMetadata[].AccessKeyId' --output text 2>/dev/null); do
    aws iam delete-access-key --user-name "$username" --access-key-id "$key"
  done

  aws iam delete-login-profile --user-name "$username" 2>/dev/null || true
  aws iam delete-user --user-name "$username" 2>/dev/null || true
}

export -f delete_user

seq -w 1 "$USER_COUNT" | xargs -P "$MAX_PARALLEL" -I {} bash -c 'delete_user "workshop-user-{}" "$1"' _ "$POLICY_ARN"

echo "Cleanup complete!"

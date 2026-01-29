#!/bin/bash

set -euo pipefail

AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-}"
USER_COUNT="${USER_COUNT:-50}"
OUTPUT_FILE="workshop-credentials.csv"

if [ -z "$AWS_ACCOUNT_ID" ]; then
  AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null) || {
    echo "Error: Could not determine AWS account ID. Set AWS_ACCOUNT_ID or configure AWS CLI."
    exit 1
  }
fi

POLICY_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:policy/WorkshopParticipantPolicy"

echo "Account: $AWS_ACCOUNT_ID"
echo "Creating $USER_COUNT users..."
echo "username,password,access_key_id,secret_access_key" > "$OUTPUT_FILE"

for i in $(seq -w 1 "$USER_COUNT"); do
  USERNAME="workshop-user-${i}"
  PASSWORD="Workshop$(openssl rand -hex 4)!"

  echo "Creating $USERNAME..."

  aws iam create-user --user-name "$USERNAME"

  aws iam create-login-profile \
    --user-name "$USERNAME" \
    --password "$PASSWORD" \
    --no-password-reset-required

  KEYS=$(aws iam create-access-key --user-name "$USERNAME")
  ACCESS_KEY=$(echo "$KEYS" | jq -r '.AccessKey.AccessKeyId')
  SECRET_KEY=$(echo "$KEYS" | jq -r '.AccessKey.SecretAccessKey')

  aws iam attach-user-policy \
    --user-name "$USERNAME" \
    --policy-arn "$POLICY_ARN"

  echo "$USERNAME,$PASSWORD,$ACCESS_KEY,$SECRET_KEY" >> "$OUTPUT_FILE"
done

echo "Done! Credentials saved to $OUTPUT_FILE"

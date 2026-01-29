#!/bin/bash

set -euo pipefail

POLICY_ARN="${POLICY_ARN:-}"
OUTPUT_FILE="workshop-credentials.csv"

if [ -z "$POLICY_ARN" ]; then
  echo "Error: POLICY_ARN environment variable is required"
  echo "Usage: POLICY_ARN=arn:aws:iam::123456789012:policy/WorkshopParticipantPolicy ./create-users.sh"
  exit 1
fi

echo "username,password,access_key_id,secret_access_key" > "$OUTPUT_FILE"

for i in $(seq -w 1 50); do
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

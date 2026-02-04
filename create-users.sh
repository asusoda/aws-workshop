#!/usr/bin/env bash

set -euo pipefail

AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-}"
USER_COUNT="${USER_COUNT:-50}"
MAX_PARALLEL="${MAX_PARALLEL:-10}"
OUTPUT_FILE="workshop-credentials.csv"

if [ -z "$AWS_ACCOUNT_ID" ]; then
  AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null) || {
    echo "Error: Could not determine AWS account ID. Set AWS_ACCOUNT_ID or configure AWS CLI."
    exit 1
  }
fi

POLICY_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:policy/WorkshopParticipantPolicy"

echo "Account: $AWS_ACCOUNT_ID"
echo "Creating $USER_COUNT users (max $MAX_PARALLEL in parallel)..."

TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

create_user() {
  local i="$1"
  local policy_arn="$2"
  local temp_dir="$3"

  USERNAME="workshop-user-${i}"
  PASSWORD="Workshop$(openssl rand -hex 4)!"

  echo "Creating $USERNAME..."

  aws iam create-user --user-name "$USERNAME" >/dev/null

  aws iam create-login-profile \
    --user-name "$USERNAME" \
    --password "$PASSWORD" \
    --no-password-reset-required >/dev/null

  KEYS=$(aws iam create-access-key --user-name "$USERNAME" --output json)
  ACCESS_KEY=$(echo "$KEYS" | jq -r '.AccessKey.AccessKeyId')
  SECRET_KEY=$(echo "$KEYS" | jq -r '.AccessKey.SecretAccessKey')

  aws iam attach-user-policy \
    --user-name "$USERNAME" \
    --policy-arn "$policy_arn" >/dev/null

  echo "$USERNAME,$PASSWORD,$ACCESS_KEY,$SECRET_KEY" > "$temp_dir/$i.csv"
}

export -f create_user

seq -w 1 "$USER_COUNT" | xargs -P "$MAX_PARALLEL" -I {} bash -c 'create_user "$@"' _ {} "$POLICY_ARN" "$TEMP_DIR"

echo "username,password,access_key_id,secret_access_key" > "$OUTPUT_FILE"
if compgen -G "$TEMP_DIR/*.csv" > /dev/null; then
  for f in "$TEMP_DIR"/*.csv; do
    cat "$f" >> "$OUTPUT_FILE"
  done
fi

echo "Done! Credentials saved to $OUTPUT_FILE"

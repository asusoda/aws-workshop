# AWS Workshop

Scripts to provision 50 sandboxed IAM users for an intro AWS workshop. Participants get EC2 and S3 access without needing credit cards.

## Setup

```bash
# 1. Create the IAM policy
aws iam create-policy \
  --policy-name WorkshopParticipantPolicy \
  --policy-document file://workshop-policy.json

# 2. Create users (outputs credentials to workshop-credentials.csv)
POLICY_ARN=arn:aws:iam::ACCOUNT_ID:policy/WorkshopParticipantPolicy ./create-users.sh
```

## Cleanup

```bash
POLICY_ARN=arn:aws:iam::ACCOUNT_ID:policy/WorkshopParticipantPolicy ./cleanup-workshop.sh
```

## What participants can do

- Launch t2.micro/t3.micro EC2 instances
- Create S3 buckets prefixed with `workshop-`
- Expensive services (RDS, EKS, etc.) are explicitly denied

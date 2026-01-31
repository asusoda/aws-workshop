# AWS Workshop

Scripts to provision sandboxed IAM users for an intro AWS workshop. The policy is set up so that only the services required for the workshop are allowed.

## Prerequisites

- [mise](https://mise.jdx.dev/installing-mise.html) for task running
- [aws cli v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
  - to configure credentials, i did the quick unsafe path by yoinking root account access keys from [here](https://us-east-1.console.aws.amazon.com/iam/home?region=us-east-1#/security_credentials) (after authing into shared SoDA login using credentials from The Login Sheet) and put them in my local `credentials` file according to [these docs](https://docs.aws.amazon.com/sdkref/latest/guide/access-iam-users.html)

## Setup

```bash
mise run create-policy   # one-time setup
mise run create-users    # creates 50 users, outputs to workshop-credentials.csv
```

Test with fewer users first:
```bash
USER_COUNT=2 mise run create-users
```

## Cleanup

Terminates all EC2 instances, deletes `workshop-*` S3 buckets, and removes IAM users.

```bash
mise run cleanup
```

## Distributing credentials

Mail merge via Google Apps Script:

1. Create a new Google Sheet, open **Extensions → Apps Script**
2. Paste contents of `mail-merge.js`
3. Replace `CREDENTIALS_CSV` with contents of `workshop-credentials.csv`
4. Replace `ATTENDEES_CSV` with attendee names/emails (just `First Name,Email` columns)
5. Click **Run** and authorize when prompted

The script assigns credentials to attendees in order and emails each their login info.

# Daily digest scripts → n8n webhooks → AWS SES email

Three host scripts collect data and POST it to n8n. Each n8n workflow runs the JSON through Bedrock Claude and sends the summary as email via AWS SES.

## Files

| Script | Webhook path | Workflow JSON |
|---|---|---|
| `authelia-audit.sh` | `/webhook/authelia-audit` | `../workflows/authelia-audit.json` |
| `container-restart-digest.sh` | `/webhook/container-restart-digest` | `../workflows/container-restart-digest.json` |
| `pacman-summary.sh` | `/webhook/pacman-summary` | `../workflows/pacman-summary.json` |

## One-time setup

### 1. Verify the SES sender address (sandbox mode)

AWS SES starts in sandbox — you can only send TO and FROM verified addresses. Verify `ahuja.madhur@gmail.com`:

```
aws ses verify-email-identity --email-address ahuja.madhur@gmail.com --region <your-ses-region>
```

Click the verification link Amazon emails you. (Or do it in the AWS console → SES → Verified identities.)

If your existing AWS IAM user doesn't have SES perms, attach `AmazonSESFullAccess` (or a tighter policy with `ses:SendEmail`).

### 2. Import the n8n workflows

In n8n UI: **Workflows → Import from File** → pick each JSON in `../workflows/`. Then for each:
- Open the **AWS Bedrock Chat Model** node, confirm the credential is your existing "AWS (IAM) account".
- Open the **Send Email (SES)** node, confirm the credential is the same. If SES is in a different region than Bedrock, you may need a second AWS credential pinned to the SES region.
- Toggle the workflow **Active**.

### 3. Enable the systemd timers

```
systemctl --user daemon-reload
systemctl --user enable --now authelia-audit.timer container-restart-digest.timer pacman-summary.timer
systemctl --user list-timers | grep -E 'authelia|container|pacman'
```

Timers fire daily at 08:00 / 08:05 / 08:10 (staggered).

## Manual test

```
# Test the script end-to-end (will POST to webhook + send email)
~/docker/n8n/scripts/authelia-audit.sh

# Test with custom window
SINCE=7d ~/docker/n8n/scripts/pacman-summary.sh

# Override webhook URL (e.g. to httpbin.org/post for dry-run)
WEBHOOK_URL=https://httpbin.org/post ~/docker/n8n/scripts/container-restart-digest.sh
```

## Why no `set -e`

The scripts use `set -uo pipefail` instead of `set -euo pipefail` because `grep` returning non-zero on no-match (which is normal for "no failed logins today") would otherwise abort the script. Errors are handled explicitly with `|| true` where expected.

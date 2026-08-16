# ntfy

Push notification server at `ntfy.madhur.co.in`, image `binwiederhier/ntfy`.

## Auth

`auth-file` + `auth-default-access: deny-all` (enabled 2026-08-16) — every
topic requires authentication for both publish and subscribe. Two
credential types are in use:

- **Personal login** — user `madhur` (admin role), used for the web UI /
  Android app. Password lives in Vaultwarden.
- **Shared publisher token** — one access token (`ntfy token list madhur`
  on the container to see its label/expiry), used by every script/service
  that publishes notifications. Wired in via each execution boundary's own
  secret store:
  - `~/.ntfy_config` (shell scripts via `homelab-ntfy` CLI)
  - `/home/madhur/Desktop/python/.env` (Python scripts via `NtfyNotifier`)
  - `ntopng-flow-watch.service` systemd unit `Environment=`
  - `docker/gatus/.env`
  - n8n: a literal `Authorization: Bearer <token>` header parameter on
    every `httpRequest` node targeting `ntfy.madhur.co.in` (4 nodes across
    4 workflows as of 2026-08-16: Image Summarizer, Email Summarizer, PDF
    Summary Workflow, and SMS Realtime's "Alert parse failure" node). NOT
    an n8n credential object. Must be patched in BOTH
    `workflow_entity.nodes` and the newest `workflow_history.nodes` row
    for each workflow — n8n executes active workflows from
    `workflow_history`, so a UI-only edit leaves the old (unauthenticated)
    token live on the running workflow. Procedure: stop n8n, back up
    `database.sqlite`, patch both tables via SQLite (not a text edit),
    restart.
  - `~/.config/ntfy/client.yml` (`default-token:`) — the desktop `ntfy
    subscribe` CLI (`ntfy-subscribe.service`). This one is a reader, not a
    publisher, but it still holds the token and needs it to authenticate
    subscribe requests.

Rotate the shared token with `docker exec ntfy ntfy token add --label=publisher madhur`,
then update it in all six places above and revoke the old one with
`ntfy token remove madhur <old-token>`.

## Topics in use

| Topic | Publishers |
|---|---|
| `monitoring` | Gatus alerts, notify_wrapper.sh (daily/weekly cron), ntopng-flow-watch, n8n-sms-webhook-alert.sh, n8n "SMS Realtime → Actual + Firefly" (Alert parse failure node) |
| `systemd` | service-notifier.sh (systemd unit start/stop/fail hooks) |
| `bootup` | idle-alert-lib.sh (idle-shutdown warning) |
| `private` | screenshot-to-ntfy.sh, n8n "Image/Email Summarizer" workflows |
| `transactions` | loan_prepayment_digest.py, n8n "PDF Summary Workflow" |
| `weekly` / `daily` / `monthly` / `weather` / `backup` / `maintenance` / `olivetin` | notify_wrapper.sh cron jobs (every_week.sh / every_24_hours.sh / every_month.sh / OliveTin actions) |
| `changes` | changedetection.io (webpage change monitoring) |
| `mac-alerts` | off-host publisher (Mac) — **known gap**: not yet authenticated as of this writing, do not assume it works |
| `homelab-alerts` | no local publisher identified as of this writing — searched scripts/, Desktop/python/, docker/ configs, and ntfy's own message cache with no hits; flagged for follow-up rather than guessed |
| `test` | ad-hoc manual verification messages |

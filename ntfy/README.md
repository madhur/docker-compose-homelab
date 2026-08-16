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
  - n8n credential on the "Send to ntfy" HTTP Request nodes

Rotate the shared token with `docker exec ntfy ntfy token add --label=publisher madhur`,
then update it in all five places above and revoke the old one with
`ntfy token remove madhur <old-token>`.

## Topics in use

| Topic | Publishers |
|---|---|
| `monitoring` | Gatus alerts, notify_wrapper.sh (daily/weekly cron), ntopng-flow-watch, n8n-sms-webhook-alert.sh |
| `systemd` | service-notifier.sh (systemd unit start/stop/fail hooks) |
| `bootup` | idle-alert-lib.sh (idle-shutdown warning) |
| `private` | screenshot-to-ntfy.sh, n8n "Image/Email Summarizer" workflows |
| `transactions` | loan_prepayment_digest.py |
| `weekly` / `daily` / `weather` / `backup` / `maintenance` / `olivetin` | notify_wrapper.sh cron jobs (every_week.sh / every_24_hours.sh / OliveTin actions) |

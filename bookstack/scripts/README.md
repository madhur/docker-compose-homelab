# BookStack scripts

## bookstack-digest.sh — daily "what changed" digest → Mailpit

Lists BookStack **pages created or modified** in the last `WINDOW_HOURS` (default 24)
and emails a grouped summary (➕ Added / ✏️ Modified, with book, author, IST time and a
direct link) to **Mailpit** via SMTP. Sent as **dark-themed HTML** — Mailpit renders HTML
on a forced white canvas, so the email paints its own dark background (set on `html`+`body`
to fill the frame).

- **API:** queries `http://localhost:6875/api/pages` (token auth, no TLS/Authelia),
  plus `/api/books` (id→slug for links) and `/api/users` (id→author name).
  Timestamps come back as UTC ISO8601; the window is enforced client-side, IST shown in mail.
- **Delivery:** `curl --url smtp://localhost:1025` → Mailpit. Sender `bookstack-digest@madhur.co.in`,
  recipient `ahuja.madhur@gmail.com`. View at <https://mail.desktop.madhur.co.in>.
- **Empty days:** still sends a short "no changes" mail (set `SEND_WHEN_EMPTY=false` to skip).
- **Not covered:** deletions (the list API only returns live pages).

### Schedule
Registered in `~/scripts/every_24_hours.sh` (fired by the `every24hours.timer`, ~20:00 IST),
alongside the other daily digests. ntfy only pings on failure.

### Config / secrets
`bookstack-digest.env` (gitignored, `chmod 600`) holds the BookStack API token:

```sh
BS_TOKEN_ID=...
BS_TOKEN_SECRET=...
# optional: WINDOW_HOURS, SEND_WHEN_EMPTY, MAIL_TO
```

Generate the token in BookStack → profile → **API Tokens**.

### Manual run
```sh
./bookstack-digest.sh                 # last 24h
WINDOW_HOURS=720 ./bookstack-digest.sh  # last 30 days
```

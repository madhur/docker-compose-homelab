# BookStack → Markdown Sync for Agentic Search

**Date:** 2026-08-23
**Status:** Approved

## Problem

BookStack wiki content is only reachable through its web UI/API. There's no way
for a Claude Code session to search across it the way it searches a codebase
(grep/glob/read). The user wants an agentic-search-friendly copy of the wiki:
plain Markdown files on disk that any Claude Code session can read directly.

## Goals

- A folder of Markdown files, one per BookStack page, that Claude Code can
  Grep/Glob/Read without any extra tooling or server.
- Enough metadata in each file to cite the source page (title, book, URL) when
  a search result is used to answer a question.
- Kept reasonably fresh (daily) without building new infrastructure.

## Non-goals

- Vector DB / embeddings / RAG service.
- MCP server for non-Claude-Code tools.
- graphify knowledge-graph ingestion.
- Real-time sync via BookStack webhooks.
- Tracking deletions (BookStack's list API only returns live pages — same
  limitation the existing digest already accepts).

## Design

### Script: `scripts/sync-wiki-markdown.sh`

A new script, sibling to the existing `scripts/export-to-outline.sh` and
`scripts/export-to-wikijs.sh`, reusing their proven approach:

- **Auth:** reuses `scripts/bookstack-digest.env` (`BS_TOKEN_ID` /
  `BS_TOKEN_SECRET`) — the same token already used by the digest and the
  Outline/Wiki.js exporters. No new secret.
- **API calls:** `GET /api/books` (id → name), then paginated
  `GET /api/pages?count=500&offset=N&sort=priority`, then
  `GET /api/pages/{id}/export/markdown` per page. Same 429-retry-with-backoff
  and pacing (`sleep 0.3`) as `export-to-outline.sh`.
- **Output layout:** `scripts/wiki-export/<Book Name>/<Page Title>-<id>.md`
  — one folder per book, one file per page. The page id suffix prevents
  collisions between same-titled pages across books/priority reorders.
- **Frontmatter:** each file gets a YAML header prepended to the page's raw
  Markdown export:
  ```yaml
  ---
  title: <page name>
  book: <book name>
  url: https://bookstack.desktop.madhur.co.in/books/<book-slug>/page/<page-slug>
  page_id: <id>
  updated_at: <UTC ISO8601 from the API>
  ---
  ```
  This lets a search hit be traced back to a clickable source link without a
  second API call.
- **Rebuild strategy:** full rebuild every run (`rm -rf wiki-export && mkdir`,
  same as `export-to-outline.sh`). At this content scale a full rebuild is
  simpler and safer than incremental diffing (no orphan-file bugs when pages
  are renamed/moved/deleted). No zip step — the folder itself is the
  deliverable, not an import artifact.
- **Exit codes:** non-zero on any unrecoverable API failure (`set -euo
  pipefail`), so the cron wrapper's failure notification fires correctly.

### Scheduling

One line added to `~/scripts/every_24_hours.sh`, alongside the other daily
jobs, using the existing `notify_wrapper.sh`:

```sh
run_with_notification "/home/madhur/docker/bookstack/scripts/sync-wiki-markdown.sh" "BookStack Wiki Markdown Sync" "monitoring"
```

`run_with_notification` already handles ntfy-on-failure; no new alerting code
needed. Fires nightly with the rest of the `every24hours.timer` batch
(~20:00 IST).

### Git tracking

`docker/.gitignore` is a whitelist (`* / !*/ / !README.md / ...`), so
`scripts/wiki-export/**` (generated content) and the new script are ignored
by default — matching how `outline-export/`, `wikijs-export/`, and the
existing sync scripts are already handled. No `.gitignore` changes needed.

## Data flow

```
BookStack API (token auth, localhost:6875)
  → sync-wiki-markdown.sh (bash, reuses digest .env)
  → scripts/wiki-export/<Book>/<Page>-<id>.md  (+ frontmatter)
  → grep/glob/read by any Claude Code session
```

## Testing / verification

- Manual run: `./scripts/sync-wiki-markdown.sh`, then confirm folder count
  matches BookStack's total page count and spot-check 2-3 files for correct
  frontmatter + content.
- Confirm `run_with_notification` line runs clean in the next
  `every24hours.timer` firing (or a manual invocation of
  `every_24_hours.sh`), and that a deliberately broken API token produces an
  ntfy failure alert (verifying the failure path, not just the happy path).

## Future extensions (not now)

- If search quality on plain grep proves insufficient, revisit with the
  graphify or RAG/MCP options considered and deferred above.

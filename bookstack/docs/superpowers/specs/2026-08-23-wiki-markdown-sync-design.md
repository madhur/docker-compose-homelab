# BookStack ↔ Markdown Sync for Agentic Search

**Date:** 2026-08-23 (revised same day: read-only export → two-way sync;
further revised same day: add OliveTin buttons)
**Status:** Approved

## Problem

BookStack wiki content is only reachable through its web UI/API. There's no way
for a Claude Code session to search across it the way it searches a codebase
(grep/glob/read). The user wants an agentic-search-friendly copy of the wiki:
plain Markdown files on disk that any Claude Code session can read directly —
and the ability to edit (or add) that Markdown and push the change back into
BookStack.

## Goals

- A folder of Markdown files, one per BookStack page, that Claude Code can
  Grep/Glob/Read without any extra tooling or server.
- Enough metadata in each file to cite the source page (title, book, URL) when
  a search result is used to answer a question.
- Kept reasonably fresh (daily pull) without building new infrastructure.
- Edit a local file (or add a new one under an existing book's folder) and
  push that change into BookStack on demand.
- Never silently destroy content on either side — conflicting concurrent
  edits must be detected and left for the user to resolve, not overwritten.

## Non-goals

- Vector DB / embeddings / RAG service.
- MCP server for non-Claude-Code tools.
- graphify knowledge-graph ingestion.
- Real-time sync via BookStack webhooks or a file-watcher/daemon — push is a
  manually-run command.
- Creating new *books* from a new local folder (new pages only go into
  folders that already map to an existing book).
- Deleting BookStack pages when a local `.md` file is deleted, or vice versa.
- Chapter hierarchy (Book → Chapter → Page) — carried over from the existing
  `export-to-outline.sh` limitation; pages are flattened directly under their
  book's folder regardless of chapter.
- Automatic conflict *resolution* — conflicts are detected and surfaced, not
  merged or resolved automatically.

## Known limitation: matching is by filename, not `page_id`

`pull` locates a page's local file by recomputing `<slug(title)>-<id>.md`
from the API response and checking whether that path exists — it does not
look up the file via `.sync-state.json`'s `page_id` key. Consequence: if a
page's title is renamed directly in BookStack (outside this tool), the next
`pull` computes a different filename, doesn't find the old file, and creates
a fresh one under the new name — orphaning the old file from state tracking
(same failure class as the file-naming bug fixed in Tasks 3/4's review; see
`docs/superpowers/plans/2026-08-23-wiki-markdown-sync.md`'s Task 6 ledger
entry). `push`'s create-page path avoids this by renaming its own output to
match `pull`'s convention immediately, but a *remote* rename after the fact
isn't covered. Not fixed now — flagged as a known gap, same tier as the
chapter-hierarchy and deletion-propagation non-goals above. A future fix
would have `pull` fall back to a `page_id`-keyed lookup via
`.sync-state.json` before deciding a page is new.

## Design

### Script: `scripts/sync-wiki-markdown.sh {pull|push}`

A new script, sibling to the existing `scripts/export-to-outline.sh` and
`scripts/export-to-wikijs.sh`, reusing their proven approach to talking to the
BookStack API, but restructured around two explicit subcommands instead of a
single one-shot export.

- **Auth:** reuses `scripts/bookstack-digest.env` (`BS_TOKEN_ID` /
  `BS_TOKEN_SECRET`) — the same token already used by the digest and the
  Outline/Wiki.js exporters. No new secret.
- **Output layout:** `scripts/wiki-export/<Book Name>/<Page Title>-<id>.md`
  — one folder per book, one file per page. Same naming scheme as the
  original design.
- **Frontmatter** (unchanged from original design), prepended to each file's
  Markdown body:
  ```yaml
  ---
  title: <page name>
  book: <book name>
  url: https://bookstack.desktop.madhur.co.in/books/<book-slug>/page/<page-slug>
  page_id: <id>
  updated_at: <UTC ISO8601 from the API>
  ---
  ```
  Purely informational/citation metadata — excluded from the content hash
  described below, so editing your prose isn't confused with editing
  metadata, and vice versa.
- **New file (no `page_id`):** a file dropped into an existing book's folder
  with no frontmatter (or frontmatter missing `page_id`) is treated as a page
  to be created on the next `push`.

### Sync state: `scripts/wiki-export/.sync-state.json`

A local, gitignored bookkeeping file (not wiki content) mapping:

```json
{ "<page_id>": { "body_hash": "<sha256 of body, frontmatter stripped>",
                  "remote_updated_at": "<UTC ISO8601 as of last sync>" } }
```

This is the basis for detecting local edits (hash mismatch vs. last known
synced hash) and remote edits (API `updated_at` mismatch vs. last known
value) independently, which is what makes conflict detection possible.

### `pull` (BookStack → local; safe to run unattended, still nightly via cron)

For each page returned by the BookStack API, compare against
`.sync-state.json`:

| Local file state | Remote changed since last sync? | Action |
|---|---|---|
| Doesn't exist locally | — | Create file + frontmatter + state entry |
| Body hash matches state (untouched) | No | No-op |
| Body hash matches state (untouched) | Yes | Overwrite with fresh content + update state |
| Body hash differs from state (locally edited, unpushed) | No | Skip — preserve the local edit |
| Body hash differs from state (locally edited, unpushed) | **Yes** | **Conflict** — skip, print a warning naming the file, both copies left as-is |

Local files whose `page_id` is no longer present in the API response (page
deleted/moved remotely) are left in place untouched and are not reported as
an error — same "doesn't cover deletions" limitation the existing digest
already accepts.

Exit non-zero only on unrecoverable API failure (matching the cron wrapper's
failure-notification contract). Conflicts are reported to stdout/stderr but
do **not** fail the run — they're expected, recoverable state, not a script
failure.

### `push` (local → BookStack; manual only, never scheduled)

For each `.md` file under `scripts/wiki-export/<Book>/`:

| Local file state | Remote changed since last sync? | Action |
|---|---|---|
| Has `page_id`, body hash matches state | — | No-op (nothing to push) |
| Has `page_id`, body hash differs, remote `updated_at` matches state | — | `PUT /api/pages/{id}` with the markdown body and frontmatter `title` (renames the page too); update state with new hash + new `updated_at` from the response |
| Has `page_id`, body hash differs, remote `updated_at` differs from state | — | **Conflict** — skip, warn "pull first," leave local file untouched |
| No `page_id`, folder matches a known book | — | `POST /api/pages` with `book_id` + `title` (from frontmatter `title` if present, else first `#` heading, else filename) + markdown body; write the returned `id`/URL into the file's frontmatter; record state |
| No `page_id`, folder matches no known book | — | Skip, warn (no book auto-creation per design decision) |

### Scheduling

`pull` is non-destructive (never blind-overwrites an unpushed local edit), so
it stays safe to automate. One line added to `~/scripts/every_24_hours.sh`:

```sh
run_with_notification "/home/madhur/docker/bookstack/scripts/sync-wiki-markdown.sh pull" "BookStack Wiki Markdown Sync" "monitoring"
```

Reuses the existing `notify_wrapper.sh`; ntfy fires only on non-zero exit
(API failures), not on detected conflicts (those are printed, not fatal).

`push` is never scheduled — the user runs it explicitly after editing.

### OliveTin one-click buttons

In addition to the CLI (`./scripts/sync-wiki-markdown.sh {pull|push}`),
both subcommands get a button in OliveTin (`~/docker/olivetin`) under a new
**BookStack → Wiki Markdown Sync** dashboard section, so pull/push can be
triggered without SSHing into the host. Since OliveTin runs in a container
with no host filesystem access, its actions SSH to the host and invoke the
script there — the same `ssh -F /config/ssh/easy.cfg
madhur@local.madhur.co.in '...'` + `notify_wrapper.sh`/`run_with_notification`
pattern every other OliveTin action already uses (ntfy channel `"olivetin"`).
`push` being a button click away doesn't change its manual-only nature — it's
still never invoked by cron, only by an explicit click (CLI or OliveTin).

### Git tracking

`docker/.gitignore` is a whitelist (`* / !*/ / !README.md / ...`), so
`scripts/wiki-export/**` (generated content + `.sync-state.json`) and the new
script are ignored by default — matching how `outline-export/`,
`wikijs-export/`, and the existing sync scripts are already handled. No
`.gitignore` changes needed.

## Data flow

```
                    ┌──────────────────────┐
   nightly cron ───▶│  sync-wiki-markdown  │───▶ scripts/wiki-export/<Book>/*.md
                     │        pull          │     (+ .sync-state.json)
                     └──────────────────────┘              │
                                                              │ grep/glob/read
   BookStack API  ◀──┌──────────────────────┐               ▼
   (localhost:6875,  │  sync-wiki-markdown  │◀── you edit / add .md files
   token auth)        │        push          │       (manual)
                      └──────────────────────┘
```

## Testing / verification

- **Pull, clean state:** run `pull` twice in a row with no BookStack changes
  in between — second run should be a no-op (no file rewrites, no state
  changes).
- **Pull, remote change:** edit a page in the BookStack UI, run `pull`,
  confirm the local file updates and the frontmatter `updated_at` moves.
- **Push, new page:** create a new `.md` file (no frontmatter) in an existing
  book's folder, run `push`, confirm the page appears in BookStack and the
  local file gets `page_id`/`url` frontmatter written back.
- **Push, edit:** edit an existing local file's body, run `push`, confirm the
  BookStack page content updates.
- **Conflict, pull side:** edit a page in BookStack UI *and* edit the same
  local file's body before running `pull` — confirm the script skips that
  file and prints a conflict warning instead of overwriting either side.
- **Conflict, push side:** after a local edit, change the same page in the
  BookStack UI, then run `push` — confirm it refuses with a warning instead
  of overwriting the newer BookStack edit.
- **Failure path:** temporarily break the API token, confirm `pull` exits
  non-zero and the cron wrapper's ntfy failure alert fires.

## Future extensions (not now)

- If search quality on plain grep proves insufficient, revisit with the
  graphify or RAG/MCP options considered and deferred above.
- Chapter-aware layout if flattening chapters into the book folder becomes a
  real problem.
- Explicit, opt-in deletion propagation (either direction) if orphan
  accumulation becomes annoying.

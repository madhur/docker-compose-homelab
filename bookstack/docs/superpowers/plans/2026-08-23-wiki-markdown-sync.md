# BookStack ↔ Markdown Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a `pull`/`push` script that mirrors BookStack wiki content to Markdown files under `scripts/wiki-export/` for agentic (grep/glob/read) search, and pushes local edits back into BookStack without ever silently clobbering a concurrent edit on either side.

**Architecture:** A single bash script, `scripts/sync-wiki-markdown.sh`, sourcing pure helper functions from `scripts/lib/wiki-sync-lib.sh` (slug/frontmatter/hash/state — all unit-testable without touching the API). The script talks to the BookStack API using the existing `bookstack-digest.env` token. A JSON state file (`scripts/wiki-export/.sync-state.json`) tracks the last-synced body hash and remote `updated_at` per page, which is what makes conflict detection possible in both directions. `pull` is non-destructive and stays on the nightly cron; `push` is manual-only, plus both get one-click OliveTin buttons.

**Tech Stack:** bash, curl, jq, sha256sum — no new dependencies, matches the existing `export-to-outline.sh`/`export-to-wikijs.sh` scripts in this repo.

## Global Constraints

- Reuse `scripts/bookstack-digest.env` for the API token (`BS_TOKEN_ID`/`BS_TOKEN_SECRET`) — do not create a new secret.
- `BASE` defaults to `http://localhost:6875` (matches existing scripts), overridable via `BS_BASE_URL` in the env file.
- Frontmatter fields are exactly: `title`, `book`, `url`, `page_id`, `updated_at` — content hashing always excludes the frontmatter block.
- `pull` must never overwrite a locally-edited, unpushed file — conflict or skip, never clobber.
- `push` must never overwrite a page that changed remotely since the last sync — conflict, never clobber.
- No book auto-creation from a new folder; no deletion propagation either direction (per approved spec).
- `scripts/wiki-export/**` and the new script are covered by the repo's existing whitelist `.gitignore` — no `.gitignore` edits needed.
- `push` is never added to any cron/scheduled job — manual (or OliveTin button click) only.
- New scripts get `chmod 755`, matching the existing `scripts/*.sh` permissions.
- OliveTin runs in a container with no host filesystem access — its actions must SSH to the host via the existing `ssh -F /config/ssh/easy.cfg madhur@local.madhur.co.in '...'` + `notify_wrapper.sh`/`run_with_notification` pattern, matching every other OliveTin action in `config.yaml`.

---

### Task 1: Pure helpers — slug, frontmatter, content hash

**Files:**
- Create: `scripts/lib/wiki-sync-lib.sh`
- Create: `scripts/lib/wiki-sync-lib.test.sh`

**Interfaces:**
- Produces: `slug(str) -> stdout`, `strip_frontmatter(file) -> stdout`, `body_hash(file) -> stdout`, `frontmatter_field(file, field) -> stdout`, `build_frontmatter(title, book, url, page_id, updated_at) -> stdout`. All later tasks (`cmd_pull`, `cmd_push`) call these by name.

- [ ] **Step 1: Write the failing test file**

Create `scripts/lib/wiki-sync-lib.test.sh`:

```bash
#!/usr/bin/env bash
# Unit tests for wiki-sync-lib.sh — pure functions only, no BookStack API calls.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/wiki-sync-lib.sh"

PASS=0
FAIL=0

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    PASS=$((PASS+1))
  else
    FAIL=$((FAIL+1))
    echo "FAIL: $desc"
    echo "  expected: $expected"
    echo "  actual:   $actual"
  fi
}

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

# --- slug() ---
assert_eq "slug: strips slashes" "Foo Bar" "$(slug 'Foo/Bar')"
assert_eq "slug: collapses spaces" "a b" "$(slug 'a    b')"
assert_eq "slug: strips special chars" "a b" "$(slug 'a<b>?')"

# --- strip_frontmatter() / body_hash() / frontmatter_field() ---
cat > "$TMPDIR/with-fm.md" <<'EOF'
---
title: Test Page
book: Test Book
url: https://example.com/books/test/page/test
page_id: 42
updated_at: 2026-08-23T00:00:00.000000Z
---

# Hello

Body content.
EOF

cat > "$TMPDIR/no-fm.md" <<'EOF'
# Hello

Body content.
EOF

assert_eq "strip_frontmatter: removes header" "$(printf '# Hello\n\nBody content.')" "$(strip_frontmatter "$TMPDIR/with-fm.md")"
assert_eq "strip_frontmatter: no-op without header" "$(printf '# Hello\n\nBody content.')" "$(strip_frontmatter "$TMPDIR/no-fm.md")"
assert_eq "body_hash: same body same hash regardless of frontmatter" "$(body_hash "$TMPDIR/with-fm.md")" "$(body_hash "$TMPDIR/no-fm.md")"
assert_eq "frontmatter_field: title" "Test Page" "$(frontmatter_field "$TMPDIR/with-fm.md" title)"
assert_eq "frontmatter_field: page_id" "42" "$(frontmatter_field "$TMPDIR/with-fm.md" page_id)"
assert_eq "frontmatter_field: url keeps colons" "https://example.com/books/test/page/test" "$(frontmatter_field "$TMPDIR/with-fm.md" url)"
assert_eq "frontmatter_field: missing field on no-fm file" "" "$(frontmatter_field "$TMPDIR/no-fm.md" page_id)"

# --- build_frontmatter() ---
build_frontmatter "Test Page" "Test Book" "https://example.com/books/test/page/test" "42" "2026-08-23T00:00:00.000000Z" > "$TMPDIR/built.md"
assert_eq "build_frontmatter: round-trips page_id" "42" "$(frontmatter_field "$TMPDIR/built.md" page_id)"
assert_eq "build_frontmatter: round-trips url" "https://example.com/books/test/page/test" "$(frontmatter_field "$TMPDIR/built.md" url)"

echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
```

- [ ] **Step 2: Run it, confirm it fails**

Run: `chmod +x scripts/lib/wiki-sync-lib.test.sh && ./scripts/lib/wiki-sync-lib.test.sh`
Expected: FAIL immediately — `source: wiki-sync-lib.sh: No such file or directory` (script exits non-zero because `set -euo pipefail` is set and the file doesn't exist yet).

- [ ] **Step 3: Implement the library**

Create `scripts/lib/wiki-sync-lib.sh`:

```bash
#!/usr/bin/env bash
# Pure helpers for BookStack <-> Markdown sync. No API calls in this file —
# everything here operates on strings/files only, so it's unit-testable
# without a running BookStack instance. See wiki-sync-lib.test.sh.

# slug STR -> stdout
# Filesystem-safe name: strip slashes/control chars, collapse spaces, trim.
slug() {
  echo "$1" | tr '/\\\n\r\t' '     ' | sed -E 's/[<>:"|?*]+/ /g; s/  +/ /g; s/^ +| +$//g' | cut -c1-120
}

# strip_frontmatter FILE -> stdout
# Prints FILE with a leading "---\n...\n---\n" YAML block removed, if present.
# A file with no frontmatter is printed unchanged.
strip_frontmatter() {
  local file="$1"
  awk '
    NR==1 && $0=="---" { infm=1; next }
    infm && $0=="---" { infm=0; skipnext=1; next }
    infm { next }
    skipnext && $0=="" { skipnext=0; next }
    { print }
  ' "$file"
}

# body_hash FILE -> stdout
# sha256 of the file's content with frontmatter stripped, so editing
# frontmatter never looks like a body edit.
body_hash() {
  local file="$1"
  strip_frontmatter "$file" | sha256sum | awk '{print $1}'
}

# frontmatter_field FILE FIELD -> stdout
# Value of a flat "field: value" key inside the leading frontmatter block.
# Empty string if there's no frontmatter or the field isn't present.
frontmatter_field() {
  local file="$1" field="$2"
  awk -v f="$field" '
    NR==1 && $0=="---" { infm=1; next }
    infm && $0=="---" { exit }
    infm {
      if ($0 ~ "^"f":") {
        sub("^"f":[ ]*", "", $0)
        print $0
        exit
      }
    }
  ' "$file"
}

# build_frontmatter TITLE BOOK URL PAGE_ID UPDATED_AT -> stdout
build_frontmatter() {
  local title="$1" book="$2" url="$3" page_id="$4" updated_at="$5"
  cat <<EOF
---
title: $title
book: $book
url: $url
page_id: $page_id
updated_at: $updated_at
---

EOF
}
```

- [ ] **Step 4: Run the test again, confirm it passes**

Run: `./scripts/lib/wiki-sync-lib.test.sh`
Expected: `10 passed, 0 failed` (exit code 0)

- [ ] **Step 5: Commit**

```bash
cd /home/madhur/docker && chmod 755 bookstack/scripts/lib/wiki-sync-lib.sh bookstack/scripts/lib/wiki-sync-lib.test.sh
git add -f bookstack/scripts/lib/wiki-sync-lib.sh bookstack/scripts/lib/wiki-sync-lib.test.sh
git commit -m "feat(bookstack): add pure helpers for wiki markdown sync

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 2: Sync-state helpers (`.sync-state.json` read/write)

**Files:**
- Modify: `scripts/lib/wiki-sync-lib.sh` (append functions)
- Modify: `scripts/lib/wiki-sync-lib.test.sh` (append assertions)

**Interfaces:**
- Consumes: nothing new (uses `jq`, already a dependency of `export-to-outline.sh`).
- Produces: `state_get_hash(state_file, page_id) -> stdout`, `state_get_updated_at(state_file, page_id) -> stdout`, `state_set(state_file, page_id, body_hash, remote_updated_at)`. `cmd_pull`/`cmd_push` (Tasks 3-4) call these by name.

- [ ] **Step 1: Add the failing assertions**

Append to `scripts/lib/wiki-sync-lib.test.sh`, just before the final `echo`/`echo "$PASS passed..."` lines:

```bash
# --- state_get_hash() / state_get_updated_at() / state_set() ---
STATE="$TMPDIR/state.json"
assert_eq "state_get_hash: empty on missing file" "" "$(state_get_hash "$STATE" 1)"
assert_eq "state_get_updated_at: empty on missing file" "" "$(state_get_updated_at "$STATE" 1)"
state_set "$STATE" "1" "abc123" "2026-08-23T00:00:00.000000Z"
assert_eq "state_set/get_hash round-trip" "abc123" "$(state_get_hash "$STATE" 1)"
assert_eq "state_set/get_updated_at round-trip" "2026-08-23T00:00:00.000000Z" "$(state_get_updated_at "$STATE" 1)"
state_set "$STATE" "2" "def456" "2026-08-23T01:00:00.000000Z"
assert_eq "state_set: preserves other entries" "abc123" "$(state_get_hash "$STATE" 1)"
assert_eq "state_get_hash: empty for unknown page_id" "" "$(state_get_hash "$STATE" 999)"
```

- [ ] **Step 2: Run it, confirm it fails**

Run: `./scripts/lib/wiki-sync-lib.test.sh`
Expected: FAIL — `state_get_hash: command not found`

- [ ] **Step 3: Implement the state helpers**

Append to `scripts/lib/wiki-sync-lib.sh`:

```bash
# state_get_hash STATE_FILE PAGE_ID -> stdout
state_get_hash() {
  local state_file="$1" page_id="$2"
  [ -f "$state_file" ] || { echo ""; return; }
  jq -r --arg id "$page_id" '.[$id].body_hash // ""' "$state_file"
}

# state_get_updated_at STATE_FILE PAGE_ID -> stdout
state_get_updated_at() {
  local state_file="$1" page_id="$2"
  [ -f "$state_file" ] || { echo ""; return; }
  jq -r --arg id "$page_id" '.[$id].remote_updated_at // ""' "$state_file"
}

# state_set STATE_FILE PAGE_ID BODY_HASH REMOTE_UPDATED_AT
state_set() {
  local state_file="$1" page_id="$2" body_hash="$3" remote_updated_at="$4"
  [ -f "$state_file" ] || echo '{}' > "$state_file"
  local tmp
  tmp="$(mktemp)"
  jq --arg id "$page_id" --arg h "$body_hash" --arg u "$remote_updated_at" \
    '.[$id] = {body_hash: $h, remote_updated_at: $u}' "$state_file" > "$tmp"
  mv "$tmp" "$state_file"
}
```

- [ ] **Step 4: Run the tests again, confirm they pass**

Run: `./scripts/lib/wiki-sync-lib.test.sh`
Expected: `15 passed, 0 failed`

- [ ] **Step 5: Commit**

```bash
cd /home/madhur/docker
git add bookstack/scripts/lib/wiki-sync-lib.sh bookstack/scripts/lib/wiki-sync-lib.test.sh
git commit -m "feat(bookstack): add sync-state read/write helpers

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 3: `pull` subcommand

**Files:**
- Create: `scripts/sync-wiki-markdown.sh`

**Interfaces:**
- Consumes: `slug`, `strip_frontmatter`, `body_hash`, `frontmatter_field`, `build_frontmatter` (Task 1); `state_get_hash`, `state_get_updated_at`, `state_set` (Task 2).
- Produces: `api(method, path, [json_body]) -> stdout` (used by Task 4's `cmd_push` too), `cmd_pull()`. Output tree: `scripts/wiki-export/<Book Name>/<Page Title>-<id>.md`, `scripts/wiki-export/.sync-state.json`.

- [ ] **Step 1: Write the script skeleton, the `api()` helper, and `cmd_pull()`**

Create `scripts/sync-wiki-markdown.sh`:

```bash
#!/usr/bin/env bash
# Two-way sync between BookStack and a local Markdown mirror.
#   pull  — BookStack -> scripts/wiki-export/  (safe, non-destructive, cron-able)
#   push  — scripts/wiki-export/ -> BookStack  (manual only, never scheduled)
# See docs/superpowers/specs/2026-08-23-wiki-markdown-sync-design.md for the
# full conflict-detection design.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/wiki-sync-lib.sh"
set -a; . "$SCRIPT_DIR/bookstack-digest.env"; set +a

BASE="${BS_BASE_URL:-http://localhost:6875}"
AUTH="Authorization: Token ${BS_TOKEN_ID}:${BS_TOKEN_SECRET}"
OUT="$SCRIPT_DIR/wiki-export"
STATE="$OUT/.sync-state.json"

# api METHOD PATH [JSON_BODY] -> stdout
# GET/POST/PUT with retry-on-429 (BookStack throttles ~180 req/min) + light pacing.
api() {
  local method="$1" path="$2" body="${3:-}"
  local out code
  while :; do
    if [ -n "$body" ]; then
      out="$(curl -sS -w $'\n%{http_code}' -X "$method" -H "$AUTH" -H "Content-Type: application/json" -d "$body" "$BASE$path")"
    else
      out="$(curl -sS -w $'\n%{http_code}' -X "$method" -H "$AUTH" "$BASE$path")"
    fi
    code="${out##*$'\n'}"; out="${out%$'\n'*}"
    if [ "$code" = "429" ]; then sleep 8; continue; fi
    if [ "${code:0:1}" != "2" ]; then
      echo "API error ($method $path): HTTP $code: $out" >&2
      return 1
    fi
    printf '%s' "$out"
    break
  done
  sleep 0.3
}

cmd_pull() {
  mkdir -p "$OUT"
  [ -f "$STATE" ] || echo '{}' > "$STATE"

  echo "==> Fetching book list"
  declare -A BOOK_NAME BOOK_SLUG
  while IFS=$'\t' read -r id name bslug; do
    BOOK_NAME["$id"]="$name"
    BOOK_SLUG["$id"]="$bslug"
  done < <(api GET "/api/books?count=500" | jq -r '.data[] | [.id, .name, .slug] | @tsv')
  echo "    ${#BOOK_NAME[@]} books"

  echo "==> Enumerating pages"
  PAGES_JSON="$(mktemp)"
  offset=0
  : > "$PAGES_JSON"
  while :; do
    chunk="$(api GET "/api/pages?count=500&offset=$offset&sort=priority")"
    n="$(echo "$chunk" | jq '.data | length')"
    [ "$n" -eq 0 ] && break
    echo "$chunk" | jq -c '.data[] | {id, name, slug, book_id, updated_at}' >> "$PAGES_JSON"
    offset=$((offset + n))
  done
  total="$(wc -l < "$PAGES_JSON" | tr -d ' ')"
  echo "    $total pages"

  echo "==> Syncing pages to Markdown"
  local created=0 updated=0 skipped=0 conflicts=0 i=0
  while IFS= read -r p; do
    i=$((i+1))
    pid="$(echo "$p" | jq -r '.id')"
    pname="$(echo "$p" | jq -r '.name')"
    pslug="$(echo "$p" | jq -r '.slug')"
    bid="$(echo "$p" | jq -r '.book_id')"
    remote_updated="$(echo "$p" | jq -r '.updated_at')"
    bname="${BOOK_NAME[$bid]:-_orphan-book-$bid}"
    bslug="${BOOK_SLUG[$bid]:-}"

    dir="$OUT/$(slug "$bname")"; mkdir -p "$dir"
    file="$dir/$(slug "$pname")-$pid.md"
    url="$BASE/books/$bslug/page/$pslug"
    printf '\r    [%d/%d] %-50.50s' "$i" "$total" "$pname"

    local_hash=""
    [ -f "$file" ] && local_hash="$(body_hash "$file")"
    synced_hash="$(state_get_hash "$STATE" "$pid")"
    synced_updated="$(state_get_updated_at "$STATE" "$pid")"

    if [ ! -f "$file" ]; then
      content="$(api GET "/api/pages/$pid/export/markdown")"
      { build_frontmatter "$pname" "$bname" "$url" "$pid" "$remote_updated"; printf '%s' "$content"; } > "$file"
      state_set "$STATE" "$pid" "$(body_hash "$file")" "$remote_updated"
      created=$((created+1))
    elif [ "$local_hash" = "$synced_hash" ]; then
      if [ "$remote_updated" != "$synced_updated" ]; then
        content="$(api GET "/api/pages/$pid/export/markdown")"
        { build_frontmatter "$pname" "$bname" "$url" "$pid" "$remote_updated"; printf '%s' "$content"; } > "$file"
        state_set "$STATE" "$pid" "$(body_hash "$file")" "$remote_updated"
        updated=$((updated+1))
      else
        skipped=$((skipped+1))
      fi
    else
      if [ "$remote_updated" != "$synced_updated" ]; then
        echo
        echo "CONFLICT: $file (edited locally AND in BookStack since last sync — run 'push' or resolve manually before the next pull)" >&2
        conflicts=$((conflicts+1))
      else
        skipped=$((skipped+1))
      fi
    fi
  done < "$PAGES_JSON"
  rm -f "$PAGES_JSON"

  echo
  echo "Pull done: $created created, $updated updated, $skipped unchanged, $conflicts conflicts"
  [ "$conflicts" -eq 0 ]
}

case "${1:-}" in
  pull) cmd_pull ;;
  *) echo "Usage: $0 {pull|push}" >&2; exit 1 ;;
esac
```

- [ ] **Step 2: Make it executable**

Run: `chmod 755 scripts/sync-wiki-markdown.sh`

- [ ] **Step 3: First live run — populate `wiki-export/` from the real BookStack instance**

Run: `./scripts/sync-wiki-markdown.sh pull`
Expected: prints book count, page count, then a `Pull done: N created, 0 updated, 0 unchanged, 0 conflicts` line. Confirm the created count matches BookStack's total page count:

Run: `find scripts/wiki-export -name '*.md' | wc -l` and separately `curl -sS -H "Authorization: Token $(grep BS_TOKEN_ID scripts/bookstack-digest.env | cut -d= -f2):$(grep BS_TOKEN_SECRET scripts/bookstack-digest.env | cut -d= -f2)" 'http://localhost:6875/api/pages?count=500' | jq '.total'`
Expected: the two counts match (adjust `count=500` upward if BookStack reports more total pages than that).

- [ ] **Step 4: Second run — confirm it's a no-op**

Run: `./scripts/sync-wiki-markdown.sh pull`
Expected: `Pull done: 0 created, 0 updated, N unchanged, 0 conflicts` (no files rewritten — spot-check with `find scripts/wiki-export -name '*.md' -newer scripts/wiki-export/.sync-state.json` returning nothing, since `.sync-state.json` itself is untouched when nothing changes... actually since `.sync-state.json` isn't rewritten on a no-op run either, confirm instead via: `md5sum scripts/wiki-export/.sync-state.json` before and after this run — expect identical).

- [ ] **Step 5: Spot-check a file's frontmatter and content**

Run: `head -8 "$(find scripts/wiki-export -name '*.md' | head -1)"`
Expected: a `---`-delimited frontmatter block with `title`, `book`, `url`, `page_id`, `updated_at`, followed by a blank line and the page's Markdown body. Open the printed `url` in a browser and confirm it loads the matching BookStack page.

- [ ] **Step 6: Commit**

```bash
cd /home/madhur/docker
git add -f bookstack/scripts/sync-wiki-markdown.sh
git commit -m "feat(bookstack): add pull subcommand for wiki markdown sync

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

(`scripts/wiki-export/` itself stays untracked — it's generated content, covered by the repo's whitelist `.gitignore`.)

---

### Task 4: `push` subcommand (create + update + conflict detection)

**Files:**
- Modify: `scripts/sync-wiki-markdown.sh`

**Interfaces:**
- Consumes: `api()`, all of Task 1/2's lib functions, plus `$BASE`, `$AUTH`, `$OUT`, `$STATE` from Task 3's script header.
- Produces: `cmd_push()`, wired into the `case` dispatch.

- [ ] **Step 1: Add `cmd_push()`**

Insert the following function directly above the `case "${1:-}" in` dispatch line in `scripts/sync-wiki-markdown.sh`:

```bash
cmd_push() {
  [ -d "$OUT" ] || { echo "No $OUT — run 'pull' first." >&2; return 1; }
  [ -f "$STATE" ] || echo '{}' > "$STATE"

  echo "==> Fetching book list"
  declare -A BOOK_ID_BY_FOLDER BOOK_NAME_BY_FOLDER BOOK_APISLUG_BY_FOLDER
  while IFS=$'\t' read -r id name bslug; do
    key="$(slug "$name")"
    BOOK_ID_BY_FOLDER["$key"]="$id"
    BOOK_NAME_BY_FOLDER["$key"]="$name"
    BOOK_APISLUG_BY_FOLDER["$key"]="$bslug"
  done < <(api GET "/api/books?count=500" | jq -r '.data[] | [.id, .name, .slug] | @tsv')

  echo "==> Pushing local changes"
  local created=0 updated=0 skipped=0 conflicts=0 unmapped=0
  while IFS= read -r -d '' file; do
    folder="$(basename "$(dirname "$file")")"
    page_id="$(frontmatter_field "$file" page_id)"
    title="$(frontmatter_field "$file" title)"
    if [ -z "$title" ]; then
      title="$(strip_frontmatter "$file" | grep -m1 '^# ' | sed 's/^# //')"
    fi
    [ -n "$title" ] || title="$(basename "$file" .md)"
    body="$(strip_frontmatter "$file")"
    local_hash="$(body_hash "$file")"

    if [ -z "$page_id" ]; then
      book_id="${BOOK_ID_BY_FOLDER[$folder]:-}"
      if [ -z "$book_id" ]; then
        echo "SKIP (no matching BookStack book for folder '$folder'): $file" >&2
        unmapped=$((unmapped+1))
        continue
      fi
      book_name="${BOOK_NAME_BY_FOLDER[$folder]}"
      book_apislug="${BOOK_APISLUG_BY_FOLDER[$folder]}"
      payload="$(jq -n --arg name "$title" --argjson book_id "$book_id" --arg md "$body" '{name:$name, book_id:$book_id, markdown:$md}')"
      resp="$(api POST "/api/pages" "$payload")"
      new_id="$(echo "$resp" | jq -r '.id')"
      new_slug="$(echo "$resp" | jq -r '.slug')"
      new_updated="$(echo "$resp" | jq -r '.updated_at')"
      url="$BASE/books/$book_apislug/page/$new_slug"
      { build_frontmatter "$title" "$book_name" "$url" "$new_id" "$new_updated"; printf '%s' "$body"; } > "$file"
      state_set "$STATE" "$new_id" "$(body_hash "$file")" "$new_updated"
      echo "CREATED: $file -> page $new_id ($url)"
      created=$((created+1))
      continue
    fi

    synced_hash="$(state_get_hash "$STATE" "$page_id")"
    synced_updated="$(state_get_updated_at "$STATE" "$page_id")"

    if [ "$local_hash" = "$synced_hash" ]; then
      skipped=$((skipped+1))
      continue
    fi

    remote="$(api GET "/api/pages/$page_id")"
    remote_updated="$(echo "$remote" | jq -r '.updated_at')"

    if [ "$remote_updated" != "$synced_updated" ]; then
      echo "CONFLICT: $file changed locally, but BookStack page $page_id changed remotely too — run 'pull' first." >&2
      conflicts=$((conflicts+1))
      continue
    fi

    payload="$(jq -n --arg name "$title" --arg md "$body" '{name:$name, markdown:$md}')"
    resp="$(api PUT "/api/pages/$page_id" "$payload")"
    new_updated="$(echo "$resp" | jq -r '.updated_at')"
    book_name="$(frontmatter_field "$file" book)"
    url="$(frontmatter_field "$file" url)"
    { build_frontmatter "$title" "$book_name" "$url" "$page_id" "$new_updated"; printf '%s' "$body"; } > "$file"
    state_set "$STATE" "$page_id" "$(body_hash "$file")" "$new_updated"
    echo "UPDATED: $file"
    updated=$((updated+1))
  done < <(find "$OUT" -mindepth 2 -maxdepth 2 -name '*.md' -print0)

  echo
  echo "Push done: $created created, $updated updated, $skipped unchanged, $conflicts conflicts, $unmapped unmapped"
  [ "$conflicts" -eq 0 ] && [ "$unmapped" -eq 0 ]
}
```

- [ ] **Step 2: Wire it into the dispatch**

Change the `case` statement at the bottom of `scripts/sync-wiki-markdown.sh`:

```bash
case "${1:-}" in
  pull) cmd_pull ;;
  *) echo "Usage: $0 {pull|push}" >&2; exit 1 ;;
esac
```

to:

```bash
case "${1:-}" in
  pull) cmd_pull ;;
  push) cmd_push ;;
  *) echo "Usage: $0 {pull|push}" >&2; exit 1 ;;
esac
```

- [ ] **Step 3: Live test — create a new page via push**

Pick any existing book folder under `scripts/wiki-export/` (run `ls scripts/wiki-export/` and pick one, referred to below as `<Book Folder>`), then:

```bash
cat > "scripts/wiki-export/<Book Folder>/wiki-sync-test-page.md" <<'EOF'
This is a disposable test page created by sync-wiki-markdown.sh push,
verifying Task 4 of the wiki-markdown-sync plan. Safe to delete from the
BookStack UI once verification is done (see Task 6).
EOF
./scripts/sync-wiki-markdown.sh push
```

Expected: `CREATED: .../wiki-sync-test-page.md -> page <id> (<url>)`, then `Push done: 1 created, 0 updated, ...`. Open the printed URL in a browser and confirm the page exists in BookStack with that content. Confirm the local file now has frontmatter (`head -8 "scripts/wiki-export/<Book Folder>/wiki-sync-test-page.md"`).

- [ ] **Step 4: Live test — update that page via push**

```bash
echo 'An appended line, verifying the update path.' >> "scripts/wiki-export/<Book Folder>/wiki-sync-test-page.md"
./scripts/sync-wiki-markdown.sh push
```

Expected: `UPDATED: .../wiki-sync-test-page.md`, then `Push done: 0 created, 1 updated, ...`. Reload the page's URL in BookStack and confirm the appended line shows up.

- [ ] **Step 5: Confirm no-op on unchanged push**

Run: `./scripts/sync-wiki-markdown.sh push`
Expected: `Push done: 0 created, 0 updated, N unchanged, 0 conflicts, 0 unmapped`.

- [ ] **Step 6: Commit**

```bash
cd /home/madhur/docker
git add bookstack/scripts/sync-wiki-markdown.sh
git commit -m "feat(bookstack): add push subcommand (create + update + conflict detection)

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

Leave the disposable test page (`wiki-sync-test-page.md` / its BookStack page) in place — Task 6 reuses it for the conflict-detection tests, then covers cleanup.

---

### Task 5: Cron wiring + documentation

**Files:**
- Modify: `/home/madhur/scripts/every_24_hours.sh`
- Modify: `scripts/README.md`

**Interfaces:**
- Consumes: `scripts/sync-wiki-markdown.sh pull` (Task 3), the `run_with_notification` wrapper already sourced by `every_24_hours.sh`.

- [ ] **Step 1: Add the nightly pull to the cron script**

In `/home/madhur/scripts/every_24_hours.sh`, find this existing line:

```
    run_with_notification "/home/madhur/scripts/bookstack_digest.py" "BookStack Daily Digest → Mailpit" "monitoring"
```

and add a new line directly after it:

```
    run_with_notification "/home/madhur/docker/bookstack/scripts/sync-wiki-markdown.sh pull" "BookStack Wiki Markdown Sync" "monitoring"
```

- [ ] **Step 2: Verify the addition doesn't break the cron script's syntax**

Run: `bash -n /home/madhur/scripts/every_24_hours.sh`
Expected: no output, exit code 0.

- [ ] **Step 3: Document the new script in `scripts/README.md`**

Append this section to `scripts/README.md` (after the existing `bookstack-digest.sh` section):

```markdown

## sync-wiki-markdown.sh — two-way BookStack ↔ Markdown sync

Mirrors BookStack pages to `wiki-export/<Book>/<Page>-<id>.md` for agentic
(grep/glob/read) search, and can push local Markdown edits back into
BookStack. See `docs/superpowers/specs/2026-08-23-wiki-markdown-sync-design.md`
for the full design.

- **`pull`** — BookStack → local. Non-destructive: never overwrites a
  locally-edited file that hasn't been pushed yet. Conflicting edits (both
  sides changed since the last sync) are skipped and printed as warnings,
  not overwritten. Safe to run unattended — scheduled nightly in
  `~/scripts/every_24_hours.sh`.
- **`push`** — local → BookStack. Manual only, never scheduled. Creates a
  new BookStack page for any `.md` file with no `page_id` frontmatter
  (only inside a folder that already matches an existing book — it will
  never create a new book). Updates existing pages when the local body
  hash has changed. Refuses (with a warning) if BookStack changed the same
  page since the last sync — run `pull` first to resolve.
- **State:** `wiki-export/.sync-state.json` tracks the last-synced content
  hash and BookStack `updated_at` per page — this is what conflict
  detection is based on. Gitignored, not wiki content.
- **Also available as OliveTin buttons** (`BookStack` dashboard →
  `Wiki Markdown Sync`) for one-click pull/push without SSHing in.

### Manual run
```sh
./sync-wiki-markdown.sh pull   # refresh the local mirror
./sync-wiki-markdown.sh push   # push local edits/new pages back to BookStack
```
```

- [ ] **Step 4: Commit**

```bash
cd /home/madhur/docker
git add bookstack/scripts/README.md
git commit -m "docs(bookstack): document sync-wiki-markdown.sh, wire nightly pull into cron

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

(`/home/madhur/scripts/every_24_hours.sh` lives outside this repo's git tree — no commit for that file, the edit itself is the deliverable.)

---

### Task 6: Conflict-detection live tests + cleanup

**Files:** none (verification only, reuses the disposable test page from Task 4)

- [ ] **Step 1: Simulate a pull-side conflict**

Edit the local test file (creating an unpushed local change):

```bash
echo 'A local-only edit, not yet pushed.' >> "scripts/wiki-export/<Book Folder>/wiki-sync-test-page.md"
```

Then, in the BookStack web UI, open the test page and add a line directly there (simulating a concurrent remote edit), and save.

Run: `./scripts/sync-wiki-markdown.sh pull`
Expected: prints `CONFLICT: .../wiki-sync-test-page.md (edited locally AND in BookStack since last sync — run 'push' or resolve manually before the next pull)`, ends with `... 1 conflicts`, and exits non-zero (`echo $?` after the run shows `1`). Confirm the local file still contains your local-only edit (not overwritten) and the BookStack page still shows the UI edit (not overwritten either) — open the page URL to check.

- [ ] **Step 2: Simulate a push-side conflict**

With the local file still holding the unpushed edit from Step 1 (and the remote page holding its own UI edit from Step 1), run:

Run: `./scripts/sync-wiki-markdown.sh push`
Expected: prints `CONFLICT: .../wiki-sync-test-page.md changed locally, but BookStack page <id> changed remotely too — run 'pull' first.`, ends with `... 1 conflicts, 0 unmapped`, exits non-zero. Confirm neither side was overwritten (BookStack page still shows only the UI edit; local file still shows the earlier local-only edit plus the original appended line from Task 4).

- [ ] **Step 3: Resolve the conflict and confirm a clean sync**

Manually reconcile: overwrite the local file's body with a merge of both edits (or just decide the BookStack UI edit wins and discard the local one), then run:

Run: `./scripts/sync-wiki-markdown.sh pull` (if BookStack's version should win) or `./scripts/sync-wiki-markdown.sh push` (if the local version should win)
Expected: `0 conflicts`, exit code 0.

- [ ] **Step 4: Run the full spec testing checklist as a final regression pass**

Re-run the checks from `docs/superpowers/specs/2026-08-23-wiki-markdown-sync-design.md`'s "Testing / verification" section end to end (pull clean-state no-op, pull remote-change, push new page, push edit, both conflict cases, API-failure path) and confirm each behaves as documented. For the failure path specifically:

```bash
BS_TOKEN_ID_REAL="$(grep BS_TOKEN_ID scripts/bookstack-digest.env)"
sed -i 's/^BS_TOKEN_ID=.*/BS_TOKEN_ID=invalid-token-for-testing/' scripts/bookstack-digest.env
./scripts/sync-wiki-markdown.sh pull; echo "exit code: $?"
git checkout -- scripts/bookstack-digest.env 2>/dev/null || sed -i "s/^BS_TOKEN_ID=.*/$BS_TOKEN_ID_REAL/" scripts/bookstack-digest.env
```

Expected: `API error (GET /api/books?count=500): HTTP 401: ...` on stderr, non-zero exit code; confirm the env file's real token is restored afterward (the script above restores it, but double-check with `cat scripts/bookstack-digest.env` since this file isn't in git and can't just be `git checkout`'d back — the `sed` fallback in the snippet handles that case).

- [ ] **Step 5: Clean up the disposable test page**

In the BookStack web UI, delete the "wiki-sync-test-page" page created in Task 4 (deletion is intentionally a manual, UI-only action per this feature's design — the script never deletes). Then remove its local mirror and state entry:

```bash
rm "scripts/wiki-export/<Book Folder>/wiki-sync-test-page.md"
./scripts/sync-wiki-markdown.sh pull
```

Expected: the pull run completes with `0 conflicts` (the deleted page is simply absent from the API response now, and its orphaned state entry is harmless — it's keyed by a `page_id` that will never come up again).

---

### Task 7: OliveTin one-click pull/push buttons

**Files:**
- Modify: `/home/madhur/docker/olivetin/OliveTin-config/config.yaml`

**Interfaces:**
- Consumes: `/home/madhur/docker/bookstack/scripts/sync-wiki-markdown.sh {pull|push}` (Tasks 3-4), the `notify_wrapper.sh`/`run_with_notification` pattern already used by every other OliveTin digest action in this file (e.g. "AWS Cost Digest" at the existing line containing `aws_cost_digest.py`), and the existing SSH-based execution pattern (`ssh -F /config/ssh/easy.cfg madhur@local.madhur.co.in '...'`) since OliveTin runs in a container without direct host filesystem access.

- [ ] **Step 1: Add the two actions**

In `/home/madhur/docker/olivetin/OliveTin-config/config.yaml`, find the last action before the `dashboards:` top-level key — it's the `"Enable Mac Block"` action, whose block ends with:

```yaml
  - title: "Enable Mac Block"
    icon: "&#128274;"
    shell: ssh -F /config/ssh/easy.cfg madhur@local.madhur.co.in 'source /home/madhur/scripts/notify_wrapper.sh && run_with_notification "sudo /home/madhur/gitpersonal/linux-router/scripts/enable-block.sh" "Enable Mac Block" "olivetin"'
    timeout: 30
```

Insert this new block directly after it (still inside `actions:`, before the blank line that precedes `dashboards:`):

```yaml

  # ===== BookStack wiki markdown sync =====
  - title: "Pull BookStack Wiki (BookStack → Markdown)"
    icon: "&#128214;"
    shell: ssh -F /config/ssh/easy.cfg madhur@local.madhur.co.in 'source /home/madhur/scripts/notify_wrapper.sh && run_with_notification "/home/madhur/docker/bookstack/scripts/sync-wiki-markdown.sh pull" "Pull BookStack Wiki" "olivetin"'
    timeout: 300

  - title: "Push BookStack Wiki (Markdown → BookStack)"
    icon: "&#128228;"
    shell: ssh -F /config/ssh/easy.cfg madhur@local.madhur.co.in 'source /home/madhur/scripts/notify_wrapper.sh && run_with_notification "/home/madhur/docker/bookstack/scripts/sync-wiki-markdown.sh push" "Push BookStack Wiki" "olivetin"'
    timeout: 300
```

- [ ] **Step 2: Add a new dashboard section for them**

At the very end of the file, after the last `dashboards:` entry (the `Teams Downloads` section ending with `- title: "Download Teams Video (yt-dlp)"`), append:

```yaml

  # ===== BookStack wiki markdown sync =====
  - title: BookStack
    contents:
      - title: Wiki Markdown Sync
        type: fieldset
        contents:
          - title: "Pull BookStack Wiki (BookStack → Markdown)"
          - title: "Push BookStack Wiki (Markdown → BookStack)"
```

- [ ] **Step 3: Validate YAML syntax**

Run: `python3 -c "import yaml; yaml.safe_load(open('/home/madhur/docker/olivetin/OliveTin-config/config.yaml'))" && echo OK`
Expected: `OK`

- [ ] **Step 4: Restart OliveTin to pick up the config change**

Run: `cd /home/madhur/docker/olivetin && docker compose restart olivetin`
Expected: container restarts cleanly (`docker compose ps olivetin` shows `Up`).

- [ ] **Step 5: Live test both buttons from the OliveTin UI**

Open `https://olivetin.desktop.madhur.co.in`, go to the new **BookStack** dashboard tab, click **Pull BookStack Wiki**, confirm it completes successfully (green) and the run log shows the same `Pull done: ...` summary line as the CLI run. Click **Push BookStack Wiki** and confirm the equivalent for `Push done: ...` (with nothing to push, expect `0 created, 0 updated, N unchanged, 0 conflicts, 0 unmapped`).

- [ ] **Step 6: Commit**

```bash
cd /home/madhur/docker
git add -f olivetin/OliveTin-config/config.yaml
git commit -m "feat(olivetin): add BookStack wiki pull/push buttons

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

(Check first whether `olivetin/OliveTin-config/config.yaml` is already tracked with `git ls-files olivetin/OliveTin-config/config.yaml` — if it is, drop `-f` from the `git add`.)

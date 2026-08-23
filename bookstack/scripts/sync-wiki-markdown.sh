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
      title="$(strip_frontmatter "$file" | grep -m1 '^# ' | sed 's/^# //' || true)"
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
      new_file="$(dirname "$file")/$(slug "$title")-$new_id.md"
      { build_frontmatter "$title" "$book_name" "$url" "$new_id" "$new_updated"; printf '%s' "$body"; } > "$new_file"
      if [ "$new_file" != "$file" ]; then
        rm -f "$file"
      fi
      state_set "$STATE" "$new_id" "$(body_hash "$new_file")" "$new_updated"
      echo "CREATED: $new_file -> page $new_id ($url)"
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

case "${1:-}" in
  pull) cmd_pull ;;
  push) cmd_push ;;
  *) echo "Usage: $0 {pull|push}" >&2; exit 1 ;;
esac

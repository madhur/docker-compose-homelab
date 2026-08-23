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

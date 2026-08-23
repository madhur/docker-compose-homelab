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
    infm && $0=="---" { infm=0; close_line=NR; next }
    infm { next }
    NR==close_line+1 && $0=="" { next }
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
  if ! jq --arg id "$page_id" --arg h "$body_hash" --arg u "$remote_updated_at" \
    '.[$id] = {body_hash: $h, remote_updated_at: $u}' "$state_file" > "$tmp"; then
    echo "state_set: jq failed updating $state_file for page $page_id — leaving state file untouched" >&2
    rm -f "$tmp"
    return 1
  fi
  mv "$tmp" "$state_file"
}

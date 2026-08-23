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

# Regression test: frontmatter closing fence NOT immediately followed by blank line,
# but body has blank lines between paragraphs. The blank lines in the body must NOT be eaten.
cat > "$TMPDIR/no-blank-after-fence.md" <<'EOF'
---
title: Test Page
page_id: 42
---
# Heading

First paragraph.

Second paragraph.
EOF

assert_eq "strip_frontmatter: removes header" "$(printf '# Hello\n\nBody content.')" "$(strip_frontmatter "$TMPDIR/with-fm.md")"
assert_eq "strip_frontmatter: no-op without header" "$(printf '# Hello\n\nBody content.')" "$(strip_frontmatter "$TMPDIR/no-fm.md")"
assert_eq "strip_frontmatter: preserves body blanks when fence has no trailing blank" "$(printf '# Heading\n\nFirst paragraph.\n\nSecond paragraph.')" "$(strip_frontmatter "$TMPDIR/no-blank-after-fence.md")"
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

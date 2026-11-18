#!/usr/bin/env bash
# Tests for tools/hooks/post-edit.sh. Each case: exit 0, no output.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="$ROOT/tools/hooks/post-edit.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fail=0

run_hook() { # $1 = file path; sets OUT and CODE
	OUT="$(printf '{"tool_input":{"file_path":"%s"}}' "$1" | bash "$HOOK" 2>&1)"
	CODE=$?
}
expect_quiet_ok() { # $1 = case name
	if [ "$CODE" -ne 0 ] || [ -n "$OUT" ]; then
		echo "FAIL: $1 (exit $CODE, output: $OUT)"
		fail=1
	else
		echo "ok: $1"
	fi
}

# 1. badly formatted .luau gets formatted
printf '%s\n' '--!strict' 'local   x={1,2,   3}' 'return    x' >"$TMP/bad.luau"
run_hook "$TMP/bad.luau"
expect_quiet_ok "luau hook run is quiet"
if stylua --check "$TMP/bad.luau" >/dev/null 2>&1; then
	echo "ok: luau file formatted"
else
	echo "FAIL: luau file still unformatted"
	fail=1
fi

# 2. .md untouched
printf '%s\n' '#   Title   ' 'text   ' >"$TMP/note.md"
cp "$TMP/note.md" "$TMP/note.md.orig"
run_hook "$TMP/note.md"
expect_quiet_ok "md hook run is quiet"
if cmp -s "$TMP/note.md" "$TMP/note.md.orig"; then
	echo "ok: md untouched"
else
	echo "FAIL: md modified"
	fail=1
fi

# 3. missing path
run_hook "$TMP/does-not-exist.luau"
expect_quiet_ok "missing file"

exit $fail

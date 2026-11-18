#!/usr/bin/env bash
# Quiet check: prints "OK" on success; on failure only `file:line: message` lines (max 30), exit 1.
# Type errors ratchet against tools/type-baseline.txt: a file may not go above its count (files not listed: 0).
# A count that dropped adds one `tools/type-baseline.txt:N: ... lower it` line before OK (not a failure).
# Covers all of src/, the Lune tools (tools/*.luau, tools/lib/) and tests (Lune specs + tests/hook.test.sh).
# Not covered: tests/NN_*.luau (Studio factory tests, run by tools/factory/test.py; StyLua can't parse them)
# and tools/types/ (downloaded Roblox definitions).
set -u
export PATH="$HOME/.rokit/bin:$PATH"
cd "$(dirname "$0")/.."

TYPES_URL="https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau"
TYPES=tools/types/globalTypes.d.luau

# Missing tools fail loudly, in one line, before anything else runs.
missing=""
for tool in stylua selene lune rojo luau-lsp; do
	command -v "$tool" >/dev/null 2>&1 || missing="$missing $tool"
done
if [ -n "$missing" ]; then
	echo "rokit.toml:1: missing tools:$missing (run rokit install)"
	exit 1
fi

BASELINE=tools/type-baseline.txt

out=$(mktemp)
log=$(mktemp)
lsp=$(mktemp)   # luau-lsp findings, normalized to `path:line: message`
notes=$(mktemp) # non-failing hints, printed before OK
trap 'rm -f "$out" "$log" "$lsp" "$notes"' EXIT

# Adds `<where>:1: <name> failed (exit N): <first output line>` when a step exits non-zero
# but produced no `file:line:` line of its own, so a crash or bad flag can't pass silently.
# $1 = step name, $2 = exit code, $3 = line count of $out before the step, $4 = file to blame.
fail_if_silent() {
	if [ "$2" -ne 0 ] && [ "$(wc -l <"$out")" -eq "$3" ]; then
		echo "$4:1: $1 failed (exit $2): $(grep -m1 -v '^[[:space:]]*$' "$log" | cut -c1-160)" >>"$out"
	fi
}
lines() { wc -l <"$out"; }

# --- file sets -------------------------------------------------------------------------------
fmt_files=()  # StyLua: every Luau file we own
lint_files=() # selene: src/ plus the Lune tools and specs
while IFS= read -r f; do fmt_files+=("$f"); done < <(
	find src tools tests -type f -name '*.luau' ! -path 'tools/types/*' ! -name '[0-9][0-9]_*.luau' | sort
)
while IFS= read -r f; do lint_files+=("$f"); done < <(
	{
		find src -type f -name '*.luau'
		ls tests/run.luau tools/*.luau tools/lib/*.luau 2>/dev/null
		find tests -type f -name '*.spec.luau'
	} | sort -u
)
# luau-lsp can't resolve @lune/* requires, so it skips files that use Lune APIs.
typed_files=()
for f in "${lint_files[@]}"; do
	case "$f" in tests/run.luau | tools/*) ;; *) grep -q '@lune/' "$f" || typed_files+=("$f") ;; esac
done

# --- format ----------------------------------------------------------------------------------
n=$(lines)
stylua --check --output-format summary "${fmt_files[@]}" >"$log" 2>&1
rc=$?
grep -E '^[^ !✓✕].*\.luau$' "$log" | sed 's/$/:1: not formatted (run stylua)/' >>"$out"
sed -nE 's/^error: could not format file ([^:]+): (.*)$/\1:1: \2/p' "$log" >>"$out"
fail_if_silent stylua "$rc" "$n" stylua.toml

# --- lint ------------------------------------------------------------------------------------
n=$(lines)
selene --display-style quiet "${lint_files[@]}" >"$log" 2>&1
rc=$?
grep -E '^[^ ]+:[0-9]+:[0-9]+:' "$log" | sed -E 's/^([^:]+):([0-9]+):[0-9]+: /\1:\2: /' >>"$out"
fail_if_silent selene "$rc" "$n" selene.toml

# --- rojo build (a prefab Rojo can't read must fail here, not crash `rojo serve`) -------------
build_ok=1
rbxl="$(dirname "$out")/check.rbxl"
n=$(lines)
rojo build default.project.json -o "$rbxl" >"$log" 2>&1
rc=$?
rm -f "$rbxl"
if [ "$rc" -ne 0 ]; then
	build_ok=0
	bad=$(grep -oE '[A-Za-z0-9_./-]+\.rbxm' "$log" | head -1 | sed "s|^$PWD/||")
	echo "${bad:-default.project.json}:1: rojo build failed${bad:+ (unreadable prefab)}: $(grep -m1 -v '^[[:space:]]*$' "$log" | cut -c1-160)" >>"$out"
fi

# --- types -----------------------------------------------------------------------------------
if [ "$build_ok" -eq 1 ]; then
	n=$(lines)
	rojo sourcemap default.project.json -o sourcemap.json >"$log" 2>&1
	fail_if_silent "rojo sourcemap" "$?" "$n" default.project.json
fi
if [ ! -s "$TYPES" ]; then
	mkdir -p tools/types
	if ! curl -sfL "$TYPES_URL" -o "$TYPES.tmp" >"$log" 2>&1 || [ ! -s "$TYPES.tmp" ]; then
		rm -f "$TYPES.tmp"
		echo "$TYPES:1: could not download Roblox types from $TYPES_URL" >>"$out"
	else
		mv "$TYPES.tmp" "$TYPES"
	fi
fi
if [ "$build_ok" -eq 1 ] && [ -s "$TYPES" ] && [ ${#typed_files[@]} -gt 0 ]; then
	luau-lsp analyze --definitions=@roblox="$TYPES" --sourcemap=sourcemap.json "${typed_files[@]}" >"$log" 2>&1
	rc=$?
	# Lines look like `path(l,c): msg` or, with a sourcemap, `/abs/path [game/...](l,c): msg`.
	# Multi-line type errors keep only their first line.
	grep -E '^[^ ]+( \[[^]]*\])?\([0-9]+,[0-9]+\): ' "$log" |
		sed -E -e 's/^([^ (]+)( \[[^]]*\])?\(([0-9]+),[0-9]+\): /\1:\3: /' -e "s|^$PWD/||" >"$lsp"
	# luau-lsp exits non-zero for any type error, baselined or not: only a run with no findings is a crash.
	if [ "$rc" -ne 0 ] && [ ! -s "$lsp" ]; then
		echo "default.project.json:1: luau-lsp failed (exit $rc): $(grep -m1 -v '^[[:space:]]*$' "$log" | cut -c1-160)" >>"$out"
	fi
	# Lints (anything but TypeError) always fail; type errors are compared with the baseline.
	grep -v ': TypeError: ' "$lsp" >>"$out"
	grep ': TypeError: ' "$lsp" | awk -v base="$BASELINE" -v notes="$notes" '
		BEGIN {
			while ((getline line < base) > 0) {
				n++
				if (line ~ /^[[:space:]]*(#|$)/) continue
				split(line, p, " ")
				allowed[p[1]] = p[2] + 0
				at[p[1]] = n
			}
		}
		{
			f = substr($0, 1, index($0, ":") - 1)
			count[f]++
			shown[f] = shown[f] $0 "\n"
		}
		END {
			for (f in count) {
				a = (f in allowed) ? allowed[f] : 0
				if (count[f] > a) {
					printf "%s:1: %d type errors, baseline allows %d (fix the new ones)\n", f, count[f], a
					printf "%s", shown[f]
				}
			}
			for (f in allowed) {
				c = (f in count) ? count[f] : 0
				if (c < allowed[f])
					printf "%s:%d: %s has %d type errors now (baseline %d); lower it\n", base, at[f], f, c, allowed[f] > notes
			}
		}' >>"$out"
fi

# --- tests -----------------------------------------------------------------------------------
n=$(lines)
lune run tests/run >"$log" 2>&1
rc=$?
sed -E 's/^([^:]+): /\1:1: /' "$log" >>"$out"
fail_if_silent lune "$rc" "$n" tests/run.luau

n=$(lines)
bash tests/hook.test.sh >"$log" 2>&1
rc=$?
sed -nE 's/^FAIL: (.*)$/tests\/hook.test.sh:1: \1/p' "$log" >>"$out"
fail_if_silent hook.test.sh "$rc" "$n" tests/hook.test.sh

if [ -s "$out" ]; then
	head -30 "$out"
	exit 1
fi
sort "$notes" | head -29
echo OK

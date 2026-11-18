#!/usr/bin/env bash
# Quiet check: prints exactly "OK" on success; on failure only `file:line: message` lines (max 30), exit 1.
# Scope: factory-2.0 files only. Legacy src/ and the Studio factory tests (tests/NN_*.luau) are excluded
# until they are brought up to standard (see ledger ruling, Task 1).
set -u
export PATH="$HOME/.rokit/bin:$PATH"
cd "$(dirname "$0")/.."

out=$(mktemp)
trap 'rm -f "$out"' EXIT

# Files owned by factory 2.0 (lune tools/tests, scene data/loader, specs).
lune_files=()
while IFS= read -r f; do lune_files+=("$f"); done < <(
	{
		ls tests/run.luau tools/*.luau tools/lib/*.luau 2>/dev/null
		find tests -type f -name '*.spec.luau' 2>/dev/null
		ls src/server/SceneLoader.luau 2>/dev/null
		find src/shared/Scene src/server/Scenes -type f -name '*.luau' 2>/dev/null
	} | sort -u
)
# luau-lsp cannot resolve @lune/* requires, so it only checks files that don't host Lune APIs.
typed_files=()
for f in "${lune_files[@]}"; do
	case "$f" in tests/run.luau | tools/*.luau | tools/lib/*.luau) ;; *) grep -q '@lune/' "$f" || typed_files+=("$f") ;; esac
done

if [ ${#lune_files[@]} -gt 0 ]; then
	stylua --check --output-format summary "${lune_files[@]}" 2>&1 |
		grep -E '^[^ !✓✕].*\.luau$' | sed 's/$/:1: not formatted (run stylua)/' >>"$out"
	selene --display-style quiet "${lune_files[@]}" 2>&1 |
		grep -E '^[^ ]+:[0-9]+:[0-9]+:' | sed -E 's/^([^:]+):([0-9]+):[0-9]+: /\1:\2: /' >>"$out"
fi

# A prefab Rojo can't read must fail the check instead of crashing `rojo serve`.
rojo_build=$(rojo build default.project.json -o "$(dirname "$out")/check.rbxl" 2>&1) || {
	bad=$(printf '%s\n' "$rojo_build" | grep -oE '[A-Za-z0-9_./-]+\.rbxm' | head -1 | sed "s|^$PWD/||")
	build_failed=1
	echo "${bad:-default.project.json}:1: rojo build failed${bad:+ (unreadable prefab)}" >>"$out"
}
rm -f "$(dirname "$out")/check.rbxl"
[ -z "${build_failed:-}" ] && { rojo sourcemap default.project.json -o sourcemap.json >/dev/null 2>&1 || echo "default.project.json:1: rojo sourcemap failed" >>"$out"; }
if [ ${#typed_files[@]} -gt 0 ] && [ -f tools/types/globalTypes.d.luau ]; then
	luau-lsp analyze --definitions=@roblox=tools/types/globalTypes.d.luau --sourcemap=sourcemap.json "${typed_files[@]}" 2>&1 |
		grep -E '^[^ ]+\([0-9]+,[0-9]+\): ' | sed -E 's/^([^(]+)\(([0-9]+),[0-9]+\): /\1:\2: /' >>"$out"
fi

lune run tests/run 2>&1 | sed -E 's/^([^:]+): /\1:1: /' >>"$out"

if [ -s "$out" ]; then
	head -30 "$out"
	exit 1
fi
echo OK

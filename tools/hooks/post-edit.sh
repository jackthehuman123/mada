#!/usr/bin/env bash
# PostToolUse hook (Edit|Write): format edited .luau files with StyLua.
# Reads hook JSON on stdin. No linting here (check.sh does that). Always exits 0.
file="$(jq -r '.tool_input.file_path // empty' 2>/dev/null)"
case "$file" in
*.luau)
	if [ -f "$file" ]; then
		stylua "$file" >/dev/null 2>&1
	fi
	;;
esac
exit 0

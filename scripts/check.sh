#!/usr/bin/env bash
# Headless verification: format check, lint, type check, unit tests, place build.
# Usage: scripts/check.sh [--fix]   (--fix runs stylua in write mode instead of check mode)
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.rokit/bin:$PATH"

DEFS=.luau-defs/globalTypes.d.luau
if [ ! -f "$DEFS" ]; then
	mkdir -p .luau-defs
	curl -sSfL -o "$DEFS" https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau
fi

if [ "${1:-}" = "--fix" ]; then
	stylua src tests .lune
else
	stylua --check src tests .lune
fi
echo "stylua: ok"

selene src tests
echo "selene: ok"

rojo sourcemap -o sourcemap.json >/dev/null
luau-lsp analyze --defs="$DEFS" --sourcemap=sourcemap.json --ignore="Packages/**" src 2>&1 | grep -v '^\[' || true
# luau-lsp exits non-zero on type errors; re-run quietly to get the status
luau-lsp analyze --defs="$DEFS" --sourcemap=sourcemap.json --ignore="Packages/**" src >/dev/null 2>&1
echo "luau-lsp analyze: ok"

python3 scripts/gen-roster.py --check
python3 scripts/gen-icons.py --check
echo "roster: up to date"

lune run test
echo "lune tests: ok"

rojo build -o build.rbxl >/dev/null
echo "rojo build: ok (build.rbxl)"

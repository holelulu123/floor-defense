#!/bin/bash
# Roblox Studio's built-in MCP server (Assistant > ... > Manage MCP Servers > Enable Studio as MCP server) for
# Claude Code on Linux, where Studio runs under Vinegar (flatpak + Wine). Roblox ships StudioMCP.exe, a stdio
# proxy that talks to the running Studio; it must run inside Studio's own flatpak sandbox and Wine prefix to
# reach it. Registered with: claude mcp add roblox-studio -- scripts/roblox/studio-mcp.sh
set -euo pipefail
B="$HOME/.var/app/org.vinegarhq.Vinegar/data/vinegar"
INSTANCE=$(flatpak ps --columns=instance,application | awk '$2 == "org.vinegarhq.Vinegar" { print $1; exit }')
if [ -z "$INSTANCE" ]; then
	echo "Roblox Studio (Vinegar) is not running; start Studio first" >&2
	exit 1
fi
# mcp.bat (written by Studio) names the StudioMCP.exe of the installed Studio version.
EXE=$(grep -o 'Z:[^"]*StudioMCP.exe' "$B/appdata/Roblox/mcp.bat" | head -1 | sed 's|^Z:||; s|\\|/|g')
[ -f "$EXE" ] || EXE=$(ls -t "$B"/versions/*/StudioMCP.exe | head -1)
exec flatpak enter "$INSTANCE" env WINEPREFIX="$B/prefixes/studio" WINEDEBUG=-all "$B/kombucha/bin/wine" "$EXE"

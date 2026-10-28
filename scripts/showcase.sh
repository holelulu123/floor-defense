#!/usr/bin/env bash
# Serves the repo over HTTP and opens the asset showcase. Browsers block glb/ogg loads from file://,
# and the page pulls three.js from a CDN, so you need internet for the first load.
# Usage: scripts/showcase.sh [port]
set -euo pipefail
cd "$(dirname "$0")/.."
PORT=${1:-8765}
python3 - "$PORT" >/dev/null 2>&1 <<'PY' &
# http.server with no-cache headers, so edits to the page show up on a plain reload.
import sys, http.server
class H(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-store"); super().end_headers()
http.server.ThreadingHTTPServer(("127.0.0.1", int(sys.argv[1])), H).serve_forever()
PY
SERVER=$!
trap 'kill $SERVER 2>/dev/null' EXIT
sleep 0.5
URL="http://127.0.0.1:$PORT/showcase/index.html"
echo "Showcase at $URL (Ctrl+C to stop)"
xdg-open "$URL" 2>/dev/null || true
wait $SERVER

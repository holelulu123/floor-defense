#!/usr/bin/env python3
"""Roblox Open Cloud helper: publish the built place, run Luau in the cloud, flip visibility.

Credentials come from scripts/roblox/.env (gitignored) or the environment:
  ROBLOX_API_KEY      Open Cloud API key (Creator Dashboard > Open Cloud > API Keys)
  ROBLOX_UNIVERSE_ID  the experience (universe) id
  ROBLOX_PLACE_ID     the start place id

Usage:
  cloud.py publish [build.rbxl] [--saved]     upload the place file as a new published (or saved) version
  cloud.py run <script.luau> [--timeout 120]  run a Luau script server-side in the cloud and print its output
  cloud.py public | private                   set the experience visibility (falls back to instructions)
  cloud.py info                               show universe + place metadata
No third-party packages: stdlib only.
"""
import json
import os
import sys
import time
import urllib.error
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
API = "https://apis.roblox.com"


def load_env():
    path = os.path.join(HERE, ".env")
    if os.path.exists(path):
        for line in open(path):
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                os.environ.setdefault(k.strip(), v.strip().strip('"'))
    missing = [k for k in ("ROBLOX_API_KEY", "ROBLOX_UNIVERSE_ID", "ROBLOX_PLACE_ID") if not os.environ.get(k)]
    if missing:
        sys.exit(f"missing {', '.join(missing)}; put them in {path} (see docs/ROBLOX.md)")
    return os.environ["ROBLOX_API_KEY"], os.environ["ROBLOX_UNIVERSE_ID"], os.environ["ROBLOX_PLACE_ID"]


def call(method, url, key, body=None, ctype="application/json", raw=False):
    data = body if isinstance(body, (bytes, type(None))) else json.dumps(body).encode()
    req = urllib.request.Request(url, data=data, method=method, headers={"x-api-key": key, "Content-Type": ctype})
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            txt = r.read()
            return r.status, (txt if raw else (json.loads(txt) if txt else {}))
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode(errors="replace")


def publish(key, uni, place, path, saved=False):
    if not os.path.exists(path):
        sys.exit(f"{path} not found; run `rojo build -o {path}` first")
    vt = "Saved" if saved else "Published"
    status, out = call("POST", f"{API}/universes/v1/{uni}/places/{place}/versions?versionType={vt}", key,
                       open(path, "rb").read(), ctype="application/octet-stream")
    print(status, out)
    if status != 200:
        sys.exit(1)
    print(f"{vt} version {out.get('versionNumber')} of place {place}")


def run_luau(key, uni, place, script_path, timeout=120):
    src = open(script_path).read()
    base = f"{API}/cloud/v2/universes/{uni}/places/{place}/luau-execution-session-tasks"
    status, out = call("POST", base, key, {"script": src})
    if status not in (200, 201):
        sys.exit(f"create task failed: {status} {out}")
    task_path = out["path"]
    deadline = time.time() + timeout
    while time.time() < deadline:
        status, task = call("GET", f"{API}/cloud/v2/{task_path}", key)
        if status != 200:
            sys.exit(f"poll failed: {status} {task}")
        if task.get("state") in ("COMPLETE", "FAILED", "CANCELLED"):
            break
        time.sleep(2)
    _, logs = call("GET", f"{API}/cloud/v2/{task_path}/logs", key)
    for page in (logs.get("luauExecutionSessionTaskLogs") or []):
        for m in page.get("messages", []):
            print(m)
    print("state:", task.get("state"))
    if task.get("error"):
        print("error:", json.dumps(task["error"], indent=1))
    if "output" in task:
        print("results:", json.dumps(task["output"].get("results"), indent=1))
    return task.get("state") == "COMPLETE" and not task.get("error")


def visibility(key, uni, public):
    status, out = call("PATCH", f"{API}/cloud/v2/universes/{uni}?updateMask=visibility", key,
                       {"visibility": "PUBLIC" if public else "PRIVATE"})
    print(status, out)
    if status != 200:
        print("Open Cloud refused the visibility change. Do it once by hand: Creator Dashboard > the experience > "
              "Audience/Access > Public, then re-run `cloud.py info` to confirm.")
        sys.exit(1)


def info(key, uni, place):
    for url in (f"{API}/cloud/v2/universes/{uni}", f"{API}/cloud/v2/universes/{uni}/places/{place}"):
        status, out = call("GET", url, key)
        print(status, json.dumps(out, indent=1) if isinstance(out, dict) else out)


def main(argv):
    if len(argv) < 2 or argv[1] in ("-h", "--help"):
        print(__doc__)
        return 0
    key, uni, place = load_env()
    cmd = argv[1]
    if cmd == "publish":
        path = next((a for a in argv[2:] if not a.startswith("--")), "build.rbxl")
        publish(key, uni, place, path, saved="--saved" in argv)
    elif cmd == "run":
        timeout = int(argv[argv.index("--timeout") + 1]) if "--timeout" in argv else 120
        ok = run_luau(key, uni, place, argv[2], timeout)
        return 0 if ok else 1
    elif cmd in ("public", "private"):
        visibility(key, uni, cmd == "public")
    elif cmd == "info":
        info(key, uni, place)
    else:
        sys.exit(f"unknown command {cmd}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))

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
  cloud.py upload <image.png>...              upload images as decals (needs ROBLOX_USER_ID); ids are kept in
                                              assets/ui/roblox-ids.json so an unchanged file is never re-uploaded
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


def run_luau(key, uni, place, script_path, timeout=120, src=None, quiet=False):
    src = src if src is not None else open(script_path).read()
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
    if quiet:
        return task.get("output", {}).get("results")
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


IDS = os.path.join(HERE, "..", "..", "assets", "ui", "roblox-ids.json")


def upload_images(key, paths):
    import hashlib
    import uuid

    user = os.environ.get("ROBLOX_USER_ID")
    if not user:
        sys.exit("set ROBLOX_USER_ID in scripts/roblox/.env (the number in your roblox.com/users/<id>/profile URL)")
    ids = json.load(open(IDS)) if os.path.exists(IDS) else {}
    for path in paths:
        name = os.path.splitext(os.path.basename(path))[0]
        data = open(path, "rb").read()
        digest = hashlib.sha256(data).hexdigest()[:16]
        if ids.get(name, {}).get("sha") == digest:
            print(f"{name}: unchanged, decal {ids[name]['decal']}")
            continue
        meta = {"assetType": "Decal", "displayName": f"Floor Defense {name}"[:50], "description": "Floor Defense UI image",
                "creationContext": {"creator": {"userId": str(user)}}}
        b = uuid.uuid4().hex
        body = (f'--{b}\r\nContent-Disposition: form-data; name="request"\r\nContent-Type: application/json\r\n\r\n'
                f"{json.dumps(meta)}\r\n--{b}\r\nContent-Disposition: form-data; name=\"fileContent\"; "
                f'filename="{os.path.basename(path)}"\r\nContent-Type: image/png\r\n\r\n').encode() + data + f"\r\n--{b}--\r\n".encode()
        status, op = call("POST", f"{API}/assets/v1/assets", key, body, ctype=f"multipart/form-data; boundary={b}")
        if status != 200:
            print(f"{name}: upload failed {status} {op}")
            continue
        asset = None
        for _ in range(30):  # the upload is an operation; poll until it reports the asset
            if isinstance(op, dict) and op.get("done"):
                asset = op.get("response", {}).get("assetId")
                break
            time.sleep(1)
            status, op = call("GET", f"{API}/assets/v1/{op['path']}", key)
        if not asset:
            print(f"{name}: no asset id yet ({op})")
            continue
        ids[name] = {"decal": asset, "sha": digest}
        json.dump(ids, open(IDS, "w"), indent=1, sort_keys=True)
        print(f"{name}: decal {asset}")
    # UI needs the decal's Image id; only a game server owned by the same creator can read it (InsertService).
    todo = {n: v["decal"] for n, v in ids.items() if not v.get("image")}
    if todo:
        lua = ("local I = game:GetService('InsertService') local out = {} for n, id in {"
               + ", ".join(f'["{n}"] = {v}' for n, v in todo.items())
               + "} do local ok, m = pcall(I.LoadAsset, I, id) local d = ok and m:FindFirstChildWhichIsA('Decal', true)"
               " out[n] = d and d.Texture or '' end return out")
        uni, place = os.environ["ROBLOX_UNIVERSE_ID"], os.environ["ROBLOX_PLACE_ID"]
        res = run_luau(key, uni, place, None, src=lua, quiet=True) or [{}]
        for n, tex in (res[0] or {}).items():
            if tex:
                ids[n]["image"] = tex
                print(f"{n}: image {tex}")
            else:
                print(f"{n}: image not ready yet (moderation?); rerun upload later")
        json.dump(ids, open(IDS, "w"), indent=1, sort_keys=True)
    return ids


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
    elif cmd == "upload":
        upload_images(key, argv[2:])
    else:
        sys.exit(f"unknown command {cmd}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))

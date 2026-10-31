#!/usr/bin/env python3
"""Fills src/shared/Icons.luau with the Image ids that `scripts/roblox/cloud.py upload` recorded in
assets/ui/roblox-ids.json. Keys missing from the json stay "" (the UI keeps its text-only look).
--check exits 1 when Icons.luau is out of date."""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
ids = json.loads((ROOT / "assets/ui/roblox-ids.json").read_text())
path = ROOT / "src/shared/Icons.luau"
src = path.read_text()


def fill(m):
    key = m.group(2)
    return f'{m.group(1)}{key} = "{ids.get(key, {}).get("image", "")}",'


out = re.sub(r'^(\t)(\w+) = "[^"]*",', fill, src, flags=re.M)
if "--check" in sys.argv:
    sys.exit(0 if out == src else "Icons.luau is out of date: run scripts/gen-icons.py")
path.write_text(out)
print("wrote", path.relative_to(ROOT))

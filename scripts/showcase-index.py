#!/usr/bin/env python3
"""Scans assets/ and writes showcase/files.json so new model files show up in the showcase
without editing HTML. Hand-written creature/character definitions live in showcase/catalog.js."""
import json
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets"
OUT = ROOT / "showcase" / "files.json"

# kind -> list of (pack dir, display name, license summary)
PACKS = {
    "weapons": [
        ("weapons/kenney-weapon-pack", "Kenney Weapon Pack", "CC0"),
        ("props/kaykit-dungeon", "KayKit Dungeon (weapons only)", "CC0"),
    ],
    "props": [
        ("props/kaykit-halloween", "KayKit Halloween Bits", "CC0"),
        ("props/kaykit-dungeon", "KayKit Dungeon Remastered (selection)", "CC0"),
        ("props/quaternius-nature", "Quaternius Ultimate Nature (selection)", "CC0"),
        ("props/quaternius-village", "Quaternius Medieval Village (selection)", "CC0"),
        ("props/quaternius-dungeon", "Quaternius Modular Dungeon (selection)", "CC0"),
        ("props/quaternius-ruins", "Quaternius Modular Dungeons ruins (selection)", "CC0"),
        ("props/quaternius-cyberpunk-props", "Quaternius Cyberpunk Game Kit props (selection)", "CC0"),
        ("props/quaternius-space-props", "Quaternius Ultimate Space Kit props (selection)", "CC0"),
        ("props/quaternius-ships", "Quaternius Ships", "CC0"),
        ("props/quaternius-crops", "Quaternius Ultimate Crops (selection)", "CC0"),
        ("props/quaternius-platformer-props", "Quaternius Modular Platformer props (selection)", "CC0"),
    ],
}
WEAPON_WORDS = re.compile(r"sword|shield|axe|bow|dagger|staff|spear|hammer|knife|gun|pistol|rifle|uzi|shotgun|sniper|rocket|flame|grenade|ammo", re.I)


def pretty(name: str) -> str:
    name = re.sub(r"\.gltf$|\.glb$", "", name)
    name = name.replace(".gltf", "")
    return re.sub(r"[_-]+", " ", name).strip()


def scan(rel: str, only_weapons: bool | None):
    folder = ASSETS / rel
    items = []
    for p in sorted(folder.iterdir()):
        if p.suffix.lower() not in (".glb", ".gltf"):
            continue
        is_weapon = bool(WEAPON_WORDS.search(p.name)) and not p.name.startswith("banner")
        if only_weapons is True and not is_weapon:
            continue
        if only_weapons is False and is_weapon:
            continue
        items.append({"name": pretty(p.name), "file": f"../assets/{rel}/{p.name}"})
    return items


catalog = {}
for kind, packs in PACKS.items():
    catalog[kind] = []
    for rel, title, lic in packs:
        only = None
        if rel == "props/kaykit-dungeon":
            only = kind == "weapons"
        items = scan(rel, only)
        if items:
            catalog[kind].append({"pack": title, "license": lic, "items": items})

OUT.write_text(json.dumps(catalog, indent=1))
print(f"wrote {OUT.relative_to(ROOT)}: " + ", ".join(f"{k}={sum(len(p['items']) for p in v)}" for k, v in catalog.items()))

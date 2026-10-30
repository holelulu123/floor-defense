# Publishing and testing on Roblox without Studio

Studio is only needed for a few things (3D import of the glb assets, authoring R15 animations, play-testing
with a real client). Everything else runs from this machine through Roblox Open Cloud:

| Step | How | Tool |
|---|---|---|
| Build the place file | `rojo build -o build.rbxl` (part of `scripts/check.sh`) | Rojo |
| Publish the place | upload `build.rbxl` as a new version | `scripts/roblox/cloud.py publish` |
| Run server-side tests in the live place | Luau Execution API runs a script inside the published place and returns its output | `scripts/roblox/cloud.py run scripts/roblox/smoke.luau` |
| Make the experience public | Universe PATCH (visibility); if refused, toggle once in Creator Dashboard | `scripts/roblox/cloud.py public` |
| Inspect universe/place metadata | | `scripts/roblox/cloud.py info` |

## One-time setup (needs the account owner)

1. Create the experience once: Creator Dashboard > Create > Experience (any template; our place file
   replaces it). Note the **Universe ID** and the **start Place ID** from the dashboard URL / experience overview.
2. Create an Open Cloud API key: Creator Dashboard > Open Cloud > API Keys > Create. Give it these
   permissions, scoped to that experience:
   - `universe-places:write` (Place publishing)
   - `universe.place.luau-execution-session:write` and `:read` (Luau execution, under "Luau Execution")
   - `universe:read` and `universe:write` (visibility, metadata)
   - `asset:read`, `asset:write` (mesh/texture uploads later)
   Restrict the key to this machine's IP or 0.0.0.0/0 while testing, and set an expiry.
3. Put the values in `scripts/roblox/.env` (gitignored):
   ```
   ROBLOX_API_KEY=...
   ROBLOX_UNIVERSE_ID=...
   ROBLOX_PLACE_ID=...
   ```

## Release loop

```
scripts/check.sh                      # lint, Lune tests, rojo build -> build.rbxl
scripts/roblox/cloud.py publish       # new published version
scripts/roblox/cloud.py run scripts/roblox/smoke.luau   # server smoke test in the cloud
```

The smoke test requires every shared module, checks the dungeon and class tables, and verifies the Lobby
folder exists in `workspace`. It prints `PASS`/`FAIL` lines and `SMOKE n checks, m failed`.

## What still needs Studio

- Importing the glb creatures, towers, weapons and props as MeshParts (3D Importer), then recording the
  asset ids in `src/shared/Assets.luau`.
- R15 animations for the 22 class skills (Animation Editor), published as animation assets.
- A real play-test with a client: pads, shooting, HUD. Open Cloud can only run server-side code.

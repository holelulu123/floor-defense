# Working with Roblox from this machine

Two channels: **Studio MCP** for anything inside a running Studio (play-tests, Output, Luau, screenshots), and
**Open Cloud** for publishing and the live place. Rojo (`rojo serve`) keeps Studio's scripts in sync with `src/`.

## Studio MCP (Claude Code drives Studio)

Roblox Studio has a built-in MCP server ([docs](https://create.roblox.com/docs/studio/mcp)). Enable it in Studio:
Assistant > ... > Manage MCP Servers > **Enable Studio as MCP server**. Roblox documents Windows and macOS only; on
this Linux machine Studio runs under Vinegar, so `scripts/roblox/studio-mcp.sh` starts Roblox's `StudioMCP.exe`
inside Studio's flatpak sandbox and Wine prefix. It is registered once per machine:

```
claude mcp add --scope local roblox-studio -- "$PWD/scripts/roblox/studio-mcp.sh"
claude mcp list        # roblox-studio: ... Connected  (Studio must be running with the toggle on)
```

Tools Claude uses (all take the `studio_id` from `list_roblox_studios`): `start_stop_play`, `get_studio_state`,
`get_console_output`, `execute_luau` (Edit, Client or Server datamodel), `screen_capture`, `character_navigation`,
`user_keyboard_input` / `user_mouse_input`, `search_game_tree`, `inspect_instance`, `script_read` / `script_grep`.
Scripts are edited in `src/` and synced by Rojo, never with the MCP script editing tools, so git stays the source
of truth. The MCP clients can change open places, so only trusted clients are connected; turn the toggle off to cut
access. The older keyboard/screen-capture loop (xdotool) and the `FloorDefenseAgent` plugin are fallbacks only.

## Open Cloud

Studio is only needed for a few things (3D import of the glb assets, authoring R15 animations, play-testing
with a real client). Everything else runs from this machine through Roblox Open Cloud:

| Step | How | Tool |
|---|---|---|
| Build the place file | `rojo build -o build.rbxl` (part of `scripts/check.sh`) | Rojo |
| Publish the place | upload `build.rbxl` as a new version | `scripts/roblox/cloud.py publish` |
| Run server-side tests in the live place | Luau Execution API runs a script inside the published place and returns its output | `scripts/roblox/cloud.py run scripts/roblox/smoke.luau` |
| Make the experience public | Universe PATCH (visibility); if refused, toggle once in Creator Dashboard | `scripts/roblox/cloud.py public` |
| Inspect universe/place metadata | | `scripts/roblox/cloud.py info` |
| Upload UI images (icons, class portraits) | uploads each PNG as a decal, then reads its Image id inside the place (InsertService); ids land in `assets/ui/roblox-ids.json`, unchanged files are skipped | `scripts/roblox/cloud.py upload assets/ui/icons/*.png` |

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
   ROBLOX_USER_ID=...   # owner of uploaded images (roblox.com/users/<id>/profile)
   ```

## Release loop

```
scripts/check.sh                      # lint, Lune tests, rojo build -> build.rbxl
scripts/roblox/cloud.py publish       # new published version
scripts/roblox/cloud.py run scripts/roblox/smoke.luau   # server smoke test in the cloud
```

The smoke test requires every shared module, checks the dungeon and class tables, and checks the lobby builder
is in the place (execution sessions do not start the place's own Scripts). It prints `PASS`/`FAIL` lines and `SMOKE n checks, m failed`.

## Studio notes

- The Studio place template ships a broken `Sky` in Lighting (SkyboxBk `rbxassetid://6444884337`, SkyboxUp
  `6412503613`, Sun `6196665106`) that renders black; `Environment.server.luau` removes any Sky/DepthOfField not
  marked as ours, Lighting is defined in `default.project.json`, and `Environment.client.luau` tweens per-zone moods.

## Still to do in Studio

- Importing the glb creatures, towers, weapons and props as MeshParts, then recording the asset ids in
  `src/shared/Assets.luau` (Studio MCP `insert_asset` can place them once uploaded).
- R15 animations for the 20 class skills (the showcase clips in `showcase/index.html` `makeRigClips` are the
  reference), published as animation assets.
- Client play-tests (pads, shooting, HUD) run through Studio MCP; Open Cloud only runs server-side code.
- DataStores in Studio: Game Settings > Security > Enable Studio Access to API Services, or saves fall back to
  default data in Studio.

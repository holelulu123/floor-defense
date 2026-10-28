# roblox-mod

Roblox experience developed code-first with Rojo. Developer works on Arch Linux; Roblox Studio runs under Vinegar (Wine).

## Layout
- `src/server` -> ServerScriptService.Server (`*.server.luau` = Script, plain `.luau` = ModuleScript)
- `src/client` -> StarterPlayer.StarterPlayerScripts.Client (`*.client.luau` = LocalScript)
- `src/shared` -> ReplicatedStorage.Shared
- `Packages` (Wally, gitignored) -> ReplicatedStorage.Packages

## Commands
- `rokit install` — install pinned toolchain (rokit.toml)
- `wally install` — install packages
- `rojo serve` — live-sync into Studio (Rojo plugin connects to localhost:34872)
- `rojo build -o build.rbxl` — build a place file
- `selene src` / `stylua src` — lint / format
- `lune run test` — run `tests/*.spec.luau` (pure modules in `src/shared` only)
- `scripts/check.sh [--fix]` — full headless check: stylua, selene, luau-lsp analyze, tests, rojo build

## Conventions
- Keep game rules (wave math, pad countdown, item data) in `src/shared` as pure modules with no Roblox API calls so Lune can test them. Roblox-coupled code lives in `src/server` / `src/client`.
- Run `scripts/check.sh` before committing.
- Design reference: `DESIGN.md`.
- Server is authoritative: never trust values from RemoteEvents; validate everything server-side.
- Developer product handling must stay idempotent (see `Monetization.luau`).
- Tabs, 120 columns, double quotes (stylua.toml).

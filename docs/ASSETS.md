# Assets and licenses

Moved out of DESIGN.md so the design doc stays about the game. Rule: only CC0 (or equivalently permissive) packs go into `assets/`, each with its LICENSE file beside it.

### In the repo now (licenses verified 2026-10-28)

| Asset | Where | License | Verified from |
| --- | --- | --- | --- |
| KayKit Character Pack: Skeletons 1.0 (4 animated glTF skeletons, 95 animations each, texture) | `assets/creatures/kaykit-skeletons/` | CC0 1.0, no attribution required; README lists Roblox as a supported engine | `LICENSE.txt` in the pack, github.com/KayKit-Game-Assets |
| Kenney Impact Sounds (130 ogg: impacts, footsteps) | `assets/sounds/kenney-impact/` | CC0 1.0 | `LICENSE.txt` in the pack; kenney.nl/support states all assets are CC0 |
| Kenney Graveyard Kit characters (zombie, skeleton, ghost, vampire, keeper; animated: idle, walk, sprint, jump, die) | `assets/creatures/kenney-graveyard/` | CC0 1.0 | kenney.nl/support; glTF copies from github.com/shorepine/kenney |
| Kenney Weapon Pack (37 guns, grenades, knives, ammo) | `assets/weapons/kenney-weapon-pack/` | CC0 1.0 | kenney.nl/support; glTF copies from github.com/shorepine/kenney |
| KayKit Halloween Bits (63 graveyard props: graves, crypts, fences, dead trees, lanterns) | `assets/props/kaykit-halloween/` | CC0 1.0 | `LICENSE.txt` in the pack |
| KayKit Dungeon Remastered, selection (chests, barrels, torches, coins, banners, sword+shield, spike trap) | `assets/props/kaykit-dungeon/` | CC0 1.0 | `LICENSE.txt` in the pack |
| Stat icons (health, speed, damage, coins, wave, kills) | `assets/ui/icons/` | Ours, CC0; drawn by `scripts/make-icons.py` | — |

Role mapping (KayKit family): Minion = Runner, Warrior = Brute (and Boss at 2.4x, red tint), Mage = Spitter, Rogue = Elite Runner. Kenney family: Zombie = Runner, Skeleton = Elite, S-Ghost = Spitter, Vampire = Brute, Keeper = Boss. Players keep their own avatar (see Classes), so no player-body packs are kept. Browse everything with `scripts/showcase.sh` (`showcase/index.html`: tabs for creatures, classes, weapons, props; animations, hit/death sounds, stats with icons, auto-rendered thumbnails). `scripts/showcase-index.py` regenerates the weapons/props list from the `assets/` folders.

### License notes per source (checked on the source pages)

| Source | License | Commercial | Attribution | Caveat |
| --- | --- | --- | --- | --- |
| Quaternius | CC0 | Yes | No | Downloads are via Google Drive / itch.io (browser only) |
| Kenney | CC0 | Yes | No | Don't use the Kenney logo |
| KayKit (Kay Lousberg) | CC0 | Yes | No | EXTRA/SOURCE tiers are paid; free tier is CC0 |
| Mixamo (Adobe) | Adobe terms, royalty-free | Yes | No | Can't redistribute characters/animations as standalone assets; official FAQ page blocks automated fetch, confirm by hand before release |
| Poly Pizza | Per model: CC0 or CC-BY | Yes | Only for CC-BY models | Record author + license per model |
| Roblox Creator Store | Roblox Terms / Creator Terms | Within Roblox | No | Usable inside Roblox experiences only; no explicit per-asset license text; avoid models containing scripts |
| Freesound | Per sound: CC0 / CC-BY / CC-BY-NC | CC0 and CC-BY only | CC-BY needs credit | CC-BY-NC is not allowed in a monetized game |
| OpenGameArt | Per asset: CC0 / CC-BY / CC-BY-SA / GPL | Depends | Usually | Avoid CC-BY-SA and GPL for a closed game |
| Sketchfab | Per model: CC variants, or Store license | Depends | Usually | Check each model; editorial licenses are non-commercial |

### Other sources considered

Where the units, weapons and map pieces come from, cheapest first:

| Source | Cost | Fits | Notes |
| --- | --- | --- | --- |
| Roblox Creator Store (Toolbox in Studio) | Free | Props, map kits, animations, some rigs | Check each asset's license; avoid anything with scripts inside (malware risk). Roblox's own "Endorsed" packs are safe. |
| Roblox Rig Builder + Avatar Editor | Free | Player characters | Built into Studio. R15 rigs with free animations; characters differ by clothing, accessories and scale, which is enough for the ten silhouettes. |
| Kenney.nl | Free (CC0) | Low-poly props, weapons, nature | Import as FBX/OBJ into Studio as MeshParts. |
| Quaternius | Free (CC0) | Low-poly animated monsters and characters | Best free source for creature families; ships with animations. |
| Synty Studios POLYGON packs | $20–60 per pack | Low-poly everything, consistent style | The usual pick for solo devs who want one coherent look. Needs Blender to re-rig for Roblox's R15 skeleton. |
| Sketchfab / CGTrader | Varies | Specific pieces | Check license allows games. |
| Blender + Mixamo | Free | Custom creatures and animations | Model in Blender, auto-rig and animate on Mixamo, import FBX into Studio. Slowest path, most control. |

What I can produce directly:

- **Blocky, Roblox-native models** built from Parts, Unions and MeshParts via code (Lune scripts or `.model.json` in Rojo): barricades, floor pads, the Town Hall, spell visuals, simple creatures in the "classic Roblox" style. Good enough for the MVP and consistent with the platform's look.
- **Blender Python scripts** that generate simple low-poly creatures and weapons procedurally, which you run in Blender and export as FBX. Quality is "stylized low-poly", not sculpted.
- **Animations** via AnimationEditor keyframe data written as code, for simple loops (walk, attack, idle).

What I cannot produce: detailed sculpted characters, hand-painted textures, or anything that needs an artist's eye on the result. For those, Quaternius for creatures and Synty for the world is the practical combination. Recommended plan: MVP with blocky code-built placeholders, then swap in Quaternius creatures once the loop is fun.


# Assets and licenses

Moved out of DESIGN.md so the design doc stays about the game. Rule: CC0 packs, or CC-BY packs with attribution recorded below (see "Attribution"), go into `assets/`, each with its LICENSE file beside it.

### In the repo now (licenses verified 2026-10-28)

| Asset | Where | License | Verified from |
| --- | --- | --- | --- |
| KayKit Character Pack: Skeletons 1.0 (4 animated glTF skeletons, 95 animations each, texture) | `assets/creatures/kaykit-skeletons/` | CC0 1.0, no attribution required; README lists Roblox as a supported engine | `LICENSE.txt` in the pack, github.com/KayKit-Game-Assets |
| Kenney Impact Sounds (130 ogg: impacts, footsteps) | `assets/sounds/kenney-impact/` | CC0 1.0 | `LICENSE.txt` in the pack; kenney.nl/support states all assets are CC0 |
| Kenney Graveyard Kit characters (zombie, skeleton, ghost, vampire, keeper; animated: idle, walk, sprint, jump, die) | `assets/creatures/kenney-graveyard/` | CC0 1.0 | kenney.nl/support; glTF copies from github.com/shorepine/kenney |
| Kenney Weapon Pack (37 guns, grenades, knives, ammo) | `assets/weapons/kenney-weapon-pack/` | CC0 1.0 | kenney.nl/support; glTF copies from github.com/shorepine/kenney |
| Quaternius Farm Animals Pack (Cow, Horse, Llama, Pig, Pug, Sheep, Zebra; Idle/Walk/Run/Jump/Death) | `assets/creatures/quaternius-farm-animals/` | CC0 1.0 | `LICENSE.txt` in the pack; Blender export, see `SOURCE.md` |
| Kenney Blocky Characters (18 animated blocky people, 27 clips each) used only as the optional random player skin in the class preview (no longer used as creatures) | `assets/creatures/kenney-blocky/` | CC0 1.0 | `SOURCE.md` in the pack; kenney.nl/support; glTF copies from github.com/shorepine/kenney |
| KayKit Halloween Bits (63 graveyard props: graves, crypts, fences, dead trees, lanterns) | `assets/props/kaykit-halloween/` | CC0 1.0 | `LICENSE.txt` in the pack |
| KayKit Dungeon Remastered, selection (chests, barrels, torches, coins, banners, sword+shield, spike trap) | `assets/props/kaykit-dungeon/` | CC0 1.0 | `LICENSE.txt` in the pack |
| Quaternius Ultimate Animated Animals (12: wolf, fox, stag, deer, husky, shiba, cow, bull, horses, donkey, alpaca; 12-13 clips each) | `assets/creatures/quaternius-animals/` | CC0 1.0 | pack page states CC0; files via the glTF mirror github.com/trebeljahr/quaternius-showcase (its LICENSES.md) |
| Quaternius Animated Dinosaurs (6) | `assets/creatures/quaternius-dinosaurs/` | CC0 1.0 | same |
| Quaternius Easy Enemy Pack (frog, rat, snake x2, spider, wasp) | `assets/creatures/quaternius-easy-enemies/` | CC0 1.0 | same |
| Quaternius Cyberpunk Kit, enemies + character only (7) | `assets/creatures/quaternius-cyberpunk/` | CC0 1.0 | same |
| Quaternius Animated Mechs (4) | `assets/creatures/quaternius-mechs/` | CC0 1.0 | same |
| Quaternius Ultimate Space Kit, enemies + astronauts + mechs only (12; Draco-decoded to plain glb with gltf-transform) | `assets/creatures/quaternius-space/` | CC0 1.0 | same |
| Quaternius Ultimate Monsters (50: 16 Big humanoids, 17 Blob, 17 Flying) | `assets/creatures/quaternius-monsters/` | CC0 1.0 | pack's own License.txt; downloaded by the owner from the author's Drive link, glTF→glb with gltf-transform |
| Quaternius Cute Animated Monsters (21) | `assets/creatures/quaternius-cute-monsters/` | CC0 1.0 | pack page states CC0 (zip has no license file); same download path |
| Quaternius props for map previews: Nature (46), Medieval Village (27), Modular Dungeon (19), Modular Dungeons ruins (15), Cyberpunk props (29), Space props (28), Ships (5), Crops (12), Platformer props (9) | `assets/props/quaternius-*/` | CC0 1.0 | pack pages state CC0; files via the glTF mirror; Draco-compressed ones decoded to plain glb |
| Quaternius Animated Monster Pack (Bat, Dragon, Skeleton, Slime), Alien Animated (2), Zombie (2) | `assets/creatures/quaternius-animated-monsters/`, `quaternius-alien/`, `quaternius-zombie/` | CC0 1.0 | packs' License.txt (Zombie: pack page states CC0); FBX/.blend converted to glb with Blender 5.2 headless |
| Quaternius Platformer Kit, creatures only (4: Enemy, Character_Gun, Bee, Crab) | `assets/creatures/quaternius-platformer/` | CC0 1.0 | pack page states CC0; glTF mirror |
| Quaternius Cute Animated Fish, selection (Piranha, BlueTang, Swordfish; 6 clips each) | `assets/creatures/quaternius-cute-fish/` | CC0 1.0 | pack page states CC0; glTF mirror |
| KayKit Adventurers enemy variants (Knight, Barbarian, Mage, Rogue, Rogue Hooded; each pruned to one weapon kit with gltf-transform, 76 clips) used as Bandit Village bandits, not as player bodies | `assets/creatures/kaykit-bandits/` | CC0 1.0 | `LICENSE.txt` in the pack; `SOURCE.md` lists the removed nodes |
| Kenney Mini Characters (12 animated chunky people, 32 clips each) used as Bandit Village / Pirate Cove humans | `assets/creatures/kenney-mini-characters/` | CC0 1.0 | kenney.nl/support; glTF copies from github.com/shorepine/kenney |
| KayKit Adventurers (Knight, Barbarian, Mage, Rogue, Rogue Hooded; 76 clips each) used only for their **weapon meshes** (staff, wand) in the class preview; the rigs are not used as player bodies | `assets/characters/kaykit-adventurers/` | CC0 1.0 | `LICENSE.txt` in the pack |
| Quaternius Ultimate Fantasy RTS towers and halls (13: watch towers, temples, town centres, wonders) used as the per-dungeon tower | `assets/props/quaternius-rts/` | CC0 1.0 | pack page states CC0; glTF mirror |
| Quaternius Modular Weapons (12 melee weapons, shields, bow) and RPG items (9) | `assets/weapons/quaternius-medieval/`, `assets/props/quaternius-rpg-items/` | CC0 1.0 | pack pages state CC0; glTF mirror |
| Stat, currency, skill and weapon icons (health, speed, damage, coins, wave, score, kills, diamonds, ammo, reload, one per class skill, one per weapon) | `assets/ui/icons/` | Ours, CC0; drawn by `scripts/make-icons.py` | — |
| Class emblems (one per class, for the in-game class cards) | `assets/ui/classes/` | Ours, CC0; drawn by `scripts/make-icons.py` | — |

Role mapping (KayKit family): Minion = Runner, Warrior = Brute (and Boss at 2.4x, red tint), Mage = Spitter, Rogue = Elite Runner. Kenney family: Zombie = Runner, Skeleton = Elite, S-Ghost = Spitter, Vampire = Brute, Keeper = Boss. Players keep their own avatar (see Classes), so no player-body packs are kept. Browse everything with `scripts/showcase.sh` (`showcase/index.html`: tabs for creatures, classes, weapons, props; animations, hit/death sounds, stats with icons, auto-rendered thumbnails). `scripts/showcase-index.py` regenerates the weapons/props list from the `assets/` folders.

### License notes per source (checked on the source pages)

| Source | License | Commercial | Attribution | Caveat |
| --- | --- | --- | --- | --- |
| Quaternius | CC0 | Yes | No | Official downloads are Google Drive folders that hit the "too many users" quota; the GitHub mirror above carries most packs as glb. Ultimate Monsters and Cute Monsters were downloaded by hand (2026-10-29). FBX-only packs (Animated Monsters, Alien, Zombie) were converted with Blender headless (import FBX or open .blend, export glb; Diffuse BSDF materials must be swapped for Principled or the texture is dropped) |
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


## Attribution (CC-BY packs)

Decision (2026-10-30): CC-BY 4.0 packs are allowed next to CC0 when no CC0 model exists (jungle animals, arctic
animals). Each CC-BY row above must carry the author, the work name, the licence link and the changes we made
(usually "converted to glTF/MeshParts, rescaled"). The same lines are shown on the Credits board in the lobby's
Scoreboard plaza and in the experience description on Roblox, in this form:

> "<Work>" by <Author>, licensed CC-BY 4.0 (https://creativecommons.org/licenses/by/4.0/). Changes: converted and rescaled.

CC0 packs need no credit; we still list them above.

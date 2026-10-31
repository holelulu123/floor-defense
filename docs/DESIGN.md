# Floor Defense — Game Design

Last updated: 2026-10-30

## Overview

Floor Defense is a wave-survival shooter for 1, 2 or 4 players: step on a floor pad in the lobby, pick a class, and defend your Town Hall against escalating waves of creatures using guns, grenades and floor spells. Creatures ignore the players and march on the Town Hall; the players are the towers. Every kill pays coins and score; coins buy gear mid-run, score goes on the Hall of Fame.

Two modes from launch: **Defense** (co-op PvE) and **Siege** (PvP, two squads).

The core fantasy: you and three friends, back to back at the gate, a horde pouring in, and one well-timed freeze spell that turns a lost wave into a win. Bloons TD pacing (short rounds, each one harder), but you are the tower.

## Lobby and floors

The lobby is one shared hub with floor pads. A run starts only when the pad is full.

Layout: distinct zones on a grass field, joined by stone paths from the central spawn plaza. The dungeon arc runs along the far side, one diorama per dungeon in unlock order, and every dungeon has its own three pads (Solo, Duo, Squad) right in front of it, so the pad also picks the dungeon. On the near side sit the Scoreboard plaza (Hall of Fame boards) and the Shop and class-select plaza; three reserved plots are kept free for later features (events, cosmetics, Siege queue). The showcase Lobby tab is the layout reference (`showLobby` in `showcase/index.html`); `src/shared/LobbyLayout.luau` is the same layout in studs at 1.4 studs per metre (grass field radius 588, dungeon ring 231, pad ring 189, spawn plaza radius 42, dioramas 61.6 x 47.6, pads 14 studs apart with a 5 stud radius; Scoreboard and Shop plazas at (-140, 77) and (140, 77), reserved plots at (-161, 168), (161, 168) and (0, 189)). `Lobby.luau` builds it from Parts and generates one pad per dungeon per mode from `LobbyLayout.pads()`; stepping on a pad for a dungeon above your level cancels the countdown and the pad says which level it needs (Studio playtests unlock everything via `Config.UnlockAllInStudio`). The pad passes its dungeon id to `Run.start`, or into the teleport data for a reserved run server. Each diorama stands on its own stone plinth with a step from its spoke, a tower prop about 1.6x the old size, a 160 stud light pillar in the dungeon's accent colour (`LobbyLayout.Accents`) and a 44 stud name sign readable from the plaza; `LobbyMarkers.client` greys the pillar and sign ("LOCKED - reach Level N") for dungeons above the local player's level.

Backdrops: `src/shared/Backdrop.luau` plans Terrain from a seed and `src/server/Backdrop.luau` fills it in a few milliseconds per frame (logging the time, warning past 3 s): around the lobby a grass lip on the field rim (hiding the step down to the horizon ground at y = -4), a row of green hills and a ring of grey snow-capped mountains (centres 650 to 1350 studs out, with gaps), plus low mounds in the field's outskirts away from paths; around each arena a skirt along the floor edge, a near and a far row of themed features (Graveyard slate crags, Farm and Village rolling hills, Swamp mud hills, Sewer concrete cliffs, Frozen snow and glacier peaks, Jungle leafy hills, Pirate sea cliffs in a shallow sea, Factory asphalt and lava crags, Station basalt craters) at least 12 studs beyond the floor edge above floor height, and a few low mounds in the floor corners at least 25 studs from the lane. The previous dungeon's terrain is filled with Air before the next one's is built. Lobby terrain keeps out of the arena's backdrop box (`Backdrop.ArenaBounds`), so clearing an arena never touches it.

| Pad | Players | Countdown once full | Enemy health | Enemy count | Coin payout |
| --- | --- | --- | --- | --- | --- |
| Solo | 1 | 5 s | x1.0 | x1.0 | x1.0 |
| Duo | 2 | 10 s | x1.3 | x1.6 | x1.2 |
| Squad | 4 | 15 s | x1.8 | x2.8 | x1.5 |
| Siege 1v1 | 2 | 10 s | Solo values | Solo values | x1.2 |
| Siege 2v2 | 4 | 15 s | Duo values | Duo values | x1.4 |
| Siege 4v4 | 8 | 20 s | Squad values | Squad values | x1.6 |

How it plays:

1. Players stand on a pad; a floating counter shows 2/4 and the pad glows brighter with each player.
2. When full, a countdown runs. Stepping off cancels it.
3. At zero the group is teleported into a private server for that map. Nobody can join mid-run.
4. When the run ends, everyone returns to the lobby with their coins and score saved.

Squad pays more per player than Solo because the enemy count rises faster than the player count. This keeps the Squad pad the one people want to fill, which keeps the lobby social. The map is picked by vote on the pad during the countdown; ties go to the newest map.

## Core loop

A run is a chain of waves with a short shop break between them. The run ends when the Town Hall's health reaches 0; the wave number reached is the score that matters.

```
Floor pad fills -> Prep phase (30 s, shop open) -> Wave N -> Town Hall standing?
                        ^                                        | yes: wave N+1 (boss every 5th)
                        +----------------------------------------+
                                                                 | no: Town Hall destroyed
                                                                 v
                                                  Run ends: score + coins saved -> back to lobby
```

- **Prep phase (30 s):** shop is open, players repair the Town Hall and reposition. Any player can press Ready to skip the wait once everyone is ready.
- **Wave:** creatures spawn from map-specific gates and path toward the Town Hall. They do not attack players; players can block lanes with their body and get pushed, not hurt. Wave N has roughly `8 + 4N` creatures with health scaled by `1 + 0.12N`, times the party multiplier.
- **Town Hall:** 1,000 health. Each creature that reaches it deals its damage and dies. Players repair it with the Repair tool (slow) or shop items (fast).
- **Boss wave:** every 5th wave swaps the horde for one boss plus a thin escort. Bosses drop a guaranteed rare item.
- **End:** Town Hall at 0 ends the run.

In-run coins are spent in the shop and reset to 0 each run. A separate persistent currency, Diamonds, carries between runs (see Progression). A 10 to 20 minute run keeps sessions short for Roblox's audience while leaving room for the "one more wave" pull.

## Camera

Both first-person and third-person, as a player setting with a hotkey to toggle mid-run. Roblox supports this natively (`CameraMode` / zoom limits), so it costs almost nothing. Third-person is the default on touch devices; first-person is the default on PC. Sniper's active zooms into first-person regardless of setting.

## Classes

Players keep their own Roblox avatar. A class is a health pool, a primary weapon, a melee secondary, a passive and **two skills with cooldowns**: skill 1 is quick (1 to 10 s), skill 2 is a long cooldown (25 to 50 s) and usually a timed buff. Every class is playable; five are free and five are **locked** and bought once with Diamonds, which players earn at the end of each run (see Progression). Skills are server-validated: the server owns the cooldown clock (`Classes.canUse`) and rejects early casts.

| Class | Unlock | Weapon | Passive | Skill 1 (quick) | Skill 2 (long) |
| --- | --- | --- | --- | --- | --- |
| Trooper | Free | Assault rifle | +10% reload | Burst Fire, 6 s: 3-round burst, 2x damage | Ammo Crate, 45 s: team reload + 20% fire rate for 10 s |
| Tank | Free | Flail and shield | Blocks creatures | Flail Sweep, 5 s: knockback in 6 studs | Iron Wall, 30 s: taunt + 80% block for 8 s |
| Scout | Free | Dual pistols | +20% speed | Dash, 4 s: 20 studs through creatures | Mark Target, 25 s: +30% damage taken for 8 s |
| Medic | Free | SMG | Melee repairs the Town Hall 2x | Repair Pulse, 8 s: +150 Town Hall HP | Overcharge, 40 s: Town Hall immune 6 s |
| Engineer | Free | Shotgun and hammer | Melee on a turret repairs it (+25% HP/hit) | Place Turret, 10 s: builds the selected turret (max 3; a 4th replaces the oldest) | Overclock, 30 s: all your turrets fire 2x for 10 s |
| Berserker | 1200 Diamonds | Two-handed axe | Kills heal 5 HP; melee +25% | Cleave, 4 s: hits everything in front | Rage, 30 s: +40% attack and move speed for 10 s |
| Mage | 1200 Diamonds | Staff | Spells cost 25% less; freeze +25% | Arcane Bolt, 2 s: homing bolt, 35 dmg | Frost Nova, 25 s: freeze 15 studs for 3 s |
| Pyro | 1500 Diamonds | Flamethrower | Burning creatures take +15% | Flame Sweep, 7 s: cone, ignites 4 s | Fire Wall, 40 s: wall across the lane for 8 s |
| Sniper | 1500 Diamonds | Bolt rifle | +50% headshot | Piercing Shot, 8 s: through 5 creatures | Overwatch, 35 s: next 5 shots crit (10 s) |
| Demolisher | 2000 Diamonds | Grenade launcher | +2 grenades, 20% wider blasts | Frag Toss, 6 s: 120 dmg in 8 studs | Cluster Bomb, 45 s: 6 bomblets along the lane |

Loadout and health (numbers in `src/shared/Classes.luau` `maxHealth` / `secondary` and `src/shared/Weapons.luau`). Key **1** holds the primary, key **2** the melee secondary, **R** reloads; an empty magazine reloads on its own. Melee and magic weapons have no magazine. The Trooper's "+10% reload speed" divides reload time by 1.1 (`Weapons.reloadTime`).

| Class | HP | Primary | Magazine | Reload | Secondary (melee, 8 studs) |
| --- | --- | --- | --- | --- | --- |
| Trooper | 120 | Assault rifle | 30 | 2.0 s (1.82 s with the passive) | Combat knife, 22 dmg, 2.2/s |
| Tank | 220 | Flail (melee) | none | none | none |
| Scout | 90 | Dual pistols | 24 (2 x 12) | 1.4 s | Karambit, 18 dmg, 2.8/s |
| Medic | 110 | SMG | 40 | 1.8 s | Scalpel, 16 dmg, 2.5/s |
| Engineer | 120 | Shotgun | 6 | 2.6 s | Hammer, 28 dmg, 1.6/s (repairs turrets) |
| Berserker | 170 | Great axe (melee) | none | none | none (the axe is already melee) |
| Mage | 90 | Staff (magic) | none | none | Dagger, 18 dmg, 2.4/s |
| Pyro | 130 | Flamethrower | 100 fuel | 3.0 s | Machete, 26 dmg, 1.9/s |
| Sniper | 85 | Bolt rifle | 5 | 3.0 s | Combat knife, 22 dmg, 2.2/s |
| Demolisher | 120 | Grenade launcher | 6 | 3.2 s | Hatchet, 27 dmg, 1.7/s |

Splash: every melee hit also lands on creatures within 8 studs of the impact (`Weapons.MeleeSplash`; creatures walk the lane 7 to 8 studs apart, so a hit reaches the next one; the Great axe and the Tank's flail reach 10). Every damaging skill hits an area too: Arcane Bolt splashes 9 studs around its target, Piercing Shot 8 studs around each creature it pierces, turret shots 8 studs (`Skills.Turret.Splash`); Cleave, Flail Sweep, Flame Sweep, Fire Wall, Frag Toss and Cluster Bomb were area skills already.

Run HUD (`src/client/Hud.client.luau`): top left, one row each for Wave, Coins, Score and Kills, each a 34 px icon with just the number, then the class line and the Town Hall / party panel. The countdown to the next wave is big near the top centre and turns red for the last 10 seconds. Bottom centre: two skill buttons (204 x 92, large icon) whose cooldown drains as a dark shade with big seconds over the icon, then flashes green when ready. Bottom right: the two weapon slots with weapon icons, the ammo count, and for the Engineer a turret panel (icon, one pip per turret, "1 / 3") above the slots. Reloading fills a bar under the crosshair with the seconds left. The crosshair dot is drawn in viewport space exactly where shots go (screen centre in first person, else the cursor) and replaces the mouse icon while a weapon is out.

Lighting: `Environments.SkyLightDiffuse` / `SkyLightSpecular` (a quarter) keep the sky from tinting models, and each dungeon's ambient light and grade tint sit half way to neutral, so weapons and creatures keep their showcase colours while the sky, fog and clouds carry the mood.

Turrets (Engineer): turret **types and rarities** are bought between runs with Diamonds and never change in a run; turret **levels** are bought in-run with coins. Placed turrets have HP; creatures that bump into them damage them, the Engineer's melee (the Hammer, slot 2) repairs them. Overclock doubles fire rate for 10 s. More classes are easy to add later (the data lives in `src/shared/Classes.luau` and `showcase/catalog.js`).

Players keep their own avatar: a class never changes the player's skin, it only puts the class weapon (and for the Tank a shield) in their hands. The showcase previews every class on the Roblox default character (a procedural R15-style figure in the classic yellow/blue/green) with a toggle to a random Kenney blocky player skin (CC0), so the weapon size and grip can be judged on a default body. Weapon models: Kenney Weapon Pack guns, Quaternius Medieval axe and round shield, the KayKit staff mesh (CC0); the flail is a procedural placeholder until a CC0 flail is found. The skill clips in the preview are Kenney's generic poses (holding-right, holding-both-shoot, attack-melee-right, interact-right, pick-up, emote-yes) re-created as keyframes on the dummy; in Roblox the moves need Roblox animation assets authored in the Animation Editor using these previews as reference.

Class select: when a run starts, the prep countdown before wave 1 opens a panel (right edge) with the classes, their two skills and unlock cost; locked ones show a Buy button (Diamonds). The choice is kept per player. The panel never shows in the lobby, C toggles it only during that first prep, and once wave 1 starts the class is fixed for the run (the server rejects `SelectClass` outside that window).

Implementation contract (code-first, see `src/shared/Skills.luau` for the numbers and `src/server/Skills.luau` for the handlers):

- Remotes: `BuyClass(classId)` and `SelectClass(classId)` are RemoteFunctions validated with `Classes.tryBuy` / `Classes.isOwned`; selecting is only allowed during the prep countdown before wave 1 of the player's run (`Run.canSwitchClass`). `UseSkill(index, aimOrigin, aimDirection)` is a RemoteEvent; the server owns the cooldown clock (`Classes.canUse` with `os.clock()`), applies the effect and answers with `SkillFx` (`{kind="cooldown", index, cooldown}` to the caster, `{kind=<fx>, position, radius, ...}` to everyone for the placeholder visuals). XP and Diamonds for a run come from `Progression.xpForRun` / `Progression.diamondsForRun(dungeonIndex, wave, mode)` at run end, are saved immediately and announced to the player with the `RunResults` RemoteEvent (`{xp, diamonds, level, levelsGained, text}`).
- Weapons: `EquipSlot(slot)` (1 or 2, ignored when the class has no such slot) and `Reload()` are RemoteEvents; `server/Combat.luau` owns the active slot and the primary's magazine, refuses shots while reloading or empty, and uses the active slot's own weapon definition for damage, range and rate. Trooper's Ammo Crate refills every run player's magazine instantly. The Humanoid's MaxHealth comes from the class `maxHealth` when the class is applied.
- Player attributes published by the server for the UI: `Class`, `Diamonds`, `Level`, `XP` (progress toward the next level), `XPToNext`, `InRun` (true while in a run; hides the lobby level tag), `OwnedClasses` (comma list), `Weapon` (active weapon), `WeaponSlot`, `Ammo`, `MagazineSize`, `Reloading`, `ReloadEnd` (server time; magazine attributes are nil for weapons without one), `Turrets`; timed buffs are `<Stat>` + `<Stat>Until` pairs (`DamageMult`, `FireRateMult`, `SpeedMult`, `CritShots`) with `Until` in `Workspace:GetServerTimeNow()` seconds so the client can read them too; read through `Skills.buffValue`.
- Creature attributes written by skills, honoured by the creature mover: `Frozen` (boolean, no movement), `SlowUntil` + `SlowFactor` (speed multiplier while `os.clock() < SlowUntil`). `BurnUntil` + `BurnBy` and `MarkedUntil` are read by `Damage.hit`, the single entry point every weapon, skill and turret uses before `Creatures.damage`.
- Town Hall part attribute `ShieldUntil` (Medic Overcharge): `TownHall.takeDamage` ignores damage while `os.clock() < ShieldUntil`.
- Weapon in hand: `WeaponModels.give` builds each Tool from the weapon's uploaded mesh (`src/shared/WeaponMeshes.luau`: size, grip, muzzle, hold pose and per-shot animation mirror the showcase), falling back to Parts when a mesh is missing. The Tank's flail is always procedural and copies the showcase flail (wooden haft, iron links, spiked ball, held upright) beside a round shield on the left forearm. The Berserker's axe is held one-handed with the double head facing forward; the SMG uses the two-handed pistol pose. The primary is equipped, the secondary waits in the Backpack and `WeaponModels.equip` swaps them (the Roblox hotbar is hidden; slots are ours); the Tool is visual only, firing still goes through `Remotes.Fire`. Guns play a magazine-change animation (`ReloadRifle` / `ReloadPistols`) stretched to the reload time. In first person the arms, hands and held weapon stay visible. The Sniper's bolt rifle has a 4x scope (`Weapons` `scope`): hold the right mouse button for first person, a quarter of the field of view, slower mouse and a scope overlay (`Scope.client.luau`).
- Engineer turrets (`src/server/Turrets.luau`): max 3, a 4th replaces the oldest (`Skills.Turret.placeIndex`), 300 HP, creatures within 4 studs chew 15 HP/s, an Engineer melee hit (Hammer) on an own turret within 8 studs repairs 25% of max, Overclock halves the fire interval for 10 s. They look like the showcase turret (Quaternius Cyberpunk `Turret_Gun`, uploaded as `Prop_TurretGun_Base` and a swivelling `Prop_TurretGun_Top` welded to the aim pivot); the box Parts stay as invisible hitboxes.

## Turrets and class gear (to discuss)

Agreed direction, numbers still open:

- Each class has its own **special weapon**, abilities and stats. The Engineer's ability is **building turrets**.
- Turrets have **levels**: each level is stronger and looks different (bigger barrel, extra armor, glow). Levels are bought **during a run** with in-run coins, like the shop.
- Turrets also have **types** (10 or more) and **rarity tiers** (common, rare, epic, legendary, ...). Type and rarity are bought **between runs** with Diamonds. In a run you can level the turret you brought, but you can never change its rarity.
- The same pattern applies to other classes' signature items (Medic's drone, Pyro's fire wall) and to **weapon spells**: enchantments bought with Diamonds that sit on the weapon between runs (slow on hit, chain lightning, bonus coins).
- Open: turret prices, how many turrets an Engineer can place at once, whether rarity changes stats or only looks plus one perk, and the exact monetization (Diamonds only, Robux shortcuts, or passes). Fairness rules in Monetization still apply: nothing that moves the Hall of Fame can be Robux-only.

## Weapons, grenades and spells

Everything in the run shop is bought with in-run coins and lost at the end of the run, so each run is a fresh build. Prices rise 10% per wave so late purchases stay meaningful.

| Category | Item | Base price (coins) | Effect |
| --- | --- | --- | --- |
| Gun | Heavy shotgun | 400 | Wide spread, two shots, high damage up close |
| Gun | Laser rifle | 650 | Pierces through a line of enemies |
| Gun | Minigun | 900 | Very high fire rate, slows you while firing |
| Gun upgrade | Damage tier +1 | 250 | +15% damage on the held weapon, stacks to 5 |
| Grenade | Frag | 80 | Burst damage in a radius |
| Grenade | Sticky | 120 | Attaches to a target, explodes after 2 s, great on bosses |
| Grenade | Flashbang | 100 | Stuns creatures in a radius for 2 s |
| Floor spell | Ice patch | 150 | Enemies on it move at 50% for 12 s |
| Floor spell | Oil slick | 130 | Enemies slip and fall; ignites if hit by fire |
| Floor spell | Tar pit | 180 | Enemies move at 30% and take 10% more damage |
| Floor spell | Spike trap | 200 | Damage over time to anything crossing it |
| Buff spell | Overcharge | 220 | Team deals +25% damage for 15 s |
| Buff spell | Stone walls | 200 | Town Hall takes 30% less damage for 15 s |
| Utility | Repair kit | 100 | +50 Town Hall health instantly |
| Utility | Ammo pack | 60 | Refill all ammo |

Floor spells are the signature mechanic: placed on the ground, visible to everyone, and they combine. Oil plus a fire grenade becomes a burning floor; ice plus a frag shatters frozen enemies for double damage. Combos make a Squad run feel coordinated and are what players will clip for TikTok.

None of this is sold for Robux. Selling in-run power would break the Hall of Fame, since a paid score is worthless to the people chasing it.

## Enemies and maps

Each map has its own creature family, so the roster stays readable: on the graveyard map everything is undead, on the swamp map everything is a bug. The same five archetypes exist in every family with the skin changed, so one set of AI and balance covers all maps.

| Archetype | Role | First appears | Town Hall damage | Graveyard | Swamp |
| --- | --- | --- | --- | --- | --- |
| Runner | Fast, weak, swarms | Wave 1 | 10 | Zombie / Minion | Caterpillar |
| Brute | Slow, tanky | Wave 3 | 40 | Vampire / Warrior | Mud Hog |
| Spitter | Stops at range and shoots the Town Hall | Wave 5 | 20 per shot | S-Ghost / Mage | Crab |
| Exploder | Rushes and detonates on the Town Hall | Wave 7 | 80 | Bomber | Bomb Bee |
| Shielder | Blocks damage for creatures behind it | Wave 10 | 20 | Guard | Beaver |
| Flyer | Ignores ground paths and floor spells, flies straight in | Wave 12 | 15 | Wraith | Parrot |
| Elite Runner | Runner with an extra ability (frost aura, regen, teleport) | Wave 15 | 10 | Skeleton / Rogue | Fox |
| Healer | Heals nearby creatures; priority target | Wave 18 | 10 | Necromancer | Bunny |
| Boss | Every 5th wave | Wave 5 | 250 | Keeper / Lich | Elephant |

Horde mix once everything is unlocked: Runner 58%, Brute 15%, Spitter 10%, Exploder 6%, Flyer 5%, Shielder 4%, Healer 2% (`Enemies.HordeMix`); shares of locked archetypes go to Runners. Two more families exist as models for future maps: slimes (Sewer) and bandits/orcs (Village), plus static UFOs for the Factory map's Flyers.

Roster rule: every creature is a distinct 3D model, never a recolor of another one. Each dungeon has its own family of 13 to 21 creatures and the waves introduce one new creature per wave in the family's listed order, with bosses on waves 5, 10 and 15; after the list runs out, waves mix everything seen so far. The showcase's Creatures tab is the source of truth for the per-dungeon order (`showcase/catalog.js`), and its Dungeons tab previews each map (260 x 200 m arena, one lane of 450 to 700 m that snakes from the gate to the tower through S-bends and switchbacks and never crosses itself, themed props, a painted sky) with a few creatures walking the lane. The lane is a seeded self-avoiding walk on a coarse grid (`laneCurve`), so every dungeon has its own route and the same route every visit. The Lobby tab shows the zoned hub described under Lobby and floors.

In the game the roster is generated, not retyped: `scripts/gen-roster.py` evaluates `showcase/catalog.js` with node and writes `src/shared/Roster.luau` (per family: id, archetype, debut wave, debut-wave health/damage/coins, speed, scale, model path, flying; per dungeon: theme colours and tower/gate prop names). Rerun it after editing the catalog; `tests/Roster.spec.luau` checks ten families, unique ids, contiguous debut waves, growing stats per archetype, a boss on wave 5 and existing model files.

Wave composition (`Waves.composition(family, wave, mode)`): the pool is every regular creature with `firstWave <= wave`. Each archetype's horde share (`Enemies.HordeMix`) is split between its creatures in the pool, rounded down, and the remainder goes to the newest creature, so the debut creature always shows up on its wave. Boss waves (every 5th, plus any wave a roster boss debuts on when a short roster runs out of regulars) lead with the latest boss that has debuted and add an escort of a quarter of the wave's count from the pool. Spawns are ordered oldest creature first, so the new face arrives last.

Scaling: a creature's roster stats are already its debut-wave stats (health x `1 + 0.2 x (debut - 1)`, damage x `1 + 0.08 x (debut - 1)`, coins x `1 + 0.12 x (debut - 1)`), and on top of that health multiplies by `1 + 0.12 x wave` and the party multiplier (`Waves.stats`), count grows by 4 per wave, and from wave 15 Elite creatures (a Runner with an extra ability: frost aura, regen, teleport) join the mix. Damage and speed are not scaled per wave so a lane keeps its rhythm.

## Dungeons

Each dungeon is a map with its own creature family, one winding lane and one gimmick, and is harder than the last (`difficulty`, x1.35 per dungeon). Dungeons unlock by **player level**, one per level (see Progression); `src/shared/Dungeons.luau` is the source of truth and the showcase's Dungeons tab mirrors it.

| # | Dungeon | Unlock level | Creature family (models in repo) | Lanes | Gimmick |
| --- | --- | --- | --- | --- | --- |
| 1 | Graveyard | 1 | Skeletons / undead | 1 | Fog rolls in on boss waves, cutting sight lines |
| 2 | Haunted Farm | 2 | Possessed farm animals | 1 | Hay bales can be pushed into lanes as cover; animals trample them |
| 3 | Swamp | 3 | Bugs and beasts | 1 | Shallow water slows everyone; ice spells freeze it solid |
| 4 | Sewer | 4 | Slimes | 1 | Slimes split in two when killed above half health |
| 5 | Bandit Village | 5 | Bandits and orcs | 1 | Bandits loot dropped coins before you can |
| 6 | Frozen Cavern | 6 | Arctic beasts | 1 | Everything is slippery; freeze spells last twice as long |
| 7 | Jungle Temple | 7 | Jungle beasts | 1 | Vines block sight lines until burned away |
| 8 | Pirate Cove | 8 | Pirates | 1 | Cannons on the cliffs can be captured and fired at the lanes |
| 9 | Factory | 9 | UFOs / robots | 1 | Conveyor belts move anything on them, including grenades |
| 10 | Space Station | 10 | Aliens and drones | 1 | Airlocks vent a lane for 5 s when opened |

### Lane and arena scale

Every dungeon is one winding lane from a gate on the near edge to the dungeon's tower on the far edge; the tower is the Town Hall. `src/shared/Lane.luau` generates it deterministically from the dungeon id with the showcase's recipe (seeded self-avoiding walk on a coarse grid, cells at least 2.6 lane widths across, Chaikin-rounded corners, rejected if it leaves the arena, comes back within 1.4 lane widths of itself or misses the length band), so server, client and tools agree on the exact route and `tests/Lane.spec.luau` can check it never self-intersects.

Stud scale decision: the showcase arena is 260 x 200 m with a 450 to 700 m lane. At the usual 3.5 studs per metre that is a 2,000+ stud lane that a Runner (14 studs/s) would need 2.5 minutes to walk, so the game uses about 1.4 studs per metre: a **360 x 280 stud arena, a 10 stud wide lane and a route of 600 to 1,000 studs (target 800)**. Creatures jog (archetype speeds in `src/shared/Enemies.luau`, studs per second): Runner 20, Exploder and Elite 24, Flyer 26, Spitter 17, Healer 16, Brute 14, Shielder 13, Boss 9. On an 800 stud lane that is about 40 s for a basic creature, 31 to 33 s for exploders and flyers, 57 to 62 s for heavies and about 89 s for a boss. Creatures are sized against a Roblox character (`ModelFit.creatureHeight`): player height for the basic ones, at most 4x (20 studs) for the biggest bosses. The prep countdown shows big in the middle of the screen and turns red for the last 10 seconds. The arena sits at z = 1500 (z from 1360 to 1640) so it never overlaps the lobby, a grass disc of radius 588 studs at the origin. Creatures walk the lane's points exactly (no PathfindingService); Flyers keep every fifth point at 8 studs height and cut the corners. The tower and gate are the theme's imported props (`Roster.Themes`, ModelIds `Prop_<name>`), sized by `src/shared/ModelFit.luau` to the showcase proportions (theme metres x the showcase map factor x 1.4 studs, footprint capped so the tower fits before the arena edge); the tower keeps an invisible `TownHall` Part sized to it for the Town Hall attributes, tag and raycasts, and both fall back to placeholder slabs when a model is missing. Floor and lane take the theme's ground and path colours. Creatures are server hitboxes (invisible Parts sized to the model, carrying Health and the skill attributes) that `CreatureVisuals.client` dresses with the creature's model from `ReplicatedStorage.CreatureModels` and animates procedurally (`src/shared/CreatureMotion.luau`: walkers bob and sway with the step rhythm, blobs/slimes/skulls/frogs/fish hop, flyers bob and bank, ground bosses stomp; hits flash and swell, deaths tip over, sink and fade in 0.6 s); a creature whose model is missing stays the archetype-coloured block.

One dungeon (Graveyard) is enough for the MVP. Each extra dungeon is a few days of building plus its creature family, and all ten families already have placeholder models in `assets/creatures/`. Props kits per dungeon are listed in the showcase and fetched as each map is built.

## Modes: Defense (PvE) and Siege (PvP)

Both ship at launch. Siege reuses every system from Defense, so it costs the lobby pads, a mirrored map layout and one extra rule.

**Defense (PvE):** 1, 2 or 4 players defend one Town Hall against endless waves. Score = wave reached.

**Siege (PvP):** two squads of equal size, each with its own Town Hall on a mirrored half of the map. Both sides face the same waves. The extra rule: every kill you make sends a creature of the same type to the enemy's side on the next wave, so a strong squad buries the other. Last Town Hall standing wins. No direct player-vs-player shooting, which means:

- No class balance pass for duels; the classes only ever shoot creatures.
- No pay-to-win debate: premium classes change how you kill creatures, not whether you can hurt a player.
- Exploiters have less to gain; the server already owns every hit and every spawn.
- Players can see the enemy squad across a chasm or wall, cheer and taunt, but not cross.

Optional later: a **Raid** rule where a player can spend coins to open the wall for 10 s and run a grenade into the enemy lane. This is the only direct interaction and is off by default until Siege is proven.

Siege ranked ladder: a separate Hall of Fame board by win streak.

## Progression and Hall of Fame

Persistent between runs: Diamonds, XP/Level and Score. Coins do not. (Diamonds were called Gems; `SaveData.migrate` moves an old saved `Gems` balance into `Diamonds` with nothing lost.)

| Currency | Earned by | Spent on | Persists |
| --- | --- | --- | --- |
| Coins | Kills during a run (10 per Runner, up to 500 per boss), times the party multiplier | Run shop: guns, grenades, spells | No, reset each run |
| Diamonds | End of run, from the dungeon and the wave reached (`Progression.diamondsForRun`); later: Siege wins, daily login bonus | Classes (slowly), gear and weapon skins, lobby cosmetics | Yes |
| Score | Sum of coins earned in a run plus a wave bonus of `wave x 100` | Nothing; it is the leaderboard number | Yes, best per mode kept |

Hall of Fame: a wall in the lobby with four boards: Solo, Duo, Squad and Siege. Defense boards list the top 100 scores with player name, class used, wave reached and date; a Squad entry lists all four names so friends chase the board together. The Siege board ranks by longest win streak. Boards reset monthly with each month's top 10 engraved on a permanent "Legends" board, so new players always have a reachable board.

XP and levels (`src/shared/Progression.luau`, multipliers in `src/shared/Dungeons.luau`):

- Level L to L+1 costs `xpToNext(L)`: 100, then x2.0, x2.3, x2.7, x3.0 and x3.0 for every level after (rounded each step): 100, 200, 460, 1,242, 3,726, 11,178, ... 905,418 at level 10. Max level 20. XP is saved as progress toward the next level (`Level`, `XP`).
- A run pays `wave^1.5 x dungeon.xpMultiplier x party` XP (party: Solo 1, Duo 1.25, Squad 1.5), where `wave` is the wave reached. The multiplier grows about x3 per dungeon (1, 1.5, 3.5, 10, 30, 90, 270, 810, 2,430, 7,290) to keep up with the curve: at the level that unlocks a dungeon, about four wave-10 runs there buy the next level.
- Diamonds per run: `wave^1.25 x dungeon.diamondMultiplier x party` (multiplier 1 to 5): 18 for Graveyard wave 10, 89 for Space Station wave 10.
- **Levels unlock dungeons**, one per level (1 to 10; table in Dungeons). Levels also unlock free gear skins and lobby emotes, never power.
- Each dungeon is harder: `Dungeons.difficulty` (Graveyard 1.0, x1.35 per dungeon, 14.89 for the Space Station) multiplies creature health and Town Hall damage in `Waves.stats`.
- UI: a big Diamonds counter sits top right in the lobby and in runs; level and XP show only on the tag just above each player's head in the lobby (hidden during runs, where a bigger HP bar with "120 / 120" takes its place); the run's results line ("+340 XP, +25 Diamonds, Level up! Lv 4") shows top centre.

| # | Dungeon | Unlock level | XP to next level there | XP wave 5 / 10 / 20 (Solo) | Diamonds wave 5 / 10 / 20 | Wave-10 runs per level |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Graveyard | 1 | 100 | 11 / 32 / 89 | 7 / 18 / 42 | 3.1 |
| 2 | Haunted Farm | 2 | 200 | 17 / 47 / 134 | 9 / 22 / 53 | 4.3 |
| 3 | Swamp | 3 | 460 | 39 / 111 / 313 | 11 / 27 / 63 | 4.1 |
| 4 | Sewer | 4 | 1,242 | 112 / 316 / 894 | 13 / 31 / 74 | 3.9 |
| 5 | Bandit Village | 5 | 3,726 | 335 / 949 / 2,683 | 15 / 36 / 85 | 3.9 |
| 6 | Frozen Cavern | 6 | 11,178 | 1,006 / 2,846 / 8,050 | 19 / 44 / 106 | 3.9 |
| 7 | Jungle Temple | 7 | 33,534 | 3,019 / 8,538 / 24,150 | 22 / 53 / 127 | 3.9 |
| 8 | Pirate Cove | 8 | 100,602 | 9,056 / 25,614 / 72,449 | 26 / 62 / 148 | 3.9 |
| 9 | Factory | 9 | 301,806 | 27,168 / 76,843 / 217,346 | 30 / 71 / 169 | 3.9 |
| 10 | Space Station | 10 | 905,418 | 81,505 / 230,530 / 652,037 | 37 / 89 / 211 | 3.9 |

Past level 10 there is no new dungeon, so each level takes about three times as many Space Station runs as the last (a soft cap).

Other persistent progression:

- **Class mastery** per class: waves reached while playing it. Mastery 10 unlocks that class's free gear skin.
- **Daily and weekly challenges** ("freeze 50 enemies", "reach wave 10 on Swamp") paying Diamonds. This is the main reason to come back on a day you weren't going to.
- **Gamble system (to discuss):** a Diamond sink with random rewards (turret types, weapon spells, skins). Constraint: Roblox requires paid random items to disclose odds, and some countries restrict loot boxes for minors, so the safe shape is a Diamonds-only spin with published odds, duplicates converting to Diamonds, and a pity counter. Never Robux directly into a random roll.

Leaderboards use Roblox OrderedDataStores, one per board, keyed by user id, refreshed every 60 s in the lobby.

## Monetization

Sell classes, cosmetics and convenience. Never sell in-run power or score.

| Product | Type | Price (Robux) | What you get |
| --- | --- | --- | --- |
| Premium class | Game pass, one each | 199 | Permanent access to Pyro, Frost Mage, Sniper or Demolisher |
| Class bundle | Game pass | 699 | All five premium classes (30% off) |
| VIP | Game pass | 399 | +25% Diamonds, VIP lobby tag, one extra daily challenge, named color on the Hall of Fame |
| Diamonds 500 / 1,200 / 3,000 | Developer product | 99 / 199 / 449 | Diamonds to spend on skins or classes |
| Gear or weapon skin | Developer product or Diamonds | 49 to 149 | Cosmetic only; layered on the player's own avatar |
| Private server | Server subscription | 99 / month | Play with a chosen group; the Hall of Fame still counts runs there |

Fairness rules, written down so future decisions stay honest:

1. Every premium class can also be bought with Diamonds earned in play, at a price that takes roughly 10 hours.
2. No item sold for Robux changes damage, Town Hall health, coin gain or score. VIP's +25% Diamonds is the single exception, and Diamonds don't affect score.
3. The Hall of Fame shows the class used, so a free class topping it is a visible proof of fairness.

Where the money comes from, in expected order: Premium Payouts from engagement (free, automatic), VIP, the class bundle, then Diamond packs. Roblox takes about 30% of each sale. Developer Exchange pays out earned Robux once you pass the threshold (30,000 Robux as of this plan; confirm the current number on the DevEx page).

The existing code already supports this: `Config.GamePasses` holds pass ids, `Config.Products` holds product ids, and `Monetization.luau` grants products idempotently. Diamonds replace Coins as the persistent field in `PlayerData`.

## 3D assets

See [ASSETS.md](ASSETS.md) for every pack in the repo, its license and the sources considered.

## MVP scope

The first playable is one map, one pad size, two free classes, three enemy archetypes and a four-item shop. Everything else is layered on after a real player has survived ten waves.

| Order | Milestone | What it proves | Code it touches |
| --- | --- | --- | --- |
| 1 | Lobby with a Solo pad that teleports to a private run server | Pads and reserved servers work | `src/server/Lobby.luau`, `TeleportService` |
| 2 | Graveyard map with a Town Hall; Runners path to it and damage it; kill = coins + score | The loop is fun with a stick and zombies | `src/server/WaveManager.luau`, `src/server/TownHall.luau`, `src/shared/Waves.luau` |
| 3 | Gun: server-authoritative hitscan with client-side feel; camera toggle | Shooting feels good and can't be spoofed | `src/server/Combat.luau`, `src/client/Weapon.client.luau`, `src/client/Camera.client.luau` |
| 4 | Prep phase + shop with frag, ice patch, repair kit, damage tier | Buying matters | `src/server/Shop.luau`, `src/shared/Items.luau` |
| 5 | Brute and Spitter archetypes, boss on wave 5 | Difficulty curve holds | `src/shared/Enemies.luau` |
| 6 | Class select in the lobby; Trooper and Brute classes with passives, actives and gear overlays | Classes are distinct while players keep their avatar | `src/shared/Classes.luau`, `src/server/Loadout.luau` |
| 7 | Hall of Fame board in the lobby via OrderedDataStore | Score persists and shows | `src/server/Leaderboard.luau` |
| 8 | Duo and Squad pads with multipliers | Co-op works | `Lobby.luau`, `WaveManager.luau` |
| 9 | Siege 1v1: mirrored map, kill-sends-creature rule, win condition | PvP works on the same systems | `src/server/Siege.luau`, `WaveManager.luau` |
| 10 | VIP pass + Diamond products wired through `Monetization.luau` | Money flows | `Config.luau`, `Monetization.luau` |
| 11 | Remaining free classes, Swamp map, challenges, Siege 2v2/4v4 | Enough content to retain | content files |

The existing `PlayerData` and `Monetization` modules stay as they are. `Config.DefaultData` gains `Diamonds`, `XP`, `BestScoreSolo`, `BestScoreDuo`, `BestScoreSquad`, `SiegeStreak`, `Level`, `OwnedClasses` and `Mastery`.

Server-authoritative rules that apply from milestone 3 on:

- The client sends "I fired in this direction"; the server raycasts, applies damage and awards coins. The client never reports a hit.
- Shop purchases are validated against the server's coin balance and the wave's price multiplier.
- Spell placement is clamped to a radius around the player and rate-limited per cooldown.
- Town Hall damage and score are computed on the server from events the server itself generated.

## Decisions made

- Both PvE (Defense) and PvP (Siege) at launch; Siege is indirect, no player-vs-player shooting until Raid is proven.
- Both cameras, player toggle.
- Creatures attack the Town Hall, never the players.
- Name stays Floor Defense.

## Open questions

- [ ] Endless waves or a fixed 30-wave run with a win screen? (Affects what "survived" means for XP and Diamonds.) Endless is simpler and feeds the Hall of Fame; fixed gives a "beat the map" moment.
- [ ] Art style: blocky Roblox-native or stylized low-poly (Quaternius/Synty)? Blocky is faster to build alone; low-poly looks better in thumbnails.
- [ ] Do premium classes launch with the MVP or after the free five are proven fun?
- [ ] Should Siege use the Defense difficulty tables as-is, or a gentler curve since the kill-send rule adds pressure?

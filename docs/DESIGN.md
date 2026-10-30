# Floor Defense — Game Design

Last updated: 2026-10-30

## Overview

Floor Defense is a wave-survival shooter for 1, 2 or 4 players: step on a floor pad in the lobby, pick a class, and defend your Town Hall against escalating waves of creatures using guns, grenades and floor spells. Creatures ignore the players and march on the Town Hall; the players are the towers. Every kill pays coins and score; coins buy gear mid-run, score goes on the Hall of Fame.

Two modes from launch: **Defense** (co-op PvE) and **Siege** (PvP, two squads).

The core fantasy: you and three friends, back to back at the gate, a horde pouring in, and one well-timed freeze spell that turns a lost wave into a win. Bloons TD pacing (short rounds, each one harder), but you are the tower.

## Lobby and floors

The lobby is one shared hub with floor pads. A run starts only when the pad is full.

Layout: distinct zones on a grass field, joined by stone paths from the central spawn plaza. The dungeon arc runs along the far side, one diorama per dungeon in unlock order, and every dungeon has its own three pads (Solo, Duo, Squad) right in front of it, so the pad also picks the dungeon. On the near side sit the Scoreboard plaza (Hall of Fame boards) and the Shop and class-select plaza; three reserved plots are kept free for later features (events, cosmetics, Siege queue). The showcase Lobby tab is the layout reference (`showLobby` in `showcase/index.html`).

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

In-run coins are spent in the shop and reset to 0 each run. A separate persistent currency, Gems, carries between runs (see Progression). A 10 to 20 minute run keeps sessions short for Roblox's audience while leaving room for the "one more wave" pull.

## Camera

Both first-person and third-person, as a player setting with a hotkey to toggle mid-run. Roblox supports this natively (`CameraMode` / zoom limits), so it costs almost nothing. Third-person is the default on touch devices; first-person is the default on PC. Sniper's active zooms into first-person regardless of setting.

## Classes

Players keep their own Roblox avatar. A class is a weapon, a passive and **two skills with cooldowns**: skill 1 is quick (1 to 10 s), skill 2 is a long cooldown (25 to 50 s) and usually a timed buff. Every class is playable; five are free and six are **locked** and bought once with gems, which players earn at the end of each run (see Progression). Skills are server-validated: the server owns the cooldown clock (`Classes.canUse`) and rejects early casts.

| Class | Unlock | Weapon | Passive | Skill 1 (quick) | Skill 2 (long) |
| --- | --- | --- | --- | --- | --- |
| Trooper | Free | Assault rifle | +10% reload | Burst Fire, 6 s: 3-round burst, 2x damage | Ammo Crate, 45 s: team reload + 20% fire rate for 10 s |
| Tank | Free | Flail and shield | Blocks creatures; +50% HP | Flail Sweep, 5 s: knockback in 6 studs | Iron Wall, 30 s: taunt + 80% block for 8 s |
| Scout | Free | Dual pistols | +20% speed | Dash, 4 s: 20 studs through creatures | Mark Target, 25 s: +30% damage taken for 8 s |
| Medic | Free | SMG | Melee repairs the Town Hall 2x | Repair Pulse, 8 s: +150 Town Hall HP | Overcharge, 40 s: Town Hall immune 6 s |
| Engineer | Free | Carbine and wrench | Melee on a turret repairs it (+25% HP/hit) | Place Turret, 10 s: builds the selected turret (max 3; a 4th replaces the oldest) | Overclock, 30 s: all your turrets fire 2x for 10 s |
| Berserker | 1200 gems | Two-handed axe | Kills heal 5 HP; melee +25% | Cleave, 4 s: hits everything in front | Rage, 30 s: +40% attack and move speed for 10 s |
| Mage | 1200 gems | Staff | Spells cost 25% less; freeze +25% | Arcane Bolt, 2 s: homing bolt, 35 dmg | Frost Nova, 25 s: freeze 15 studs for 3 s |
| Pyro | 1500 gems | Flamethrower | Burning creatures take +15% | Flame Sweep, 7 s: cone, ignites 4 s | Fire Wall, 40 s: wall across the lane for 8 s |
| Sniper | 1500 gems | Bolt rifle | +50% headshot | Piercing Shot, 8 s: through 5 creatures | Overwatch, 35 s: next 5 shots crit (10 s) |
| Demolisher | 2000 gems | Grenade launcher | +2 grenades, 20% wider blasts | Frag Toss, 6 s: 120 dmg in 8 studs | Cluster Bomb, 45 s: 6 bomblets along the lane |
| Summoner | 2500 gems | Wand and spellbook | Starts with an attacking pet | Pet Pounce, 5 s: pet leaps for 60 dmg | Enrage, 45 s: pet 2x size and damage for 8 s |

Turrets (Engineer): turret **types and rarities** are bought between runs with gems and never change in a run; turret **levels** are bought in-run with coins. Placed turrets have HP; creatures that bump into them damage them, the Engineer's melee repairs them. Overclock doubles fire rate for 10 s. More classes are easy to add later (the data lives in `src/shared/Classes.luau` and `showcase/catalog.js`).

Players keep their own avatar: a class never changes the player's skin, it only puts the class weapon (and for the Tank a shield) in their hands. The showcase previews every class on the Roblox default character (a procedural R15-style figure in the classic yellow/blue/green) with a toggle to a random Kenney blocky player skin (CC0), so the weapon size and grip can be judged on a default body. Weapon models: Kenney Weapon Pack guns, Quaternius Medieval axe and round shield, the KayKit staff and wand meshes (CC0); the flail is a procedural placeholder until a CC0 flail is found. The skill clips in the preview are Kenney's generic poses (holding-right, holding-both-shoot, attack-melee-right, interact-right, pick-up, emote-yes) re-created as keyframes on the dummy; in Roblox the moves need Roblox animation assets authored in the Animation Editor using these previews as reference.

Class select: on entering the lobby a panel shows the classes with their two skills and unlock cost; locked ones show a Buy button (gems). The choice is kept per player and can be changed in the lobby at any time.

Implementation contract (code-first, see `src/shared/Skills.luau` for the numbers and `src/server/Skills.luau` for the handlers):

- Remotes: `BuyClass(classId)` and `SelectClass(classId)` are RemoteFunctions validated with `Classes.tryBuy` / `Classes.isOwned`; selecting is only allowed in the lobby or during prep. `UseSkill(index, aimOrigin, aimDirection)` is a RemoteEvent; the server owns the cooldown clock (`Classes.canUse` with `os.clock()`), applies the effect and answers with `SkillFx` (`{kind="cooldown", index, cooldown}` to the caster, `{kind=<fx>, position, radius, ...}` to everyone for the placeholder visuals). Gems for a run come from `Classes.gemsForRun(wave, mode)` at run end.
- Player attributes published by the server for the UI: `Class`, `Gems`, `OwnedClasses` (comma list), `Weapon`, `Turrets`; timed buffs are `<Stat>` + `<Stat>Until` pairs (`DamageMult`, `FireRateMult`, `SpeedMult`, `CritShots`), read through `Skills.buffValue`.
- Creature attributes written by skills, honoured by the creature mover: `Frozen` (boolean, no movement), `SlowUntil` + `SlowFactor` (speed multiplier while `os.clock() < SlowUntil`). `BurnUntil` + `BurnBy` and `MarkedUntil` are read by `Damage.hit`, the single entry point every weapon, skill, turret and pet uses before `Creatures.damage`.
- Town Hall part attribute `ShieldUntil` (Medic Overcharge): `TownHall.takeDamage` ignores damage while `os.clock() < ShieldUntil`.
- Weapon in hand: `WeaponModels.give` builds a placeholder Tool from Parts per weapon (rifle, carbine, SMG, bolt rifle, flamethrower, launcher, two pistols, axe, staff, wand, flail with a left-arm shield) and equips it; the Tool is visual only, firing still goes through `Remotes.Fire`.
- Engineer turrets (`src/server/Turrets.luau`): max 3, a 4th replaces the oldest (`Skills.Turret.placeIndex`), 300 HP, creatures within 4 studs chew 15 HP/s, an Engineer shot at an own turret within 8 studs repairs 25% of max, Overclock halves the fire interval for 10 s.

## Turrets and class gear (to discuss)

Agreed direction, numbers still open:

- Each class has its own **special weapon**, abilities and stats. The Engineer's ability is **building turrets**.
- Turrets have **levels**: each level is stronger and looks different (bigger barrel, extra armor, glow). Levels are bought **during a run** with in-run coins, like the shop.
- Turrets also have **types** (10 or more) and **rarity tiers** (common, rare, epic, legendary, ...). Type and rarity are bought **between runs** with Gems. In a run you can level the turret you brought, but you can never change its rarity.
- The same pattern applies to other classes' signature items (Medic's drone, Summoner's pet, Pyro's fire wall) and to **weapon spells**: enchantments bought with Gems that sit on the weapon between runs (slow on hit, chain lightning, bonus coins).
- Open: turret prices, how many turrets an Engineer can place at once, whether rarity changes stats or only looks plus one perk, and the exact monetization (Gems only, Robux shortcuts, or passes). Fairness rules in Monetization still apply: nothing that moves the Hall of Fame can be Robux-only.

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

Each dungeon is a map with its own creature family, one winding lane and one gimmick. Dungeons unlock by **player level** (see Progression); `src/shared/Dungeons.luau` is the source of truth and the showcase's Dungeons tab mirrors it.

| # | Dungeon | Unlock level | Creature family (models in repo) | Lanes | Gimmick |
| --- | --- | --- | --- | --- | --- |
| 1 | Graveyard | 1 | Skeletons / undead | 1 | Fog rolls in on boss waves, cutting sight lines |
| 2 | Haunted Farm | 3 | Possessed farm animals | 1 | Hay bales can be pushed into lanes as cover; animals trample them |
| 3 | Swamp | 5 | Bugs and beasts | 1 | Shallow water slows everyone; ice spells freeze it solid |
| 4 | Sewer | 10 | Slimes | 1 | Slimes split in two when killed above half health |
| 5 | Bandit Village | 15 | Bandits and orcs | 1 | Bandits loot dropped coins before you can |
| 6 | Frozen Cavern | 20 | Arctic beasts | 1 | Everything is slippery; freeze spells last twice as long |
| 7 | Jungle Temple | 25 | Jungle beasts | 1 | Vines block sight lines until burned away |
| 8 | Pirate Cove | 30 | Pirates | 1 | Cannons on the cliffs can be captured and fired at the lanes |
| 9 | Factory | 35 | UFOs / robots | 1 | Conveyor belts move anything on them, including grenades |
| 10 | Space Station | 40 | Aliens and drones | 1 | Airlocks vent a lane for 5 s when opened |

### Lane and arena scale

Every dungeon is one winding lane from a gate on the near edge to the dungeon's tower on the far edge; the tower is the Town Hall. `src/shared/Lane.luau` generates it deterministically from the dungeon id with the showcase's recipe (seeded self-avoiding walk on a coarse grid, cells at least 2.6 lane widths across, Chaikin-rounded corners, rejected if it leaves the arena, comes back within 1.4 lane widths of itself or misses the length band), so server, client and tools agree on the exact route and `tests/Lane.spec.luau` can check it never self-intersects.

Stud scale decision: the showcase arena is 260 x 200 m with a 450 to 700 m lane. At the usual 3.5 studs per metre that is a 2,000+ stud lane that a Runner (14 studs/s) would need 2.5 minutes to walk, so the game uses about 1.4 studs per metre: a **360 x 280 stud arena, a 10 stud wide lane and a route of 600 to 1,000 studs (target 800)**. A Runner crosses it in about a minute, a Brute in two, which keeps a wave at one to two minutes. The arena sits at z = 600 so it never overlaps the 120 x 120 lobby at the origin. Creatures walk the lane's points exactly (no PathfindingService); Flyers keep every fifth point at 8 studs height and cut the corners. The tower and gate are placeholder Parts named after the theme prop (`Roster.Themes`) until the meshes are imported; floor and lane take the theme's ground and path colours.

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

Two things persist between runs: Gems and Score. Coins do not.

| Currency | Earned by | Spent on | Persists |
| --- | --- | --- | --- |
| Coins | Kills during a run (10 per Runner, up to 500 per boss), times the party multiplier | Run shop: guns, grenades, spells | No, reset each run |
| Gems | 1 per wave cleared, 25 per boss, 10 per Siege win, daily login bonus | Classes (slowly), gear and weapon skins, lobby cosmetics | Yes |
| Score | Sum of coins earned in a run plus a wave bonus of `wave x 100` | Nothing; it is the leaderboard number | Yes, best per mode kept |

Hall of Fame: a wall in the lobby with four boards: Solo, Duo, Squad and Siege. Defense boards list the top 100 scores with player name, class used, wave reached and date; a Squad entry lists all four names so friends chase the board together. The Siege board ranks by longest win streak. Boards reset monthly with each month's top 10 engraved on a permanent "Legends" board, so new players always have a reachable board.

XP and levels (`src/shared/Progression.luau`):

- A run pays `wave x 25 + kills` XP, plus 100 if the Town Hall is still standing when the run ends.
- Level N to N+1 costs `100 x N^1.5` XP (100, 282, 519, 800, ... 2,700 at level 9, 8,900 at level 20), so each level takes longer than the last. Max level 60.
- **Levels unlock dungeons** (table in Dungeons). Levels also unlock free gear skins and lobby emotes, never power.
- Gems per run: `waves + 25 per boss`, plus 20 if the Town Hall survived (endless mode ends by wipe, so "survived" means ending the run voluntarily between waves with the Town Hall alive; still to confirm).

Other persistent progression:

- **Class mastery** per class: waves reached while playing it. Mastery 10 unlocks that class's free gear skin.
- **Daily and weekly challenges** ("freeze 50 enemies", "reach wave 10 on Swamp") paying Gems. This is the main reason to come back on a day you weren't going to.
- **Gamble system (to discuss):** a Gem sink with random rewards (turret types, weapon spells, skins). Constraint: Roblox requires paid random items to disclose odds, and some countries restrict loot boxes for minors, so the safe shape is a Gems-only spin with published odds, duplicates converting to Gems, and a pity counter. Never Robux directly into a random roll.

Leaderboards use Roblox OrderedDataStores, one per board, keyed by user id, refreshed every 60 s in the lobby.

## Monetization

Sell classes, cosmetics and convenience. Never sell in-run power or score.

| Product | Type | Price (Robux) | What you get |
| --- | --- | --- | --- |
| Premium class | Game pass, one each | 199 | Permanent access to Pyro, Frost Mage, Sniper, Demolisher or Summoner |
| Class bundle | Game pass | 699 | All five premium classes (30% off) |
| VIP | Game pass | 399 | +25% Gems, VIP lobby tag, one extra daily challenge, named color on the Hall of Fame |
| Gems 500 / 1,200 / 3,000 | Developer product | 99 / 199 / 449 | Gems to spend on skins or classes |
| Gear or weapon skin | Developer product or Gems | 49 to 149 | Cosmetic only; layered on the player's own avatar |
| Private server | Server subscription | 99 / month | Play with a chosen group; the Hall of Fame still counts runs there |

Fairness rules, written down so future decisions stay honest:

1. Every premium class can also be bought with Gems earned in play, at a price that takes roughly 10 hours.
2. No item sold for Robux changes damage, Town Hall health, coin gain or score. VIP's +25% Gems is the single exception, and Gems don't affect score.
3. The Hall of Fame shows the class used, so a free class topping it is a visible proof of fairness.

Where the money comes from, in expected order: Premium Payouts from engagement (free, automatic), VIP, the class bundle, then Gem packs. Roblox takes about 30% of each sale. Developer Exchange pays out earned Robux once you pass the threshold (30,000 Robux as of this plan; confirm the current number on the DevEx page).

The existing code already supports this: `Config.GamePasses` holds pass ids, `Config.Products` holds product ids, and `Monetization.luau` grants products idempotently. Gems replace Coins as the persistent field in `PlayerData`.

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
| 10 | VIP pass + Gem products wired through `Monetization.luau` | Money flows | `Config.luau`, `Monetization.luau` |
| 11 | Remaining free classes, Swamp map, challenges, Siege 2v2/4v4 | Enough content to retain | content files |

The existing `PlayerData` and `Monetization` modules stay as they are. `Config.DefaultData` gains `Gems`, `BestScoreSolo`, `BestScoreDuo`, `BestScoreSquad`, `SiegeStreak`, `Level`, `OwnedClasses` and `Mastery`.

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

- [ ] Endless waves or a fixed 30-wave run with a win screen? (Affects what "survived" means for XP and Gems.) Endless is simpler and feeds the Hall of Fame; fixed gives a "beat the map" moment.
- [ ] Art style: blocky Roblox-native or stylized low-poly (Quaternius/Synty)? Blocky is faster to build alone; low-poly looks better in thumbnails.
- [ ] Do premium classes launch with the MVP or after the free five are proven fun?
- [ ] Should Siege use the Defense difficulty tables as-is, or a gentler curve since the kill-send rule adds pressure?

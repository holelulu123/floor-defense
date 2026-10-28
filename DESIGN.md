# Floor Defense — Game Design

Last updated: 2026-10-28

## Overview

Floor Defense is a wave-survival shooter for 1, 2 or 4 players: step on a floor pad in the lobby, pick a class, and defend your Town Hall against escalating waves of creatures using guns, grenades and floor spells. Creatures ignore the players and march on the Town Hall; the players are the towers. Every kill pays coins and score; coins buy gear mid-run, score goes on the Hall of Fame.

Two modes from launch: **Defense** (co-op PvE) and **Siege** (PvP, two squads).

The core fantasy: you and three friends, back to back at the gate, a horde pouring in, and one well-timed freeze spell that turns a lost wave into a win. Bloons TD pacing (short rounds, each one harder), but you are the tower.

## Lobby and floors

The lobby is one shared hub with floor pads. A run starts only when the pad is full.

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

Players keep their own Roblox avatar. On entering the lobby (and again on any pad before the countdown ends) they pick a **class**: a starting weapon, one passive and one active ability on a cooldown. Ten classes, five free and five premium. The balance rule: a premium class is never stronger than a free one, only different. A player who masters the free five should be able to top the Hall of Fame.

| Class | Tier | Role | Starting weapon | Passive | Active (cooldown) |
| --- | --- | --- | --- | --- | --- |
| Trooper | Free | All-rounder | Assault rifle | +10% reload speed | Ammo crate for the team (60 s) |
| Brute | Free | Blocker | Shotgun | Creatures cannot push past you | Taunt: nearby creatures chase you instead of the Town Hall for 5 s (45 s) |
| Scout | Free | Mobility | Dual pistols | +20% move speed | Dash through enemies (20 s) |
| Medic | Free | Support | SMG | Repairs the Town Hall 2x faster | Repair pulse: +150 Town Hall health (40 s) |
| Engineer | Free | Area control | Carbine | Spells cost 15% less | Drop a barricade that blocks a lane for 10 s (50 s) |
| Pyro | Premium | Area damage | Flamethrower | Burning enemies take +15% damage | Fire wall across a lane (45 s) |
| Frost Mage | Premium | Crowd control | Ice wand | Freeze spells last 25% longer | Blizzard: slows everything on screen (60 s) |
| Sniper | Premium | Boss killer | Bolt rifle | +50% headshot damage | Mark a target: team deals +30% to it (40 s) |
| Demolisher | Premium | Burst | Grenade launcher | Carries +2 grenades | Cluster bomb (50 s) |
| Summoner | Premium | Pet | Staff | Starts with a pet that attacks | Pet enrages, double damage for 8 s (45 s) |

How a class shows on an avatar: the class adds a small **gear overlay** on top of whatever the player is wearing, applied server-side with `HumanoidDescription` accessories: Brute gets heavy pauldrons, Medic a visible pack, Scout a hood, Engineer a tool belt, plus the weapon model in hand. Bodies, faces and Marketplace items stay untouched. This is what the top Roblox games do (BedWars kits, Rivals/TDS skins on gear, never on the body).

Class select UI: a panel on lobby entry with the ten classes, role, weapon, passive and active, premium ones marked with a price. The last-used class is remembered in `PlayerData`. Changing class is free and instant in the lobby; locked once a run starts.

Premium classes are bought once with Robux, or slowly with Gems earned in game. Skins are **gear and weapon skins** (gold pauldrons, flaming pack, camo rifle): free ones unlocked by milestones (reach wave 20 as Brute), paid ones with Gems or Robux. Later, selling our own accessories as Roblox UGC items is a second revenue line.

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

Scaling: health multiplies by `1 + 0.12 x wave`, count grows by 4 per wave, and from wave 15 some Runners spawn as elites with an extra ability (frost aura, regen, teleport). Elites keep late waves interesting without only raising numbers.

Maps at launch:

| Map | Theme | Lanes | Gimmick |
| --- | --- | --- | --- |
| Graveyard | Undead, night | 3 | Fog rolls in on boss waves, cutting sight lines |
| Swamp | Bugs, water | 2 | Shallow water slows players and creatures; ice spells freeze it solid |
| Factory | Robots, indoors | 4 | Conveyor belts move anything on them, including grenades |

One map (Graveyard) is enough for launch. Each extra map is a few days of building plus one creature family of five skins.

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

Other persistent progression:

- **Player level** from total score, shown next to the name. Levels unlock free skins and lobby emotes, never power.
- **Class mastery** per class: waves reached while playing it. Mastery 10 unlocks that class's free gear skin.
- **Daily and weekly challenges** ("freeze 50 enemies", "reach wave 10 on Swamp") paying Gems. This is the main reason to come back on a day you weren't going to.

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

- [ ] Endless waves or a fixed 30-wave run with a win screen? Endless is simpler and feeds the Hall of Fame; fixed gives a "beat the map" moment.
- [ ] Art style: blocky Roblox-native or stylized low-poly (Quaternius/Synty)? Blocky is faster to build alone; low-poly looks better in thumbnails.
- [ ] Do premium classes launch with the MVP or after the free five are proven fun?
- [ ] Should Siege use the Defense difficulty tables as-is, or a gentler curve since the kill-send rule adds pressure?

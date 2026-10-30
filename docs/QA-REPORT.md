# Showcase QA report

Date: 2026-10-30

## Environment

- Product: `showcase/index.html` + `showcase/catalog.js` (three.js viewer), served from the repo root on `127.0.0.1:8802`.
- The files were being edited by other engineers during the pass. Each run records the md5 of the file it tested:
  - creature walk: index `5da33335`, catalog `c7604dfe`
  - maps (first run): between `5da33335` and `b23d4772`; maps re-run: index `b1275a38`, catalog `c8812ad6`
  - classes: index `b23d4772` (default view), `6645e79a` (front), `b1275a38` (side and final front), catalog `c7604dfe` / `c8812ad6`
  - last file state seen: index `22963bfb`, catalog `c8812ad6`
- Browser for the functional audits: Firefox 159.0 headless, software WebGL (`webgl.force-enabled`, `gfx.webrender.software`), private profile copy (`scratchpad/qa/ffp`; the shared `ffp` profile was only touched by two aborted first loads whose output is not used here). Classes were checked with both the default Roblox dummy and `&rig=kenney`.
- Browser for full-page UI screenshots: Chromium headless (`--use-angle=swiftshader`) at 1400x900, 1000x700 and 1920x1080. Reason: in Firefox 159 `--screenshot` fires on the load event, which the module's top-level await does not hold, so `--screenshot` + `&snapshot=N` always captures the empty page before the list renders (see defect 13).
- Static checks: node 22 importing `catalog.js` directly; python3 for log parsing and contact sheets.
- Evidence root: `/tmp/claude-1000/-home-holelulu-projects-roblox-experience/c51ff247-d054-43b0-be83-348ace8ea36e/scratchpad/qa/` (referred to as `qa/` below).

## Defects

1. **Blocker · Classes tab · clicking a class card never opens the class viewer.**
   Repro: open `index.html#classes` (the first card auto-clicks), or click any class card.
   Observed: a plain Kenney character appears with no weapon, framed so close that only the head and torso fit; the HUD shows "Trooper" without the weapon name; the Stats table has only Tier and Role (no skills, passive, weapon); the Skill buttons read "Skill 1 / Skill 2" instead of the skill names; the Player selector says "Roblox default character (R15)" while a Kenney rig is shown; an error banner reads `unhandled: Cannot convert undefined or null to object` (from `Object.entries(def.sounds)` in `showAnimated`, classes have no `sounds`).
   Expected: `showClass` runs, weapon in hand, turret/pet, labelled skills.
   Cause: `showcase/index.html:1205` card `onclick` tests `cfg.animated ? showAnimated(item) : cfg.isClass ? showClass(item)`, and the `classes` tab config is `{ animated: true, isClass: true }`, so `isClass` is unreachable. Thumbnails take the same branch (defect 11). The `?cls=1` hook calls `showClass` directly, which is why the automated class shots look different from what a user sees.
   Evidence: `qa/ui/classes_1400.png`, `qa/ui/classes_1000.png`. Still present at index md5 `22963bfb` (line 1205).

2. **Major · Classes · every weapon is far too small on the Roblox dummy.**
   Repro: `?log=1&cls=1&shots=1` (and `&view=front`, `&view=side`).
   Observed: on all 11 classes the held model is a fist-sized stub. Guns (Trooper, Scout, Medic, Engineer, Pyro, Sniper, Demolisher) are about 0.3 of the hand width instead of 0.24..0.7 of the character height; the Berserker axe is a thin line beside the arm; the Summoner wand is a dot. The Tank's round shield lies horizontally at hip level in idle (only in Iron Wall does it stand up), and the flail hangs down beside the arm instead of pointing forward. The Mage staff hangs tip-down from the hand in idle and only looks right during Frost Nova.
   Expected: weapon length as configured in `CLASSES[].hold[].len`, pointing forward (gun grip along the arm, melee forward and up).
   Same result on the Kenney skin (`&rig=kenney`, index `22963bfb`): guns are stubs at the fist, the Tank shield is a horizontal disc at the hip in idle, the Mage staff hangs tip-down, the Berserker axe is a thin line.
   Evidence: `qa/cls_default_sheet.jpg`, `qa/cls_front_sheet.jpg`, `qa/cls_side_sheet.jpg`, `qa/cls_final_sheet.jpg` (re-run at the end of the pass, index `b1275a38`: unchanged), `qa/cls_kenney_sheet.jpg`. Log lines `class <id>: rig roblox-dummy size 4.00x5.25x2.60 ... weapons 1` in `qa/cls_front.log`.

3. **Major · Dungeons · the "winding" lane is a straight ribbon in all ten maps.**
   Repro: `?log=1&map=all&shots=1`, or open the Dungeons tab.
   Observed: every map draws one straight lane from the gate to the tower; the stats row says "116 m winding route" and the log reports `lane 116 m` for all ten maps (identical length is only possible for a straight segment of `towerZ - 6 - gateZ`). Re-run after the lane code changed (`laneCurve(... bends: [6, 9])`, index `b1275a38`): still straight, still 116 m everywhere.
   Expected: per-dungeon bends as described in the code comment and the HUD text.
   Evidence: `qa/maps_sheet.jpg`, `qa/maps2_sheet.jpg`, `qa/maps2/map__Frozen.jpg`, `qa/ui/dungeons_1400.png`; log `qa/maps2.log`.

4. **Major · UI · layout does not adapt below about 1300 px: the 3D view collapses.**
   Repro: window 1000x700, any tab.
   Observed: the grid is fixed `340px 1fr 440px`, so the viewport gets ~220 px; the model is cropped to a slice (Zombie head only, Trooper torso only, a strip of the Graveyard map). The only breakpoint is 900 px.
   Expected: side panels shrink or collapse before the view does; the right panel could drop to ~300 px.
   Evidence: `qa/ui/creatures_1000.png`, `qa/ui/classes_1000.png`, `qa/ui/dungeons_1000.png`.

5. **Major · Creatures · three models are not standing on the pad / not framed.**
   Repro: `?log=1&walk=1&shots=1&only=<id>`.
   - `Bone Walker` (graveyard, `quaternius-animated-monsters/Skeleton.glb`): floats about 1.3 m above the pad and off centre. Log: `box y 1.27..6.36`.
   - `Longneck` (jungle, `Apatosaurus.glb`): framed as a tiny silhouette far from the camera (bind-pose box 8x17x75 m defeats the pixel fit). Log: `size 8.4x17.5x74.6`, `cover 0.0%`.
   - `Farmhand Zombie` (farm, `quaternius-zombie/Zombie.glb`): floated with feet above the pad (`box y -4.51`). The entry was removed from `catalog.js` during the pass (`c8812ad6`), so this is resolved if the removal is intended.
   Evidence: `qa/suspects_sheet.jpg`, `qa/walkshots/graveyard__Bone Walker.jpg`, `qa/walkshots/jungle__Longneck.jpg`, `qa/walk.log`.

6. **Minor · Creatures · 21 catalog clips do not exist in their model.**
   Repro: `?log=1&walk=1`; lines ending in `MISSING`.
   - All 18 Kenney Blocky characters (Bandit Village: Footpad, Cutpurse, Crossbowman, Powder Thief, Shield Thug, Quack, Bruiser, Bandit King, Lieutenant; Pirate Cove: Deckhand, Swabbie, Gunner, Powder Monkey, Boatswain, Surgeon, First Mate, Lookout, Quartermaster): `hit=jump` is not in the pack (27 clips, no `jump`), so "Take a hit" shows `missing clip "jump", showing idle`.
   - `Scarecrow Tree` (farm): `death=Death` missing (Tree.glb has 9 clips).
   - `Swamp Snake` and `Viper` (swamp): `death=Snake_Death` missing (4 clips). "Kill" leaves them standing.
   Evidence: `qa/walk.log` (grep `MISSING`).

7. **Minor · Catalog · wave ladder: Pirate Cove's third boss is on wave 14, and eight families have no wave-15 boss.**
   Repro: `node qa/catalog_check.mjs` (imports `catalog.js`).
   Observed: Pirate Cove has 14 creatures and 3 bosses; the ordering loop runs out of regulars and puts `Sea Dragon` on wave 14. Graveyard, Farm, Swamp, Sewer, Village, Frozen, Jungle and Station list only two bosses, so wave 15 is a regular creature although the blurb says "Every 5th wave".
   Expected: bosses on 5/10/15 (and 20 where the family is long enough).

8. **Minor · Dungeons tab · creature controls shown for a map; wrong grammar; hidden text.**
   Observed on `#dungeons`: the right panel shows Walk/Run/Attack/Take a hit/Kill/Respawn, an empty "Any animation" select, Sounds checkboxes and an empty "Sounds used" section, none of which apply to a map. Cards read "1 lanes". The arena size text (`$('dims')`) is written into `#static-controls`, which is hidden on animated tabs, so it is never visible.
   Evidence: `qa/ui/dungeons_1400.png`.

9. **Minor · Page · a module-level error blanks the whole page with no recovery.**
   Observed once during the pass (file mid-edit): `Uncaught TypeError: Cannot set properties of null (setting 'onclick') (index.html:1178)` left the list empty, no canvas content, and all tabs dead. Not reproducible on the final file, but any missing element id in the top-level wiring has the same effect because the module has no guard around the `$('btn-...').onclick` assignments.
   Evidence: first capture of `qa/ui/classes_1400.png` (overwritten; banner text recorded here).

10. **Minor · Creatures · odd rest poses.**
    - `Frost Dragon` (frozen): `Flying_Idle` leaves the dragon lying flat on the pad with its head on the floor.
    - `Hornet` (swamp): rolled about 45° to one side in `Wasp_Flying`.
    Evidence: `qa/suspects_sheet.jpg`.

11. **Minor · Classes · list thumbnails are all the same Kenney figure without a weapon.**
    Observed: every class card shows the same `character-a.glb` thumbnail (set by `c.model = BLOCKY_RIGS[0]`), regardless of weapon or the selected Roblox rig.
    Evidence: `qa/ui/classes_1400.png`.

12. **Minor · Tooling · the `?walk=1` audit's `cover%` is wrong, so it cannot catch invisible models.**
    Observed: clearly visible creatures report `cover 0.1%` (Horse, Alpaca, Raptor, Trike, Rex ...) while others report 9%. The threshold compares a 160x120 render against the scene background colour after the walk shot changed renderer size; the numbers do not track what is drawn.
    Evidence: `qa/walk.log` versus `qa/walk_sheet_*.jpg`.

13. **Minor · Tooling · `?snapshot=N` does not hold Firefox `--screenshot`.**
    Observed: `firefox --headless --screenshot ... "?log=1&snapshot=12"` exits after ~1 s with the empty page (only `page start` / `module start` logged); the console shows the module being torn down (`Script terminated by timeout ... WebGLRenderer`). Firefox 159 fires `load` before the module's top-level await finishes.
    Evidence: first `qa/ui/creatures_1400.png` capture (overwritten by the Chromium one), `qa/ff_console.txt`.

## Passed

- Static: all 188 creature models, every map tower/hall/gate/prop/planet, every class weapon/turret/pet, all 18 blocky rigs and all 419 `files.json` entries exist on disk (0 missing). No duplicate creature ids, no model used twice, waves contiguous 1..N in every family, health/coins non-decreasing with wave within each archetype, no NaN/undefined stats, every class has exactly 2 skills with skill 1 cooldown 2..10 s and skill 2 cooldown 25..45 s.
- Creatures: 189/189 (now 188) load and animate with 0 `ERROR` lines; thumbnails render; the live view frames the first creature correctly at 1400x900 and 1920x1080.
- Maps: all 10 build with `0 failed` props, a sky gradient and horizon are visible, tower present at the far end, gate at the near end, 11..14 creatures walking the lane.
- Lobby: `687 loads, 0 failed`; spawn plaza, pads, scoreboard/shop/reserved placeholders and 10 dioramas render (`qa/maps/lobby.jpg`).
- Classes (via the `?cls=1` hook): all 11 load with 0 errors, turret stands next to the Engineer, bat pet next to the Summoner, skill animations play and cooldown text updates.
- Weapons and Props tabs render their first item with auto-rotate and size text (`qa/ui/weapons_1400.png`, `qa/ui/props_1400.png`).
- Not run: `?zoomtest=1`, manual orbit/zoom, sound playback.

// Hand-written catalog for animated things. Props and weapons are listed automatically in
// files.json (scripts/showcase-index.py). Stats mirror src/shared/Enemies.luau.

const KAYKIT = '../assets/creatures/kaykit-skeletons/';
const KENNEY = '../assets/creatures/kenney-graveyard/';
const ADV = '../assets/characters/kaykit-adventurers/';

// Animation names differ per pack; each entry maps the showcase's verbs to the pack's clip names.
const KAYKIT_RUNNER = { idle: 'Idle', walk: 'Walking_A', run: 'Running_A', attack: 'Unarmed_Melee_Attack_Punch_A', hit: 'Hit_A', death: 'Death_A', spawn: 'Spawn_Ground_Skeletons' };
const KENNEY_ANIMS = { idle: 'idle', walk: 'walk', run: 'sprint', attack: 'pick-up', hit: 'jump', death: 'die', spawn: 'idle' };

export const FAMILIES = [
  {
    id: 'skeletons', name: 'Graveyard: KayKit Skeletons', source: 'KayKit Character Pack: Skeletons (CC0, Kay Lousberg)',
    creatures: [
      { id: 'Runner', model: KAYKIT + 'Skeleton_Minion.glb', scale: 1.0, tint: null,
        stats: { health: 30, speed: 14, damage: 10, coins: 10, firstWave: 1 },
        anims: KAYKIT_RUNNER,
        sounds: { hit: 'impact_punch_medium', death: 'impact_soft_heavy', attack: 'impact_generic_light', step: 'footstep_grass' },
        blurb: 'Fast, weak, swarms. The first thing you shoot.' },
      { id: 'Brute', model: KAYKIT + 'Skeleton_Warrior.glb', scale: 1.35, tint: null,
        stats: { health: 150, speed: 8, damage: 40, coins: 30, firstWave: 3 },
        anims: { idle: '2H_Melee_Idle', walk: 'Walking_B', run: 'Running_B', attack: '2H_Melee_Attack_Chop', hit: 'Hit_B', death: 'Death_B', spawn: 'Skeletons_Awaken_Standing' },
        sounds: { hit: 'impact_plate_medium', death: 'impact_metal_heavy', attack: 'impact_wood_heavy', step: 'footstep_concrete' },
        blurb: 'Slow and tanky. Hits the Town Hall hard.' },
      { id: 'Spitter', model: KAYKIT + 'Skeleton_Mage.glb', scale: 1.0, tint: null,
        stats: { health: 60, speed: 10, damage: 20, coins: 20, firstWave: 5 },
        anims: { idle: 'Idle_B', walk: 'Walking_C', run: 'Running_C', attack: 'Spellcast_Shoot', hit: 'Hit_A', death: 'Death_C_Skeletons', spawn: 'Spawn_Air' },
        sounds: { hit: 'impact_glass_light', death: 'impact_glass_heavy', attack: 'impact_generic_light', step: 'footstep_wood' },
        blurb: 'Stops at range and shoots the Town Hall.' },
      { id: 'Elite Runner', model: KAYKIT + 'Skeleton_Rogue.glb', scale: 1.05, tint: 0x9ad5ff,
        stats: { health: 45, speed: 16, damage: 10, coins: 20, firstWave: 15 },
        anims: { idle: 'Idle_Combat', walk: 'Walking_D_Skeletons', run: 'Running_Strafe_Left', attack: 'Dualwield_Melee_Attack_Slice', hit: 'Hit_B', death: 'Death_A', spawn: 'Skeletons_Awaken_Floor' },
        sounds: { hit: 'impact_punch_heavy', death: 'impact_soft_heavy', attack: 'impact_generic_light', step: 'footstep_snow' },
        blurb: 'Wave 15+. A Runner with an extra ability (frost aura shown as a blue tint).' },
      { id: 'Boss', model: KAYKIT + 'Skeleton_Warrior.glb', scale: 2.4, tint: 0xff5a5a,
        stats: { health: 1200, speed: 6, damage: 250, coins: 500, firstWave: 5 },
        anims: { idle: '2H_Melee_Idle', walk: 'Walking_B', run: 'Running_B', attack: '2H_Melee_Attack_Spin', hit: 'Hit_A', death: 'Death_C_Skeletons', spawn: 'Skeletons_Awaken_Floor_Long' },
        sounds: { hit: 'impact_plate_heavy', death: 'impact_bell_heavy', attack: 'impact_metal_heavy', step: 'impact_soft_heavy' },
        blurb: 'Every 5th wave. Drops a guaranteed rare item.' },
    ],
  },
  {
    id: 'kenney', name: 'Graveyard: Kenney characters', source: 'Kenney Graveyard Kit (CC0)',
    creatures: [
      { id: 'Zombie', model: KENNEY + 'character-zombie.glb', scale: 1.0, tint: null,
        stats: { health: 30, speed: 14, damage: 10, coins: 10, firstWave: 1 }, anims: KENNEY_ANIMS,
        sounds: { hit: 'impact_soft_medium', death: 'impact_soft_heavy', attack: 'impact_punch_medium', step: 'footstep_grass' },
        blurb: 'Runner alternative. Blocky Kenney style, closer to the Roblox look.' },
      { id: 'Skeleton', model: KENNEY + 'character-skeleton.glb', scale: 1.0, tint: null,
        stats: { health: 45, speed: 16, damage: 10, coins: 20, firstWave: 15 }, anims: KENNEY_ANIMS,
        sounds: { hit: 'impact_wood_light', death: 'impact_wood_heavy', attack: 'impact_generic_light', step: 'footstep_concrete' },
        blurb: 'Elite Runner alternative.' },
      { id: 'S-Ghost', model: KENNEY + 'character-ghost.glb', scale: 1.0, tint: 0xa0e0ff,
        stats: { health: 60, speed: 10, damage: 20, coins: 20, firstWave: 5 }, anims: KENNEY_ANIMS,
        sounds: { hit: 'impact_glass_light', death: 'impact_glass_heavy', attack: 'impact_generic_light', step: 'footstep_snow' },
        blurb: 'Spitter alternative. Floats, so footsteps are off for it in game.' },
      { id: 'Vampire', model: KENNEY + 'character-vampire.glb', scale: 1.15, tint: null,
        stats: { health: 150, speed: 8, damage: 40, coins: 30, firstWave: 3 }, anims: KENNEY_ANIMS,
        sounds: { hit: 'impact_plate_light', death: 'impact_bell_heavy', attack: 'impact_punch_heavy', step: 'footstep_wood' },
        blurb: 'Brute alternative.' },
      { id: 'Keeper', model: KENNEY + 'character-keeper.glb', scale: 2.2, tint: 0xff7a5a,
        stats: { health: 1200, speed: 6, damage: 250, coins: 500, firstWave: 5 }, anims: KENNEY_ANIMS,
        sounds: { hit: 'impact_plate_heavy', death: 'impact_bell_heavy', attack: 'impact_metal_heavy', step: 'impact_soft_heavy' },
        blurb: 'Boss alternative: the graveyard keeper, scaled up.' },
    ],
  },
];

// Player characters (DESIGN.md "Characters"). KayKit Adventurers share the Skeletons rig, so the
// same animation names work.
// The Adventurers pack has 76 of the Skeletons' 95 clips: no Spawn_*, Idle_B, Idle_Combat,
// Running_C or *_Skeletons clips, so only names present in both packs are used here.
const ADV_ANIMS = { idle: 'Idle', walk: 'Walking_A', run: 'Running_A', attack: '1H_Melee_Attack_Slice_Diagonal', hit: 'Hit_A', death: 'Death_A', spawn: 'Cheer' };
export const CHARACTERS = [
  { id: 'Trooper', model: ADV + 'Rogue.glb', scale: 1, tint: null, anims: { ...ADV_ANIMS, attack: '1H_Ranged_Shoot' }, sounds: { hit: 'impact_soft_medium', death: 'impact_soft_heavy', attack: 'impact_generic_light', step: 'footstep_concrete' },
    stats: { tier: 'Free', role: 'All-rounder', weapon: 'Assault rifle' }, blurb: 'Stand-in: KayKit Rogue. Passive +10% reload; active: ammo crate.' },
  { id: 'Brute', model: ADV + 'Barbarian.glb', scale: 1.2, tint: null, anims: { ...ADV_ANIMS, attack: '2H_Melee_Attack_Chop', idle: '2H_Melee_Idle' }, sounds: { hit: 'impact_plate_medium', death: 'impact_metal_heavy', attack: 'impact_wood_heavy', step: 'footstep_concrete' },
    stats: { tier: 'Free', role: 'Blocker', weapon: 'Shotgun' }, blurb: 'Stand-in: KayKit Barbarian. Creatures cannot push past; active: taunt.' },
  { id: 'Scout', model: ADV + 'Rogue_Hooded.glb', scale: 0.95, tint: null, anims: { ...ADV_ANIMS, run: 'Running_B', attack: 'Dualwield_Melee_Attack_Slice' }, sounds: { hit: 'impact_soft_medium', death: 'impact_soft_heavy', attack: 'impact_generic_light', step: 'footstep_grass' },
    stats: { tier: 'Free', role: 'Mobility', weapon: 'Dual pistols' }, blurb: 'Stand-in: KayKit Hooded Rogue. +20% move speed; active: dash.' },
  { id: 'Medic', model: ADV + 'Mage.glb', scale: 1, tint: 0x9affb0, anims: { ...ADV_ANIMS, attack: 'Spellcast_Raise' }, sounds: { hit: 'impact_soft_medium', death: 'impact_soft_heavy', attack: 'impact_bell_heavy', step: 'footstep_wood' },
    stats: { tier: 'Free', role: 'Support', weapon: 'SMG' }, blurb: 'Stand-in: KayKit Mage, green tint. Repairs the Town Hall 2x faster; active: repair pulse.' },
  { id: 'Engineer', model: ADV + 'Knight.glb', scale: 1.05, tint: null, anims: { ...ADV_ANIMS, attack: 'Interact', idle: 'Blocking' }, sounds: { hit: 'impact_plate_light', death: 'impact_metal_heavy', attack: 'impact_wood_medium', step: 'footstep_concrete' },
    stats: { tier: 'Free', role: 'Area control', weapon: 'Carbine' }, blurb: 'Stand-in: KayKit Knight. Spells cost 15% less; active: barricade.' },
];

export const STAT_ICONS = { health: 'health', speed: 'speed', damage: 'damage', coins: 'coins', firstWave: 'wave', kills: 'kills' };
export const STAT_LABELS = { health: 'Health', speed: 'Speed (studs/s)', damage: 'Town Hall damage', coins: 'Coins per kill', firstWave: 'First wave', tier: 'Tier', role: 'Role', weapon: 'Starting weapon' };

// Hand-written catalog for animated things and classes. Props and weapons are listed automatically
// in files.json (scripts/showcase-index.py). Stats mirror src/shared/Enemies.luau.

const KAYKIT = '../assets/creatures/kaykit-skeletons/';
const KENNEY = '../assets/creatures/kenney-graveyard/';
const PETS = '../assets/creatures/kenney-cube-pets/';
const BLOBS = '../assets/creatures/kenney-blobs/';
const BLOCKY = '../assets/creatures/kenney-blocky/';
const DUNGEON = '../assets/creatures/kenney-mini-dungeon/';
const UFO = '../assets/creatures/kenney-ufo/';
const GUNS = '../assets/weapons/kenney-weapon-pack/';

// Archetype stats from src/shared/Enemies.luau: health, speed, Town Hall damage, coins, first wave.
export const ARCHETYPES = {
  Runner:   { health: 30,   speed: 14, damage: 10,  coins: 10,  firstWave: 1,  blurb: 'Fast, weak, swarms. The first thing you shoot.' },
  Brute:    { health: 150,  speed: 8,  damage: 40,  coins: 30,  firstWave: 3,  blurb: 'Slow and tanky. Hits the Town Hall hard.' },
  Spitter:  { health: 60,   speed: 10, damage: 20,  coins: 20,  firstWave: 5,  blurb: 'Stops at range and shoots the Town Hall.' },
  Exploder: { health: 40,   speed: 16, damage: 80,  coins: 25,  firstWave: 7,  blurb: 'Rushes the Town Hall and detonates. Kill it early.' },
  Shielder: { health: 200,  speed: 7,  damage: 20,  coins: 40,  firstWave: 10, blurb: 'Blocks damage for creatures behind it. Flank it.' },
  Flyer:    { health: 35,   speed: 18, damage: 15,  coins: 20,  firstWave: 12, blurb: 'Ignores ground paths and floor spells; flies straight in.' },
  Healer:   { health: 80,   speed: 9,  damage: 10,  coins: 45,  firstWave: 18, blurb: 'Heals nearby creatures. Priority target.' },
  Elite:    { health: 45,   speed: 16, damage: 10,  coins: 20,  firstWave: 15, blurb: 'Wave 15+. A Runner with an extra ability (frost aura, regen or teleport).' },
  Boss:     { health: 1200, speed: 6,  damage: 250, coins: 500, firstWave: 5,  blurb: 'Every 5th wave. Drops a guaranteed rare item.' },
};

// Animation names differ per pack; each entry maps the showcase's verbs to the pack's clip names.
const KENNEY_CHAR = { idle: 'idle', walk: 'walk', run: 'sprint', attack: 'pick-up', hit: 'jump', death: 'die', spawn: 'idle' };
const KENNEY_PET = { idle: 'idle', walk: 'walk', run: 'run', attack: 'eat', hit: 'gesture-negative', death: 'static', spawn: 'gesture-positive' };
const NONE = {}; // static models (UFOs) bob in place instead of animating

const c = (id, type, model, extra = {}) => ({ id, type, model, scale: 1, tint: null, anims: KENNEY_CHAR,
  sounds: { hit: 'impact_punch_medium', death: 'impact_soft_heavy', attack: 'impact_generic_light', step: 'footstep_grass' }, ...extra });

export const FAMILIES = [
  {
    id: 'skeletons', name: 'Graveyard: KayKit Skeletons', map: 'Graveyard', source: 'KayKit Character Pack: Skeletons (CC0, Kay Lousberg)',
    creatures: [
      c('Minion', 'Runner', KAYKIT + 'Skeleton_Minion.glb', { anims: { idle: 'Idle', walk: 'Walking_A', run: 'Running_A', attack: 'Unarmed_Melee_Attack_Punch_A', hit: 'Hit_A', death: 'Death_A', spawn: 'Spawn_Ground_Skeletons' } }),
      c('Warrior', 'Brute', KAYKIT + 'Skeleton_Warrior.glb', { scale: 1.35, anims: { idle: '2H_Melee_Idle', walk: 'Walking_B', run: 'Running_B', attack: '2H_Melee_Attack_Chop', hit: 'Hit_B', death: 'Death_B', spawn: 'Skeletons_Awaken_Standing' },
        sounds: { hit: 'impact_plate_medium', death: 'impact_metal_heavy', attack: 'impact_wood_heavy', step: 'footstep_concrete' } }),
      c('Mage', 'Spitter', KAYKIT + 'Skeleton_Mage.glb', { anims: { idle: 'Idle_B', walk: 'Walking_C', run: 'Running_C', attack: 'Spellcast_Shoot', hit: 'Hit_A', death: 'Death_C_Skeletons', spawn: 'Spawn_Air' },
        sounds: { hit: 'impact_glass_light', death: 'impact_glass_heavy', attack: 'impact_generic_light', step: 'footstep_wood' } }),
      c('Bomber', 'Exploder', KAYKIT + 'Skeleton_Minion.glb', { scale: 1.1, tint: 0xffa040, anims: { idle: 'Idle', walk: 'Running_A', run: 'Running_B', attack: 'Jump_Full_Short', hit: 'Hit_B', death: 'Death_B', spawn: 'Spawn_Ground' },
        sounds: { hit: 'impact_punch_medium', death: 'impact_bell_heavy', attack: 'impact_metal_heavy', step: 'footstep_grass' } }),
      c('Guard', 'Shielder', KAYKIT + 'Skeleton_Warrior.glb', { scale: 1.2, tint: 0x6080c0, anims: { idle: 'Blocking', walk: 'Walking_B', run: 'Running_B', attack: 'Block_Attack', hit: 'Block_Hit', death: 'Death_A', spawn: 'Skeletons_Awaken_Standing' },
        sounds: { hit: 'impact_plate_heavy', death: 'impact_metal_heavy', attack: 'impact_plate_medium', step: 'footstep_concrete' } }),
      c('Necromancer', 'Healer', KAYKIT + 'Skeleton_Mage.glb', { tint: 0x80ff9a, anims: { idle: 'Spellcasting', walk: 'Walking_C', run: 'Running_C', attack: 'Spellcast_Raise', hit: 'Hit_A', death: 'Death_C_Skeletons', spawn: 'Spawn_Air' },
        sounds: { hit: 'impact_glass_light', death: 'impact_glass_heavy', attack: 'impact_bell_heavy', step: 'footstep_wood' } }),
      c('Rogue', 'Elite', KAYKIT + 'Skeleton_Rogue.glb', { scale: 1.05, tint: 0x9ad5ff, anims: { idle: 'Idle_Combat', walk: 'Walking_D_Skeletons', run: 'Running_Strafe_Left', attack: 'Dualwield_Melee_Attack_Slice', hit: 'Hit_B', death: 'Death_A', spawn: 'Skeletons_Awaken_Floor' },
        sounds: { hit: 'impact_punch_heavy', death: 'impact_soft_heavy', attack: 'impact_generic_light', step: 'footstep_snow' } }),
      c('Lich', 'Boss', KAYKIT + 'Skeleton_Warrior.glb', { scale: 2.4, tint: 0xff5a5a, anims: { idle: '2H_Melee_Idle', walk: 'Walking_B', run: 'Running_B', attack: '2H_Melee_Attack_Spin', hit: 'Hit_A', death: 'Death_C_Skeletons', spawn: 'Skeletons_Awaken_Floor_Long' },
        sounds: { hit: 'impact_plate_heavy', death: 'impact_bell_heavy', attack: 'impact_metal_heavy', step: 'impact_soft_heavy' } }),
    ],
  },
  {
    id: 'kenney-graveyard', name: 'Graveyard: Kenney characters', map: 'Graveyard', source: 'Kenney Graveyard Kit (CC0)',
    creatures: [
      c('Zombie', 'Runner', KENNEY + 'character-zombie.glb', { sounds: { hit: 'impact_soft_medium', death: 'impact_soft_heavy', attack: 'impact_punch_medium', step: 'footstep_grass' } }),
      c('Vampire', 'Brute', KENNEY + 'character-vampire.glb', { scale: 1.15, sounds: { hit: 'impact_plate_light', death: 'impact_bell_heavy', attack: 'impact_punch_heavy', step: 'footstep_wood' } }),
      c('S-Ghost', 'Spitter', KENNEY + 'character-ghost.glb', { tint: 0xa0e0ff, sounds: { hit: 'impact_glass_light', death: 'impact_glass_heavy', attack: 'impact_generic_light', step: 'footstep_snow' } }),
      c('Wraith', 'Flyer', KENNEY + 'character-ghost.glb', { scale: 0.9, tint: 0xffffff, sounds: { hit: 'impact_glass_light', death: 'impact_glass_medium', attack: 'impact_generic_light', step: 'footstep_snow' } }),
      c('Skeleton', 'Elite', KENNEY + 'character-skeleton.glb', { sounds: { hit: 'impact_wood_light', death: 'impact_wood_heavy', attack: 'impact_generic_light', step: 'footstep_concrete' } }),
      c('Keeper', 'Boss', KENNEY + 'character-keeper.glb', { scale: 2.2, tint: 0xff7a5a, sounds: { hit: 'impact_plate_heavy', death: 'impact_bell_heavy', attack: 'impact_metal_heavy', step: 'impact_soft_heavy' } }),
    ],
  },
  {
    id: 'swamp', name: 'Swamp: Kenney Cube Pets (bugs and beasts)', map: 'Swamp', source: 'Kenney Cube Pets (CC0)',
    creatures: [
      c('Caterpillar', 'Runner', PETS + 'animal-caterpillar.glb', { anims: KENNEY_PET, sounds: { hit: 'impact_soft_medium', death: 'impact_soft_heavy', attack: 'impact_generic_light', step: 'footstep_grass' } }),
      c('Mud Hog', 'Brute', PETS + 'animal-hog.glb', { scale: 1.3, anims: KENNEY_PET, sounds: { hit: 'impact_soft_heavy', death: 'impact_plank_medium', attack: 'impact_punch_heavy', step: 'footstep_grass' } }),
      c('Crab', 'Spitter', PETS + 'animal-crab.glb', { anims: KENNEY_PET, sounds: { hit: 'impact_plate_light', death: 'impact_plate_medium', attack: 'impact_tin_medium', step: 'footstep_concrete' } }),
      c('Bomb Bee', 'Exploder', PETS + 'animal-bee.glb', { tint: 0xffb000, anims: KENNEY_PET, sounds: { hit: 'impact_generic_light', death: 'impact_bell_heavy', attack: 'impact_metal_heavy', step: 'footstep_grass' } }),
      c('Beaver', 'Shielder', PETS + 'animal-beaver.glb', { scale: 1.2, tint: 0x6080c0, anims: KENNEY_PET, sounds: { hit: 'impact_wood_medium', death: 'impact_wood_heavy', attack: 'impact_wood_light', step: 'footstep_wood' } }),
      c('Parrot', 'Flyer', PETS + 'animal-parrot.glb', { anims: KENNEY_PET, sounds: { hit: 'impact_soft_medium', death: 'impact_soft_heavy', attack: 'impact_generic_light', step: 'footstep_snow' } }),
      c('Bunny', 'Healer', PETS + 'animal-bunny.glb', { tint: 0x80ff9a, anims: KENNEY_PET, sounds: { hit: 'impact_soft_medium', death: 'impact_soft_heavy', attack: 'impact_bell_heavy', step: 'footstep_grass' } }),
      c('Fox', 'Elite', PETS + 'animal-fox.glb', { tint: 0x9ad5ff, anims: KENNEY_PET, sounds: { hit: 'impact_soft_medium', death: 'impact_soft_heavy', attack: 'impact_punch_medium', step: 'footstep_snow' } }),
      c('Elephant', 'Boss', PETS + 'animal-elephant.glb', { scale: 2.2, tint: 0xff7a5a, anims: KENNEY_PET, sounds: { hit: 'impact_plate_heavy', death: 'impact_bell_heavy', attack: 'impact_metal_heavy', step: 'impact_soft_heavy' } }),
    ],
  },
  {
    id: 'slimes', name: 'Sewer: Kenney blobs (slimes)', map: 'Sewer', source: 'Kenney Platformer Kit characters (CC0)',
    creatures: [
      c('Green Slime', 'Runner', BLOBS + 'character-oozi.glb', { sounds: { hit: 'impact_soft_medium', death: 'impact_soft_heavy', attack: 'impact_generic_light', step: 'footstep_carpet' } }),
      c('Big Slime', 'Brute', BLOBS + 'character-oobi.glb', { scale: 1.5, sounds: { hit: 'impact_soft_heavy', death: 'impact_soft_heavy', attack: 'impact_punch_heavy', step: 'footstep_carpet' } }),
      c('Spit Slime', 'Spitter', BLOBS + 'character-ooli.glb', { sounds: { hit: 'impact_soft_medium', death: 'impact_glass_light', attack: 'impact_generic_light', step: 'footstep_carpet' } }),
      c('Boom Slime', 'Exploder', BLOBS + 'character-oopi.glb', { tint: 0xffa040, sounds: { hit: 'impact_soft_medium', death: 'impact_bell_heavy', attack: 'impact_metal_heavy', step: 'footstep_carpet' } }),
      c('Nurse Slime', 'Healer', BLOBS + 'character-oodi.glb', { tint: 0x80ff9a, sounds: { hit: 'impact_soft_medium', death: 'impact_soft_heavy', attack: 'impact_bell_heavy', step: 'footstep_carpet' } }),
      c('King Slime', 'Boss', BLOBS + 'character-oobi.glb', { scale: 2.6, tint: 0xff5a5a, sounds: { hit: 'impact_soft_heavy', death: 'impact_bell_heavy', attack: 'impact_metal_heavy', step: 'impact_soft_heavy' } }),
    ],
  },
  {
    id: 'bandits', name: 'Village: Kenney bandits and orcs', map: 'Bandit Village', source: 'Kenney Blocky Characters + Mini Dungeon (CC0)',
    creatures: [
      c('Bandit', 'Runner', BLOCKY + 'character-a.glb'),
      c('Thug', 'Runner', BLOCKY + 'character-e.glb'),
      c('Orc', 'Brute', DUNGEON + 'character-orc.glb', { scale: 1.3, sounds: { hit: 'impact_punch_heavy', death: 'impact_soft_heavy', attack: 'impact_wood_heavy', step: 'footstep_concrete' } }),
      c('Archer', 'Spitter', BLOCKY + 'character-f.glb', { sounds: { hit: 'impact_punch_medium', death: 'impact_soft_heavy', attack: 'impact_wood_light', step: 'footstep_grass' } }),
      c('Sapper', 'Exploder', BLOCKY + 'character-j.glb', { tint: 0xffa040, sounds: { hit: 'impact_punch_medium', death: 'impact_bell_heavy', attack: 'impact_metal_heavy', step: 'footstep_grass' } }),
      c('Shield Bearer', 'Shielder', BLOCKY + 'character-k.glb', { scale: 1.1, tint: 0x6080c0, sounds: { hit: 'impact_plate_medium', death: 'impact_metal_heavy', attack: 'impact_plate_light', step: 'footstep_concrete' } }),
      c('Cleric', 'Healer', DUNGEON + 'character-human.glb', { tint: 0x80ff9a, sounds: { hit: 'impact_punch_medium', death: 'impact_soft_heavy', attack: 'impact_bell_heavy', step: 'footstep_wood' } }),
      c('Assassin', 'Elite', BLOCKY + 'character-r.glb', { tint: 0x9ad5ff, sounds: { hit: 'impact_punch_heavy', death: 'impact_soft_heavy', attack: 'impact_generic_light', step: 'footstep_snow' } }),
      c('Warlord', 'Boss', DUNGEON + 'character-orc.glb', { scale: 2.3, tint: 0xff5a5a, sounds: { hit: 'impact_plate_heavy', death: 'impact_bell_heavy', attack: 'impact_metal_heavy', step: 'impact_soft_heavy' } }),
    ],
  },
  {
    id: 'farm', name: 'Haunted Farm: Kenney Cube Pets', map: 'Haunted Farm', source: 'Kenney Cube Pets (CC0)',
    creatures: [
      c('Chick', 'Runner', PETS + 'animal-chick.glb', { anims: KENNEY_PET, sounds: { hit: 'impact_soft_medium', death: 'impact_soft_heavy', attack: 'impact_generic_light', step: 'footstep_grass' } }),
      c('Pig', 'Brute', PETS + 'animal-pig.glb', { scale: 1.3, anims: KENNEY_PET, sounds: { hit: 'impact_soft_heavy', death: 'impact_plank_medium', attack: 'impact_punch_heavy', step: 'footstep_grass' } }),
      c('Cat', 'Spitter', PETS + 'animal-cat.glb', { anims: KENNEY_PET, sounds: { hit: 'impact_soft_medium', death: 'impact_soft_heavy', attack: 'impact_generic_light', step: 'footstep_carpet' } }),
      c('Hound', 'Elite', PETS + 'animal-dog.glb', { tint: 0x9ad5ff, anims: KENNEY_PET, sounds: { hit: 'impact_soft_medium', death: 'impact_soft_heavy', attack: 'impact_punch_medium', step: 'footstep_grass' } }),
      c('Mad Cow', 'Boss', PETS + 'animal-cow.glb', { scale: 2.2, tint: 0xff7a5a, anims: KENNEY_PET, sounds: { hit: 'impact_plate_heavy', death: 'impact_bell_heavy', attack: 'impact_metal_heavy', step: 'impact_soft_heavy' } }),
    ],
  },
  {
    id: 'frozen', name: 'Frozen Cavern: Kenney Cube Pets', map: 'Frozen Cavern', source: 'Kenney Cube Pets (CC0)',
    creatures: [
      c('Penguin', 'Runner', PETS + 'animal-penguin.glb', { anims: KENNEY_PET, sounds: { hit: 'impact_soft_medium', death: 'impact_soft_heavy', attack: 'impact_generic_light', step: 'footstep_snow' } }),
      c('Polar Bear', 'Brute', PETS + 'animal-polar.glb', { scale: 1.3, anims: KENNEY_PET, sounds: { hit: 'impact_soft_heavy', death: 'impact_plank_medium', attack: 'impact_punch_heavy', step: 'footstep_snow' } }),
      c('Ice Fish', 'Spitter', PETS + 'animal-fish.glb', { tint: 0xa0e0ff, anims: KENNEY_PET, sounds: { hit: 'impact_glass_light', death: 'impact_glass_medium', attack: 'impact_glass_light', step: 'footstep_snow' } }),
      c('Ice Bomb', 'Exploder', PETS + 'animal-penguin.glb', { scale: 1.1, tint: 0xffa040, anims: KENNEY_PET, sounds: { hit: 'impact_glass_light', death: 'impact_glass_heavy', attack: 'impact_bell_heavy', step: 'footstep_snow' } }),
      c('Stag', 'Elite', PETS + 'animal-deer.glb', { tint: 0x9ad5ff, anims: KENNEY_PET, sounds: { hit: 'impact_soft_medium', death: 'impact_soft_heavy', attack: 'impact_wood_medium', step: 'footstep_snow' } }),
      c('Frost King', 'Boss', PETS + 'animal-polar.glb', { scale: 2.3, tint: 0xff7a5a, anims: KENNEY_PET, sounds: { hit: 'impact_plate_heavy', death: 'impact_bell_heavy', attack: 'impact_metal_heavy', step: 'impact_soft_heavy' } }),
    ],
  },
  {
    id: 'jungle', name: 'Jungle Temple: Kenney Cube Pets', map: 'Jungle Temple', source: 'Kenney Cube Pets (CC0)',
    creatures: [
      c('Monkey', 'Runner', PETS + 'animal-monkey.glb', { anims: KENNEY_PET, sounds: { hit: 'impact_soft_medium', death: 'impact_soft_heavy', attack: 'impact_generic_light', step: 'footstep_grass' } }),
      c('Lion', 'Brute', PETS + 'animal-lion.glb', { scale: 1.3, anims: KENNEY_PET, sounds: { hit: 'impact_soft_heavy', death: 'impact_plank_medium', attack: 'impact_punch_heavy', step: 'footstep_grass' } }),
      c('Giraffe', 'Spitter', PETS + 'animal-giraffe.glb', { anims: KENNEY_PET, sounds: { hit: 'impact_soft_medium', death: 'impact_soft_heavy', attack: 'impact_generic_light', step: 'footstep_grass' } }),
      c('Panda', 'Shielder', PETS + 'animal-panda.glb', { scale: 1.2, tint: 0x6080c0, anims: KENNEY_PET, sounds: { hit: 'impact_wood_medium', death: 'impact_wood_heavy', attack: 'impact_wood_light', step: 'footstep_wood' } }),
      c('Koala', 'Healer', PETS + 'animal-koala.glb', { tint: 0x80ff9a, anims: KENNEY_PET, sounds: { hit: 'impact_soft_medium', death: 'impact_soft_heavy', attack: 'impact_bell_heavy', step: 'footstep_wood' } }),
      c('Tiger', 'Elite', PETS + 'animal-tiger.glb', { tint: 0x9ad5ff, anims: KENNEY_PET, sounds: { hit: 'impact_soft_medium', death: 'impact_soft_heavy', attack: 'impact_punch_medium', step: 'footstep_grass' } }),
      c('Temple Lion', 'Boss', PETS + 'animal-lion.glb', { scale: 2.3, tint: 0xff7a5a, anims: KENNEY_PET, sounds: { hit: 'impact_plate_heavy', death: 'impact_bell_heavy', attack: 'impact_metal_heavy', step: 'impact_soft_heavy' } }),
    ],
  },
  {
    id: 'pirates', name: 'Pirate Cove: Kenney blocky characters', map: 'Pirate Cove', source: 'Kenney Blocky Characters (CC0)',
    creatures: [
      c('Deckhand', 'Runner', BLOCKY + 'character-b.glb'),
      c('Gunner', 'Spitter', BLOCKY + 'character-c.glb', { sounds: { hit: 'impact_punch_medium', death: 'impact_soft_heavy', attack: 'impact_metal_medium', step: 'footstep_wood' } }),
      c('Powder Monkey', 'Exploder', BLOCKY + 'character-d.glb', { tint: 0xffa040, sounds: { hit: 'impact_punch_medium', death: 'impact_bell_heavy', attack: 'impact_metal_heavy', step: 'footstep_wood' } }),
      c('Boatswain', 'Shielder', BLOCKY + 'character-g.glb', { scale: 1.1, tint: 0x6080c0, sounds: { hit: 'impact_plate_medium', death: 'impact_metal_heavy', attack: 'impact_plate_light', step: 'footstep_wood' } }),
      c('Surgeon', 'Healer', BLOCKY + 'character-h.glb', { tint: 0x80ff9a, sounds: { hit: 'impact_punch_medium', death: 'impact_soft_heavy', attack: 'impact_bell_heavy', step: 'footstep_wood' } }),
      c('First Mate', 'Brute', BLOCKY + 'character-l.glb', { scale: 1.25, sounds: { hit: 'impact_punch_heavy', death: 'impact_soft_heavy', attack: 'impact_wood_heavy', step: 'footstep_wood' } }),
      c('Captain', 'Boss', BLOCKY + 'character-i.glb', { scale: 2.2, tint: 0xff5a5a, sounds: { hit: 'impact_plate_heavy', death: 'impact_bell_heavy', attack: 'impact_metal_heavy', step: 'impact_soft_heavy' } }),
    ],
  },
  {
    id: 'invaders', name: 'Factory: Kenney UFOs (flying, static models)', map: 'Factory', source: 'Kenney Tower Defense Kit (CC0)',
    creatures: [
      c('Scout UFO', 'Flyer', UFO + 'enemy-ufo-a.glb', { anims: NONE, sounds: { hit: 'impact_metal_light', death: 'impact_metal_heavy', attack: 'impact_generic_light', step: null } }),
      c('Gunship', 'Spitter', UFO + 'enemy-ufo-b-weapon.glb', { anims: NONE, sounds: { hit: 'impact_metal_medium', death: 'impact_metal_heavy', attack: 'impact_tin_medium', step: null } }),
      c('Hauler', 'Brute', UFO + 'enemy-ufo-c.glb', { scale: 1.3, anims: NONE, sounds: { hit: 'impact_metal_medium', death: 'impact_metal_heavy', attack: 'impact_plate_heavy', step: null } }),
      c('Kamikaze', 'Exploder', UFO + 'enemy-ufo-a-weapon.glb', { tint: 0xffa040, anims: NONE, sounds: { hit: 'impact_metal_light', death: 'impact_bell_heavy', attack: 'impact_metal_heavy', step: null } }),
      c('Mothership', 'Boss', UFO + 'enemy-ufo-d-weapon.glb', { scale: 2.5, tint: 0xff5a5a, anims: NONE, sounds: { hit: 'impact_plate_heavy', death: 'impact_bell_heavy', attack: 'impact_metal_heavy', step: null } }),
    ],
  },
  {
    id: 'aliens', name: 'Space Station: Kenney space aliens and UFOs (static models)', map: 'Space Station', source: 'Kenney Space Kit + Tower Defense Kit (CC0)',
    creatures: [
      c('Alien', 'Runner', '../assets/creatures/kenney-space/alien.glb', { anims: NONE, tint: 0x80ff9a, sounds: { hit: 'impact_soft_medium', death: 'impact_glass_heavy', attack: 'impact_generic_light', step: null } }),
      c('Drone', 'Flyer', UFO + 'enemy-ufo-a.glb', { scale: 0.8, anims: NONE, sounds: { hit: 'impact_metal_light', death: 'impact_metal_heavy', attack: 'impact_generic_light', step: null } }),
      c('Lancer', 'Spitter', UFO + 'enemy-ufo-c-weapon.glb', { anims: NONE, sounds: { hit: 'impact_metal_medium', death: 'impact_metal_heavy', attack: 'impact_tin_medium', step: null } }),
      c('Bulwark', 'Shielder', UFO + 'enemy-ufo-d.glb', { scale: 1.3, tint: 0x6080c0, anims: NONE, sounds: { hit: 'impact_plate_heavy', death: 'impact_metal_heavy', attack: 'impact_plate_medium', step: null } }),
      c('Hive Alien', 'Boss', '../assets/creatures/kenney-space/alien.glb', { scale: 2.6, tint: 0xff5a5a, anims: NONE, sounds: { hit: 'impact_plate_heavy', death: 'impact_bell_heavy', attack: 'impact_metal_heavy', step: null } }),
    ],
  },
];

// Fill in stats and blurb from the archetype table so each family only states what differs.
for (const f of FAMILIES) for (const cr of f.creatures) {
  const a = ARCHETYPES[cr.type];
  cr.stats = { health: a.health, speed: a.speed, damage: a.damage, coins: a.coins, firstWave: a.firstWave };
  cr.blurb = `${cr.type}. ${a.blurb}`;
  cr.source = f.source;
}

// Classes (DESIGN.md "Classes"). Players keep their own avatar; a class is a starting weapon,
// a passive, an active and a gear overlay. The showcase previews the starting weapon model.
export const CLASSES = [
  { id: 'Trooper', tier: 'Free', role: 'All-rounder', weapon: 'Assault rifle', model: GUNS + 'machinegun.glb',
    passive: '+10% reload speed', active: 'Ammo crate for the team (60 s)', gear: 'Light vest, cap' },
  { id: 'Brute', tier: 'Free', role: 'Blocker', weapon: 'Shotgun', model: GUNS + 'shotgun.glb',
    passive: 'Creatures cannot push past you', active: 'Taunt: creatures chase you for 5 s (45 s)', gear: 'Heavy pauldrons, wide stance' },
  { id: 'Scout', tier: 'Free', role: 'Mobility', weapon: 'Dual pistols', model: GUNS + 'pistol.glb',
    passive: '+20% move speed', active: 'Dash through enemies (20 s)', gear: 'Hood, light boots' },
  { id: 'Medic', tier: 'Free', role: 'Support', weapon: 'SMG', model: GUNS + 'uzi.glb',
    passive: 'Repairs the Town Hall 2x faster', active: 'Repair pulse: +150 Town Hall HP (40 s)', gear: 'Visible backpack, armband' },
  { id: 'Engineer', tier: 'Free', role: 'Area control', weapon: 'Carbine', model: GUNS + 'machinegunLauncher.glb',
    passive: 'Spells cost 15% less', active: 'Barricade blocks a lane for 10 s (50 s)', gear: 'Tool belt, goggles' },
  { id: 'Pyro', tier: 'Premium', role: 'Area damage', weapon: 'Flamethrower', model: GUNS + 'flamethrower_long.glb',
    passive: 'Burning enemies take +15% damage', active: 'Fire wall across a lane (45 s)', gear: 'Tank on back, mask' },
  { id: 'Frost Mage', tier: 'Premium', role: 'Crowd control', weapon: 'Ice wand', model: GUNS + 'pistolSilencer.glb',
    passive: 'Freeze spells last 25% longer', active: 'Blizzard: slows everything on screen (60 s)', gear: 'Frost cloak (placeholder weapon model)' },
  { id: 'Sniper', tier: 'Premium', role: 'Boss killer', weapon: 'Bolt rifle', model: GUNS + 'sniper.glb',
    passive: '+50% headshot damage', active: 'Mark a target: team deals +30% (40 s)', gear: 'Ghillie hood, scope' },
  { id: 'Demolisher', tier: 'Premium', role: 'Burst', weapon: 'Grenade launcher', model: GUNS + 'rocketlauncherModern.glb',
    passive: 'Carries +2 grenades', active: 'Cluster bomb (50 s)', gear: 'Bandolier, helmet' },
  { id: 'Summoner', tier: 'Premium', role: 'Pet', weapon: 'Staff', model: GUNS + 'knifeRound_smooth.glb',
    passive: 'Starts with a pet that attacks', active: 'Pet enrages, 2x damage for 8 s (45 s)', gear: 'Robe trim, floating pet (placeholder weapon model)' },
];

// Dungeons (src/shared/Dungeons.luau): unlock level, creature family, lanes, gimmick, props kit.
export const DUNGEONS = [
  { id: 'Graveyard', name: 'Graveyard', unlockLevel: 1, family: 'skeletons', lanes: 3, gimmick: 'Fog rolls in on boss waves, cutting sight lines', props: 'KayKit Halloween Bits, Kenney Graveyard Kit' },
  { id: 'Farm', name: 'Haunted Farm', unlockLevel: 3, family: 'farm', lanes: 2, gimmick: 'Hay bales can be pushed into lanes as cover; animals trample them', props: 'Kenney Farm / Nature kits (to fetch)' },
  { id: 'Swamp', name: 'Swamp', unlockLevel: 5, family: 'swamp', lanes: 2, gimmick: 'Shallow water slows everyone; ice spells freeze it solid', props: 'Kenney Nature Kit (to fetch)' },
  { id: 'Sewer', name: 'Sewer', unlockLevel: 10, family: 'slimes', lanes: 3, gimmick: 'Slimes split in two when killed above half health', props: 'Kenney Modular Cave / Platformer kits (to fetch)' },
  { id: 'Village', name: 'Bandit Village', unlockLevel: 15, family: 'bandits', lanes: 4, gimmick: 'Bandits loot dropped coins before you can', props: 'KayKit Dungeon, Kenney Fantasy Town (to fetch)' },
  { id: 'Frozen', name: 'Frozen Cavern', unlockLevel: 20, family: 'frozen', lanes: 2, gimmick: 'Everything is slippery; freeze spells last twice as long', props: 'Kenney Holiday + Modular Cave kits (to fetch)' },
  { id: 'Jungle', name: 'Jungle Temple', unlockLevel: 25, family: 'jungle', lanes: 3, gimmick: 'Vines block sight lines until burned away', props: 'Kenney Nature Kit (to fetch)' },
  { id: 'Pirate', name: 'Pirate Cove', unlockLevel: 30, family: 'pirates', lanes: 3, gimmick: 'Cannons on the cliffs can be captured and fired at the lanes', props: 'Kenney Pirate Kit (to fetch)' },
  { id: 'Factory', name: 'Factory', unlockLevel: 35, family: 'invaders', lanes: 4, gimmick: 'Conveyor belts move anything on them, including grenades', props: 'Kenney Factory Kit (to fetch)' },
  { id: 'Station', name: 'Space Station', unlockLevel: 40, family: 'aliens', lanes: 4, gimmick: 'Airlocks vent a lane for 5 s when opened', props: 'Kenney Space Station Kit (to fetch)' },
];

export const STAT_ICONS = { health: 'health', speed: 'speed', damage: 'damage', coins: 'coins', firstWave: 'wave', kills: 'kills' };
export const STAT_LABELS = { health: 'Health', speed: 'Speed (studs/s)', damage: 'Town Hall damage', coins: 'Coins per kill', firstWave: 'First wave', tier: 'Tier', role: 'Role', weapon: 'Starting weapon', passive: 'Passive', active: 'Active', gear: 'Gear overlay' };

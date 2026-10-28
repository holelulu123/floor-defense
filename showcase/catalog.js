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
const QA = '../assets/creatures/quaternius-animals/';
const QD = '../assets/creatures/quaternius-dinosaurs/';
const QE = '../assets/creatures/quaternius-easy-enemies/';
const QC = '../assets/creatures/quaternius-cyberpunk/';
const QM = '../assets/creatures/quaternius-mechs/';
const QS = '../assets/creatures/quaternius-space/';
const QP = '../assets/creatures/quaternius-platformer/';

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
// Quaternius packs (the viewer strips the "Armature|" prefix from clip names).
const Q_ANIMAL = { idle: 'Idle', walk: 'Walk', run: 'Gallop', attack: 'Attack_Headbutt', hit: 'Idle_HitReact_Left', death: 'Death', spawn: 'Idle_2' };
const Q_CANINE = { ...Q_ANIMAL, attack: 'Attack' };
const Q_DINO = n => ({ idle: `${n}_Idle`, walk: `${n}_Walk`, run: `${n}_Run`, attack: `${n}_Attack`, hit: `${n}_Jump`, death: `${n}_Death`, spawn: `${n}_Jump` });
const Q_EASY = (n, walk = `${n}_Walk`, run = `${n}_Run`) => ({ idle: `${n}_Idle`, walk, run, attack: `${n}_Attack`, hit: `${n}_Jump`, death: `${n}_Death`, spawn: `${n}_Jump` });
const Q_CYBER = { idle: 'Idle', walk: 'Walk', run: 'Run', attack: 'Attack', hit: 'Jump', death: 'Death', spawn: 'Jump' };
const Q_MECH = { idle: 'Idle', walk: 'Walk', run: 'Run', attack: 'Punch', hit: 'HitRecieve_1', death: 'Death', spawn: 'Hello' };
const Q_SPACE_FLYER = { idle: 'Flying_Idle', walk: 'Flying_Idle', run: 'Fast_Flying', attack: 'Headbutt', hit: 'HitReact', death: 'Death', spawn: 'Yes' };
const Q_SPACE_CHAR = { idle: 'Idle', walk: 'Walk', run: 'Run', attack: 'Punch', hit: 'HitReact', death: 'Death', spawn: 'Wave' };
const Q_SPACE_MECH = { idle: 'Idle', walk: 'Walk', run: 'Run', attack: 'Shoot_Big', hit: 'HitRecieve_1', death: 'Death', spawn: 'Hello' };
const Q_MONSTER = { idle: 'Idle', walk: 'Walk', run: 'Walk', attack: 'Bite_Front', hit: 'HitRecieve', death: 'Death', spawn: 'Jump' };
const SOFT = { hit: 'impact_soft_medium', death: 'impact_soft_heavy', attack: 'impact_punch_medium', step: 'footstep_grass' };
const HEAVY = { hit: 'impact_soft_heavy', death: 'impact_plank_medium', attack: 'impact_punch_heavy', step: 'impact_soft_heavy' };
const METAL = { hit: 'impact_metal_medium', death: 'impact_metal_heavy', attack: 'impact_tin_medium', step: 'footstep_concrete' };
const BIGMETAL = { hit: 'impact_plate_heavy', death: 'impact_bell_heavy', attack: 'impact_metal_heavy', step: 'impact_plate_medium' };

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
    id: 'swamp', name: 'Swamp: Kenney Cube Pets (bugs and beasts)', map: 'Swamp', source: 'Kenney Cube Pets (CC0) + Quaternius Easy Enemy Pack (CC0)',
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
      c('Bog Frog', 'Runner', QE + 'Frog.glb', { anims: Q_EASY('Frog', 'Frog_Jump', 'Frog_Jump'), sounds: { ...SOFT, step: 'footstep_carpet' } }),
      c('Marsh Rat', 'Runner', QE + 'Rat.glb', { anims: Q_EASY('Rat'), sounds: SOFT }),
      c('Swamp Snake', 'Spitter', QE + 'Snake.glb', { anims: Q_EASY('Snake', 'Snake_Walk', 'Snake_Walk'), sounds: { ...SOFT, attack: 'impact_generic_light' } }),
      c('Viper', 'Elite', QE + 'Snake_angry.glb', { tint: 0x9ad5ff, anims: Q_EASY('Snake', 'Snake_Walk', 'Snake_Walk'), sounds: { ...SOFT, attack: 'impact_generic_light' } }),
      c('Bog Spider', 'Brute', QE + 'Spider.glb', { scale: 1.3, anims: Q_EASY('Spider', 'Spider_Walk', 'Spider_Walk'), sounds: { ...SOFT, step: 'footstep_wood' } }),
      c('Hornet', 'Flyer', QE + 'Wasp.glb', { anims: { ...Q_EASY('Wasp', 'Wasp_Flying', 'Wasp_Flying'), idle: 'Wasp_Flying', hit: 'Wasp_Attack', spawn: 'Wasp_Flying' }, sounds: { ...SOFT, step: null } }),
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
    id: 'farm', name: 'Haunted Farm: Kenney Cube Pets', map: 'Haunted Farm', source: 'Kenney Cube Pets (CC0) + Quaternius Ultimate Animated Animals (CC0)',
    creatures: [
      c('Chick', 'Runner', PETS + 'animal-chick.glb', { anims: KENNEY_PET, sounds: { hit: 'impact_soft_medium', death: 'impact_soft_heavy', attack: 'impact_generic_light', step: 'footstep_grass' } }),
      c('Pig', 'Brute', PETS + 'animal-pig.glb', { scale: 1.3, anims: KENNEY_PET, sounds: { hit: 'impact_soft_heavy', death: 'impact_plank_medium', attack: 'impact_punch_heavy', step: 'footstep_grass' } }),
      c('Cat', 'Spitter', PETS + 'animal-cat.glb', { anims: KENNEY_PET, sounds: { hit: 'impact_soft_medium', death: 'impact_soft_heavy', attack: 'impact_generic_light', step: 'footstep_carpet' } }),
      c('Hound', 'Elite', PETS + 'animal-dog.glb', { tint: 0x9ad5ff, anims: KENNEY_PET, sounds: { hit: 'impact_soft_medium', death: 'impact_soft_heavy', attack: 'impact_punch_medium', step: 'footstep_grass' } }),
      c('Mad Cow', 'Boss', PETS + 'animal-cow.glb', { scale: 2.2, tint: 0xff7a5a, anims: KENNEY_PET, sounds: { hit: 'impact_plate_heavy', death: 'impact_bell_heavy', attack: 'impact_metal_heavy', step: 'impact_soft_heavy' } }),
      c('Cow', 'Brute', QA + 'Cow.glb', { scale: 1.2, anims: Q_ANIMAL, sounds: HEAVY }),
      c('Bull', 'Brute', QA + 'Bull.glb', { scale: 1.3, anims: Q_ANIMAL, sounds: HEAVY }),
      c('Horse', 'Runner', QA + 'Horse.glb', { anims: Q_ANIMAL, sounds: SOFT }),
      c('Pale Horse', 'Elite', QA + 'Horse_White.glb', { tint: 0x9ad5ff, anims: Q_ANIMAL, sounds: SOFT }),
      c('Donkey', 'Shielder', QA + 'Donkey.glb', { scale: 1.1, tint: 0x6080c0, anims: Q_ANIMAL, sounds: SOFT }),
      c('Alpaca', 'Healer', QA + 'Alpaca.glb', { tint: 0x80ff9a, anims: Q_ANIMAL, sounds: SOFT }),
      c('Farm Dog', 'Runner', QA + 'ShibaInu.glb', { anims: Q_CANINE, sounds: SOFT }),
    ],
  },
  {
    id: 'frozen', name: 'Frozen Cavern: Kenney Cube Pets', map: 'Frozen Cavern', source: 'Kenney Cube Pets (CC0) + Quaternius Ultimate Animated Animals (CC0)',
    creatures: [
      c('Penguin', 'Runner', PETS + 'animal-penguin.glb', { anims: KENNEY_PET, sounds: { hit: 'impact_soft_medium', death: 'impact_soft_heavy', attack: 'impact_generic_light', step: 'footstep_snow' } }),
      c('Polar Bear', 'Brute', PETS + 'animal-polar.glb', { scale: 1.3, anims: KENNEY_PET, sounds: { hit: 'impact_soft_heavy', death: 'impact_plank_medium', attack: 'impact_punch_heavy', step: 'footstep_snow' } }),
      c('Ice Fish', 'Spitter', PETS + 'animal-fish.glb', { tint: 0xa0e0ff, anims: KENNEY_PET, sounds: { hit: 'impact_glass_light', death: 'impact_glass_medium', attack: 'impact_glass_light', step: 'footstep_snow' } }),
      c('Ice Bomb', 'Exploder', PETS + 'animal-penguin.glb', { scale: 1.1, tint: 0xffa040, anims: KENNEY_PET, sounds: { hit: 'impact_glass_light', death: 'impact_glass_heavy', attack: 'impact_bell_heavy', step: 'footstep_snow' } }),
      c('Stag', 'Elite', PETS + 'animal-deer.glb', { tint: 0x9ad5ff, anims: KENNEY_PET, sounds: { hit: 'impact_soft_medium', death: 'impact_soft_heavy', attack: 'impact_wood_medium', step: 'footstep_snow' } }),
      c('Frost King', 'Boss', PETS + 'animal-polar.glb', { scale: 2.3, tint: 0xff7a5a, anims: KENNEY_PET, sounds: { hit: 'impact_plate_heavy', death: 'impact_bell_heavy', attack: 'impact_metal_heavy', step: 'impact_soft_heavy' } }),
      c('Frost Wolf', 'Runner', QA + 'Wolf.glb', { anims: Q_CANINE, sounds: { ...SOFT, step: 'footstep_snow' } }),
      c('Husky', 'Elite', QA + 'Husky.glb', { tint: 0x9ad5ff, anims: Q_CANINE, sounds: { ...SOFT, step: 'footstep_snow' } }),
      c('Ice Stag', 'Brute', QA + 'Stag.glb', { scale: 1.2, anims: Q_ANIMAL, sounds: { ...HEAVY, step: 'footstep_snow' } }),
      c('Doe', 'Runner', QA + 'Deer.glb', { anims: Q_ANIMAL, sounds: { ...SOFT, step: 'footstep_snow' } }),
      c('Arctic Fox', 'Healer', QA + 'Fox.glb', { tint: 0x80ff9a, anims: Q_CANINE, sounds: { ...SOFT, step: 'footstep_snow' } }),
    ],
  },
  {
    id: 'jungle', name: 'Jungle Temple: Kenney Cube Pets', map: 'Jungle Temple', source: 'Kenney Cube Pets (CC0) + Quaternius Dinosaurs and Platformer Kit (CC0)',
    creatures: [
      c('Monkey', 'Runner', PETS + 'animal-monkey.glb', { anims: KENNEY_PET, sounds: { hit: 'impact_soft_medium', death: 'impact_soft_heavy', attack: 'impact_generic_light', step: 'footstep_grass' } }),
      c('Lion', 'Brute', PETS + 'animal-lion.glb', { scale: 1.3, anims: KENNEY_PET, sounds: { hit: 'impact_soft_heavy', death: 'impact_plank_medium', attack: 'impact_punch_heavy', step: 'footstep_grass' } }),
      c('Giraffe', 'Spitter', PETS + 'animal-giraffe.glb', { anims: KENNEY_PET, sounds: { hit: 'impact_soft_medium', death: 'impact_soft_heavy', attack: 'impact_generic_light', step: 'footstep_grass' } }),
      c('Panda', 'Shielder', PETS + 'animal-panda.glb', { scale: 1.2, tint: 0x6080c0, anims: KENNEY_PET, sounds: { hit: 'impact_wood_medium', death: 'impact_wood_heavy', attack: 'impact_wood_light', step: 'footstep_wood' } }),
      c('Koala', 'Healer', PETS + 'animal-koala.glb', { tint: 0x80ff9a, anims: KENNEY_PET, sounds: { hit: 'impact_soft_medium', death: 'impact_soft_heavy', attack: 'impact_bell_heavy', step: 'footstep_wood' } }),
      c('Tiger', 'Elite', PETS + 'animal-tiger.glb', { tint: 0x9ad5ff, anims: KENNEY_PET, sounds: { hit: 'impact_soft_medium', death: 'impact_soft_heavy', attack: 'impact_punch_medium', step: 'footstep_grass' } }),
      c('Temple Lion', 'Boss', PETS + 'animal-lion.glb', { scale: 2.3, tint: 0xff7a5a, anims: KENNEY_PET, sounds: { hit: 'impact_plate_heavy', death: 'impact_bell_heavy', attack: 'impact_metal_heavy', step: 'impact_soft_heavy' } }),
      c('Raptor', 'Runner', QD + 'Velociraptor.glb', { anims: Q_DINO('Velociraptor'), sounds: SOFT }),
      c('Spitter Para', 'Spitter', QD + 'Parasaurolophus.glb', { anims: Q_DINO('Parasaurolophus'), sounds: SOFT }),
      c('Stego', 'Brute', QD + 'Stegosaurus.glb', { scale: 1.2, anims: Q_DINO('Stegosaurus'), sounds: HEAVY }),
      c('Trike', 'Shielder', QD + 'Triceratops.glb', { scale: 1.2, tint: 0x6080c0, anims: Q_DINO('Triceratops'), sounds: HEAVY }),
      c('Longneck', 'Brute', QD + 'Apatosaurus.glb', { scale: 1.5, anims: { ...Q_DINO('Apatosaurus'), death: 'Stegosaurus_Death' }, sounds: HEAVY }),
      c('Rex', 'Boss', QD + 'Trex.glb', { scale: 1.8, tint: 0xff7a5a, anims: Q_DINO('TRex'), sounds: BIGMETAL }),
      c('Temple Beast', 'Exploder', QP + 'Enemy.glb', { tint: 0xffa040, anims: Q_MONSTER, sounds: { ...SOFT, death: 'impact_bell_heavy' } }),
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
    id: 'invaders', name: 'Factory: Kenney UFOs (flying, static models)', map: 'Factory', source: 'Kenney Tower Defense Kit (CC0) + Quaternius Cyberpunk Kit and Mechs (CC0)',
    creatures: [
      c('Scout UFO', 'Flyer', UFO + 'enemy-ufo-a.glb', { anims: NONE, sounds: { hit: 'impact_metal_light', death: 'impact_metal_heavy', attack: 'impact_generic_light', step: null } }),
      c('Gunship', 'Spitter', UFO + 'enemy-ufo-b-weapon.glb', { anims: NONE, sounds: { hit: 'impact_metal_medium', death: 'impact_metal_heavy', attack: 'impact_tin_medium', step: null } }),
      c('Hauler', 'Brute', UFO + 'enemy-ufo-c.glb', { scale: 1.3, anims: NONE, sounds: { hit: 'impact_metal_medium', death: 'impact_metal_heavy', attack: 'impact_plate_heavy', step: null } }),
      c('Kamikaze', 'Exploder', UFO + 'enemy-ufo-a-weapon.glb', { tint: 0xffa040, anims: NONE, sounds: { hit: 'impact_metal_light', death: 'impact_bell_heavy', attack: 'impact_metal_heavy', step: null } }),
      c('Mothership', 'Boss', UFO + 'enemy-ufo-d-weapon.glb', { scale: 2.5, tint: 0xff5a5a, anims: NONE, sounds: { hit: 'impact_plate_heavy', death: 'impact_bell_heavy', attack: 'impact_metal_heavy', step: null } }),
      c('Walker', 'Runner', QC + 'Enemy_2Legs.glb', { anims: Q_CYBER, sounds: METAL }),
      c('Gun Walker', 'Spitter', QC + 'Enemy_2Legs_Gun.glb', { anims: { ...Q_CYBER, attack: 'Shoot' }, sounds: METAL }),
      c('Hover Drone', 'Flyer', QC + 'Enemy_Flying.glb', { anims: { ...Q_CYBER, death: 'Dead', hit: 'Attack', spawn: 'Idle' }, sounds: { ...METAL, step: null } }),
      c('Gun Drone', 'Spitter', QC + 'Enemy_Flying_Gun.glb', { anims: { ...Q_CYBER, attack: 'Shoot', death: 'Dead', hit: 'Attack', spawn: 'Idle' }, sounds: { ...METAL, step: null } }),
      c('Crusher', 'Brute', QC + 'Enemy_Large.glb', { scale: 1.3, anims: Q_CYBER, sounds: BIGMETAL }),
      c('Siege Unit', 'Boss', QC + 'Enemy_Large_Gun.glb', { scale: 2.0, tint: 0xff5a5a, anims: { ...Q_CYBER, attack: 'Shoot' }, sounds: BIGMETAL }),
      c('Cyber Raider', 'Elite', QC + 'Character.glb', { tint: 0x9ad5ff, anims: { idle: 'Idle_Neutral', walk: 'Walk', run: 'Run', attack: 'Gun_Shoot', hit: 'HitRecieve', death: 'Death', spawn: 'Interact' }, sounds: SOFT }),
      c('Dozer Mech', 'Brute', QM + 'George.glb', { scale: 1.3, anims: Q_MECH, sounds: BIGMETAL }),
      c('Scout Mech', 'Runner', QM + 'Leela.glb', { anims: Q_MECH, sounds: METAL }),
      c('Welder Mech', 'Healer', QM + 'Mike.glb', { tint: 0x80ff9a, anims: Q_MECH, sounds: METAL }),
      c('Riot Mech', 'Shielder', QM + 'Stan.glb', { scale: 1.2, tint: 0x6080c0, anims: Q_MECH, sounds: BIGMETAL }),
    ],
  },
  {
    id: 'aliens', name: 'Space Station: Kenney space aliens and UFOs (static models)', map: 'Space Station', source: 'Kenney Space Kit + Tower Defense Kit (CC0) + Quaternius Ultimate Space Kit (CC0)',
    creatures: [
      c('Alien', 'Runner', '../assets/creatures/kenney-space/alien.glb', { anims: NONE, tint: 0x80ff9a, sounds: { hit: 'impact_soft_medium', death: 'impact_glass_heavy', attack: 'impact_generic_light', step: null } }),
      c('Drone', 'Flyer', UFO + 'enemy-ufo-a.glb', { scale: 0.8, anims: NONE, sounds: { hit: 'impact_metal_light', death: 'impact_metal_heavy', attack: 'impact_generic_light', step: null } }),
      c('Lancer', 'Spitter', UFO + 'enemy-ufo-c-weapon.glb', { anims: NONE, sounds: { hit: 'impact_metal_medium', death: 'impact_metal_heavy', attack: 'impact_tin_medium', step: null } }),
      c('Bulwark', 'Shielder', UFO + 'enemy-ufo-d.glb', { scale: 1.3, tint: 0x6080c0, anims: NONE, sounds: { hit: 'impact_plate_heavy', death: 'impact_metal_heavy', attack: 'impact_plate_medium', step: null } }),
      c('Hive Alien', 'Boss', '../assets/creatures/kenney-space/alien.glb', { scale: 2.6, tint: 0xff5a5a, anims: NONE, sounds: { hit: 'impact_plate_heavy', death: 'impact_bell_heavy', attack: 'impact_metal_heavy', step: null } }),
      c('Spore', 'Flyer', QS + 'Enemy_ExtraSmall.glb', { anims: Q_SPACE_FLYER, sounds: { ...SOFT, step: null } }),
      c('Floater', 'Flyer', QS + 'Enemy_Small.glb', { anims: Q_SPACE_FLYER, sounds: { ...SOFT, step: null } }),
      c('Stinger', 'Flyer', QS + 'Enemy_Flying.glb', { scale: 1.2, anims: Q_SPACE_FLYER, sounds: { ...SOFT, step: null } }),
      c('Brood Alien', 'Brute', QS + 'Enemy_Large.glb', { scale: 1.3, anims: Q_SPACE_CHAR, sounds: HEAVY }),
      c('Rogue Bee', 'Runner', QS + 'Astronaut_BarbaraTheBee.glb', { anims: Q_SPACE_CHAR, sounds: SOFT }),
      c('Rogue Flamingo', 'Spitter', QS + 'Astronaut_FernandoTheFlamingo.glb', { anims: { ...Q_SPACE_CHAR, attack: 'Run_Gun_Shoot', idle: 'Idle_Gun' }, sounds: SOFT }),
      c('Rogue Frog', 'Healer', QS + 'Astronaut_FinnTheFrog.glb', { tint: 0x80ff9a, anims: Q_SPACE_CHAR, sounds: SOFT }),
      c('Rogue Panda', 'Elite', QS + 'Astronaut_RaeTheRedPanda.glb', { tint: 0x9ad5ff, anims: Q_SPACE_CHAR, sounds: SOFT }),
      c('Bee Mech', 'Shielder', QS + 'Mech_BarbaraTheBee.glb', { scale: 1.2, tint: 0x6080c0, anims: Q_SPACE_MECH, sounds: BIGMETAL }),
      c('Flamingo Mech', 'Spitter', QS + 'Mech_FernandoTheFlamingo.glb', { anims: Q_SPACE_MECH, sounds: METAL }),
      c('Frog Mech', 'Brute', QS + 'Mech_FinnTheFrog.glb', { scale: 1.3, anims: { ...Q_SPACE_MECH, attack: 'Kick' }, sounds: BIGMETAL }),
      c('Panda Mech', 'Boss', QS + 'Mech_RaeTheRedPanda.glb', { scale: 2.0, tint: 0xff5a5a, anims: Q_SPACE_MECH, sounds: BIGMETAL }),
    ],
  },
];

// Variants pad every family to MIN_PER_FAMILY creatures. A variant reuses a base model with a
// prefix, a tint, a scale and a stat twist, so it is a placeholder for a distinct model later:
// the game can ship with recolors, but each one is a candidate for its own model or accessory.
export const MIN_PER_FAMILY = 20;
const VARIANTS = [
  { prefix: 'Feral',    tint: 0xffd060, scale: 0.95, stats: { speed: 1.25, coins: 1.1 },  note: 'faster' },
  { prefix: 'Armored',  tint: 0xb0b8c8, scale: 1.1,  stats: { health: 1.6, speed: 0.85, coins: 1.3 }, note: 'tougher, slower' },
  { prefix: 'Shadow',   tint: 0x6040a0, scale: 1.0,  stats: { damage: 1.3, coins: 1.4 },  note: 'hits harder' },
  { prefix: 'Giant',    tint: 0xff9060, scale: 1.4,  stats: { health: 2.2, speed: 0.75, damage: 1.5, coins: 1.8 }, note: 'much bigger' },
  { prefix: 'Plagued',  tint: 0x80d040, scale: 1.0,  stats: { health: 0.8, coins: 1.2 },  note: 'leaves a slow pool on death' },
  { prefix: 'Burning',  tint: 0xff5020, scale: 1.0,  stats: { damage: 1.2, coins: 1.3 },  note: 'ignites floor spells' },
];

function expandFamily(f) {
  const base = f.creatures.slice();
  let v = 0;
  while (f.creatures.length < MIN_PER_FAMILY && base.length) {
    const src = base[v % base.length];
    const variant = VARIANTS[Math.floor(v / base.length) % VARIANTS.length];
    if (src.type !== 'Boss') {
      f.creatures.push({ ...src, id: `${variant.prefix} ${src.id}`, tint: variant.tint, scale: src.scale * variant.scale,
        variantOf: src.id, variant });
    }
    v++;
    if (v > base.length * VARIANTS.length) break;
  }
}

// Fill in stats and blurb from the archetype table so each family only states what differs.
for (const f of FAMILIES) {
  expandFamily(f);
  for (const cr of f.creatures) {
    const a = ARCHETYPES[cr.type];
    const m = cr.variant?.stats ?? {};
    cr.stats = {
      health: Math.round(a.health * (m.health ?? 1)), speed: Math.round(a.speed * (m.speed ?? 1)),
      damage: Math.round(a.damage * (m.damage ?? 1)), coins: Math.round(a.coins * (m.coins ?? 1)), firstWave: a.firstWave + (cr.variant ? 4 : 0),
    };
    cr.blurb = cr.variant ? `${cr.type} variant of ${cr.variantOf}: ${cr.variant.note}.` : `${cr.type}. ${a.blurb}`;
    cr.source = f.source;
  }
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

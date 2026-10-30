// Hand-written catalog for animated things and classes. Props and weapons are listed automatically
// in files.json (scripts/showcase-index.py). Stats mirror src/shared/Enemies.luau.

const KAYKIT = '../assets/creatures/kaykit-skeletons/';
const KENNEY = '../assets/creatures/kenney-graveyard/';
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
const QF = '../assets/creatures/quaternius-cute-fish/';
const KKB = '../assets/creatures/kaykit-bandits/';
const MINIC = '../assets/creatures/kenney-mini-characters/';

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
const KENNEY_CHAR = { idle: 'idle', walk: 'walk', run: 'sprint', attack: 'attack-melee-right', hit: 'emote-no', death: 'die', spawn: 'idle' };
const KENNEY_PET = { idle: 'idle', walk: 'walk', run: 'run', attack: 'eat', hit: 'gesture-negative', death: 'static', spawn: 'gesture-positive' };
const KENNEY_MINI = { idle: 'idle', walk: 'walk', run: 'sprint', attack: 'attack-melee-right', hit: 'emote-no', death: 'die', spawn: 'jump' };
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
const Q_PLAT_GUN = { idle: 'Idle_Gun', walk: 'Walk_Gun', run: 'Run_Gun', attack: 'Idle_Shoot', hit: 'HitReact', death: 'Death', spawn: 'Wave' };
const Q_FISH = { idle: 'Swimming_Normal', walk: 'Swimming_Normal', run: 'Swimming_Fast', attack: 'Attack', hit: 'Swimming_Impulse', death: 'Death', spawn: 'Out_Of_Water' };
const SOFT = { hit: 'impact_soft_medium', death: 'impact_soft_heavy', attack: 'impact_punch_medium', step: 'footstep_grass' };
const HEAVY = { hit: 'impact_soft_heavy', death: 'impact_plank_medium', attack: 'impact_punch_heavy', step: 'impact_soft_heavy' };
const METAL = { hit: 'impact_metal_medium', death: 'impact_metal_heavy', attack: 'impact_tin_medium', step: 'footstep_concrete' };
const BIGMETAL = { hit: 'impact_plate_heavy', death: 'impact_bell_heavy', attack: 'impact_metal_heavy', step: 'impact_plate_medium' };

const c = (id, type, model, extra = {}) => ({ id, type, model, scale: 1, tint: null, anims: KENNEY_CHAR,
  sounds: { hit: 'impact_punch_medium', death: 'impact_soft_heavy', attack: 'impact_generic_light', step: 'footstep_grass' }, ...extra });

const QU = '../assets/creatures/quaternius-monsters/';
const QCU = '../assets/creatures/quaternius-cute-monsters/';
const MINI = '../assets/creatures/kenney-mini-dungeon/';
const Q_BIG = { idle: 'Idle', walk: 'Walk', run: 'Run', attack: 'Punch', hit: 'HitReact', death: 'Death', spawn: 'Wave' };
const Q_BLOB = { idle: 'Idle', walk: 'Walk', run: 'Walk', attack: 'Bite_Front', hit: 'HitRecieve', death: 'Death', spawn: 'Jump' };
const Q_CUTE = { ...Q_BLOB, attack: 'Bite_InPlace' };
const Q_CUTE_FLY = { idle: 'Flying', walk: 'Flying', run: 'Flying', attack: 'Bite_Front', hit: 'HitRecieve', death: 'Death', spawn: 'Flying' };
const Q_FLY = Q_SPACE_FLYER;
const QAM = '../assets/creatures/quaternius-animated-monsters/';
const QAL = '../assets/creatures/quaternius-alien/';
const QZ = '../assets/creatures/quaternius-zombie/';
const Q_SKEL = { idle: 'Skeleton_Idle', walk: 'Skeleton_Running', run: 'Skeleton_Running', attack: 'Skeleton_Attack', hit: 'Skeleton_Attack', death: 'Skeleton_Death', spawn: 'Skeleton_Spawn' };
const Q_WING = n => ({ idle: `${n}_Flying`, walk: `${n}_Flying`, run: `${n}_Flying`, attack: `${n}_Attack`, hit: `${n}_Hit`, death: `${n}_Death`, spawn: `${n}_Flying` });
const Q_SLIME = { idle: 'Slime_Idle', walk: 'Slime_Walk', run: 'Slime_Walk', attack: 'Slime_Attack', hit: 'Slime_Idle', death: 'Slime_Death', spawn: 'Slime_Idle' };
const Q_ZOMBIE = { idle: 'ZombieIdle', walk: 'ZombieWalk', run: 'ZombieRun', attack: 'ZombieBite', hit: 'ZombieIdle', death: 'ZombieCrawl', spawn: 'ZombieIdle' };
const Q_ALIEN = { idle: 'Alien_Idle', walk: 'Alien_Walk', run: 'Alien_Run', attack: 'Alien_Punch', hit: 'Alien_Jump', death: 'Alien_Death', spawn: 'Alien_Standing' };
const SK = (idle, walk, run, attack, hit, death, spawn) => ({ idle, walk, run, attack, hit, death, spawn });
const GLASS = { hit: 'impact_glass_light', death: 'impact_glass_heavy', attack: 'impact_generic_light', step: 'footstep_snow' };
const BONE = { hit: 'impact_wood_light', death: 'impact_wood_heavy', attack: 'impact_generic_light', step: 'footstep_concrete' };
const WOOD = { hit: 'impact_wood_medium', death: 'impact_wood_heavy', attack: 'impact_wood_light', step: 'footstep_wood' };
const SNOW = { ...SOFT, step: 'footstep_snow' };
const FLY = { ...SOFT, step: null };
const BOOM = { ...SOFT, death: 'impact_bell_heavy' };

// One family per dungeon. Every entry is a distinct model (no recolors): the wave list introduces one
// new creature per wave, bosses on waves 5, 10, ... Order inside a family is the order they appear.
export const FAMILIES = [
  {
    id: 'graveyard', name: 'Graveyard', map: 'Graveyard', source: 'KayKit Skeletons, Kenney Graveyard Kit, Quaternius Ultimate + Cute Monsters (all CC0)',
    creatures: [
      c('Zombie', 'Runner', KENNEY + 'character-zombie.glb', { sounds: SOFT }),
      c('Minion', 'Runner', KAYKIT + 'Skeleton_Minion.glb', { anims: SK('Idle', 'Walking_A', 'Running_A', 'Unarmed_Melee_Attack_Punch_A', 'Hit_A', 'Death_A', 'Spawn_Ground_Skeletons'), sounds: BONE }),
      c('Skull Hopper', 'Runner', QCU + 'Skull.glb', { anims: Q_CUTE, sounds: BONE }),
      c('Bat', 'Flyer', QCU + 'Bat.glb', { anims: Q_CUTE_FLY, sounds: FLY }),
      c('Keeper', 'Boss', KENNEY + 'character-keeper.glb', { scale: 2.0, sounds: BIGMETAL }),
      c('S-Ghost', 'Spitter', KENNEY + 'character-ghost.glb', { sounds: GLASS }),
      c('Rogue', 'Elite', KAYKIT + 'Skeleton_Rogue.glb', { anims: SK('Idle_Combat', 'Walking_D_Skeletons', 'Running_Strafe_Left', 'Dualwield_Melee_Attack_Slice', 'Hit_B', 'Death_A', 'Skeletons_Awaken_Floor'), sounds: BONE }),
      c('Warrior', 'Brute', KAYKIT + 'Skeleton_Warrior.glb', { scale: 1.3, anims: SK('2H_Melee_Idle', 'Walking_B', 'Running_B', '2H_Melee_Attack_Chop', 'Hit_B', 'Death_B', 'Skeletons_Awaken_Standing'), sounds: BONE }),
      c('Mage', 'Spitter', KAYKIT + 'Skeleton_Mage.glb', { anims: SK('Idle_B', 'Walking_C', 'Running_C', 'Spellcast_Shoot', 'Hit_A', 'Death_C_Skeletons', 'Spawn_Air'), sounds: BONE }),
      c('Bone Dragon', 'Boss', QU + 'Flying_Dragon_Evolved.glb', { scale: 1.8, anims: Q_FLY, sounds: BIGMETAL }),
      c('Skeleton', 'Runner', KENNEY + 'character-skeleton.glb', { sounds: BONE }),
      c('Poltergeist', 'Healer', QCU + 'Ghost.glb', { anims: Q_CUTE, sounds: GLASS }),
      c('Wraith', 'Flyer', QU + 'Flying_Ghost.glb', { anims: Q_FLY, sounds: GLASS }),
      c('Vampire', 'Brute', KENNEY + 'character-vampire.glb', { scale: 1.15, sounds: { ...SOFT, death: 'impact_bell_heavy' } }),
      c('Imp', 'Exploder', QCU + 'Demon.glb', { anims: Q_CUTE, sounds: BOOM }),
      c('Skull Wraith', 'Flyer', QU + 'Flying_Ghost_Skull.glb', { anims: Q_FLY, sounds: GLASS }),
      c('Orc Skull', 'Shielder', QU + 'Big_Orc_Skull.glb', { scale: 1.2, anims: Q_BIG, sounds: HEAVY }),
      c('Blue Demon', 'Brute', QU + 'Big_BlueDemon.glb', { scale: 1.3, anims: Q_BIG, sounds: HEAVY }),
      c('Necromancer', 'Healer', QU + 'Blob_Wizard.glb', { anims: Q_BLOB, sounds: GLASS }),
      c('Hell Demon', 'Elite', QU + 'Big_Demon.glb', { scale: 1.2, anims: Q_BIG, sounds: HEAVY }),
      c('Bone Walker', 'Runner', QAM + 'Skeleton.glb', { anims: Q_SKEL, sounds: BONE }),
    ],
  },
  {
    id: 'farm', name: 'Haunted Farm', map: 'Haunted Farm', source: 'Quaternius Animals + Ultimate + Cute Monsters (all CC0)',
    creatures: [
      c('Chicken', 'Runner', QCU + 'Chicken.glb', { anims: Q_CUTE, sounds: SOFT }),
      c('Piglet', 'Runner', QCU + 'Pig.glb', { anims: Q_CUTE, sounds: SOFT }),
      c('Bomb Hen', 'Exploder', QU + 'Blob_Chicken.glb', { anims: Q_BLOB, sounds: BOOM }),
      c('Farm Dog', 'Runner', QA + 'ShibaInu.glb', { anims: Q_CANINE, sounds: SOFT }),
      c('Mutt', 'Elite', QU + 'Blob_Dog.glb', { anims: Q_BLOB, sounds: SOFT }),
      c('Monkroose', 'Boss', QU + 'Big_Monkroose.glb', { scale: 2.0, anims: Q_BIG, sounds: BIGMETAL }),
      c('Alley Cat', 'Elite', QU + 'Blob_Cat.glb', { anims: Q_BLOB, sounds: SOFT }),
      c('Pigeon', 'Flyer', QU + 'Flying_Pigeon.glb', { anims: Q_FLY, sounds: FLY }),
      c('Fat Pigeon', 'Runner', QU + 'Blob_Pigeon.glb', { anims: Q_BLOB, sounds: SOFT }),
      c('Horse', 'Runner', QA + 'Horse.glb', { anims: Q_ANIMAL, sounds: SOFT }),
      c('Pale Horse', 'Elite', QA + 'Horse_White.glb', { anims: Q_ANIMAL, sounds: SOFT }),
      c('Donkey', 'Shielder', QA + 'Donkey.glb', { scale: 1.1, anims: Q_ANIMAL, sounds: SOFT }),
      c('Alpaca', 'Healer', QA + 'Alpaca.glb', { anims: Q_ANIMAL, sounds: SOFT }),
      c('Cow', 'Brute', QA + 'Cow.glb', { scale: 1.2, anims: Q_ANIMAL, sounds: HEAVY }),
      c('Bull', 'Brute', QA + 'Bull.glb', { scale: 1.3, anims: Q_ANIMAL, sounds: HEAVY }),
      c('Scarecrow Tree', 'Shielder', QCU + 'Tree.glb', { scale: 1.2, anims: { ...Q_CUTE, hit: 'HitRecieve', death: 'HitRecieve' }, sounds: WOOD }),
    ],
  },
  {
    id: 'swamp', name: 'Swamp', map: 'Swamp', source: 'Quaternius Easy Enemies + Platformer Kit + Cute Fish + Ultimate + Cute Monsters (all CC0)',
    creatures: [
      c('Piranha', 'Runner', QF + 'Piranha.glb', { scale: 0.7, anims: Q_FISH, sounds: SOFT }),
      c('Bog Frog', 'Runner', QE + 'Frog.glb', { anims: Q_EASY('Frog', 'Frog_Jump', 'Frog_Jump'), sounds: SOFT }),
      c('Marsh Rat', 'Runner', QE + 'Rat.glb', { anims: Q_EASY('Rat'), sounds: SOFT }),
      c('Swamp Snake', 'Spitter', QE + 'Snake.glb', { anims: { ...Q_EASY('Snake', 'Snake_Walk', 'Snake_Walk'), death: 'Snake_Jump' }, sounds: SOFT }),
      c('Mushroom King', 'Boss', QU + 'Big_MushroomKing.glb', { scale: 2.0, anims: Q_BIG, sounds: BIGMETAL }),
      c('Viper', 'Elite', QE + 'Snake_angry.glb', { anims: { ...Q_EASY('Snake', 'Snake_Walk', 'Snake_Walk'), death: 'Snake_Jump' }, sounds: SOFT }),
      c('Bog Spider', 'Brute', QE + 'Spider.glb', { scale: 1.3, anims: Q_EASY('Spider', 'Spider_Walk', 'Spider_Walk'), sounds: SOFT }),
      c('Hornet', 'Flyer', QE + 'Wasp.glb', { anims: { ...Q_EASY('Wasp', 'Wasp_Flying', 'Wasp_Flying'), idle: 'Wasp_Flying', hit: 'Wasp_Attack', spawn: 'Wasp_Flying' }, sounds: FLY }),
      c('Bomb Bee', 'Exploder', QP + 'Bee.glb', { anims: Q_CUTE_FLY, sounds: BOOM }),
      c('Toad King', 'Boss', QU + 'Big_Frog.glb', { scale: 2.0, anims: Q_BIG, sounds: BIGMETAL }),
      c('Crab', 'Spitter', QP + 'Crab.glb', { anims: Q_CUTE, sounds: { ...SOFT, hit: 'impact_plate_light' } }),
      c('Bog Fish', 'Runner', QU + 'Big_Fish.glb', { anims: Q_BIG, sounds: SOFT }),
      c('Shroomling', 'Healer', QCU + 'Mushroom.glb', { anims: Q_CUTE, sounds: SOFT }),
      c('Mushnub', 'Runner', QU + 'Blob_Mushnub.glb', { anims: Q_BLOB, sounds: SOFT }),
      c('Mushnub Evolved', 'Elite', QU + 'Blob_Mushnub_Evolved.glb', { anims: Q_BLOB, sounds: SOFT }),
      c('Spiky Blob', 'Exploder', QU + 'Blob_GreenSpikyBlob.glb', { anims: Q_BLOB, sounds: BOOM }),
      c('Glub', 'Flyer', QU + 'Flying_Glub.glb', { anims: Q_FLY, sounds: FLY }),
    ],
  },
  {
    id: 'sewer', name: 'Sewer', map: 'Sewer', source: 'Kenney Platformer Kit blobs, Quaternius Ultimate Monsters + Platformer Kit (all CC0)',
    creatures: [
      c('Oozi', 'Runner', BLOBS + 'character-oozi.glb', { sounds: { ...SOFT, step: 'footstep_carpet' } }),
      c('Green Blob', 'Runner', QU + 'Blob_GreenBlob.glb', { anims: Q_BLOB, sounds: SOFT }),
      c('Oodi', 'Spitter', BLOBS + 'character-oodi.glb', { sounds: SOFT }),
      c('Sewer Grub', 'Spitter', QU + 'Blob_Alien.glb', { anims: Q_BLOB, sounds: SOFT }),
      c('Cyclops', 'Boss', QCU + 'Cyclops.glb', { scale: 2.0, anims: Q_CUTE, sounds: BIGMETAL }),
      c('Ooli', 'Exploder', BLOBS + 'character-ooli.glb', { sounds: BOOM }),
      c('Oobi', 'Brute', BLOBS + 'character-oobi.glb', { scale: 1.5, sounds: HEAVY }),
      c('Pink Blob', 'Healer', QU + 'Blob_PinkBlob.glb', { anims: Q_BLOB, sounds: SOFT }),
      c('Drain Fish', 'Runner', QU + 'Blob_Fish.glb', { anims: Q_BLOB, sounds: SOFT }),
      c('Mutant Bunny', 'Boss', QU + 'Big_Bunny.glb', { scale: 2.0, anims: Q_BIG, sounds: BIGMETAL }),
      c('Oopi', 'Healer', BLOBS + 'character-oopi.glb', { sounds: SOFT }),
      c('Sewer Beast', 'Brute', QP + 'Enemy.glb', { scale: 1.3, anims: Q_MONSTER, sounds: HEAVY }),
      c('Glub Evolved', 'Elite', QU + 'Flying_Glub_Evolved.glb', { anims: Q_FLY, sounds: FLY }),
      c('Drain Birb', 'Flyer', QU + 'Blob_Birb.glb', { anims: Q_BLOB, sounds: FLY }),
      c('Slime', 'Runner', QAM + 'Slime.glb', { anims: Q_SLIME, sounds: { ...SOFT, step: 'footstep_carpet' } }),
      c('Sewer Bat', 'Flyer', QAM + 'Bat.glb', { anims: Q_WING('Bat'), sounds: FLY }),
    ],
  },
  {
    id: 'village', name: 'Bandit Village', map: 'Bandit Village', source: 'KayKit Adventurers (enemy variants), Kenney Mini Characters + Mini Dungeon, Quaternius Ultimate + Cute Monsters (all CC0)',
    creatures: [
      c('Footpad', 'Runner', KKB + 'Rogue.glb', { anims: SK('Idle', 'Walking_A', 'Running_A', 'Dualwield_Melee_Attack_Slice', 'Hit_A', 'Death_A', 'Dodge_Forward'), sounds: SOFT }),
      c('Cutpurse', 'Runner', MINIC + 'character-female-a.glb', { scale: 4, anims: KENNEY_MINI, sounds: SOFT }),
      c('Crossbowman', 'Spitter', KKB + 'Rogue_Hooded.glb', { anims: SK('2H_Ranged_Aiming', 'Walking_B', 'Running_B', '2H_Ranged_Shoot', 'Hit_B', 'Death_B', 'Jump_Land'), sounds: { ...SOFT, attack: 'impact_wood_light' } }),
      c('Powder Thief', 'Exploder', MINIC + 'character-male-b.glb', { scale: 4, anims: KENNEY_MINI, sounds: BOOM }),
      c('Green Demon', 'Boss', QCU + 'GreenDemon.glb', { scale: 2.0, anims: Q_CUTE, sounds: BIGMETAL }),
      c('Shield Thug', 'Shielder', MINIC + 'character-female-f.glb', { scale: 4.4, anims: { ...KENNEY_MINI, attack: 'attack-kick-right' }, sounds: { ...SOFT, hit: 'impact_plate_medium' } }),
      c('Quack', 'Healer', KKB + 'Mage.glb', { anims: SK('Idle', 'Walking_A', 'Running_B', 'Spellcast_Raise', 'Hit_A', 'Death_B', 'Spellcast_Long'), sounds: SOFT }),
      c('Bruiser', 'Brute', KKB + 'Barbarian.glb', { scale: 1.25, anims: SK('2H_Melee_Idle', 'Walking_B', 'Running_B', '2H_Melee_Attack_Spin', 'Hit_B', 'Death_A', 'Cheer'), sounds: HEAVY }),
      c('Mercenary', 'Runner', MINI + 'character-human.glb'),
      c('Bandit King', 'Boss', KKB + 'Knight.glb', { scale: 1.9, anims: SK('Blocking', 'Walking_C', 'Running_A', 'Block_Attack', 'Block_Hit', 'Death_A', 'Cheer'), sounds: BIGMETAL }),
      c('Orc', 'Brute', MINI + 'character-orc.glb', { scale: 1.3, sounds: HEAVY }),
      c('Orc Chief', 'Brute', QU + 'Big_Orc.glb', { scale: 1.4, anims: Q_BIG, sounds: HEAVY }),
      c('Orc Runt', 'Runner', QU + 'Blob_Orc.glb', { anims: Q_BLOB, sounds: SOFT }),
      c('Ninja', 'Elite', QU + 'Big_Ninja.glb', { anims: Q_BIG, sounds: SOFT }),
      c('Ninja Runt', 'Runner', QU + 'Blob_Ninja.glb', { anims: Q_BLOB, sounds: SOFT }),
      c('Tribal', 'Spitter', QU + 'Big_Tribal.glb', { anims: Q_BIG, sounds: SOFT }),
      c('Tribal Flyer', 'Flyer', QU + 'Flying_Tribal.glb', { anims: Q_FLY, sounds: FLY }),
      c('Cactoro', 'Shielder', QU + 'Big_Cactoro.glb', { scale: 1.2, anims: Q_BIG, sounds: WOOD }),
      c('Cactoro Runt', 'Runner', QU + 'Blob_Cactoro.glb', { anims: Q_BLOB, sounds: WOOD }),
      c('Lieutenant', 'Elite', MINIC + 'character-male-c.glb', { scale: 4, anims: KENNEY_MINI, sounds: SOFT }),
    ],
  },
  {
    id: 'frozen', name: 'Frozen Cavern', map: 'Frozen Cavern', source: 'Quaternius Animals + Cute Fish + Ultimate + Cute Monsters (all CC0)',
    creatures: [
      c('Puffin', 'Runner', QCU + 'Penguin.glb', { anims: Q_CUTE, sounds: SNOW }),
      c('Frost Wolf', 'Runner', QA + 'Wolf.glb', { anims: Q_CANINE, sounds: SNOW }),
      c('Ice Fish', 'Spitter', QF + 'BlueTang.glb', { scale: 0.6, anims: Q_FISH, sounds: GLASS }),
      c('Yeti', 'Boss', QU + 'Big_Yeti.glb', { scale: 2.0, anims: Q_BIG, sounds: BIGMETAL }),
      c('Husky', 'Elite', QA + 'Husky.glb', { anims: Q_CANINE, sounds: SNOW }),
      c('Doe', 'Runner', QA + 'Deer.glb', { anims: Q_ANIMAL, sounds: SNOW }),
      c('Arctic Fox', 'Spitter', QA + 'Fox.glb', { anims: Q_CANINE, sounds: SNOW }),
      c('Frost Dragon', 'Boss', QU + 'Flying_Dragon.glb', { scale: 1.8, anims: Q_FLY, sounds: BIGMETAL }),
      c('Ice Stag', 'Brute', QA + 'Stag.glb', { scale: 1.2, anims: Q_ANIMAL, sounds: HEAVY }),
      c('Reindeer', 'Healer', QCU + 'Deer.glb', { anims: Q_CUTE, sounds: SNOW }),
      c('Yeti Cub', 'Runner', QU + 'Blob_Yeti.glb', { anims: Q_BLOB, sounds: SNOW }),
      c('Young Yeti', 'Brute', QCU + 'Yeti.glb', { scale: 1.2, anims: Q_CUTE, sounds: HEAVY }),
      c('Alpaking', 'Flyer', QU + 'Flying_Alpaking.glb', { anims: Q_FLY, sounds: FLY }),
      c('Alpaking Evolved', 'Flyer', QU + 'Flying_Alpaking_Evolved.glb', { scale: 1.2, anims: Q_FLY, sounds: FLY }),
      c('Snow Birb', 'Shielder', QU + 'Big_Birb.glb', { scale: 1.2, anims: Q_BIG, sounds: SNOW }),
      c('Hywirl', 'Elite', QU + 'Flying_Hywirl.glb', { anims: Q_FLY, sounds: GLASS }),
    ],
  },
  {
    id: 'jungle', name: 'Jungle Temple', map: 'Jungle Temple', source: 'Quaternius Dinosaurs + Ultimate + Cute Monsters (all CC0)',
    creatures: [
      c('Raptor', 'Runner', QD + 'Velociraptor.glb', { anims: Q_DINO('Velociraptor'), sounds: SOFT }),
      c('Rex', 'Boss', QD + 'Trex.glb', { scale: 1.8, anims: Q_DINO('TRex'), sounds: BIGMETAL }),
      c('Para', 'Spitter', QD + 'Parasaurolophus.glb', { anims: Q_DINO('Parasaurolophus'), sounds: SOFT }),
      c('Yellow Dragon', 'Boss', QCU + 'YellowDragon.glb', { scale: 1.8, anims: Q_CUTE_FLY, sounds: BIGMETAL }),
      c('Stego', 'Brute', QD + 'Stegosaurus.glb', { scale: 1.2, anims: Q_DINO('Stegosaurus'), sounds: HEAVY }),
      c('Trike', 'Shielder', QD + 'Triceratops.glb', { scale: 1.2, anims: Q_DINO('Triceratops'), sounds: HEAVY }),
      c('Longneck', 'Brute', QD + 'Apatosaurus.glb', { scale: 1.5, anims: { ...Q_DINO('Apatosaurus'), death: 'Stegosaurus_Death' }, sounds: HEAVY }),
      c('Dino', 'Runner', QU + 'Big_Dino.glb', { anims: Q_BIG, sounds: SOFT }),
      c('Red Panda', 'Healer', QCU + 'Panda.glb', { anims: Q_CUTE, sounds: SOFT }),
      c('Cactus', 'Exploder', QCU + 'Cactus.glb', { anims: Q_CUTE, sounds: BOOM }),
      c('Armabee', 'Flyer', QU + 'Flying_Armabee.glb', { anims: Q_FLY, sounds: FLY }),
      c('Armabee Evolved', 'Flyer', QU + 'Flying_Armabee_Evolved.glb', { scale: 1.2, anims: Q_FLY, sounds: FLY }),
      c('Jungle Bee', 'Flyer', QCU + 'Bee.glb', { anims: Q_CUTE_FLY, sounds: FLY }),
    ],
  },
  {
    id: 'pirate', name: 'Pirate Cove', map: 'Pirate Cove', source: 'Kenney Mini Characters, Quaternius Platformer Kit + Cute Fish + Ultimate + Cute Monsters (all CC0)',
    creatures: [
      c('Deckhand', 'Runner', MINIC + 'character-male-d.glb', { scale: 4, anims: KENNEY_MINI, sounds: { ...SOFT, step: 'footstep_wood' } }),
      c('Swabbie', 'Runner', MINIC + 'character-female-b.glb', { scale: 4, anims: KENNEY_MINI, sounds: { ...SOFT, step: 'footstep_wood' } }),
      c('Gunner', 'Spitter', QP + 'Character_Gun.glb', { scale: 0.7, anims: Q_PLAT_GUN, sounds: { ...SOFT, attack: 'impact_metal_medium' } }),
      c('Powder Monkey', 'Exploder', MINIC + 'character-male-e.glb', { scale: 4, anims: KENNEY_MINI, sounds: BOOM }),
      c('Kraken', 'Boss', QU + 'Flying_Squidle.glb', { scale: 2.2, anims: Q_FLY, sounds: BIGMETAL }),
      c('Boatswain', 'Shielder', MINIC + 'character-male-f.glb', { scale: 4.4, anims: KENNEY_MINI, sounds: { ...SOFT, hit: 'impact_plate_medium' } }),
      c('Surgeon', 'Healer', MINIC + 'character-female-c.glb', { scale: 4, anims: KENNEY_MINI, sounds: SOFT }),
      c('First Mate', 'Brute', MINIC + 'character-male-a.glb', { scale: 5, anims: KENNEY_MINI, sounds: HEAVY }),
      c('Swordfish', 'Flyer', QF + 'Swordfish.glb', { scale: 0.5, anims: Q_FISH, sounds: FLY }),
      c('Deep One', 'Boss', QCU + 'Cthulhu.glb', { scale: 2.0, anims: Q_CUTE_FLY, sounds: BIGMETAL }),
      c('Lookout', 'Runner', MINIC + 'character-female-d.glb', { scale: 4, anims: KENNEY_MINI, sounds: SOFT }),
      c('Quartermaster', 'Elite', MINIC + 'character-female-e.glb', { scale: 4, anims: KENNEY_MINI, sounds: SOFT }),
      c('Reef Crab', 'Brute', QCU + 'Crab.glb', { scale: 1.3, anims: Q_CUTE, sounds: { ...HEAVY, hit: 'impact_plate_medium' } }),
      c('Sea Dragon', 'Boss', QAM + 'Dragon.glb', { scale: 2.0, anims: Q_WING('Dragon'), sounds: BIGMETAL }),
    ],
  },
  {
    id: 'factory', name: 'Factory', map: 'Factory', source: 'Quaternius Cyberpunk Kit + Mechs + Ultimate Monsters, Kenney Tower Defense UFOs (static) (all CC0)',
    creatures: [
      c('Walker', 'Runner', QC + 'Enemy_2Legs.glb', { anims: Q_CYBER, sounds: METAL }),
      c('Scout Mech', 'Runner', QM + 'Leela.glb', { anims: Q_MECH, sounds: METAL }),
      c('Gun Walker', 'Spitter', QC + 'Enemy_2Legs_Gun.glb', { anims: { ...Q_CYBER, attack: 'Shoot' }, sounds: METAL }),
      c('Hover Drone', 'Flyer', QC + 'Enemy_Flying.glb', { anims: { ...Q_CYBER, death: 'Dead', hit: 'Attack', spawn: 'Idle' }, sounds: { ...METAL, step: null } }),
      c('Siege Unit', 'Boss', QC + 'Enemy_Large_Gun.glb', { scale: 2.0, anims: { ...Q_CYBER, attack: 'Shoot' }, sounds: BIGMETAL }),
      c('Scout UFO', 'Flyer', UFO + 'enemy-ufo-a.glb', { anims: NONE, sounds: { ...METAL, step: null } }),
      c('Gun Drone', 'Spitter', QC + 'Enemy_Flying_Gun.glb', { anims: { ...Q_CYBER, attack: 'Shoot', death: 'Dead', hit: 'Attack', spawn: 'Idle' }, sounds: { ...METAL, step: null } }),
      c('Crusher', 'Brute', QC + 'Enemy_Large.glb', { scale: 1.3, anims: Q_CYBER, sounds: BIGMETAL }),
      c('Welder Mech', 'Healer', QM + 'Mike.glb', { anims: Q_MECH, sounds: METAL }),
      c('Dozer Mech', 'Boss', QM + 'George.glb', { scale: 2.0, anims: Q_MECH, sounds: BIGMETAL }),
      c('Riot Mech', 'Shielder', QM + 'Stan.glb', { scale: 1.2, anims: Q_MECH, sounds: BIGMETAL }),
      c('Cyber Raider', 'Elite', QC + 'Character.glb', { anims: { idle: 'Idle_Neutral', walk: 'Walk', run: 'Run', attack: 'Gun_Shoot', hit: 'HitRecieve', death: 'Death', spawn: 'Interact' }, sounds: SOFT }),
      c('Gunship', 'Spitter', UFO + 'enemy-ufo-b-weapon.glb', { anims: NONE, sounds: { ...METAL, step: null } }),
      c('Hauler', 'Brute', UFO + 'enemy-ufo-c.glb', { scale: 1.3, anims: NONE, sounds: { ...BIGMETAL, step: null } }),
      c('Kamikaze', 'Exploder', UFO + 'enemy-ufo-a-weapon.glb', { anims: NONE, sounds: { ...METAL, death: 'impact_bell_heavy', step: null } }),
      c('Lancer', 'Spitter', UFO + 'enemy-ufo-c-weapon.glb', { anims: NONE, sounds: { ...METAL, step: null } }),
      c('Bulwark', 'Shielder', UFO + 'enemy-ufo-d.glb', { scale: 1.3, anims: NONE, sounds: { ...BIGMETAL, step: null } }),
      c('Goleling', 'Shielder', QU + 'Flying_Goleling.glb', { anims: Q_FLY, sounds: { ...BIGMETAL, step: null } }),
      c('Goleling Evolved', 'Elite', QU + 'Flying_Goleling_Evolved.glb', { scale: 1.2, anims: Q_FLY, sounds: { ...BIGMETAL, step: null } }),
      c('Mothership', 'Boss', UFO + 'enemy-ufo-d-weapon.glb', { scale: 2.5, anims: NONE, sounds: { ...BIGMETAL, step: null } }),
    ],
  },
  {
    id: 'station', name: 'Space Station', map: 'Space Station', source: 'Quaternius Ultimate Space Kit + Ultimate + Cute Monsters, Kenney Space Kit alien (static) (all CC0)',
    creatures: [
      c('Spore', 'Flyer', QS + 'Enemy_ExtraSmall.glb', { anims: Q_SPACE_FLYER, sounds: FLY }),
      c('Alien', 'Runner', '../assets/creatures/kenney-space/alien.glb', { anims: NONE, sounds: GLASS }),
      c('Grey', 'Runner', QCU + 'Alien.glb', { anims: Q_CUTE, sounds: GLASS }),
      c('Floater', 'Flyer', QS + 'Enemy_Small.glb', { anims: Q_SPACE_FLYER, sounds: FLY }),
      c('Panda Mech', 'Boss', QS + 'Mech_RaeTheRedPanda.glb', { scale: 2.0, anims: Q_SPACE_MECH, sounds: BIGMETAL }),
      c('Tall Grey', 'Elite', QCU + 'Alien_Tall.glb', { anims: Q_CUTE, sounds: GLASS }),
      c('Stinger', 'Flyer', QS + 'Enemy_Flying.glb', { scale: 1.2, anims: Q_SPACE_FLYER, sounds: FLY }),
      c('Rogue Bee', 'Runner', QS + 'Astronaut_BarbaraTheBee.glb', { anims: Q_SPACE_CHAR, sounds: SOFT }),
      c('Rogue Flamingo', 'Spitter', QS + 'Astronaut_FernandoTheFlamingo.glb', { anims: { ...Q_SPACE_CHAR, attack: 'Run_Gun_Shoot', idle: 'Idle_Gun' }, sounds: SOFT }),
      c('Brood Alien', 'Boss', QU + 'Big_Alien.glb', { scale: 2.0, anims: Q_BIG, sounds: BIGMETAL }),
      c('Rogue Frog', 'Healer', QS + 'Astronaut_FinnTheFrog.glb', { anims: Q_SPACE_CHAR, sounds: SOFT }),
      c('Rogue Panda', 'Elite', QS + 'Astronaut_RaeTheRedPanda.glb', { anims: Q_SPACE_CHAR, sounds: SOFT }),
      c('Brood Guard', 'Brute', QS + 'Enemy_Large.glb', { scale: 1.3, anims: Q_SPACE_CHAR, sounds: HEAVY }),
      c('Bee Mech', 'Shielder', QS + 'Mech_BarbaraTheBee.glb', { scale: 1.2, anims: Q_SPACE_MECH, sounds: BIGMETAL }),
      c('Flamingo Mech', 'Spitter', QS + 'Mech_FernandoTheFlamingo.glb', { anims: Q_SPACE_MECH, sounds: METAL }),
      c('Frog Mech', 'Brute', QS + 'Mech_FinnTheFrog.glb', { scale: 1.3, anims: { ...Q_SPACE_MECH, attack: 'Kick' }, sounds: BIGMETAL }),
      c('Visitor', 'Runner', QAL + 'Alien.glb', { anims: Q_ALIEN, sounds: GLASS }),
      c('Helmet Visitor', 'Shielder', QAL + 'Alien_Helmet.glb', { scale: 1.1, anims: Q_ALIEN, sounds: GLASS }),
    ],
  },
];

// Fill in stats and blurb from the archetype table. Waves: creatures appear in list order, one new
// creature per wave; bosses take waves 5, 10, 15, 20 in the order listed.
// Difficulty ladder: within a family the regular creatures are ordered by archetype threat, then by
// size, so the small and weak come first and the big, scary ones arrive late. Bosses keep their
// listed order on waves 5, 10, 15. Health, damage and coins grow with the wave a creature debuts on.
const THREAT = { Runner: 0, Spitter: 1, Flyer: 2, Exploder: 3, Healer: 4, Elite: 5, Shielder: 6, Brute: 7 };
const waveMult = (w, k) => 1 + k * (w - 1);
for (const f of FAMILIES) {
  const bosses = f.creatures.filter(c => c.type === 'Boss');
  const rest = f.creatures.filter(c => c.type !== 'Boss').sort((a, b) => (THREAT[a.type] - THREAT[b.type]) || (a.scale - b.scale));
  const ordered = [];
  let wave = 0, bossN = 0;
  while (rest.length || bossN < bosses.length) {
    wave++;
    if (wave % 5 === 0 && bossN < bosses.length) { bosses[bossN].firstWave = wave; ordered.push(bosses[bossN++]); }
    else if (rest.length) { const c = rest.shift(); c.firstWave = wave; ordered.push(c); }
    else { bosses[bossN].firstWave = wave; ordered.push(bosses[bossN++]); }
  }
  f.creatures = ordered;
  for (const cr of f.creatures) {
    const a = ARCHETYPES[cr.type]; const w = cr.firstWave;
    // Steeper ladder: a wave-20 creature has ~5x the health and ~3.3x the coins of its wave-1 cousin.
    cr.stats = { health: Math.round(a.health * waveMult(w, 0.2)), speed: a.speed, damage: Math.round(a.damage * waveMult(w, 0.08)),
      coins: Math.round(a.coins * waveMult(w, 0.12)), firstWave: w };
    cr.blurb = `${cr.type}. ${a.blurb}`;
    cr.source = f.source;
  }
}

// Classes (DESIGN.md "Classes"). Players keep their own Roblox avatar; a class is a weapon, a passive
// Classes. Five are free and the rest are locked; everyone can play all of them once bought with gems
// earned at the end of each run. The showcase previews each class on a random Kenney blocky character
// (CC0), standing in for a player's own avatar: the game never changes the player's skin, it only puts
// the class weapon in their hand. Clips are Kenney's; they are the reference for the Roblox animations.
export const BLOCKY_RIGS = 'abcdefghijklmnopqr'.split('').map(l => BLOCKY + `character-${l}.glb`);
const ADV = '../assets/characters/kaykit-adventurers/';
const QMED = '../assets/weapons/quaternius-medieval/';
const PCY = '../assets/props/quaternius-cyberpunk-props/';
const sk = (name, cooldown, anim, desc, extra = {}) => ({ name, cooldown, anim, desc, duration: 0, loop: false, ...extra });
// Weapon in hand: file (+ optional node inside it), side, forward axis of the model, length as a fraction of the
// player's height, grip ('gun' along the arm, 'melee' pointing forward, 'shield' on the forearm), offset toward the butt.
const gun = (file, len = 0.42, extra = {}) => ({ file: GUNS + file, side: 'right', fwd: '-z', len, grip: 'gun', offset: 0.1, ...extra });
const melee = (file, len = 0.5, extra = {}) => ({ file, side: 'right', fwd: '+y', len, grip: 'melee', offset: 0.2, ...extra });
export const CLASSES = [
  { id: 'Trooper', tier: 'Free', cost: 0, role: 'All-rounder', weapon: 'Assault rifle', idle: 'holding-right', hold: [gun('machinegun.glb', 0.5)],
    passive: '+10% reload speed',
    skills: [sk('Burst Fire', 6, 'holding-right-shoot', '3-round burst, double damage', { duration: 1, loop: true }), sk('Ammo Crate', 45, 'interact-right', 'Drops a crate: team reloads instantly and gets +20% fire rate for 10 s', { duration: 10 })] },
  { id: 'Tank', tier: 'Free', cost: 0, role: 'Blocker', weapon: 'Flail and shield', hold: [{ flail: true, side: 'right', len: 0.6, grip: 'melee', offset: 0.3 }, { file: QMED + 'Shield_Round.glb', side: 'left', fwd: '+y', len: 0.36, grip: 'shield' }],
    passive: 'Creatures cannot push past you; +50% max health',
    skills: [sk('Flail Sweep', 5, 'attack-melee-right', 'Spin: knocks back everything within 6 studs', { duration: 1 }), sk('Iron Wall', 30, 'holding-left', 'Raise the shield: taunts creatures and blocks 80% damage for 8 s', { duration: 8, loop: true })] },
  { id: 'Scout', tier: 'Free', cost: 0, role: 'Mobility', weapon: 'Dual pistols', idle: 'holding-both', hold: [gun('pistol.glb', 0.24), gun('pistol.glb', 0.24, { side: 'left' })],
    passive: '+20% move speed',
    skills: [sk('Dash', 4, 'sprint', 'Dash 20 studs through creatures', { duration: 0.4, loop: true }), sk('Mark Target', 25, 'holding-both-shoot', 'Marked creature takes +30% damage from everyone for 8 s', { duration: 8, loop: true })] },
  { id: 'Medic', tier: 'Free', cost: 0, role: 'Support', weapon: 'SMG', idle: 'holding-right', hold: [gun('uzi.glb', 0.34)],
    passive: 'Repairs the Town Hall 2x faster with melee',
    skills: [sk('Repair Pulse', 8, 'interact-right', '+150 Town Hall HP'), sk('Overcharge', 40, 'emote-yes', 'Town Hall takes no damage for 6 s', { duration: 6 })] },
  { id: 'Engineer', tier: 'Free', cost: 0, role: 'Area control', weapon: 'Carbine and wrench', idle: 'holding-right', hold: [gun('machinegunLauncher.glb', 0.52)], turret: PCY + 'Turret_Gun.glb',
    passive: 'Melee hits on a turret repair it (+25% HP per hit); turrets bought between runs with gems, upgraded in-run with coins',
    skills: [sk('Place Turret', 10, 'pick-up', 'Builds the selected turret where you aim (max 3 up; placing a 4th removes the oldest)', { repair: 'attack-melee-right' }), sk('Overclock', 30, 'emote-yes', 'All your turrets fire 2x faster for 10 s', { duration: 10 })] },
  { id: 'Berserker', tier: 'Locked', cost: 1200, role: 'Melee damage', weapon: 'Two-handed axe', hold: [melee(QMED + 'Axe_Double.glb', 0.65, { fwd: 'auto' })],
    passive: 'Kills heal you 5 HP; melee damage +25%',
    skills: [sk('Cleave', 4, 'attack-melee-right', 'Wide swing: hits every creature in front of you', { duration: 0.8 }), sk('Rage', 30, 'emote-yes', '+40% attack speed and move speed for 10 s', { duration: 10 })] },
  { id: 'Mage', tier: 'Locked', cost: 1200, role: 'Crowd control', weapon: 'Staff', hold: [melee(ADV + 'Mage.glb', 0.8, { node: '2H_Staff', offset: 0.05 })],
    passive: 'Spells cost 25% less coins; freeze lasts 25% longer',
    skills: [sk('Arcane Bolt', 2, 'interact-right', 'Homing bolt, 35 damage'), sk('Frost Nova', 25, 'holding-both', 'Freezes every creature within 15 studs for 3 s', { duration: 3, loop: true })] },
  { id: 'Pyro', tier: 'Locked', cost: 1500, role: 'Area damage', weapon: 'Flamethrower', idle: 'holding-both', hold: [gun('flamethrower_long.glb', 0.6, { offset: 0.2 })],
    passive: 'Burning creatures take +15% damage',
    skills: [sk('Flame Sweep', 7, 'holding-both-shoot', 'Cone of fire, ignites for 4 s', { duration: 1.5, loop: true }), sk('Fire Wall', 40, 'interact-right', 'Wall of fire across the lane for 8 s', { duration: 8 })] },
  { id: 'Sniper', tier: 'Locked', cost: 1500, role: 'Boss killer', weapon: 'Bolt rifle', idle: 'holding-both', hold: [gun('sniper.glb', 0.7, { offset: 0.15 })],
    passive: '+50% headshot damage',
    skills: [sk('Piercing Shot', 8, 'holding-both-shoot', 'Shot goes through up to 5 creatures', { loop: true, duration: 0.6 }), sk('Overwatch', 35, 'holding-both', 'Next 5 shots in 10 s are guaranteed crits', { duration: 10, loop: true })] },
  { id: 'Demolisher', tier: 'Locked', cost: 2000, role: 'Burst', weapon: 'Grenade launcher', idle: 'holding-both', hold: [gun('rocketlauncherModern.glb', 0.5, { fwd: '+z', offset: 0.1 })],
    passive: 'Carries +2 grenades; explosions 20% wider',
    skills: [sk('Frag Toss', 6, 'interact-right', 'Grenade: 120 damage in 8 studs'), sk('Cluster Bomb', 45, 'holding-both-shoot', 'Shell splits into 6 bomblets along the lane', { duration: 1, loop: true })] },
  { id: 'Summoner', tier: 'Locked', cost: 2500, role: 'Pet', weapon: 'Wand', hold: [melee(ADV + 'Mage.glb', 0.3, { node: '1H_Wand', offset: 0.15 })], pet: QCU + 'Bat.glb', petAnims: Q_CUTE_FLY,
    passive: 'Starts with a pet that attacks the nearest creature',
    skills: [sk('Pet Pounce', 5, 'interact-right', 'Pet leaps on your target for 60 damage', { duration: 0.5 }), sk('Enrage', 45, 'holding-both', 'Pet grows: 2x size and damage for 8 s', { duration: 8, loop: true })] },
];
for (const c of CLASSES) { c.model = BLOCKY_RIGS[0]; c.anims = { idle: c.idle ?? 'idle', walk: 'walk', run: 'sprint' }; c.scale = 1; c.tint = null; c.stats = { tier: c.tier, role: c.role }; }

// Dungeons (src/shared/Dungeons.luau): unlock level, creature family, lanes, gimmick, props kit.
export const DUNGEONS = [
  { id: 'Graveyard', name: 'Graveyard', unlockLevel: 1, family: 'graveyard', lanes: 1, gimmick: 'Fog rolls in on boss waves, cutting sight lines', props: 'KayKit Halloween Bits' },
  { id: 'Farm', name: 'Haunted Farm', unlockLevel: 3, family: 'farm', lanes: 1, gimmick: 'Hay bales can be pushed into lanes as cover; animals trample them', props: 'Quaternius Village + Crops + Nature' },
  { id: 'Swamp', name: 'Swamp', unlockLevel: 5, family: 'swamp', lanes: 1, gimmick: 'Shallow water slows everyone; ice spells freeze it solid', props: 'Quaternius Nature (willows, lilypads)' },
  { id: 'Sewer', name: 'Sewer', unlockLevel: 10, family: 'sewer', lanes: 1, gimmick: 'Slimes split in two when killed above half health', props: 'Quaternius Modular Dungeon + Platformer pipes, KayKit Dungeon' },
  { id: 'Village', name: 'Bandit Village', unlockLevel: 15, family: 'village', lanes: 1, gimmick: 'Bandits loot dropped coins before you can', props: 'Quaternius Medieval Village' },
  { id: 'Frozen', name: 'Frozen Cavern', unlockLevel: 20, family: 'frozen', lanes: 1, gimmick: 'Everything is slippery; freeze spells last twice as long', props: 'Quaternius Nature (snow trees, rocks) + Space dome' },
  { id: 'Jungle', name: 'Jungle Temple', unlockLevel: 25, family: 'jungle', lanes: 1, gimmick: 'Vines block sight lines until burned away', props: 'Quaternius Nature (palms) + Modular Dungeons ruins + Crops bamboo' },
  { id: 'Pirate', name: 'Pirate Cove', unlockLevel: 30, family: 'pirate', lanes: 1, gimmick: 'Cannons on the cliffs can be captured and fired at the lanes', props: 'Quaternius Ships + Nature palms + Village barrels' },
  { id: 'Factory', name: 'Factory', unlockLevel: 35, family: 'factory', lanes: 1, gimmick: 'Conveyor belts move anything on them, including grenades', props: 'Quaternius Cyberpunk Game Kit' },
  { id: 'Station', name: 'Space Station', unlockLevel: 40, family: 'station', lanes: 1, gimmick: 'Airlocks vent a lane for 5 s when opened', props: 'Quaternius Ultimate Space Kit' },
];


// Map previews (Dungeons tab). A map is a themed arena: ground + lane paths from the gates to the
// Town Hall, a hall model, a gate model per lane, scattered props, and a few of the family's creatures
// walking the lanes. `h` is the target height in metres the prop is scaled to; `n` how many to scatter.
const HW = '../assets/props/kaykit-halloween/';
const PN = '../assets/props/quaternius-nature/';
const PV = '../assets/props/quaternius-village/';
const PD = '../assets/props/quaternius-dungeon/';
const PR = '../assets/props/quaternius-ruins/';
const PC = '../assets/props/quaternius-cyberpunk-props/';
const PS = '../assets/props/quaternius-space-props/';
const PSH = '../assets/props/quaternius-ships/';
const PCR = '../assets/props/quaternius-crops/';
const PP = '../assets/props/quaternius-platformer-props/';
const KD = '../assets/props/kaykit-dungeon/';
const PRTS = '../assets/props/quaternius-rts/';

const pr = (file, n, h, opts = {}) => ({ file, n, h, ...opts });
export const MAPS = {
  Graveyard: { ground: 0x2b3a2b, path: 0x4a3f33, sky: 0x151a22, fog: 0x1b2230,
    tower: pr(HW + 'crypt.gltf', 1, 7),
    hall: pr(HW + 'crypt.gltf', 1, 6), gate: pr(HW + 'arch_gate.gltf', 1, 4), props: [
      pr(HW + 'tree_dead_large.gltf', 8, 6), pr(HW + 'tree_dead_medium.gltf', 8, 4), pr(HW + 'gravestone.gltf', 14, 1.2), pr(HW + 'grave_A.gltf', 8, 0.8),
      pr(HW + 'grave_B.gltf', 6, 0.9), pr(HW + 'coffin.gltf', 3, 0.8), pr(HW + 'fence.gltf', 16, 1.2), pr(HW + 'post_lantern.gltf', 6, 2.4),
      pr(HW + 'pumpkin_orange_jackolantern.gltf', 6, 0.6), pr(HW + 'shrine.gltf', 2, 2.5), pr(HW + 'tree_pine_orange_large.gltf', 5, 7) ] },
  Farm: { ground: 0x5a7a33, path: 0x8a6a3a, sky: 0x3a2f3f, fog: 0x4a3a4f,
    tower: pr(PV + 'Mill.glb', 1, 10),
    hall: pr(PV + 'Stable.glb', 1, 6), gate: pr(PV + 'Fence.glb', 1, 1.6), props: [
      pr(PV + 'Hay.glb', 10, 1.2), pr(PV + 'Cart.glb', 3, 1.6), pr(PV + 'Well.glb', 1, 2.2), pr(PV + 'Barrel.glb', 6, 1), pr(PV + 'Crate.glb', 5, 1),
      pr(PCR + 'Pumpkin_Crop.glb', 8, 0.7), pr(PCR + 'Corn_Crop.glb', 10, 1.8), pr(PCR + 'Wheat_Crop.glb', 10, 1.2),
      pr(PN + 'CommonTree_1.glb', 6, 6), pr(PN + 'CommonTree_Dead_1.glb', 3, 5), pr(HW + 'pumpkin_yellow.gltf', 5, 0.6) ] },
  Swamp: { ground: 0x2f3f24, path: 0x3f4a2a, sky: 0x1c2420, fog: 0x2a3a2e, water: 0x274a3f,
    tower: pr(PRTS + 'Temple_FirstAge_Level3.glb', 1, 9),
    hall: pr(PV + 'Gazebo.glb', 1, 5), gate: pr(PN + 'Willow_Dead_1.glb', 1, 7), props: [
      pr(PN + 'Willow_1.glb', 6, 8), pr(PN + 'Willow_2.glb', 5, 7), pr(PN + 'Lilypad.glb', 14, 0.15), pr(PN + 'Plant_1.glb', 10, 1), pr(PN + 'Plant_2.glb', 8, 1),
      pr(PN + 'Plant_3.glb', 8, 1.2), pr(PN + 'Grass.glb', 14, 0.6), pr(PN + 'Rock_1.glb', 5, 1), pr(PN + 'Rock_2.glb', 5, 1.4), pr(PN + 'CommonTree_Dead_2.glb', 4, 5),
      pr(PN + 'WoodLog.glb', 4, 0.6), pr(PN + 'TreeStump.glb', 4, 0.6) ] },
  Sewer: { ground: 0x2a2d31, path: 0x3b4044, sky: 0x101214, fog: 0x1a1e22, water: 0x3a5a2a,
    tower: pr(PRTS + 'WatchTower_FirstAge_Level3.glb', 1, 10),
    hall: pr(PD + 'Entrance.glb', 1, 6), gate: pr(PD + 'Bars.glb', 1, 3), props: [
      pr(PD + 'Barrel.glb', 8, 1), pr(PD + 'Bones.glb', 6, 0.5), pr(PD + 'Bones2.glb', 4, 0.5), pr(PD + 'Column.glb', 10, 4), pr(PD + 'Column_Broken.glb', 5, 2.5),
      pr(PD + 'Torch.glb', 8, 1.6), pr(PD + 'Rock1.glb', 6, 1), pr(PD + 'Rock2.glb', 5, 1.3), pr(PP + 'Pipe.glb', 6, 2.2), pr(PD + 'WallRocks.glb', 6, 2.5),
      pr(KD + 'crates_stacked.gltf.glb', 3, 1.4), pr(PD + 'Chest.glb', 2, 0.8) ] },
  Village: { ground: 0x5f7f3a, path: 0x8c7a5a, sky: 0x4a3a30, fog: 0x5a4a40,
    tower: pr(PRTS + 'TownCenter_SecondAge_Level3.glb', 1, 10),
    hall: pr(PV + 'Inn.glb', 1, 8), gate: pr(PV + 'Fence.glb', 1, 1.6), props: [
      pr(PV + 'House_1.glb', 2, 6), pr(PV + 'House_2.glb', 2, 6), pr(PV + 'House_3.glb', 2, 6.5), pr(PV + 'House_4.glb', 1, 7), pr(PV + 'Blacksmith.glb', 1, 6),
      pr(PV + 'MarketStand_1.glb', 2, 2.5), pr(PV + 'MarketStand_2.glb', 2, 2.5), pr(PV + 'Bonfire_Lit.glb', 2, 1.2), pr(PV + 'Well.glb', 1, 2.2), pr(PV + 'Cart.glb', 2, 1.6),
      pr(PV + 'Bell_Tower.glb', 1, 9), pr(PV + 'Barrel.glb', 6, 1), pr(PV + 'Crate.glb', 6, 1), pr(PV + 'Bench_1.glb', 3, 0.8), pr(PN + 'CommonTree_2.glb', 5, 6) ] },
  Frozen: { ground: 0xd8e4ee, path: 0xa8bccc, sky: 0x1a2634, fog: 0x3a4a5c,
    tower: pr(PRTS + 'Wonder_SecondAge_Level3.glb', 1, 11),
    hall: pr(PS + 'GeodesicDome.glb', 1, 6), gate: pr(PN + 'BirchTree_Dead_Snow_1.glb', 1, 6), props: [
      pr(PN + 'PineTree_Snow_1.glb', 8, 8), pr(PN + 'PineTree_Snow_2.glb', 8, 7), pr(PN + 'PineTree_Snow_3.glb', 6, 6), pr(PN + 'CommonTree_Snow_1.glb', 5, 6),
      pr(PN + 'CommonTree_Snow_2.glb', 4, 5), pr(PN + 'Bush_Snow_1.glb', 8, 1), pr(PN + 'Bush_Snow_2.glb', 6, 1), pr(PN + 'Rock_Snow_1.glb', 6, 1.4),
      pr(PN + 'Rock_Snow_2.glb', 6, 2), pr(PN + 'Rock_Snow_3.glb', 4, 2.6), pr(PN + 'BirchTree_Dead_Snow_2.glb', 4, 6) ] },
  Jungle: { ground: 0x3f6a2f, path: 0x6a5a3a, sky: 0x1e2a1a, fog: 0x2e4a2a,
    tower: pr(PRTS + 'Temple_SecondAge_Level3.glb', 1, 10),
    hall: pr(PR + 'Statue_Horse.glb', 1, 6), gate: pr(PR + 'Arch_Door.glb', 1, 4.5), props: [
      pr(PN + 'PalmTree_1.glb', 6, 8), pr(PN + 'PalmTree_2.glb', 6, 7), pr(PN + 'PalmTree_3.glb', 4, 9), pr(PN + 'CommonTree_3.glb', 5, 7), pr(PN + 'Plant_4.glb', 10, 1.2),
      pr(PN + 'Plant_5.glb', 10, 1.4), pr(PN + 'Flowers.glb', 8, 0.5), pr(PN + 'Grass_2.glb', 10, 0.6), pr(PR + 'Column.glb', 6, 4), pr(PR + 'Column2.glb', 4, 4),
      pr(PR + 'Pedestal.glb', 4, 1.2), pr(PR + 'Vase.glb', 4, 1), pr(PR + 'Skull.glb', 4, 0.5), pr(PCR + 'Bamboo_Crop.glb', 8, 3) ] },
  Pirate: { ground: 0xd8c48a, path: 0xb8a070, sky: 0x1a2a3a, fog: 0x2a3a4a, water: 0x2a6a8a,
    tower: pr(PSH + 'Sail_ship.glb', 1, 14),
    hall: pr(PSH + 'Sail_ship.glb', 1, 12), gate: pr(PSH + 'Boat.glb', 1, 1.6), props: [
      pr(PN + 'PalmTree_1.glb', 6, 7), pr(PN + 'PalmTree_4.glb', 6, 8), pr(PV + 'Barrel.glb', 8, 1), pr(PV + 'Crate.glb', 6, 1), pr(PV + 'Bonfire_Lit.glb', 2, 1.2),
      pr(PN + 'Rock_3.glb', 6, 1.6), pr(PN + 'Rock_4.glb', 4, 2.4), pr(PSH + 'Viking_boat.glb', 1, 3), pr(PSH + 'BoatWSail.glb', 1, 4), pr(PSH + 'Lifeboat.glb', 2, 1.2),
      pr(KD + 'chest_gold.glb', 2, 0.8), pr(PN + 'Grass_Short.glb', 10, 0.4) ] },
  Factory: { ground: 0x33363c, path: 0x4a4e55, sky: 0x101418, fog: 0x1c2228,
    tower: pr(PC + 'Turret_Cannon.glb', 1, 9),
    hall: pr(PC + 'Computer_Large.glb', 1, 5), gate: pr(PC + 'Door.glb', 1, 4), props: [
      pr(PC + 'AC.glb', 5, 1), pr(PC + 'AC_Stacked.glb', 3, 2), pr(PC + 'Antenna_1.glb', 4, 3), pr(PC + 'Antenna_2.glb', 3, 4), pr(PC + 'Cable_Thick.glb', 4, 0.6),
      pr(PC + 'Fence.glb', 10, 1.6), pr(PC + 'Light_Street_1.glb', 6, 4), pr(PC + 'Pipe_1.glb', 6, 1.2), pr(PC + 'Platform_4x4.glb', 3, 0.8), pr(PC + 'Rail_Long.glb', 4, 1),
      pr(PC + 'Sign_1.glb', 3, 2.4), pr(PC + 'Support_Long.glb', 6, 5), pr(PC + 'Tank.glb', 4, 2.2), pr(PC + 'Turret_Gun.glb', 3, 2), pr(PC + 'Lootbox.glb', 3, 1) ] },
  Station: { ground: 0x9a4a30, path: 0xc07a58, sky: 0x06060e, fog: 0x3a1a16, space: true, planets: [pr(PS + 'Planet_1.glb', 1, 60), pr(PS + 'Planet_3.glb', 1, 40), pr(PS + 'Planet_7.glb', 1, 28)],
    tower: pr(PS + 'Base_Large.glb', 1, 9),
    hall: pr(PS + 'Base_Large.glb', 1, 7), gate: pr(PS + 'Ramp.glb', 1, 1.5), props: [
      pr(PS + 'Building_L.glb', 2, 6), pr(PS + 'House_Cylinder.glb', 2, 5), pr(PS + 'House_Long.glb', 2, 4), pr(PS + 'House_Single.glb', 2, 4), pr(PS + 'MetalSupport.glb', 6, 3),
      pr(PS + 'Roof_Antenna.glb', 3, 2), pr(PS + 'Roof_Radar.glb', 2, 2.4), pr(PS + 'Rock_Large_1.glb', 4, 3), pr(PS + 'Rock_Large_2.glb', 3, 3.5), pr(PS + 'Rock_1.glb', 6, 1),
      pr(PS + 'SolarPanel_Ground.glb', 4, 1.6), pr(PS + 'Tree_Light_1.glb', 5, 4), pr(PS + 'Tree_Spiral_1.glb', 4, 4), pr(PS + 'Rover_1.glb', 2, 1.6), pr(PS + 'Plant_1.glb', 8, 0.8) ] },
};

export const STAT_ICONS = { health: 'health', speed: 'speed', damage: 'damage', coins: 'coins', firstWave: 'wave', kills: 'kills' };
export const STAT_LABELS = { health: 'Health', speed: 'Speed (studs/s)', damage: 'Town Hall damage', coins: 'Coins per kill', firstWave: 'First wave', tier: 'Tier', role: 'Role', weapon: 'Weapon', passive: 'Passive' };

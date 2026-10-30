-- Creature archetypes. Pure data, no Roblox APIs, so Lune tests can load it.
-- Health and count are scaled per wave and per party size in Waves.luau.

export type Archetype = {
	name: string,
	health: number,
	speed: number, -- studs per second
	damage: number, -- dealt to the Town Hall on arrival
	coins: number, -- paid to the killer, before party multiplier
	firstWave: number,
	size: Vector3 | { number }, -- body size; a plain table when running outside Roblox
	color: { number }, -- RGB 0-255
	flying: boolean?,
}

local Enemies = {}

Enemies.Archetypes = {
	Runner = {
		name = "Runner",
		health = 30,
		speed = 14,
		damage = 10,
		coins = 10,
		firstWave = 1,
		size = { 2, 3, 1 },
		color = { 96, 160, 96 },
	},
	Brute = {
		name = "Brute",
		health = 150,
		speed = 8,
		damage = 40,
		coins = 30,
		firstWave = 3,
		size = { 4, 5, 2 },
		color = { 120, 80, 60 },
	},
	Spitter = {
		name = "Spitter",
		health = 60,
		speed = 10,
		damage = 20,
		coins = 20,
		firstWave = 5,
		size = { 2, 3, 1 },
		color = { 160, 96, 160 },
	},
	Exploder = {
		name = "Exploder",
		health = 40,
		speed = 16,
		damage = 80, -- detonates on the Town Hall
		coins = 25,
		firstWave = 7,
		size = { 3, 3, 3 },
		color = { 220, 140, 40 },
	},
	Shielder = {
		name = "Shielder",
		health = 200,
		speed = 7,
		damage = 20,
		coins = 40,
		firstWave = 10,
		size = { 4, 5, 3 },
		color = { 90, 110, 160 },
	},
	Flyer = {
		name = "Flyer",
		health = 35,
		speed = 18,
		damage = 15,
		coins = 20,
		firstWave = 12,
		size = { 3, 2, 3 },
		color = { 170, 220, 255 },
		flying = true, -- ignores ground paths; straight line at height
	},
	Elite = {
		name = "Elite",
		health = 45,
		speed = 16,
		damage = 10,
		coins = 20,
		firstWave = 15,
		size = { 2, 3, 1 },
		color = { 230, 200, 90 },
	},
	Healer = {
		name = "Healer",
		health = 80,
		speed = 9,
		damage = 10,
		coins = 45,
		firstWave = 18,
		size = { 2, 3, 1 },
		color = { 120, 230, 150 },
	},
	Boss = {
		name = "Boss",
		health = 1200,
		speed = 6,
		damage = 250,
		coins = 500,
		firstWave = 5,
		size = { 8, 10, 4 },
		color = { 200, 40, 40 },
	},
}

-- Horde shares per archetype for regular (non-boss) waves. Waves.composition splits a share between
-- the roster creatures of that archetype that have debuted, so a wave is mostly runners with a few of
-- everything else; shares of archetypes with no creature in the pool yet go unused and the rest are
-- renormalised, so early waves are all Runners.
Enemies.HordeMix = {
	{ archetype = "Runner", share = 0.53 },
	{ archetype = "Elite", share = 0.05 },
	{ archetype = "Brute", share = 0.15 },
	{ archetype = "Spitter", share = 0.1 },
	{ archetype = "Exploder", share = 0.06 },
	{ archetype = "Shielder", share = 0.04 },
	{ archetype = "Flyer", share = 0.05 },
	{ archetype = "Healer", share = 0.02 },
}

function Enemies.get(name: string): Archetype
	local def = Enemies.Archetypes[name]
	assert(def, `Unknown archetype {name}`)
	return def
end

return Enemies

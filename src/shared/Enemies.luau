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

-- Archetypes that may appear in regular (non-boss) waves, in spawn-weight order.
Enemies.HordeMix = {
	{ archetype = "Runner", share = 0.7 },
	{ archetype = "Brute", share = 0.2 },
	{ archetype = "Spitter", share = 0.1 },
}

function Enemies.get(name: string): Archetype
	local def = Enemies.Archetypes[name]
	assert(def, `Unknown archetype {name}`)
	return def
end

return Enemies

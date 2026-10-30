-- Wave composition and scaling. Pure functions so they can be unit-tested with Lune.
-- See DESIGN.md "Core loop" and "Enemies and maps".
--
-- A wave is composed from the dungeon's roster (Roster.luau): at wave w the pool is every regular
-- creature whose firstWave <= w, the newest one is guaranteed to show up, and boss waves (every 5th)
-- lead with the roster boss for that tier plus a thin escort from the pool. Counts grow with the wave
-- and the party mode; health grows with the wave on top of the roster's debut-wave values.

local Enemies = require(script and script.Parent.Enemies or "./Enemies")
local Roster = require(script and script.Parent.Roster or "./Roster")

-- Structurally identical to Creature; spelled out because the Lune-compatible require above
-- hides the module's exported types from the type checker.
export type Creature = {
	id: string,
	archetype: string,
	firstWave: number,
	health: number,
	speed: number,
	damage: number,
	coins: number,
	scale: number,
	model: string,
	flying: boolean,
}
export type Mode = { health: number, count: number, coins: number }
export type SpawnGroup = { creature: Creature, count: number }
export type Stats = { health: number, damage: number, coins: number, speed: number }

local Waves = {}

Waves.Modes = {
	Solo = { health = 1.0, count = 1.0, coins = 1.0 },
	Duo = { health = 1.3, count = 1.6, coins = 1.2 },
	Squad = { health = 1.8, count = 2.8, coins = 1.5 },
}

Waves.BossEvery = 5
Waves.EliteFromWave = 15

function Waves.mode(name: string): Mode
	local mode = Waves.Modes[name]
	assert(mode, `Unknown mode {name}`)
	return mode
end

-- Every 5th wave, plus any wave a roster boss debuts on (a roster whose regular creatures run out
-- places its remaining bosses on the next waves, so the showcase order is kept).
function Waves.isBossWave(wave: number, familyId: string?): boolean
	if wave % Waves.BossEvery == 0 then
		return true
	end
	if familyId then
		for _, c in Roster.family(familyId) do
			if c.archetype == "Boss" and c.firstWave == wave then
				return true
			end
		end
	end
	return false
end

-- Base creature count before the party multiplier.
function Waves.baseCount(wave: number): number
	return 8 + 4 * wave
end

function Waves.creatureCount(wave: number, modeName: string): number
	return math.floor(Waves.baseCount(wave) * Waves.mode(modeName).count + 0.5)
end

function Waves.healthMultiplier(wave: number, modeName: string): number
	return (1 + 0.12 * wave) * Waves.mode(modeName).health
end

-- Final numbers for one creature spawned on `wave`: the roster's debut-wave stats times the wave and
-- party multipliers. Damage and speed are not scaled so a lane keeps its rhythm.
function Waves.stats(creature: Creature, wave: number, modeName: string): Stats
	return {
		health = math.floor(creature.health * Waves.healthMultiplier(wave, modeName) + 0.5),
		damage = creature.damage,
		coins = math.floor(creature.coins * Waves.mode(modeName).coins + 0.5),
		speed = creature.speed,
	}
end

-- Regular (non-boss) roster creatures that have debuted by `wave`, in debut order.
function Waves.pool(familyId: string, wave: number): { Creature }
	local pool = {}
	for _, c in Roster.family(familyId) do
		if c.archetype ~= "Boss" and c.firstWave <= wave then
			table.insert(pool, c)
		end
	end
	return pool
end

-- The boss for a boss wave: the latest roster boss that has debuted, so wave 15 on a roster with two
-- bosses repeats the wave-10 boss. Nil only if the roster has no boss by `wave`.
function Waves.bossFor(familyId: string, wave: number): Creature?
	local boss: Creature? = nil
	for _, c in Roster.family(familyId) do
		if c.archetype == "Boss" and c.firstWave <= wave and (boss == nil or c.firstWave > boss.firstWave) then
			boss = c
		end
	end
	return boss
end

local function share(archetype: string): number
	for _, entry in Enemies.HordeMix do
		if entry.archetype == archetype then
			return entry.share
		end
	end
	return 0
end

-- Splits `total` creatures across the pool: each archetype's horde share is divided between its
-- creatures in the pool, rounded down, and the remainder goes to the newest creature so it is always
-- present on its debut wave. Groups keep debut order.
local function distribute(pool: { Creature }, total: number): { SpawnGroup }
	if total <= 0 or #pool == 0 then
		return {}
	end
	local perArchetype: { [string]: number } = {}
	for _, c in pool do
		perArchetype[c.archetype] = (perArchetype[c.archetype] or 0) + 1
	end
	local weights = {}
	local weightSum = 0
	for i, c in pool do
		weights[i] = share(c.archetype) / perArchetype[c.archetype]
		weightSum += weights[i]
	end
	if weightSum == 0 then
		for i in pool do
			weights[i] = 1
		end
		weightSum = #pool
	end

	local counts = {}
	local assigned = 0
	for i in pool do
		counts[i] = math.floor(total * weights[i] / weightSum)
		assigned += counts[i]
	end
	-- The newest creature is the last in debut order.
	local newest = #pool
	counts[newest] += total - assigned
	if counts[newest] == 0 then
		local biggest = 1
		for i in pool do
			if counts[i] > counts[biggest] then
				biggest = i
			end
		end
		counts[biggest] -= 1
		counts[newest] = 1
	end

	local groups: { SpawnGroup } = {}
	for i, c in pool do
		if counts[i] > 0 then
			table.insert(groups, { creature = c, count = counts[i] })
		end
	end
	return groups
end

-- Which creatures spawn in a wave, in spawn order. Boss waves are the tier boss plus an escort of a
-- quarter of the wave's count; regular waves split the whole count across the pool.
function Waves.composition(familyId: string, wave: number, modeName: string): { SpawnGroup }
	local total = Waves.creatureCount(wave, modeName)
	local pool = Waves.pool(familyId, wave)

	if Waves.isBossWave(wave, familyId) then
		local boss = Waves.bossFor(familyId, wave)
		if boss then
			local groups = { { creature = boss, count = 1 } }
			for _, g in distribute(pool, math.ceil(total / 4)) do
				table.insert(groups, g)
			end
			return groups
		end
	end
	return distribute(pool, total)
end

-- Score awarded on top of coins when a wave is cleared.
function Waves.waveBonus(wave: number): number
	return wave * 100
end

return Waves

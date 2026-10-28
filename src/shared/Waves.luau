-- Wave composition and scaling. Pure functions so they can be unit-tested with Lune.
-- See DESIGN.md "Core loop" and "Enemies and maps".

local Enemies = require(script and script.Parent.Enemies or "./Enemies")

export type Mode = { health: number, count: number, coins: number }
export type SpawnGroup = { archetype: string, count: number }

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

function Waves.isBossWave(wave: number): boolean
	return wave % Waves.BossEvery == 0
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

function Waves.creatureHealth(archetype: string, wave: number, modeName: string): number
	return math.floor(Enemies.get(archetype).health * Waves.healthMultiplier(wave, modeName) + 0.5)
end

function Waves.coinsFor(archetype: string, modeName: string): number
	return math.floor(Enemies.get(archetype).coins * Waves.mode(modeName).coins + 0.5)
end

-- Which creatures spawn in a wave. Boss waves are one boss plus a thin Runner escort.
-- Regular waves split the count across the horde mix, skipping archetypes not yet unlocked
-- and handing their share to Runners.
function Waves.composition(wave: number, modeName: string): { SpawnGroup }
	local total = Waves.creatureCount(wave, modeName)

	if Waves.isBossWave(wave) then
		return {
			{ archetype = "Boss", count = 1 },
			{ archetype = "Runner", count = math.ceil(total / 4) },
		}
	end

	local groups: { SpawnGroup } = {}
	local assigned = 0
	for _, entry in Enemies.HordeMix do
		local def = Enemies.get(entry.archetype)
		if wave >= def.firstWave and entry.archetype ~= "Runner" then
			local count = math.floor(total * entry.share)
			if count > 0 then
				table.insert(groups, { archetype = entry.archetype, count = count })
				assigned += count
			end
		end
	end
	table.insert(groups, 1, { archetype = "Runner", count = total - assigned })
	return groups
end

-- Score awarded on top of coins when a wave is cleared.
function Waves.waveBonus(wave: number): number
	return wave * 100
end

return Waves

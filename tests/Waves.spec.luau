-- Run with: lune run test   (or lune run tests/Waves.spec)
local Roster = require("../src/shared/Roster")
local Waves = require("../src/shared/Waves")

local function eq(got, want, label)
	assert(got == want, `{label}: got {got}, want {want}`)
end

local function total(groups)
	local sum = 0
	for _, g in groups do
		sum += g.count
	end
	return sum
end

local function countOf(groups, id)
	for _, g in groups do
		if g.creature.id == id then
			return g.count
		end
	end
	return 0
end

-- base scaling
eq(Waves.baseCount(1), 12, "wave 1 base count")
eq(Waves.baseCount(10), 48, "wave 10 base count")
eq(Waves.creatureCount(1, "Solo"), 12, "solo wave 1 count")
eq(Waves.creatureCount(1, "Squad"), 34, "squad wave 1 count (12 * 2.8 rounded)")
eq(Waves.healthMultiplier(0, "Solo"), 1, "wave 0 solo health")

-- stats: roster debut values times the wave and party multipliers
local zombie = Roster.get("graveyard", "Zombie")
eq(Waves.stats(zombie, 10, "Solo").health, 66, "zombie wave 10 solo (30 * 2.2)")
eq(Waves.stats(zombie, 1, "Squad").coins, 15, "zombie coins in squad")
eq(Waves.stats(zombie, 1, "Solo").damage, 10, "damage is not scaled")
eq(Waves.stats(zombie, 1, "Solo").speed, 28, "speed is not scaled")

-- boss cadence
assert(not Waves.isBossWave(4), "wave 4 is not a boss wave")
assert(Waves.isBossWave(5), "wave 5 is a boss wave")
assert(Waves.isBossWave(10), "wave 10 is a boss wave")
assert(Waves.isBossWave(14, "pirate"), "a boss debuting off-cadence makes a boss wave")
assert(not Waves.isBossWave(14, "graveyard"), "wave 14 is regular where no boss debuts")

-- pool: regular creatures that have debuted
eq(#Waves.pool("graveyard", 1), 1, "wave 1 pool has one creature")
eq(Waves.pool("graveyard", 1)[1].id, "Zombie", "wave 1 pool is the Zombie")
eq(#Waves.pool("graveyard", 4), 4, "wave 4 pool has four creatures")
eq(#Waves.pool("graveyard", 5), 4, "the wave 5 boss is not in the pool")
eq(#Waves.pool("graveyard", 6), 5, "wave 6 adds one more")

-- bosses per tier
eq(Waves.bossFor("graveyard", 5).id, "Keeper", "graveyard wave 5 boss")
eq(Waves.bossFor("graveyard", 10).id, "Bone Dragon", "graveyard wave 10 boss")
eq(Waves.bossFor("graveyard", 15).id, "Bone Dragon", "wave 15 repeats the latest boss")
eq(Waves.bossFor("graveyard", 4), nil, "no boss before wave 5")

-- composition
local w1 = Waves.composition("graveyard", 1, "Solo")
eq(#w1, 1, "wave 1 has only the first creature")
eq(w1[1].creature.id, "Zombie", "wave 1 group is Zombie")
eq(w1[1].count, 12, "wave 1 count")

local w2 = Waves.composition("graveyard", 2, "Solo")
eq(total(w2), 16, "wave 2 sums to the count")
assert(countOf(w2, "Minion") >= 1, "wave 2 debut creature appears")
assert(countOf(w2, "Zombie") >= 1, "wave 2 keeps the older creature")

local w5 = Waves.composition("graveyard", 5, "Solo")
eq(w5[1].creature.id, "Keeper", "wave 5 leads with the boss")
eq(w5[1].count, 1, "exactly one boss")
eq(total(w5) - 1, 7, "boss escort = ceil(28 / 4)")

local w10 = Waves.composition("graveyard", 10, "Squad")
eq(w10[1].creature.id, "Bone Dragon", "wave 10 leads with the tier-2 boss")

-- every regular wave sums to the count and the debut creature is present, for every family and mode
for _, familyId in Roster.FamilyOrder do
	for _, modeName in { "Solo", "Duo", "Squad" } do
		for wave = 1, 30 do
			local groups = Waves.composition(familyId, wave, modeName)
			assert(#groups > 0, `{familyId} wave {wave} {modeName} spawns something`)
			if Waves.isBossWave(wave, familyId) then
				eq(groups[1].creature.archetype, "Boss", `{familyId} wave {wave} leads with a boss`)
			else
				eq(total(groups), Waves.creatureCount(wave, modeName), `{familyId} wave {wave} {modeName} total`)
				for _, c in Roster.family(familyId) do
					if c.firstWave == wave then
						assert(countOf(groups, c.id) >= 1, `{familyId} wave {wave}: {c.id} debuts`)
					end
				end
			end
			for _, g in groups do
				assert(g.count > 0, "no empty groups")
			end
		end
	end
end

-- late waves mix everything seen so far
local w30 = Waves.composition("graveyard", 29, "Squad")
local seen = 0
for _ in w30 do
	seen += 1
end
assert(seen >= 10, `wave 29 squad mixes many creatures ({seen})`)

-- dungeon difficulty scales health and Town Hall damage, not coins or speed
local hard = Waves.stats(zombie, 10, "Solo", 2)
eq(hard.health, 132, "zombie wave 10 solo at difficulty 2 (66 * 2)")
eq(hard.damage, 20, "town hall damage doubles at difficulty 2")
eq(hard.coins, Waves.stats(zombie, 10, "Solo").coins, "coins are not scaled by difficulty")
eq(hard.speed, 28, "speed is not scaled by difficulty")
eq(Waves.stats(zombie, 10, "Solo", 1).health, 66, "difficulty 1 is the base")

print("Waves.spec: ok")

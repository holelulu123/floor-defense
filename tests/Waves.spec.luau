-- Run with: lune run test   (or lune run tests/Waves.spec)
local Waves = require("../src/shared/Waves")

local function eq(got, want, label)
	assert(got == want, `{label}: got {got}, want {want}`)
end

-- base scaling
eq(Waves.baseCount(1), 12, "wave 1 base count")
eq(Waves.baseCount(10), 48, "wave 10 base count")
eq(Waves.creatureCount(1, "Solo"), 12, "solo wave 1 count")
eq(Waves.creatureCount(1, "Squad"), 34, "squad wave 1 count (12 * 2.8 rounded)")
eq(Waves.healthMultiplier(0, "Solo"), 1, "wave 0 solo health")
eq(Waves.creatureHealth("Runner", 10, "Solo"), 66, "runner wave 10 solo (30 * 2.2)")
eq(Waves.coinsFor("Runner", "Squad"), 15, "runner coins in squad")

-- boss cadence
assert(not Waves.isBossWave(4), "wave 4 is not a boss wave")
assert(Waves.isBossWave(5), "wave 5 is a boss wave")
assert(Waves.isBossWave(10), "wave 10 is a boss wave")

-- composition
local w1 = Waves.composition(1, "Solo")
eq(#w1, 1, "wave 1 has only runners")
eq(w1[1].archetype, "Runner", "wave 1 group is Runner")
eq(w1[1].count, 12, "wave 1 runner count")

local w3 = Waves.composition(3, "Solo") -- 20 creatures; brutes unlock, spitters not yet
eq(#w3, 2, "wave 3 has runners and brutes")
eq(w3[2].archetype, "Brute", "wave 3 second group is Brute")
eq(w3[2].count, 4, "wave 3 brutes = floor(20 * 0.2)")
eq(w3[1].count, 16, "wave 3 runners take the rest")

local w5 = Waves.composition(5, "Solo")
eq(w5[1].archetype, "Boss", "wave 5 leads with the boss")
eq(w5[1].count, 1, "exactly one boss")
eq(w5[2].count, 7, "boss escort = ceil(28 / 4)")

local w6 = Waves.composition(6, "Squad") -- 32 * 2.8 = 89.6 -> 90
local sum = 0
for _, g in w6 do
	sum += g.count
end
eq(sum, 90, "composition always sums to creatureCount")

print("Waves.spec: ok")

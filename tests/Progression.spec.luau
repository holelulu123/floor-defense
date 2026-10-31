local Dungeons = require("../src/shared/Dungeons")
local Progression = require("../src/shared/Progression")

local function eq(got, want, label)
	assert(got == want, `{label}: got {got}, want {want}`)
end

-- level curve: 100, x2.0, x2.3, x2.7, x3.0, then x3.0 per level (rounded each step)
eq(Progression.xpToNext(1), 100, "level 1 -> 2")
eq(Progression.xpToNext(2), 200, "level 2 -> 3 (x2.0)")
eq(Progression.xpToNext(3), 460, "level 3 -> 4 (x2.3)")
eq(Progression.xpToNext(4), 1242, "level 4 -> 5 (x2.7)")
eq(Progression.xpToNext(5), 3726, "level 5 -> 6 (x3.0)")
eq(Progression.xpToNext(6), 11178, "level 6 -> 7 (x3.0 from here on)")
eq(Progression.xpToNext(10), 3726 * 3 ^ 5, "level 10 -> 11")
eq(Progression.xpToNext(Progression.MaxLevel), 0, "nothing to earn at the max level")
for level = 1, Progression.MaxLevel - 1 do
	local need = Progression.xpToNext(level)
	assert(need == math.floor(need), `level {level} need is a whole number`)
end

-- addXp
local level, xp, gained = Progression.addXp(1, 0, 50)
assert(level == 1 and xp == 50 and gained == 0, "50 xp stays on level 1")
level, xp, gained = Progression.addXp(1, 50, 50)
assert(level == 2 and xp == 0 and gained == 1, "exactly enough to level up")
level, xp, gained = Progression.addXp(1, 90, 300)
assert(level == 3 and xp == 90 and gained == 2, `390 xp from level 1: 100 + 200, 90 left (got {level} {xp})`)
level, xp, gained = Progression.addXp(3, 10, 0)
assert(level == 3 and xp == 10 and gained == 0, "no xp, no change")
level, xp, gained = Progression.addXp(Progression.MaxLevel - 1, 0, 1e15)
assert(level == Progression.MaxLevel and xp == 0 and gained == 1, "capped at the max level")
level, xp = Progression.addXp(0, -5, -10)
assert(level == 1 and xp == 0, "bad input is clamped")
level, xp, gained = Progression.addXp(2, 500, 0)
assert(level == 3 and xp == 300 and gained == 1, "over-full progress (curve change) is rolled over")

-- run XP: later waves are worth more than linearly, harder dungeons pay much more, party bonus applies
eq(Progression.xpForRun(1, 0, "Solo"), 0, "no waves, no xp")
eq(Progression.xpForRun(1, 10, "Solo"), 32, "graveyard wave 10 solo (10^1.5)")
eq(Progression.xpForRun(1, 10, "Squad"), 47, "squad x1.5")
eq(Progression.xpForRun(1, 10, "Unknown"), 32, "unknown mode falls back to x1")
assert(Progression.xpForRun(1, 20, "Solo") > 2 * Progression.xpForRun(1, 10, "Solo"), "superlinear in waves")
for i = 2, #Dungeons.List do
	assert(
		Progression.xpForRun(i, 10, "Solo") > 1.4 * Progression.xpForRun(i - 1, 10, "Solo"),
		`dungeon {i} pays clearly more XP than dungeon {i - 1}`
	)
end
eq(Progression.xpForRun(99, 10, "Solo"), Progression.xpForRun(#Dungeons.List, 10, "Solo"), "index is clamped")

-- pacing: at the level that unlocks dungeon N, about wave 10 there levels you up in 3 to 6 runs
for i, d in Dungeons.List do
	local runs = Progression.xpToNext(d.unlockLevel) / Progression.xpForRun(i, 10, "Solo")
	assert(runs >= 3 and runs <= 6, `{d.id}: {runs} wave-10 runs to level up at level {d.unlockLevel}`)
end

-- diamonds: same shape, smaller numbers
eq(Progression.diamondsForRun(1, 0, "Solo"), 0, "no waves, no diamonds")
eq(Progression.diamondsForRun(1, 10, "Solo"), 18, "graveyard wave 10 solo (10^1.25)")
eq(Progression.diamondsForRun(1, 10, "Duo"), 22, "duo x1.25")
eq(Progression.diamondsForRun(#Dungeons.List, 10, "Solo"), 89, "station wave 10 solo (x5)")
for i = 1, #Dungeons.List do
	assert(
		Progression.diamondsForRun(i, 10, "Solo") < Progression.xpForRun(i, 10, "Solo") or i == 1,
		`diamonds stay below xp in dungeon {i}`
	)
	if i > 1 then
		assert(
			Progression.diamondsForRun(i, 10, "Solo") >= Progression.diamondsForRun(i - 1, 10, "Solo"),
			`dungeon {i} pays at least as many diamonds as dungeon {i - 1}`
		)
	end
end

-- HUD text
eq(Progression.formatNumber(0), "0", "zero")
eq(Progression.formatNumber(999), "999", "no separator under 1000")
eq(Progression.formatNumber(1240), "1,240", "thousands")
eq(Progression.formatNumber(905418), "905,418", "hundreds of thousands")
eq(Progression.formatNumber(1234567), "1,234,567", "millions")
eq(Progression.resultsLine(340, 25, 1, 4), "+340 XP, +25 Diamonds, Level up! Lv 4", "level-up line")
eq(Progression.resultsLine(1240, 5, 0, 4), "+1,240 XP, +5 Diamonds", "no level up")

-- dungeon unlocks follow level: one dungeon per level
eq(#Dungeons.List, 10, "ten dungeons")
for i, d in Dungeons.List do
	eq(d.unlockLevel, i, `{d.id} unlock level`)
	eq(Dungeons.indexOf(d.id), i, `{d.id} index`)
end
eq(Dungeons.indexOf("Nowhere"), nil, "unknown dungeon has no index")
eq(#Dungeons.unlockedFor(1), 1, "level 1 has only the Graveyard")
eq(#Dungeons.unlockedFor(3), 3, "level 3 has Graveyard, Farm, Swamp")
assert(Dungeons.isUnlocked("Swamp", 3), "swamp at level 3")
assert(not Dungeons.isUnlocked("Swamp", 2), "no swamp at level 2")
eq(Dungeons.nextUnlock(3).id, "Sewer", "next after level 3 is the Sewer")
eq(Dungeons.nextUnlock(10), nil, "nothing left to unlock at level 10")

-- difficulty: Graveyard 1.0, x1.35 per dungeon (rounded to 2 places)
eq(Dungeons.get("Graveyard").difficulty, 1, "graveyard difficulty")
for i, d in Dungeons.List do
	local want = math.floor(Dungeons.DifficultyStep ^ (i - 1) * 100 + 0.5) / 100
	assert(math.abs(d.difficulty - want) < 1e-9, `{d.id} difficulty {d.difficulty}, want {want}`)
end

print("Progression.spec: ok")

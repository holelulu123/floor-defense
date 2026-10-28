local Progression = require("../src/shared/Progression")
local Dungeons = require("../src/shared/Dungeons")

local function eq(got, want, label)
	assert(got == want, `{label}: got {got}, want {want}`)
end

-- XP curve gets steeper
eq(Progression.xpForLevel(1), 100, "level 1 -> 2 costs 100")
eq(Progression.xpForLevel(4), 800, "level 4 -> 5 costs 800")
eq(Progression.xpForLevel(9), 2700, "level 9 -> 10 costs 2700")
assert(Progression.xpForLevel(20) > 2 * Progression.xpForLevel(10), "later levels cost much more")
eq(Progression.totalXpForLevel(3), 100 + 282, "total XP to reach level 3")

local level, progress = Progression.levelFromXp(0)
eq(level, 1, "0 xp is level 1")
eq(progress, 0, "no progress at 0 xp")
level, progress = Progression.levelFromXp(150)
eq(level, 2, "150 xp is level 2")
assert(math.abs(progress - 50 / 282) < 1e-9, "progress toward level 3")
level = Progression.levelFromXp(1e12)
eq(level, Progression.MaxLevel, "xp is capped at max level")

-- run rewards
eq(Progression.runXp(10, 40, false), 290, "wave 10, 40 kills, wiped")
eq(Progression.runXp(10, 40, true), 390, "survival bonus")
eq(Progression.runGems(15, 3, true), 110, "15 waves, 3 bosses, survived")

-- dungeon unlocks follow level
eq(#Dungeons.unlockedFor(1), 1, "level 1 has only the Graveyard")
eq(#Dungeons.unlockedFor(5), 3, "level 5 has Graveyard, Farm, Swamp")
assert(Dungeons.isUnlocked("Swamp", 5), "swamp at level 5")
assert(not Dungeons.isUnlocked("Swamp", 4), "no swamp at level 4")
eq(Dungeons.nextUnlock(5).id, "Sewer", "next after level 5 is the Sewer")
eq(Dungeons.nextUnlock(99), nil, "nothing left to unlock at max")
eq(#Dungeons.List, 10, "ten dungeons")

print("Progression.spec: ok")

-- Player XP and levels. Pure math; tuning numbers live here so tests pin them.
-- XP needed per level grows with level^1.5, so each level takes longer than the last.

local Progression = {}

Progression.MaxLevel = 60
Progression.BaseXp = 100
Progression.Exponent = 1.5

-- XP needed to go from `level` to `level + 1`.
function Progression.xpForLevel(level: number): number
	return math.floor(Progression.BaseXp * level ^ Progression.Exponent)
end

-- Total XP needed to reach `level` from level 1.
function Progression.totalXpForLevel(level: number): number
	local total = 0
	for l = 1, level - 1 do
		total += Progression.xpForLevel(l)
	end
	return total
end

-- Level for a total XP amount, plus progress toward the next level as 0..1.
function Progression.levelFromXp(totalXp: number): (number, number)
	local level = 1
	local remaining = totalXp
	while level < Progression.MaxLevel do
		local need = Progression.xpForLevel(level)
		if remaining < need then
			return level, remaining / need
		end
		remaining -= need
		level += 1
	end
	return Progression.MaxLevel, 1
end

-- XP earned by one run. Waves are worth more than kills so support classes keep up.
function Progression.runXp(wave: number, kills: number, survived: boolean): number
	local xp = wave * 25 + kills
	if survived then
		xp += 100
	end
	return xp
end

-- Gems earned by one run (persistent currency; see DESIGN.md "Progression").
function Progression.runGems(wave: number, bosses: number, survived: boolean): number
	local gems = wave + bosses * 25
	if survived then
		gems += 20
	end
	return gems
end

return Progression

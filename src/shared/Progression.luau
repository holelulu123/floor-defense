-- Player levels, XP and the end-of-run rewards (XP and Diamonds). Pure math; tuning numbers live here and
-- in Dungeons.luau so tests pin them. See DESIGN.md "Progression".
--
-- XP is stored per level: a player is at `level` with `xp` toward the next one (0 <= xp < xpToNext).
-- The curve explodes: need(1) = 100 and each level costs Growth[level] times the previous one (x3 from
-- level 5 on). Run rewards keep up through the dungeons' xpMultiplier, which also grows about x3 per
-- dungeon, so a player at a dungeon's unlock level needs roughly four wave-10 runs there to level up.

local Dungeons = require(script and script.Parent.Dungeons or "./Dungeons")

local Progression = {}

-- High enough that nobody reaches it (level 20 needs ~5e10 XP), low enough that every number stays an
-- exact integer in a double and in the DataStore.
Progression.MaxLevel = 20
Progression.BaseXp = 100
-- need(L + 1) = need(L) * Growth[L]; levels past the table use LateGrowth.
Progression.Growth = { 2.0, 2.3, 2.7, 3.0 }
Progression.LateGrowth = 3.0

-- Party bonus on run rewards so Duo/Squad runs keep up with the faster Solo clears.
Progression.PartyMultiplier = { Solo = 1, Duo = 1.25, Squad = 1.5 }

-- Reward per wave reached grows faster than linearly: waveXp(w) = w ^ XpWaveExponent.
Progression.XpWaveExponent = 1.5
Progression.DiamondWaveExponent = 1.25

local needCache: { number } = { Progression.BaseXp }

-- XP needed to go from `level` to `level + 1` (0 at the max level).
function Progression.xpToNext(level: number): number
	if level >= Progression.MaxLevel then
		return 0
	end
	level = math.max(1, math.floor(level))
	for l = #needCache, level - 1 do
		local growth = Progression.Growth[l] or Progression.LateGrowth
		needCache[l + 1] = math.floor(needCache[l] * growth + 0.5)
	end
	return needCache[level]
end

-- Adds `gained` XP to a player at `level` with `xp` toward the next level. Returns the new level, the new
-- progress and how many levels were gained. XP past the max level is dropped.
function Progression.addXp(level: number, xp: number, gained: number): (number, number, number)
	level = math.clamp(math.floor(level), 1, Progression.MaxLevel)
	xp = math.max(0, math.floor(xp)) + math.max(0, math.floor(gained))
	local start = level
	while level < Progression.MaxLevel and xp >= Progression.xpToNext(level) do
		xp -= Progression.xpToNext(level)
		level += 1
	end
	if level >= Progression.MaxLevel then
		xp = 0
	end
	return level, xp, level - start
end

local function partyMultiplier(mode: string): number
	return Progression.PartyMultiplier[mode] or 1
end

local function dungeonAt(dungeonIndex: number)
	local i = math.clamp(math.floor(dungeonIndex), 1, #Dungeons.List)
	return Dungeons.List[i]
end

-- XP for a run that reached `wave` (the wave the Town Hall fell on) in the dungeon at `dungeonIndex`
-- (unlock order).
function Progression.xpForRun(dungeonIndex: number, wave: number, mode: string): number
	local w = math.max(0, math.floor(wave))
	local base = w ^ Progression.XpWaveExponent
	return math.floor(base * dungeonAt(dungeonIndex).xpMultiplier * partyMultiplier(mode) + 0.5)
end

-- Diamonds (persistent currency) for the same run: same shape as XP, much gentler dungeon multiplier.
function Progression.diamondsForRun(dungeonIndex: number, wave: number, mode: string): number
	local w = math.max(0, math.floor(wave))
	local base = w ^ Progression.DiamondWaveExponent
	return math.floor(base * dungeonAt(dungeonIndex).diamondMultiplier * partyMultiplier(mode) + 0.5)
end

-- 1240 -> "1,240" (whole numbers; negatives keep their sign).
function Progression.formatNumber(n: number): string
	local s = string.format("%.0f", math.floor(math.abs(n) + 0.5))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if out:sub(1, 1) == "," then
		out = out:sub(2)
	end
	return if n < 0 then "-" .. out else out
end

-- Short HUD line for a finished run, e.g. "+340 XP, +25 Diamonds, Level up! Lv 4".
function Progression.resultsLine(xp: number, diamonds: number, levelsGained: number, level: number): string
	local line = `+{Progression.formatNumber(xp)} XP, +{Progression.formatNumber(diamonds)} Diamonds`
	if levelsGained > 0 then
		line ..= `, Level up! Lv {level}`
	end
	return line
end

return Progression

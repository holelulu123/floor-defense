-- Pure HP-bar maths shared by the in-game billboards and the HUD: fill fraction, the
-- green -> yellow -> red colour for a fraction, and the "HP / Max" label. No Roblox API so Lune can test it.

local HealthBar = {}

-- Colour stops as 0-255 RGB, from empty to full. Between stops the colour is linearly interpolated.
HealthBar.Red = { 220, 50, 40 }
HealthBar.Yellow = { 240, 200, 40 }
HealthBar.Green = { 70, 200, 80 }

-- How full the bar is, clamped to [0, 1]. A missing or non-positive max reads as empty.
function HealthBar.fraction(health: number?, maxHealth: number?): number
	if type(health) ~= "number" or type(maxHealth) ~= "number" or maxHealth <= 0 or health ~= health then
		return 0
	end
	return math.clamp(health / maxHealth, 0, 1)
end

local function lerp(a: { number }, b: { number }, t: number): (number, number, number)
	return math.round(a[1] + (b[1] - a[1]) * t),
		math.round(a[2] + (b[2] - a[2]) * t),
		math.round(a[3] + (b[3] - a[3]) * t)
end

-- 0-255 RGB for a fill fraction: red at 0, yellow at 0.5, green at 1.
function HealthBar.color(fraction: number): (number, number, number)
	local f = math.clamp(fraction, 0, 1)
	if f >= 0.5 then
		return lerp(HealthBar.Yellow, HealthBar.Green, (f - 0.5) * 2)
	end
	return lerp(HealthBar.Red, HealthBar.Yellow, f * 2)
end

-- "1,250 / 2,000": health rounded up so a sliver of HP never shows as 0.
local function commas(n: number): string
	local s = tostring(n)
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (out:gsub("^,", ""))
end

function HealthBar.label(health: number?, maxHealth: number?): string
	local h = if type(health) == "number" then math.max(0, math.ceil(health)) else 0
	local m = if type(maxHealth) == "number" then math.max(0, math.ceil(maxHealth)) else 0
	return `{commas(h)} / {commas(m)}`
end

-- Creature bars hide at full HP so a fresh wave doesn't clutter the lane.
function HealthBar.shouldShow(fraction: number, hideWhenFull: boolean): boolean
	return not (hideWhenFull and fraction >= 1)
end

return HealthBar

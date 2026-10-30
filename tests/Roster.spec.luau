-- Run with: lune run test   (or lune run tests/Roster.spec)
-- Checks the generated roster (scripts/gen-roster.py) against the rules the game relies on.
local fs = require("@lune/fs")
local Dungeons = require("../src/shared/Dungeons")
local Enemies = require("../src/shared/Enemies")
local Roster = require("../src/shared/Roster")

local function eq(got, want, label)
	assert(got == want, `{label}: got {got}, want {want}`)
end

-- ten families, one per dungeon, in unlock order
eq(#Roster.FamilyOrder, 10, "family count")
local familyCount = 0
for _ in Roster.Families do
	familyCount += 1
end
eq(familyCount, 10, "Families table size")
for i, d in Dungeons.List do
	eq(Roster.FamilyOrder[i], d.family, `family order matches dungeon {d.id}`)
	assert(Roster.Families[d.family], `dungeon {d.id} has a roster`)
	assert(Roster.Themes[d.id], `dungeon {d.id} has a theme`)
end

local seenIds = {}
for _, familyId in Roster.FamilyOrder do
	local list = Roster.family(familyId)
	assert(#list >= 13, `{familyId} has at least 13 creatures ({#list})`)

	local lastByArchetype = {}
	for i, c in list do
		assert(not seenIds[c.id], `creature id {c.id} is unique across families`)
		seenIds[c.id] = true

		eq(c.firstWave, i, `{familyId} #{i} firstWave is contiguous from 1`)
		assert(Enemies.Archetypes[c.archetype], `{c.id} archetype {c.archetype} exists in Enemies`)
		assert(c.health > 0 and c.damage > 0 and c.coins > 0 and c.speed > 0, `{c.id} stats positive`)
		assert(c.scale > 0, `{c.id} scale positive`)
		eq(c.flying, c.archetype == "Flyer" or c.flying, `{c.id} flyers fly`)
		assert(c.model:match("^assets/creatures/.+%.gl[bt]f?$"), `{c.id} model path {c.model}`)
		assert(fs.isFile(c.model), `{c.id} model file exists: {c.model}`)

		-- health and coins grow with the debut wave within an archetype
		local prev = lastByArchetype[c.archetype]
		if prev then
			assert(c.health >= prev.health, `{c.id} health >= {prev.id}`)
			assert(c.coins >= prev.coins, `{c.id} coins >= {prev.id}`)
			assert(c.damage >= prev.damage, `{c.id} damage >= {prev.id}`)
		end
		lastByArchetype[c.archetype] = c

		if c.archetype == "Boss" then
			assert(c.health >= 1200, `{c.id} boss health`)
		end
	end

	-- boss waves: wave 5 is always a boss, and while bosses remain every 5th wave is one
	local bosses = 0
	for _, c in list do
		if c.archetype == "Boss" then
			bosses += 1
		end
	end
	assert(bosses >= 1, `{familyId} has a boss`)
	eq(list[5].archetype, "Boss", `{familyId} wave 5 is a boss`)
	local placed = 0
	for wave = 5, #list, 5 do
		if placed < bosses then
			eq(list[wave].archetype, "Boss", `{familyId} wave {wave} is a boss`)
			placed += 1
		end
	end
end

-- themes carry what Arena needs
for _, d in Dungeons.List do
	local t = Roster.theme(d.id)
	for _, key in { "ground", "path", "sky", "fog" } do
		eq(#t[key], 3, `{d.id} theme {key} is RGB`)
	end
	assert(#t.tower > 0 and t.towerHeight > 0, `{d.id} has a tower`)
	assert(#t.gate > 0 and t.gateHeight > 0, `{d.id} has a gate`)
end

eq(Roster.get("graveyard", "Zombie").firstWave, 1, "Roster.get")
assert(not pcall(Roster.get, "graveyard", "Nobody"), "Roster.get errors on unknown id")
assert(not pcall(Roster.family, "nowhere"), "Roster.family errors on unknown family")

print("Roster.spec: ok")

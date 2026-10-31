local Classes = require("../src/shared/Classes")
local Skills = require("../src/shared/Skills")

local function eq(got, want, label)
	assert(got == want, `{label}: got {tostring(got)}, want {tostring(want)}`)
end

local function near(got, want, label)
	assert(math.abs(got - want) < 1e-6, `{label}: got {got}, want {want}`)
end

local function p(x, y, z)
	return { X = x, Y = y, Z = z }
end

-- every class has two skills with an effect table and a cooldown in its band
for _, c in Classes.List do
	eq(#c.skills, 2, `{c.id} has two skills`)
	for i, s in c.skills do
		local effect = Skills.effectFor(c.id, i)
		assert(type(effect.kind) == "string", `{s.id} has an effect kind`)
		assert(type(effect.fx) == "string", `{s.id} has a client fx name`)
		if effect.damage then
			assert(effect.damage > 0, `{s.id} damage is positive`)
		end
	end
	assert(c.skills[1].cooldown >= 1 and c.skills[1].cooldown <= 10, `{c.id} skill 1 cooldown 1-10 s`)
	assert(c.skills[2].cooldown >= 25 and c.skills[2].cooldown <= 45, `{c.id} skill 2 cooldown 25-45 s`)
	assert(Classes.weaponFor(c.id) ~= nil, `{c.id} has a weapon`)
end
local kinds = {}
for id, e in Skills.Effects do
	kinds[e.kind] = (kinds[e.kind] or 0) + 1
	assert(not e.duration or e.duration > 0, `{id} duration positive`)
end
assert(kinds.turret == 1 and kinds.overclock == 1, "engineer kinds present")
assert(kinds.pounce == nil and kinds.enrage == nil and Skills.Pet == nil, "Summoner pet skills removed")
assert(Skills.Effects.AmmoCrate.refill == true, "Ammo Crate refills team magazines")
eq(Skills.Passives.Trooper.reloadSpeed, 1.1, "Trooper +10% reload speed")
eq(Skills.Passives.Tank, nil, "Tank health comes from Classes.maxHealth, not a passive")

-- diamonds for a run: see Progression.spec (Progression.diamondsForRun)
eq(#Classes.playable({}), 5, "five playable with nothing bought")
eq(#Classes.playable({ "Mage", "Pyro" }), 7, "two purchases add two classes")

-- geometry
local positions = { p(0, 0, 5), p(0, 0, 20), p(3, 0, 0), p(0, 0, -5), p(30, 0, 30) }
local hits = Skills.inRadius(p(0, 0, 0), positions, 6)
eq(#hits, 3, "three within 6 studs")
eq(hits[1], 3, "nearest first")
local cone = Skills.inCone(p(0, 0, 0), p(0, 0, 1), positions, 25, 30)
eq(#cone, 2, "cone forward catches the two ahead")
assert(table.find(cone, 1) and table.find(cone, 2), "cone contents")
cone = Skills.inCone(p(0, 0, 0), p(0, 0, 1), positions, 25, 90)
eq(#cone, 3, "wide cone also takes the one to the side")
local line =
	Skills.lineHits(p(0, 0, 0), p(0, 0, 1), { p(0.5, 0, 10), p(0, 2, 40), p(4, 0, 20), p(0, 0, -3) }, 120, 2.5, 5)
eq(#line, 2, "line ignores the one 4 studs off and the one behind")
eq(line[1], 1, "nearest along the line first")
line = Skills.lineHits(
	p(0, 0, 0),
	p(0, 0, 1),
	{ p(0, 0, 1), p(0, 0, 2), p(0, 0, 3), p(0, 0, 4), p(0, 0, 5), p(0, 0, 6) },
	120,
	1,
	5
)
eq(#line, 5, "piercing shot stops after five")
local points = Skills.clusterPoints(p(0, 0, 0), p(1, 0, 0), 6, 6, 10)
eq(#points, 6, "six bomblets")
near(points[1].X, 10, "first bomblet 10 ahead")
near(points[6].X, 40, "last bomblet at 10 + 5 * 6")

-- buffs and status
eq(Skills.buffValue(2, 105, 100, 1), 2, "buff active")
eq(Skills.buffValue(2, 105, 105, 1), 1, "buff expired exactly at until")
eq(Skills.buffValue(nil, nil, 0, 1), 1, "no buff")
near(Skills.damageTakenMultiplier({ MarkedUntil = 10 }, 5), 1.3, "marked +30%")
near(Skills.damageTakenMultiplier({ MarkedUntil = 10, BurnUntil = 10 }, 5), 1.3 * 1.15, "marked and burning stack")
eq(Skills.damageTakenMultiplier({ MarkedUntil = 10 }, 10), 1, "mark expired")
near(Skills.freezeDuration("Mage", 3), 3.75, "mage freeze +25%")
near(Skills.freezeDuration("Trooper", 3), 3, "others unchanged")
near(Skills.splashRadius("Demolisher", 8), 9.6, "demolisher blasts 20% wider")

-- turret rules
local idx, replaced = Skills.Turret.placeIndex({})
eq(idx, 1, "first turret in slot 1")
eq(replaced, false, "nothing replaced")
idx, replaced = Skills.Turret.placeIndex({ 10, 20 })
eq(idx, 3, "third slot free")
idx, replaced = Skills.Turret.placeIndex({ 10, 5, 20 })
eq(idx, 2, "fourth turret replaces the oldest (slot 2)")
eq(replaced, true, "replaced flag")
eq(Skills.Turret.repair(100, 300), 175, "repair adds 25% of max")
eq(Skills.Turret.repair(280, 300), 300, "repair is capped at max")
near(Skills.Turret.interval(nil, 0), 0.6, "base interval")
near(Skills.Turret.interval(110, 100), 0.3, "overclocked interval halves")
near(Skills.Turret.interval(110, 110), 0.6, "overclock over at until")
assert(Skills.Turret.canFire(nil, nil, 0), "first shot")
assert(not Skills.Turret.canFire(100, nil, 100.5), "too soon at base rate")
assert(Skills.Turret.canFire(100, 120, 100.5), "fast enough while overclocked")

print("Skills.spec: ok")

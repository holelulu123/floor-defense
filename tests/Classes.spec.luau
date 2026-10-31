local Classes = require("../src/shared/Classes")
local Weapons = require("../src/shared/Weapons")

local function eq(got, want, label)
	assert(got == want, `{label}: got {tostring(got)}, want {tostring(want)}`)
end

eq(#Classes.List, 10, "ten classes")
eq(Classes.find("Summoner"), nil, "Summoner removed")
local free = 0
for _, c in Classes.List do
	eq(#c.skills, 2, `{c.id} has two skills`)
	assert(c.skills[1].cooldown >= 1 and c.skills[1].cooldown <= 10, `{c.id} skill 1 is quick (1-10 s)`)
	assert(c.skills[2].cooldown >= 25, `{c.id} skill 2 is a long cooldown`)
	assert(c.free == (c.cost == 0), `{c.id} free iff cost 0`)
	if c.free then
		free += 1
	end
end
eq(free, 5, "five free classes")

assert(Classes.isOwned("Trooper", {}), "free class is always owned")
assert(not Classes.isOwned("Mage", {}), "locked class needs purchase")
assert(Classes.isOwned("Mage", { "Mage" }), "owned after purchase")

local left, why = Classes.tryBuy("Mage", 1000, {})
eq(left, nil, "cannot afford")
eq(why, "not enough diamonds", "reason")
left, why = Classes.tryBuy("Mage", 1300, {})
eq(left, 100, "diamonds left after buying the Mage")
left, why = Classes.tryBuy("Trooper", 1300, {})
eq(why, "already owned", "free class cannot be bought")

local used = {}
local ok, wait = Classes.canUse("Engineer", 2, used, 100)
assert(ok and wait == 0, "overclock ready at first")
used.Overclock = 100
ok, wait = Classes.canUse("Engineer", 2, used, 110)
assert(not ok and wait == 20, "overclock has 20 s left after 10 s")
ok = Classes.canUse("Engineer", 2, used, 130)
assert(ok, "overclock ready again after 30 s")
eq(Classes.Turrets.MaxPlaced, 3, "three turrets max")

-- health, primary and melee secondary per class
local loadouts = {
	Trooper = { 120, "AssaultRifle", "CombatKnife" },
	Tank = { 220, "Flail", nil },
	Scout = { 90, "DualPistols", "Karambit" },
	Medic = { 110, "SMG", "Scalpel" },
	Engineer = { 120, "Shotgun", "Hammer" },
	Berserker = { 170, "GreatAxe", "Sword" },
	Mage = { 90, "Staff", "Dagger" },
	Pyro = { 130, "Flamethrower", "Machete" },
	Sniper = { 85, "BoltRifle", "CombatKnife" },
	Demolisher = { 120, "GrenadeLauncher", "Hatchet" },
}
for _, c in Classes.List do
	local want = loadouts[c.id]
	assert(want, `{c.id} has an expected loadout`)
	eq(c.maxHealth, want[1], `{c.id} max health`)
	eq(Classes.weaponInSlot(c.id, 1), want[2], `{c.id} slot 1`)
	eq(Classes.weaponInSlot(c.id, 2), want[3], `{c.id} slot 2`)
	assert(Weapons.Definitions[c.weapon], `{c.id} primary {c.weapon} is defined`)
	if c.secondary then
		assert(Weapons.get(c.secondary).melee, `{c.id} secondary {c.secondary} is melee`)
	end
end
eq(Classes.weaponInSlot("Trooper", 3), nil, "no slot 3")
eq(Classes.weaponInSlot("Trooper", "1"), nil, "slot must be a number")
assert(not Classes.get("Tank").passive:find("health"), "Tank passive no longer mentions health")

print("Classes.spec: ok")

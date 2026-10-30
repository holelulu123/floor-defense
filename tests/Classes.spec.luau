local Classes = require("../src/shared/Classes")

local function eq(got, want, label)
	assert(got == want, `{label}: got {tostring(got)}, want {tostring(want)}`)
end

eq(#Classes.List, 11, "eleven classes")
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
eq(why, "not enough gems", "reason")
left, why = Classes.tryBuy("Mage", 1300, {})
eq(left, 100, "gems left after buying the Mage")
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

print("Classes.spec: ok")

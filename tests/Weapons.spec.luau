local Weapons = require("../src/shared/Weapons")

local function eq(got, want, label)
	assert(got == want, `{label}: got {got}, want {want}`)
end

local rifle = Weapons.get("AssaultRifle")
eq(Weapons.interval(rifle), 0.125, "rifle interval is 1/8 s")

assert(Weapons.canFire(rifle, nil, 0), "first shot always allowed")
assert(not Weapons.canFire(rifle, 0, 0.05), "0.05 s after a shot is too soon")
assert(not Weapons.canFire(rifle, 0, 0.099), "just under the tolerated interval is rejected")
assert(Weapons.canFire(rifle, 0, 0.1), "tolerated interval (0.125 * 0.8) is accepted")
assert(Weapons.canFire(rifle, 0, 0.125), "nominal interval is accepted")

local shotgun = Weapons.get("Shotgun")
assert(not Weapons.canFire(shotgun, 10, 10.4), "shotgun cannot fire 0.4 s later")
assert(Weapons.canFire(shotgun, 10, 10.6), "shotgun can fire 0.6 s later")

assert(not Weapons.canFire(rifle, 0, 0.085), "0.085 s is too soon unbuffed")
assert(Weapons.canFire(rifle, 0, 0.085, 1.25), "...but fine with a 1.25x fire-rate buff")
for _, name in { "Shotgun", "SMG", "Flamethrower", "BoltRifle", "GrenadeLauncher", "Flail", "GreatAxe", "Staff" } do
	local def = Weapons.get(name)
	assert(def.damage > 0 and def.fireRate > 0 and def.range > 0, `{name} has stats`)
end
assert(Weapons.get("GreatAxe").melee and Weapons.get("GreatAxe").range <= 12, "axe is a short melee swing")
assert(Weapons.get("GrenadeLauncher").splash == 8, "launcher has splash")

assert(Weapons.Definitions.Wand == nil and Weapons.Definitions.Carbine == nil, "removed weapons are gone")

-- magazines and reload times (seconds)
local mags = {
	AssaultRifle = { 30, 2.0 },
	DualPistols = { 24, 1.4 },
	SMG = { 40, 1.8 },
	Shotgun = { 6, 2.6 },
	Flamethrower = { 100, 3.0 },
	BoltRifle = { 5, 3.0 },
	GrenadeLauncher = { 6, 3.2 },
}
for name, want in mags do
	local def = Weapons.get(name)
	eq(Weapons.magazineSize(def), want[1], `{name} magazine`)
	eq(Weapons.reloadTime(def, "Medic"), want[2], `{name} reload for a class without a reload passive`)
end
for _, name in { "Flail", "GreatAxe", "Staff", "CombatKnife", "Hammer", "Sword" } do
	local def = Weapons.get(name)
	eq(Weapons.magazineSize(def), nil, `{name} has no magazine`)
	eq(Weapons.reloadTime(def, "Trooper"), nil, `{name} never reloads`)
	eq(Weapons.newMagazine(def), nil, `{name} gets no magazine state`)
end
assert(math.abs(Weapons.reloadTime(rifle, "Trooper") :: number - 2.0 / 1.1) < 1e-9, "Trooper reloads 10% faster")
eq(Weapons.reloadTime(rifle, nil), 2.0, "no class, base reload")

-- melee secondaries: damage, swings per second, short reach
local melee = {
	CombatKnife = { 22, 2.2 },
	Karambit = { 18, 2.8 },
	Scalpel = { 16, 2.5 },
	Hammer = { 28, 1.6 },
	Sword = { 30, 1.8 },
	Dagger = { 18, 2.4 },
	Machete = { 26, 1.9 },
	Hatchet = { 27, 1.7 },
}
for name, want in melee do
	local def = Weapons.get(name)
	assert(def.melee == true, `{name} is melee`)
	eq(def.damage, want[1], `{name} damage`)
	eq(def.fireRate, want[2], `{name} rate`)
	eq(def.range, 8, `{name} range`)
end

-- magazine state machine
local mag = Weapons.newMagazine(Weapons.get("BoltRifle")) :: Weapons.Magazine
eq(mag.ammo, 5, "starts full")
assert(not Weapons.beginReload(mag, 3, 0), "cannot reload a full magazine")
for _ = 1, 5 do
	assert(Weapons.consume(mag, 0), "fires while rounds are left")
end
eq(mag.ammo, 0, "empty after five")
assert(not Weapons.consume(mag, 0), "empty magazine refuses")
assert(Weapons.beginReload(mag, 3, 10), "reload starts")
assert(not Weapons.beginReload(mag, 3, 11), "no second reload while reloading")
assert(Weapons.isReloading(mag, 12.9), "still reloading just before the end")
assert(not Weapons.consume(mag, 12.9), "no shots while reloading")
assert(Weapons.consume(mag, 13), "reload done at 13: fires again")
eq(mag.ammo, 4, "full magazine minus that shot")
assert(Weapons.beginReload(mag, 3, 20), "partial magazine can reload")
Weapons.refill(mag)
eq(mag.ammo, 5, "refill fills")
assert(not Weapons.isReloading(mag, 21), "refill cancels the reload")
eq(Weapons.find("Bazooka"), nil, "find: unknown name")
eq(Weapons.find(42), nil, "find: non-string")

local ok = pcall(Weapons.get, "Bazooka")
assert(not ok, "unknown weapon errors")

print("Weapons.spec: ok")

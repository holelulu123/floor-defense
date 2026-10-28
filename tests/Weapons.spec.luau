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

local ok = pcall(Weapons.get, "Bazooka")
assert(not ok, "unknown weapon errors")

print("Weapons.spec: ok")

local Classes = require("../src/shared/Classes")
local ModelIds = require("../src/shared/ModelIds")
local WeaponMeshes = require("../src/shared/WeaponMeshes")
local Weapons = require("../src/shared/Weapons")

local function near(got: number, want: number, label: string)
	assert(math.abs(got - want) < 1e-6, `{label}: got {got}, want {want}`)
end

-- Every class weapon (primary and secondary) has a mesh or a procedural fallback, and every mesh names an uploaded
-- model and a real weapon.
for _, class in Classes.List do
	for _, name in { class.weapon, class.secondary } do
		if name then
			local hold, action = WeaponMeshes.animationsFor(name)
			assert(hold and action, `{class.id} {name} has hold and action animations`)
			assert(WeaponMeshes.get(name) or WeaponMeshes.Fallback[name], `{name} has a mesh or fallback`)
		end
	end
end
for name, mesh in WeaponMeshes.Weapons do
	assert(ModelIds[mesh.model], `{name}: model {mesh.model} is uploaded`)
	assert(name == "Shield" or Weapons.Definitions[name], `{name} is a weapon`)
	assert(mesh.length > 0.5 and mesh.length < 6, `{name}: length {mesh.length} studs is sensible`)
	assert(mesh.grip[1] >= 0 and mesh.grip[1] <= 1 and mesh.grip[2] >= 0 and mesh.grip[2] <= 1, `{name}: grip in box`)
	if mesh.kind == "gun" then
		assert(mesh.forward == "-Z", `{name}: Kenney guns arrive muzzle -Z (export half turn)`)
		assert(Weapons.Definitions[name].melee ~= true, `{name}: guns are not melee`)
	elseif mesh.kind == "melee" then
		assert(mesh.edge and mesh.edge ~= mesh.forward, `{name}: melee has an edge axis across the blade`)
	end
	local hold, action = WeaponMeshes.animationsFor(name)
	if mesh.kind ~= "shield" then
		assert(table.find(WeaponMeshes.Animations, hold), `{name}: {hold} is authored`)
		assert(table.find(WeaponMeshes.Animations, action), `{name}: {action} is authored`)
	end
end

-- Showcase lengths: fraction of the 5.5-stud R15 height.
near(WeaponMeshes.Weapons.AssaultRifle.length, 2.75, "rifle length")
near(WeaponMeshes.Weapons.CombatKnife.length, 1.1, "knife length")
assert(WeaponMeshes.Weapons.Hatchet.model == "GreatAxe", "hatchet reuses the axe model")

-- Axis helper.
local v, ax, sign = WeaponMeshes.axis("-Y")
assert(v.x == 0 and v.y == -1 and v.z == 0 and ax == "y" and sign == -1, "axis -Y")

-- Scale: a 60-stud rifle becomes 2.75 studs.
near(WeaponMeshes.scale(WeaponMeshes.Weapons.AssaultRifle, { x = 5.8, y = 26.4, z = 60 }), 2.75 / 60, "rifle scale")

-- Grip point: along the forward axis from the butt, up from the bottom.
local min, max = { x = -1, y = 0, z = -30 }, { x = 1, y = 10, z = 30 }
local p = WeaponMeshes.point("+Z", min, max, { 0.25, 0.3 })
near(p.x, 0, "grip x centred")
near(p.y, 3, "grip up 30%")
near(p.z, -15, "grip 25% from the butt (-Z)")
local q = WeaponMeshes.point("-Z", min, max, { 0.25, 0.3 })
near(q.z, 15, "reversed forward measures from +Z")
local r = WeaponMeshes.point("+Y", min, max, { 0.2, 0.9 })
near(r.y, 2, "melee grip 20% up the handle; `up` ignored on Y")
near(r.z, 0, "melee grip centred in z")

-- Muzzle sits at the far end.
local m = WeaponMeshes.point("+Z", min, max, WeaponMeshes.Weapons.AssaultRifle.muzzle)
near(m.z, 30, "muzzle at +Z end")

assert(WeaponMeshes.animationsFor("Flail") == "HoldMelee", "procedural flail still animates")
assert(WeaponMeshes.animationsFor(nil) == nil, "no weapon, no animation")

print("WeaponMeshes: ok")

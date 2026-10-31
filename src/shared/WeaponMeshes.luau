-- How each class weapon's uploaded mesh (src/shared/ModelIds.luau) is sized and held, mirroring the showcase
-- (showcase/catalog.js: the GRIP table, each class's `hold` len and each melee secondary's knife()/blade()). Pure data
-- plus box math on plain {x, y, z} tables so Lune can test it; WeaponModels.luau turns it into Tools.
--
-- Axes are the uploaded model's own axes (they match the glTF source: +Y up). Kenney guns point the muzzle along +Z;
-- Kenney knives and the Quaternius / KayKit melee models stand blade (or head) up along +Y, handle at the bottom; the
-- KayKit staff lies along +Z with its head at +Z.
--
-- Axes are in the uploaded model's frame: the Blender export turns glTF models half a turn about Y, so a glb's +Z
-- and +X arrive as -Z and -X (a rifle's muzzle is at -Z; seen in Studio 2026-10-31).
-- Fractions are of the model's bounding box: `grip` = {along, up} where `along` runs butt -> tip on the forward axis
-- and `up` runs bottom -> top on Y (ignored when forward is Y; the other axes stay centred). `muzzle` is the business
-- end the same way. `edge` (melee) is the model axis the striking side faces; it is turned to face forward.

local WeaponMeshes = {}

-- R15 avatar height in studs; showcase lengths are fractions of the character's height.
WeaponMeshes.CharacterHeight = 5.5

export type Axis = "+X" | "-X" | "+Y" | "-Y" | "+Z" | "-Z"
export type Kind = "gun" | "melee" | "shield"
export type Hold = "Rifle" | "Pistols" | "Melee" | "Heavy" | "Staff"
export type Action = "RecoilRifle" | "RecoilPistols" | "Swing" | "SwingHeavy" | "Cast"
export type Vec = { x: number, y: number, z: number }

export type Mesh = {
	model: string, -- ModelIds key
	kind: Kind,
	length: number, -- studs along the model's longest side
	forward: Axis, -- model axis toward the muzzle / blade tip / staff head
	edge: Axis?, -- melee: model axis the striking side faces
	grip: { number }, -- {along, up}
	muzzle: { number }, -- {along, up}
	hold: Hold?, -- looped arm pose while equipped (animation Anim_Hold<hold>)
	action: Action?, -- played per shot / swing (animation Anim_<action>)
}

local H = WeaponMeshes.CharacterHeight

local function gun(model: string, len: number, grip: { number }, muzzleUp: number, hold: Hold?): Mesh
	return {
		model = model,
		kind = "gun",
		length = len * H,
		forward = "-Z",
		grip = grip,
		muzzle = { 1, muzzleUp },
		hold = hold or "Rifle",
		action = if hold == "Pistols" then "RecoilPistols" else "RecoilRifle",
	}
end

local function melee(model: string, len: number, gripAlong: number, edge: Axis, hold: Hold?, action: Action?): Mesh
	return {
		model = model,
		kind = "melee",
		length = len * H,
		forward = "+Y",
		edge = edge,
		grip = { gripAlong, 0.5 },
		muzzle = { 0.95, 0.5 },
		hold = hold or "Melee",
		action = action or "Swing",
	}
end

-- Weapon name (Weapons.luau / Classes.luau) -> mesh. The Tank's Flail stays procedural (no mesh in the packs).
WeaponMeshes.Weapons = {
	-- Primaries: gun(len) with the showcase GRIP point; muzzle height read off the barrel in the glb.
	AssaultRifle = gun("AssaultRifle", 0.5, { 0.31, 0.3 }, 0.72),
	Shotgun = gun("Shotgun", 0.52, { 0.31, 0.5 }, 0.75),
	DualPistols = gun("DualPistols", 0.24, { 0.2, 0.42 }, 0.85, "Pistols"),
	SMG = gun("SMG", 0.34, { 0.34, 0.5 }, 0.8),
	Flamethrower = gun("Flamethrower", 0.6, { 0.33, 0.28 }, 0.6),
	BoltRifle = gun("BoltRifle", 0.7, { 0.255, 0.3 }, 0.7),
	GrenadeLauncher = gun("GrenadeLauncher", 0.5, { 0.5, 0.3 }, 0.6),
	-- Berserker axe: melee(len 0.9, offset 0.2) -> hand 0.3 up from the butt; head along -X.
	GreatAxe = melee("GreatAxe", 0.9, 0.3, "-X", "Heavy", "SwingHeavy"),
	-- Mage staff: melee(len 0.8, offset 0.05) -> hand at 0.45; lies along -Z in the upload.
	Staff = {
		model = "Staff",
		kind = "melee",
		length = 0.8 * H,
		forward = "-Z",
		edge = "+Y",
		grip = { 0.45, 0.5 },
		muzzle = { 1, 0.5 },
		hold = "Staff",
		action = "Cast",
	},
	-- Melee secondaries: knife(len 0.2 default, at 0.2) and blade(len, grip).
	CombatKnife = melee("CombatKnife", 0.2, 0.2, "-Z"),
	Karambit = melee("Karambit", 0.2, 0.2, "-Z"),
	Scalpel = melee("Scalpel", 0.2, 0.2, "-Z"),
	Machete = melee("Machete", 0.26, 0.2, "-Z"),
	Hammer = melee("Hammer", 0.34, 0.12, "-X"),
	Sword = melee("Sword", 0.45, 0.1, "-X"),
	Dagger = melee("Dagger", 0.24, 0.12, "-X"),
	Hatchet = melee("GreatAxe", 0.3, 0.12, "-X"), -- the Demolisher's hatchet is the same axe model, smaller
	-- Tank shield on the left forearm (len 0.36); its face (the boss) points -Z.
	Shield = {
		model = "Shield",
		kind = "shield",
		length = 0.36 * H,
		forward = "-Z",
		grip = { 0, 0.5 },
		muzzle = { 1, 0.5 },
	},
} :: { [string]: Mesh }

-- Animations for weapons with no mesh entry (the procedural Flail).
WeaponMeshes.Fallback = { Flail = { hold = "Melee" :: Hold, action = "Swing" :: Action } }

-- Every animation the game plays, authored by scripts/roblox/make-animations.luau (keys Anim_<name> in ModelIds).
WeaponMeshes.Animations = {
	"HoldRifle",
	"HoldPistols",
	"HoldMelee",
	"HoldHeavy",
	"HoldStaff",
	"RecoilRifle",
	"RecoilPistols",
	"Swing",
	"SwingHeavy",
	"Cast",
}

function WeaponMeshes.get(weaponName: string?): Mesh?
	return if weaponName then WeaponMeshes.Weapons[weaponName] else nil
end

-- Hold pose and per-shot animation names for a weapon (mesh entry or fallback); nil when it has none.
function WeaponMeshes.animationsFor(weaponName: string?): (string?, string?)
	local mesh = WeaponMeshes.get(weaponName)
	local entry = mesh or (weaponName and WeaponMeshes.Fallback[weaponName])
	if not entry then
		return nil, nil
	end
	return if entry.hold then "Hold" .. entry.hold else nil, entry.action
end

-- Unit vector of an axis name as {x, y, z}, plus the component name and sign.
function WeaponMeshes.axis(axis: Axis): (Vec, string, number)
	local sign = if string.sub(axis, 1, 1) == "-" then -1 else 1
	local name = string.lower(string.sub(axis, 2, 2))
	local v = { x = 0, y = 0, z = 0 }
	v[name] = sign
	return v, name, sign
end

-- Uniform scale that makes a box of `size` the mesh's length along its longest side.
function WeaponMeshes.scale(mesh: Mesh, size: Vec): number
	local longest = math.max(size.x, size.y, size.z)
	return mesh.length / math.max(longest, 1e-6)
end

-- A {along, up} fraction pair as a point inside the box min..max (forward axis from `forward`).
function WeaponMeshes.point(forward: Axis, min: Vec, max: Vec, fraction: { number }): Vec
	local _, ax, sign = WeaponMeshes.axis(forward)
	local p = { x = (min.x + max.x) / 2, y = (min.y + max.y) / 2, z = (min.z + max.z) / 2 }
	local along = fraction[1]
	p[ax] = if sign > 0 then min[ax] + (max[ax] - min[ax]) * along else max[ax] - (max[ax] - min[ax]) * along
	if ax ~= "y" then
		p.y = min.y + (max.y - min.y) * fraction[2]
	end
	return p
end

return WeaponMeshes

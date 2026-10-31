-- Weapon definitions, fire-rate rules and the magazine / reload state machine. Pure data and math so
-- Lune tests can load it. The server enforces these numbers; the client only uses them for feel (local
-- cooldown, crosshair, the HUD ammo readout).

local Skills = require(script and script.Parent.Skills or "./Skills")

export type Weapon = {
	name: string,
	damage: number,
	fireRate: number, -- shots (or swings) per second
	range: number, -- studs
	automatic: boolean,
	melee: boolean?, -- short range swing; the raycast is still the hit test
	splash: number?, -- studs of area damage around the impact point
	burn: number?, -- seconds a hit creature keeps burning (BurnUntil attribute)
	magazine: number?, -- rounds (or fuel units) per reload; nil for melee and magic weapons
	reload: number?, -- base seconds to reload a magazine; nil when there is no magazine
}

-- Server-side magazine of one player's primary weapon. Times are seconds on any one clock (the server
-- uses Workspace:GetServerTimeNow() so the client can read ReloadEnd for its countdown).
export type Magazine = {
	size: number,
	ammo: number,
	reloadUntil: number?, -- set while a reload is running
}

local Weapons = {}

-- Melee secondaries share one reach; the Engineer's turret repair reach matches it.
Weapons.MeleeRange = 8
-- A swing that misses with its ray still connects with the nearest creature in this arc in front of the player:
-- creatures run 20-38 studs/s, so the server's hitbox has moved on by the time the swing arrives.
Weapons.MeleeArc = { slack = 3, halfAngle = 60 } -- extra studs of reach (hitbox half-width), degrees each side

local function melee(name: string, damage: number, fireRate: number): Weapon
	return {
		name = name,
		damage = damage,
		fireRate = fireRate,
		range = Weapons.MeleeRange,
		automatic = true,
		melee = true,
	}
end

Weapons.Definitions = {
	-- Primaries (Classes.luau `weapon` field).
	AssaultRifle = {
		name = "AssaultRifle",
		damage = 10,
		fireRate = 8,
		range = 250,
		automatic = true,
		magazine = 30,
		reload = 2.0,
	},
	Shotgun = {
		name = "Shotgun",
		damage = 40,
		fireRate = 1.5,
		range = 60,
		automatic = false,
		magazine = 6,
		reload = 2.6,
	},
	-- Two pistols of 12 each, fired alternately from one shared 24-round pool.
	DualPistols = {
		name = "DualPistols",
		damage = 12,
		fireRate = 6,
		range = 150,
		automatic = false,
		magazine = 24,
		reload = 1.4,
	},
	SMG = { name = "SMG", damage = 6, fireRate = 12, range = 120, automatic = true, magazine = 40, reload = 1.8 },
	-- The flamethrower's magazine is fuel: one unit per tick of flame.
	Flamethrower = {
		name = "Flamethrower",
		damage = 4,
		fireRate = 15,
		range = 25,
		automatic = true,
		burn = 2,
		magazine = 100,
		reload = 3.0,
	},
	BoltRifle = {
		name = "BoltRifle",
		damage = 60,
		fireRate = 0.8,
		range = 400,
		automatic = false,
		magazine = 5,
		reload = 3.0,
	},
	GrenadeLauncher = {
		name = "GrenadeLauncher",
		damage = 50,
		fireRate = 1,
		range = 150,
		automatic = false,
		splash = 8,
		magazine = 6,
		reload = 3.2,
	},
	-- Melee and magic primaries never reload.
	-- The Tank's flail hits everything within `splash` studs of the swing's impact (area damage).
	Flail = { name = "Flail", damage = 25, fireRate = 1.5, range = 10, automatic = true, melee = true, splash = 6 },
	GreatAxe = { name = "GreatAxe", damage = 45, fireRate = 1.2, range = 10, automatic = true, melee = true },
	Staff = { name = "Staff", damage = 20, fireRate = 2, range = 150, automatic = false },

	-- Melee secondaries (Classes.luau `secondary` field), slot 2.
	CombatKnife = melee("CombatKnife", 22, 2.2),
	Karambit = melee("Karambit", 18, 2.8),
	Scalpel = melee("Scalpel", 16, 2.5),
	Hammer = melee("Hammer", 28, 1.6), -- the Engineer's repair tool
	Sword = melee("Sword", 30, 1.8),
	Dagger = melee("Dagger", 18, 2.4),
	Machete = melee("Machete", 26, 1.9),
	Hatchet = melee("Hatchet", 27, 1.7),
}

-- How much earlier than the nominal interval a shot may arrive before the server rejects it.
-- Covers network jitter without letting a modified client double its fire rate.
Weapons.RateTolerance = 0.8

function Weapons.find(name: any): Weapon?
	return if type(name) == "string" then Weapons.Definitions[name] else nil
end

function Weapons.get(name: string): Weapon
	local def = Weapons.Definitions[name]
	assert(def, `Unknown weapon {name}`)
	return def
end

function Weapons.interval(def: Weapon): number
	return 1 / def.fireRate
end

-- Server-side check: may a weapon that last fired at `lastFiredAt` fire again at `now`?
-- `rateMult` > 1 (skill buffs) shortens the interval.
function Weapons.canFire(def: Weapon, lastFiredAt: number?, now: number, rateMult: number?): boolean
	if lastFiredAt == nil then
		return true
	end
	return now - lastFiredAt >= Weapons.interval(def) / (rateMult or 1) * Weapons.RateTolerance
end

-- Magazine / reload -----------------------------------------------------------------------------------

-- Rounds per magazine, or nil for weapons that never reload (melee, magic).
function Weapons.magazineSize(def: Weapon): number?
	return def.magazine
end

-- Seconds a reload takes for this class. The Trooper's "+10% reload speed" divides it by 1.1.
function Weapons.reloadTime(def: Weapon, classId: string?): number?
	if not def.magazine or not def.reload then
		return nil
	end
	local passive = classId and Skills.Passives[classId]
	local speed = (passive and passive.reloadSpeed) or 1
	return def.reload / speed
end

-- A full magazine for `def`, or nil when the weapon has none.
function Weapons.newMagazine(def: Weapon): Magazine?
	if not def.magazine then
		return nil
	end
	return { size = def.magazine, ammo = def.magazine, reloadUntil = nil }
end

-- Finishes a reload whose time has come. Returns true when it changed the magazine.
function Weapons.settle(mag: Magazine, now: number): boolean
	if mag.reloadUntil and now >= mag.reloadUntil then
		mag.reloadUntil = nil
		mag.ammo = mag.size
		return true
	end
	return false
end

function Weapons.isReloading(mag: Magazine, now: number): boolean
	return mag.reloadUntil ~= nil and now < mag.reloadUntil
end

-- Spends one round. False (nothing spent) while reloading or when empty.
function Weapons.consume(mag: Magazine, now: number): boolean
	Weapons.settle(mag, now)
	if mag.reloadUntil ~= nil or mag.ammo <= 0 then
		return false
	end
	mag.ammo -= 1
	return true
end

-- Starts a reload lasting `seconds`. False when the magazine is full or already reloading.
function Weapons.beginReload(mag: Magazine, seconds: number, now: number): boolean
	Weapons.settle(mag, now)
	if mag.reloadUntil ~= nil or mag.ammo >= mag.size then
		return false
	end
	mag.reloadUntil = now + seconds
	return true
end

-- Instantly fills the magazine and cancels any reload (Trooper's Ammo Crate).
function Weapons.refill(mag: Magazine)
	mag.ammo = mag.size
	mag.reloadUntil = nil
end

return Weapons
